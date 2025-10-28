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

param logAnalyticsWorkspaceId string

@description('The resource ID of the spoke VNet.')
param spokeVNetId string

@description('The name of the private endpoint subnet in the spoke VNet.')
param spokePrivateEndpointSubnetName string

@description('The name of the networking resource group.')
param networkingResourceGroup string

@description('The environment name (e.g., dev, prod).')
param environment string

// ------------------
// RESOURCES
// ------------------

var spokeVNetIdTokens = split(spokeVNetId, '/')
var spokeSubscriptionId = spokeVNetIdTokens[2]
var spokeResourceGroupName = spokeVNetIdTokens[4]
var spokeVNetName = spokeVNetIdTokens[8]

var spokeVNetLinks = [
  {
    vnetName: spokeVNetName
    vnetId: vnetSpoke.id
    registrationEnabled: false
  }
]

resource vnetSpoke 'Microsoft.Network/virtualNetworks@2024-07-01' existing = {
  scope: resourceGroup(spokeSubscriptionId, spokeResourceGroupName)
  name: spokeVNetName
}

resource spokePrivateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' existing = {
  parent: vnetSpoke
  name: spokePrivateEndpointSubnetName
}

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


resource diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${topicName}-diagnostics'
  scope: customEventGridTopic
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'DeliveryFailures'
        enabled: true
      }
      {
        category: 'PublishFailures'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

module privateEndpoint '../../../shared/bicep/network/private-networking-spoke.bicep' = {
  name: '${topicName}PrivateEndpoint'
  scope: resourceGroup(spokeSubscriptionId, networkingResourceGroup)
  params: {
    azServicePrivateDnsZoneName: 'privatelink.eventgrid.azure.net'
    azServiceId: customEventGridTopic.id
    privateEndpointName: 'pep-${topicName}-${environment}'
    privateEndpointSubResourceName: 'topic'
    virtualNetworkLinks: spokeVNetLinks
    subnetId: spokePrivateEndpointSubnet.id
  }
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
