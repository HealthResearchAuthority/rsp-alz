targetScope = 'managementGroup'

// ------------------
//    PARAMETERS
// ------------------

@description('The location where the resources will be created.')
param location string =  deployment().location

@description('The location where the resources will be created.')
param managementSubscriptionId string =  ''

@description('The address prefix for the virtual network.')
param vnetprefix string = '10.1.192.0/19'

param devopspoolSubnetPrefix string = '10.1.192.0/22'
param devopspoolpepSubnetPrefix string = '10.1.196.0/24'

// ------------------
//    Variables
// ------------------

//Management Group
var topLevelManagementGroupPrefix = 'mg-rsp'
var topLevelManagementGroupParentId = 'mg-future-iras'
var opsManagementResourceGroupName = 'rg-hra-operationsmanagement'
var manageddevopspoolResourceGroupName = 'rg-hra-manageddevopspool'

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

@description('Resource group to host managed devops pool related resources')
module manageddevopspoolrg '../shared/bicep/resourceGroup.bicep' = {
  name: take('02-manageddevopspoolResourceGroupName-${deployment().name}', 64)
  scope: subscription(managementSubscriptionId)
  params: {
    parLocation: location
    parResourceGroupName: manageddevopspoolResourceGroupName
    parTags: {}
  }
}

module manageddevopspoolmodule 'modules/manageddevopspool.bicep' = {
  name: take('05-manageddevopspool-${deployment().name}', 64)
  scope: resourceGroup(managementSubscriptionId, manageddevopspoolResourceGroupName)
  params: {
    devopspoolSubnetPrefix: devopspoolSubnetPrefix
    vnetName: 'vnet-rsp-networking-devopspool'
    devopspoolSubnetName: 'snet-devopspool'
    spokeVNetAddressPrefixes: [vnetprefix]
    devopspoolpepSubnetPrefix: devopspoolpepSubnetPrefix
    logAnalyticsWorkspaceId: loganalytics.outputs.outLogAnalyticsWorkspaceId
  }
}

