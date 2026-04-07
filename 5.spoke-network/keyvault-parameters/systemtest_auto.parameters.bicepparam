using '../main.keyvault-update.bicep'

param parSharedServicesSubscriptionId = ''

param parSharedServicesResourceGroup = 'rg-rsp-sharedservices-spoke-systemtestauto-uks'

param parKeyVaultName = 'kv-rsp-shared-ryefn-auto'

param parKeyVaultSecrets = loadJsonContent('./systemtest_auto.secrets.json')
