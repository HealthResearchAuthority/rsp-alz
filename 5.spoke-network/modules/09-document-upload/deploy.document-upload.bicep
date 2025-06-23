targetScope = 'resourceGroup'

// ------------------
// PARAMETERS
// ------------------

@description('The location where the resources will be created.')
param location string = resourceGroup().location

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

@description('The resource ID of the VNet to which the private endpoint will be connected.')
param spokeVNetId string

@description('The name of the subnet in the VNet to which the private endpoint will be connected.')
param spokePrivateEndpointSubnetName string

@description('File upload storage account configuration')
param storageConfig object

@description('Resource naming configuration from naming module')
param resourcesNames object


@description('Networking resource group name')
param networkingResourceGroup string

@description('Environment name for storage account naming')
param environment string

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

resource vnetSpoke 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  scope: resourceGroup(spokeSubscriptionId, spokeResourceGroupName)
  name: spokeVNetName
}

resource spokePrivateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' existing = {
  parent: vnetSpoke
  name: spokePrivateEndpointSubnetName
}

module managedIdentity '../../../shared/bicep/managed-identity.bicep' = {
  name: 'fileUploadStorageManagedIdentity'
  params: {
    name: 'id-${resourcesNames.storageAccount}fileupload-StorageBlobDataContributor'
    location: location
    tags: tags
  }
}

module storageAccount '../../../shared/bicep/storage/storage.bicep' = {
  name: 'fileUploadStorageAccount'
  params: {
    name: 'strspdocupload${environment}'
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

module privateEndpoint '../../../shared/bicep/network/private-networking-spoke.bicep' = {
  name: 'fileUploadStoragePrivateEndpoint'
  scope: resourceGroup(spokeSubscriptionId, networkingResourceGroup)
  params: {
    azServicePrivateDnsZoneName: 'privatelink.blob.${az.environment().suffixes.storage}'
    azServiceId: storageAccount.outputs.id
    privateEndpointName: 'pep-strspdocupload${environment}'
    privateEndpointSubResourceName: 'blob'
    virtualNetworkLinks: spokeVNetLinks
    subnetId: spokePrivateEndpointSubnet.id
  }
}

module blobService '../../../shared/bicep/storage/storage.blobsvc.bicep' = {
  name: 'fileUploadStorageBlobService'
  params: {
    storageAccountName: storageAccount.outputs.name
    deleteRetentionPolicy: true
    deleteRetentionPolicyDays: 30
    containers: [
      {
        name: storageConfig.containerName
        publicAccess: 'None'
      }
    ]
  }
}

module roleAssignment '../../../shared/bicep/role-assignments/role-assignment.bicep' = {
  name: 'fileUploadStorageRoleAssignment'
  params: {
    name: 'ra-fileupload-storage-${uniqueString(managedIdentity.outputs.id, storageAccount.outputs.id)}'
    principalId: managedIdentity.outputs.principalId
    roleDefinitionId: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // Storage Blob Data Contributor
    resourceId: storageAccount.outputs.id
  }
}

// ------------------
// OUTPUTS
// ------------------

@description('The resource ID of the file upload storage account.')
output storageAccountId string = storageAccount.outputs.id

@description('The name of the file upload storage account.')
output storageAccountName string = storageAccount.outputs.name

@description('The resource ID of the managed identity for file upload storage.')
output managedIdentityId string = managedIdentity.outputs.id

@description('The principal ID of the managed identity for file upload storage.')
output managedIdentityPrincipalId string = managedIdentity.outputs.principalId

@description('The client ID of the managed identity for file upload storage.')
output managedIdentityClientId string = managedIdentity.outputs.clientId

@description('The name of the blob container for file uploads.')
output containerName string = storageConfig.containerName
