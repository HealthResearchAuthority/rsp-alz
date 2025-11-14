targetScope = 'resourceGroup'

// ------------------
// PARAMETERS
// ------------------

@description('The storage type to deploy (staging, clean, or quarantine)')
@allowed(['staging', 'clean', 'quarantine'])
param storageType string

@description('The Azure region where resources will be deployed.')
param location string = resourceGroup().location

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

@description('The environment name (e.g., dev, prod).')
param environment string

@description('The resource ID of the spoke VNet.')
param spokeVNetId string

@description('The name of the private endpoint subnet in the spoke VNet.')
param spokePrivateEndpointSubnetName string

@description('The name of the networking resource group.')
param networkingResourceGroup string

@description('Storage account configuration object')
param storageConfig object

@description('Enable blob delete retention policy')
param enableDeleteRetentionPolicy bool = true

@description('Blob delete retention policy days for this storage type')
param retentionPolicyDays int

@description('Network security configuration object')
param networkSecurityConfig object

@description('Enable customer-managed key encryption')
param enableEncryption bool = false

@description('Encryption configuration object (when encryption is enabled)')
param encryptionConfig object = {}

@description('Enable malware scanning integration')
param enableMalwareScanning bool = false

@description('Override subscription level settings for storage account level defender configuration')
param overrideSubscriptionLevelSettings bool = false

@description('Log Analytics workspace ID for security alerts')
param logAnalyticsWorkspaceId string = ''

@description('Enable Event Grid integration for scan result processing')
param enableEventGridIntegration bool = false

@description('Enable enhanced monitoring and forensic features')
param enableEnhancedMonitoring bool = false

@description('Enable blob index tags for forensic tagging')
param enableBlobIndexTags bool = false

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

var storageAccountNames = {
  staging: 'strspstagng${environment}'
  clean: 'strspclean${environment}'
  quarantine: 'strspquar${environment}'
}

var storageAccountName = storageAccountNames[storageType]

var managedIdentityNames = {
  staging: 'id-staging-storage-${environment}-contributor'
  clean: 'id-clean-storage-${environment}-contributor'  
  quarantine: 'id-quarantine-storage-${environment}-contributor'
}

var managedIdentityName = managedIdentityNames[storageType]

var privateEndpointNames = {
  staging: 'pep-strspstagng${environment}'
  clean: 'pep-strspclean${environment}'
  quarantine: 'pep-strspquar${environment}'
}

var privateEndpointName = privateEndpointNames[storageType]

var networkSecurityByType = {
  staging: networkSecurityConfig
  clean: networkSecurityConfig
  quarantine: union(networkSecurityConfig, {
    bypass: networkSecurityConfig.?quarantineBypass ?? 'None'
  })
}

var effectiveNetworkSecurity = networkSecurityByType[storageType]

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

// Main managed identity for storage access
module managedIdentity '../../../../shared/bicep/managed-identity.bicep' = {
  name: '${storageType}StorageManagedIdentity'
  params: {
    name: managedIdentityName
    location: location
    tags: tags
  }
}

// Encryption managed identity (when encryption is enabled)
module encryptionManagedIdentity '../../../../shared/bicep/managed-identity.bicep' = if (enableEncryption) {
  name: '${storageType}StorageEncryptionManagedIdentity'
  params: {
    name: 'id-${storageType}-storage-${environment}-encryption'
    location: location
    tags: tags
  }
}

// Encryption key setup (when encryption is enabled)
module encryptionKey '../../../../shared/bicep/key-vault/storage-encryption-key.bicep' = if (enableEncryption && !empty(encryptionConfig.keyVaultResourceId)) {
  name: '${storageType}StorageEncryptionKey'
  scope: resourceGroup(split(encryptionConfig.keyVaultResourceId, '/')[2], split(encryptionConfig.keyVaultResourceId, '/')[4])
  params: {
    keyVaultName: split(encryptionConfig.keyVaultResourceId, '/')[8]
    keyName: encryptionConfig.keyName
    managedIdentityPrincipalId: encryptionManagedIdentity!.outputs.principalId
    tags: tags
  }
}

// Storage account with conditional encryption
module storageAccount '../../../../shared/bicep/storage/storage-with-encryption.bicep' = {
  name: '${storageType}StorageAccount'
  params: {
    name: storageAccountName
    location: location
    tags: tags
    kind: storageConfig.?kind ?? 'StorageV2'
    sku: storageConfig.sku
    accessTier: storageConfig.accessTier
    supportsHttpsTrafficOnly: effectiveNetworkSecurity.httpsTrafficOnly
    networkAcls: {
      defaultAction: effectiveNetworkSecurity.defaultAction
      bypass: effectiveNetworkSecurity.bypass
      ipRules: []
      virtualNetworkRules: []
    }
    encryptionConfig: enableEncryption ? encryptionConfig : { enabled: false }
    createManagedIdentity: false
    managedIdentityName: ''
    externalManagedIdentityId: enableEncryption ? encryptionManagedIdentity!.outputs.id : ''
  }
  dependsOn: (enableEncryption && !empty(encryptionConfig.keyVaultResourceId)) ? [
    encryptionKey
  ] : []
}

// Private endpoint
module privateEndpoint '../../../../shared/bicep/network/private-networking-spoke.bicep' = {
  name: '${storageType}StoragePrivateEndpoint'
  scope: resourceGroup(spokeSubscriptionId, networkingResourceGroup)
  params: {
    azServicePrivateDnsZoneName: 'privatelink.blob.${az.environment().suffixes.storage}'
    azServiceId: storageAccount.outputs.id
    privateEndpointName: privateEndpointName
    privateEndpointSubResourceName: 'blob'
    virtualNetworkLinks: spokeVNetLinks
    subnetId: spokePrivateEndpointSubnet.id
  }
}

// Blob service configuration
module blobService '../../../../shared/bicep/storage/storage.blobsvc.bicep' = {
  name: '${storageType}BlobService'
  params: {
    storageAccountName: storageAccount.outputs.name
    name: 'default'
    deleteRetentionPolicy: enableDeleteRetentionPolicy
    deleteRetentionPolicyDays: enableDeleteRetentionPolicy ? retentionPolicyDays : 1
  }
}

// Container for the storage type
module container '../../../../shared/bicep/storage/storage.blobsvc.containers.bicep' = {
  name: '${storageType}Container'
  params: {
    storageAccountName: storageAccount.outputs.name
    blobServicesName: 'default'
    name: storageConfig.containerName
  }
  dependsOn: [
    blobService
  ]
}

// Storage Blob Data Contributor role assignment
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccountName, managedIdentityName, 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: managedIdentity.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}

// ========================
// MALWARE SCANNING FEATURES (STAGING)
// ========================

// Defender Storage Permissions (staging only)
module defenderStoragePermissions '../../../../shared/bicep/role-assignments/defender-storage-permissions.bicep' = if (enableMalwareScanning) {
  name: '${storageType}DefenderPermissions'
  params: {
    storageAccountId: storageAccount.outputs.id
    eventGridSystemTopicPrincipalId: ''
    enableEventGridPermissions: false
    enableDefenderPermissions: enableMalwareScanning
  }
}

// Defender Storage Account Config (staging only)
module defenderStorageAccountConfig '../../../../shared/bicep/security/defender-storage-account-config.bicep' = if (enableMalwareScanning && !empty(logAnalyticsWorkspaceId)) {
  name: '${storageType}DefenderConfig'
  params: {
    storageAccountId: storageAccount.outputs.id
    enableMalwareScanning: enableMalwareScanning
    malwareScanningCapGBPerMonth: 1000
    enableSensitiveDataDiscovery: true
    overrideSubscriptionLevelSettings: overrideSubscriptionLevelSettings
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    customEventGridTopicId: (enableEventGridIntegration && customEventGridTopic != null) ? customEventGridTopic!.outputs.topicId : ''
    enableBlobIndexTags: enableBlobIndexTags
  }
  dependsOn: [
    defenderStoragePermissions
  ]
}

// Custom Event Grid Topic (staging only)
module customEventGridTopic '../../../../shared/bicep/event-grid/custom-event-grid-topic.bicep' = if (enableEventGridIntegration) {
  name: '${storageType}CustomEventGridTopic'
  params: {
    topicName: 'evgt-${storageAccount.outputs.name}-scan-results'
    location: location
    tags: tags
    enableSystemAssignedIdentity: true
    publicNetworkAccess: 'Enabled'
    inputSchema: 'EventGridSchema'
    disableLocalAuth: false
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    spokeVNetId: spokeVNetId
    spokePrivateEndpointSubnetName: spokePrivateEndpointSubnetName
    networkingResourceGroup: networkingResourceGroup
    environment: environment
  }
}

// ========================
// ENHANCED MONITORING FEATURES (QUARANTINE)
// ========================

// Enhanced Defender Config for Quarantine (quarantine only)
module enhancedDefenderConfig '../../../../shared/bicep/security/defender-storage-account-config.bicep' = if (enableEnhancedMonitoring && !empty(logAnalyticsWorkspaceId)) {
  name: '${storageType}EnhancedDefenderConfig'
  params: {
    storageAccountId: storageAccount.outputs.id
    enableMalwareScanning: false
    malwareScanningCapGBPerMonth: 0
    enableSensitiveDataDiscovery: true
    overrideSubscriptionLevelSettings: overrideSubscriptionLevelSettings
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    customEventGridTopicId: ''
    enableBlobIndexTags: enableBlobIndexTags
  }
}

// ------------------
// OUTPUTS
// ------------------

@description('The resource ID of the storage account.')
output storageAccountId string = storageAccount.outputs.id

@description('The name of the storage account.')
output storageAccountName string = storageAccount.outputs.name

@description('The resource ID of the managed identity.')
output managedIdentityId string = managedIdentity.outputs.id

@description('The principal ID of the managed identity.')
output managedIdentityPrincipalId string = managedIdentity.outputs.principalId

@description('The client ID of the managed identity.')
output managedIdentityClientId string = managedIdentity.outputs.clientId

@description('The name of the blob container.')
output containerName string = storageConfig.containerName

// Encryption-specific outputs (all storage types when enabled)
@description('The resource ID of the encryption managed identity.')
output encryptionManagedIdentityId string = enableEncryption ? encryptionManagedIdentity!.outputs.id : ''

@description('The principal ID of the encryption managed identity.')
output encryptionManagedIdentityPrincipalId string = enableEncryption ? encryptionManagedIdentity!.outputs.principalId : ''

@description('The client ID of the encryption managed identity.')
output encryptionManagedIdentityClientId string = enableEncryption ? encryptionManagedIdentity!.outputs.clientId : ''

@description('The name of the encryption key.')
output encryptionKeyName string = (enableEncryption && !empty(encryptionConfig.keyVaultResourceId)) ? encryptionKey!.outputs.keyName : ''

@description('The URI of the encryption key.')
output encryptionKeyUri string = (enableEncryption && !empty(encryptionConfig.keyVaultResourceId)) ? encryptionKey!.outputs.keyUri : ''

// Malware scanning outputs (staging only)
@description('Indicates whether malware scanning is enabled.')
output malwareScanningEnabled bool = enableMalwareScanning

@description('Custom Event Grid topic ID used for Defender scan results.')
output customEventGridTopicId string = (enableEventGridIntegration && customEventGridTopic != null) ? customEventGridTopic!.outputs.topicId : ''

@description('Custom Event Grid topic endpoint URL.')
output customEventGridTopicEndpoint string = (enableEventGridIntegration && customEventGridTopic != null) ? customEventGridTopic!.outputs.topicEndpoint : ''

// Enhanced monitoring outputs (quarantine only)
@description('Indicates whether enhanced monitoring is enabled.')
output enhancedMonitoringEnabled bool = enableEnhancedMonitoring

@description('Indicates whether blob index tags are enabled.')
output blobIndexTagsEnabled bool = enableBlobIndexTags

output topicManagedIdentityID string = enableEventGridIntegration ? customEventGridTopic!.outputs.topicPrincipalId : ''
