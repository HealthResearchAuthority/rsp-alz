@description('Required. Name of your Function App.')
param functionAppName string

@description('Optional. Location for all resources.')
param location string

@description('Optional. Tags of the resource.')
param tags object = {}

@description('Optional. Additional app settings.')
param appSettings array = []

@maxLength(24)
@description('Conditional. The name of the parent Storage Account. Required if the template is used in a standalone deployment.')
param storageAccountName string

@description('Optional. Runtime for Function App.')
@allowed([
  'node'
  'dotnet'
  'java'
])
param runtime string = 'dotnet' // e.g., 'dotnet', 'node', 'python', etc.

@description('Optional. Runtime Version for Function App.')
param runtimeVersion string = '~4'

@description('Optional. Dotnet framework version.')
param dotnetVersion string = '9.0'

var hostingPlanName = take('${functionAppName}-plan', 40)

// @description('Optional. ID of AppInsights.')
// var appInsightId string

// resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
//   name: storageAccountName
// }

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
  tags: tags
}

resource hostingPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {}
  tags: tags
}

// resource appInsights 'microsoft.insights/components@2020-02-02' existing = if (!empty(appInsightId)) {
//   name: last(split(appInsightId, '/'))!
//   scope: resourceGroup(split(appInsightId, '/')[2], split(appInsightId, '/')[4])
// }

// resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
//   name: appInsightsName
//   location: location
//   kind: 'web'
//   properties: {
//     Application_Type: 'web'
//     Request_Source: 'rest'
//   }
//   tags: tags
// }

var defaultSettings = [
  {
    name: 'AzureWebJobsStorage'
    value: storageAccount.properties.primaryEndpoints.blob
  }
  {
    name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id, '2022-09-01').keys[0].value};EndpointSuffix=core.windows.net'
  }
  {
    name: 'FUNCTIONS_EXTENSION_VERSION'
    value: runtimeVersion
  }
  {
    name: 'FUNCTIONS_WORKER_RUNTIME'
    value: runtime
  }
]

resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      netFrameworkVersion: dotnetVersion
      appSettings: concat(defaultSettings, appSettings)
    }
  }
  tags: tags
}

output functionAppName string = functionApp.name
output functionAppId string = functionApp.id
