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

param parOneLoginAuthority = 'https://oidc.account.gov.uk'

param parOneLoginIssuers = ['https://oidc.account.gov.uk/']

param parSqlAuditRetentionDays = 30

// Azure Front Door Configuration
param parEnableFrontDoor = true
param parFrontDoorWafMode = 'Prevention'
param parEnableFrontDoorRateLimiting = true
param parFrontDoorRateLimitThreshold = 2000
param parEnableFrontDoorCaching = false
param parFrontDoorCacheDuration = 'P1D'
param parEnableFrontDoorHttpsRedirect = true
param parEnableFrontDoorPrivateLinkForIRAS = true
param parEnableFrontDoorPrivateLinkForCMS = true
param parEnableFunctionAppPrivateEndpoints = true
param parEnableKeyVaultPrivateEndpoints = true
param parEnableAppConfigPrivateEndpoints = false
param parFrontDoorCustomDomains = []

// ValidateIRASID Function Authentication Configuration
// Note: Allowed applications and principals are automatically retrieved from App Configuration Managed Identity
param parEnableValidateIrasIdAuth = true
param parValidateIrasIdClientId = '2032f90d-d672-4ea3-9116-acd0cf20d4e3'
param parValidateIrasIdClientSecretSettingName = 'MICROSOFT_PROVIDER_AUTHENTICATION_SECRET'
param parValidateIrasIdOpenIdIssuer = 'https://login.microsoftonline.com/8e1f0aca-d87d-4f20-939e-36243d574267/v2.0'
param parValidateIrasIdAllowedAudiences = [
  'api://2032f90d-d672-4ea3-9116-acd0cf20d4e3'
]

param parDefenderForStorageConfig = {
  enabled: true
  enableMalwareScanning: true
  enableSensitiveDataDiscovery: true
  enforce: true
}

param parOverrideSubscriptionLevelSettings = true

param parSkipExistingRoleAssignments = true

param parCreateKVSecretsWithPlaceholders = false

// Storage configuration for all storage account types
param parStorageConfig = {
  clean: {
    account: {
      sku: 'Standard_ZRS'
      accessTier: 'Hot'
      containerName: 'clean'
    }
    encryption: {
      enabled: true
      keyName: 'key-clean-storage-prod'
      enableInfrastructureEncryption: true
      keyRotationEnabled: true
    }
    retention: {
      enabled: false
      retentionDays: 0
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
      keyName: 'key-staging-storage-prod'
      enableInfrastructureEncryption: true
      keyRotationEnabled: true
    }
    retention: {
      enabled: true
      retentionDays: 30
    }
  }
  quarantine: {
    account: {
      sku: 'Standard_ZRS'
      accessTier: 'Cool'
      containerName: 'quarantine'
    }
    encryption: {
      enabled: true
      keyName: 'key-quarantine-storage-prod'
      enableInfrastructureEncryption: true
      keyRotationEnabled: true
    }
    retention: {
      enabled: true
      retentionDays: 60
    }
  }
}

// SKU configuration for all resource types - Production environment (high performance & availability)
param parSkuConfig = {
  appServicePlan: {
    webApp: 'P2V3'
    functionApp: 'P1V3'
    cmsApp: 'P2V3'
  }
  sqlDatabase: {
    name: 'GP_Gen5'
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: 8
    minCapacity: 4
    storageSize: '64GB'
    zoneRedundant: true
  }
  containerApp: {
    cpu: '4.0'
    memory: '8Gi'
    minReplicas: 1
    maxReplicas: 10
  }
  keyVault: 'premium'
  appConfiguration: 'standard'
  frontDoor: 'Premium_AzureFrontDoor'
}

param parAppConfigEncryptionConfig = {
  enabled: true
  keyName: 'key-appconfig-production'
  keyRotationEnabled: true
}

// Network security configuration for production environment
param parNetworkSecurityConfig = {
  defaultAction: 'Deny'
  bypass: 'AzureServices'
  httpsTrafficOnly: true
  quarantineBypass: 'None'
}

param parSpokeNetworks = [
  {
    subscriptionId: 'd27a0dcc-453d-4bfa-9c3d-1447c6ea0119'
    parEnvironment: 'prod'
    workloadName: 'container-app'
    zoneRedundancy: true
    ddosProtectionEnabled: 'Enabled'
    containerRegistryTier: 'Premium'
    deploy: false
    configurePrivateDNS: true
    devBoxPeering: false
    rgNetworking: 'rg-rsp-networking-spoke-prod-uks'
    vnet: 'vnet-rsp-networking-prod-uks-spoke'
    rgapplications: 'rg-rsp-applications-spoke-prod-uks'
    rgSharedServices: 'rg-rsp-sharedservices-spoke-prod-uks'
    rgStorage: 'rg-rsp-storage-spoke-prod-uks'
    deployWebAppSlot: true
    IDGENV: 'production'
    appInsightsConnectionString: ''
  }
]

// Allowed hosts for the production environment to be used when the Web App is behind Front Door
// NOTE: This value is used for initial deployment. When Front Door is enabled,
// the app-config-update module will automatically update this with dynamic URLs
param parAllowedHosts = '*'

// indicates whether to use Front Door for the production environment
param parUseFrontDoor = true

param useOneLogin = true

param paramWhitelistIPs = ''
param parEnableFrontDoorIPWhitelisting = false

param parClarityProjectId = ''

param parCmsUri = ''

param parPortalUrl = ''

param parGoogleTagId = ''

param parApiRequestMaxConcurrency = 10

param parApiRequestPageSize = 100

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
param processDocuUploadManagedIdentityClientId = ''
param harpProjectRecordsQuery = ''
param bgodatabase= ''
param bgodatabaseuser = ''
param bgodatabasepassword = ''
