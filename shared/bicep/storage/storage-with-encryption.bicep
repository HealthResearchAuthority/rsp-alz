@description('name must be max 24 chars, globally unique, all lowercase letters or numbers with no spaces.')
param name string
param location string
param tags object

@allowed([
  'Storage'
  'StorageV2'
  'BlobStorage'
  'FileStorage'
  'BlockBlobStorage'
])
@description('Optional. Type of Storage Account to create.')
param kind string = 'StorageV2'

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
])
@description('Optional. Storage Account Sku Name.')
param sku string = 'Standard_GRS'

@allowed([
  'Hot'
  'Cool'
])
@description('Optional. Storage Account Access Tier.')
param accessTier string = 'Hot'

@description('Optional. Allows HTTPS traffic only to storage service if sets to true.')
param supportsHttpsTrafficOnly bool = true

@description('Network ACLs object to apply to the storage account.')
param networkAcls object

@description('Encryption configuration for the storage account.')
param encryptionConfig object = {
  enabled: false
  keyVaultResourceId: ''
  keyName: ''
  enableInfrastructureEncryption: false
  keyRotationEnabled: true
}

@description('Optional. Create and configure managed identity for Key Vault access.')
param createManagedIdentity bool = true

@description('Optional. Name for the managed identity. Auto-generated if empty.')
param managedIdentityName string = ''

// Variables
var maxNameLength = 24
var storageNameValid = toLower(replace(name, '-', ''))
var uniqueStorageName = length(storageNameValid) > maxNameLength ? substring(storageNameValid, 0, maxNameLength) : storageNameValid

// Generate managed identity name following project naming conventions
var generatedIdentityName = !empty(managedIdentityName) ? managedIdentityName : 'id-${uniqueStorageName}-encryption'

// Parse Key Vault resource ID to get vault URI and subscription/resource group info
var keyVaultResourceIdTokens = split(encryptionConfig.keyVaultResourceId, '/')
var keyVaultName = !empty(encryptionConfig.keyVaultResourceId) ? keyVaultResourceIdTokens[8] : ''
var keyVaultUri = !empty(encryptionConfig.keyVaultResourceId) ? 'https://${keyVaultName}${az.environment().suffixes.keyvaultDns}/' : ''

// Generate key name following project naming conventions if not provided
var keyName = !empty(encryptionConfig.keyName) ? encryptionConfig.keyName : 'key-${uniqueStorageName}-encryption'

// Create managed identity for Key Vault access when encryption is enabled
resource storageIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = if (encryptionConfig.enabled && createManagedIdentity) {
  name: generatedIdentityName
  location: location
  tags: tags
}

// Storage account with optional encryption
resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: uniqueStorageName
  location: location
  kind: kind
  sku: {
    name: sku
  }
  identity: encryptionConfig.enabled && createManagedIdentity ? {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${storageIdentity.id}': {}
    }
  } : null
  tags: union(tags, {
    displayName: uniqueStorageName
  })
  properties: {
    accessTier: accessTier
    supportsHttpsTrafficOnly: supportsHttpsTrafficOnly
    networkAcls: networkAcls
    publicNetworkAccess: 'Enabled'
    minimumTlsVersion: 'TLS1_2'
    encryption: encryptionConfig.enabled ? {
      identity: createManagedIdentity ? {
        userAssignedIdentity: storageIdentity.id
      } : null
      keySource: 'Microsoft.Keyvault'
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
        queue: {
          enabled: true
          keyType: 'Account'
        }
        table: {
          enabled: true
          keyType: 'Account'
        }
      }
      keyvaultproperties: {
        keyname: keyName
        keyvaulturi: keyVaultUri
        keyversion: encryptionConfig.keyRotationEnabled ? null : '' // null for auto-rotation, specific version for manual
      }
    } : {
      keySource: 'Microsoft.Storage'
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
      }
    }
  }
  dependsOn: encryptionConfig.enabled && createManagedIdentity ? [
    storageIdentity
  ] : []
}

output id string = storage.id
output name string = storage.name
output apiVersion string = storage.apiVersion
output managedIdentityId string = (encryptionConfig.enabled && createManagedIdentity) ? storageIdentity.id : ''
output managedIdentityPrincipalId string = (encryptionConfig.enabled && createManagedIdentity) ? storageIdentity!.properties.principalId : ''
output managedIdentityClientId string = (encryptionConfig.enabled && createManagedIdentity) ? storageIdentity!.properties.clientId : ''
output keyName string = encryptionConfig.enabled ? keyName : ''
output keyVaultUri string = encryptionConfig.enabled ? keyVaultUri : ''
output encryptionEnabled bool = encryptionConfig.enabled