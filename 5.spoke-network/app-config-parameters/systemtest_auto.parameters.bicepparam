using '../main.appconfig-update.bicep'

param parEnvironment = 'systemtest_auto'

param parSharedServicesSubscriptionId = '75875981-b04d-42c7-acc5-073e2e5e2e65'

param parSharedServicesResourceGroup = 'rg-rsp-sharedservices-spoke-systemtestauto-uks'

param parAppConfigurationStoreName = 'appcs-rsp-shared-ryefn-automationtest-uks'

param parAppConfigurationValues = [
  {
    key: 'AppSettings:ProjectRecordValidationScopes'
    label: 'portal'
    value: 'api://a858e7ac-b7f5-4fc6-b993-ebd3c7082a17'
    contentType: 'text/plain'
  }
  {
    key: 'AppSettings:ProjectRecordValidationUri'
    label: 'portal'
    value: 'https://func-validate-irasid-automationtest.azurewebsites.net/api'
    contentType: 'text/plain'
  }
]
