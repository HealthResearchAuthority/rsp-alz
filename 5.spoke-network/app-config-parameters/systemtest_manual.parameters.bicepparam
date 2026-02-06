using '../main.appconfig-update.bicep'

param parEnvironment = 'systemtest_manual'

param parSharedServicesSubscriptionId = '66482e26-764b-4717-ae2f-fab6b8dd1379'

param parSharedServicesResourceGroup = 'rg-rsp-sharedservices-spoke-systemtest-uks'

param parAppConfigurationStoreName = 'appcs-rsp-shared-rwcwe-manualtest-uks'

param parAppConfigurationValues = [
    {
    key: 'AppSettings:ProjectRecordValidationScopes'
    label: 'portal'
    value: 'api://ca77020d-4001-42a6-9d4a-505b9d1f7572'
    contentType: 'text/plain'
  }
  {
    key: 'AppSettings:ProjectRecordValidationUri'
    label: 'portal'
    value: 'https://func-validate-irasid-manualtest.azurewebsites.net/api'
    contentType: 'text/plain'
  }
]
