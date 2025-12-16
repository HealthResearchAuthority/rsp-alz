targetScope = 'resourceGroup'

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

@description('Name of the App Configuration store that should receive the key-value updates.')
param parAppConfigurationStoreName string

@description('List of App Configuration key-values to upsert.')
param parAppConfigurationValues appConfigurationKeyValue[] = []

// ------------------
// VARIABLES
// ------------------

var normalizedKeyValues = [
  for keyValue in parAppConfigurationValues: union({
    label: ''
    contentType: ''
    tags: {}
  }, keyValue)
]

var resolvedAppConfigValues = [
  for keyValue in normalizedKeyValues: {
    name: empty(string(keyValue.label)) ? keyValue.key : '${keyValue.key}$${keyValue.label}'
    value: keyValue.value
    contentType: empty(string(keyValue.contentType)) ? null : keyValue.contentType
    tags: empty(keyValue.tags) ? null : keyValue.tags
  }
]

// ------------------
// RESOURCES
// ------------------

resource appConfigurationKeyValues 'Microsoft.AppConfiguration/configurationStores/keyValues@2024-05-01' = [
  for keyValue in resolvedAppConfigValues: {
    name: '${parAppConfigurationStoreName}/${keyValue.name}'
    properties: {
      value: string(keyValue.value)
      contentType: keyValue.contentType
      tags: keyValue.tags
    }
  }
]

// ------------------
// OUTPUTS
// ------------------

@description('Name of the App Configuration store updated by this deployment.')
output appConfigurationStoreName string = parAppConfigurationStoreName

@description('Key identifiers (key + label) updated during this deployment.')
output updatedKeys array = [
  for keyValue in resolvedAppConfigValues: keyValue.name
]
