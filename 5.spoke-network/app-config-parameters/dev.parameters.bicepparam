using '../main.appconfig-update.bicep'

param parEnvironment = 'dev'

param parSharedServicesSubscriptionId = 'b83b4631-b51b-4961-86a1-295f539c826b'

param parSharedServicesResourceGroup = 'rg-rsp-sharedservices-spoke-dev-uks'

param parAppConfigurationStoreName = 'appcs-rsp-shared-2i2oq-dev-uks'

param parAppConfigurationValues = [
  // Example:
  // {
  //   key: 'AppSettings:RtsApiBaseUrl'
  //   label: ''
  //   value: 'https://api-rts-dev.example.com'
  //   contentType: null
  // }
  {
    key: 'AppSettings:ProjectRecordValidationScopes'
    label: 'portal'
    value: 'api://2032f90d-d672-4ea3-9116-acd0cf20d4e3'
    contentType: 'text/plain'
  }
  {
    key: 'AppSettings:ProjectRecordValidationUri'
    label: 'portal'
    value: 'https://func-validate-irasid-dev.azurewebsites.net/api'
    contentType: 'text/plain'
  }
]
