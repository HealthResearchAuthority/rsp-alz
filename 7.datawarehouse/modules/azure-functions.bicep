targetScope = 'resourceGroup'

// --------------------
//    PARAMETERS
// --------------------

@description('The location where this resource will be created')
param location string = resourceGroup().location

@description('Optional. The tags to be assigned to created resources')
param tags object = {}

@description('The resource ID of the Vnet to which the private endpoint will be connected')
param spokeVNetId string

@description('The name of the subnet in the VNET to which the private endpoint will be connected')
param spokePrivateEndpointSubnetName string

@description('The name of the subnet for VNet integration')
param functionAppSubnetName string

@description('Client ID of the managed Identity to be used for the SQL DB connection string')
param sqlDBManagedIdentityClientId string = ''

@description('The resource id of an existing Azure Log Analytics Workspace')
param logAnalyticsWorkspaceId string

@description('Array of user assigned identity resource IDs')
param userAssignedIdentities array = []

@description('Environment name (dev, prod)')
param environment string = 'dev'

@description('Defines the name, tier, size, family and capacity of the App Service Plan. Plans ending to _AZ, are deploying at least three instances in three Availability Zones. EP* is only for functions')
@allowed([ 'B1','S1', 'S2', 'S3', 'P1V3', 'P2V3', 'P3V3', 'P1V3_AZ', 'P2V3_AZ', 'P3V3_AZ', 'EP1', 'EP2', 'EP3', 'ASE_I1V2_AZ', 'ASE_I2V2_AZ', 'ASE_I3V2_AZ', 'ASE_I1V2', 'ASE_I2V2', 'ASE_I3V2' ])
param sku string

// --------------------
//    VARIABLES
// --------------------

var spokeVNetIdTokens = split(spokeVNetId, '/')
var spokeSubscriptionId = spokeVNetIdTokens[2]
var spokeResourceGroupName = spokeVNetIdTokens[4]
var spokeVNetName = spokeVNetIdTokens[8]
var networkAcls = {
  defaultAction: 'Deny'
  bypass: 'AzureServices'
  virtualNetworkRules: [
    {
      id: functionAppSubnet.id
      action: 'Allow'
    }
  ]
}

var functionApps = [
  {
    name: 'func-harp-data-sync'
    storageAccountName: 'stharpdatasync${environment}'
    appServicePlanName: 'asp-harp-data-sync-uks'
  }
  {
    name: 'func-validate-irasid'
    storageAccountName: 'stvalidateirasid${environment}'
    appServicePlanName: 'asp-validate-irasid-uks'
  }
]


// ---------------
//    RESOURCES
// ---------------

resource vnetSpoke 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  scope: resourceGroup(spokeSubscriptionId, spokeResourceGroupName)
  name: spokeVNetName
}

resource spokePrivateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' existing = {
  parent: vnetSpoke
  name: spokePrivateEndpointSubnetName
}

resource functionAppSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' existing = {
  parent: vnetSpoke
  name: functionAppSubnetName
}

module appInsights '../../shared/bicep/app-insights.bicep' = {
  name: 'appInsights-harp-functions'
  params: {
    name: 'appi-harp-functions-${environment}'
    location: location
    tags: tags
    workspaceResourceId: logAnalyticsWorkspaceId
  }
}

module appServicePlans '../../shared/bicep/app-services/app-service-plan.bicep' = [for (funcApp, index) in functionApps: {
  name: 'appServicePlan-${funcApp.name}'
  params: {
    name: funcApp.appServicePlanName
    location: location
    tags: tags
    sku: sku
    serverOS: 'Windows'
    diagnosticWorkspaceId: logAnalyticsWorkspaceId
  }
}]

module blobPrivateDnsZone '../../shared/bicep/network/private-dns-zone.bicep' = {
  name: 'blobPrivateDnsZone'
  params: {
    name: 'privatelink.blob.${az.environment().suffixes.storage}'
    virtualNetworkLinks: [
      {
        vnetName: spokeVNetName
        vnetId: vnetSpoke.id
        registrationEnabled: false
      }
    ]
  }
}

module filePrivateDnsZone '../../shared/bicep/network/private-dns-zone.bicep' = {
  name: 'filePrivateDnsZone'
  params: {
    name: 'privatelink.file.${az.environment().suffixes.storage}'
    virtualNetworkLinks: [
      {
        vnetName: spokeVNetName
        vnetId: vnetSpoke.id
        registrationEnabled: false
      }
    ]
  }
}

module functionAppPrivateDnsZone '../../shared/bicep/network/private-dns-zone.bicep' = {
  name: 'functionAppPrivateDnsZone'
  params: {
    name: 'privatelink.azurewebsites.net'
    virtualNetworkLinks: [
      {
        vnetName: spokeVNetName
        vnetId: vnetSpoke.id
        registrationEnabled: false
      }
    ]
  }
}

module fnstorage '../../shared/bicep/storage/storage.bicep' = [for (funcApp, index) in functionApps:{
  name: 'storage-${funcApp.name}'
  params: {
    name: funcApp.storageAccountName
    location: location
    sku: 'Standard_LRS'
    kind: 'StorageV2'
    supportsHttpsTrafficOnly: true
    tags: {}
    networkAcls: networkAcls 
  }
}]

module storageBlobPrivateNetwork '../../shared/bicep/network/private-networking-spoke.bicep' = [for (funcApp, index) in functionApps: {
  name:'storageBlobPE-${funcApp.name}'
  params: {
    location: location
    azServicePrivateDnsZoneName: 'privatelink.blob.${az.environment().suffixes.storage}'
    azServiceId: fnstorage[index].outputs.id
    privateEndpointName: 'pep-${funcApp.storageAccountName}-blob'
    privateEndpointSubResourceName: 'blob'
    virtualNetworkLinks: [
      {
        vnetName: spokeVNetName
        vnetId: vnetSpoke.id
        registrationEnabled: false
      }
    ]
    subnetId: spokePrivateEndpointSubnet.id
  }
}]

module storageFilesPrivateNetwork '../../shared/bicep/network/private-networking-spoke.bicep' = [for (funcApp, index) in functionApps: {
  name:'storageFilePE-${funcApp.name}'
  params: {
    location: location
    azServicePrivateDnsZoneName: 'privatelink.file.${az.environment().suffixes.storage}'
    azServiceId: fnstorage[index].outputs.id
    privateEndpointName: 'pep-${funcApp.storageAccountName}-file'
    privateEndpointSubResourceName: 'file'
    virtualNetworkLinks: [
      {
        vnetName: spokeVNetName
        vnetId: vnetSpoke.id
        registrationEnabled: false
      }
    ]
    subnetId: spokePrivateEndpointSubnet.id
  }
  dependsOn: [
    storageBlobPrivateNetwork
  ]
}]

module fnApp '../../shared/bicep/app-services/function-app.bicep' = [for (funcApp, index) in functionApps: {
  name: 'functionApp-${funcApp.name}'
  params: {
    kind: 'functionapp'
    functionAppName:  funcApp.name
    location: location
    serverFarmResourceId: appServicePlans[index].outputs.resourceId
    hasPrivateEndpoint: true
    virtualNetworkSubnetId: functionAppSubnet.id
    appInsightId: appInsights.outputs.appInsResourceId
    userAssignedIdentities:  {
      type: 'UserAssigned'
      userAssignedIdentities: reduce(userAssignedIdentities, {}, (result, id) => union(result, { '${id}': {} }))
    }
    storageAccountName: funcApp.storageAccountName
    sqlDBManagedIdentityClientId: sqlDBManagedIdentityClientId
  }
  dependsOn: [
    fnstorage
  ]
}]

// module functionAppPrivateEndpoints '../../shared/bicep/network/private-endpoint.bicep' = [for (funcApp, index) in functionApps: {
//   name: 'funcAppPE-${funcApp.name}'
//   params: {
//     location: location
//     name: 'pep-${funcApp.name}'
//     snetId: spokePrivateEndpointSubnet.id
//     privateLinkServiceId: fnApp[index].outputs.functionAppId
//     subresource: 'sites'
//     privateDnsZonesId: functionAppPrivateDnsZone.outputs.privateDnsZonesId
//     tags: tags
//   }
//   dependsOn: [
//     storageBlobPrivateNetwork
//     storageFilesPrivateNetwork
//   ]
// }]

// Private endpoint for App Service/Function App using existing private-networking-spoke module
module appServicePrivateEndpoint '../../shared/bicep/network/private-networking-spoke.bicep' = [for (funcApp, index) in functionApps: {
  name: 'funcAppPE-${funcApp.name}'
  params: {
    location: location
    azServicePrivateDnsZoneName: 'privatelink.azurewebsites.net'
    azServiceId: fnApp[index].outputs.functionAppId
    privateEndpointName: 'pep-${funcApp.name}'
    privateEndpointSubResourceName: 'sites'
    virtualNetworkLinks: [
      {
        vnetName: spokeVNetName
        vnetId: vnetSpoke.id
        registrationEnabled: false
      }
    ]
    subnetId: spokePrivateEndpointSubnet.id
  }
}]

// Outputs
output functionAppNames array = [for (funcApp, index) in functionApps: {
  name: funcApp.name
  id: fnApp[index].outputs.functionAppId
  defaultHostName: fnApp[index].outputs.defaultHostName
}]

output storageAccountNames array = [for (funcApp, index) in functionApps: {
  name: funcApp.storageAccountName
  id: fnstorage[index].outputs.id
}]

output appServicePlanNames array = [for (funcApp, index) in functionApps: {
  name: funcApp.appServicePlanName
  id: appServicePlans[index].outputs.resourceId
}]
