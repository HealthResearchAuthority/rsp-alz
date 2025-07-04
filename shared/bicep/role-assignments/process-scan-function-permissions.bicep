targetScope = 'resourceGroup'

// ------------------
// PARAMETERS
// ------------------

@description('Function App system-assigned managed identity principal ID')
param functionAppPrincipalId string

@description('Document upload storage account resource ID')
param documentUploadStorageAccountId string

// ------------------
// VARIABLES
// ------------------

var documentUploadResourceGroupName = split(documentUploadStorageAccountId, '/')[4]
var documentUploadStorageAccountName = split(documentUploadStorageAccountId, '/')[8]

// ------------------
// RESOURCES
// ------------------

// Storage Blob Data Contributor role for document upload storage account
// This allows the function to read, write, and delete blobs for file movement operations
resource storageBlobDataContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(documentUploadStorageAccountId, functionAppPrincipalId, 'Storage Blob Data Contributor')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: functionAppPrincipalId
    principalType: 'ServicePrincipal'
    description: 'Allow process-scan Function App to manage blobs in document upload storage account'
  }
}

// Storage Queue Data Contributor role for potential queue operations
// This allows the function to read and process queue messages if needed
resource storageQueueDataContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(documentUploadStorageAccountId, functionAppPrincipalId, 'Storage Queue Data Contributor')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '974c5e8b-45b9-4653-ba55-5f855dd0fb88')
    principalId: functionAppPrincipalId
    principalType: 'ServicePrincipal'
    description: 'Allow process-scan Function App to manage queue messages in document upload storage account'
  }
}

// ------------------
// OUTPUTS
// ------------------

@description('The resource ID of the Storage Blob Data Contributor role assignment.')
output storageBlobRoleAssignmentId string = storageBlobDataContributor.id

@description('The resource ID of the Storage Queue Data Contributor role assignment.')
output storageQueueRoleAssignmentId string = storageQueueDataContributor.id

@description('The storage account name configured with permissions.')
output configuredStorageAccountName string = documentUploadStorageAccountName