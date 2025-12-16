using '../main.keyvault-update.bicep'

param parSharedServicesSubscriptionId = 'b83b4631-b51b-4961-86a1-295f539c826b'

param parSharedServicesResourceGroup = 'rg-rsp-sharedservices-spoke-dev-uks'

param parKeyVaultName = 'kv-rsp-shared-2i2oq-dev'

param parKeyVaultSecrets = loadJsonContent('./dev.secrets.json')
