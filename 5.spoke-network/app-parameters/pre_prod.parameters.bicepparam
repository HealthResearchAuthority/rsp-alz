using '../main.application.bicep'

param logAnalyticsWorkspaceId = ''

param parAdminLogin = ''

param parSqlAdminPhrase = ''

param parSqlAuditRetentionDays = 15

param parFileUploadStorageConfig = {
  containerName: 'documentuploadpreprod'
  sku: 'Standard_GRS'
  accessTier: 'Hot'
  allowPublicAccess: false
}

// Azure Front Door Configuration
param parEnableFrontDoor = true
param parFrontDoorWafMode = 'Prevention'
param parEnableFrontDoorRateLimiting = true
param parFrontDoorRateLimitThreshold = 1000
param parEnableFrontDoorCaching = false
param parFrontDoorCacheDuration = 'P1D'
param parEnableFrontDoorHttpsRedirect = true
param parEnableFrontDoorPrivateLink = false
param parFrontDoorCustomDomains = []

param parDefenderForStorageConfig = {
  enabled: true
  enableMalwareScanning: true
  enableSensitiveDataDiscovery: true
  enforce: true
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
      sku: 'Standard_LRS'      
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
      sku: 'Standard_LRS'      
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
      retentionDays: 90                     
    }
  }
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
    subscriptionId: ''
    parEnvironment: 'preprod'
    workloadName: 'container-app'
    zoneRedundancy: true
    ddosProtectionEnabled: 'Enabled'
    containerRegistryTier: 'Premium'
    deploy: false
    configurePrivateDNS: true
    devBoxPeering: false
    rgNetworking: 'rg-rsp-networking-spoke-preprod-uks'
    vnet: 'vnet-rsp-networking-preprod-uks-spoke'
    rgapplications: 'rg-rsp-applications-spoke-preprod-uks'
    rgSharedServices: 'rg-rsp-sharedservices-spoke-preprod-uks'
    rgStorage: 'rg-rsp-storage-spoke-preprod-uks'
    deployWebAppSlot: false
  }
]
