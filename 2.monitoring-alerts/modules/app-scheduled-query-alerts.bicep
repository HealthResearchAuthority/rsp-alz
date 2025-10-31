targetScope = 'resourceGroup'

metadata name = 'App Alerts - Scheduled Query Alerts'
metadata description = 'Deploys KQL-based scheduled query alerts for applications'

// ------------------
// PARAMETERS
// ------------------

@description('Resource IDs of Log Analytics workspaces to query')
param workspaceIds array

@description('Environment name')
param environment string

@description('Naming prefix for alert rules')
param namingPrefix string

@description('Action group objects with optional webhook and teams entries (id, name)')
param actionGroups object

@description('Enable routing to the webhook action group globally')
param enableWebhookAg bool = true

@description('Enable routing to the Teams action group globally')
param enableTeamsAg bool = true

@description('Tags to apply to all resources')
param tags object = {}

// Per-alert enable and routing params
@description('Enable App Service Down alert')
param enableAppServiceDownAlert bool = true
@description('Route App Service Down to webhook')
param routeAppServiceDownToWebhook bool = true
@description('Route App Service Down to Teams')
param routeAppServiceDownToTeams bool = true

@description('Enable Identity Provider alert')
param enableIdentityProviderAlert bool = true
@description('Route Identity Provider alert to webhook')
param routeIdentityProviderFailuresToWebhook bool = true
@description('Route Identity Provider alert to Teams')
param routeIdentityProviderFailuresToTeams bool = true

@description('Enable Database Connection Failures alert')
param enableDbConnectionFailuresAlert bool = true
@description('Route Database Connection Failures to webhook')
param routeDbConnectionFailuresToWebhook bool = true
@description('Route Database Connection Failures to Teams')
param routeDbConnectionFailuresToTeams bool = true

@description('Enable App Service High Error Rate alert')
param enableHighErrorRateAlert bool = true
@description('Route App Service High Error Rate to webhook')
param routeHighErrorRateAlertToWebhook bool = true
@description('Route App Service High Error Rate to Teams')
param routeHighErrorRateAlertToTeams bool = true

@description('Enable Container Apps Failures alert')
param enableContainerAppsFailuresAlert bool = true
@description('Route Container Apps Failures to webhook')
param routeContainerAppsFailuresToWebhook bool = true
@description('Route Container Apps Failures to Teams')
param routeContainerAppsFailuresToTeams bool = true

@description('Enable Function App Failures alert')
param enableFuncAppFailuresAlert bool = true
@description('Route Function App Failures to webhook')
param routeFuncAppFailuresToWebhook bool = true
@description('Route Function App Failures to Teams')
param routeFuncAppFailuresToTeams bool = true

// ------------------
// VARIABLES
// ------------------

var defaultTags = union(tags, {
  Environment: environment
  Purpose: 'Application Scheduled Query Alerts'
})

var webhookId = (contains(actionGroups, 'webhook') && !empty(actionGroups.webhook)) ? actionGroups.webhook.id : ''
var teamsId = (contains(actionGroups, 'teams') && !empty(actionGroups.teams)) ? actionGroups.teams.id : ''


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
    ruleDescription: 'Detects 500s on IRAS/CMS portal endpoints over 5m with threshold >= 10'
    enabled: true
    severity: 0
    actionGroupIds: concat(
      enableWebhookAg && routeAppServiceDownToWebhook && !empty(webhookId) ? [webhookId] : [],
      enableTeamsAg && routeAppServiceDownToTeams && !empty(teamsId) ? [teamsId] : []
    )
    query: '''
let timeWindow = 5m;
let errorThreshold = 10;
AppRequests
| where TimeGenerated > ago(timeWindow)
| where ResultCode == "500"
| where Name in ("GET /", "GET Application/Welcome", "GET /application/welcome")
| where AppRoleName in ("irasportal-${environment}")
| summarize FirstOccurrence = min(TimeGenerated), LastOccurrence = max(TimeGenerated), TotalErrors = sum(ItemCount), UniqueInstances = dcount(AppRoleName), SampleUrls = make_set(Url, 3) by AppRoleName, OperationName, ResultCode, _ResourceId
| where TotalErrors >= errorThreshold
| project AlertTitle = strcat("P1: App Service Unavailable - ", AppRoleName), Severity = "P1-Critical", FirstOccurrence, LastOccurrence, AppServiceName = AppRoleName, OperationName, ResultCode, TotalErrors, UniqueInstances, SampleUrls
'''
    dataSourceIds: workspaceIds
    evaluationFrequencyInMinutes: 60
    windowSizeInMinutes: 10080
    operator: 'GreaterThan'
    threshold: 0
    numberOfEvaluationPeriods: 1
    minFailingPeriodsToAlert: 1
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
    enabled: true
    severity: 0
    actionGroupIds: concat(
      enableWebhookAg && routeIdentityProviderFailuresToWebhook && !empty(webhookId) ? [webhookId] : [],
      enableTeamsAg && routeIdentityProviderFailuresToTeams && !empty(teamsId) ? [teamsId] : []
    )
    query: '''
let timeWindow = 5m;
let errorThreshold = 10;
AppDependencies
| where TimeGenerated > ago(timeWindow)
| where Target == "oidc.integration.account.gov.uk"
| where AppRoleName in ("irasportal-manualtest")
| where ResultCode in ("Canceled") or ResultCode startswith "5"
| summarize FirstOccurrence = min(TimeGenerated), LastOccurrence = max(TimeGenerated), TotalErrors = sum(ItemCount), UniqueInstances = dcount(Data), SampleUrls = make_set(Data, 3) by Target, AppRoleName, OperationName, ResultCode
| where TotalErrors >= errorThreshold
| project AlertTitle = strcat("P1: Service Unavailable - One Login"), Severity = "P1-Critical", FirstOccurrence, LastOccurrence, AppServiceName = AppRoleName, OperationName, ResultCode, TotalErrors, UniqueInstances, SampleUrls
'''
    dataSourceIds: workspaceIds
    evaluationFrequencyInMinutes: 5
    windowSizeInMinutes: 5
    operator: 'GreaterThan'
    threshold: 0
    numberOfEvaluationPeriods: 1
    minFailingPeriodsToAlert: 1
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
    enabled: true
    severity: 0
    actionGroupIds: concat(
      enableWebhookAg && routeDbConnectionFailuresToWebhook && !empty(webhookId) ? [webhookId] : [],
      enableTeamsAg && routeDbConnectionFailuresToTeams && !empty(teamsId) ? [teamsId] : []
    )
    query: '''
let timeWindow = 5m;
let errorThreshold = 10;
AppDependencies
| where TimeGenerated > ago(timeWindow)
| where DependencyType in ("SQL")
| where Success in (false)
| where Target has "rspsqlserver${environment}"
| extend Exception = tostring(todynamic(Properties).Exception)
| summarize FirstOccurrence = min(TimeGenerated), LastOccurrence = max(TimeGenerated), TotalErrors = sum(ItemCount), UniqueInstances = dcount(AppRoleInstance) by AppRoleInstance, OperationName, Exception, Target
| where TotalErrors >= errorThreshold
| project AlertTitle = strcat("P1: Database Unavailable - ", AppRoleInstance), Severity = "P1-Critical", FirstOccurrence, LastOccurrence, AppServiceName = AppRoleInstance, OperationName, Target, TotalErrors, UniqueInstances, Exception
'''
    dataSourceIds: workspaceIds
    evaluationFrequencyInMinutes: 5
    windowSizeInMinutes: 5
    operator: 'GreaterThan'
    threshold: 0
    numberOfEvaluationPeriods: 1
    minFailingPeriodsToAlert: 1
    tags: defaultTags
  }
}

// 4. App Service High Error Rate
module alert4 '../../shared/bicep/monitoring/scheduled-query-rule.bicep' = if (enableHighErrorRateAlert) {
  name: 'sq-appservice-high-error-rate'
  params: {
    ruleName: ruleName4
    displayName: 'P2: High App Service Error Rate'
    ruleDescription: 'Detects high 500 error rate over 5minutes with threshold > 50'
    enabled: true
    severity: 1
    actionGroupIds: concat(
      enableWebhookAg && routeHighErrorRateAlertToWebhook && !empty(webhookId) ? [webhookId] : [],
      enableTeamsAg && routeHighErrorRateAlertToTeams && !empty(teamsId) ? [teamsId] : []
    )
    query: '''
let timeWindow = 5m;
let errorThreshold = 50;
AppRequests
| where ResultCode in (500)
| where AppRoleName has "${environment}"
| summarize FirstAlertTime = min(TimeGenerated), TotalFailures = sum(ItemCount), UniqueErrorCodes = make_set(ResultCode), UniqueInstances = make_set(AppRoleInstance) by AppRoleName, OperationName
| where TotalFailures > errorThreshold
| project AlertTitle = strcat("P2: High Error Rate - ", AppRoleName), Severity = "P2-High", FirstAlertTime, AppServiceName = AppRoleName, OperationName, TotalFailures, AffectedInstances = UniqueInstances, ErrorCodes = UniqueErrorCodes
'''
    dataSourceIds: workspaceIds
    evaluationFrequencyInMinutes: 60
    windowSizeInMinutes: 43200
    operator: 'GreaterThan'
    threshold: 0
    numberOfEvaluationPeriods: 1
    minFailingPeriodsToAlert: 1
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
    enabled: true
    severity: 1
    actionGroupIds: concat(
      enableWebhookAg && routeContainerAppsFailuresToWebhook && !empty(webhookId) ? [webhookId] : [],
      enableTeamsAg && routeContainerAppsFailuresToTeams && !empty(teamsId) ? [teamsId] : []
    )
    query: '''
let timeWindow = 5;
let errorThreshold = 50;
AppRequests
| where ResultCode in (500)
| where Url has "azurecontainerapps.io"
| summarize FirstAlertTime = min(TimeGenerated), TotalFailures = sum(ItemCount), UniqueErrorCodes = make_set(ResultCode), UniqueInstances = make_set(AppRoleInstance) by AppRoleName, OperationName
| where TotalFailures > errorThreshold
| project AlertTitle = strcat("P2: Container App API Failures - ", AppRoleName), Severity = "P2-High", FirstAlertTime, ContainerAppName = AppRoleName, OperationName, TotalFailures, AffectedInstances = UniqueInstances, ErrorCodes = UniqueErrorCodes
'''
    dataSourceIds: workspaceIds
    evaluationFrequencyInMinutes: 60
    windowSizeInMinutes: 5
    operator: 'GreaterThan'
    threshold: 0
    numberOfEvaluationPeriods: 1
    minFailingPeriodsToAlert: 1
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
    enabled: true
    severity: 1
    actionGroupIds: concat(
      enableWebhookAg && routeFuncAppFailuresToWebhook && !empty(webhookId) ? [webhookId] : [],
      enableTeamsAg && routeFuncAppFailuresToTeams && !empty(teamsId) ? [teamsId] : []
    )
    query: '''
let timeWindow = 5m;
let errorThreshold = 50;
AppExceptions
| where AppRoleName has_any ("${environment}")
| where AppRoleName has "func-"
| where InnermostMessage has "Unhandled Exception"
| extend ExceptionMessage = tostring(Details[1]['message'])
| project TimeGenerated, ExceptionMessage, ExceptionType, SeverityLevel, InnermostType, InnermostMessage, Details, AppRoleName
'''
    dataSourceIds: workspaceIds
    evaluationFrequencyInMinutes: 60
    windowSizeInMinutes: 43200
    operator: 'GreaterThan'
    threshold: 0
    numberOfEvaluationPeriods: 1
    minFailingPeriodsToAlert: 1
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


