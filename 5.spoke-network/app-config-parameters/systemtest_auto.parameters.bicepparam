using '../main.appconfig-update.bicep'

param parEnvironment = 'automationtest'

param parSharedServicesSubscriptionId = '75875981-b04d-42c7-acc5-073e2e5e2e65'

param parSharedServicesResourceGroup = 'rg-rsp-sharedservices-spoke-systemtestauto-uks'

param parAppConfigurationStoreName = 'appcs-rsp-shared-ryefn-automationtest-uks'

param parAppConfigurationValues = [
  {
    key: 'AppSettings:ManagedIdentityRtsClientID'
    label: ''
    value: '47626cc0-009a-4f48-94d7-b0160145eff8'
    contentType: 'text/plain'
  }
]
