targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------

param sqlServerName string = 'sql-rsp-dev-uks'
param adminLogin string = ''
@secure()
param adminPassword string

param databases array = []

@description('The location where the resources will be created.')
param location string = resourceGroup().location

@description('The name of the environment (e.g. "dev", "test", "prod", "uat", "dr", "qa"). Up to 8 characters long.')
@maxLength(12)
param environment string

@description('The resource ID of the VNet to which the private endpoint will be connected.')
param spokeVNetId string

@description('The name of the subnet in the VNet to which the private endpoint will be connected.')
param spokePrivateEndpointSubnetName string

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

param sqlServerUAIName string = ''

param networkingResourcesNames object
param networkingResourceGroup string

// ------------------
// VARIABLES
// ------------------

var privateDnsZoneNames = 'privatelink${az.environment().suffixes.sqlServerHostname}'
var sqlServerResourceName = 'sqlServer'

var spokeVNetIdTokens = split(spokeVNetId, '/')
var spokeSubscriptionId = spokeVNetIdTokens[2]
var spokeResourceGroupName = spokeVNetIdTokens[4]
var spokeVNetName = spokeVNetIdTokens[8]

var sqlServerContributorRoleGuid='9b7fa17d-e63e-47b0-bb0a-15c516ac86ec'

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

// ------------------
//    Resources
// ------------------

resource vnetSpoke 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  scope: resourceGroup(spokeSubscriptionId, spokeResourceGroupName)
  name: spokeVNetName
}

resource spokePrivateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' existing = {
  parent: vnetSpoke
  name: spokePrivateEndpointSubnetName
}

resource sqlServerUserAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: sqlServerUAIName
  location: location
  tags: tags
}

// SQL Server Resource
resource SQL_Server 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: sqlServerName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${sqlServerUserAssignedIdentity.id}': {}  
    }
  }
  properties: {
    administratorLogin: adminLogin
    administratorLoginPassword: adminPassword
    publicNetworkAccess: 'Disabled'
    administrators: {
      administratorType:'ActiveDirectory'
      login: 'nikhil.bharathesh_PA@hra.nhs.uk'
      sid: '9a3eae88-0bf5-41d8-8791-92ddfe098a0b'
      tenantId: '8e1f0aca-d87d-4f20-939e-36243d574267'
      azureADOnlyAuthentication: false
      principalType: 'User'
    }
    primaryUserAssignedIdentityId: sqlServerUserAssignedIdentity.id
  }
}

module sqlserveradminRoleAssignment '../../../shared/bicep/role-assignments/role-assignment.bicep' = {
  name: take('sqlServerContributorRoleAssignmentDeployment-${deployment().name}', 64)
  params: {
    name: 'ra-sqlServerContributorRoleAssignment'
    principalId: sqlServerUserAssignedIdentity.properties.principalId
    resourceId: SQL_Server.id
    roleDefinitionId: sqlServerContributorRoleGuid
    principalType: 'ServicePrincipal'
  }
}

// Database on SQL Server Resource
resource database 'Microsoft.Sql/servers/databases@2023-05-01-preview' = [for i in range(0, length(databases)): {
  name: databases[i]
  parent: SQL_Server
  location: location
  sku: {
    name: environment == 'dev' || environment == 'test' ? 'basic': 'standard'
    tier: environment == 'dev' || environment == 'test' ? 'basic': 'standard'
  }
  properties: {
    zoneRedundant: false
  }
}]

module sqlServerNetwork '../../../shared/bicep/network/private-networking-spoke.bicep' = {
  name: 'sqlServerNetwork-${uniqueString(SQL_Server.id)}'
  scope: resourceGroup(networkingResourceGroup)
  params: {
    location: location
    azServicePrivateDnsZoneName: privateDnsZoneNames
    azServiceId: SQL_Server.id
    privateEndpointName: networkingResourcesNames.azuresqlserverpep
    privateEndpointSubResourceName: sqlServerResourceName
    virtualNetworkLinks: spokeVNetLinks
    subnetId: spokePrivateEndpointSubnet.id
    //vnetSpokeResourceId: spokeVNetId
  }
}

// Outputs
output sqlServer_name string = SQL_Server.name
output outputsqlServerUAIID string = sqlServerUserAssignedIdentity.id
output outputsqlServerUAIName string = sqlServerUserAssignedIdentity.name

output database_names array = [for i in range(0, length(databases)): {
  id: database[i].name
}]
