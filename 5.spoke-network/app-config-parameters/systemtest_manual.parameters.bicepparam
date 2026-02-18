using '../main.appconfig-update.bicep'

param parEnvironment = 'systemtest_manual'

param parSharedServicesSubscriptionId = '66482e26-764b-4717-ae2f-fab6b8dd1379'

param parSharedServicesResourceGroup = 'rg-rsp-sharedservices-spoke-systemtest-uks'

param parAppConfigurationStoreName = 'appcs-rsp-shared-rwcwe-manualtest-uks'

param parAppConfigurationValues = [
  {
    key: 'AppSettings:ManagedIdentityRtsClientID'
    label: ''
    value: '24a17ac8-6f28-44bb-a936-62871e84018e'
    contentType: 'text/plain'
  }
]
