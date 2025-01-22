using '../main.application.bicep'

param parAdminLogin = ''

param parSqlAdminPhrase = ''

param hubVNetId = '/subscriptions/15642d2a-27a2-4ee8-9eba-788bf7223d95/resourceGroups/rg-hra-connectivity/providers/Microsoft.Network/virtualHubs/vhub-rsp-uksouth'

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
