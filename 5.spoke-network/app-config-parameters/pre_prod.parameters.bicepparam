using '../main.appconfig-update.bicep'

param parEnvironment = 'pre_prod'

param parSharedServicesSubscriptionId = ''

param parSharedServicesResourceGroup = 'rg-rsp-sharedservices-spoke-preprod-uks'

param parAppConfigurationStoreName = 'appcs-rsp-shared-psz73-preprod-uks'

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
