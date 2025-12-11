
@description('Required. Name of the App Service Plan.')
@minLength(1)
@maxLength(40)
param appServicePlanName string

@description('Required. Name of the web app.')
@maxLength(60)
param appName string 

@description('Optional S1 is default. Defines the name, tier, size, family and capacity of the App Service Plan. Plans ending to _AZ, are deploying at least three instances in three Availability Zones. EP* is only for functions. WS1 is for Logic Apps Standard.')
@allowed([ 'B1','B3','S1', 'S2', 'S3', 'P1V3', 'P2V3', 'P3V3', 'P1V3_AZ', 'P2V3_AZ', 'P3V3_AZ', 'EP1', 'EP2', 'EP3', 'ASE_I1V2_AZ', 'ASE_I2V2_AZ', 'ASE_I3V2_AZ', 'ASE_I1V2', 'ASE_I2V2', 'ASE_I3V2', 'WS1' ])
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

@description('Name of the storage account if deploying Function App or Logic App')
@maxLength(24)
param storageAccountName string = ''

@description('Webapp, functionapp, or functionapp,workflowapp')
@allowed(['functionapp','app','functionapp,workflowapp'])
param kind string

@description('Client ID of the managed identity to be used for the SQL DB connection string. For Function App Only')
param sqlDBManagedIdentityClientId string = ''

param deploySlot bool

param deployAppPrivateEndPoint bool
param userAssignedIdentities array
param eventGridServiceTagRestriction bool = false

@description('Override to allow public access even when private endpoint exists')
param allowPublicAccessOverride bool = false


var slotName = 'staging'

var varWhitelistIPs = filter(split(paramWhitelistIPs, ','), ip => !empty(trim(ip)))
var contentShareName = (kind == 'functionapp' || kind == 'functionapp,workflowapp') ? take(replace(toLower('${appName}-content'), '_', '-'), 63) : ''
var storageAccountSanitized = toLower(replace(storageAccountName, '-', ''))
var storageAccountResourceName = length(storageAccountSanitized) > 24 ? substring(storageAccountSanitized, 0, 24) : storageAccountSanitized

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
    allowPublicAccessOverride: allowPublicAccessOverride
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
        ipAddress: contains(ip, '/') ? ip : '${ip}/32'
        action: 'Allow'
        name: 'Allow-IP-${index + 1}'
        priority: 100 + index
      }]
  }
}

module funcUAI '../../../shared/bicep/managed-identity.bicep' = if(kind == 'functionapp') {
  name: take('mi-${appName}', 64)
  params: {
    name: 'id-${appName}'
    location: location
    tags: tags
  }
}

var funcUaiId = resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', 'id-${appName}')
var funcUaiClientId = kind == 'functionapp' ? reference(funcUaiId, '2023-01-31', 'Full').properties.clientId : ''
var funcUaiPrincipalId = kind == 'functionapp' ? reference(funcUaiId, '2023-01-31', 'Full').properties.principalId : ''
var storageAccountId = resourceId('Microsoft.Storage/storageAccounts', storageAccountResourceName)

module fnstorage '../../../shared/bicep/storage/storage.bicep' = if(kind == 'functionapp' || kind == 'functionapp,workflowapp') {
  name: take('fnAppStoragePrivateNetwork-${deployment().name}', 64)
  params: {
    name: storageAccountName
    location: location
    sku: 'Standard_LRS'
    kind: 'StorageV2'
    supportsHttpsTrafficOnly: true
    allowSharedKeyAccess: (kind == 'functionapp') ? false : true // Logic App still needs shared accedd keys enabled on their storage accounts
    tags: {}
    networkAcls: networkAcls 
  }
}

module storageBlobPrivateNetwork '../../../shared/bicep/network/private-networking-spoke.bicep' = if((kind == 'functionapp' || kind == 'functionapp,workflowapp') && deployAppPrivateEndPoint == true) {
  name: take('pep-${appName}-blob', 64)
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

module storageFilesPrivateNetwork '../../../shared/bicep/network/private-networking-spoke.bicep' = if((kind == 'functionapp' || kind == 'functionapp,workflowapp') && deployAppPrivateEndPoint == true) {
  name: take('pep-${appName}-file', 64)
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
  }
  dependsOn: [
    storageBlobPrivateNetwork
  ]
}

// Role assignments for Function App managed identity on storage account
module assignBlobContributor '../../../shared/bicep/role-assignments/role-assignment.bicep' = if(kind == 'functionapp') {
  name: take('ra-${appName}-blob', 64)
  params: {
    name: take('ra-${appName}-blob', 64)
    resourceId: storageAccountId
    roleDefinitionId: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // Storage Blob Data Contributor
    principalId: funcUaiPrincipalId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    funcUAI
  ]
}


module fnApp '../../../shared/bicep/app-services/function-app.bicep' = if(kind == 'functionapp') {
  name: take('${appName}-webApp-Deployment', 64)
  params: {
    kind: (webAppBaseOs =~ 'linux') ? 'functionapp,linux' : 'functionapp'
    functionAppName:  appName
    location: location
    serverFarmResourceId: appSvcPlan.outputs.resourceId
    //diagnosticWorkspaceId: logAnalyticsWsId
    virtualNetworkSubnetId: subnetIdForVnetInjection
    appInsightId: appInsights.outputs.appInsResourceId
    userAssignedIdentities:  {
      type: 'UserAssigned'
      userAssignedIdentities: reduce(union(userAssignedIdentities, [funcUaiId]), {}, (result, id) => union(result, { '${id}': {} }))
    }
    storageAccountName: storageAccountName
    hasPrivateEndpoint: deployAppPrivateEndPoint
    sqlDBManagedIdentityClientId: sqlDBManagedIdentityClientId
    eventGridServiceTagRestriction: eventGridServiceTagRestriction
    appSettings: [
      {
        name: 'AzureWebJobsStorage__credential'
        value: 'managedidentity'
      }
      {
        name: 'AzureWebJobsStorage__accountName'
        value: storageAccountName
      }
      {
        name: 'AzureWebJobsStorage__blobServiceUri'
        value: 'https://${storageAccountName}.blob.${environment().suffixes.storage}'
      }
      {
        name: 'AzureWebJobsStorage__clientId'
        value: funcUaiClientId
      }
    ]
  }
  dependsOn: [
    fnstorage
    assignBlobContributor
    funcUAI
  ]
}

module lgApp '../../../shared/bicep/app-services/logic-app.bicep' = if(kind == 'functionapp,workflowapp') {
  name: take('${appName}-logicApp-Deployment', 64)
  params: {
    kind: 'functionapp,workflowapp'
    logicAppName:  appName
    location: location
    serverFarmResourceId: appSvcPlan.outputs.resourceId
    appInsightId: appInsights.outputs.appInsResourceId
    virtualNetworkSubnetId: subnetIdForVnetInjection
    userAssignedIdentities:  {
      type: 'UserAssigned'
      userAssignedIdentities: reduce(userAssignedIdentities, {}, (result, id) => union(result, { '${id}': {} }))
    }
    storageAccountName: storageAccountName
    contentShareName: contentShareName
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

// Private endpoint for App Service/Function App/Logic App using existing private-networking-spoke module
module appServicePrivateEndpoint '../../../shared/bicep/network/private-networking-spoke.bicep' = if(deployAppPrivateEndPoint && (kind == 'app' || kind == 'functionapp')) {
  name: take('pep-${appName}-sites', 64)
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

module logicappServicePrivateEndpoint '../../../shared/bicep/network/private-networking-spoke.bicep' = if(deployAppPrivateEndPoint && kind == 'functionapp,workflowapp') {
  name: take('pep-${appName}-logic', 64)
  scope: resourceGroup(privateEndpointRG)
  params: {
    location: location
    azServicePrivateDnsZoneName: 'privatelink.azurewebsites.net'
    azServiceId: lgApp!.outputs.logicAppId
    privateEndpointName: take('pep-${lgApp!.outputs.logicAppName}', 64)
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
  dependsOn: [
    storageFilesPrivateNetwork
  ]
}

output appName string = appName
output appHostName string = (kind == 'app') ? webApp!.outputs.defaultHostname: kind == 'functionapp,workflowapp' ? lgApp!.outputs.defaultHostName : fnApp!.outputs.defaultHostName
output webAppResourceId string = (kind == 'app') ? webApp!.outputs.resourceId : kind == 'functionapp,workflowapp' ? lgApp!.outputs.logicAppId : fnApp!.outputs.functionAppId
output systemAssignedPrincipalId string = (kind == 'app') ? webApp!.outputs.systemAssignedPrincipalId : kind == 'functionapp,workflowapp' ? lgApp!.outputs.systemAssignedPrincipalId : fnApp!.outputs.systemAssignedPrincipalId
output appInsightsResourceId string = appInsights.outputs.appInsResourceId
output logicAppName string = kind == 'functionapp,workflowapp' ? lgApp!.outputs.logicAppName : ''
output logicAppId string = kind == 'functionapp,workflowapp' ? lgApp!.outputs.logicAppId : ''





