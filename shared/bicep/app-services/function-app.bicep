@description('Required. Name of your Function App.')
param functionAppName string

@description('Optional. Location for all resources.')
param location string

@description('Optional. Tags of the resource.')
param tags object = {}

@description('Optional. Additional app settings.')
param appSettings array = []

@description('Required. The resource ID of the app service plan to use for the site.')
param serverFarmResourceId string

@description('Optional, default is false. If true, then a private endpoint must be assigned to the function app')
param hasPrivateEndpoint bool = false

@description('Client ID of the managed identity to be used for the SQL DB connection string.')
param sqlDBManagedIdentityClientId string = ''

@maxLength(24)
@description('Conditional. The name of the parent Storage Account. Required if the template is used in a standalone deployment.')
param storageAccountName string

@description('Optional. Runtime for Function App.')
@allowed([
  'node'
  'dotnet'
  'java'
  'dotnet-isolated'
])
param runtime string = 'dotnet-isolated' // e.g., 'dotnet', 'node', 'python', etc.

@description('Optional. Runtime Version for Function App.')
param runtimeVersion string = '~4'

@description('Optional. Dotnet framework version.')
param dotnetVersion string = '9.0'


// @description('Optional. Resource ID of log analytics workspace.')
// param diagnosticWorkspaceId string = ''

@description('Optional. The ID(s) to assign to the resource.')
param userAssignedIdentities object = {}

@description('Optional. Resource ID of the app insight to leverage for this resource.')
param appInsightId string = ''

param eventGridServiceTagRestriction bool = false
@description('Optional. The IP ACL rules. Note, requires the \'acrSku\' to be \'Premium\'.')
param networkRuleSetIpRules array = []

@description('Required. Type of site to deploy.')
@allowed([
  'functionapp' // function app windows os
  'functionapp,linux' // function app linux os
  'functionapp,workflowapp' // logic app workflow
  // 'functionapp,workflowapp,linux' // logic app docker container
  'app' // normal web app
  'app,linux' // normal web app linux OS
  'app,linux,container' //web app for containers - linux
])
param kind string

@description('Optional. Azure Resource Manager ID of the Virtual network and subnet to be joined by Regional VNET Integration. This must be of the form /subscriptions/{subscriptionName}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{vnetName}/subnets/{subnetName}.')
param virtualNetworkSubnetId string = ''

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: storageAccountName
}

resource fnAppAppInsights 'microsoft.insights/components@2020-02-02' existing = if (!empty(appInsightId)) {
  name: last(split(appInsightId, '/'))!
  scope: resourceGroup(split(appInsightId, '/')[2], split(appInsightId, '/')[4])
}

var defaultSettings = [
  // {
  //   name: 'AzureWebJobsStorage'
  //   value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id, '2022-09-01').keys[0].value};EndpointSuffix=core.windows.net'
  // }
  // {
  //   name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
  //   value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id, '2022-09-01').keys[0].value};EndpointSuffix=core.windows.net'
  // }
  {
    name: 'FUNCTIONS_EXTENSION_VERSION'
    value: runtimeVersion
  }
  {
    name: 'FUNCTIONS_WORKER_RUNTIME'
    value: runtime
  }
  {
    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
    value: fnAppAppInsights!.properties.InstrumentationKey
  }
  {
    name: 'AZURE_CLIENT_ID'
    value: sqlDBManagedIdentityClientId
  }
]

// Additional settings for private endpoint scenarios
var privateEndpointSettings = hasPrivateEndpoint ? [
  {
    name: 'WEBSITE_VNET_ROUTE_ALL' 
    value: '1'
  }
  {
    name: 'WEBSITE_WEBDEPLOY_USE_SCM'
    value: 'true'
  }
] : []

// NEW VARIABLE FOR EVENT GRID RULE
var eventGridRule = {
  ipAddress: 'AzureEventGrid' // Service Tag value
  action: 'Allow'
  tag: 'ServiceTag'
  priority: 100 // Set a high priority to ensure it's evaluated early
  name: 'Allow-AzureEventGrid-Traffic'
  description: 'Allow Azure Event Grid inbound.'
}

var combinedIpRestrictions = eventGridServiceTagRestriction ? concat(networkRuleSetIpRules, [eventGridRule]) : networkRuleSetIpRules

resource functionApp 'Microsoft.Web/sites@2024-04-01' = {
  name: functionAppName
  location: location
  kind: kind
  identity: userAssignedIdentities
  properties: {
    httpsOnly: true
    publicNetworkAccess: hasPrivateEndpoint && !eventGridServiceTagRestriction ? 'Disabled' : 'Enabled'
    serverFarmId: serverFarmResourceId
    virtualNetworkSubnetId: !empty(virtualNetworkSubnetId) ? virtualNetworkSubnetId : any(null)
    siteConfig: {
      netFrameworkVersion: dotnetVersion
      appSettings: concat(defaultSettings, privateEndpointSettings, appSettings)
      alwaysOn: true
    }
  }
  tags: tags
}

resource webConfig 'Microsoft.Web/sites/config@2022-09-01' = if (!empty(networkRuleSetIpRules) || eventGridServiceTagRestriction) {
  parent: functionApp
  name: 'web'
  properties: {
    // UPDATED: Use the combined array of IP restrictions
    ipSecurityRestrictions: combinedIpRestrictions
  }
}

output functionAppName string = functionApp.name
output functionAppId string = functionApp.id
output defaultHostName string = functionApp.properties.defaultHostName
output systemAssignedPrincipalId string = functionApp.identity.?principalId ?? ''

