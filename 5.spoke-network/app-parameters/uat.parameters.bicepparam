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
      keyName: 'key-clean-storage-uat'      
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
      keyName: 'key-staging-storage-uat'    
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
      keyName: 'key-quarantine-storage-uat' 
      enableInfrastructureEncryption: true  
      keyRotationEnabled: true              
    }
    retention: {
      enabled: true                         
      retentionDays: 30                     
    }
  }
}

// SKU configuration for all resource types - UAT environment (balanced performance/cost)
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
  keyName: 'key-appconfig-uat'
  keyRotationEnabled: true
}

// Network security configuration for UAT environment
param parNetworkSecurityConfig = {
  defaultAction: 'Deny'        
  bypass: 'AzureServices'      
  httpsTrafficOnly: true       
  quarantineBypass: 'None'     
}

param parSpokeNetworks = [
  {
    subscriptionId: 'e1a1a4ff-2db5-4de3-b7e5-6d51413f6390'
    parEnvironment: 'uat'
    workloadName: 'container-app'
    zoneRedundancy: false
    ddosProtectionEnabled: 'Disabled'
    containerRegistryTier: 'Premium'
    deploy: false
    configurePrivateDNS: true
    devBoxPeering: false
    rgNetworking: 'rg-rsp-networking-spoke-uat-uks'
    vnet: 'vnet-rsp-networking-uat-uks-spoke'
    rgapplications: 'rg-rsp-applications-spoke-uat-uks'
    rgSharedServices: 'rg-rsp-sharedservices-spoke-uat-uks'
    rgStorage: 'rg-rsp-storage-spoke-uat-uks'
    deployWebAppSlot: false
    IDGENV: 'test'
    appInsightsConnectionString: 'InstrumentationKey=58f85e46-e52f-45cd-835e-a850068cbe46;IngestionEndpoint=https://uksouth-1.in.applicationinsights.azure.com/;LiveEndpoint=https://uksouth.livediagnostics.monitor.azure.com/;ApplicationId=888acb96-8b54-4078-b449-09c98201da06'
  }
]

// Allowed hosts for the UAT environment to be used when the Web App is behind Front Door
// NOTE: This value is used for initial deployment. When Front Door is enabled,
// the app-config-update module will automatically update this with dynamic URLs
param parAllowedHosts = '*'

// indicates whether to use Front Door for the UAT environment
param parUseFrontDoor = true

param useOneLogin = true

param paramWhitelistIPs = ''
param parEnableFrontDoorIPWhitelisting = false

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


param parMicrosoftEntraAuthority = ''
param parMicrosoftEntraAudience = ''
param processDocuUploadManagedIdentityClientId =  ''
param harpProjectRecordsQuery = ''
param bgodatabase= ''
param bgodatabaseuser = ''
param bgodatabasepassword = ''
