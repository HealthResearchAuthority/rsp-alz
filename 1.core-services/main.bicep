targetScope = 'managementGroup'

// ------------------
//    PARAMETERS
// ------------------

@description('The location where the resources will be created.')
param location string =  deployment().location

@description('The location where the resources will be created.')
param managementSubscriptionId string =  ''

// ------------------
//    Variables
// ------------------

//Management Group
var topLevelManagementGroupPrefix = 'mg-rsp'
var topLevelManagementGroupParentId = 'mg-future-iras'
var opsManagementResourceGroupName = 'rg-hra-operationsmanagement'

//Logging and Sentinel
var logAnalyticsWorkspaceName = 'hra-rsp-log-analytics'
var automationAccountName = 'alz-automation-account'
var logAnalyticsLinkedServiceAutomationAccountName = 'automation'

@description('Deploy Management Groups')
module managementGroup 'modules/managementGroups.bicep' = {
  name: take('01-managementGroup-${deployment().name}', 64)
  params: {
    parTopLevelManagementGroupPrefix: topLevelManagementGroupPrefix
    parTopLevelManagementGroupParentId: topLevelManagementGroupParentId
  }
}

@description('Resource group to host operatations management related resources')
module opsManagementResourceGroup '../shared/bicep/resourceGroup.bicep' = {
  name: take('02-opsManagementResourceGroup-${deployment().name}', 64)
  scope: subscription(managementSubscriptionId)
  params: {
    parLocation: location
    parResourceGroupName: opsManagementResourceGroupName
    parTags: {}
  }
}

@description('Deploy log analytics')
module loganalytics 'modules/logging.bicep' = {
  name: take('03-logging-${deployment().name}', 64)
  scope: resourceGroup(managementSubscriptionId,opsManagementResourceGroupName)
  params: {
    parLogAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    parAutomationAccountName: automationAccountName
    parLogAnalyticsLinkedServiceAutomationAccountName: logAnalyticsLinkedServiceAutomationAccountName
    parTags: {}
  }
}

@description('Deploy log analytics and sentinel resources')
module diagnostics 'modules/diagnostics/mgDiagSettingsAll.bicep' = {
  name: take('04-diagnostics-${deployment().name}', 64)
  params: {
    parTopLevelManagementGroupPrefix: topLevelManagementGroupPrefix
    parLogAnalyticsWorkspaceResourceId: loganalytics.outputs.outLogAnalyticsWorkspaceId
  }
}


