using '../main.application.bicep'

param parAdminLogin = ''

param parSqlAdminPhrase = ''

param parIrasContainerImageTag = 'rsp-irasservice:latest'

param parUserServiceContainerImageTag = 'rsp-usermanagementservice:latest'

param parQuestionSetContainerImageTag = 'rsp-questionsetservice:latest'

param parRtsContainerImageTag = 'rsp-rtsservice:latest'

param parClientID = ''

param parClientSecret = ''

param parOneLoginAuthority = 'https://oidc.integration.account.gov.uk'

param parOneLoginPrivateKeyPem = ''

param parOneLoginClientId = 'GJVVaSadH1BG8GXohuWK3U8lUAA'

param parOneLoginIssuers = ['https://oidc.integration.account.gov.uk/']

param parSqlAuditRetentionDays = 15

param parFileUploadStorageConfig = {
  containerName: 'documentupload'
  sku: 'Standard_LRS'
  accessTier: 'Hot'
  allowPublicAccess: false
}

param parDefenderForStorageConfig = {
  enabled: false
  enableMalwareScanning: false
  enableSensitiveDataDiscovery: false
  malwareScanningCapGBPerMonth: 1000
  enforce: false
}

param parOverrideSubscriptionLevelSettings = false

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
    appInsightsConnectionString: 'InstrumentationKey=5d4746f6-cea9-4d2e-ade9-a943edaafadb;IngestionEndpoint=https://uksouth-1.in.applicationinsights.azure.com/;LiveEndpoint=https://uksouth.livediagnostics.monitor.azure.com/;ApplicationId=1d5b29c1-8cfb-4346-a5aa-134095ec7821'
  }
]
