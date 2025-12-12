using '../main.keyvault-update.bicep'

param parSharedServicesSubscriptionId = '66482e26-764b-4717-ae2f-fab6b8dd1379'

param parSharedServicesResourceGroup = 'rg-rsp-sharedservices-spoke-systemtest-uks'

param parKeyVaultName = 'kv-rsp-shared-rwcwe-manu'

param parKeyVaultSecrets = loadJsonContent('./systemtest_manual.secrets.json')
