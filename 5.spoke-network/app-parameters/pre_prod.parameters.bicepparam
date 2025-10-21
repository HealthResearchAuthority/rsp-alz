using '../main.application.bicep'

param parLogoutUrl = ''

param logAnalyticsWorkspaceId = ''

param parAdminLogin = ''

param parSqlAdminPhrase = ''

param parIrasContainerImageTag = 'rsp-irasservice:latest'

param parUserServiceContainerImageTag = 'rsp-usermanagementservice:latest'

param parRtsContainerImageTag = 'rsp-rtsservice:latest'

param parClientID = ''

param parClientSecret = ''

param parOneLoginAuthority = 'https://oidc.integration.account.gov.uk'

param parOneLoginIssuers = ['https://oidc.integration.account.gov.uk/']

param parSqlAuditRetentionDays = 15

// Azure Front Door Configuration
param parEnableFrontDoor = true
param parFrontDoorWafMode = 'Detection'
param parEnableFrontDoorRateLimiting = true
param parFrontDoorRateLimitThreshold = 1000
param parEnableFrontDoorCaching = false
param parFrontDoorCacheDuration = 'P1D'
param parEnableFrontDoorHttpsRedirect = true
param parEnableFrontDoorPrivateLink = true
param parEnableFunctionAppPrivateEndpoints = true
param parEnableKeyVaultPrivateEndpoints = true
param parEnableAppConfigPrivateEndpoints = false
param parFrontDoorCustomDomains = []

param parDefenderForStorageConfig = {
  enabled: true
  enableMalwareScanning: false
  enableSensitiveDataDiscovery: true
  enforce: false
}

param parOverrideSubscriptionLevelSettings = true

param parSkipExistingRoleAssignments = true

param parCreateKVSecretsWithPlaceholders = false

// Storage configuration for all storage account types
param parStorageConfig = {
  clean: {
    account: {
      sku: 'Standard_LRS'
      accessTier: 'Hot'
      containerName: 'clean'
    }
    encryption: {
      enabled: true
      keyName: 'key-clean-storage-preprod'
      enableInfrastructureEncryption: true
      keyRotationEnabled: true
    }
    retention: {
      enabled: false
      retentionDays: 7
    }
  }
  staging: {
    account: {
      sku: 'Standard_LRS'
      accessTier: 'Hot'
      containerName: 'staging'
    }
    encryption: {
      enabled: true
      keyName: 'key-staging-storage-preprod'
      enableInfrastructureEncryption: true
      keyRotationEnabled: true
    }
    retention: {
      enabled: true
      retentionDays: 15
    }
  }
  quarantine: {
    account: {
      sku: 'Standard_LRS'
      accessTier: 'Cool'
      containerName: 'quarantine'
    }
    encryption: {
      enabled: true
      keyName: 'key-quarantine-storage-preprod'
      enableInfrastructureEncryption: true
      keyRotationEnabled: true
    }
    retention: {
      enabled: true
      retentionDays: 30
    }
  }
}

// SKU configuration for all resource types - Pre-Production environment
param parSkuConfig = {
  appServicePlan: {
    webApp: 'B3'
    functionApp: 'B3'
    cmsApp: 'B3'
  }
  sqlDatabase: {
    name: 'GP_S_Gen5'
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: 6
    minCapacity: 4
    storageSize: '6GB'
    zoneRedundant: false
  }
  keyVault: 'standard'
  appConfiguration: 'standard'
  frontDoor: 'Premium_AzureFrontDoor'
}

// Network security configuration for pre-production environment
param parNetworkSecurityConfig = {
  defaultAction: 'Deny'
  bypass: 'AzureServices'
  httpsTrafficOnly: true
  quarantineBypass: 'None'
}

param parSpokeNetworks = [
  {
    subscriptionId: 'be1174fc-09c8-470f-9409-d0054ab9586a'
    parEnvironment: 'preprod'
    workloadName: 'container-app'
    zoneRedundancy: false
    ddosProtectionEnabled: 'Disabled'
    containerRegistryTier: 'Premium'
    deploy: false
    configurePrivateDNS: true
    devBoxPeering: false
    rgNetworking: 'rg-rsp-networking-spoke-preprod-uks'
    vnet: 'vnet-rsp-networking-preprod-uks-spoke'
    rgapplications: 'rg-rsp-applications-spoke-preprod-uks'
    rgSharedServices: 'rg-rsp-sharedservices-spoke-preprod-uks'
    rgStorage: 'rg-rsp-storage-spoke-preprod-uks'
    deployWebAppSlot: false
    IDGENV: 'integration'
    appInsightsConnectionString: ''
  }
]

param parStorageAccountName = 'strrspstg'
param parStorageAccountKey = ''

// Allowed hosts for the pre-production environment to be used when the Web App is behind Front Door
// NOTE: This value is used for initial deployment. When Front Door is enabled,
// the app-config-update module will automatically update this with dynamic URLs
param parAllowedHosts = '*'

// indicates whether to use Front Door for the pre-production environment
param parUseFrontDoor = true

@description('Indicates whether to use One Login for the application')
param useOneLogin = true

param paramWhitelistIPs = ''

param parClarityProjectId = ''

param parCmsUri = ''

param parPortalUrl = ''

param parGoogleTagId = ''

param parApiRequestMaxConcurrency = 8

param parApiRequestPageSize = 50

param parRtsApiBaseUrl = ''

param parRtsAuthApiBaseUrl = ''

param parCleanStorageAccountKey = ''
param parStagingStorageAccountKey = ''
param parQuarantineStorageAccountKey = ''
param parCleanStorageAccountName = ''
param parStagingStorageAccountName = ''
param parQuarantineStorageAccountName = ''


param parApplicationServiceApplicationId = '' 
param processDocuUploadManagedIdentityClientId =  ''
