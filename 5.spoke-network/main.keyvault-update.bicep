targetScope = 'subscription'

@description('Definition of a Key Vault secret to update.')
type keyVaultSecretDefinition = {
  @description('Secret name inside Key Vault.')
  name: string

  @description('Optional content type metadata that will be stored with the secret.')
  contentType: string?
}

@description('Subscription containing the shared services resource group.')
param parSharedServicesSubscriptionId string

@description('Shared services resource group that hosts the Key Vault.')
param parSharedServicesResourceGroup string

@description('Name of the Key Vault to update.')
param parKeyVaultName string

@description('Secrets metadata (name, optional tags/contentType/attributes).')
param parKeyVaultSecrets keyVaultSecretDefinition[] = []

@secure()
@description('Object keyed by secret name containing the actual secret values supplied during deployment.')
param parSecretValues object

module keyVaultSecrets 'modules/keyvault-update/deploy.keyvault-secrets.bicep' = {
  name: take('keyVaultSecrets-${deployment().name}', 64)
  scope: resourceGroup(parSharedServicesSubscriptionId, parSharedServicesResourceGroup)
  params: {
    keyVaultName: parKeyVaultName
    parKeyVaultSecrets: parKeyVaultSecrets
    parSecretValues: parSecretValues
  }
}

output keyVaultName string = parKeyVaultName
output updatedSecretNames array = keyVaultSecrets.outputs.updatedSecretNames
