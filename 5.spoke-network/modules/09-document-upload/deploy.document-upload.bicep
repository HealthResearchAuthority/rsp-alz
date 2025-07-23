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
// RESOURCES
// ------------------

// Staging Storage Account - Where users initially upload files for malware scanning
module stagingStorage 'modules/staging-storage.bicep' = {
  name: 'stagingStorageDeployment'
  params: {
    location: location
    tags: tags
    environment: environment
    storageConfig: storageConfig
    spokeVNetId: spokeVNetId
    spokePrivateEndpointSubnetName: spokePrivateEndpointSubnetName
    networkingResourceGroup: networkingResourceGroup
    enableMalwareScanning: enableMalwareScanning
    overrideSubscriptionLevelSettings: overrideSubscriptionLevelSettings
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    enableEventGridIntegration: enableEventGridIntegration
    enableEventGridSubscriptions: enableEventGridSubscriptions
    processScanWebhookEndpoint: processScanWebhookEndpoint
  }
}

// Clean Storage Account - For verified safe files after scanning
module cleanStorage 'modules/clean-storage.bicep' = {
  name: 'cleanStorageDeployment'
  params: {
    location: location
    tags: tags
    environment: environment
    storageConfig: {
      sku: 'Standard_GRS'  // Higher availability for production files
      accessTier: 'Hot'    // Frequent access for clean files
    }
    spokeVNetId: spokeVNetId
    spokePrivateEndpointSubnetName: spokePrivateEndpointSubnetName
    networkingResourceGroup: networkingResourceGroup
  }
}

// Quarantine Storage Account - For infected/suspicious files
module quarantineStorage 'modules/quarantine-storage.bicep' = {
  name: 'quarantineStorageDeployment'
  params: {
    location: location
    tags: tags
    environment: environment
    // Quarantine storage parameters optimized for security and cost
    spokeVNetId: spokeVNetId
    spokePrivateEndpointSubnetName: spokePrivateEndpointSubnetName
    networkingResourceGroup: networkingResourceGroup
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}

// ------------------
// OUTPUTS
// ------------------

// Staging Storage Outputs (for backward compatibility)
@description('The resource ID of the staging storage account (backward compatibility).')
output storageAccountId string = stagingStorage.outputs.storageAccountId

@description('The name of the staging storage account (backward compatibility).')
output storageAccountName string = stagingStorage.outputs.storageAccountName

@description('The resource ID of the managed identity for staging storage (backward compatibility).')
output managedIdentityId string = stagingStorage.outputs.managedIdentityId

@description('The principal ID of the managed identity for staging storage (backward compatibility).')
output managedIdentityPrincipalId string = stagingStorage.outputs.managedIdentityPrincipalId

@description('The client ID of the managed identity for staging storage (backward compatibility).')
output managedIdentityClientId string = stagingStorage.outputs.managedIdentityClientId

@description('The name of the blob container for file uploads (backward compatibility).')
output containerName string = stagingStorage.outputs.containerName

// New Comprehensive Outputs
@description('Staging storage account details for initial file uploads.')
output stagingStorage object = {
  storageAccountId: stagingStorage.outputs.storageAccountId
  storageAccountName: stagingStorage.outputs.storageAccountName
  containerName: stagingStorage.outputs.containerName
  managedIdentityId: stagingStorage.outputs.managedIdentityId
  managedIdentityPrincipalId: stagingStorage.outputs.managedIdentityPrincipalId
  managedIdentityClientId: stagingStorage.outputs.managedIdentityClientId
}

@description('Clean storage account details for verified safe files.')
output cleanStorage object = {
  storageAccountId: cleanStorage.outputs.storageAccountId
  storageAccountName: cleanStorage.outputs.storageAccountName
  containerName: cleanStorage.outputs.containerName
  managedIdentityId: cleanStorage.outputs.managedIdentityId
  managedIdentityPrincipalId: cleanStorage.outputs.managedIdentityPrincipalId
  managedIdentityClientId: cleanStorage.outputs.managedIdentityClientId
}

@description('Quarantine storage account details for infected/suspicious files.')
output quarantineStorage object = {
  storageAccountId: quarantineStorage.outputs.storageAccountId
  storageAccountName: quarantineStorage.outputs.storageAccountName
  containerName: quarantineStorage.outputs.containerName
  managedIdentityId: quarantineStorage.outputs.managedIdentityId
  managedIdentityPrincipalId: quarantineStorage.outputs.managedIdentityPrincipalId
  managedIdentityClientId: quarantineStorage.outputs.managedIdentityClientId
}

@description('Indicates whether malware scanning is enabled.')
output malwareScanningEnabled bool = enableMalwareScanning

@description('Custom Event Grid topic ID used for Defender scan results.')
output customEventGridTopicId string = stagingStorage.outputs.customEventGridTopicId

@description('Custom Event Grid topic endpoint URL.')
output customEventGridTopicEndpoint string = stagingStorage.outputs.customEventGridTopicEndpoint

@description('Indicates whether Event Grid subscriptions are enabled.')
output eventGridSubscriptionsEnabled bool = enableEventGridSubscriptions

@description('All storage account IDs for process scan function permissions.')
output allStorageAccountIds array = [
  stagingStorage.outputs.storageAccountId
  cleanStorage.outputs.storageAccountId
  quarantineStorage.outputs.storageAccountId
]
