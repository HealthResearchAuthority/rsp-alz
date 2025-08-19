


@description('Required. Name of the App Service Plan.')
@minLength(1)
@maxLength(40)
param appServicePlanName string

@description('Required. Name of the web app.')
@maxLength(60)
param appName string 

@description('Optional S1 is default. Defines the name, tier, size, family and capacity of the App Service Plan. Plans ending to _AZ, are deploying at least three instances in three Availability Zones. EP* is only for functions')
@allowed([ 'B1','S1', 'S2', 'S3', 'P1V3', 'P2V3', 'P3V3', 'P1V3_AZ', 'P2V3_AZ', 'P3V3_AZ', 'EP1', 'EP2', 'EP3', 'ASE_I1V2_AZ', 'ASE_I2V2_AZ', 'ASE_I3V2_AZ', 'ASE_I1V2', 'ASE_I2V2', 'ASE_I3V2' ])
param sku string

@description('Optional. Location for all resources.')
param location string

@description('Resource tags that we might need to add to all resources (i.e. Environment, Cost center, application name etc)')
param tags object

@description('Optional. The IP ACL rules. Note, requires the \'acrSku\' to be \'Premium\'.')
param paramWhitelistIPs string = ''

param subnetPrivateEndpointSubnetId string

@description('Resource Group where PEP and PEP DNS needs to be deployed')
param privateEndpointRG string

@description('The resource ID of the VNet to which the private endpoint will be connected.')
param spokeVNetId string

@description('Kind of server OS of the App Service Plan')
@allowed([ 'Windows', 'Linux'])
param webAppBaseOs string

@description('An existing Log Analytics WS Id for creating app Insights, diagnostics etc.')
param logAnalyticsWsId string

@description('The subnet ID that is dedicated to Web Server, for Vnet Injection of the web app. If deployAseV3=true then this is the subnet dedicated to the ASE v3')
param subnetIdForVnetInjection string

@description('Name of the storage account if deploying Function App')
@maxLength(24)
param storageAccountName string = ''

@description('Webapp or functionapp')
@allowed(['functionapp','app'])
param kind string

@description('Client ID of the managed identity to be used for the SQL DB connection string. For Function App Only')
param sqlDBManagedIdentityClientId string = ''

param deploySlot bool

param deployAppPrivateEndPoint bool
param userAssignedIdentities array


var slotName = 'staging'

 var varWhitelistIPs = filter(split(paramWhitelistIPs, ','), ip => !empty(trim(ip)))

var spokeVNetIdTokens = split(spokeVNetId, '/')
var spokeSubscriptionId = spokeVNetIdTokens[2]
var spokeResourceGroupName = spokeVNetIdTokens[4]
var spokeVNetName = spokeVNetIdTokens[8]
var networkAcls = deployAppPrivateEndPoint ? {
  defaultAction: 'Deny'
  bypass: 'AzureServices'
  virtualNetworkRules: [
    {
      id: subnetIdForVnetInjection
      action: 'Allow'
    }
  ]
} : {
  defaultAction: 'Allow'
  bypass: 'AzureServices'
}

module appInsights '../../../shared/bicep/app-insights.bicep' = {
  name: take('${appName}-appInsights-Deployment', 64)
  params: {
    name: 'appi-${appName}'
    location: location
    tags: tags
    workspaceResourceId: logAnalyticsWsId
  }
}

module appSvcPlan '../../../shared/bicep/app-services/app-service-plan.bicep' = {
  name: take('appSvcPlan-${appServicePlanName}-Deployment', 64) 
  params: {
    name: appServicePlanName
    location: location
    tags: tags
    sku: sku
    serverOS: (webAppBaseOs =~ 'linux') ? 'Linux' : 'Windows'
    diagnosticWorkspaceId: logAnalyticsWsId
  }
}

module webApp '../../../shared/bicep/app-services/web-app.bicep' = if(kind == 'app') {
  name: take('${appName}-webApp-Deployment', 64)
  params: {
    kind: (webAppBaseOs =~ 'linux') ? 'app,linux' : 'app'
    name:  appName
    location: location
    serverFarmResourceId: appSvcPlan.outputs.resourceId
    diagnosticWorkspaceId: logAnalyticsWsId   
    virtualNetworkSubnetId: subnetIdForVnetInjection
    appInsightId: appInsights.outputs.appInsResourceId
    operatingSystem:  (webAppBaseOs =~ 'linux') ? 'linuxNet9' : 'windowsNet9'
    hasPrivateLink: deployAppPrivateEndPoint
    systemAssignedIdentity: false
    userAssignedIdentities:  {
      type: 'UserAssigned'
      userAssignedIdentities: reduce(userAssignedIdentities, {}, (result, id) => union(result, { '${id}': {} }))
    }
    slots: deploySlot ? [
      {
        name: slotName
      }
    ] : []
    networkRuleSetIpRules: [for (ip, index) in varWhitelistIPs: {
        ipAddress: '${ip}/32'
        action: 'Allow'
        name: 'Allow-IP-${index + 1}'
        priority: 100 + index
      }]
  }
}

module fnstorage '../../../shared/bicep/storage/storage.bicep' = if(kind == 'functionapp') {
  name: take('fnAppStoragePrivateNetwork-${deployment().name}', 64)
  params: {
    name: storageAccountName
    location: location
    sku: 'Standard_LRS'
    kind: 'StorageV2'
    supportsHttpsTrafficOnly: true
    tags: {}
    networkAcls: networkAcls 
  }
}

module storageBlobPrivateNetwork '../../../shared/bicep/network/private-networking-spoke.bicep' = if(kind == 'functionapp' && deployAppPrivateEndPoint == true) {
  name:take('rtsfnStorageBlobPrivateNetwork-${deployment().name}', 64)
  scope: resourceGroup(privateEndpointRG)
  params: {
    location: location
    azServicePrivateDnsZoneName: 'privatelink.blob.${environment().suffixes.storage}'
    azServiceId: fnstorage!.outputs.id
    privateEndpointName: take('pep-${storageAccountName}-blob', 64)
    privateEndpointSubResourceName: 'blob'
    virtualNetworkLinks: [
      {
        vnetName: spokeVNetName
        vnetId: vnetSpoke.id
        registrationEnabled: false
      }
    ]
    subnetId: subnetPrivateEndpointSubnetId
    //vnetSpokeResourceId: spokeVNetId
  }
}

module storageFilesPrivateNetwork '../../../shared/bicep/network/private-networking-spoke.bicep' = if(kind == 'functionapp' && deployAppPrivateEndPoint == true) {
  name:take('rtsfnStorageFilePrivateNetwork-${deployment().name}', 64)
  scope: resourceGroup(privateEndpointRG)
  params: {
    location: location
    azServicePrivateDnsZoneName: 'privatelink.file.${environment().suffixes.storage}'
    azServiceId: fnstorage!.outputs.id
    privateEndpointName: take('pep-${storageAccountName}-file', 64)
    privateEndpointSubResourceName: 'file'
    virtualNetworkLinks: [
      {
        vnetName: spokeVNetName
        vnetId: vnetSpoke.id
        registrationEnabled: false
      }
    ]
    subnetId: subnetPrivateEndpointSubnetId
    //vnetSpokeResourceId: spokeVNetId
  }
  dependsOn: [
    storageBlobPrivateNetwork
  ]
}

module fnApp '../../../shared/bicep/app-services/function-app.bicep' = if(kind == 'functionapp') {
  name: take('${appName}-webApp-Deployment', 64)
  params: {
    kind: 'functionapp'
    functionAppName:  appName
    location: location
    serverFarmResourceId: appSvcPlan.outputs.resourceId
    //diagnosticWorkspaceId: logAnalyticsWsId
    virtualNetworkSubnetId: subnetIdForVnetInjection
    appInsightId: appInsights.outputs.appInsResourceId
    userAssignedIdentities:  {
      type: 'UserAssigned'
      userAssignedIdentities: reduce(userAssignedIdentities, {}, (result, id) => union(result, { '${id}': {} }))
    }
    storageAccountName: storageAccountName
    hasPrivateEndpoint: deployAppPrivateEndPoint
    sqlDBManagedIdentityClientId: sqlDBManagedIdentityClientId
  }
  dependsOn: [
    fnstorage
  ]
}

resource vnetSpoke 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  scope: resourceGroup(spokeSubscriptionId, spokeResourceGroupName)
  name: spokeVNetName
}

// Private endpoint for App Service/Function App using existing private-networking-spoke module
module appServicePrivateEndpoint '../../../shared/bicep/network/private-networking-spoke.bicep' = if(deployAppPrivateEndPoint) {
  name: take('appServicePrivateEndpoint-${deployment().name}', 64)
  scope: resourceGroup(privateEndpointRG)
  params: {
    location: location
    azServicePrivateDnsZoneName: 'privatelink.azurewebsites.net'
    azServiceId: kind == 'app' ? webApp!.outputs.resourceId : fnApp!.outputs.functionAppId
    privateEndpointName: kind == 'app' ? take('pep-${webApp!.outputs.name}', 64) : take('pep-${fnApp!.outputs.functionAppName}', 64)
    privateEndpointSubResourceName: 'sites'
    virtualNetworkLinks: [
      {
        vnetName: spokeVNetName
        vnetId: vnetSpoke.id
        registrationEnabled: false
      }
    ]
    subnetId: subnetPrivateEndpointSubnetId
    //vnetSpokeResourceId: spokeVNetId
  }
}

output appHostName string = (kind == 'app') ? webApp!.outputs.defaultHostname: fnApp!.outputs.defaultHostName
output webAppResourceId string = (kind == 'app') ? webApp!.outputs.resourceId : fnApp!.outputs.functionAppId
output systemAssignedPrincipalId string = (kind == 'app') ? webApp!.outputs.systemAssignedPrincipalId : fnApp!.outputs.systemAssignedPrincipalId
// output webAppLocation string = webApp.outputs.location
// output webAppSystemAssignedPrincipalId string = webApp.outputs.systemAssignedPrincipalId

