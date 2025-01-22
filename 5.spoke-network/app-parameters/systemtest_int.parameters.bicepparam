using '../main.application.bicep'

param parAdminLogin = ''

param parSqlAdminPhrase = ''

param hubVNetId = '/subscriptions/15642d2a-27a2-4ee8-9eba-788bf7223d95/resourceGroups/rg-hra-connectivity/providers/Microsoft.Network/virtualHubs/vhub-rsp-uksouth'

param parSpokeNetworks = [
  {
    subscriptionId: 'c9d1b222-c47a-43fc-814a-33083b8d3375'
    parEnvironment: 'integrationtest'
    workloadName: 'container-app'
    zoneRedundancy: false
    ddosProtectionEnabled: 'Disabled'
    containerRegistryTier: 'Premium'
    deploy: false
    configurePrivateDNS: false
    devBoxPeering: false
    rgNetworking: 'rg-rsp-networking-spoke-systemtestint-uks'
    vnet: 'vnet-rsp-networking-systemtestint-uks-spoke'
    rgapplications: 'rg-rsp-applications-spoke-systemtestint-uks'
    rgSharedServices: 'rg-rsp-sharedservices-spoke-systemtestint-uks'
    rgStorage: 'rg-rsp-storage-spoke-systemtestint-uks'
    deployWebAppSlot: false
  }
]
