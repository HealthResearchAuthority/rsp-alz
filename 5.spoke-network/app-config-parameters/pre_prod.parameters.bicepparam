using '../main.appconfig-update.bicep'

param parEnvironment = 'pre_prod'

param parSharedServicesSubscriptionId = 'be1174fc-09c8-470f-9409-d0054ab9586a'

param parSharedServicesResourceGroup = 'rg-rsp-sharedservices-spoke-preprod-uks'

param parAppConfigurationStoreName = 'appcs-rsp-shared-psz73-preprod-uks'

param parAppConfigurationValues = []
