using '../main.featureflags-update.bicep'

param parEnvironment = 'production'

param parSharedServicesSubscriptionId = ''

param parSharedServicesResourceGroup = 'rg-rsp-sharedservices-spoke-prod-uks'

param parAppConfigurationStoreName = 'appcs-rsp-shared-67jvv-prod-uks'

param parFeatureFlags = [
  {
    id: 'Action.ProceedToSubmit'
    label: 'portal'
    description: 'When disabled Proceed To Submit button won\'t appear.'
    enabled: true
  }
  {
    id: 'Logging.InterceptedLogging'
    description: 'If enabled, all action methods and services will have start/end logging using Interceptors.'
    label: null
    enabled: true
  }
  {
    id: 'Navigation.Admin'
    description: 'When disabled the Admin menu won\'t appear.'
    label: 'portal'
    enabled: true
  }
  {
    id: 'Navigation.MyApplications'
    description: 'When disabled My Applications men won\'t appear.'
    label: 'portal'
    enabled: true
  }
  {
    id: 'Navigation.ReviewApplications'
    description: 'When disabled the Review Applications menu won\'t appear.'
    label: 'portal'
    enabled: true
  }
  {
    id: 'UX.ProgressiveEnhancement'
    description: 'If this flag is enabled, and javascript is enabled, will provide an enhanced user experience.'
    label: 'portal'
    enabled: true
  }
  {
    id: 'UX.MyResearchPage'
    description: 'If this flag is enabled, show projects added to new service in my research dashboard'
    label: 'portal'
    enabled: true
  }
  {
    id: 'Auth.UseOneLogin'
    description: 'When enabled, Gov UK One Login will be used for authentication'
    label: null
    enabled: true
  }
  {
    id: 'WebApp.UseFrontDoor'
    description: 'When enabled, it will use the AllowedHosts to Front Door URL.'
    label: 'portal'
    enabled: true
  }
  {
    id: 'Modifications.RevisionAndAuthorisation'
    enabled: true
    description: 'When enabled, additional options for `Revise and authorise` and `Request for revision` will be available for a sponsor when authorising the modifications.'
    label: null
    conditions: {
      client_filters: [
        {
          name: 'Microsoft.Targeting'
          parameters: {
            Audience: {
              Users: []
              Groups: []
              DefaultRolloutPercentage: 0
            }
          }
        }
      ]
    }
  }
  {
    id: 'Modifications.ChangeOfSponsorOrganisation'
    enabled: true
    description: 'When enabled, allows changing sponsor organisation via modification journey'
    label: null
    conditions: {
      client_filters: [
        {
          name: 'Microsoft.Targeting'
          parameters: {
            Audience: {
              Users: []
              Groups: []
              DefaultRolloutPercentage: 0
            }
          }
        }
      ]
    }
  }
  {
    id: 'Modifications.ParticipatingOrganisations'
    enabled: true
    description: 'When enabled participating organisations feature will be available.'
    label: null
    conditions: {
      client_filters: [
        {
          name: 'Microsoft.Targeting'
          parameters: {
            Audience: {
              Users: []
              Groups: []
              DefaultRolloutPercentage: 0
            }
          }
        }
      ]
    }
  }
  {
    id: 'Modifications.DownloadPack'
    enabled: true
    description: 'When enabled, the download pack option will be available for modifications.'
    label: null
    conditions: {
      client_filters: [
        {
          name: 'Microsoft.Targeting'
          parameters: {
            Audience: {
              Users: []
              Groups: []
              DefaultRolloutPercentage: 0
            }
          }
        }
      ]
    }
  }
  {
    id: 'Modifications.SupersedingDocuments'
    enabled: true
    description: 'When enabled, the superseding documents feature will be available for modifications.'
    label: null
    conditions: {
      client_filters: [
        {
          name: 'Microsoft.Targeting'
          parameters: {
            Audience: {
              Users: []
              Groups: []
              DefaultRolloutPercentage: 0
            }
          }
        }
      ]
    }
  }
  {
    id: 'Modifications.Withdraw'
    enabled: true
    description: 'When enabled, the withdraw option will be available for modifications.'
    label: null
    conditions: {
      client_filters: [
        {
          name: 'Microsoft.Targeting'
          parameters: {
            Audience: {
              Users: []
              Groups: []
              DefaultRolloutPercentage: 0
            }
          }
        }
      ]
    }
  }
  {
    id: 'ProjectOverview.BackButton'
    enabled: true
    description: 'When enabled, the back button will be available on the project overview page.'
    label: null
    conditions: {
      client_filters: [
        {
          name: 'Microsoft.Targeting'
          parameters: {
            Audience: {
              Users: []
              Groups: []
              DefaultRolloutPercentage: 0
            }
          }
        }
      ]
    }
  }
  {
    id: 'Modifications.RequestForInformation'
    enabled: true
    description: 'When enabled, the request for information option will be available for sponsor authorisation.'
    label: null
    conditions: {
      client_filters: [
        {
          name: 'Microsoft.Targeting'
          parameters: {
            Audience: {
              Users: []
              Groups: []
              DefaultRolloutPercentage: 0
            }
          }
        }
      ]
    }
  }
  {
    id: 'Modifications.NotAuthorisedReason'
    enabled: true
    description: 'When enabled, the not authorised reason will be available for sponsor authorisation.'
    label: null
    conditions: {
      client_filters: [
        {
          name: 'Microsoft.Targeting'
          parameters: {
            Audience: {
              Users: []
              Groups: []
              DefaultRolloutPercentage: 0
            }
          }
        }
      ]
    }
  }
  {
    id: 'System.UserNotifications'
    enabled: true
    description: 'When enabled, the user notifications area is available to all logged in users.'
    label: null
    conditions: {
      client_filters: [
        {
          name: 'Microsoft.Targeting'
          parameters: {
            Audience: {
              Users: []
              Groups: []
              DefaultRolloutPercentage: 0
            }
          }
        }
      ]
    }
  }
]
