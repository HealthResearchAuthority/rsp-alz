
// ------------------
// PARAMETERS
// ------------------

@description('The name of the Event Grid subscription.')
param subscriptionName string

@description('The resource ID of the custom Event Grid topic.')
param customTopicId string

@description('Destination type for Event Grid subscription')
@allowed(['webhook', 'storagequeue', 'AzureFunction'])
param destinationType string = 'webhook'

@description('Storage account name for queue destination (required if destinationType is storagequeue).')
param storageAccountName string = ''

@description('Container name to monitor for blob events.')
param containerName string = ''

@description('Queue name for storage queue destination')
param queueName string = 'defender-malware-scan-queue'

@description('Event types to subscribe to.')
param eventTypes array = [
  'Microsoft.Security.MalwareScanningResult'
]

@description('Enable dead letter destination for failed events.')
param enableDeadLetter bool = true

@description('Storage account for dead letter events.')
param deadLetterStorageAccountName string = ''

@description('Container name for dead letter events.')
param deadLetterContainerName string = 'event-grid-dead-letters'

@description('Maximum delivery attempts for events.')
param maxDeliveryAttempts int = 3

@description('Event time to live in minutes.')
param eventTimeToLiveInMinutes int = 1440

@description('Enable advanced filtering for blob events.')
param enableAdvancedFiltering bool = true

param functionAppname string
param functionAppId string

// ------------------
// VARIABLES
// ------------------

var subjectFilter = enableAdvancedFiltering && !empty(containerName) ? {
  subjectBeginsWith: '/blobServices/default/containers/${containerName}/'
  subjectEndsWith: ''
  includedEventTypes: eventTypes
} : {
  includedEventTypes: eventTypes
}

var deadLetterConfig = enableDeadLetter && !empty(deadLetterStorageAccountName) ? {
  endpointType: 'StorageBlob'
  properties: {
    resourceId: resourceId('Microsoft.Storage/storageAccounts', deadLetterStorageAccountName)
    blobContainerName: deadLetterContainerName
  }
} : null

// ------------------
// RESOURCES
// ------------------

resource customTopic 'Microsoft.EventGrid/topics@2022-06-15' existing = {
  name: split(customTopicId, '/')[8]
}

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-${customTopic.name}-egDataSender'
  location: resourceGroup().location
}

resource eventGridSubscription 'Microsoft.EventGrid/topics/eventSubscriptions@2022-06-15' = {
  parent: customTopic
  name: subscriptionName
  properties: {
    destination: destinationType == 'AzureFunction' ? {
      endpointType: 'AzureFunction'
      properties: {
        resourceId: functionAppId
        maxEventsPerBatch: 1
        preferredBatchSizeInKilobytes: 64
      }
    } : {
      endpointType: 'StorageQueue'
      properties: {
        resourceId: resourceId('Microsoft.Storage/storageAccounts', storageAccountName)
        queueName: queueName
      }
    }
    deliveryWithResourceIdentity: {
      identity: {
        type: 'UserAssigned'
        userAssignedIdentity: uami.id
      }
      destination: {
        endpointType: 'AzureFunction'
      }
    }
    filter: subjectFilter
    labels: [
      'defender-malware-scanning'
      'storage-security'
    ]
    deadLetterDestination: deadLetterConfig
    retryPolicy: {
      maxDeliveryAttempts: maxDeliveryAttempts
      eventTimeToLiveInMinutes: eventTimeToLiveInMinutes
    }
  }
}

resource functionApp 'Microsoft.Web/sites@2022-09-01' existing = {
  name: functionAppname
}

// Assign EventGrid Data Sender role to Event Grid’s managed identity on Function App
resource eventGridToFunctionRBAC 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(functionApp.id, 'EventGridDataSender')
  scope: functionApp
  properties: {
    principalId: uami.properties.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '428e0ff0-5e57-4d9c-8d3a-0e7b4a75be13') // EventGrid Data Sender
    principalType: 'ServicePrincipal'
  }
}

// ------------------
// OUTPUTS
// ------------------

@description('The resource ID of the Event Grid subscription.')
output eventSubscriptionId string = eventGridSubscription.id

@description('The name of the Event Grid subscription.')
output eventSubscriptionName string = eventGridSubscription.name

@description('The custom topic being used.')
output customTopicName string = customTopic.name

@description('The container being monitored.')
output monitoredContainer string = containerName
