targetScope = 'subscription'

// ------------------
//    PARAMETERS
// ------------------

@description('The environment name (e.g., dev, uat, prod)')
param environment string

@description('Replica SQL Server resource ID to create private endpoints for')
param replicaSqlServerResourceId string

@description('Replica SQL Server name (for private endpoint naming)')
param replicaSqlServerName string

@description('The DevBox subscription ID')
param devboxSubscriptionId string

@description('The DevBox resource group name')
param devboxResourceGroupName string

@description('The DevBox VNet name')
param devboxVNetName string

@description('The DevBox private endpoint subnet name')
param devboxPrivateEndpointSubnetName string

@description('Location for the private endpoints')
param location string = 'uksouth'

@description('Optional. Tags of the resource.')
param tags object = {}

// ------------------
//    VARIABLES
// ------------------

var privateEndpointNames = 'pep-devbox-${replicaSqlServerName}'

// ------------------
//    RESOURCES
// ------------------

resource devboxVNet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  scope: resourceGroup(devboxSubscriptionId, devboxResourceGroupName)
  name: devboxVNetName
}

resource devboxPrivateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {
  parent: devboxVNet
  name: devboxPrivateEndpointSubnetName
}

resource sqlPrivateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' existing = {
  scope: resourceGroup(devboxSubscriptionId, devboxResourceGroupName)
  name: 'privatelink${az.environment().suffixes.sqlServerHostname}'
}

module replicaSqlPrivateEndpoints '../../../shared/bicep/network/private-endpoint.bicep' = {
  name: take('replicaSqlPE-${environment}', 64)
  scope: resourceGroup(devboxSubscriptionId, devboxResourceGroupName)
  params: {
    location: location
    name: privateEndpointNames
    snetId: devboxPrivateEndpointSubnet.id
    privateLinkServiceId: replicaSqlServerResourceId
    subresource: 'sqlServer'
    privateDnsZonesId: sqlPrivateDnsZone.id
    tags: tags
  }
}

// ------------------
//    OUTPUTS
// ------------------

output privateEndpointNames string = privateEndpointNames

