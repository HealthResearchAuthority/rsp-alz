using '../main.application.bicep'

param parAdminLogin = ''

param parSqlAdminPhrase = ''

param parSqlAuditRetentionDays = 15

param parFileUploadStorageConfig = {
  containerName: 'document-uploads'
  sku: 'Standard_GRS'
  accessTier: 'Hot'
  allowPublicAccess: false
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
