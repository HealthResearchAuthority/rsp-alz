targetScope = 'subscription'

// ------------------
// TYPE DEFINITIONS
// ------------------

@description('Definition of a single App Configuration key-value pair.')
type appConfigurationKeyValue = {
  @description('Key to update in App Configuration.')
  key: string

  @description('Optional label for the key. Leave empty to target the null label.')
  label: string?

  @description('Value to set for the key.')
  value: string

  @description('Optional content type metadata (for example text/plain or application/json).')
  contentType: string?

  @description('Optional tags to associate with the key.')
  tags: object?
}

// ------------------
// PARAMETERS
// ------------------

@description('Location passed to child modules (defaults to the deployment location).')
param location string = deployment().location

@description('Azure environment short name (for example dev, uat, prod).')
param parEnvironment string

@description('Subscription ID hosting the shared services resource group that contains the App Configuration store.')
param parSharedServicesSubscriptionId string

@description('Shared services resource group that contains the App Configuration store.')
param parSharedServicesResourceGroup string

@description('Name of the App Configuration store to update (should match the CAF naming output).')
param parAppConfigurationStoreName string

@description('Optional override for the workload name passed to the CAF naming module.')
param parNamingWorkloadName string = 'shared'

@description('List of App Configuration key-values to upsert.')
param parAppConfigurationValues appConfigurationKeyValue[] = []

@description('ProjectRecordValidationScopes value (sourced from Azure DevOps variable group).')
#disable-next-line no-unused-params
param parProjectRecordValidationScopes string

@description('ProjectRecordValidationUri value (sourced from Azure DevOps variable group).')
#disable-next-line no-unused-params
param parProjectRecordValidationUri string

@description('ManagedIdentityRtsClientID value (sourced from Azure DevOps variable group).')
#disable-next-line no-unused-params
param parManagedIdentityRtsClientID string

// ------------------
// MODULES
// ------------------

module sharedServicesNaming '../shared/bicep/naming/naming.module.bicep' = {
  name: take('appConfigNaming-${deployment().name}', 64)
  scope: resourceGroup(parSharedServicesSubscriptionId, parSharedServicesResourceGroup)
  params: {
    uniqueId: uniqueString(subscriptionResourceId(parSharedServicesSubscriptionId, 'Microsoft.Resources/resourceGroups', parSharedServicesResourceGroup))
    environment: parEnvironment
    workloadName: parNamingWorkloadName
    location: location
  }
}

var derivedAppConfigurationStoreName = sharedServicesNaming.outputs.resourcesNames.azureappconfigurationstore

// ------------------
// MODULES
// ------------------

module appConfigurationUpdates 'modules/app-config-update/deploy.appconfig-keyvalues.bicep' = {
  name: take('appConfigUpdate-${deployment().name}', 64)
  scope: resourceGroup(parSharedServicesSubscriptionId, parSharedServicesResourceGroup)
  params: {
    parAppConfigurationStoreName: parAppConfigurationStoreName
    parAppConfigurationValues: parAppConfigurationValues
  }
}

// ------------------
// OUTPUTS
// ------------------

@description('Name of the App Configuration store updated by this deployment.')
output appConfigurationStoreName string = appConfigurationUpdates.outputs.appConfigurationStoreName

@description('Key identifiers (key + label) updated during this deployment.')
output updatedKeys array = appConfigurationUpdates.outputs.updatedKeys

@description('App Configuration store name derived from the CAF naming module (for validation purposes).')
output derivedAppConfigurationStoreName string = derivedAppConfigurationStoreName
