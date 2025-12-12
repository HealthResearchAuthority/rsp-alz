using '../main.keyvault-update.bicep'

param parSharedServicesSubscriptionId = 'd27a0dcc-453d-4bfa-9c3d-1447c6ea0119'

param parSharedServicesResourceGroup = 'rg-rsp-sharedservices-spoke-prod-uks'

param parKeyVaultName = 'kv-rsp-shared-67jvv-prod'

param parKeyVaultSecrets = loadJsonContent('./production.secrets.json')
