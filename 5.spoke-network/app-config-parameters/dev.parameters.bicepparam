using '../main.appconfig-update.bicep'

param parEnvironment = 'dev'

param parSharedServicesSubscriptionId = 'b83b4631-b51b-4961-86a1-295f539c826b'

param parSharedServicesResourceGroup = 'rg-rsp-sharedservices-spoke-dev-uks'

param parAppConfigurationStoreName = 'appcs-rsp-shared-2i2oq-dev-uks'

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
