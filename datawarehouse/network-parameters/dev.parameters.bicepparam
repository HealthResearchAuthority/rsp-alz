using '../main.network.bicep'

param connectionName = 'VysiionSite'

param devboxVnetId = '/subscriptions/9ef9a127-7a6e-452e-b18d-d2e2e89ffa92/resourceGroups/rg-rsp-devcenter/providers/Microsoft.Network/virtualNetworks/vnet-dbox-rsp-uksouth'

param devopsAccountName = 'HRADataWarehouse'

param localNetworkGatewayName = 'HRADataWarehouseNetworkGateway'

param manualTestVnetId = '/subscriptions/66482e26-764b-4717-ae2f-fab6b8dd1379/resourceGroups/NetworkWatcherRG/providers/Microsoft.Network/virtualNetworks/vnet-manual-test'

param publicIpName = 'HRADataWarehouseVirtualNetwork-PIP'

param remoteLocalGatewayId = '/subscriptions/461016b5-8363-472e-81be-eef6aad08353/resourceGroups/VisualStudioOnline-4140D62E99124BBBABC390FFA33D669D/providers/Microsoft.Network/localNetworkGateways/HRADataWarehouseNetworkGateway'

param remoteVpnGatewayId = '/subscriptions/461016b5-8363-472e-81be-eef6aad08353/resourceGroups/VisualStudioOnline-4140D62E99124BBBABC390FFA33D669D/providers/Microsoft.Network/virtualNetworkGateways/HRADataWarehouseVPNGateway'

param vnetName = 'HRADataWarehouseVirtualNetwork'

param vpnGatewayName = 'HRADataWarehouseVPNGateway'

param GatewayIp = ''

param bgpPeeringAddress = ''
