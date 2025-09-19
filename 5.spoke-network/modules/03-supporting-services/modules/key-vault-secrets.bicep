targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------

@description('Required. Name of the Key Vault where secrets will be stored.')
param keyVaultName string

@description('Optional. Tags to be assigned to the created resources.')
param tags object = {}

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

// ------------------
//    RESOURCES
// ------------------

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource oneLoginSecretResources 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = [
  for secret in oneLoginSecrets: {
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

@description('Array of OneLogin secret names that were created.')
output oneLoginSecretNames array = [for secret in oneLoginSecrets: secret.name]

@description('Key Vault URI for oneLoginClientId secret.')
output oneLoginClientIdSecretUri string = '${keyVault.properties.vaultUri}secrets/oneLoginClientId'

@description('Key Vault URI for oneLoginPrivateKeyPem secret.')
output oneLoginPrivateKeyPemSecretUri string = '${keyVault.properties.vaultUri}secrets/oneLoginPrivateKeyPem'