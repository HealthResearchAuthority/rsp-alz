// ------------------
//    PARAMETERS
// ------------------

@description('Name of your Flow log resource')
param flowLogName string = ''

@description('Region where you resources are located')
param location string

@description('Flag to enable/disable flow logging')
param enableFlowLogs bool = true

@description('Retention period in days. Default is zero which stands for permanent retention. Can be any Integer from 0 to 365')
@minValue(0)
@maxValue(365)
param retentionDays int = 7

@description('FlowLogs Version. Correct values are 1 or 2 (default)')
@allowed([
  1
  2
])
param flowLogsVersion int = 2

@description('ID of network security group to which flow log will be applied.')
param targetResourceId string

@description('Name of the storage account if creating flow logs')
@maxLength(24)
param flStorageAccountName string

// @description('Network ACLs object to apply to the storage account.')
// param networkAcls object

@description('Central Log Analytics Workspace ID')
param logAnalyticsWorkspaceId string

// @description('Storage resource group name for storage accounts')
// param spokeStorageResourceGroup string

param subnetIdForNsgFlowLog string

var networkAcls = {
  defaultAction: 'Deny'
  bypass: 'AzureServices'
  virtualNetworkRules: [
    {
      id: subnetIdForNsgFlowLog
      action: 'Allow'
    }
  ]
}

module flStorage '../storage/storage.bicep' = {
  name: take('flStorage-${deployment().name}', 64)
  params: {
    name: flStorageAccountName
    location: location
    sku: 'Standard_LRS'
    kind: 'StorageV2'
    supportsHttpsTrafficOnly: true
    tags: {}
    networkAcls: networkAcls
    allowSharedKeyAccess: false
  }  
}

resource flowLog 'Microsoft.Network/networkWatchers/flowLogs@2022-01-01' = {
  name: flowLogName
  location: location
  properties: {
    targetResourceId: targetResourceId
    storageId: flStorage.outputs.id
    enabled: enableFlowLogs
    flowAnalyticsConfiguration: {
      networkWatcherFlowAnalyticsConfiguration: {
        enabled: empty(logAnalyticsWorkspaceId) ? false : true
        trafficAnalyticsInterval: 60
        workspaceResourceId: empty(logAnalyticsWorkspaceId) ? null : logAnalyticsWorkspaceId
      }
    }
    retentionPolicy: {
      days: retentionDays
      enabled: true
    }
    format: {
      type: 'JSON'
      version: flowLogsVersion
    }
  }
}
