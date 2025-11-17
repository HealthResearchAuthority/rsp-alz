targetScope = 'resourceGroup'

@description('Rule name for the scheduled query alert')
param ruleName string

@description('Display name for the alert')
param displayName string = 'All Errors - Exceptions and Requests'

@description('Environment name')
param environment string

@description('Description for the alert')
param ruleDescription string = 'Combined Exceptions (Severity >= Error) and Request failures (5xx or Success=false)'

@description('Enable or disable the alert')
param enabled bool = true

@description('Severity (0=Critical, 1=Error, 2=Warning, 3=Informational, 4=Verbose)')
@allowed([0, 1, 2, 3, 4])
param severity int = 3

@description('Log Analytics workspace resource ID to query')
param workspaceId string

@description('Array of Action Group IDs to notify')
param actionGroupIds array = []

@description('Evaluation frequency in minutes')
param evaluationFrequencyInMinutes int = 5

@description('Time window in minutes')
param windowSizeInMinutes int = 5

@description('Throttle duplicate notifications for this many minutes')
param muteActionsDurationInMinutes int = 10

@description('Tags to apply')
param tags object = {}

var query = format('''
let timeWindow = 10m;
let resourceId = "";
let env = "{0}";
let req =
AppRequests
| where TimeGenerated > ago(timeWindow)
| where toint(ResultCode) == 500
| where isempty(resourceId) or _ResourceId == resourceId
| where AppRoleName has env
| project TimeGenerated, AlertTitle = strcat("AppInsight Error - ", AppRoleName), Severity = "Informational", AffectedService = AppRoleName, Detail = strcat(OperationName, " = HTTP ", tostring(ResultCode)), _ResourceId;
let exc =
AppExceptions
| where TimeGenerated > ago(timeWindow)
| where isempty(resourceId) or _ResourceId == resourceId
| where AppRoleName has env
| project TimeGenerated, AlertTitle = strcat("AppInsight Error - ", AppRoleName), Severity = "Informational", AffectedService = AppRoleName, Detail = strcat(OperationName , Detail = InnermostMessage), _ResourceId;
union req, exc
|summarize arg_max(TimeGenerated, AlertTitle, Severity) by bin(TimeGenerated, 1m), AffectedService, Detail, _ResourceId
| project TimeGenerated, AlertTitle, Severity, Detail, AffectedService, _ResourceId
| order by TimeGenerated

''', environment)

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
    resourceIdColumn: '_ResourceId'
    tags: tags
  }
}

@description('Scheduled query rule resource ID')
output scheduledQueryRuleId string = resourceId('Microsoft.Insights/scheduledQueryRules', ruleName)

@description('Scheduled query rule name')
output scheduledQueryRuleName string = ruleName


