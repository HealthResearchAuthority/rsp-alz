targetScope = 'resourceGroup'

// ------------------
// PARAMETERS
// ------------------

@description('The location where the resources will be created.')
param location string = resourceGroup().location

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

@description('Environment name for storage account naming')
param environment string

@description('Storage account configuration')
param storageConfig object

@description('The resource ID of the VNet to which the private endpoint will be connected.')
param spokeVNetId string

@description('The name of the subnet in the VNet to which the private endpoint will be connected.')
param spokePrivateEndpointSubnetName string

@description('Networking resource group name')
param networkingResourceGroup string

// ------------------
// VARIABLES
// ------------------

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
]

// ------------------
// RESOURCES
// ------------------

resource vnetSpoke 'Microsoft.Network/virtualNetworks@2024-07-01' existing = {
  scope: resourceGroup(spokeSubscriptionId, spokeResourceGroupName)
  name: spokeVNetName
}

resource spokePrivateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' existing = {
  parent: vnetSpoke
  name: spokePrivateEndpointSubnetName
}

module managedIdentity '../../../../shared/bicep/managed-identity.bicep' = {
  name: 'cleanStorageManagedIdentity'
  params: {
    name: 'id-clean-storage-${environment}-contributor'
    location: location
    tags: tags
  }
}

module storageAccount '../../../../shared/bicep/storage/storage.bicep' = {
  name: 'cleanStorageAccount'
  params: {
    name: 'strspclean${environment}'
    location: location
    tags: tags
    kind: 'StorageV2'
    sku: storageConfig.sku
    accessTier: storageConfig.accessTier
    supportsHttpsTrafficOnly: true
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      ipRules: []
      virtualNetworkRules: []
    }
  }
}

module privateEndpoint '../../../../shared/bicep/network/private-networking-spoke.bicep' = {
  name: 'cleanStoragePrivateEndpoint'
  scope: resourceGroup(spokeSubscriptionId, networkingResourceGroup)
  params: {
    azServicePrivateDnsZoneName: 'privatelink.blob.${az.environment().suffixes.storage}'
    azServiceId: storageAccount.outputs.id
    privateEndpointName: 'pep-strspclean${environment}'
    privateEndpointSubResourceName: 'blob'
    virtualNetworkLinks: spokeVNetLinks
    subnetId: spokePrivateEndpointSubnet.id
  }
}

module blobService '../../../../shared/bicep/storage/storage.blobsvc.bicep' = {
  name: 'cleanStorageBlobService'
  params: {
    storageAccountName: storageAccount.outputs.name
    deleteRetentionPolicy: true
    deleteRetentionPolicyDays: 365  // Long retention for clean files
    containers: [
      {
        name: 'clean'
        publicAccess: 'None'
      }
    ]
  }
}

module roleAssignment '../../../../shared/bicep/role-assignments/role-assignment.bicep' = {
  name: 'cleanStorageRoleAssignment'
  params: {
    name: 'ra-clean-storage-${uniqueString(managedIdentity.outputs.id, storageAccount.outputs.id)}'
    principalId: managedIdentity.outputs.principalId
    roleDefinitionId: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // Storage Blob Data Contributor
    resourceId: storageAccount.outputs.id
  }
}

// ------------------
// OUTPUTS
// ------------------

@description('The resource ID of the clean storage account.')
output storageAccountId string = storageAccount.outputs.id

@description('The name of the clean storage account.')
output storageAccountName string = storageAccount.outputs.name

@description('The resource ID of the managed identity for clean storage.')
output managedIdentityId string = managedIdentity.outputs.id

@description('The principal ID of the managed identity for clean storage.')
output managedIdentityPrincipalId string = managedIdentity.outputs.principalId

@description('The client ID of the managed identity for clean storage.')
output managedIdentityClientId string = managedIdentity.outputs.clientId

@description('The name of the clean blob container.')
output containerName string = 'clean'