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
@maxLength(8)
param environment string

@description('The name of the workload that is being deployed. Up to 10 characters long.')
@minLength(2)
@maxLength(10)
param workloadName string

@description('The resource ID of the VNet to which the private endpoint will be connected.')
param spokeVNetId string

@description('The name of the subnet in the VNet to which the private endpoint will be connected.')
param spokePrivateEndpointSubnetName string

@description('The resource ID of the Hub Virtual Network.')
param hubVNetId string

// ------------------
// VARIABLES
// ------------------

var privateDnsZoneNames = '${environment}.privatelink${az.environment().suffixes.sqlServerHostname}'
var sqlServerResourceName = 'sqlServer'

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

@description('User-configured naming rules')
module naming '../../../shared/bicep/naming/naming.module.bicep' = {
  name: take('03-sharedNamingDeployment-${deployment().name}', 64)
  params: {
    uniqueId: uniqueString(resourceGroup().id)
    environment: environment
    workloadName: workloadName
    location: location
  }
}

// SQL Server Resource
resource SQL_Server_windowsauth_reset 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administrators: {
      azureADOnlyAuthentication: true
    }
  }
}

// SQL Server Resource
resource SQL_Server 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: adminLogin
    administratorLoginPassword: adminPassword
    publicNetworkAccess: 'Disabled'
    administrators: {
      administratorType:'ActiveDirectory'
      login: 'nikhil.bharathesh_PA@hra.nhs.uk'
      sid: '9a3eae88-0bf5-41d8-8791-92ddfe098a0b'
      tenantId: '8e1f0aca-d87d-4f20-939e-36243d574267'
      azureADOnlyAuthentication: true
      principalType: 'User'
    }
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
  params: {
    location: location
    azServicePrivateDnsZoneName: privateDnsZoneNames
    azServiceId: SQL_Server.id
    privateEndpointName: naming.outputs.resourcesNames.azuresqlserverpep
    privateEndpointSubResourceName: sqlServerResourceName
    virtualNetworkLinks: spokeVNetLinks
    subnetId: spokePrivateEndpointSubnet.id
    vnetHubResourceId: hubVNetId
  }
}

// Outputs
output sqlServer_name string = SQL_Server.name

output database_names array = [for i in range(0, length(databases)): {
  id: database[i].name
}]
