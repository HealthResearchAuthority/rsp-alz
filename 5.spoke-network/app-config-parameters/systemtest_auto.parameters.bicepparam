using '../main.appconfig-update.bicep'

param parEnvironment = 'automationtest'

param parSharedServicesSubscriptionId = '75875981-b04d-42c7-acc5-073e2e5e2e65'

param parSharedServicesResourceGroup = 'rg-rsp-sharedservices-spoke-systemtestauto-uks'

param parAppConfigurationStoreName = 'appcs-rsp-shared-ryefn-automationtest-uks'

// Value for ManagedIdentityRtsClientID is passed from Azure DevOps variable group
param parManagedIdentityRtsClientID = ''

// Value for ManagedIdentityManageNotificationsClientID is passed from Azure DevOps variable group
param parManagedIdentityManageNotificationsClientID = ''

param parAppConfigurationValues = [
  {
    key: 'AppSettings:ManagedIdentityRtsClientID'
    label: ''
    value: parManagedIdentityRtsClientID
    contentType: 'text/plain'
  },
    {
    key: 'AppSettings:ManagedIdentityManageNotificationsClientID'
    label: ''
    value: parManagedIdentityManageNotificationsClientID
    contentType: 'text/plain'
  }
]
