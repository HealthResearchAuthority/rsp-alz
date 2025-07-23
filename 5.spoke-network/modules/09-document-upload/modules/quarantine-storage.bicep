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

// Storage account configuration is optimized for quarantine (archive tier, cost-effective)

@description('The resource ID of the VNet to which the private endpoint will be connected.')
param spokeVNetId string

@description('The name of the subnet in the VNet to which the private endpoint will be connected.')
param spokePrivateEndpointSubnetName string

@description('Networking resource group name')
param networkingResourceGroup string

@description('Log Analytics workspace ID for enhanced security monitoring')
param logAnalyticsWorkspaceId string

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
  name: 'quarantineStorageManagedIdentity'
  params: {
    name: 'id-quarantine-storage-${environment}-contributor'
    location: location
    tags: tags
  }
}

module storageAccount '../../../../shared/bicep/storage/storage.bicep' = {
  name: 'quarantineStorageAccount'
  params: {
    name: 'strspquar${environment}'
    location: location
    tags: tags
    kind: 'StorageV2'
    sku: 'Standard_LRS'  // Cost-optimized for quarantine
    accessTier: 'Cool'  // Cool tier for quarantine (Archive not supported for blob storage accounts)
    supportsHttpsTrafficOnly: true
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'None'  // Strictest network access
      ipRules: []
      virtualNetworkRules: []
    }
  }
}

module privateEndpoint '../../../../shared/bicep/network/private-networking-spoke.bicep' = {
  name: 'quarantineStoragePrivateEndpoint'
  scope: resourceGroup(spokeSubscriptionId, networkingResourceGroup)
  params: {
    azServicePrivateDnsZoneName: 'privatelink.blob.${az.environment().suffixes.storage}'
    azServiceId: storageAccount.outputs.id
    privateEndpointName: 'pep-strspquar${environment}'
    privateEndpointSubResourceName: 'blob'
    virtualNetworkLinks: spokeVNetLinks
    subnetId: spokePrivateEndpointSubnet.id
  }
}

module blobService '../../../../shared/bicep/storage/storage.blobsvc.bicep' = {
  name: 'quarantineStorageBlobService'
  params: {
    storageAccountName: storageAccount.outputs.name
    deleteRetentionPolicy: true
    deleteRetentionPolicyDays: 2555  // 7 years retention for forensic analysis
    containers: [
      {
        name: 'quarantine'
        publicAccess: 'None'
      }
    ]
  }
}

module roleAssignment '../../../../shared/bicep/role-assignments/role-assignment.bicep' = {
  name: 'quarantineStorageRoleAssignment'
  params: {
    name: 'ra-quarantine-storage-${uniqueString(managedIdentity.outputs.id, storageAccount.outputs.id)}'
    principalId: managedIdentity.outputs.principalId
    roleDefinitionId: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // Storage Blob Data Contributor
    resourceId: storageAccount.outputs.id
  }
}

// Enhanced Defender configuration with sensitive data discovery for quarantine analysis
module defenderStorageAccountConfig '../../../../shared/bicep/security/defender-storage-account-config.bicep' = if (!empty(logAnalyticsWorkspaceId)) {
  name: 'quarantineDefenderConfig'
  params: {
    storageAccountId: storageAccount.outputs.id
    enableMalwareScanning: false  // No scanning needed - already infected
    malwareScanningCapGBPerMonth: 0
    enableSensitiveDataDiscovery: true  // Enhanced monitoring for quarantine
    overrideSubscriptionLevelSettings: true
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    customEventGridTopicId: ''
    enableBlobIndexTags: true  // Enable for forensic tagging
  }
}

// ------------------
// OUTPUTS
// ------------------

@description('The resource ID of the quarantine storage account.')
output storageAccountId string = storageAccount.outputs.id

@description('The name of the quarantine storage account.')
output storageAccountName string = storageAccount.outputs.name

@description('The resource ID of the managed identity for quarantine storage.')
output managedIdentityId string = managedIdentity.outputs.id

@description('The principal ID of the managed identity for quarantine storage.')
output managedIdentityPrincipalId string = managedIdentity.outputs.principalId

@description('The client ID of the managed identity for quarantine storage.')
output managedIdentityClientId string = managedIdentity.outputs.clientId

@description('The name of the quarantine blob container.')
output containerName string = 'quarantine'