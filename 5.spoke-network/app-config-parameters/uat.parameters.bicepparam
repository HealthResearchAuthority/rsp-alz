using '../main.appconfig-update.bicep'

param parEnvironment = 'uat'

param parSharedServicesSubscriptionId = 'e1a1a4ff-2db5-4de3-b7e5-6d51413f6390'

param parSharedServicesResourceGroup = 'rg-rsp-sharedservices-spoke-uat-uks'

param parAppConfigurationStoreName = 'appcs-rsp-shared-p2ntz-uat-uks'

param parAppConfigurationValues = [
  {
    key: 'AppSettings:ProjectRecordValidationScopes'
    label: 'portal'
    value: 'api://[YOUR-UAT-CLIENT-ID]'
    contentType: 'text/plain'
  }
  {
    key: 'AppSettings:ProjectRecordValidationUri'
    label: 'portal'
    value: 'https://func-validate-irasid-uat.azurewebsites.net/api'
    contentType: 'text/plain'
  }
]
