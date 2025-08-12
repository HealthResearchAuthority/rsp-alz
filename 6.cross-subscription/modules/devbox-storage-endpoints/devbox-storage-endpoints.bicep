targetScope = 'subscription'

// ------------------
//    PARAMETERS
// ------------------

@description('The environment name (e.g., dev, uat, prod)')
param environment string

@description('The subscription ID where storage accounts are located')
param storageSubscriptionId string

@description('The resource group name where storage accounts are located')
param storageResourceGroupName string

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

// ------------------
//    VARIABLES
// ------------------

// Storage account names following the project naming convention
var storageAccounts = {
  clean: 'strspclean${environment}'
  staging: 'strspstagng${environment}'
  quarantine: 'strspquar${environment}'
}

// Private endpoint names following the existing pattern
var privateEndpointNames = {
  clean: 'pep-devbox-strspclean-${environment}'
  staging: 'pep-devbox-strspstagng-${environment}'
  quarantine: 'pep-devbox-strspquar-${environment}'
}

// Storage account resource IDs
var storageAccountResourceIds = {
  clean: '/subscriptions/${storageSubscriptionId}/resourceGroups/${storageResourceGroupName}/providers/Microsoft.Storage/storageAccounts/${storageAccounts.clean}'
  staging: '/subscriptions/${storageSubscriptionId}/resourceGroups/${storageResourceGroupName}/providers/Microsoft.Storage/storageAccounts/${storageAccounts.staging}'
  quarantine: '/subscriptions/${storageSubscriptionId}/resourceGroups/${storageResourceGroupName}/providers/Microsoft.Storage/storageAccounts/${storageAccounts.quarantine}'
}

// ------------------
//    RESOURCES
// ------------------

// Reference to DevBox VNet
resource devboxVNet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  scope: resourceGroup(devboxSubscriptionId, devboxResourceGroupName)
  name: devboxVNetName
}

// Reference to DevBox private endpoint subnet
resource devboxPrivateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {
  parent: devboxVNet
  name: devboxPrivateEndpointSubnetName
}

// Reference to existing private DNS zone for blob storage
resource blobPrivateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' existing = {
  scope: resourceGroup(devboxSubscriptionId, devboxResourceGroupName)
  name: 'privatelink.blob.${az.environment().suffixes.storage}'
}

// Private endpoint for clean storage account using existing private-endpoint module
module cleanStoragePrivateEndpoint '../../../shared/bicep/network/private-endpoint.bicep' = {
  name: take('cleanStoragePE-${environment}', 64)
  scope: resourceGroup(devboxSubscriptionId, devboxResourceGroupName)
  params: {
    location: location
    name: privateEndpointNames.clean
    snetId: devboxPrivateEndpointSubnet.id
    privateLinkServiceId: storageAccountResourceIds.clean
    subresource: 'blob'
    privateDnsZonesId: blobPrivateDnsZone.id
  }
}

// Private endpoint for staging storage account using existing private-endpoint module
module stagingStoragePrivateEndpoint '../../../shared/bicep/network/private-endpoint.bicep' = {
  name: take('stagingStoragePE-${environment}', 64)
  scope: resourceGroup(devboxSubscriptionId, devboxResourceGroupName)
  params: {
    location: location
    name: privateEndpointNames.staging
    snetId: devboxPrivateEndpointSubnet.id
    privateLinkServiceId: storageAccountResourceIds.staging
    subresource: 'blob'
    privateDnsZonesId: blobPrivateDnsZone.id
  }
}

// Private endpoint for quarantine storage account using existing private-endpoint module
module quarantineStoragePrivateEndpoint '../../../shared/bicep/network/private-endpoint.bicep' = {
  name: take('quarantineStoragePE-${environment}', 64)
  scope: resourceGroup(devboxSubscriptionId, devboxResourceGroupName)
  params: {
    location: location
    name: privateEndpointNames.quarantine
    snetId: devboxPrivateEndpointSubnet.id
    privateLinkServiceId: storageAccountResourceIds.quarantine
    subresource: 'blob'
    privateDnsZonesId: blobPrivateDnsZone.id
  }
}

// ------------------
//    OUTPUTS
// ------------------

output cleanStoragePrivateEndpointName string = privateEndpointNames.clean
output stagingStoragePrivateEndpointName string = privateEndpointNames.staging
output quarantineStoragePrivateEndpointName string = privateEndpointNames.quarantine