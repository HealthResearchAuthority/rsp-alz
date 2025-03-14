using '../main.application.bicep'

param parAdminLogin = ''

param parSqlAdminPhrase = ''

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
