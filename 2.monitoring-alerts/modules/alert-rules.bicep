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
    resourceProvider: 'Microsoft.Security'
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
    resourceProvider: 'Microsoft.Authorization'
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

// SQL firewall operations alert
module sqlFirewallAlerts '../../shared/bicep/monitoring/activity-log-alert.bicep' = if (enableAdminAlerts && contains(actionGroups, 'admin') && !empty(actionGroups.admin)) {
  name: 'deploy-sql-firewall-alerts'
  params: {
    alertRuleName: '${alertRuleNames.admin.adminOperations}-sql'
    alertDescription: 'Alert on SQL server firewall rule operations'
    enabled: true
    actionGroupIds: [actionGroups.admin.id]
    scopes: [subscriptionScope]
    category: 'Administrative'
    resourceProvider: 'Microsoft.Sql'
    operationNames: [
      'Microsoft.Sql/servers/firewallRules/write'
      'Microsoft.Sql/servers/firewallRules/delete'
    ]
    tags: defaultTags
  }
}

// Network Security Group operations alert
module nsgOperationsAlerts '../../shared/bicep/monitoring/activity-log-alert.bicep' = if (enableAdminAlerts && contains(actionGroups, 'admin') && !empty(actionGroups.admin)) {
  name: 'deploy-nsg-operations-alerts'
  params: {
    alertRuleName: '${alertRuleNames.admin.adminOperations}-nsg'
    alertDescription: 'Alert on Network Security Group operations'
    enabled: true
    actionGroupIds: [actionGroups.admin.id]
    scopes: [subscriptionScope]
    category: 'Administrative'
    resourceProvider: 'Microsoft.Network'
    operationNames: [
      'Microsoft.Network/networkSecurityGroups/write'
      'Microsoft.Network/networkSecurityGroups/delete'
      'Microsoft.Network/networkSecurityGroups/securityRules/write'
      'Microsoft.Network/networkSecurityGroups/securityRules/delete'
    ]
    tags: defaultTags
  }
}

// Classic Network Security Group operations alert
module classicNsgOperationsAlerts '../../shared/bicep/monitoring/activity-log-alert.bicep' = if (enableAdminAlerts && contains(actionGroups, 'admin') && !empty(actionGroups.admin)) {
  name: 'deploy-classic-nsg-operations-alerts'
  params: {
    alertRuleName: '${alertRuleNames.admin.adminOperations}-classic-nsg'
    alertDescription: 'Alert on Classic Network Security Group operations'
    enabled: true
    actionGroupIds: [actionGroups.admin.id]
    scopes: [subscriptionScope]
    category: 'Administrative'
    resourceProvider: 'Microsoft.ClassicNetwork'
    operationNames: [
      'Microsoft.ClassicNetwork/networkSecurityGroups/write'
      'Microsoft.ClassicNetwork/networkSecurityGroups/delete'
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
    sqlFirewallOperations: enableAdminAlerts && contains(actionGroups, 'admin') && !empty(actionGroups.admin) ? sqlFirewallAlerts.outputs.activityLogAlertId : ''
    nsgOperations: enableAdminAlerts && contains(actionGroups, 'admin') && !empty(actionGroups.admin) ? nsgOperationsAlerts.outputs.activityLogAlertId : ''
    classicNsgOperations: enableAdminAlerts && contains(actionGroups, 'admin') && !empty(actionGroups.admin) ? classicNsgOperationsAlerts.outputs.activityLogAlertId : ''
  }
}
