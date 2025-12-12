using '../main.keyvault-update.bicep'

param parSharedServicesSubscriptionId = '75875981-b04d-42c7-acc5-073e2e5e2e65'

param parSharedServicesResourceGroup = 'rg-rsp-sharedservices-spoke-systemtestauto-uks'

param parKeyVaultName = 'kv-rsp-shared-ryefn-auto'

param parKeyVaultSecrets = loadJsonContent('./systemtest_auto.secrets.json')
