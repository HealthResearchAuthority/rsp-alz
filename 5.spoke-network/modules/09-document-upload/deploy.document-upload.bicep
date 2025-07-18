targetScope = 'resourceGroup'

// ------------------
// PARAMETERS
// ------------------

@description('The location where the resources will be created.')
param location string = resourceGroup().location

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

@description('The resource ID of the VNet to which the private endpoint will be connected.')
param spokeVNetId string

@description('The name of the subnet in the VNet to which the private endpoint will be connected.')
param spokePrivateEndpointSubnetName string

@description('File upload storage account configuration')
param storageConfig object

@description('Resource naming configuration from naming module')
param resourcesNames object


@description('Networking resource group name')
param networkingResourceGroup string

@description('Environment name for storage account naming')
param environment string

@description('Enable malware scanning integration')
param enableMalwareScanning bool = true

@description('Override subscription level settings for storage account level defender configuration')
param overrideSubscriptionLevelSettings bool = true


@description('Log Analytics workspace ID for security alerts')
param logAnalyticsWorkspaceId string

@description('Enable Event Grid integration for scan result processing')
param enableEventGridIntegration bool = true

@description('Enable Event Grid subscriptions - set to true only after Function App code is deployed with working webhook endpoint')
param enableEventGridSubscriptions bool = false

@description('Process scan Function App webhook endpoint URL')
param processScanWebhookEndpoint string = ''

// ------------------
// VARIABLES
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

// ------------------
// RESOURCES
// ------------------

resource vnetSpoke 'Microsoft.Network/virtualNetworks@2024-07-01' existing = {
  scope: resourceGroup(spokeSubscriptionId, spokeResourceGroupName)
  name: spokeVNetName
}

resource spokePrivateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' existing = {
  parent: vnetSpoke
  name: spokePrivateEndpointSubnetName
}

module managedIdentity '../../../shared/bicep/managed-identity.bicep' = {
  name: 'fileUploadStorageManagedIdentity'
  params: {
    name: 'id-${resourcesNames.storageAccount}fileupload-StorageBlobDataContributor'
    location: location
    tags: tags
  }
}

module storageAccount '../../../shared/bicep/storage/storage.bicep' = {
  name: 'fileUploadStorageAccount'
  params: {
    name: 'strspdocupload${environment}'
    location: location
    tags: tags
    kind: 'StorageV2'
    sku: storageConfig.sku
    accessTier: storageConfig.accessTier
    supportsHttpsTrafficOnly: true
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      ipRules: []
      virtualNetworkRules: []
    }
  }
}

module privateEndpoint '../../../shared/bicep/network/private-networking-spoke.bicep' = {
  name: 'fileUploadStoragePrivateEndpoint'
  scope: resourceGroup(spokeSubscriptionId, networkingResourceGroup)
  params: {
    azServicePrivateDnsZoneName: 'privatelink.blob.${az.environment().suffixes.storage}'
    azServiceId: storageAccount.outputs.id
    privateEndpointName: 'pep-strspdocupload${environment}'
    privateEndpointSubResourceName: 'blob'
    virtualNetworkLinks: spokeVNetLinks
    subnetId: spokePrivateEndpointSubnet.id
  }
}

module blobService '../../../shared/bicep/storage/storage.blobsvc.bicep' = {
  name: 'fileUploadStorageBlobService'
  params: {
    storageAccountName: storageAccount.outputs.name
    deleteRetentionPolicy: true
    deleteRetentionPolicyDays: 30
    containers: [
      {
        name: storageConfig.containerName
        publicAccess: 'None'
      }
      {
        name: 'quarantine'
        publicAccess: 'None'
      }
      {
        name: 'clean'
        publicAccess: 'None'
      }
    ]
  }
}


module roleAssignment '../../../shared/bicep/role-assignments/role-assignment.bicep' = {
  name: 'fileUploadStorageRoleAssignment'
  params: {
    name: 'ra-fileupload-storage-${uniqueString(managedIdentity.outputs.id, storageAccount.outputs.id)}'
    principalId: managedIdentity.outputs.principalId
    roleDefinitionId: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // Storage Blob Data Contributor
    resourceId: storageAccount.outputs.id
  }
}


module defenderStoragePermissions '../../../shared/bicep/role-assignments/defender-storage-permissions.bicep' = if (enableMalwareScanning) {
  name: 'documentUploadDefenderPermissions'
  params: {
    storageAccountId: storageAccount.outputs.id
    eventGridSystemTopicPrincipalId: '' // Defender manages its own Event Grid permissions
    enableEventGridPermissions: false // Defender handles Event Grid permissions automatically
    enableDefenderPermissions: enableMalwareScanning
  }
}

// Configure storage account-level Defender for Storage settings with override
module defenderStorageAccountConfig '../../../shared/bicep/security/defender-storage-account-config.bicep' = if (enableMalwareScanning && !empty(logAnalyticsWorkspaceId)) {
  name: 'documentUploadDefenderConfig'
  params: {
    storageAccountId: storageAccount.outputs.id
    enableMalwareScanning: enableMalwareScanning
    malwareScanningCapGBPerMonth: 1000
    enableSensitiveDataDiscovery: true
    overrideSubscriptionLevelSettings: overrideSubscriptionLevelSettings
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    customEventGridTopicId: enableEventGridIntegration ? customEventGridTopic!.outputs.topicId : ''
    enableBlobIndexTags: false  // Set to false to optimize costs - must be configured post-deployment via Azure Portal
  }
  dependsOn: [
    defenderStoragePermissions
  ]
}

// Custom Event Grid topic for Defender for Storage scan results - always created when Event Grid integration is enabled
module customEventGridTopic '../../../shared/bicep/event-grid/custom-event-grid-topic.bicep' = if (enableEventGridIntegration) {
  name: 'documentUploadCustomEventGridTopic'
  params: {
    topicName: 'evgt-${storageAccount.outputs.name}-custom-scan-results'
    location: location
    tags: tags
    enableSystemAssignedIdentity: true
    publicNetworkAccess: 'Enabled'
    inputSchema: 'EventGridSchema'
    disableLocalAuth: false
  }
}

// Event Grid subscription for custom topic - only created when enableEventGridSubscriptions=true (after Function App code deployment)
module customTopicEventSubscription '../../../shared/bicep/event-grid/custom-topic-subscription.bicep' = if (enableEventGridIntegration && enableEventGridSubscriptions && !empty(processScanWebhookEndpoint)) {
  name: 'customTopicEventSubscription'
  params: {
    subscriptionName: 'defender-scan-processing'
    customTopicId: customEventGridTopic!.outputs.topicId
    destinationType: 'webhook'
    webhookEndpointUrl: processScanWebhookEndpoint
    eventTypes: [
      'Microsoft.Security.MalwareScanningResult'
    ]
    containerName: storageConfig.containerName
    enableAdvancedFiltering: true
    maxDeliveryAttempts: 3
    eventTimeToLiveInMinutes: 1440
  }
}

// ------------------
// OUTPUTS
// ------------------

@description('The resource ID of the file upload storage account.')
output storageAccountId string = storageAccount.outputs.id

@description('The name of the file upload storage account.')
output storageAccountName string = storageAccount.outputs.name

@description('The resource ID of the managed identity for file upload storage.')
output managedIdentityId string = managedIdentity.outputs.id

@description('The principal ID of the managed identity for file upload storage.')
output managedIdentityPrincipalId string = managedIdentity.outputs.principalId

@description('The client ID of the managed identity for file upload storage.')
output managedIdentityClientId string = managedIdentity.outputs.clientId

@description('The name of the blob container for file uploads.')
output containerName string = storageConfig.containerName

@description('Indicates whether malware scanning is enabled.')
output malwareScanningEnabled bool = enableMalwareScanning

@description('Custom Event Grid topic ID used for Defender scan results.')
output customEventGridTopicId string = enableEventGridIntegration ? customEventGridTopic!.outputs.topicId : ''

@description('Custom Event Grid topic endpoint URL.')
output customEventGridTopicEndpoint string = enableEventGridIntegration ? customEventGridTopic!.outputs.topicEndpoint : ''

@description('Event Grid subscription resource ID (only when subscriptions are enabled).')
output eventGridSubscriptionId string = (enableEventGridIntegration && enableEventGridSubscriptions) ? customTopicEventSubscription!.outputs.eventSubscriptionId : ''

@description('Event Grid subscription name (only when subscriptions are enabled).')
output eventGridSubscriptionName string = (enableEventGridIntegration && enableEventGridSubscriptions) ? customTopicEventSubscription!.outputs.eventSubscriptionName : ''

@description('Indicates whether Event Grid subscriptions are enabled.')
output eventGridSubscriptionsEnabled bool = enableEventGridSubscriptions
