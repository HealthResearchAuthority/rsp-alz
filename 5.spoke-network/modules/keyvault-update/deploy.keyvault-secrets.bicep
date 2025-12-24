targetScope = 'resourceGroup'

@description('Definition of a Key Vault secret to update.')
type keyVaultSecretDefinition = {
  @description('Secret name inside Key Vault.')
  name: string

  @description('Optional content type metadata that will be stored with the secret.')
  contentType: string?
}

@description('Name of the existing Key Vault to update.')
param keyVaultName string

@description('Secrets metadata (name, optional tags/contentType/attributes).')
param parKeyVaultSecrets keyVaultSecretDefinition[] = []

@secure()
@description('Object keyed by secret name containing the actual secret values. Each property name must match a secret name from parKeyVaultSecrets.')
param parSecretValues object

var normalizedSecrets = [
  for secret in parKeyVaultSecrets: {
    name: secret.name
    value: parSecretValues[secret.name]
    contentType: secret.?contentType
  }
]

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource keyVaultSecrets 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = [
  for secret in normalizedSecrets: {
    parent: keyVault
    name: secret.name
    properties: {
      value: string(secret.value)
      contentType: secret.?contentType
      attributes: {
        enabled: true
      }
    }
  }
]

output updatedSecretNames array = [for secret in normalizedSecrets: secret.name]
