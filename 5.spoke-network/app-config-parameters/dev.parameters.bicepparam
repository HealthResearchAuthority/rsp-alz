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
    key: 'AppSettings:ManagedIdentityRtsClientID'
    label: ''
    value: '056ae900-5905-45e7-ae2c-a67764b5c9e2'
    contentType: 'text/plain'
  }
]
