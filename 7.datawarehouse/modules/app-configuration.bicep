targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------

@description('Specifies the name of the App Configuration store.')
param configStoreName string

@description('Specifies the Azure location where the app configuration store should be created.')
param location string = resourceGroup().location

@description('Adds tags for the key-value resources. It\'s optional')
param tags object = {}

@description('Name of the user-assigned managed identity for App Configuration access')
param appConfigurationUserAssignedIdentityName string = ''

@description('SQL Server name for connection strings')
param sqlServerName string

@description('The resource ID of the VNet to which the private endpoint will be connected.')
param spokeVNetId string

@description('The name of the subnet in the VNet to which the private endpoint will be connected.')
param spokePrivateEndpointSubnetName string

@description('Enable private endpoints for App Configuration')
param enablePrivateEndpoints bool = false

@description('RTS Timer Schedule for the function app')
param rtsTimerSchedule string = '0 */5 * * * *'

@description('HARP Database name')
param harpDatabaseName string = 'harpprojectdata'

// ------------------
//    VARIABLES
// ------------------

var spokeVNetIdTokens = split(spokeVNetId, '/')
var spokeSubscriptionId = spokeVNetIdTokens[2]
var spokeResourceGroupName = spokeVNetIdTokens[4]
var spokeVNetName = spokeVNetIdTokens[8]

var keyValues = [
  {
    name: 'RtsTimerSchedule'
    value: rtsTimerSchedule
    contentType: null
  }
  {
    name: 'ConnectionStrings:HarpDatabaseConnection'
    value: 'Server=tcp:${sqlServerName}${az.environment().suffixes.sqlServerHostname},1433;Database=${harpDatabaseName};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;Authentication=\'Active Directory Default\';'
    contentType: null
  }
]

// ------------------
//    RESOURCES
// ------------------

resource vnetSpoke 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  scope: resourceGroup(spokeSubscriptionId, spokeResourceGroupName)
  name: spokeVNetName
}

resource spokePrivateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' existing = {
  parent: vnetSpoke
  name: spokePrivateEndpointSubnetName
}

@description('User-assigned managed identity for App Configuration access')
resource appConfigurationUserAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: appConfigurationUserAssignedIdentityName
  location: location
  tags: tags
}

@description('App Configuration store for HARP functions')
resource configStore 'Microsoft.AppConfiguration/configurationStores@2024-05-01' = {
  name: configStoreName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    disableLocalAuth: true
    enablePurgeProtection: false
    publicNetworkAccess: enablePrivateEndpoints ? 'Disabled' : 'Enabled'
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${appConfigurationUserAssignedIdentity.id}': {}
    }
  }
}

@description('Key-value pairs in the App Configuration store')
resource configStoreKeyValue 'Microsoft.AppConfiguration/configurationStores/keyValues@2023-03-01' = [for keyValue in keyValues: {
  parent: configStore
  name: keyValue.name
  properties: {
    value: keyValue.value
    contentType: keyValue.contentType
  }
}]

@description('Role assignment for the managed identity to access App Configuration')
resource appConfigDataReaderRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(configStore.id, appConfigurationUserAssignedIdentity.id, 'App Configuration Data Reader')
  scope: configStore
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '516239f1-63e1-4d78-a4de-a74fb236a071') // App Configuration Data Reader
    principalId: appConfigurationUserAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

@description('Private DNS zone for App Configuration')
module appConfigPrivateDnsZone '../../shared/bicep/network/private-dns-zone.bicep' = if (enablePrivateEndpoints) {
  name: 'appConfigPrivateDnsZone'
  params: {
    name: 'privatelink.azconfig.io'
    virtualNetworkLinks: [
      {
        vnetName: spokeVNetName
        vnetId: vnetSpoke.id
        registrationEnabled: false
      }
    ]
  }
}

@description('Private endpoint for App Configuration')
module appConfigPrivateEndpoint '../../shared/bicep/network/private-endpoint.bicep' = if (enablePrivateEndpoints) {
  name: 'appConfigPrivateEndpoint'
  params: {
    location: location
    name: 'pep-${configStoreName}'
    snetId: spokePrivateEndpointSubnet.id
    privateLinkServiceId: configStore.id
    subresource: 'configurationStores'
    privateDnsZonesId: appConfigPrivateDnsZone.outputs.privateDnsZonesId
    tags: tags
  }
}

// ------------------
//    OUTPUTS
// ------------------

@description('The resource ID of the user assigned managed identity for the App Configuration to be able to read configurations from it.')
output appConfigurationUserAssignedIdentityId string = appConfigurationUserAssignedIdentity.id

@description('The principal ID of the user assigned managed identity for the App Configuration.')
output appConfigurationUserAssignedIdentityPrincipalId string = appConfigurationUserAssignedIdentity.properties.principalId

@description('The endpoint URL of the App Configuration store')
output appConfigURL string = configStore.properties.endpoint

@description('The client ID of the managed identity for App Configuration access')
output appConfigMIClientID string = appConfigurationUserAssignedIdentity.properties.clientId

@description('The resource ID of the App Configuration store')
output configStoreId string = configStore.id

@description('The name of the App Configuration store')
output configStoreName string = configStore.name
