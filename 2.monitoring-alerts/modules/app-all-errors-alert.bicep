targetScope = 'resourceGroup'

@description('Rule name for the scheduled query alert')
param ruleName string

@description('Display name for the alert')
param displayName string = 'All Errors - Exceptions and Requests'

@description('Description for the alert')
param ruleDescription string = 'Combined Exceptions (Severity >= Error) and Request failures (5xx or Success=false)'

@description('Enable or disable the alert')
param enabled bool = true

@description('Severity (0=Critical, 1=Error, 2=Warning, 3=Informational, 4=Verbose)')
@allowed([0, 1, 2, 3, 4])
param severity int = 1

@description('Log Analytics workspace resource ID to query')
param workspaceId string

@description('Array of Action Group IDs to notify')
param actionGroupIds array = []

@description('Evaluation frequency in minutes')
param evaluationFrequencyInMinutes int = 5

@description('Time window in minutes')
param windowSizeInMinutes int = 5

@description('Throttle duplicate notifications for this many minutes')
param muteActionsDurationInMinutes int = 60

@description('Optional target Azure resourceId to filter on (_ResourceId)')
param targetResourceId string = ''

@description('Tags to apply')
param tags object = {}

var query = format('''
let timeWindow = {0}m;
let resourceId = "{1}";
let exceptions_raw =
AppExceptions
| where TimeGenerated > ago(timeWindow)
| where SeverityLevel >= 3
| where isempty(resourceId) or _ResourceId == resourceId
| project Source = "Exceptions", TimeGenerated, AppRoleName, OperationName, Detail = InnermostMessage, _ResourceId;
let requests_raw =
AppRequests
| where TimeGenerated > ago(timeWindow)
| where toint(ResultCode) >= 500 or Success == false
| where isempty(resourceId) or _ResourceId == resourceId
| project Source = "Requests", TimeGenerated, AppRoleName, OperationName, Detail = strcat("HTTP ", tostring(ResultCode)), _ResourceId;
let exceptions =
exceptions_raw
| summarize TimeGenerated = max(TimeGenerated) by Source, AppRoleName, OperationName, Detail, _ResourceId;
let requests =
requests_raw
| summarize TimeGenerated = max(TimeGenerated) by Source, AppRoleName, OperationName, Detail, _ResourceId;
union exceptions, requests
| order by TimeGenerated desc
''', string(windowSizeInMinutes), targetResourceId)

module rule '../../shared/bicep/monitoring/scheduled-query-rule.bicep' = {
  name: 'deploy-all-errors-sqrule'
  params: {
    ruleName: ruleName
    displayName: displayName
    ruleDescription: ruleDescription
    enabled: enabled
    severity: severity
    actionGroupIds: actionGroupIds
    query: query
    dataSourceIds: workspaceId
    evaluationFrequencyInMinutes: evaluationFrequencyInMinutes
    windowSizeInMinutes: windowSizeInMinutes
    operator: 'GreaterThan'
    threshold: 0
    numberOfEvaluationPeriods: 1
    minFailingPeriodsToAlert: 1
    muteActionsDurationInMinutes: muteActionsDurationInMinutes
    tags: tags
  }
}

@description('Scheduled query rule resource ID')
output scheduledQueryRuleId string = resourceId('Microsoft.Insights/scheduledQueryRules', ruleName)

@description('Scheduled query rule name')
output scheduledQueryRuleName string = ruleName


