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

// VNet links for DNS zone
var vNetLinksForDnsZone = [
  {
    vnetName: devboxVNetName
    vnetId: devboxVNet.id
    registrationEnabled: false
  }
]

// Private endpoint for clean storage account using existing private-networking-spoke module
module cleanStoragePrivateEndpoint '../../../shared/bicep/network/private-networking-spoke.bicep' = {
  name: take('cleanStoragePE-${environment}', 64)
  scope: resourceGroup(devboxSubscriptionId, devboxResourceGroupName)
  params: {
    location: location
    azServicePrivateDnsZoneName: 'privatelink.blob.${az.environment().suffixes.storage}'
    azServiceId: storageAccountResourceIds.clean
    privateEndpointName: privateEndpointNames.clean
    privateEndpointSubResourceName: 'blob'
    virtualNetworkLinks: vNetLinksForDnsZone
    subnetId: devboxPrivateEndpointSubnet.id
  }
}

// Private endpoint for staging storage account using existing private-networking-spoke module
module stagingStoragePrivateEndpoint '../../../shared/bicep/network/private-networking-spoke.bicep' = {
  name: take('stagingStoragePE-${environment}', 64)
  scope: resourceGroup(devboxSubscriptionId, devboxResourceGroupName)
  params: {
    location: location
    azServicePrivateDnsZoneName: 'privatelink.blob.${az.environment().suffixes.storage}'
    azServiceId: storageAccountResourceIds.staging
    privateEndpointName: privateEndpointNames.staging
    privateEndpointSubResourceName: 'blob'
    virtualNetworkLinks: vNetLinksForDnsZone
    subnetId: devboxPrivateEndpointSubnet.id
  }
  dependsOn: [
    cleanStoragePrivateEndpoint // Ensure sequential deployment to avoid DNS zone race conditions
  ]
}

// Private endpoint for quarantine storage account using existing private-networking-spoke module
module quarantineStoragePrivateEndpoint '../../../shared/bicep/network/private-networking-spoke.bicep' = {
  name: take('quarantineStoragePE-${environment}', 64)
  scope: resourceGroup(devboxSubscriptionId, devboxResourceGroupName)
  params: {
    location: location
    azServicePrivateDnsZoneName: 'privatelink.blob.${az.environment().suffixes.storage}'
    azServiceId: storageAccountResourceIds.quarantine
    privateEndpointName: privateEndpointNames.quarantine
    privateEndpointSubResourceName: 'blob'
    virtualNetworkLinks: vNetLinksForDnsZone
    subnetId: devboxPrivateEndpointSubnet.id
  }
  dependsOn: [
    stagingStoragePrivateEndpoint // Ensure sequential deployment to avoid DNS zone race conditions
  ]
}

// ------------------
//    OUTPUTS
// ------------------

output cleanStoragePrivateEndpointName string = privateEndpointNames.clean
output stagingStoragePrivateEndpointName string = privateEndpointNames.staging
output quarantineStoragePrivateEndpointName string = privateEndpointNames.quarantine