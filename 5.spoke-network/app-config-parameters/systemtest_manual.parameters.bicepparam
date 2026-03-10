using '../main.appconfig-update.bicep'

param parEnvironment = 'manualtest'

param parSharedServicesSubscriptionId = '66482e26-764b-4717-ae2f-fab6b8dd1379'

param parSharedServicesResourceGroup = 'rg-rsp-sharedservices-spoke-systemtest-uks'

param parAppConfigurationStoreName = 'appcs-rsp-shared-rwcwe-manualtest-uks'

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
