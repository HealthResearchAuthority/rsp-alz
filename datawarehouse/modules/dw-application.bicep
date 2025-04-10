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
// Parameters end here

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: virtualNetworks_HRADataWarehouseVirtualNetwork_name
}

resource networkSecurityGroups_HRA_Data_DataModelling_nsg_name_resource 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: networkSecurityGroups_HRA_Data_DataModelling_nsg_name
  location: resourceGroup().location
  properties: {
    securityRules: []
  }
}

resource networkSecurityGroups_AllowAnyCustom8443Inbound 'Microsoft.Network/networkSecurityGroups/securityRules@2024-05-01' = {
  parent: networkSecurityGroups_HRA_Data_DataModelling_nsg_name_resource
  name: 'AllowAnyCustom8443Inbound'
  properties: {
    description: 'Allows Inbound Connection From iBoss'
    protocol: '*'
    sourcePortRange: '*'
    destinationPortRange: '8443'
    destinationAddressPrefix: '*'
    access: 'Allow'
    priority: 120
    direction: 'Inbound'
    sourcePortRanges: []
    destinationPortRanges: []
    sourceAddressPrefixes: [
      '136.228.232.21/32'
      '136.228.234.3/32'
      '136.228.244.77/32'
      '185.251.11.210/32'
      '185.251.11.92/32'
      '136.228.234.5/32'
      '136.228.234.30/32'
      '136.228.234.48/32'
      '136.228.234.67/32'
      '136.228.224.113/32'
      '136.228.244.17/32'
      '136.228.244.21/32'
      '136.228.224.106/32'
      '136.228.244.128/32'
      '136.228.244.78/32'
      '136.228.244.161/32'
      '136.228.244.45/32'
      '136.228.234.7/32'
      '136.228.244.115/32'
    ]
    destinationAddressPrefixes: []
  }
}

resource networkSecurityGroups_AllowPAIps 'Microsoft.Network/networkSecurityGroups/securityRules@2024-05-01' = {
  parent: networkSecurityGroups_HRA_Data_DataModelling_nsg_name_resource
  name: 'AllowPAIps'
  properties: {
    protocol: '*'
    sourcePortRange: '*'
    destinationPortRange: '8443'
    destinationAddressPrefix: '*'
    access: 'Allow'
    priority: 140
    direction: 'Inbound'
    sourcePortRanges: []
    destinationPortRanges: []
    sourceAddressPrefixes: [
      '217.38.8.142'
      '194.75.196.200'
      '80.169.67.56'
      '194.196.148.229'
    ]
    destinationAddressPrefixes: []
  }
}

resource networkSecurityGroups_AllowCidrBlockCustomAnyInbound 'Microsoft.Network/networkSecurityGroups/securityRules@2024-05-01' = {
  parent: networkSecurityGroups_HRA_Data_DataModelling_nsg_name_resource
  name: 'AllowCidrBlockCustomAnyInbound'
  properties: {
    description: 'This is the ERStudioApp IP address and it\'s needed for login via SSO to work'
    protocol: '*'
    sourcePortRange: '*'
    destinationPortRange: '*'
    sourceAddressPrefix: '20.0.121.199'
    destinationAddressPrefix: '*'
    access: 'Allow'
    priority: 130
    direction: 'Inbound'
    sourcePortRanges: []
    destinationPortRanges: []
    sourceAddressPrefixes: []
    destinationAddressPrefixes: []
  }
}

resource networkSecurityGroups_AllowTagCustom1433Inbound 'Microsoft.Network/networkSecurityGroups/securityRules@2024-05-01' = {
  parent: networkSecurityGroups_HRA_Data_DataModelling_nsg_name_resource
  name: 'AllowTagCustom1433Inbound'
  properties: {
    protocol: '*'
    sourcePortRange: '*'
    destinationPortRange: '1433'
    sourceAddressPrefix: 'VirtualNetwork'
    destinationAddressPrefix: '*'
    access: 'Allow'
    priority: 100
    direction: 'Inbound'
    sourcePortRanges: []
    destinationPortRanges: []
    sourceAddressPrefixes: []
    destinationAddressPrefixes: []
  }
}

resource publicIPAddresses_ERStudioApp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: publicIPAddresses_ERStudioApp_name
  location: resourceGroup().location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  zones: [
    '1'
  ]
  properties: {
    ipAddress: '20.0.121.199'
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource publicIPAddresses_ERStudioDB 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: publicIPAddresses_ERStudioDB_name
  location: resourceGroup().location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  zones: [
    '1'
  ]
  properties: {
    ipAddress: '20.77.4.116'
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource publicIPAddresses_HRADataWarehouseVirtualNetwork 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: publicIPAddresses_HRADataWarehouseVirtualNetwork_ip_name
  location: resourceGroup().location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    ipAddress: '172.167.143.176'
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    ipTags: []
  }
}

resource bastionHosts_HRA_Data_DataModellingBS_name_resource 'Microsoft.Network/bastionHosts@2024-05-01' = {
  name: bastionHosts_HRA_Data_DataModellingBS_name
  location: resourceGroup().location
  sku: {
    name: 'Standard'
  }
  properties: {
    enablePrivateOnlyBastion: false
    enableSessionRecording: false
    dnsName: bastionDnsName
    scaleUnits: 2
    enableTunneling: true
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddresses_HRADataWarehouseVirtualNetwork.id
          }
          subnet: {
            id: resourceId('VisualStudioOnline-4140D62E99124BBBABC390FFA33D669D', 'Microsoft.Network/virtualNetworks/subnets', virtualNetworks_HRADataWarehouseVirtualNetwork_name, 'AzureBastionSubnet')
          }
        }
        id: resourceId('Microsoft.Network/bastionHosts/bastionHostIpConfigurations', bastionHosts_HRA_Data_DataModellingBS_name, 'IpConf')
      }
    ]
  }
}

resource networkInterfaces_hra_data_erstudioapp913_z1_name_resource 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: networkInterfaces_hra_data_erstudioapp913_z1_name
  location: resourceGroup().location
  kind: 'Regular'
  properties: {
    defaultOutboundConnectivityEnabled: false
    allowPort25Out: false
    ipConfigurations: [
      {
        name: 'ipconfig1'
        type: 'Microsoft.Network/networkInterfaces/ipConfigurations'
        properties: {
          privateIPAddress: '172.18.0.4'
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddresses_ERStudioApp.id
            properties: {
              deleteOption: 'Delete'
            }
          }
          subnet: {
            id: resourceId('VisualStudioOnline-4140D62E99124BBBABC390FFA33D669D', 'Microsoft.Network/virtualNetworks/subnets', virtualNetworks_HRADataWarehouseVirtualNetwork_name, 'HRADataWarehouseVirtualNetworkSubnet')
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: true
    enableIPForwarding: false
    disableTcpStateTracking: false
    networkSecurityGroup: {
      id: networkSecurityGroups_HRA_Data_DataModelling_nsg_name_resource.id
    }
    nicType: 'Standard'
    auxiliaryMode: 'None'
    auxiliarySku: 'None'
  }
}

resource networkInterfaces_hra_data_erstudiodb711_z1_name_resource 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: networkInterfaces_hra_data_erstudiodb711_z1_name
  location: resourceGroup().location
  kind: 'Regular'
  properties: {
    defaultOutboundConnectivityEnabled: false
    allowPort25Out: false
    ipConfigurations: [
      {
        name: 'ipconfig1'
        type: 'Microsoft.Network/networkInterfaces/ipConfigurations'
        properties: {
          privateIPAddress: '172.18.0.5'
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddresses_ERStudioDB.id
            properties: {
              deleteOption: 'Delete'
            }
          }
          subnet: {
            id: resourceId('VisualStudioOnline-4140D62E99124BBBABC390FFA33D669D', 'Microsoft.Network/virtualNetworks/subnets', virtualNetworks_HRADataWarehouseVirtualNetwork_name, 'HRADataWarehouseVirtualNetworkSubnet')
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: true
    enableIPForwarding: false
    disableTcpStateTracking: false
    networkSecurityGroup: {
      id: networkSecurityGroups_HRA_Data_DataModelling_nsg_name_resource.id
    }
    nicType: 'Standard'
    auxiliaryMode: 'None'
    auxiliarySku: 'None'
  }
}

resource virtualMachines_HRA_Data_ERStudioApp_name_resource 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: virtualMachines_HRA_Data_ERStudioApp_name
  location: resourceGroup().location
  zones: [
    '1'
  ]
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D4as_v5'
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-datacenter-gensecond'
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        diskSizeGB: 512
      }
    }
    osProfile: {
      adminUsername: adminUsername
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
      }
    }
    securityProfile: {
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
      securityType: 'TrustedLaunch'
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaces_hra_data_erstudioapp913_z1_name_resource.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

resource virtualMachines_HRA_Data_ERStudioDB_name_resource 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: virtualMachines_HRA_Data_ERStudioDB_name
  location: resourceGroup().location
  zones: [
    '1'
  ]
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_E2as_v5'
    }
    storageProfile: {
      imageReference: {
        publisher: 'microsoftsqlserver'
        offer: 'sql2019-ws2019'
        sku: 'standard-gen2'
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
        diskSizeGB: 256
      }
    }
    osProfile: {
      adminUsername: adminUsername
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
      }
    }
    securityProfile: {
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
      securityType: 'TrustedLaunch'
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaces_hra_data_erstudiodb711_z1_name_resource.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}


resource sqlVirtualMachines_HRA_Data_ERStudioDB_name_resource 'Microsoft.SqlVirtualMachine/sqlVirtualMachines@2023-10-01' = {
  name: sqlVirtualMachines_HRA_Data_ERStudioDB_name
  location: resourceGroup().location
  properties: {
    virtualMachineResourceId: virtualMachines_HRA_Data_ERStudioDB_name_resource.id
    sqlImageOffer: 'SQL2019-WS2019'
    sqlServerLicenseType: 'AHUB'
    sqlManagement: 'Full'
    leastPrivilegeMode: 'Enabled'
    sqlImageSku: 'Standard'
    enableAutomaticUpgrade: true
  }
}

output vnetID string = vnet.id
