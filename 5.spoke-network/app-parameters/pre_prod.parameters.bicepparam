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

param parSqlAuditRetentionDays = 30

// Disable SQL authentication - use Azure AD only
param parEnableSqlAdminLogin = true

// Azure Front Door Configuration
param parEnableFrontDoor = true
param parFrontDoorWafMode = 'Detection'
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
// Allowed applications and principals are automatically retrieved from App Configuration Managed Identity
param parEnableValidateIrasIdAuth = true
param parValidateIrasIdClientSecretSettingName = 'MICROSOFT_PROVIDER_AUTHENTICATION_SECRET'
param parValidateIrasIdOpenIdIssuer = 'https://login.microsoftonline.com/8e1f0aca-d87d-4f20-939e-36243d574267/v2.0'

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
      keyName: 'key-clean-storage-preprod'
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
      sku: 'Standard_GRS'
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
      keyName: 'key-quarantine-storage-preprod'
      enableInfrastructureEncryption: true
      keyRotationEnabled: true
    }
    retention: {
      enabled: true
      retentionDays: 60
    }
  }
}

// SKU configuration for all resource types - Pre-Production environment (matching production)
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
  keyName: 'key-appconfig-pre-prod'
  keyRotationEnabled: true
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
    deployWebAppSlot: true
    IDGENV: 'integration'
    appInsightsConnectionString: ''
  }
]

// Allowed hosts for the pre-production environment to be used when the Web App is behind Front Door
// NOTE: This value is used for initial deployment. When Front Door is enabled,
// the app-config-update module will automatically update this with dynamic URLs
param parAllowedHosts = '*'

// indicates whether to use Front Door for the pre-production environment
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

// Failover/DR Configuration
param parEnableDatabaseFailover = false
param parSecondaryLocation = 'ukwest'

param parSecondarySpokeNetworks = [
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
    rgNetworking: 'rg-rsp-networking-spoke-preprod-ukw'
    vnet: 'vnet-rsp-networking-preprod-ukw-spoke'
    rgapplications: 'rg-rsp-applications-spoke-preprod-ukw'
    rgSharedServices: 'rg-rsp-sharedservices-spoke-preprod-ukw'
    rgStorage: 'rg-rsp-storage-spoke-preprod-ukw'
    deployWebAppSlot: false
    IDGENV: 'preprod'
    appInsightsConnectionString: ''
  }
]
