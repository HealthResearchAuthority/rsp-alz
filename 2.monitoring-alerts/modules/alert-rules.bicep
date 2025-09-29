targetScope = 'resourceGroup'

metadata name = 'ALZ Bicep - Alert Rules Deployment'
metadata description = 'Module used to deploy Activity Log Alert Rules for Security, Policy, and Administrative operations'

// ------------------
// PARAMETERS
// ------------------

@description('Alert rule names for different categories')
param alertRuleNames object

@description('Action groups for different alert categories')
param actionGroups object

@description('Subscription ID to monitor')
param subscriptionId string

@description('Enable security operation alerts')
param enableSecurityAlerts bool = true

@description('Enable policy operation alerts')
param enablePolicyAlerts bool = true

@description('Enable administrative operation alerts')
param enableAdminAlerts bool = true

@description('Alert severity levels to include (Critical=0, Error=1, Warning=2)')
param alertSeverityLevels array = [0, 1, 2]

@description('Tags to apply to all resources')
param tags object = {}

// ------------------
// VARIABLES
// ------------------

var subscriptionScope = '/subscriptions/${subscriptionId}'
var defaultTags = union(tags, {
  Purpose: 'Activity Log Monitoring'
})

// ------------------
// SECURITY ALERT RULES
// ------------------

// Security operations alert
module securityOperationsAlerts '../../shared/bicep/monitoring/activity-log-alert.bicep' = if (enableSecurityAlerts && contains(actionGroups, 'security') && !empty(actionGroups.security)) {
  name: 'deploy-security-operations-alerts'
  params: {
    alertRuleName: alertRuleNames.security.securityOperations
    alertDescription: 'Alert on security policy and solution operations'
    enabled: true
    actionGroupIds: [actionGroups.security.id]
    scopes: [subscriptionScope]
    category: 'Administrative'
    operationNames: [
      'Microsoft.Security/policies/write'
      'Microsoft.Security/securitySolutions/write'
      'Microsoft.Security/securitySolutions/delete'
    ]
    level: contains(alertSeverityLevels, 0) ? 'Critical' : contains(alertSeverityLevels, 1) ? 'Error' : 'Warning'
    tags: defaultTags
  }
}

// ------------------
// POLICY ALERT RULES
// ------------------

// Policy assignment operations alert
module policyOperationsAlerts '../../shared/bicep/monitoring/activity-log-alert.bicep' = if (enablePolicyAlerts && contains(actionGroups, 'policy') && !empty(actionGroups.policy)) {
  name: 'deploy-policy-operations-alerts'
  params: {
    alertRuleName: alertRuleNames.policy.policyOperations
    alertDescription: 'Alert on policy assignment operations'
    enabled: true
    actionGroupIds: [actionGroups.policy.id]
    scopes: [subscriptionScope]
    category: 'Administrative'
    operationNames: [
      'Microsoft.Authorization/policyAssignments/write'
      'Microsoft.Authorization/policyAssignments/delete'
    ]
    tags: defaultTags
  }
}

// ------------------
// ADMINISTRATIVE ALERT RULES
// ------------------

// Administrative operations alert
module adminOperationsAlerts '../../shared/bicep/monitoring/activity-log-alert.bicep' = if (enableAdminAlerts && contains(actionGroups, 'admin') && !empty(actionGroups.admin)) {
  name: 'deploy-admin-operations-alerts'
  params: {
    alertRuleName: alertRuleNames.admin.adminOperations
    alertDescription: 'Alert on SQL firewall rules and NSG operations'
    enabled: true
    actionGroupIds: [actionGroups.admin.id]
    scopes: [subscriptionScope]
    category: 'Administrative'
    operationNames: [
      'Microsoft.Sql/servers/firewallRules/write'
      'Microsoft.Sql/servers/firewallRules/delete'
      'Microsoft.Network/networkSecurityGroups/write'
      'Microsoft.Network/networkSecurityGroups/delete'
      'Microsoft.ClassicNetwork/networkSecurityGroups/write'
      'Microsoft.ClassicNetwork/networkSecurityGroups/delete'
      'Microsoft.Network/networkSecurityGroups/securityRules/write'
      'Microsoft.Network/networkSecurityGroups/securityRules/delete'
      'Microsoft.ClassicNetwork/networkSecurityGroups/securityRules/write'
      'Microsoft.ClassicNetwork/networkSecurityGroups/securityRules/delete'
    ]
    tags: defaultTags
  }
}

// ------------------
// OUTPUTS
// ------------------

@description('Alert rule resource IDs')
output alertRuleIds object = {
  security: {
    securityOperations: enableSecurityAlerts && contains(actionGroups, 'security') && !empty(actionGroups.security) ? securityOperationsAlerts.outputs.activityLogAlertId : ''
  }
  policy: {
    policyOperations: enablePolicyAlerts && contains(actionGroups, 'policy') && !empty(actionGroups.policy) ? policyOperationsAlerts.outputs.activityLogAlertId : ''
  }
  admin: {
    adminOperations: enableAdminAlerts && contains(actionGroups, 'admin') && !empty(actionGroups.admin) ? adminOperationsAlerts.outputs.activityLogAlertId : ''
  }
}
