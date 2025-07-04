targetScope = 'resourceGroup'

// ------------------
// PARAMETERS
// ------------------

@description('The resource ID of the storage account.')
param storageAccountId string

@description('The principal ID of the Event Grid system topic managed identity.')
param eventGridSystemTopicPrincipalId string

@description('The principal ID of the Defender for Storage service principal.')
param defenderServicePrincipalId string = ''

@description('Enable Event Grid permissions for storage account access.')
param enableEventGridPermissions bool = true

@description('Enable Defender for Storage permissions.')
param enableDefenderPermissions bool = true

// ------------------
// VARIABLES
// ------------------

// Role definition IDs for Azure built-in roles
var storageBlobDataReaderRoleId = '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
var storageBlobDataContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
var eventGridEventSubscriptionReaderRoleId = '2414bbcf-6497-4faf-8c65-045460748405'

// ------------------
// RESOURCES
// ------------------

// Event Grid system topic permissions for storage account access
resource eventGridStoragePermission 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableEventGridPermissions && !empty(eventGridSystemTopicPrincipalId)) {
  name: guid(storageAccountId, eventGridSystemTopicPrincipalId, storageBlobDataReaderRoleId)
  properties: {
    principalId: eventGridSystemTopicPrincipalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataReaderRoleId)
    principalType: 'ServicePrincipal'
  }
}

// Event Grid Event Subscription Reader permissions
resource eventGridSubscriptionPermission 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableEventGridPermissions && !empty(eventGridSystemTopicPrincipalId)) {
  name: guid(storageAccountId, eventGridSystemTopicPrincipalId, eventGridEventSubscriptionReaderRoleId)
  properties: {
    principalId: eventGridSystemTopicPrincipalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', eventGridEventSubscriptionReaderRoleId)
    principalType: 'ServicePrincipal'
  }
}

// Defender for Storage service permissions - needs contributor access to move files to quarantine
resource defenderStoragePermission 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableDefenderPermissions && !empty(defenderServicePrincipalId)) {
  name: guid(storageAccountId, defenderServicePrincipalId, storageBlobDataContributorRoleId)
  properties: {
    principalId: defenderServicePrincipalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributorRoleId)
    principalType: 'ServicePrincipal'
  }
}

// ------------------
// OUTPUTS
// ------------------

@description('The resource ID of the Event Grid storage permission role assignment.')
output eventGridStoragePermissionId string = enableEventGridPermissions ? eventGridStoragePermission.id : ''

@description('The resource ID of the Event Grid subscription permission role assignment.')
output eventGridSubscriptionPermissionId string = enableEventGridPermissions ? eventGridSubscriptionPermission.id : ''

@description('The resource ID of the Defender storage permission role assignment.')
output defenderStoragePermissionId string = enableDefenderPermissions ? defenderStoragePermission.id : ''