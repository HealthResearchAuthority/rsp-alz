using '../main.appconfig-update.bicep'

param parEnvironment = 'uat'

param parSharedServicesSubscriptionId = 'e1a1a4ff-2db5-4de3-b7e5-6d51413f6390'

param parSharedServicesResourceGroup = 'rg-rsp-sharedservices-spoke-uat-uks'

param parAppConfigurationStoreName = 'appcs-rsp-shared-p2ntz-uat-uks'

// Value for ManagedIdentityRtsClientID is passed from Azure DevOps variable group
param parManagedIdentityRtsClientID = ''

// Value for ManagedIdentityManageNotificationsClientID is passed from Azure DevOps variable group
param parManagedIdentityManageNotificationsClientID = ''

// Value for ManagedIdentityNotifyClientID is passed from Azure DevOps variable group
param parManagedIdentityNotifyClientID = ''

param parAppConfigurationValues = [
  {
    key: 'AppSettings:ManagedIdentityRtsClientID'
    label: ''
    value: parManagedIdentityRtsClientID
    contentType: 'text/plain'
  }
  {
    key: 'AppSettings:ManagedIdentityManageNotificationsClientID'
    label: ''
    value: parManagedIdentityManageNotificationsClientID
    contentType: 'text/plain'
  }
  {
    key: 'AppSettings:ManagedIdentityNotifyClientID'
    label: ''
    value: parManagedIdentityNotifyClientID
    contentType: 'text/plain'
  }
]
