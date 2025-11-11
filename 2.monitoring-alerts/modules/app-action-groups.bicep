targetScope = 'resourceGroup'

// ------------------
// PARAMETERS
// ------------------

@description('Names for application alert action groups')
param actionGroupNames object

@description('Recipients for the webhook action group')
param webhookRecipients array = []

@description('Logic App resource IDs to receive alerts (callback URL will be derived)')
param logicAppResourceIds array = []

@description('Enable or disable the webhook action group')
param enableWebhookAg bool = true

@description('Enable or disable the Logic App action group')
param enableLogicAppAg bool = true

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
var webhookAgName = actionGroupNames.webhook
var logicAppAgName = actionGroupNames.logicapp

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
    enabled: enableWebhookAg
    tags: defaultTags
  }
}

// Logic App Action Group (derive callbackUrl from resourceId)
module logicAppActionGroup '../../shared/bicep/monitoring/action-group.bicep' = if (enableLogicAppAg && !empty(logicAppResourceIds)) {
  name: 'deploy-app-logicapp-action-group'
  params: {
    actionGroupName: logicAppAgName
    shortName: 'AppLogic'
    logicAppRecipients: [for (rid, i) in logicAppResourceIds: {
      name: 'LogicApp_${i}'
      resourceId: rid
      callbackUrl: listCallbackUrl('${rid}/triggers/manual', '2016-06-01').value
      useCommonAlertSchema: true
    }]
    enabled: enableLogicAppAg
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
  logicapp: enableLogicAppAg && !empty(logicAppResourceIds) ? {
    id: resourceId('Microsoft.Insights/actionGroups', logicAppAgName)
    name: logicAppAgName
  } : {}
}
