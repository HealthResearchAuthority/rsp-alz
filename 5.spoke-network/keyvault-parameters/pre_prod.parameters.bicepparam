using '../main.keyvault-update.bicep'

param parSharedServicesSubscriptionId = 'be1174fc-09c8-470f-9409-d0054ab9586a'

param parSharedServicesResourceGroup = 'rg-rsp-sharedservices-spoke-preprod-uks'

param parKeyVaultName = 'kv-rsp-shared-psz73-prep'

param parKeyVaultSecrets = loadJsonContent('./pre_prod.secrets.json')
