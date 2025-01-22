using '../main.application.bicep'

param parAdminLogin = ''

param parSqlAdminPhrase = ''

param hubVNetId = '/subscriptions/15642d2a-27a2-4ee8-9eba-788bf7223d95/resourceGroups/rg-hra-connectivity/providers/Microsoft.Network/virtualHubs/vhub-rsp-uksouth'

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
  }
]
