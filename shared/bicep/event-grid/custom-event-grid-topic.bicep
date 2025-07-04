targetScope = 'resourceGroup'

// ------------------
// PARAMETERS
// ------------------

@description('The location where the resources will be created.')
param location string = resourceGroup().location

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

@description('The name of the custom Event Grid topic.')
param topicName string

@description('Enable system topic identity for authentication.')
param enableSystemAssignedIdentity bool = true

@description('Enable public network access for the Event Grid topic.')
param publicNetworkAccess string = 'Enabled'

@description('Input schema for the Event Grid topic.')
@allowed(['EventGridSchema', 'CustomEventSchema', 'CloudEventSchemaV1_0'])
param inputSchema string = 'EventGridSchema'

@description('Local authentication settings for the topic.')
param disableLocalAuth bool = false

// ------------------
// RESOURCES
// ------------------

resource customEventGridTopic 'Microsoft.EventGrid/topics@2022-06-15' = {
  name: topicName
  location: location
  tags: tags
  properties: {
    inputSchema: inputSchema
    publicNetworkAccess: publicNetworkAccess
    disableLocalAuth: disableLocalAuth
  }
  identity: enableSystemAssignedIdentity ? {
    type: 'SystemAssigned'
  } : null
}

// ------------------
// OUTPUTS
// ------------------

@description('The resource ID of the custom Event Grid topic.')
output topicId string = customEventGridTopic.id

@description('The name of the custom Event Grid topic.')
output topicName string = customEventGridTopic.name

@description('The endpoint URL of the custom Event Grid topic.')
output topicEndpoint string = customEventGridTopic.properties.endpoint

// Note: Access keys not exposed as outputs for security reasons
// Use managed identity or service principal authentication instead

@description('The principal ID of the topic managed identity.')
output topicPrincipalId string = enableSystemAssignedIdentity ? customEventGridTopic.identity.principalId : ''