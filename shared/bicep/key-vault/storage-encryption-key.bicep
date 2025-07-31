targetScope = 'resourceGroup'

// ------------------
// PARAMETERS
// ------------------

@description('The name of the Key Vault.')
param keyVaultName string

@description('The name of the encryption key to create.')
param keyName string

@description('The principal ID of the managed identity that will access the key.')
param managedIdentityPrincipalId string

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

// ------------------
// VARIABLES
// ------------------

// Key Vault Crypto Service Encryption User role definition ID
var keyVaultCryptoServiceEncryptionUserRoleId = 'e147488a-f6f5-4113-8e2d-b22465e65bf6'

// ------------------
// RESOURCES
// ------------------

// Reference existing Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

// Create encryption key
resource encryptionKey 'Microsoft.KeyVault/vaults/keys@2023-07-01' = {
  parent: keyVault
  name: keyName
  properties: {
    kty: 'RSA'
    keySize: 2048
    keyOps: [
      'encrypt'
      'decrypt'
      'sign'
      'verify'
      'wrapKey'
      'unwrapKey'
    ]
    attributes: {
      enabled: true
    }
  }
  tags: tags
}

// Grant Key Vault permissions to managed identity
resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, managedIdentityPrincipalId, keyVaultCryptoServiceEncryptionUserRoleId)
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultCryptoServiceEncryptionUserRoleId)
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Add a deployment script to ensure role assignment propagation
resource roleAssignmentDelay 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'roleAssignmentDelay-${keyName}'
  location: resourceGroup().location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '9.0'
    scriptContent: 'Start-Sleep -Seconds 30'
    retentionInterval: 'P1D'
  }
  dependsOn: [
    keyVaultRoleAssignment
  ]
}

// ------------------
// OUTPUTS
// ------------------

@description('The resource ID of the encryption key.')
output keyId string = encryptionKey.id

@description('The name of the encryption key.')
output keyName string = encryptionKey.name

@description('The URI of the encryption key.')
output keyUri string = encryptionKey.properties.keyUri

@description('The Key Vault URI.')
output keyVaultUri string = keyVault.properties.vaultUri