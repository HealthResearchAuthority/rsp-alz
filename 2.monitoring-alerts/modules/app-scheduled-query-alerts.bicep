targetScope = 'resourceGroup'

// ------------------
// PARAMETERS
// ------------------

@description('Resource IDs of Log Analytics workspace to query')
param logAnalyticsWorkspaceId string

@description('Environment name')
param environment string

@description('Naming prefix for alert rules')
param namingPrefix string

@description('Action group objects with optional webhook and logicapp entries (id, name)')
param actionGroups object

@description('Enable routing to the webhook action group globally')
param enableWebhookAg bool

@description('Enable routing to the Logic App action group globally')
param enableLogicAppAg bool

@description('Tags to apply to all resources')
param tags object = {}


@description('Enable App Service Down alert')
param enableAppServiceDownAlert bool = true
@description('Send App Service Down to webhook')
param sendAppServiceDownToWebhook bool = true
@description('Send App Service Down to Logic App')
param sendAppServiceDownToLogicApp bool = true

@description('Enable Identity Provider alert')
param enableIdentityProviderAlert bool = true
@description('Send Identity Provider alert to webhook')
param sendIdentityProviderFailuresToWebhook bool = true
@description('Send Identity Provider alert to Logic App')
param sendIdentityProviderFailuresToLogicApp bool = true

@description('Enable Database Connection Failures alert')
param enableDbConnectionFailuresAlert bool = true
@description('Send Database Connection Failures to webhook')
param sendDbConnectionFailuresToWebhook bool = true
@description('Send Database Connection Failures to Logic App')
param sendDbConnectionFailuresToLogicApp bool = true

@description('Enable App Service High Error Rate alert')
param enableHighErrorRateAlert bool = true
@description('Send App Service High Error Rate to webhook')
param sendHighErrorRateAlertToWebhook bool = true
@description('Send App Service High Error Rate to Logic App')
param sendHighErrorRateAlertToLogicApp bool = true

@description('Enable Container Apps Failures alert')
param enableContainerAppsFailuresAlert bool = true
@description('Send Container Apps Failures to webhook')
param sendContainerAppsFailuresToWebhook bool = true
@description('Send Container Apps Failures to Logic App')
param sendContainerAppsFailuresToLogicApp bool = true

@description('Enable Function App Failures alert')
param enableFuncAppFailuresAlert bool = true
@description('Send Function App Failures to webhook')
param sendFuncAppFailuresToWebhook bool = true
@description('Send Function App Failures to Logic App')
param sendFuncAppFailuresToLogicApp bool = true

// ------------------
// VARIABLES
// ------------------

var defaultTags = union(tags, {
  Environment: environment
  Purpose: 'Application Scheduled Query Alerts'
})

var webhookId = (contains(actionGroups, 'webhook') && !empty(actionGroups.webhook)) ? actionGroups.webhook.id : ''
var logicAppAgId = (contains(actionGroups, 'logicapp') && !empty(actionGroups.logicapp)) ? actionGroups.logicapp.id : ''


var ruleName1 = '${namingPrefix}-appservice-down'
var ruleName2 = '${namingPrefix}-identity-provider'
var ruleName3 = '${namingPrefix}-db-connection-failures'
var ruleName4 = '${namingPrefix}-appservice-high-error-rate'
var ruleName5 = '${namingPrefix}-container-apps-failures'
var ruleName6 = '${namingPrefix}-function-app-failures'

// ------------------
// RESOURCES
// ------------------

// 1. App Service Down - IRAS and CMS Portal
module alert1 '../../shared/bicep/monitoring/scheduled-query-rule.bicep' = if (enableAppServiceDownAlert) {
  name: 'sq-appservice-down'
  params: {
    ruleName: ruleName1
    displayName: 'P1: App Service Unavailable'
    ruleDescription: 'Detects 500s on IRAS/CMS portal endpoints over 5m with threshold >= 4'
    enabled: enableAppServiceDownAlert
    severity: 0
    actionGroupIds: concat(
      enableWebhookAg && sendAppServiceDownToWebhook && !empty(webhookId) ? [webhookId] : [],
      enableLogicAppAg && sendAppServiceDownToLogicApp && !empty(logicAppAgId) ? [logicAppAgId] : []
    )
    query: format('''
let timeWindow = 5m;
AppRequests
| where TimeGenerated > ago(timeWindow)
| where ResultCode == "500"
| where Name in ("GET /", "GET Application/Welcome", "GET /application/welcome")
| where AppRoleName in ("irasportal-{0}")
| summarize UniqueInstances = dcount(AppRoleName) by AppRoleName, OperationName, ResultCode, _ResourceId
| project AlertTitle = strcat("App Service Unavailable - ", AppRoleName), Severity = "P1-Critical", AffectedService = AppRoleName, Detail = OperationName, _ResourceId
''', environment)
    dataSourceIds: logAnalyticsWorkspaceId
    evaluationFrequencyInMinutes: 5
    windowSizeInMinutes: 5
    operator: 'GreaterThan'
    threshold: 4
    numberOfEvaluationPeriods: 1
    minFailingPeriodsToAlert: 1
    resourceIdColumn: '_ResourceId'
    tags: defaultTags
  }
}

// 2. Identity Provider Failure Alert
module alert2 '../../shared/bicep/monitoring/scheduled-query-rule.bicep' = if (enableIdentityProviderAlert) {
  name: 'sq-identity-provider'
  params: {
    ruleName: ruleName2
    displayName: 'P1: One Login Unavailable'
    ruleDescription: 'Detects One Login dependency failures over 5m with threshold >= 10'
    enabled: enableIdentityProviderAlert
    severity: 0
    actionGroupIds: concat(
      enableWebhookAg && sendIdentityProviderFailuresToWebhook && !empty(webhookId) ? [webhookId] : [],
      enableLogicAppAg && sendIdentityProviderFailuresToLogicApp && !empty(logicAppAgId) ? [logicAppAgId] : []
    )
    query: format('''
let timeWindow = 5m;
let errorThreshold = 10;
AppDependencies
| where TimeGenerated > ago(timeWindow)
| where Target == "oidc.integration.account.gov.uk"
| where AppRoleName in ("irasportal-{0}")
| where ResultCode in ("Canceled") or ResultCode startswith "5"
| summarize FirstOccurrence = min(TimeGenerated), LastOccurrence = max(TimeGenerated), TotalErrors = sum(ItemCount), UniqueInstances = dcount(Data), SampleUrls = make_set(Data, 3) by Target, AppRoleName, OperationName, ResultCode, _ResourceId
| where TotalErrors >= errorThreshold
| project AlertTitle = strcat("P1: Service Unavailable - One Login"), Severity = "P1-Critical", FirstOccurrence, LastOccurrence, AffectedService = AppRoleName, Detail = OperationName, ResultCode, TotalErrors, UniqueInstances, SampleUrls, _ResourceId
''', environment)
    dataSourceIds: logAnalyticsWorkspaceId 
    evaluationFrequencyInMinutes: 5
    windowSizeInMinutes: 5
    operator: 'GreaterThan'
    threshold: 0
    numberOfEvaluationPeriods: 1
    minFailingPeriodsToAlert: 1
    resourceIdColumn: '_ResourceId'
    tags: defaultTags
  }
}

// 3. Database Connection Failures
module alert3 '../../shared/bicep/monitoring/scheduled-query-rule.bicep' = if (enableDbConnectionFailuresAlert) {
  name: 'sq-db-connection-failures'
  params: {
    ruleName: ruleName3
    displayName: 'P1: Database Unavailable'
    ruleDescription: 'Detects failed SQL dependencies over 5m with threshold >= 10'
    enabled: enableDbConnectionFailuresAlert
    severity: 0
    actionGroupIds: concat(
      enableWebhookAg && sendDbConnectionFailuresToWebhook && !empty(webhookId) ? [webhookId] : [],
      enableLogicAppAg && sendDbConnectionFailuresToLogicApp && !empty(logicAppAgId) ? [logicAppAgId] : []
    )
    query: format('''
let timeWindow = 5m;
let errorThreshold = 10;
AppDependencies
| where TimeGenerated > ago(timeWindow)
| where DependencyType in ("SQL")
| where Success in (false)
| where Target has "rspsqlserver{0}"
| extend Exception = tostring(todynamic(Properties).Exception)
| summarize FirstOccurrence = min(TimeGenerated), LastOccurrence = max(TimeGenerated), TotalErrors = sum(ItemCount), UniqueInstances = dcount(AppRoleInstance) by AppRoleInstance, OperationName, Exception, Target, _ResourceId
| where TotalErrors >= errorThreshold
| project AlertTitle = strcat("Database Unavailable - ", AppRoleInstance), Severity = "P1-Critical", FirstOccurrence, LastOccurrence, AffectedService = AppRoleInstance, OperationName, Target, TotalErrors, UniqueInstances, Detail = Exception, _ResourceId
''', environment)
    dataSourceIds: logAnalyticsWorkspaceId 
    evaluationFrequencyInMinutes: 5
    windowSizeInMinutes: 5
    operator: 'GreaterThan'
    threshold: 0
    numberOfEvaluationPeriods: 1
    minFailingPeriodsToAlert: 1
    metricMeasureColumn: 'TotalErrors'
    resourceIdColumn: '_ResourceId'
    timeAggregation: 'Total'
    tags: defaultTags
  }
}

// 4. App Service High Error Rate
module alert4 '../../shared/bicep/monitoring/scheduled-query-rule.bicep' = if (enableHighErrorRateAlert) {
  name: 'sq-appservice-high-error-rate'
  params: {
    ruleName: ruleName4
    displayName: 'P2: High App Service Error Rate'
    ruleDescription: 'Detects high 500 error rate over 5minutes with threshold > 20'
    enabled: enableHighErrorRateAlert
    severity: 1
    actionGroupIds: concat(
      enableWebhookAg && sendHighErrorRateAlertToWebhook && !empty(webhookId) ? [webhookId] : [],
      enableLogicAppAg && sendHighErrorRateAlertToLogicApp && !empty(logicAppAgId) ? [logicAppAgId] : []
    )
    query: format('''
let timeWindow = 10m;
let errorThreshold = 20;
AppRequests
| where ResultCode in (500)
| where AppRoleName has "{0}"
| summarize FirstAlertTime = min(TimeGenerated), TotalFailures = sum(ItemCount) by AppRoleName, OperationName, _ResourceId
| where TotalFailures > errorThreshold
| project AlertTitle = strcat("High Error Rate - ", AppRoleName), Severity = "P2-High", FirstAlertTime, AffectedService = AppRoleName, Detail = OperationName, TotalFailures, _ResourceId
''', environment)
    dataSourceIds: logAnalyticsWorkspaceId
    evaluationFrequencyInMinutes: 5
    windowSizeInMinutes: 15
    operator: 'GreaterThan'
    threshold: 20
    numberOfEvaluationPeriods: 1
    minFailingPeriodsToAlert: 1
    metricMeasureColumn: 'TotalFailures'
    timeAggregation: 'Total'
    resourceIdColumn: '_ResourceId'
    tags: defaultTags
  }
}

// 5. Container Apps Failures
module alert5 '../../shared/bicep/monitoring/scheduled-query-rule.bicep' = if (enableContainerAppsFailuresAlert) {
  name: 'sq-container-apps-failures'
  params: {
    ruleName: ruleName5
    displayName: 'P2: Container App API Failures'
    ruleDescription: 'Detects container app API 500 failures over 5m with threshold > 50'
    enabled: enableContainerAppsFailuresAlert
    severity: 1
    actionGroupIds: concat(
      enableWebhookAg && sendContainerAppsFailuresToWebhook && !empty(webhookId) ? [webhookId] : [],
      enableLogicAppAg && sendContainerAppsFailuresToLogicApp && !empty(logicAppAgId) ? [logicAppAgId] : []
    )
    query: format('''
let timeWindow = 10m;
let errorThreshold = 50;
AppRequests
| where ResultCode in (500)
| where Url has "azurecontainerapps.io"
| where AppRoleName has "{0}"
| summarize FirstAlertTime = min(TimeGenerated), TotalFailures = sum(ItemCount), UniqueErrorCodes = make_set(ResultCode), UniqueInstances = make_set(AppRoleInstance) by AppRoleName, OperationName, _ResourceId
| where TotalFailures > errorThreshold
| project AlertTitle = strcat("Container App API Failures - ", AppRoleName), Severity = "P2-High", FirstAlertTime, AffectedService = AppRoleName, Detail = OperationName, TotalFailures, AffectedInstances = UniqueInstances, ErrorCodes = UniqueErrorCodes, _ResourceId
''', environment)
    dataSourceIds: logAnalyticsWorkspaceId 
    evaluationFrequencyInMinutes: 5
    windowSizeInMinutes: 5
    operator: 'GreaterThan'
    threshold: 0
    numberOfEvaluationPeriods: 1
    minFailingPeriodsToAlert: 1
    metricMeasureColumn: 'TotalFailures'
    timeAggregation: 'Total'
    resourceIdColumn: '_ResourceId'
    tags: defaultTags
  }
}

// 6. Function App Failures
module alert6 '../../shared/bicep/monitoring/scheduled-query-rule.bicep' = if (enableFuncAppFailuresAlert) {
  name: 'sq-function-app-failures'
  params: {
    ruleName: ruleName6
    displayName: 'P1: Function App Failures'
    ruleDescription: 'Detects unhandled exceptions in function apps over 5minutes'
    enabled: enableFuncAppFailuresAlert
    severity: 1
    actionGroupIds: concat(
      enableWebhookAg && sendFuncAppFailuresToWebhook && !empty(webhookId) ? [webhookId] : [],
      enableLogicAppAg && sendFuncAppFailuresToLogicApp && !empty(logicAppAgId) ? [logicAppAgId] : []
    )
    query: format('''
let timeWindow = 5m;
AppExceptions
| where AppRoleName has_any ("{0}")
| where AppRoleName has "func-"
| where InnermostMessage has "Unhandled Exception"
| extend ExceptionMessage = tostring(Details[1]['message'])
| project AlertTitle = strcat("Function App Execution Failure - ", AppRoleName), Severity = "P1-Critical", TimeGenerated, AffectedService = AppRoleName, Detail = InnermostMessage, Details, _ResourceId
''', environment)
    dataSourceIds: logAnalyticsWorkspaceId 
    evaluationFrequencyInMinutes: 5
    windowSizeInMinutes: 5
    operator: 'GreaterThan'
    threshold: 0
    numberOfEvaluationPeriods: 1
    minFailingPeriodsToAlert: 1
    resourceIdColumn: '_ResourceId'
    muteActionsDurationInMinutes: 30
    tags: defaultTags
  }
}

// ------------------
// OUTPUTS
// ------------------

@description('Scheduled query rule resource IDs')
output alertRuleIds object = {
  alert1: enableAppServiceDownAlert ? resourceId('Microsoft.Insights/scheduledQueryRules', ruleName1) : ''
  alert2: enableIdentityProviderAlert ? resourceId('Microsoft.Insights/scheduledQueryRules', ruleName2) : ''
  alert3: enableDbConnectionFailuresAlert ? resourceId('Microsoft.Insights/scheduledQueryRules', ruleName3) : ''
  alert4: enableHighErrorRateAlert ? resourceId('Microsoft.Insights/scheduledQueryRules', ruleName4) : ''
  alert5: enableContainerAppsFailuresAlert ? resourceId('Microsoft.Insights/scheduledQueryRules', ruleName5) : ''
  alert6: enableFuncAppFailuresAlert? resourceId('Microsoft.Insights/scheduledQueryRules', ruleName6) : ''
}
