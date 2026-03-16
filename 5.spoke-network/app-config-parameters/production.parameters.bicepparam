using '../main.appconfig-update.bicep'

param parEnvironment = 'production'

param parSharedServicesSubscriptionId = ''

param parSharedServicesResourceGroup = 'rg-rsp-sharedservices-spoke-prod-uks'

param parAppConfigurationStoreName = 'appcs-rsp-shared-67jvv-prod-uks'

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
