// ------------------
// PARAMETERS
// ------------------

@description('Required. Environment name for resource naming.')
param environment string

@description('Required. Subscription ID for the target environment.')
param subscriptionId string

@description('Required. Resource group name for the target environment.')
param resourceGroupName string

@description('Required. Location for all resources.')
param location string

@description('Optional. Tags for all resources.')
param tags object = {}

@description('Optional. Function App 1 name (e.g., func-processdocupload-{env}).')
param functionApp1Name string = 'func-processdocupload-${environment}'

@description('Optional. Function App 2 name (e.g., func-rts-data-sync-{env}).')
param functionApp2Name string = 'func-rts-data-sync-${environment}'

@description('Optional. Front Door profile name (e.g., afd-rsp-applications-{env}-uks).')
param frontDoorProfileName string = 'afd-rsp-applications-${environment}-uks'

@description('Optional. Front Door endpoint hostname.')
param frontDoorEndpoint string = 'fd-rsp-applications-${environment}-uks-cveeakgqdgbqexbz.a03.azurefd.net'

@description('Optional. Origin Group 1 name.')
param originGroup1Name string = 'og-rsp-applications-${environment}-uks'

@description('Optional. Origin Group 2 name.')
param originGroup2Name string = 'og-rsp-applications-${environment}-uks-cms'

@description('Optional. Subscription display name for SQL metrics.')
param subscriptionDisplayName string = 'hra-rsp-${environment}'

@description('Optional. Master database filter for SQL metrics.')
param masterDatabaseFilter string = '/SUBSCRIPTIONS/${toUpper(subscriptionId)}/RESOURCEGROUPS/${toUpper(resourceGroupName)}/PROVIDERS/MICROSOFT.SQL/SERVERS/RSPSQLSERVER${toUpper(environment)}/DATABASES/MASTER'

// ------------------
// VARIABLES
// ------------------

var resourceDashboardName = 'dashboard-iras-resources-${environment}'

// Template placeholder values to replace
var templateSubscriptionId = 'TEMPLATE_SUBSCRIPTION_ID'
var templateResourceGroup = 'TEMPLATE_RESOURCE_GROUP'
var templateEnvironment = 'TEMPLATE_ENVIRONMENT'
var templateFunctionApp1 = 'TEMPLATE_FUNCTION_APP_1'
var templateFunctionApp2 = 'TEMPLATE_FUNCTION_APP_2'
var templateFrontDoorProfile = 'TEMPLATE_FRONTDOOR_PROFILE'
var templateFrontDoorEndpoint = 'TEMPLATE_FRONTDOOR_ENDPOINT'
var templateOriginGroup1 = 'TEMPLATE_ORIGIN_GROUP_1'
var templateOriginGroup2 = 'TEMPLATE_ORIGIN_GROUP_2'
var templateSubscriptionName = 'TEMPLATE_SUBSCRIPTION_NAME'
var templateMasterDatabaseFilter = 'TEMPLATE_MASTER_DATABASE_FILTER'

// Load dashboard template and convert to string for replacement
var resourceDashboardTemplateString = string(loadJsonContent('iras-resource-dashboard-template.json').properties)

// Replace template placeholders with actual values
var step1 = replace(resourceDashboardTemplateString, templateSubscriptionId, subscriptionId)
var step2 = replace(step1, templateResourceGroup, resourceGroupName)
var step3 = replace(step2, templateEnvironment, environment)
var step4 = replace(step3, templateFunctionApp1, functionApp1Name)
var step5 = replace(step4, templateFunctionApp2, functionApp2Name)
var step6 = replace(step5, templateFrontDoorProfile, frontDoorProfileName)
var step7 = replace(step6, templateFrontDoorEndpoint, frontDoorEndpoint)
var step8 = replace(step7, templateOriginGroup1, originGroup1Name)
var step9 = replace(step8, templateOriginGroup2, originGroup2Name)
var step10 = replace(step9, templateSubscriptionName, subscriptionDisplayName)
var step11 = replace(step10, templateMasterDatabaseFilter, masterDatabaseFilter)

// Parse back to JSON
var resourceDashboardProperties = json(step11)

// Dashboard title and name
var dashboardTitle = 'IRAS Resources - ${environment}'

// ------------------
// RESOURCES
// ------------------

resource resourceDashboard 'Microsoft.Portal/dashboards@2022-12-01-preview' = {
  name: resourceDashboardName
  location: location
  tags: union(tags, {
    'hidden-title': dashboardTitle
  })
  properties: resourceDashboardProperties
}

// ------------------
// OUTPUTS
// ------------------

@description('The resource ID of the IRAS Resource dashboard.')
output resourceDashboardId string = resourceDashboard.id

@description('The name of the IRAS Resource dashboard.')
output resourceDashboardName string = resourceDashboard.name
