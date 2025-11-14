targetScope = 'resourceGroup'

metadata name = 'ALZ Bicep - Scheduled Query Rule'
metadata description = 'Module used to create Scheduled Query Rules for Azure Monitor'

// ------------------
// PARAMETERS
// ------------------

@description('Name of the scheduled query rule')
param ruleName string

@description('Display name of the scheduled query rule')
param displayName string

@description('Kind of the scheduled query rule')
param kind string = 'LogAlert'

@description('Description of the scheduled query rule')
param ruleDescription string

@description('Enable or disable the scheduled query rule')
param enabled bool

@description('Severity of the alert (0=Critical, 1=Error, 2=Warning, 3=Informational, 4=Verbose)')
@allowed([0, 1, 2, 3, 4])
param severity int = 2

@description('Array of action group resource IDs to notify')
param actionGroupIds array

@description('KQL query to execute')
param query string

@description('Resource ID column for the alert')
param resourceIdColumn string = ''

@description('Log Analytics workspace resource IDs to query')
param dataSourceIds string

@description('How often the query is evaluated (in minutes)')
param evaluationFrequencyInMinutes int = 5

@description('Time window for the query (in minutes)')
param windowSizeInMinutes int = 15

@description('Threshold operator for the alert')
@allowed(['GreaterThan', 'GreaterThanOrEqual', 'LessThan', 'LessThanOrEqual', 'Equal'])
param operator string = 'GreaterThan'

@description('Metric measure column for the alert')
param metricMeasureColumn string = ''

@description('Threshold value for the alert')
param threshold int = 0

@description('Number of violations to trigger alert')
param numberOfEvaluationPeriods int = 1

@description('Minimum number of violations within evaluation periods to trigger alert')
param minFailingPeriodsToAlert int = 1

@description('Auto-mitigate the alert or not')
param autoMitigate bool = false

@description('Mute notifications for this many minutes after an alert fires (throttling)')
param muteActionsDurationInMinutes int = 5

@description('Aggregation type. Relevant and required only for rules of the kind LogAlert.')
@allowed(['Average', 'Count', 'Total', 'Maximum', 'Minimum'])
param timeAggregation string = 'Count'

@description('Check workspace linked storage account for query')
param checkWorkspaceAlertsStorageConfigured bool = false

@description('Skip query validation')
param skipQueryValidation bool = false

@description('Tags to apply to the scheduled query rule')
param tags object = {}

@description('Location for the scheduled query rule')
param location string = resourceGroup().location

var dimensions = [
  {
    name: 'AlertTitle'
    operator: 'Include'
    values: [
      '*'
    ]
  }
  {
    name: 'Severity'
    operator: 'Include'
    values: [
      '*'
    ]
  }
  {
    name: 'Detail'
    operator: 'Include'
    values: [
      '*'
    ]
  }
  {
    name: 'AffectedService'
    operator: 'Include'
    values: [
      '*'
    ]
  }
]

// ------------------
// RESOURCES
// ------------------

resource scheduledQueryRule 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
  name: ruleName
  kind: kind
  location: location
  tags: tags
  properties: {
    displayName: displayName
    description: ruleDescription
    enabled: enabled
    severity: severity
    evaluationFrequency: 'PT${evaluationFrequencyInMinutes}M'
    windowSize: 'PT${windowSizeInMinutes}M'
    scopes: [dataSourceIds]
    criteria: {
      allOf: [
        {
          query: query
          dimensions: dimensions
          resourceIdColumn: resourceIdColumn
          timeAggregation: timeAggregation
          metricMeasureColumn: metricMeasureColumn
          operator: operator
          threshold: threshold
          failingPeriods: {
            numberOfEvaluationPeriods: numberOfEvaluationPeriods
            minFailingPeriodsToAlert: minFailingPeriodsToAlert
          }
        }
      ]
    }
    actions: {
      actionGroups: actionGroupIds
    }
    autoMitigate: autoMitigate
    muteActionsDuration: 'PT${muteActionsDurationInMinutes}M'
    checkWorkspaceAlertsStorageConfigured: checkWorkspaceAlertsStorageConfigured
    skipQueryValidation: skipQueryValidation
  }
}

// ------------------
// OUTPUTS
// ------------------

@description('The resource ID of the Scheduled Query Rule')
output scheduledQueryRuleId string = scheduledQueryRule.id

@description('The name of the Scheduled Query Rule')
output scheduledQueryRuleName string = scheduledQueryRule.name
