targetScope = 'subscription'

param targetRgName string = 'HRA-Data-DataModelling'

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

resource targetRg 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name: targetRgName
}

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
