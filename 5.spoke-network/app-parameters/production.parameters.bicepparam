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
param parEnableFrontDoorCaching = true
param parFrontDoorCacheDuration = 'P1D'
param parEnableFrontDoorHttpsRedirect = true
param parEnableFrontDoorPrivateLink = false
param parFrontDoorCustomDomains = []

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
