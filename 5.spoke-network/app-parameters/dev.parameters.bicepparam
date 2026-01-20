using '../main.application.bicep'

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
param parEnableFrontDoorPrivateLinkForIRAS = true
param parEnableFrontDoorPrivateLinkForCMS = true
param parEnableFunctionAppPrivateEndpoints = true
param parEnableKeyVaultPrivateEndpoints = true
param parEnableAppConfigPrivateEndpoints = true
param parFrontDoorCustomDomains = []

// ValidateIRASID Function Authentication Configuration
// Allowed applications and principals are automatically retrieved from App Configuration Managed Identity
param parEnableValidateIrasIdAuth = true
param parValidateIrasIdClientSecretSettingName = 'MICROSOFT_PROVIDER_AUTHENTICATION_SECRET'
param parValidateIrasIdOpenIdIssuer = 'https://login.microsoftonline.com/8e1f0aca-d87d-4f20-939e-36243d574267/v2.0'

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
      enabled: true // Enable for encryption
      keyName: 'key-clean-storage-dev' // Environment-specific key name
      enableInfrastructureEncryption: true
      keyRotationEnabled: true // Automatic key version updates
    }
    retention: {
      enabled: false // Disable retention for clean storage
      retentionDays: 0 // No auto-deletion
    }
  }
  staging: {
    account: {
      sku: 'Standard_LRS' // Cost-optimized for dev
      accessTier: 'Hot'
      containerName: 'staging'
    }
    encryption: {
      enabled: true // Enable for encryption
      keyName: 'key-staging-storage-dev' // Environment-specific key name
      enableInfrastructureEncryption: true
      keyRotationEnabled: true // Automatic key version updates
    }
    retention: {
      enabled: true // Enable retention for staging
      retentionDays: 7 // Short retention for staging files
    }
  }
  quarantine: {
    account: {
      sku: 'Standard_LRS' // Cost-optimized 
      accessTier: 'Cool' // Cool tier for quarantine
      containerName: 'quarantine'
    }
    encryption: {
      enabled: true // Enable for encryption
      keyName: 'key-quarantine-storage-dev' // Environment-specific key name
      enableInfrastructureEncryption: true
      keyRotationEnabled: true // Automatic key version updates
    }
    retention: {
      enabled: true // Enable retention for quarantine
      retentionDays: 15 // 15 days retention for analysis
    }
  }
}

// SKU configuration for all resource types - dev environment (cost-optimized)
param parSkuConfig = {
  appServicePlan: {
    webApp: 'B1'
    functionApp: 'B1'
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
  containerApp: {
    cpu: '0.5'
    memory: '1Gi'
    minReplicas: 1
    maxReplicas: 5
  }
  keyVault: 'standard'
  appConfiguration: 'standard'
  frontDoor: 'Premium_AzureFrontDoor'
}

param parAppConfigEncryptionConfig = {
  enabled: true
  keyName: 'key-appconfig-dev'
  keyRotationEnabled: true
}

// Network security configuration for dev environment
param parNetworkSecurityConfig = {
  defaultAction: 'Deny'
  bypass: 'AzureServices'
  httpsTrafficOnly: true
  quarantineBypass: 'None' // Strictest setting for quarantine storage
}

param parSpokeNetworks = [
  {
    subscriptionId: 'b83b4631-b51b-4961-86a1-295f539c826b'
    parEnvironment: 'dev'
    workloadName: 'container-app'
    zoneRedundancy: false
    ddosProtectionEnabled: 'Disabled'
    containerRegistryTier: 'Premium'
    deploy: true
    configurePrivateDNS: true
    devBoxPeering: true
    rgNetworking: 'rg-rsp-networking-spoke-dev-uks'
    vnet: 'vnet-rsp-networking-dev-uks-spoke'
    rgapplications: 'rg-rsp-applications-spoke-dev-uks'
    rgSharedServices: 'rg-rsp-sharedservices-spoke-dev-uks'
    rgStorage: 'rg-rsp-storage-spoke-dev-uks'
    deployWebAppSlot: false
    IDGENV: 'dev'
    appInsightsConnectionString: 'InstrumentationKey=5d4746f6-cea9-4d2e-ade9-a943edaafadb;IngestionEndpoint=https://uksouth-1.in.applicationinsights.azure.com/;LiveEndpoint=https://uksouth.livediagnostics.monitor.azure.com/;ApplicationId=1d5b29c1-8cfb-4346-a5aa-134095ec7821'
  }
]

param parClarityProjectId = ''
param parGoogleTagId = ''
param parCmsUri = ''
param parPortalUrl = ''
param parLogoutUrl = ''

// Allowed hosts for the dev environment to be used when the Web App is behind Front Door
// NOTE: This value is used for initial deployment. When Front Door is enabled,
// the app-config-update module will automatically update this with dynamic URLs
param parAllowedHosts = '*'

// indicates whether to use Front Door for the dev environment
param parUseFrontDoor = true

param useOneLogin = true
param paramWhitelistIPs = ''
param parEnableFrontDoorIPWhitelisting = true

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


param parMicrosoftEntraAuthority = ''
param parMicrosoftEntraAudience = '' 
param processDocuUploadManagedIdentityClientId =  ''
param harpProjectRecordsQuery = ''
param bgodatabase= ''
param bgodatabaseuser = ''
param bgodatabasepassword = ''


