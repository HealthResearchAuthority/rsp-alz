targetScope = 'resourceGroup'

// ------------------
// PARAMETERS
// ------------------


@description('The name of the Event Grid subscription.')
param subscriptionName string


@description('The resource ID of the Event Grid system topic.')
param systemTopicId string

@description('Destination type for Event Grid subscription')
@allowed(['webhook', 'storagequeue'])
param destinationType string = 'webhook'

@description('Storage account name for queue destination (required if destinationType is storagequeue).')
param storageAccountName string = ''

@description('Container name to monitor for blob events.')
param containerName string = ''

@description('Queue name for storage queue destination')
param queueName string = 'defender-malware-scan-queue'

@description('Event types to subscribe to.')
param eventTypes array = [
  'Microsoft.Storage.BlobCreated'
]

@description('Enable dead letter destination for failed events.')
param enableDeadLetter bool = true

@description('Storage account for dead letter events.')
param deadLetterStorageAccountName string = ''

@description('Container name for dead letter events.')
param deadLetterContainerName string = 'event-grid-dead-letters'

@description('Webhook endpoint URL for malware scanning notifications.')
@secure()
param webhookEndpointUrl string = ''

@description('Maximum delivery attempts for events.')
param maxDeliveryAttempts int = 3

@description('Event time to live in minutes.')
param eventTimeToLiveInMinutes int = 1440

@description('Enable advanced filtering for blob events.')
param enableAdvancedFiltering bool = true

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

resource systemTopic 'Microsoft.EventGrid/systemTopics@2022-06-15' existing = {
  name: split(systemTopicId, '/')[8]
}

resource eventGridSubscription 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2022-06-15' = {
  parent: systemTopic
  name: subscriptionName
  properties: {
    destination: destinationType == 'webhook' ? {
      endpointType: 'WebHook'
      properties: {
        endpointUrl: webhookEndpointUrl
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

// ------------------
// OUTPUTS
// ------------------

@description('The resource ID of the Event Grid subscription.')
output eventSubscriptionId string = eventGridSubscription.id

@description('The name of the Event Grid subscription.')
output eventSubscriptionName string = eventGridSubscription.name

@description('The storage account being monitored.')
output monitoredStorageAccount string = storageAccountName

@description('The container being monitored.')
output monitoredContainer string = containerName
