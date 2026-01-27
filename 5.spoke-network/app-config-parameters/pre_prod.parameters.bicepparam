using '../main.appconfig-update.bicep'

param parEnvironment = 'pre_prod'

param parSharedServicesSubscriptionId = 'be1174fc-09c8-470f-9409-d0054ab9586a'

param parSharedServicesResourceGroup = 'rg-rsp-sharedservices-spoke-preprod-uks'

param parAppConfigurationStoreName = 'appcs-rsp-shared-psz73-preprod-uks'

param parAppConfigurationValues = [
  {
    key: 'AppSettings:ProjectRecordValidationScopes'
    label: 'portal'
    value: 'api://[YOUR-PREPROD-CLIENT-ID]'
    contentType: 'text/plain'
  }
  {
    key: 'AppSettings:ProjectRecordValidationUri'
    label: 'portal'
    value: 'https://func-validate-irasid-preprod.azurewebsites.net/api'
    contentType: 'text/plain'
  }
]
