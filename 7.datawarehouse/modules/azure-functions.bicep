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
    storageAccountName: 'stharpdatasync${environment}${substring(uniqueString(resourceGroup().id, 'harpdatasync'), 0, 6)}'
    appServicePlanName: 'asp-harp-data-sync-uks'
  }
  {
    name: 'func-validate-irasid'
    storageAccountName: 'stvalidateirasid${environment}${substring(uniqueString(resourceGroup().id, 'validateirasid'), 0, 6)}'
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
    sku: 'EP1'
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

module storageBlobPrivateEndpoints '../../shared/bicep/network/private-networking-spoke.bicep' = [for (funcApp, index) in functionApps: {
  name: 'storageBlobPE-${funcApp.name}'
  params: {
    location: location
    azServicePrivateDnsZoneName: 'privatelink.blob.${az.environment().suffixes.storage}'
    azServiceId: storageAccounts[index].outputs.id
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

module storageFilePrivateEndpoints '../../shared/bicep/network/private-networking-spoke.bicep' = [for (funcApp, index) in functionApps: {
  name: 'storageFilePE-${funcApp.name}'
  params: {
    location: location
    azServicePrivateDnsZoneName: 'privatelink.file.${az.environment().suffixes.storage}'
    azServiceId: storageAccounts[index].outputs.id
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
    runtime: 'dotnet-isolated'
    runtimeVersion: '~4'
    dotnetVersion: '9.0'
    userAssignedIdentities: {
      type: 'UserAssigned'
      userAssignedIdentities: reduce(userAssignedIdentities, {}, (result, id) => union(result, { '${id}': {} }))
    }
    appInsightId: appInsights.outputs.appInsResourceId
    kind: 'functionapp'
    virtualNetworkSubnetId: functionAppSubnet.id
    appSettings: concat([
      {
        name: 'FUNCTIONS_WORKER_RUNTIME'
        value: 'dotnet-isolated'
      }
      {
        name: 'FUNCTIONS_EXTENSION_VERSION'
        value: '~4'
      }
    ], !empty(sqlDBManagedIdentityClientId) ? [
      {
        name: 'AZURE_CLIENT_ID'
        value: sqlDBManagedIdentityClientId
      }
    ] : [])
  }
  dependsOn:  [
    storageAccounts
    storageBlobPrivateEndpoints
    storageFilePrivateEndpoints
  ]
}]

module functionAppPrivateEndpoints '../../shared/bicep/network/private-networking-spoke.bicep' = [for (funcApp, index) in functionApps: {
  name: 'functionAppPE-${funcApp.name}'
  params: {
    location: location
    azServicePrivateDnsZoneName: 'privatelink.azurewebsites.net'
    azServiceId: functionAppsDeployment[index].outputs.functionAppId
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
  dependsOn: [
    storageBlobPrivateEndpoints
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
