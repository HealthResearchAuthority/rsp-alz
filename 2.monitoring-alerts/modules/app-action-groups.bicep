targetScope = 'resourceGroup'

metadata name = 'App Alerts - Action Groups'
metadata description = 'Deploys Action Groups for application alerts: Webhook and Teams Email'

// ------------------
// PARAMETERS
// ------------------

@description('Names for application alert action groups')
param actionGroupNames object

@description('Recipients for the webhook action group')
param webhookRecipients array = []

@description('Recipients for the Teams email action group')
param teamsEmailRecipients array = []

@description('Enable or disable the webhook action group')
param enableWebhookAg bool = true

@description('Enable or disable the Teams email action group')
param enableTeamsAg bool = true

@description('Environment name')
param environment string

@description('Tags to apply to all resources')
param tags object = {}

// ------------------
// VARIABLES
// ------------------

var defaultTags = union(tags, {
  Environment: environment
  Purpose: 'Application Alerts'
})

var deployWebhookActionGroup = enableWebhookAg && !empty(webhookRecipients)
var deployTeamsActionGroup = enableTeamsAg && !empty(teamsEmailRecipients)
var webhookAgName = actionGroupNames.webhook
var teamsAgName = actionGroupNames.teams

// ------------------
// RESOURCES
// ------------------

// Webhook Action Group
module webhookActionGroup '../../shared/bicep/monitoring/action-group.bicep' = if (deployWebhookActionGroup) {
  name: 'deploy-app-webhook-action-group'
  params: {
    actionGroupName: actionGroupNames.webhook
    shortName: 'AppWebhook'
    emailRecipients: []
    webhookRecipients: webhookRecipients
    enabled: true
    tags: defaultTags
  }
}

// Teams Email Action Group
module teamsActionGroup '../../shared/bicep/monitoring/action-group.bicep' = if (deployTeamsActionGroup) {
  name: 'deploy-app-teams-action-group'
  params: {
    actionGroupName: actionGroupNames.teams
    shortName: 'AppTeams'
    emailRecipients: teamsEmailRecipients
    enabled: true
    tags: defaultTags
  }
}

// ------------------
// OUTPUTS
// ------------------

@description('Action group IDs and names for application alerts')
output actionGroups object = {
  webhook: deployWebhookActionGroup ? {
    id: resourceId('Microsoft.Insights/actionGroups', webhookAgName)
    name: webhookAgName
  } : {}
  teams: deployTeamsActionGroup ? {
    id: resourceId('Microsoft.Insights/actionGroups', teamsAgName)
    name: teamsAgName
  } : {}
}


