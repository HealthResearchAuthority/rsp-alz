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

@description('Resource IDs of Log Analytics workspaces for app alerts')
param logAnalyticsWorkspaceIds array = []

@description('Enable routing to the webhook action group for app alerts')
param enableWebhookAg bool = true

@description('Enable routing to the Teams action group for app alerts')
param enableTeamsAg bool = true

@description('Webhook recipients for app alerts (placeholder by default)')
param appWebhookRecipients array = [
  {
    name: 'App Alerts Webhook'
    serviceUri: 'https://example.com/webhook'
    useCommonAlertSchema: true
  }
]

@description('Teams channel email recipients for app alerts (placeholder by default)')
param appTeamsEmailRecipients array = [
  {
    name: 'App Alerts Teams'
    address: 'app-alerts@example.onmicrosoft.com'
    useCommonAlertSchema: true
  }
]

// Per-alert toggles and routing for application alerts
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

var namingPrefix = '${organizationPrefix}-${environment}'
var actionGroupNames = {
  security: '${namingPrefix}-security-alerts'
  policy: '${namingPrefix}-policy-alerts'
  admin: '${namingPrefix}-admin-alerts'
}

var appActionGroupNames = {
  webhook: '${namingPrefix}-app-alerts-webhook'
  teams: '${namingPrefix}-app-alerts-teams'
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

// App Alerts - Action Groups (Webhook + Teams)
module appActionGroups 'modules/app-action-groups.bicep' = {
  name: 'deploy-app-action-groups'
  scope: monitoringResourceGroup
  params: {
    actionGroupNames: appActionGroupNames
    webhookRecipients: appWebhookRecipients
    teamsEmailRecipients: appTeamsEmailRecipients
    enableWebhookAg: enableWebhookAg
    enableTeamsAg: enableTeamsAg
    environment: environment
    tags: tags
  }
}

// App Alerts - Scheduled Query Rules
module appScheduledQueryAlerts 'modules/app-scheduled-query-alerts.bicep' = if (!empty(logAnalyticsWorkspaceIds)) {
  name: 'deploy-app-scheduled-query-alerts'
  scope: monitoringResourceGroup
  params: {
    workspaceIds: logAnalyticsWorkspaceIds
    environment: environment
    namingPrefix: namingPrefix
    actionGroups: appActionGroups.outputs.actionGroups
    enableWebhookAg: enableWebhookAg
    enableTeamsAg: enableTeamsAg
    tags: tags
    enableAppServiceDownAlert: enableAppServiceDownAlert
    routeAppServiceDownToWebhook: routeAppServiceDownToWebhook
    routeAppServiceDownToTeams: routeAppServiceDownToTeams
    enableIdentityProviderAlert: enableIdentityProviderAlert
    routeIdentityProviderFailuresToWebhook: routeIdentityProviderFailuresToWebhook
    routeIdentityProviderFailuresToTeams: routeIdentityProviderFailuresToTeams
    enableDbConnectionFailuresAlert: enableDbConnectionFailuresAlert
    routeDbConnectionFailuresToWebhook: routeDbConnectionFailuresToWebhook
    routeDbConnectionFailuresToTeams: routeDbConnectionFailuresToTeams
    enableHighErrorRateAlert: enableHighErrorRateAlert
    routeHighErrorRateAlertToWebhook: routeHighErrorRateAlertToWebhook
    routeHighErrorRateAlertToTeams: routeHighErrorRateAlertToTeams
    enableContainerAppsFailuresAlert: enableContainerAppsFailuresAlert
    routeContainerAppsFailuresToWebhook: routeContainerAppsFailuresToWebhook
    routeContainerAppsFailuresToTeams: routeContainerAppsFailuresToTeams
    enableFuncAppFailuresAlert: enableFuncAppFailuresAlert
    routeFuncAppFailuresToWebhook: routeFuncAppFailuresToWebhook
    routeFuncAppFailuresToTeams: routeFuncAppFailuresToTeams
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
