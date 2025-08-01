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

@description('Blob delete retention policy configuration per storage type')
param retentionPolicyDays object = {
  staging: 7     // Short retention for staging files
  clean: 365     // Long retention for production files
  quarantine: 15 // Short retention for quarantine files
}

@description('Storage account configuration per storage type')
param storageAccountConfig object = {
  staging: {
    sku: 'Standard_LRS'
    accessTier: 'Hot'
    containerName: 'staging'
  }
  clean: {
    sku: 'Standard_GRS'  
    accessTier: 'Hot'
    containerName: 'clean'
  }
  quarantine: {
    sku: 'Standard_LRS'
    accessTier: 'Cool' 
    containerName: 'quarantine'
  }
}

@description('Network security configuration for storage accounts')
param networkSecurityConfig object = {
  defaultAction: 'Deny'
  bypass: 'AzureServices'
  httpsTrafficOnly: true
  quarantineBypass: 'None'
}

@description('Clean storage encryption configuration')
param cleanStorageEncryption object = {
  enabled: false
  keyVaultResourceId: ''
  keyName: ''
  enableInfrastructureEncryption: false
  keyRotationEnabled: true
}

@description('Staging storage encryption configuration')
param stagingStorageEncryption object = {
  enabled: false
  keyVaultResourceId: ''
  keyName: ''
  enableInfrastructureEncryption: false
  keyRotationEnabled: true
}

@description('Quarantine storage encryption configuration')
param quarantineStorageEncryption object = {
  enabled: false
  keyVaultResourceId: ''
  keyName: ''
  enableInfrastructureEncryption: false
  keyRotationEnabled: true
}

// ------------------
// RESOURCES
// ------------------

// Staging Storage Account - Where users initially upload files for malware scanning
module stagingStorage 'modules/document-storage.bicep' = {
  name: 'stagingStorageDeployment'
  params: {
    storageType: 'staging'
    location: location
    tags: tags
    environment: environment
    spokeVNetId: spokeVNetId
    spokePrivateEndpointSubnetName: spokePrivateEndpointSubnetName
    networkingResourceGroup: networkingResourceGroup
    storageConfig: storageAccountConfig.staging
    enableDeleteRetentionPolicy: retentionPolicyDays.staging > 0
    retentionPolicyDays: retentionPolicyDays.staging
    networkSecurityConfig: networkSecurityConfig
    // Encryption support for staging (NEW FEATURE)
    enableEncryption: stagingStorageEncryption.enabled
    encryptionConfig: stagingStorageEncryption
    // Malware scanning features (RESTORED)
    enableMalwareScanning: enableMalwareScanning
    overrideSubscriptionLevelSettings: overrideSubscriptionLevelSettings
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    enableEventGridIntegration: enableEventGridIntegration
    enableEventGridSubscriptions: enableEventGridSubscriptions
    processScanWebhookEndpoint: processScanWebhookEndpoint
    // Enhanced monitoring
    enableEnhancedMonitoring: false
    enableBlobIndexTags: false
  }
}

// Clean Storage Account - For verified safe files after scanning
module cleanStorage 'modules/document-storage.bicep' = {
  name: 'cleanStorageDeployment'
  params: {
    storageType: 'clean'
    location: location
    tags: tags
    environment: environment
    spokeVNetId: spokeVNetId
    spokePrivateEndpointSubnetName: spokePrivateEndpointSubnetName
    networkingResourceGroup: networkingResourceGroup
    storageConfig: storageAccountConfig.clean
    enableDeleteRetentionPolicy: retentionPolicyDays.clean > 0
    retentionPolicyDays: retentionPolicyDays.clean
    networkSecurityConfig: networkSecurityConfig
    enableEncryption: cleanStorageEncryption.enabled
    encryptionConfig: cleanStorageEncryption
  }
  dependsOn: [
    stagingStorage  // Deploy after staging to avoid DNS zone conflicts
  ]
}

// Quarantine Storage Account - For infected/suspicious files
module quarantineStorage 'modules/document-storage.bicep' = {
  name: 'quarantineStorageDeployment'
  params: {
    storageType: 'quarantine'
    location: location
    tags: tags
    environment: environment
    spokeVNetId: spokeVNetId
    spokePrivateEndpointSubnetName: spokePrivateEndpointSubnetName
    networkingResourceGroup: networkingResourceGroup
    storageConfig: storageAccountConfig.quarantine
    enableDeleteRetentionPolicy: retentionPolicyDays.quarantine > 0
    retentionPolicyDays: retentionPolicyDays.quarantine
    networkSecurityConfig: networkSecurityConfig
    // Encryption support for quarantine (NEW FEATURE)
    enableEncryption: quarantineStorageEncryption.enabled
    encryptionConfig: quarantineStorageEncryption
    // Malware scanning (disabled for quarantine)
    enableMalwareScanning: false
    overrideSubscriptionLevelSettings: overrideSubscriptionLevelSettings
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    enableEventGridIntegration: false
    enableEventGridSubscriptions: false
    processScanWebhookEndpoint: ''
    // Enhanced monitoring features (RESTORED)
    enableEnhancedMonitoring: true
    enableBlobIndexTags: true
  }
  dependsOn: [
    cleanStorage  // Deploy after clean storage to avoid DNS zone conflicts
  ]
}

// ------------------
// OUTPUTS
// ------------------


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
