
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

param topicRGName string

param functionAppname string
param functionName string
param eventGridTopicManagedIdentityPrincipalId string


// ------------------
// RESOURCES
// ------------------

resource functionApp 'Microsoft.Web/sites@2022-03-01' existing = if(destinationType == 'AzureFunction') {
  name: functionAppname
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' =  {
  name: guid(subscription().id, 'AzureEventGridEventSubscriptionContributorrole', functionAppname)
  scope: functionApp
  properties: {
    principalId: eventGridTopicManagedIdentityPrincipalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '428e0ff0-5e57-4d9c-a221-2c70d0e0a443') // Azure Event Grid EventSubscription Contributor role assignment
    principalType: 'ServicePrincipal'
  }
}

module customTopicSubscription './custom-topic-subscription.bicep' = {
  scope: resourceGroup(topicRGName)
  name: take('customTopicSubscription-${deployment().name}', 64)
  params: {
    subscriptionName: subscriptionName
    customTopicId: customTopicId
    destinationType: destinationType
    storageAccountName: storageAccountName
    containerName: containerName
    queueName: queueName
    eventTypes: eventTypes
    enableDeadLetter: enableDeadLetter
    deadLetterStorageAccountName: deadLetterStorageAccountName
    deadLetterContainerName: deadLetterContainerName
    maxDeliveryAttempts: maxDeliveryAttempts
    eventTimeToLiveInMinutes: eventTimeToLiveInMinutes
    enableAdvancedFiltering: enableAdvancedFiltering
    functionAppId: '${functionApp.id}/functions/${functionName}'
    functionAppname: functionAppname
  }
  dependsOn: [
    roleAssignment
  ]
}

// ------------------
// OUTPUTS
// ------------------

@description('The resource ID of the Event Grid subscription.')
output eventSubscriptionId string = customTopicSubscription.outputs.eventSubscriptionId

@description('The name of the Event Grid subscription.')
output eventSubscriptionName string = customTopicSubscription.outputs.eventSubscriptionName

@description('The custom topic being used.')
output customTopicName string = customTopicSubscription.outputs.customTopicName

@description('The container being monitored.')
output monitoredContainer string = containerName
