targetScope = 'resourceGroup'

metadata name = 'ALZ Bicep - Action Group'
metadata description = 'Module used to create Action Groups for Azure Monitor Alerts'

// ------------------
// PARAMETERS
// ------------------

@description('Name of the Action Group')
param actionGroupName string


@description('Short name for the Action Group (max 12 characters)')
@maxLength(12)
param shortName string

@description('Email recipients for notifications')
param emailRecipients array = []

@description('SMS recipients for notifications')
param smsRecipients array = []

@description('Webhook recipients for notifications')
param webhookRecipients array = []

@description('Azure Function recipients for notifications')
param azureFunctionRecipients array = []

@description('Logic App recipients for notifications')
param logicAppRecipients array = []

@description('Enable or disable the Action Group')
param enabled bool = true

@description('Tags to apply to the Action Group')
param tags object = {}

@description('Location for the Action Group')
param location string = 'global'

// ------------------
// VARIABLES
// ------------------

var emailActions = [for (email, index) in emailRecipients: {
  name: 'Email_${index}_${replace(email.name, ' ', '_')}'
  emailAddress: email.address
  useCommonAlertSchema: email.?useCommonAlertSchema ?? true
}]

var smsActions = [for (sms, index) in smsRecipients: {
  name: 'SMS_${index}_${replace(sms.name, ' ', '_')}'
  countryCode: sms.countryCode
  phoneNumber: sms.phoneNumber
}]

var webhookActions = [for (webhook, index) in webhookRecipients: {
  name: 'Webhook_${index}_${replace(webhook.name, ' ', '_')}'
  serviceUri: webhook.serviceUri
  useCommonAlertSchema: webhook.?useCommonAlertSchema ?? true
}]

var azureFunctionActions = [for (func, index) in azureFunctionRecipients: {
  name: 'AzureFunction_${index}_${replace(func.name, ' ', '_')}'
  functionAppResourceId: func.functionAppResourceId
  functionName: func.functionName
  httpTriggerUrl: func.httpTriggerUrl
  useCommonAlertSchema: func.?useCommonAlertSchema ?? true
}]

var logicAppActions = [for (logicApp, index) in logicAppRecipients: {
  name: 'LogicApp_${index}_${replace(logicApp.name, ' ', '_')}'
  resourceId: logicApp.resourceId
  callbackUrl: logicApp.callbackUrl
  useCommonAlertSchema: logicApp.?useCommonAlertSchema ?? true
}]

// ------------------
// RESOURCES
// ------------------

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: actionGroupName
  location: location
  tags: tags
  properties: {
    groupShortName: shortName
    enabled: enabled
    emailReceivers: emailActions
    smsReceivers: smsActions
    webhookReceivers: webhookActions
    azureFunctionReceivers: azureFunctionActions
    logicAppReceivers: logicAppActions
  }
}

// ------------------
// OUTPUTS
// ------------------

@description('The resource ID of the Action Group')
output actionGroupId string = actionGroup.id

@description('The name of the Action Group')
output actionGroupName string = actionGroup.name

@description('The resource group of the Action Group')
output resourceGroupName string = resourceGroup().name
