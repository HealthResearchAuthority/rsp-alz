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

module storageAccounts '../../shared/bicep/storage/storage.bicep' = [for (funcApp, index) in functionApps: {
  name: 'storage-${funcApp.name}'
  params: {
    name: funcApp.storageAccountName
    location: location
    sku: 'Standard_LRS'
    kind: 'StorageV2'
    supportsHttpsTrafficOnly: true
    tags: tags
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: functionAppSubnet.id
          action: 'Allow'
        }
      ]
    }
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

module storageBlobPrivateEndpoints '../../shared/bicep/network/private-endpoint.bicep' = [for (funcApp, index) in functionApps: {
  name: 'storageBlobPE-${funcApp.name}'
  params: {
    location: location
    name: 'pep-${funcApp.storageAccountName}-blob'
    snetId: spokePrivateEndpointSubnet.id
    privateLinkServiceId: storageAccounts[index].outputs.id
    subresource: 'blob'
    privateDnsZonesId: blobPrivateDnsZone.outputs.privateDnsZonesId
    tags: tags
  }
}]

module storageFilePrivateEndpoints '../../shared/bicep/network/private-endpoint.bicep' = [for (funcApp, index) in functionApps: {
  name: 'storageFilePE-${funcApp.name}'
  params: {
    location: location
    name: 'pep-${funcApp.storageAccountName}-file'
    snetId: spokePrivateEndpointSubnet.id
    privateLinkServiceId: storageAccounts[index].outputs.id
    subresource: 'file'
    privateDnsZonesId: blobPrivateDnsZone.outputs.privateDnsZonesId
    tags: tags
  }
  dependsOn: [
    storageBlobPrivateEndpoints
  ]
}]

// Function Apps
module functionAppsDeployment '../../shared/bicep/app-services/function-app.bicep' = [for (funcApp, index) in functionApps:{
  name: 'functionApp-${funcApp.name}'
  params: {
    functionAppName: funcApp.name
    location: location
    tags: tags
    serverFarmResourceId: appServicePlans[index].outputs.resourceId
    hasPrivateEndpoint: true
    sqlDBManagedIdentityClientId: sqlDBManagedIdentityClientId
    storageAccountName: funcApp.storageAccountName
    userAssignedIdentities: length(userAssignedIdentities) > 0 ? {
      type: 'UserAssigned'
      userAssignedIdentities: reduce(userAssignedIdentities, {}, (result, id) => union(result, { '${id}': {} }))
    } : {
      type: 'SystemAssigned'
    }
    appInsightId: appInsights.outputs.appInsResourceId
    kind: 'functionapp'
    virtualNetworkSubnetId: functionAppSubnet.id
  }
  dependsOn:  [
    storageAccounts
  ]
}]

module functionAppPrivateEndpoints '../../shared/bicep/network/private-endpoint.bicep' = [for (funcApp, index) in functionApps: {
  name: 'funcAppPE-${funcApp.name}'
  params: {
    location: location
    name: 'pep-${funcApp.name}'
    snetId: spokePrivateEndpointSubnet.id
    privateLinkServiceId: functionAppsDeployment[index].outputs.functionAppId
    subresource: 'sites'
    privateDnsZonesId: functionAppPrivateDnsZone.outputs.privateDnsZonesId
    tags: tags
  }
  dependsOn: [
    storageBlobPrivateEndpoints
    storageFilePrivateEndpoints
  ]
}]

// Outputs
output functionAppNames array = [for (funcApp, index) in functionApps: {
  name: funcApp.name
  id: functionAppsDeployment[index].outputs.functionAppId
  defaultHostName: functionAppsDeployment[index].outputs.defaultHostName
}]

output storageAccountNames array = [for (funcApp, index) in functionApps: {
  name: funcApp.storageAccountName
  id: storageAccounts[index].outputs.id
}]

output appServicePlanNames array = [for (funcApp, index) in functionApps: {
  name: funcApp.appServicePlanName
  id: appServicePlans[index].outputs.resourceId
}]

output functionAppResourceIds array = [for (funcApp, index) in functionApps: functionAppsDeployment[index].outputs.functionAppId]

output storageAccountResourceIds array = [for (funcApp, index) in functionApps: storageAccounts[index].outputs.id]

output storageAccountNamesArray array = [for (funcApp, index) in functionApps: funcApp.storageAccountName]
