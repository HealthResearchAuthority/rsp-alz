targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------

@description('Required. Name of the App Configuration store to update.')
param configStoreName string

@description('Required. Front Door endpoint hostname (without protocol).')
param frontDoorHostName string

@description('Required. Web App hostname (without protocol).')
param webAppHostName string

@description('Required. Indicates whether Front Door is enabled for the application.')
param useFrontDoor bool


// ------------------
//    VARIABLES
// ------------------

// Construct the dynamic values based on Front Door availability
var allowedHostsValue = useFrontDoor ? '${frontDoorHostName};${webAppHostName}' : webAppHostName
var jwksUriValue = useFrontDoor ? 'https://${frontDoorHostName}/jwks' : 'https://${webAppHostName}/jwks'

// Key-value pairs to update in App Configuration
var keyValuesToUpdate = [
  {
    name: 'AppSettings:AllowedHosts$portal'
    value: allowedHostsValue
    contentType: null
  }
  {
    name: 'AppSettings:AuthSettings:JwksUri'
    value: jwksUriValue
    contentType: null
  }
]

// ------------------
//    RESOURCES
// ------------------

resource configStore 'Microsoft.AppConfiguration/configurationStores@2024-05-01' existing = {
  name: configStoreName
}

// Update the key-value pairs in App Configuration
resource configStoreKeyValueUpdate 'Microsoft.AppConfiguration/configurationStores/keyValues@2024-05-01' = [
  for keyValue in keyValuesToUpdate: {
    parent: configStore
    name: keyValue.name
    properties: {
      value: string(keyValue.value)
      contentType: keyValue.contentType
    }
  }
]

// ------------------
//    OUTPUTS
// ------------------

@description('The updated allowed hosts value.')
output allowedHostsValue string = allowedHostsValue

@description('The updated JWKS URI value.')
output jwksUriValue string = jwksUriValue

@description('The name of the App Configuration store that was updated.')
output configStoreName string = configStore.name