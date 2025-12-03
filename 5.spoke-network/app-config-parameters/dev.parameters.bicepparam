using '../main.appconfig-update.bicep'

param parEnvironment = 'dev'

param parSharedServicesSubscriptionId = 'b83b4631-b51b-4961-86a1-295f539c826b'

param parSharedServicesResourceGroup = 'rg-rsp-sharedservices-spoke-dev-uks'

// Replace the placeholder with the actual App Configuration store name
param parAppConfigurationStoreName = 'appcs-rsp-shared-2i2oq-dev-uks'

// Populate this array with the key/value pairs that need to be updated.
// Example:
// {
//   key: 'AppSettings:AllowedHosts'
//   label: 'portal'
//   value: 'irasportal-dev.azurefd.net;irasportal-dev.azurewebsites.net'
//   contentType: 'text/plain'
// }
param parAppConfigurationValues = [
  {
    key: 'AppSettings:OneLogin:AuthCookieTimeout'
    label: 'portal'
    value: '3700'
    contentType: null
  }
  {
    key: 'AppSettings:Testing'
    label: 'deleteThis'
    value: 'Testing App config create'
    contentType: 'text/plain'
  }
]
