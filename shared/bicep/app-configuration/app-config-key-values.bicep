param configStoreName string
param webAppURLConfigKey string
param webAppURLConfigValue string

resource configStore 'Microsoft.AppConfiguration/configurationStores@2023-03-01' existing = {
  name: configStoreName
}

resource configStoreKeyValue 'Microsoft.AppConfiguration/configurationStores/keyValues@2021-10-01-preview' = {
  parent: configStore
  name: webAppURLConfigKey
  properties: {
    value: webAppURLConfigValue
  }
}
