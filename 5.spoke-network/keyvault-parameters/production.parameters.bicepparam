using '../main.keyvault-update.bicep'

param parSharedServicesSubscriptionId = ''

param parSharedServicesResourceGroup = 'rg-rsp-sharedservices-spoke-prod-uks'

param parKeyVaultName = 'kv-rsp-shared-67jvv-prod'

param parKeyVaultSecrets = loadJsonContent('./production.secrets.json')
