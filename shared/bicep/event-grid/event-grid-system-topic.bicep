targetScope = 'resourceGroup'

// ------------------
// PARAMETERS
// ------------------

@description('The location where the resources will be created.')
param location string = resourceGroup().location

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

@description('The name of the Event Grid system topic.')
param systemTopicName string

@description('The resource ID of the storage account for which to create the system topic.')
param storageAccountId string

@description('The type of Azure service for the system topic.')
param topicType string = 'Microsoft.Storage.StorageAccounts'

@description('Enable system topic identity for authentication.')
param enableSystemAssignedIdentity bool = true

// ------------------
// VARIABLES
// ------------------

var storageAccountIdTokens = split(storageAccountId, '/')
var storageAccountName = storageAccountIdTokens[8]

// ------------------
// RESOURCES
// ------------------

resource eventGridSystemTopic 'Microsoft.EventGrid/systemTopics@2022-06-15' = {
  name: systemTopicName
  location: location
  tags: tags
  properties: {
    source: storageAccountId
    topicType: topicType
  }
  identity: enableSystemAssignedIdentity ? {
    type: 'SystemAssigned'
  } : null
}

// ------------------
// OUTPUTS
// ------------------

@description('The resource ID of the Event Grid system topic.')
output systemTopicId string = eventGridSystemTopic.id

@description('The name of the Event Grid system topic.')
output systemTopicName string = eventGridSystemTopic.name

@description('The principal ID of the system topic managed identity.')
output systemTopicPrincipalId string = enableSystemAssignedIdentity ? eventGridSystemTopic.identity.principalId : ''

@description('The storage account name associated with this system topic.')
output associatedStorageAccountName string = storageAccountName
