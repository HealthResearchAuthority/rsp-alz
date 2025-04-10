using '../main.application.bicep'

param virtualMachines_HRA_Data_ERStudioDB_name = 'HRA-Data-ERStudioDB'

param virtualMachines_HRA_Data_ERStudioApp_name = 'HRA-Data-ERStudioApp' 

param adminUsername = ''

param bastionHosts_HRA_Data_DataModellingBS_name = 'HRA-Data-DataModellingBS'

param publicIPAddresses_ERStudioDB_name = 'HRA-Data-ERStudioDB-ip'

param publicIPAddresses_ERStudioApp_name = 'HRA-Data-ERStudioApp-ip'

param networkInterfaces_hra_data_erstudiodb711_z1_name = 'hra-data-erstudiodb711_z1'

param networkInterfaces_hra_data_erstudioapp913_z1_name = 'hra-data-erstudioapp913_z1'

param networkSecurityGroups_HRA_Data_DataModelling_nsg_name = 'HRA-Data-DataModelling-nsg'

param sqlVirtualMachines_HRA_Data_ERStudioDB_name = 'HRA-Data-ERStudioDB'

param publicIPAddresses_HRADataWarehouseVirtualNetwork_ip_name = 'HRADataWarehouseVirtualNetwork-ip'

param virtualNetworks_HRADataWarehouseVirtualNetwork_name = 'HRADataWarehouseVirtualNetwork'

param bastionDnsName = 'bst-9e2df993-e5ae-4c65-a0ec-d9418579c0ad.bastion.azure.com'
