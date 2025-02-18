
@description('Required. Name of the App Service Plan.')
@minLength(1)
@maxLength(40)
param appServicePlanName string

@description('Required. Name of the web app.')
@maxLength(60)
param appName string 

// @description('Required. Name of the managed Identity that will be assigned to the web app.')
// param appConfigmanagedIdentityId string

// @description('Required. Name of the managed Identity that will be assigned to the web app.')
// param keyVaultmanagedIdentityId string = ''

// @description('Required. Name of the managed Identity that will be assigned to the web app.')
// param sqlServermanagedIdentityId string = ''

@description('Optional S1 is default. Defines the name, tier, size, family and capacity of the App Service Plan. Plans ending to _AZ, are deploying at least three instances in three Availability Zones. EP* is only for functions')
@allowed([ 'B1','S1', 'S2', 'S3', 'P1V3', 'P2V3', 'P3V3', 'P1V3_AZ', 'P2V3_AZ', 'P3V3_AZ', 'EP1', 'EP2', 'EP3', 'ASE_I1V2_AZ', 'ASE_I2V2_AZ', 'ASE_I3V2_AZ', 'ASE_I1V2', 'ASE_I2V2', 'ASE_I3V2' ])
param sku string

@description('Optional. Location for all resources.')
param location string

@description('Resource tags that we might need to add to all resources (i.e. Environment, Cost center, application name etc)')
param tags object

@description('Default is empty. If empty no Private Endpoint will be created for the resoure. Otherwise, the subnet where the private endpoint will be attached to')
param subnetPrivateEndpointId string = ''

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

param deploySlot bool

param deployAppPrivateEndPoint bool
param userAssignedIdentities array

// @description('The name of an existing keyvault, that it will be used to store secrets (connection string)' )
// param keyvaultName string


// @description('Deploy an azure app configuration, or not')
// param deployAppConfig bool

// var webAppDnsZoneName = 'privatelink.azurewebsites.net'
// var appConfigurationDnsZoneName = 'privatelink.azconfig.io'
var slotName = 'staging'

var spokeVNetIdTokens = split(spokeVNetId, '/')
var spokeSubscriptionId = spokeVNetIdTokens[2]
var spokeResourceGroupName = spokeVNetIdTokens[4]
var spokeVNetName = spokeVNetIdTokens[8]

// resource keyvault 'Microsoft.KeyVault/vaults@2022-11-01' existing = {
//   name: keyvaultName
// }

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
    siteConfigSelection:  (webAppBaseOs =~ 'linux') ? 'linuxNet9' : 'windowsNet9'
    hasPrivateLink: !empty (subnetPrivateEndpointId)
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
  }
}

module storageBlobPrivateNetwork '../../../shared/bicep/network/private-networking-spoke.bicep' = if(kind == 'functionapp') {
  name:take('rtsfnStorageBlobPrivateNetwork-${deployment().name}', 64)
  scope: resourceGroup(privateEndpointRG)
  params: {
    location: location
    azServicePrivateDnsZoneName: 'privatelink.blob.${environment().suffixes.storage}'
    azServiceId: fnstorage.outputs.id
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

module storageFilesPrivateNetwork '../../../shared/bicep/network/private-networking-spoke.bicep' = if(kind == 'functionapp') {
  name:take('rtsfnStorageFilePrivateNetwork-${deployment().name}', 64)
  scope: resourceGroup(privateEndpointRG)
  params: {
    location: location
    azServicePrivateDnsZoneName: 'privatelink.file.${environment().suffixes.storage}'
    azServiceId: fnstorage.outputs.id
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
  }
  dependsOn: [
    fnstorage
  ]
}

resource vnetSpoke 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  scope: resourceGroup(spokeSubscriptionId, spokeResourceGroupName)
  name: spokeVNetName
}

module webAppPrivateNetwork '../../../shared/bicep/network/private-networking-spoke.bicep' = if(deployAppPrivateEndPoint == true) {
  name:take('webAppPrivateNetwork-${deployment().name}', 64)
  scope: resourceGroup(privateEndpointRG)
  params: {
    location: location
    azServicePrivateDnsZoneName: 'privatelink.azurewebsites.net'
    azServiceId: kind == 'app' ? webApp.outputs.resourceId : fnApp.outputs.functionAppId
    privateEndpointName: kind == 'app' ? take('pep-${webApp.outputs.name}', 64) : take('pep-${fnApp.outputs.functionAppName}', 64)
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

// module webAppPrivateDnsZone '../../../shared/bicep/network/private-dns-zone.bicep' = if ( !empty(subnetPrivateEndpointId)) {
//   // conditional scope is not working: https://github.com/Azure/bicep/issues/7367
//   //scope: empty(vnetHubResourceId) ? resourceGroup() : resourceGroup(vnetHubSplitTokens[2], vnetHubSplitTokens[4]) 
//   scope: resourceGroup(privateEndpointRG)
//   name: take('${replace(webAppDnsZoneName, '.', '-')}-PrivateDnsZoneDeployment', 64)
//   params: {
//     name: webAppDnsZoneName
//     virtualNetworkLinks: virtualNetworkLinks
//     tags: tags
//   }
// }

// module pepWebApp '../../../shared/bicep/network/private-endpoint.bicep' = if ( !empty(subnetPrivateEndpointId)) {
//   name:  take('pep-${webAppName}-Deployment', 64)
//   scope: resourceGroup(privateEndpointRG)
//   params: {
//     name: take('pep-${webApp.outputs.name}', 64)
//     location: location
//     tags: tags
//     privateDnsZonesId: ( !empty(subnetPrivateEndpointId)) ? webAppPrivateDnsZone.outputs.privateDnsZonesId : ''
//     privateLinkServiceId: webApp.outputs.resourceId
//     snetId: subnetPrivateEndpointId
//     subresource: 'sites'
//   }
// }

// module peWebAppSlot '../../../shared/bicep/private-endpoint.bicep' = if ( !empty(subnetPrivateEndpointId) && !deployAseV3) {
//   name:  take('pe-${webAppName}-slot-${slotName}-Deployment', 64)
//   params: {
//     name: take('pe-${webAppName}-slot-${slotName}', 64)
//     location: location
//     tags: tags
//     privateDnsZonesId: ( !empty(subnetPrivateEndpointId) && !deployAseV3 ) ? webAppPrivateDnsZone.outputs.privateDnsZonesId : ''
//     privateLinkServiceId: webApp.outputs.resourceId
//     snetId: subnetPrivateEndpointId
//     subresource: 'sites-${slotName}'
//   }
// }

// module azConfigPrivateDnsZone '../../../shared/bicep/private-dns-zone.bicep' = if ( !empty(subnetPrivateEndpointId) && deployAppConfig ) {
//   // conditional scope is not working: https://github.com/Azure/bicep/issues/7367
//   //scope: empty(vnetHubResourceId) ? resourceGroup() : resourceGroup(vnetHubSplitTokens[2], vnetHubSplitTokens[4]) 
//   scope: resourceGroup(vnetHubSplitTokens[2], vnetHubSplitTokens[4])
//   name: take('${replace(appConfigurationDnsZoneName, '.', '-')}-PrivateDnsZoneDeployment', 64)
//   params: {
//     name: appConfigurationDnsZoneName
//     virtualNetworkLinks: virtualNetworkLinks
//     tags: tags
//   }
// }
// module peAzConfig '../../../shared/bicep/private-endpoint.bicep' = if ( !empty(subnetPrivateEndpointId)  && deployAppConfig) {
//   name: take('pe-${appConfigurationName}-Deployment', 64)
//   params: {
//     name: ( !empty(subnetPrivateEndpointId)  && deployAppConfig) ? 'pe-${appConfigStore.outputs.name}' : ''
//     location: location
//     tags: tags
//     privateDnsZonesId:  ( !empty(subnetPrivateEndpointId)  && deployAppConfig) ? azConfigPrivateDnsZone.outputs.privateDnsZonesId : ''
//     privateLinkServiceId: ( !empty(subnetPrivateEndpointId)  && deployAppConfig) ? appConfigStore.outputs.resourceId : ''
//     snetId: subnetPrivateEndpointId
//     subresource: 'configurationStores'
//   }
// }

// module webAppStagingSlotSystemIdentityOnAppConfigDataReader '../../../shared/bicep/role-assignments/role-assignment.bicep' = if ( deployAppConfig ) {
//   name: 'webAppStagingSlotSystemIdentityOnAppConfigDataReader-Deployment'
//   params: {
//     name: 'ra-webAppStagingSlotSystemIdentityOnAppConfigDataReader'
//     principalId: webAppUserAssignedManagedIdenity.outputs.principalId //webApp.outputs.slotSystemAssignedPrincipalIds[0]
//     resourceId: ( deployAppConfig ) ?  appConfigStore.outputs.resourceId : ''
//     roleDefinitionId: '516239f1-63e1-4d78-a4de-a74fb236a071'  //App Configuration Data Reader 
//   }
// }

// module webAppStagingSlotSystemIdentityOnKeyvaultSecretsUser '../../../shared/bicep/role-assignments/role-assignment.bicep' = {
//   name: 'webAppStagingSlotSystemIdentityOnKeyvaultSecretsUser-Deployment'
//   params: {
//     name: 'ra-webAppStagingSlotSystemIdentityOnKeyvaultSecretsUser'
//     principalId: webAppUserAssignedManagedIdenity.outputs.principalId // webApp.outputs.slotSystemAssignedPrincipalIds[0]
//     resourceId: keyvault.id
//     roleDefinitionId: '4633458b-17de-408a-b874-0445c86b69e6'  //Key Vault Secrets User   
//   }
// }


// output appConfigStoreName string =  deployAppConfig ? appConfigStore.outputs.name : ''
// output appConfigStoreId string = deployAppConfig ? appConfigStore.outputs.resourceId : ''
// output webAppName string = webApp.outputs.name
 output appHostName string = (kind == 'app') ? webApp.outputs.defaultHostname: fnApp.outputs.defaultHostName
// output webAppResourceId string = webApp.outputs.resourceId
// output webAppLocation string = webApp.outputs.location
// output webAppSystemAssignedPrincipalId string = webApp.outputs.systemAssignedPrincipalId

