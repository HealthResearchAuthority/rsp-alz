targetScope = 'resourceGroup'

// ------------------
// PARAMETERS
// ------------------

@description('Function App system-assigned managed identity principal ID')
param functionAppPrincipalId string

@description('Array of all storage account resource IDs that the function needs access to')
param storageAccountIds array

// ------------------
// VARIABLES
// ------------------

var storageBlobDataContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
var storageQueueDataContributorRoleId = '974c5e8b-45b9-4653-ba55-5f855dd0fb88'

// ------------------
// RESOURCES
// ------------------

// Storage Blob Data Contributor role for all storage accounts
// This allows the function to read, write, and delete blobs across staging, clean, and quarantine storage
resource storageBlobDataContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (storageAccountId, index) in storageAccountIds: {
    name: guid(storageAccountId, functionAppPrincipalId, storageBlobDataContributorRoleId)
    properties: {
      roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributorRoleId)
      principalId: functionAppPrincipalId
      principalType: 'ServicePrincipal'
      description: 'Allow process-scan Function App to manage blobs in storage account ${split(storageAccountId, '/')[8]}'
    }
  }
]

// Storage Queue Data Contributor role for all storage accounts
// This allows the function to read and process queue messages if needed
resource storageQueueDataContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (storageAccountId, index) in storageAccountIds: {
    name: guid(storageAccountId, functionAppPrincipalId, storageQueueDataContributorRoleId)
    properties: {
      roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageQueueDataContributorRoleId)
      principalId: functionAppPrincipalId
      principalType: 'ServicePrincipal'
      description: 'Allow process-scan Function App to manage queue messages in storage account ${split(storageAccountId, '/')[8]}'
    }
  }
]

// ------------------
// OUTPUTS
// ------------------

@description('The resource IDs of all Storage Blob Data Contributor role assignments.')
output storageBlobRoleAssignmentIds array = [
  for i in range(0, length(storageAccountIds)): storageBlobDataContributor[i].id
]

@description('The resource IDs of all Storage Queue Data Contributor role assignments.')
output storageQueueRoleAssignmentIds array = [
  for i in range(0, length(storageAccountIds)): storageQueueDataContributor[i].id
]

@description('The names of all storage accounts configured with permissions.')
output configuredStorageAccountNames array = [
  for storageAccountId in storageAccountIds: split(storageAccountId, '/')[8]
]

@description('Number of storage accounts configured with permissions.')
output numberOfStorageAccounts int = length(storageAccountIds)