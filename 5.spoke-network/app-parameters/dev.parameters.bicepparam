using '../main.application.bicep'

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

param parOneLoginClientId = 'GJVVaSadH1BG8GXohuWK3U8lUAA'

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
param parFrontDoorCustomDomains = []

param parDefenderForStorageConfig = {
  enabled: true
  enableMalwareScanning: false
  enableSensitiveDataDiscovery: true
  enforce: false
}

param parOverrideSubscriptionLevelSettings = true

// Blob retention policy configuration for dev environment
param parBlobRetentionPolicyDays = {
  staging: 7       // Short retention for staging files
  clean: 30        // Shorter retention for dev environment  
  quarantine: 15   // 15 days retention for dev forensic analysis
}

// Storage account configuration for dev environment
param parStorageAccountConfig = {
  staging: {
    sku: 'Standard_LRS'      // Cost-optimized for dev
    accessTier: 'Hot'
    containerName: 'staging'
  }
  clean: {
    sku: 'Standard_LRS'      // Cost-optimized for dev (not GRS)
    accessTier: 'Hot'
    containerName: 'clean'
  }
  quarantine: {
    sku: 'Standard_LRS'      // Cost-optimized 
    accessTier: 'Cool'       // Cool tier for quarantine
    containerName: 'quarantine'
  }
}

// Network security configuration for dev environment
param parNetworkSecurityConfig = {
  defaultAction: 'Deny'        // Maintain security even in dev
  bypass: 'AzureServices'      // Allow Azure services for operational flexibility
  httpsTrafficOnly: true       // Always enforce HTTPS
  quarantineBypass: 'None'     // Strictest setting for quarantine storage
}

// Clean storage encryption configuration for dev environment
param parCleanStorageEncryption = {
  enabled: true                          // Enable for testing encryption
  keyName: 'key-clean-storage-dev'      // Environment-specific key name
  enableInfrastructureEncryption: true  // Double encryption for enhanced security
  keyRotationEnabled: true              // Automatic key version updates
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
