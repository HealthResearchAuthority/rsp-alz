using '../main.appconfig-update.bicep'

param parEnvironment = 'production'

param parSharedServicesSubscriptionId = 'd27a0dcc-453d-4bfa-9c3d-1447c6ea0119'

param parSharedServicesResourceGroup = 'rg-rsp-sharedservices-spoke-prod-uks'

param parAppConfigurationStoreName = 'appcs-rsp-shared-67jvv-prod-uks'

param parAppConfigurationValues = [
  {
    key: 'AppSettings:ProjectRecordValidationScopes'
    label: 'portal'
    value: 'api://[YOUR-PRODUCTION-CLIENT-ID]'
    contentType: 'text/plain'
  }
  {
    key: 'AppSettings:ProjectRecordValidationUri'
    label: 'portal'
    value: 'https://func-validate-irasid-prod.azurewebsites.net/api'
    contentType: 'text/plain'
  }
]
