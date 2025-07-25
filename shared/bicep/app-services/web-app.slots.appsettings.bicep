// ================ //
// Parameters       //
// ================ //
@description('Required. Slot name to be configured.')
param slotName string

@description('Conditional. The name of the parent site resource. Required if the template is used in a standalone deployment.')
param appName string

@description('Required. Type of slot to deploy.')
@allowed([
  'functionapp' // function app windows os
  'functionapp,linux' // function app linux os
  // 'functionapp,workflowapp' // logic app workflow
  // 'functionapp,workflowapp,linux' // logic app docker container
  'app' // normal web app
  'app,linux' // normal web app linux OS
  'app,linux,container' //web app for containers - linux
])
param kind string

@description('Optional. Required if app of kind functionapp. Resource ID of the storage account to manage triggers and logging function executions.')
param storageAccountId string = ''

@description('Optional. Resource ID of the app insight to leverage for this resource.')
param appInsightId string = ''

@description('Optional. For function apps. If true the app settings "AzureWebJobsDashboard" will be set. If false not. In case you use Application Insights it can make sense to not set it for performance reasons.')
param setAzureWebJobsDashboard bool = contains(kind, 'functionapp') ? true : false

@description('Optional. The app settings key-value pairs except for AzureWebJobsStorage, AzureWebJobsDashboard, APPINSIGHTS_INSTRUMENTATIONKEY and APPLICATIONINSIGHTS_CONNECTION_STRING.')
param appSettingsKeyValuePairs object = {}

// =========== //
// Variables   //
// =========== //
var azureWebJobsValues = !empty(storageAccountId) ? union({
    AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount!.name};AccountKey=${storageAccount!.listKeys().keys[0].value};'
  }, ((setAzureWebJobsDashboard == true) ? {
    AzureWebJobsDashboard: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount!.name};AccountKey=${storageAccount!.listKeys().keys[0].value};'
  } : {})) : {}

var appInsightsValues = !empty(appInsightId) ? {
  APPINSIGHTS_INSTRUMENTATIONKEY: appInsight!.properties.InstrumentationKey
  APPLICATIONINSIGHTS_CONNECTION_STRING: appInsight!.properties.ConnectionString
  XDT_MicrosoftApplicationInsights_Mode: 'recommended'
  ApplicationInsightsAgent_EXTENSION_VERSION: contains(kind, 'linux') ? '~3' : '~2'
} : {}

var expandedAppSettings = union(appSettingsKeyValuePairs, azureWebJobsValues, appInsightsValues)

// =========== //
// Existing resources //
// =========== //
resource app 'Microsoft.Web/sites@2022-03-01' existing = {
  name: appName
  resource slot 'slots' existing = {
    name: slotName
  }
}

resource appInsight 'microsoft.insights/components@2020-02-02' existing = if (!empty(appInsightId)) {
  name: last(split(appInsightId, '/'))!
  scope: resourceGroup(split(appInsightId, '/')[2], split(appInsightId, '/')[4])
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' existing = if (!empty(storageAccountId)) {
  name: last(split(storageAccountId, '/'))!
  scope: resourceGroup(split(storageAccountId, '/')[2], split(storageAccountId, '/')[4])
}


resource slotSettings 'Microsoft.Web/sites/slots/config@2022-03-01' = {
  name: 'appsettings'
  kind: kind
  parent: app::slot
  properties: expandedAppSettings
}

// =========== //
// Outputs     //
// =========== //
@description('The name of the slot config.')
output name string = slotSettings.name

@description('The resource ID of the slot config.')
output resourceId string = slotSettings.id

@description('The resource group the slot config was deployed into.')
output resourceGroupName string = resourceGroup().name
