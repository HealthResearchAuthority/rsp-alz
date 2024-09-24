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

param appConfigurationUserUserAssignedIdentityName string = ''
param sqlServerName string

param networkingResourcesNames object
param networkingResourceGroup string

@description('The resource ID of the VNet to which the private endpoint will be connected.')
param spokeVNetId string

@description('The name of the subnet in the VNet to which the private endpoint will be connected.')
param spokePrivateEndpointSubnetName string

@description('JWKS URi for backend services to validate a request')
param jwksURI string

var appConfigurationDataReaderRoleGUID = '516239f1-63e1-4d78-a4de-a74fb236a071'

var keyvalues = [
  {
    name: 'AppSettings:AuthSettings:Authority'
    value: 'https://dev.id.nihr.ac.uk:443/oauth2/token'
  }
  {
    name: 'AppSettings:AuthSettings:ClientId'
    value: 'Uf6CKXOECh6zhzgtdlfsrnhbzXca'
  }
  {
    name: 'AppSettings:AuthSettings:JwksUri'
    value: '${jwksURI}/jwks'
  }
  {
    name: 'ConnectionStrings:IrasServiceDatabaseConnection'
    value: 'Server=tcp:${sqlServerName}${az.environment().suffixes.sqlServerHostname},1433;Database=applicationservice;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;Authentication=\'Active Directory Default\';'
  }
  {
    name: 'ConnectionStrings:IdentityDbConnection'
    value: 'Server=tcp:${sqlServerName}${az.environment().suffixes.sqlServerHostname},1433;Database=identityservice;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;Authentication=\'Active Directory Default\';'
  }
]

var privateDnsZoneNames = 'privatelink.azconfig.io'
var appConfigResourceName = 'configurationStores'

var spokeVNetIdTokens = split(spokeVNetId, '/')
var spokeSubscriptionId = spokeVNetIdTokens[2]
var spokeResourceGroupName = spokeVNetIdTokens[4]
var spokeVNetName = spokeVNetIdTokens[8]

var spokeVNetLinks = [
  {
    vnetName: spokeVNetName
    vnetId: vnetSpoke.id
    registrationEnabled: false
  }
  // {
  //   vnetName: vnetHub.name
  //   vnetId: vnetHub.id
  //   registrationEnabled: false
  // }
]

resource vnetSpoke 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  scope: resourceGroup(spokeSubscriptionId, spokeResourceGroupName)
  name: spokeVNetName
}

resource spokePrivateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' existing = {
  parent: vnetSpoke
  name: spokePrivateEndpointSubnetName
}

resource appConfigurationUserAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: appConfigurationUserUserAssignedIdentityName
  location: location
  tags: tags
}

resource configStore 'Microsoft.AppConfiguration/configurationStores@2023-03-01' = {
  name: configStoreName
  location: location
  sku: {
    name: 'standard'
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${appConfigurationUserAssignedIdentity.id}': {}
    }
  }
}

module appConfigurationDataReaderAssignment '../../../../shared/bicep/role-assignments/role-assignment.bicep' = {
  name: take('appConfigurationDataReaderAssignmentDeployment-${deployment().name}', 64)
  params: {
    name: 'ra-appConfigurationDataReaderRoleAssignment'
    principalId: appConfigurationUserAssignedIdentity.properties.principalId
    resourceId: configStore.id
    roleDefinitionId: appConfigurationDataReaderRoleGUID
    principalType: 'ServicePrincipal'
  }
}

resource configStoreKeyValue 'Microsoft.AppConfiguration/configurationStores/keyValues@2021-10-01-preview' = [for keyValue in keyvalues: {
  parent: configStore
  name: keyValue.name
  properties: {
    value: keyValue.value
  }
}]

module appConfigNetwork '../../../../shared/bicep/network/private-networking-spoke.bicep' = {
  name: 'appConfigNetwork-${uniqueString(configStore.id)}'
  scope: resourceGroup(networkingResourceGroup)
  params: {
    location: location
    azServicePrivateDnsZoneName: privateDnsZoneNames
    azServiceId: configStore.id
    privateEndpointName: networkingResourcesNames.azureappconfigurationstorepep
    privateEndpointSubResourceName: appConfigResourceName
    virtualNetworkLinks: spokeVNetLinks
    subnetId: spokePrivateEndpointSubnet.id
  }
}

@description('The resource ID of the user assigned managed identity for the App Configuration to be able to read configurations from it.')
output appConfigurationUserAssignedIdentityId string = appConfigurationUserAssignedIdentity.id

output appConfigURL string = configStore.properties.endpoint
output appConfigMIClientID string = appConfigurationUserAssignedIdentity.properties.clientId
