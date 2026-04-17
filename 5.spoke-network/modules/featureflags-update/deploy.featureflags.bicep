targetScope = 'resourceGroup'

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

@description('Name of the App Configuration store that should receive the feature flag updates.')
param parAppConfigurationStoreName string

@description('List of feature flags to upsert.')
param parFeatureFlags featureFlagDefinition[] = []

// ------------------
// VARIABLES
// ------------------

var normalizedFeatureFlags = [
  for flag in parFeatureFlags: union({
    label: null
    description: ''
    conditions: {}
  }, flag)
]

var resolvedFeatureFlags = [
  for flag in normalizedFeatureFlags: {
    name: flag.label == null ? '.appconfig.featureflag~2F${flag.id}' : '.appconfig.featureflag~2F${flag.id}$${flag.label}'
    value: flag
    contentType: 'application/vnd.microsoft.appconfig.ff+json;charset=utf-8'
  }
]

// ------------------
// RESOURCES
// ------------------

resource appConfigurationStore 'Microsoft.AppConfiguration/configurationStores@2024-05-01' existing = {
  name: parAppConfigurationStoreName
}

resource featureFlagKeyValues 'Microsoft.AppConfiguration/configurationStores/keyValues@2024-05-01' = [
  for flag in resolvedFeatureFlags: {
    parent: appConfigurationStore
    name: flag.name
    properties: {
      value: string(flag.value)
      contentType: flag.contentType
    }
  }
]

// ------------------
// OUTPUTS
// ------------------

@description('Name of the App Configuration store updated by this deployment.')
output appConfigurationStoreName string = parAppConfigurationStoreName

@description('Feature flag identifiers (id + label) updated during this deployment.')
output updatedFeatureFlags array = [
  for flag in resolvedFeatureFlags: flag.name
]
