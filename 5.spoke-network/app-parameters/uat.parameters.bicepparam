using '../main.application.bicep'

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
param parEnableFrontDoorPrivateLink = false
param parEnableFunctionAppPrivateEndpoints = true
param parEnableKeyVaultPrivateEndpoints = false
param parEnableAppConfigPrivateEndpoints = false
param parFrontDoorCustomDomains = []

param parDefenderForStorageConfig = {
  enabled: true
  enableMalwareScanning: true
  enableSensitiveDataDiscovery: true
  enforce: false
}

param parOverrideSubscriptionLevelSettings = true

param parSkipExistingRoleAssignments = false

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
      keyName: 'key-staging-storage-uat'    
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
      retentionDays: 90                     
    }
  }
}

// SKU configuration for all resource types - UAT environment (balanced performance/cost)
param parSkuConfig = {
  appServicePlan: {
    webApp: 'S2'        // Standard tier for better performance
    functionApp: 'S1'   // Standard tier for functions
    cmsApp: 'S1'        // Standard tier for CMS
  }
  sqlDatabase: {
    name: 'GP_Gen5'             // General Purpose (non-serverless)
    tier: 'GeneralPurpose'       // General Purpose tier
    family: 'Gen5'               // Gen5 hardware
    capacity: 8                  // 8 vCores for UAT performance
    minCapacity: 4               // Minimum capacity
    storageSize: '32GB'          // More storage for UAT
    zoneRedundant: true          // Zone redundancy for UAT
  }
  keyVault: 'standard'           // Standard tier
  appConfiguration: 'standard'   // Standard tier
  frontDoor: 'Premium_AzureFrontDoor'  // Premium for advanced features
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
    subscriptionId: ''
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
