using '../main.keyvault-update.bicep'

param parSharedServicesSubscriptionId = 'e1a1a4ff-2db5-4de3-b7e5-6d51413f6390'

param parSharedServicesResourceGroup = 'rg-rsp-sharedservices-spoke-uat-uks'

param parKeyVaultName = 'kv-rsp-shared-p2ntz-uat'

param parKeyVaultSecrets = loadJsonContent('./uat.secrets.json')
