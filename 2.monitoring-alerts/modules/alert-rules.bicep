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

// Microsoft Defender for Cloud alerts
module defenderAlerts '../../shared/bicep/monitoring/activity-log-alert.bicep' = if (enableSecurityAlerts && contains(actionGroups, 'security') && !empty(actionGroups.security)) {
  name: 'deploy-defender-alerts'
  params: {
    alertRuleName: alertRuleNames.security.defenderAlerts
    alertDescription: 'Alert when Microsoft Defender for Cloud generates security alerts'
    enabled: true
    actionGroupIds: [actionGroups.security.id]
    scopes: [subscriptionScope]
    category: 'Security'
    level: contains(alertSeverityLevels, 0) ? 'Critical' : contains(alertSeverityLevels, 1) ? 'Error' : 'Warning'
    tags: defaultTags
  }
}

// Key Vault access events
module keyVaultAccessAlerts '../../shared/bicep/monitoring/activity-log-alert.bicep' = if (enableSecurityAlerts && contains(actionGroups, 'security') && !empty(actionGroups.security)) {
  name: 'deploy-keyvault-access-alerts'
  params: {
    alertRuleName: alertRuleNames.security.keyVaultAccess
    alertDescription: 'Alert on Key Vault access and modification events'
    enabled: true
    actionGroupIds: [actionGroups.security.id]
    scopes: [subscriptionScope]
    category: 'Administrative'
    resourceProvider: 'Microsoft.KeyVault'
    operationName: 'Microsoft.KeyVault/vaults/write'
    tags: defaultTags
  }
}

// Storage account security events
// module storageSecurityAlerts '../../shared/bicep/monitoring/activity-log-alert.bicep' = if (enableSecurityAlerts && contains(actionGroups, 'security') && !empty(actionGroups.security)) {
//   name: 'deploy-storage-security-alerts'
//   params: {
//     alertRuleName: alertRuleNames.security.storageSecurityEvents
//     alertDescription: 'Alert on storage account security configuration changes'
//     enabled: true
//     actionGroupIds: [actionGroups.security.id]
//     scopes: [subscriptionScope]
//     category: 'Administrative'
//     resourceProvider: 'Microsoft.Storage'
//     operationName: 'Microsoft.Storage/storageAccounts/write'
//     tags: defaultTags
//   }
// }

// Network Security Group changes
// module nsgChangeAlerts '../../shared/bicep/monitoring/activity-log-alert.bicep' = if (enableSecurityAlerts && contains(actionGroups, 'security') && !empty(actionGroups.security)) {
//   name: 'deploy-nsg-change-alerts'
//   params: {
//     alertRuleName: alertRuleNames.security.nsgChanges
//     alertDescription: 'Alert on Network Security Group rule modifications'
//     enabled: true
//     actionGroupIds: [actionGroups.security.id]
//     scopes: [subscriptionScope]
//     category: 'Administrative'
//     resourceProvider: 'Microsoft.Network'
//     operationName: 'Microsoft.Network/networkSecurityGroups/write'
//     tags: defaultTags
//   }
// }

// ------------------
// POLICY ALERT RULES
// ------------------

// Policy assignment changes
module policyAssignmentAlerts '../../shared/bicep/monitoring/activity-log-alert.bicep' = if (enablePolicyAlerts && contains(actionGroups, 'policy') && !empty(actionGroups.policy)) {
  name: 'deploy-policy-assignment-alerts'
  params: {
    alertRuleName: alertRuleNames.policy.policyAssignmentChanges
    alertDescription: 'Alert on Azure Policy assignment modifications'
    enabled: true
    actionGroupIds: [actionGroups.policy.id]
    scopes: [subscriptionScope]
    category: 'Policy'
    operationName: 'Microsoft.Authorization/policyAssignments/write'
    tags: defaultTags
  }
}

// Policy compliance state changes
// module complianceStateAlerts '../../shared/bicep/monitoring/activity-log-alert.bicep' = if (enablePolicyAlerts && contains(actionGroups, 'policy') && !empty(actionGroups.policy)) {
//   name: 'deploy-compliance-state-alerts'
//   params: {
//     alertRuleName: alertRuleNames.policy.complianceStateChanges
//     alertDescription: 'Alert on policy compliance state changes'
//     enabled: true
//     actionGroupIds: [actionGroups.policy.id]
//     scopes: [subscriptionScope]
//     category: 'Policy'
//     tags: defaultTags
//   }
// }

// // Policy exemption activities
// module policyExemptionAlerts '../../shared/bicep/monitoring/activity-log-alert.bicep' = if (enablePolicyAlerts && contains(actionGroups, 'policy') && !empty(actionGroups.policy)) {
//   name: 'deploy-policy-exemption-alerts'
//   params: {
//     alertRuleName: alertRuleNames.policy.policyExemptions
//     alertDescription: 'Alert on policy exemption creation or modification'
//     enabled: true
//     actionGroupIds: [actionGroups.policy.id]
//     scopes: [subscriptionScope]
//     category: 'Administrative'
//     operationName: 'Microsoft.Authorization/policyExemptions/write'
//     tags: defaultTags
//   }
// }

// ------------------
// ADMINISTRATIVE ALERT RULES
// ------------------

// Resource group changes
module resourceGroupAlerts '../../shared/bicep/monitoring/activity-log-alert.bicep' = if (enableAdminAlerts && contains(actionGroups, 'admin') && !empty(actionGroups.admin)) {
  name: 'deploy-resource-group-alerts'
  params: {
    alertRuleName: alertRuleNames.admin.resourceGroupChanges
    alertDescription: 'Alert on resource group creation, modification, or deletion'
    enabled: true
    actionGroupIds: [actionGroups.admin.id]
    scopes: [subscriptionScope]
    category: 'Administrative'
    operationName: 'Microsoft.Resources/subscriptions/resourceGroups/write'
    tags: defaultTags
  }
}

// Role assignment changes
module roleAssignmentAlerts '../../shared/bicep/monitoring/activity-log-alert.bicep' = if (enableAdminAlerts && contains(actionGroups, 'admin') && !empty(actionGroups.admin)) {
  name: 'deploy-role-assignment-alerts'
  params: {
    alertRuleName: alertRuleNames.admin.roleAssignmentChanges
    alertDescription: 'Alert on RBAC role assignment modifications'
    enabled: true
    actionGroupIds: [actionGroups.admin.id]
    scopes: [subscriptionScope]
    category: 'Administrative'
    operationName: 'Microsoft.Authorization/roleAssignments/write'
    tags: defaultTags
  }
}

// Subscription configuration changes
module subscriptionConfigAlerts '../../shared/bicep/monitoring/activity-log-alert.bicep' = if (enableAdminAlerts && contains(actionGroups, 'admin') && !empty(actionGroups.admin)) {
  name: 'deploy-subscription-config-alerts'
  params: {
    alertRuleName: alertRuleNames.admin.subscriptionConfigChanges
    alertDescription: 'Alert on subscription-level configuration changes'
    enabled: true
    actionGroupIds: [actionGroups.admin.id]
    scopes: [subscriptionScope]
    category: 'Administrative'
    resourceProvider: 'Microsoft.Subscription'
    tags: defaultTags
  }
}

// ------------------
// OUTPUTS
// ------------------

@description('Alert rule resource IDs')
output alertRuleIds object = {
  security: {
    defenderAlerts: enableSecurityAlerts && contains(actionGroups, 'security') && !empty(actionGroups.security) ? defenderAlerts.outputs.activityLogAlertId : ''
    keyVaultAccess: enableSecurityAlerts && contains(actionGroups, 'security') && !empty(actionGroups.security) ? keyVaultAccessAlerts.outputs.activityLogAlertId : ''
    // storageSecurityEvents: enableSecurityAlerts && contains(actionGroups, 'security') && !empty(actionGroups.security) ? storageSecurityAlerts.outputs.activityLogAlertId : ''
    // nsgChanges: enableSecurityAlerts && contains(actionGroups, 'security') && !empty(actionGroups.security) ? nsgChangeAlerts.outputs.activityLogAlertId : ''
  }
  policy: {
    policyAssignmentChanges: enablePolicyAlerts && contains(actionGroups, 'policy') && !empty(actionGroups.policy) ? policyAssignmentAlerts.outputs.activityLogAlertId : ''
    // complianceStateChanges: enablePolicyAlerts && contains(actionGroups, 'policy') && !empty(actionGroups.policy) ? complianceStateAlerts.outputs.activityLogAlertId : ''
    // policyExemptions: enablePolicyAlerts && contains(actionGroups, 'policy') && !empty(actionGroups.policy) ? policyExemptionAlerts.outputs.activityLogAlertId : ''
  }
  admin: {
    resourceGroupChanges: enableAdminAlerts && contains(actionGroups, 'admin') && !empty(actionGroups.admin) ? resourceGroupAlerts.outputs.activityLogAlertId : ''
    roleAssignmentChanges: enableAdminAlerts && contains(actionGroups, 'admin') && !empty(actionGroups.admin) ? roleAssignmentAlerts.outputs.activityLogAlertId : ''
    subscriptionConfigChanges: enableAdminAlerts && contains(actionGroups, 'admin') && !empty(actionGroups.admin) ? subscriptionConfigAlerts.outputs.activityLogAlertId : ''
  }
}
