using '../main.keyvault-update.bicep'

param parSharedServicesSubscriptionId = ''

param parSharedServicesResourceGroup = 'rg-rsp-sharedservices-spoke-systemtest-uks'

param parKeyVaultName = 'kv-rsp-shared-rwcwe-manu'

param parKeyVaultSecrets = loadJsonContent('./systemtest_manual.secrets.json')
