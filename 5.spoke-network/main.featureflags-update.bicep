targetScope = 'subscription'

// ------------------
// TYPE DEFINITIONS
// ------------------

@description('Definition of a feature flag for App Configuration.')
type featureFlagDefinition = {
  @description('Feature flag ID (e.g., "Auth.UseOneLogin")')
  id: string

  @description('Optional label for the flag (e.g., "portal"). Use null for no label.')
  label: string?

  @description('Whether the feature flag is enabled')
  enabled: bool

  @description('Description of the feature flag purpose')
  description: string?

  @description('Optional conditions for targeted rollout using Microsoft.Targeting filter')
  conditions: object?
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

@description('List of feature flags to upsert in App Configuration.')
param parFeatureFlags featureFlagDefinition[] = []

// ------------------
// MODULES
// ------------------

module sharedServicesNaming '../shared/bicep/naming/naming.module.bicep' = {
  name: take('featureFlagsNaming-${deployment().name}', 64)
  scope: resourceGroup(parSharedServicesSubscriptionId, parSharedServicesResourceGroup)
  params: {
    uniqueId: uniqueString(subscriptionResourceId(parSharedServicesSubscriptionId, 'Microsoft.Resources/resourceGroups', parSharedServicesResourceGroup))
    environment: parEnvironment
    workloadName: parNamingWorkloadName
    location: location
  }
}

var derivedAppConfigurationStoreName = sharedServicesNaming.outputs.resourcesNames.azureappconfigurationstore

module featureFlagsUpdates 'modules/featureflags-update/deploy.featureflags.bicep' = {
  name: take('featureFlagsUpdate-${deployment().name}', 64)
  scope: resourceGroup(parSharedServicesSubscriptionId, parSharedServicesResourceGroup)
  params: {
    parAppConfigurationStoreName: parAppConfigurationStoreName
    parFeatureFlags: parFeatureFlags
  }
}

// ------------------
// OUTPUTS
// ------------------

@description('Name of the App Configuration store updated by this deployment.')
output appConfigurationStoreName string = featureFlagsUpdates.outputs.appConfigurationStoreName

@description('Feature flag identifiers (id + label) updated during this deployment.')
output updatedFeatureFlags array = featureFlagsUpdates.outputs.updatedFeatureFlags

@description('App Configuration store name derived from the CAF naming module (for validation purposes).')
output derivedAppConfigurationStoreName string = derivedAppConfigurationStoreName
