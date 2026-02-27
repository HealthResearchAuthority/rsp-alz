using '../main.appconfig-update.bicep'

param parEnvironment = 'production'

param parSharedServicesSubscriptionId = 'd27a0dcc-453d-4bfa-9c3d-1447c6ea0119'

param parSharedServicesResourceGroup = 'rg-rsp-sharedservices-spoke-prod-uks'

param parAppConfigurationStoreName = 'appcs-rsp-shared-67jvv-prod-uks'

// Values are passed from Azure DevOps variable group
param parManagedIdentityRtsClientID = ''
param parProjectRecordValidationScopes = ''
param parProjectRecordValidationUri = ''

param parAppConfigurationValues = [
  {
    key: 'AppSettings:ManagedIdentityRtsClientID'
    label: ''
    value: parManagedIdentityRtsClientID
    contentType: 'text/plain'
  }
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
