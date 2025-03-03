using '../main.application.bicep'

param parAdminLogin = ''

param parSqlAdminPhrase = ''

param hubVNetId = '/subscriptions/15642d2a-27a2-4ee8-9eba-788bf7223d95/resourceGroups/rg-hra-connectivity/providers/Microsoft.Network/virtualHubs/vhub-rsp-uksouth'

param parIrasContainerImageTag = 'rsp-irasservice:latest'

param parUserServiceContainerImageTag = 'rsp-usermanagementservice:latest'

param parQuestionSetContainerImageTag = 'rsp-questionsetservice:latest'

param parRtsContainerImageTag = 'rsp-rtsservice:latest'

param parClientID = ''

param parClientSecret = ''

param parSpokeNetworks = [
  {
    subscriptionId: 'b83b4631-b51b-4961-86a1-295f539c826b'
    parEnvironment: 'dev'
    workloadName: 'container-app'
    zoneRedundancy: false
    ddosProtectionEnabled: 'Disabled'
    containerRegistryTier: 'Premium'
    deploy: true
    configurePrivateDNS: true
    devBoxPeering: true
    rgNetworking: 'rg-rsp-networking-spoke-dev-uks'
    vnet: 'vnet-rsp-networking-dev-uks-spoke'
    rgapplications: 'rg-rsp-applications-spoke-dev-uks'
    rgSharedServices: 'rg-rsp-sharedservices-spoke-dev-uks'
    rgStorage: 'rg-rsp-storage-spoke-dev-uks'
    deployWebAppSlot: false
    IDGENV: 'dev'
    appInsightsConnectionString: 'InstrumentationKey=1925d527-9a3a-4439-9bf5-375666529422;IngestionEndpoint=https://uksouth-1.in.applicationinsights.azure.com/;LiveEndpoint=https://uksouth.livediagnostics.monitor.azure.com/;ApplicationId=0dd21ec7-c4a7-40da-8c7e-75f31d979301'

  }
]
