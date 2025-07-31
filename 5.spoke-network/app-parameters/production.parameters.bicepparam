using '../main.application.bicep'

param parAdminLogin = ''

param parSqlAdminPhrase = ''

param parSqlAuditRetentionDays = 15

param parFileUploadStorageConfig = {
  containerName: 'documentuploadprod'
  sku: 'Standard_GRS'
  accessTier: 'Hot'
  allowPublicAccess: false
}

// Azure Front Door Configuration
param parEnableFrontDoor = true
param parFrontDoorWafMode = 'Prevention'
param parEnableFrontDoorRateLimiting = true
param parFrontDoorRateLimitThreshold = 2000
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
      sku: 'Standard_GRS'      
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
      sku: 'Standard_GRS'      
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
      retentionDays: 90                     
    }
  }
  quarantine: {
    account: {
      sku: 'Standard_GRS'      
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
      retentionDays: 365                    
    }
  }
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
    subscriptionId: ''
    parEnvironment: 'prod'
    workloadName: 'container-app'
    zoneRedundancy: false
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
    deployWebAppSlot: false
  }
]
