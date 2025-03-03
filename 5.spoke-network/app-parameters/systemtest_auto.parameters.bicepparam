using '../main.application.bicep'

param parAdminLogin = ''

param parSqlAdminPhrase = ''

param parIrasContainerImageTag = 'rsp-irasservice:latest'

param parUserServiceContainerImageTag = 'rsp-usermanagementservice:latest'

param parQuestionSetContainerImageTag = 'rsp-questionsetservice:latest'

param parRtsContainerImageTag = 'rsp-rtsservice:latest'

param parClientID = ''

param parClientSecret = ''

param hubVNetId = '/subscriptions/15642d2a-27a2-4ee8-9eba-788bf7223d95/resourceGroups/rg-hra-connectivity/providers/Microsoft.Network/virtualHubs/vhub-rsp-uksouth'

param parSpokeNetworks = [
  {
    subscriptionId: '75875981-b04d-42c7-acc5-073e2e5e2e65'
    parEnvironment: 'automationtest'
    workloadName: 'container-app'
    zoneRedundancy: false
    ddosProtectionEnabled: 'Disabled'
    containerRegistryTier: 'Premium'
    deploy: false
    configurePrivateDNS: false
    devBoxPeering: false
    rgNetworking: 'rg-rsp-networking-spoke-systemtestauto-uks'
    vnet: 'vnet-rsp-networking-systemtestauto-uks-spoke'
    rgapplications: 'rg-rsp-applications-spoke-systemtestauto-uks'
    rgSharedServices: 'rg-rsp-sharedservices-spoke-systemtestauto-uks'
    rgStorage: 'rg-rsp-storage-spoke-systemtestauto-uks'
    deployWebAppSlot: false
    IDGENV: 'test'
    appInsightsConnectionString: 'InstrumentationKey=225c2ec1-bb7d-4c33-9d5f-cb89c117f2d6;IngestionEndpoint=https://uksouth-1.in.applicationinsights.azure.com/;LiveEndpoint=https://uksouth.livediagnostics.monitor.azure.com/;ApplicationId=3dc21d1c-0655-44cc-8ad3-cb4eab8c8c67'

  }
]
