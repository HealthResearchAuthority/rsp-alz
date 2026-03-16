using '../main.keyvault-update.bicep'

param parSharedServicesSubscriptionId = ''

param parSharedServicesResourceGroup = 'rg-rsp-sharedservices-spoke-uat-uks'

param parKeyVaultName = 'kv-rsp-shared-p2ntz-uat'

param parKeyVaultSecrets = loadJsonContent('./uat.secrets.json')
