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
      keyName: 'key-clean-storage-manualtest'
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
      keyName: 'key-staging-storage-manualtest'
      enableInfrastructureEncryption: true
      keyRotationEnabled: true
    }
    retention: {
      enabled: true
      retentionDays: 7
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
      keyName: 'key-quarantine-storage-manualtest'
      enableInfrastructureEncryption: true
      keyRotationEnabled: true
    }
    retention: {
      enabled: true
      retentionDays: 15
    }
  }
}

// SKU configuration for all resource types - systemtest_manual environment
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
  keyName: 'key-appconfig-systemtest-manual'
  keyRotationEnabled: true
}

// Network security configuration for manual test environment
param parNetworkSecurityConfig = {
  defaultAction: 'Deny'
  bypass: 'AzureServices'
  httpsTrafficOnly: true
  quarantineBypass: 'None'
}

param parSpokeNetworks = [
  {
    subscriptionId: '66482e26-764b-4717-ae2f-fab6b8dd1379'
    parEnvironment: 'manualtest'
    workloadName: 'container-app'
    zoneRedundancy: false
    ddosProtectionEnabled: 'Disabled'
    containerRegistryTier: 'Premium'
    deploy: true
    configurePrivateDNS: true
    devBoxPeering: true
    rgNetworking: 'rg-rsp-networking-spoke-systemtest-uks'
    vnet: 'vnet-rsp-networking-manualtest-uks-spoke'
    rgapplications: 'rg-rsp-applications-spoke-systemtest-uks'
    rgSharedServices: 'rg-rsp-sharedservices-spoke-systemtest-uks'
    rgStorage: 'rg-rsp-storage-spoke-systemtest-uks'
    deployWebAppSlot: false
    IDGENV: 'test'
    appInsightsConnectionString: 'InstrumentationKey=1f99c9ac-add2-45f4-b2f9-e57c455f0d71;IngestionEndpoint=https://uksouth-1.in.applicationinsights.azure.com/;LiveEndpoint=https://uksouth.livediagnostics.monitor.azure.com/;ApplicationId=fb4cfc88-bc43-454f-8fc0-c872415ea77d'
  }
]

// Allowed hosts for the systemtest_manual environment to be used when the Web App is behind Front Door
// NOTE: This value is used for initial deployment. When Front Door is enabled,
// the app-config-update module will automatically update this with dynamic URLs
param parAllowedHosts = 'fd-rsp-applications-manualtest-uks-a9ducvbchybpasgn.a01.azurefd.net;irasportal-manualtest.azurewebsites.net'

// indicates whether to use Front Door for the systemtest_manual environment
param parUseFrontDoor = true

param useOneLogin = true

param paramWhitelistIPs = ''
param parEnableFrontDoorIPWhitelisting = true

param parClarityProjectId = ''

param parGoogleTagId = ''

param parCmsUri = ''

param parPortalUrl = ''

param parLogoutUrl = ''

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
