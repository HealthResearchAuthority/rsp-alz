using '../main.application.bicep'

param parLogoutUrl = ''

param logAnalyticsWorkspaceId = ''

param parAdminLogin = ''

param parSqlAdminPhrase = ''

param parIrasContainerImageTag = 'rsp-irasservice:latest'

param parUserServiceContainerImageTag = 'rsp-usermanagementservice:latest'

param parQuestionSetContainerImageTag = 'rsp-questionsetservice:latest'

param parRtsContainerImageTag = 'rsp-rtsservice:latest'

param parClientID = ''

param parClientSecret = ''

param parOneLoginAuthority = 'https://oidc.integration.account.gov.uk'

param parOneLoginPrivateKeyPem = ''

param parOneLoginClientId = 'WlsPS-_Zpm64UhTpf5zj9_BnAN4'

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
  keyVault: 'standard'
  appConfiguration: 'standard'
  frontDoor: 'Premium_AzureFrontDoor'
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
    appInsightsConnectionString: 'InstrumentationKey=225c2ec1-bb7d-4c33-9d5f-cb89c117f2d6;IngestionEndpoint=https://uksouth-1.in.applicationinsights.azure.com/;LiveEndpoint=https://uksouth.livediagnostics.monitor.azure.com/;ApplicationId=3dc21d1c-0655-44cc-8ad3-cb4eab8c8c67'
  }
]

param parStorageAccountName = 'strrspstg'
param parStorageAccountKey = ''

// Allowed hosts for the UAT environment to be used when the Web App is behind Front Door
param parAllowedHosts = '*'

// indicates whether to use Front Door for the UAT environment
param parUseFrontDoor = true

@description('Indicates whether to use One Login for the application')
param useOneLogin = true

param paramWhitelistIPs = ''

param parClarityProjectId = ''

param parCmsUri = ''
