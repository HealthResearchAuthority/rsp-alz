targetScope = 'subscription'

// ------------------
//    PARAMETERS
// ------------------

@description('The environment name (e.g., dev, uat, prod)')
param environment string

@description('Array of replica SQL Server resource IDs to create private endpoints for')
param replicaSqlServerResourceIds array

@description('Array of replica SQL Server names (for private endpoint naming)')
param replicaSqlServerNames array

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

var privateEndpointNames = [for i in range(0, length(replicaSqlServerNames)): 'pep-devbox-${replicaSqlServerNames[i]}']

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

// Private endpoints for replica SQL servers
// Using @batchSize(1) to avoid deployment conflicts when creating multiple private endpoints
@batchSize(1)
module replicaSqlPrivateEndpoints '../../../shared/bicep/network/private-endpoint.bicep' = [for i in range(0, length(replicaSqlServerResourceIds)): {
  name: take('replicaSqlPE-${environment}-${i}', 64)
  scope: resourceGroup(devboxSubscriptionId, devboxResourceGroupName)
  params: {
    location: location
    name: privateEndpointNames[i]
    snetId: devboxPrivateEndpointSubnet.id
    privateLinkServiceId: replicaSqlServerResourceIds[i]
    subresource: 'sqlServer'
    privateDnsZonesId: sqlPrivateDnsZone.id
    tags: tags
  }
}]

// ------------------
//    OUTPUTS
// ------------------

output privateEndpointNames array = privateEndpointNames

