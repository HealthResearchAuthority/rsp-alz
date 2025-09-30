targetScope = 'subscription'

metadata name = 'ALZ Bicep - Monitoring Alerts'
metadata description = 'Module used to deploy Azure Monitor Alert Rules for Security, Policy, and Administrative operations'

// ------------------
// PARAMETERS
// ------------------

@description('Location for resources')
param location string = deployment().location

@description('Resource group name for monitoring resources')
param monitoringResourceGroupName string = 'rg-monitoring-alerts'


@description('Environment name (e.g., dev, prod)')
param environment string

@description('Organization prefix for naming')
param organizationPrefix string = 'hra'

@description('Email recipients for security alerts')
param securityEmailRecipients array = []

@description('Email recipients for policy alerts')
param policyEmailRecipients array = []

@description('Email recipients for administrative alerts')
param adminEmailRecipients array = []

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

var namingPrefix = '${organizationPrefix}-${environment}'
var actionGroupNames = {
  security: '${namingPrefix}-security-alerts'
  policy: '${namingPrefix}-policy-alerts'
  admin: '${namingPrefix}-admin-alerts'
}

var alertRuleNames = {
  security: {
    securityOperations: '${namingPrefix}-security-operations'
  }
  policy: {
    policyOperations: '${namingPrefix}-policy-operations'
  }
  admin: {
    adminOperations: '${namingPrefix}-admin-operations'
  }
}

// ------------------
// RESOURCES
// ------------------

// Resource Group for monitoring resources
resource monitoringResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: monitoringResourceGroupName
  location: location
  tags: tags
}

// Action Groups Module
module actionGroups 'modules/action-groups.bicep' = {
  name: 'deploy-action-groups'
  scope: monitoringResourceGroup
  params: {
    actionGroupNames: actionGroupNames
    securityEmailRecipients: securityEmailRecipients
    policyEmailRecipients: policyEmailRecipients
    adminEmailRecipients: adminEmailRecipients
    environment: environment
    tags: tags
  }
}

// Alert Rules Module
module alertRules 'modules/alert-rules.bicep' = {
  name: 'deploy-alert-rules'
  scope: monitoringResourceGroup
  params: {
    alertRuleNames: alertRuleNames
    actionGroups: actionGroups.outputs.actionGroups
    subscriptionId: subscription().subscriptionId
    enableSecurityAlerts: enableSecurityAlerts
    enablePolicyAlerts: enablePolicyAlerts
    enableAdminAlerts: enableAdminAlerts
    alertSeverityLevels: alertSeverityLevels
    tags: tags
  }
}

// ------------------
// OUTPUTS
// ------------------

@description('Resource group name for monitoring resources')
output monitoringResourceGroupName string = monitoringResourceGroup.name

@description('Action group resource IDs')
output actionGroupIds object = actionGroups.outputs.actionGroups

@description('Alert rule resource IDs')
output alertRuleIds object = alertRules.outputs.alertRuleIds
