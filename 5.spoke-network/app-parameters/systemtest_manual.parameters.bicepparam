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

param parOneLoginClientId = 'bBf29bxbeNGjYFRA_jvrge3hsBI'

param parOneLoginIssuers = ['https://oidc.integration.account.gov.uk/']

param parSqlAuditRetentionDays = 15

param parFileUploadStorageConfig = {
  containerName: 'documentuploadmanualtest'
  sku: 'Standard_LRS'
  accessTier: 'Hot'
  allowPublicAccess: false
}

// Azure Front Door Configuration
param parEnableFrontDoor = true
param parFrontDoorWafMode = 'Detection'
param parEnableFrontDoorRateLimiting = true
param parFrontDoorRateLimitThreshold = 1000
param parEnableFrontDoorCaching = false
param parFrontDoorCacheDuration = 'P1D'
param parEnableFrontDoorHttpsRedirect = true
param parEnableFrontDoorPrivateLink = false
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
    deploy: false
    configurePrivateDNS: false
    devBoxPeering: false
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

param parStorageAccountName = 'strspstagngdev'
param parStorageAccountKey = ''
