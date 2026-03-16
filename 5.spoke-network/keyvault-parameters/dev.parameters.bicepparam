using '../main.keyvault-update.bicep'

param parSharedServicesSubscriptionId = ''

param parSharedServicesResourceGroup = 'rg-rsp-sharedservices-spoke-dev-uks'

param parKeyVaultName = 'kv-rsp-shared-2i2oq-dev'

param parKeyVaultSecrets = loadJsonContent('./dev.secrets.json')
