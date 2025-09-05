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
      keyName: 'key-clean-storage-autotest'
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
      keyName: 'key-staging-storage-autotest'
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
      keyName: 'key-quarantine-storage-autotest'
      enableInfrastructureEncryption: true
      keyRotationEnabled: true
    }
    retention: {
      enabled: true
      retentionDays: 15
    }
  }
}

// SKU configuration for all resource types - systemtest_auto environment
param parSkuConfig = {
  appServicePlan: {
    webApp: 'B1'        // Basic tier for test environments
    functionApp: 'B1'   // Basic tier for test environments
    cmsApp: 'B1'        // Basic tier for test environments
  }
  sqlDatabase: {
    name: 'GP_S_Gen5'           // General Purpose Serverless
    tier: 'GeneralPurpose'       // General Purpose tier
    family: 'Gen5'               // Gen5 hardware
    capacity: 6                  // 6 vCores (test environment)
    minCapacity: 4               // Minimum 4 vCores for serverless
    storageSize: '6GB'           // Small storage for test
    zoneRedundant: false         // No zone redundancy for cost savings
  }
  keyVault: 'standard'           // Standard tier (cost-effective)
  appConfiguration: 'standard'   // Standard tier (test doesn't need premium)
  frontDoor: 'Premium_AzureFrontDoor'  // Premium for WAF and private link features
}

// Network security configuration for auto test environment
param parNetworkSecurityConfig = {
  defaultAction: 'Deny'
  bypass: 'AzureServices'
  httpsTrafficOnly: true
  quarantineBypass: 'None'
}

param parSpokeNetworks = [
  {
    subscriptionId: '75875981-b04d-42c7-acc5-073e2e5e2e65'
    parEnvironment: 'automationtest'
    workloadName: 'container-app'
    zoneRedundancy: false
    ddosProtectionEnabled: 'Disabled'
    containerRegistryTier: 'Premium'
    deploy: false
    configurePrivateDNS: false
    devBoxPeering: true
    rgNetworking: 'rg-rsp-networking-spoke-systemtestauto-uks'
    vnet: 'vnet-rsp-networking-automationtest-uks-spoke'
    rgapplications: 'rg-rsp-applications-spoke-systemtestauto-uks'
    rgSharedServices: 'rg-rsp-sharedservices-spoke-systemtestauto-uks'
    rgStorage: 'rg-rsp-storage-spoke-systemtestauto-uks'
    deployWebAppSlot: false
    IDGENV: 'test'
    appInsightsConnectionString: 'InstrumentationKey=225c2ec1-bb7d-4c33-9d5f-cb89c117f2d6;IngestionEndpoint=https://uksouth-1.in.applicationinsights.azure.com/;LiveEndpoint=https://uksouth.livediagnostics.monitor.azure.com/;ApplicationId=3dc21d1c-0655-44cc-8ad3-cb4eab8c8c67'
  }
]

param parStorageAccountName = 'strrspstg'
param parStorageAccountKey = ''

// Allowed hosts for the systemtest_auto environment to be used when the Web App is behind Front Door
param parAllowedHosts = 'fd-rsp-applications-automationtest-uks-e7f6hkg3c5edhxex.a03.azurefd.net;irasportal-automationtest.azurewebsites.net'

// indicates whether to use Front Door for the systemtest_auto environment
param parUseFrontDoor = true

@description('Indicates whether to use One Login for the application')
param useOneLogin = true

param paramWhitelistIPs =  ''

param parClarityProjectId = ''
