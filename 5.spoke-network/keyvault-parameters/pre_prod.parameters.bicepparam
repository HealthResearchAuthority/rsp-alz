using '../main.keyvault-update.bicep'

param parSharedServicesSubscriptionId = ''

param parSharedServicesResourceGroup = 'rg-rsp-sharedservices-spoke-preprod-uks'

param parKeyVaultName = 'kv-rsp-shared-psz73-prep'

param parKeyVaultSecrets = loadJsonContent('./pre_prod.secrets.json')
