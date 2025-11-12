using '../main.bicep'

// ------------------
// GENERAL PARAMETERS
// ------------------

param location = 'uksouth'
param environment = 'manualtest'
param organizationPrefix = 'hra'
param monitoringResourceGroupName = 'rg-hra-monitoring-manualtest'


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

param enableWebhookAg = true
param enableLogicAppAg = true
param webhookUrl = ''
param logAnalyticsWorkspaceId = ''
param enableAllErrorsAlert = true

// ------------------
// TAGS
// ------------------

param tags = {
  Environment: 'Manual Test'
  // Owner: 'Platform Team'
  // CostCenter: 'IT Operations'
  // Project: 'Azure Landing Zone'
  Purpose: 'Monitoring and Alerting'
}
