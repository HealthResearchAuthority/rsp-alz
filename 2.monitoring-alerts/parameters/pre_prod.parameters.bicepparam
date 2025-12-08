using '../main.bicep'

// ------------------
// GENERAL PARAMETERS
// ------------------

param location = 'uksouth'
param environment = 'pre_prod'
param organizationPrefix = 'hra'
param monitoringResourceGroupName = 'rg-hra-monitoring-pre_prod'


// ------------------
// ALERT CONFIGURATION
// ------------------

param enableSecurityAlerts = true
param enablePolicyAlerts = true
param enableAdminAlerts = true

// Only alert on Critical (0), Error (1), and Warning (2) levels
param alertSeverityLevels = [0, 1, 2]

// ------------------
// EMAIL RECIPIENTS
// ------------------

param securityEmailRecipients = [
  {
    name: 'Security Team'
    address: 'azure.security@hra.nhs.uk'
    useCommonAlertSchema: true
  }
]

param policyEmailRecipients = [
  {
    name: 'Governance Team'
    address: 'azure.security@hra.nhs.uk'
    useCommonAlertSchema: true
  }
]

param adminEmailRecipients = [
  {
    name: 'Platform Team'
    address: 'azure.security@hra.nhs.uk'
    useCommonAlertSchema: true
  }
]

param enableWebhookAg = false
param enableLogicAppAg = false
param webhookUrl = ''
param logAnalyticsWorkspaceId = ''
param enableAllErrorsAlert = false

param teamsGroupId = ''
param teamsChannelId = ''
param teamsApiConnectionId = ''
param teamsConnectionId = ''

// ------------------
// TAGS
// ------------------

param tags = {
  Environment: 'Pre-Production'
  Purpose: 'Monitoring and Alerting'
}
