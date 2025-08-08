targetScope = 'subscription'

param targetRgName string = 'HRA-Data-DataModelling'

param location string = 'uksouth'

@description('Name of the ERStudioDB VM')
param virtualMachines_HRA_Data_ERStudioDB_name string

@description('Name of the ERStudioApp VM')
param virtualMachines_HRA_Data_ERStudioApp_name string

@description('Admin username for the VMs')
param adminUsername string

@description('Name of the Bastion Host for VM access')
param bastionHosts_HRA_Data_DataModellingBS_name string

@description('Public IP Address name for ERStudioDB VM')
param publicIPAddresses_ERStudioDB_name string

@description('Public IP Address name for ERStudioDB VM')
param publicIPAddresses_ERStudioApp_name string

@description('Network interface name for ERStudioDB VM')
param networkInterfaces_hra_data_erstudiodb711_z1_name string

@description('Network interface name for ERStudioApp VM')
param networkInterfaces_hra_data_erstudioapp913_z1_name string

@description('NSG for VMs')
param networkSecurityGroups_HRA_Data_DataModelling_nsg_name string

@description('SQL VM name for ERStudioApp')
param sqlVirtualMachines_HRA_Data_ERStudioDB_name string

@description('Public IP address for the Bastion Host')
param publicIPAddresses_HRADataWarehouseVirtualNetwork_ip_name string

@description('Name of the Data Warehouse Virtual Network')
param virtualNetworks_HRADataWarehouseVirtualNetwork_name string

@description('DNS hostname for Bastion Host')
param bastionDnsName string

// New Params for Azure Functions and Database
@description('Admin username for the HARP Sync Database server')
param harpSqlAdminLogin string = ''

@secure()
@description('Admin password for the HARP Sync SQL Server')
param harpSqlAdminPassword string

@description('Envrionment name (e.g dev, prod)')
param environment string

@description('Name of the resource group for HARP data sync resources')
param harpSyncResourceGroupName string

@description('The resource id of an existing Azure Log Analytics Workspace')
param logAnalyticsWorkspaceId string

@description('Enable deployment of Azure Functions and Database')
param enableHarpDeployment bool = true

resource targetRg 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name: targetRgName
}

resource harpSyncRG 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name: harpSyncResourceGroupName
}

// resource vnetSpoke 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
//   scope: resourceGroup(spokeSubscriptionId, spokeResourceGroupName)
//   name: spokeVNetName
// }

module dw_application 'modules/dw-application.bicep' = {
  name: 'deployApplication'
  scope: targetRg
  params: {
    adminUsername: adminUsername
    virtualMachines_HRA_Data_ERStudioApp_name: virtualMachines_HRA_Data_ERStudioApp_name
    virtualMachines_HRA_Data_ERStudioDB_name: virtualMachines_HRA_Data_ERStudioDB_name
    virtualNetworks_HRADataWarehouseVirtualNetwork_name: virtualNetworks_HRADataWarehouseVirtualNetwork_name
    bastionDnsName: bastionDnsName
    bastionHosts_HRA_Data_DataModellingBS_name: bastionHosts_HRA_Data_DataModellingBS_name
    networkInterfaces_hra_data_erstudioapp913_z1_name: networkInterfaces_hra_data_erstudioapp913_z1_name
    networkInterfaces_hra_data_erstudiodb711_z1_name: networkInterfaces_hra_data_erstudiodb711_z1_name
    networkSecurityGroups_HRA_Data_DataModelling_nsg_name: networkSecurityGroups_HRA_Data_DataModelling_nsg_name
    publicIPAddresses_HRADataWarehouseVirtualNetwork_ip_name: publicIPAddresses_HRADataWarehouseVirtualNetwork_ip_name
    publicIPAddresses_ERStudioApp_name: publicIPAddresses_ERStudioApp_name
    publicIPAddresses_ERStudioDB_name: publicIPAddresses_ERStudioDB_name
    sqlVirtualMachines_HRA_Data_ERStudioDB_name: sqlVirtualMachines_HRA_Data_ERStudioDB_name
  }
}

// --------------------------------------
//     Variables for HARP DB deployment
// --------------------------------------

var harpSqlServerUAIName = 'id-sql-harp-dw-${environment}'
var harpSqlServerName = 'sql-harp-dw-${environment}-uks'

module harpSyncDatabase '../5.spoke-network/modules/05-database/deploy.database.bicep' = if (enableHarpDeployment) {
  name: 'deployHarpSyncDatabase'
  scope: harpSyncRG
  params: {
    location: location
    sqlServerName: harpSqlServerName
    adminLogin: harpSqlAdminLogin
    adminPassword: harpSqlAdminPassword
    databases: ['harpprojectdata']
    spokeVNetId: '/subscriptions/461016b5-8363-472e-81be-eef6aad08353/resourceGroups/VisualStudioOnline-4140D62E99124BBBABC390FFA33D669D/providers/Microsoft.Network/virtualNetworks/HRADataWarehouseVirtualNetwork'
    spokePrivateEndpointSubnetName: 'snet-privateendpoints'
    sqlServerUAIName: harpSqlServerUAIName
    networkingResourcesNames: {
      azuresqlserverpep: 'pep-${harpSqlServerName}'
    }
    networkingResourceGroup: harpSyncResourceGroupName
    auditRetentionDays: 30
    enableSqlServerAuditing:true
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    tags: {
      Environment: environment
      Purpose: 'HARP Data Sync'
    }
  }
}


module harpSyncFunctions 'modules/azure-functions.bicep' = if (enableHarpDeployment) {
  name: 'deployHarpSyncFunctions'
  scope: harpSyncRG
  params: {
    location: location
    sku: 'B1'
    spokeVNetId: '/subscriptions/461016b5-8363-472e-81be-eef6aad08353/resourceGroups/VisualStudioOnline-4140D62E99124BBBABC390FFA33D669D/providers/Microsoft.Network/virtualNetworks/HRADataWarehouseVirtualNetwork'
    spokePrivateEndpointSubnetName: 'snet-privateendpoints'
    functionAppSubnetName: 'snet-functionapps'
    sqlDBManagedIdentityClientId: enableHarpDeployment ? (harpSyncDatabase.?outputs.?outputsqlServerUAIClientID ?? '') : ''
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    userAssignedIdentities: enableHarpDeployment && !empty(harpSyncDatabase.?outputs.?outputsqlServerUAIID ?? '') ? [harpSyncDatabase.?outputs.?outputsqlServerUAIID] : []
    environment: environment
    tags: {
      Environment: environment
      Purpose: 'HARP Data Sync'
    }
  }
  dependsOn: [
    harpSyncDatabase
  ]
}

// Outputs
output sqlServerName string = enableHarpDeployment ? harpSyncDatabase.?outputs.?sqlServer_name ?? '' : ''
output functionAppIds array = enableHarpDeployment ? (harpSyncFunctions.?outputs.?functionAppNames ?? []) : []
output harpDatabaseNames array = enableHarpDeployment ? (harpSyncDatabase.?outputs.?database_names ?? []) : []
output sqlServerUAIId string = enableHarpDeployment ? harpSyncDatabase.?outputs.?outputsqlServerUAIID ?? '' : ''

