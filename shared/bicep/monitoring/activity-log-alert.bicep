targetScope = 'resourceGroup'

metadata name = 'ALZ Bicep - Activity Log Alert Rule'
metadata description = 'Module used to create Activity Log Alert Rules for Azure Monitor'

// ------------------
// PARAMETERS
// ------------------

@description('Name of the alert rule')
param alertRuleName string


@description('Description of the alert rule')
param alertDescription string

@description('Enable or disable the alert rule')
param enabled bool = true


@description('Array of action group resource IDs to notify')
param actionGroupIds array

@description('Scope for the alert rule (subscription, resource group, or resource)')
param scopes array

@description('Activity log event category')
@allowed([
  'Administrative'
  'Security' 
  'Policy'
  'Alert'
  'Autoscale'
  'Recommendation'
  'ResourceHealth'
  'ServiceHealth'
])
param category string

@description('Operation name for the alert (e.g., Microsoft.Storage/storageAccounts/write)')
param operationName string = ''

@description('Resource type for the alert')
param resourceType string = ''

@description('Resource group name for filtering')
param resourceGroupName string = ''

@description('Resource name for filtering')
param resourceName string = ''

@description('Status of the operation')
@allowed(['Started', 'Succeeded', 'Failed', ''])
param status string = ''

@description('Sub status of the operation')
param subStatus string = ''

@description('Resource provider for filtering')
param resourceProvider string = ''

@description('Level of the event')
@allowed(['Critical', 'Error', 'Warning', 'Informational', 'Verbose', ''])
param level string = ''

@description('Tags to apply to the alert rule')
param tags object = {}

@description('Location for the alert rule')
param location string = 'global'

// ------------------
// VARIABLES
// ------------------

var actionGroups = [for actionGroupId in actionGroupIds: {
  actionGroupId: actionGroupId
  webhookProperties: {}
}]

// Build condition array based on provided parameters
var baseConditions = [
  {
    field: 'category'
    equals: category
  }
]

var operationCondition = !empty(operationName) ? [{
  field: 'operationName'
  equals: operationName
}] : []

var resourceTypeCondition = !empty(resourceType) ? [{
  field: 'resourceType'
  equals: resourceType
}] : []

var resourceGroupCondition = !empty(resourceGroupName) ? [{
  field: 'resourceGroup'
  equals: resourceGroupName
}] : []

var resourceNameCondition = !empty(resourceName) ? [{
  field: 'resourceId'
  contains: resourceName
}] : []

var statusCondition = !empty(status) ? [{
  field: 'status'
  equals: status
}] : []

var subStatusCondition = !empty(subStatus) ? [{
  field: 'subStatus'
  equals: subStatus
}] : []

var resourceProviderCondition = !empty(resourceProvider) ? [{
  field: 'resourceProvider'
  equals: resourceProvider
}] : []

var levelCondition = !empty(level) ? [{
  field: 'level'
  equals: level
}] : []

var allConditions = concat(
  baseConditions,
  operationCondition,
  resourceTypeCondition,
  resourceGroupCondition,
  resourceNameCondition,
  statusCondition,
  subStatusCondition,
  resourceProviderCondition,
  levelCondition
)

// ------------------
// RESOURCES
// ------------------

resource activityLogAlert 'Microsoft.Insights/activityLogAlerts@2020-10-01' = {
  name: alertRuleName
  location: location
  tags: tags
  properties: {
    enabled: enabled
    scopes: scopes
    condition: {
      allOf: allConditions
    }
    actions: {
      actionGroups: actionGroups
    }
    description: alertDescription
  }
}

// ------------------
// OUTPUTS
// ------------------

@description('The resource ID of the Activity Log Alert')
output activityLogAlertId string = activityLogAlert.id

@description('The name of the Activity Log Alert')
output activityLogAlertName string = activityLogAlert.name
