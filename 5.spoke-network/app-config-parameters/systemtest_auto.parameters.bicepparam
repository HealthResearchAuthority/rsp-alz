using '../main.appconfig-update.bicep'

param parEnvironment = 'systemtest_auto'

param parSharedServicesSubscriptionId = '75875981-b04d-42c7-acc5-073e2e5e2e65'

param parSharedServicesResourceGroup = 'rg-rsp-sharedservices-spoke-systemtestauto-uks'

param parAppConfigurationStoreName = 'appcs-rsp-shared-ryefn-automationtest-uks'

// Values for ProjectRecordValidationScopes and ProjectRecordValidationUri are passed from Azure DevOps variable group
param parProjectRecordValidationScopes = ''
param parProjectRecordValidationUri = ''

param parAppConfigurationValues = [
  {
    key: 'AppSettings:ProjectRecordValidationScopes'
    label: 'portal'
    value: parProjectRecordValidationScopes
    contentType: 'text/plain'
  }
  {
    key: 'AppSettings:ProjectRecordValidationUri'
    label: 'portal'
    value: parProjectRecordValidationUri
    contentType: 'text/plain'
  }
]
