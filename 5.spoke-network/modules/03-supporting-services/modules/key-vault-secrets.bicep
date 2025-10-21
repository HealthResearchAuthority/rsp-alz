targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------

@description('Required. Name of the Key Vault where secrets will be stored.')
param keyVaultName string

@description('Optional. Tags to be assigned to the created resources.')
param tags object = {}

@description('Optional. Whether to create secrets with placeholder values. Set to false to skip secret creation and only output URIs for existing secrets.')
param createSecretsWithPlaceholders bool = false

// ------------------
//    VARIABLES
// ------------------

// OneLogin secrets with placeholder values - actual values to be updated manually via portal
var oneLoginSecrets = [
  {
    name: 'oneLoginClientId'
    value: 'placeholder-client-id-to-be-updated-manually'
  }
  {
    name: 'oneLoginPrivateKeyPem'
    value: 'placeholder-private-key-pem-to-be-updated-manually'
  }
]

// RTS API secrets with placeholder values - actual values to be updated manually via portal
var rtsApiSecrets = [
  {
    name: 'rtsApiClientId'
    value: 'placeholder-rts-client-id-to-be-updated-manually'
  }
  {
    name: 'rtsApiClientSecret'
    value: 'placeholder-rts-client-secret-to-be-updated-manually'
  }
]

// Storage account secrets with placeholder values - actual values to be updated manually via portal
var storageSecrets = [
  {
    name: 'documentBlobStorageAccountKey'
    value: 'placeholder-document-storage-key-to-be-updated-manually'
  }
  {
    name: 'stagingStorageAccountKey'
    value: 'placeholder-staging-storage-key-to-be-updated-manually'
  }
  {
    name: 'quarantineStorageAccountKey'
    value: 'placeholder-quarantine-storage-key-to-be-updated-manually'
  }
  {
    name: 'cleanStorageAccountKey'
    value: 'placeholder-clean-storage-key-to-be-updated-manually'
  }
]

// ------------------
//    RESOURCES
// ------------------

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource oneLoginSecretResources 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = [
  for secret in oneLoginSecrets: if (createSecretsWithPlaceholders) {
    parent: keyVault
    name: secret.name
    tags: tags
    properties: {
      value: secret.value
      contentType: 'text/plain'
    }
  }
]

resource rtsApiSecretResources 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = [
  for secret in rtsApiSecrets: if (createSecretsWithPlaceholders) {
    parent: keyVault
    name: secret.name
    tags: tags
    properties: {
      value: secret.value
      contentType: 'text/plain'
    }
  }
]

resource storageSecretResources 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = [
  for secret in storageSecrets: if (createSecretsWithPlaceholders) {
    parent: keyVault
    name: secret.name
    tags: tags
    properties: {
      value: secret.value
      contentType: 'text/plain'
    }
  }
]

// ------------------
//    OUTPUTS
// ------------------

@description('Array of OneLogin secret names that were created or referenced.')
output oneLoginSecretNames array = [for secret in oneLoginSecrets: secret.name]

@description('Array of RTS API secret names that were created or referenced.')
output rtsApiSecretNames array = [for secret in rtsApiSecrets: secret.name]

@description('Array of storage secret names that were created or referenced.')
output storageSecretNames array = [for secret in storageSecrets: secret.name]

@description('Key Vault URI for oneLoginClientId secret.')
output oneLoginClientIdSecretUri string = '${keyVault.properties.vaultUri}secrets/oneLoginClientId'

@description('Key Vault URI for oneLoginPrivateKeyPem secret.')
output oneLoginPrivateKeyPemSecret string = '${keyVault.properties.vaultUri}secrets/oneLoginPrivateKeyPem'

@description('Key Vault URI for rtsApiClientId secret.')
output rtsApiClientIdSecretUri string = '${keyVault.properties.vaultUri}secrets/rtsApiClientId'

@description('Key Vault URI for rtsApiClientSecret secret.')
output rtsApiClientSecretSecretUri string = '${keyVault.properties.vaultUri}secrets/rtsApiClientSecret'

@description('Key Vault URI for documentBlobStorageAccountKey secret.')
output documentBlobStorageAccountKeySecretUri string = '${keyVault.properties.vaultUri}secrets/documentBlobStorageAccountKey'
