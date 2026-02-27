using '../main.appconfig-update.bicep'

param parEnvironment = 'pre_prod'

param parSharedServicesSubscriptionId = 'be1174fc-09c8-470f-9409-d0054ab9586a'

param parSharedServicesResourceGroup = 'rg-rsp-sharedservices-spoke-preprod-uks'

param parAppConfigurationStoreName = 'appcs-rsp-shared-psz73-preprod-uks'

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


