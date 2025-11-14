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
param logAnalyticsWorkspaceId string

@description('Enable routing to the webhook action group for app alerts')
param enableWebhookAg bool

@description('Enable routing to the Logic App action group for app alerts')
param enableLogicAppAg bool

param webhookUrl string

@description('Logic App resource IDs to receive alerts')
param logicAppResourceIds array = []

// Per-alert toggles and routing for application alerts
@description('Enable App Service Down alert')
param enableAppServiceDownAlert bool = true
@description('Route App Service Down to webhook')
param routeAppServiceDownToWebhook bool = true
@description('Route App Service Down to Logic App')
param routeAppServiceDownToLogicApp bool = true

@description('Enable Identity Provider alert')
param enableIdentityProviderAlert bool = true
@description('Route Identity Provider alert to webhook')
param routeIdentityProviderFailuresToWebhook bool = true
@description('Route Identity Provider alert to Logic App')
param routeIdentityProviderFailuresToLogicApp bool = true

@description('Enable Database Connection Failures alert')
param enableDbConnectionFailuresAlert bool = true
@description('Route Database Connection Failures to webhook')
param routeDbConnectionFailuresToWebhook bool = true
@description('Route Database Connection Failures to Logic App')
param routeDbConnectionFailuresToLogicApp bool = true

@description('Enable App Service High Error Rate alert')
param enableHighErrorRateAlert bool = true
@description('Route App Service High Error Rate to webhook')
param routeHighErrorRateAlertToWebhook bool = true
@description('Route App Service High Error Rate to Logic App')
param routeHighErrorRateAlertToLogicApp bool = true

@description('Enable Container Apps Failures alert')
param enableContainerAppsFailuresAlert bool = true
@description('Route Container Apps Failures to webhook')
param routeContainerAppsFailuresToWebhook bool = true
@description('Route Container Apps Failures to Logic App')
param routeContainerAppsFailuresToLogicApp bool = true

@description('Enable Function App Failures alert')
param enableFuncAppFailuresAlert bool = true
@description('Route Function App Failures to webhook')
param routeFuncAppFailuresToWebhook bool = true
@description('Route Function App Failures to Logic App')
param routeFuncAppFailuresToLogicApp bool = true

@description('Enable combined All Errors alert (Exceptions + Request failures)')
param enableAllErrorsAlert bool
@description('Route All Errors alert to Logic App')
param routeAllErrorsToLogicApp bool = true

@description('All Errors alert severity (0=Critical,1=Error,2=Warning,3=Info,4=Verbose)')
@allowed([0,1,2,3,4])
param allErrorsSeverity int = 1
@description('All Errors alert frequency/window in minutes')
param allErrorsEvaluationFrequencyInMinutes int = 5
param allErrorsWindowSizeInMinutes int = 5
@description('All Errors alert mute duration in minutes')
param allErrorsMuteInMinutes int = 60

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
  logicapp: '${namingPrefix}-app-alerts-logicapp'
}

var allErrorsRuleName = '${namingPrefix}-all-errors'

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

@description('Webhook recipients for app alerts')
var appWebhookRecipients = [
  {
    name: 'App Alerts Webhook'
    serviceUri: webhookUrl
    useCommonAlertSchema: true
  }
]

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

// Create Logic App to send alerts to Teams
module teamsLogicApp 'modules/logic-app-teams-alerts.bicep' = {
  name: 'deploy-teams-logicapp'
  scope: monitoringResourceGroup
  params: {
    environment: environment
    organizationPrefix: organizationPrefix
    tags: tags
  }
}

// App Alerts - Action Groups (Webhook + Logic App)
module appActionGroups 'modules/app-action-groups.bicep' = {
  name: 'deploy-app-action-groups'
  scope: monitoringResourceGroup
  params: {
    actionGroupNames: appActionGroupNames
    webhookRecipients: appWebhookRecipients
    logicAppResourceIds: empty(logicAppResourceIds) ? [teamsLogicApp.outputs.logicAppId] : logicAppResourceIds
    enableWebhookAg: enableWebhookAg
    enableLogicAppAg: enableLogicAppAg
    environment: environment
    tags: tags
  }
}

// App Alerts - Scheduled Query Rules
module appScheduledQueryAlerts 'modules/app-scheduled-query-alerts.bicep' = if (!empty(logAnalyticsWorkspaceId)) {
  name: 'deploy-app-scheduled-query-alerts'
  scope: monitoringResourceGroup
  params: {
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    environment: environment
    namingPrefix: namingPrefix
    actionGroups: appActionGroups.outputs.actionGroups
    enableWebhookAg: enableWebhookAg
    enableLogicAppAg: enableLogicAppAg
    tags: tags
    enableAppServiceDownAlert: enableAppServiceDownAlert
    sendAppServiceDownToWebhook: routeAppServiceDownToWebhook
    sendAppServiceDownToLogicApp: routeAppServiceDownToLogicApp
    enableIdentityProviderAlert: enableIdentityProviderAlert
    sendIdentityProviderFailuresToWebhook: routeIdentityProviderFailuresToWebhook
    sendIdentityProviderFailuresToLogicApp: routeIdentityProviderFailuresToLogicApp
    enableDbConnectionFailuresAlert: enableDbConnectionFailuresAlert
    sendDbConnectionFailuresToWebhook: routeDbConnectionFailuresToWebhook
    sendDbConnectionFailuresToLogicApp: routeDbConnectionFailuresToLogicApp
    enableHighErrorRateAlert: enableHighErrorRateAlert
    sendHighErrorRateAlertToWebhook: routeHighErrorRateAlertToWebhook
    sendHighErrorRateAlertToLogicApp: routeHighErrorRateAlertToLogicApp
    enableContainerAppsFailuresAlert: enableContainerAppsFailuresAlert
    sendContainerAppsFailuresToWebhook: routeContainerAppsFailuresToWebhook
    sendContainerAppsFailuresToLogicApp: routeContainerAppsFailuresToLogicApp
    enableFuncAppFailuresAlert: enableFuncAppFailuresAlert
    sendFuncAppFailuresToWebhook: routeFuncAppFailuresToWebhook
    sendFuncAppFailuresToLogicApp: routeFuncAppFailuresToLogicApp
  }
}

// All Errors - Combined Exceptions and Request Failures
module allErrorsAlert 'modules/app-all-errors-alert.bicep' = if (enableAllErrorsAlert && !empty(logAnalyticsWorkspaceId)) {
  name: 'deploy-app-all-errors-alert'
  scope: monitoringResourceGroup
  params: {
    ruleName: allErrorsRuleName
    enabled: true
    severity: allErrorsSeverity
    workspaceId: logAnalyticsWorkspaceId
    environment: environment
    actionGroupIds: concat(
      enableLogicAppAg && routeAllErrorsToLogicApp && contains(appActionGroups.outputs.actionGroups, 'logicapp') && !empty(appActionGroups.outputs.actionGroups.logicapp) ? [appActionGroups.outputs.actionGroups.logicapp.id] : []
    )
    evaluationFrequencyInMinutes: allErrorsEvaluationFrequencyInMinutes
    windowSizeInMinutes: allErrorsWindowSizeInMinutes
    muteActionsDurationInMinutes: allErrorsMuteInMinutes
    tags: tags
  }
}

// ------------------
// OUTPUTS
// ------------------

@description('Action group resource IDs')
output actionGroupIds object = actionGroups.outputs.actionGroups

@description('Alert rule resource IDs')
output alertRuleIds object = alertRules.outputs.alertRuleIds


