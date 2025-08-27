using '../main.network.bicep'

param connectionName = 'VysiionSite'

param devboxVnetId = '/subscriptions/9ef9a127-7a6e-452e-b18d-d2e2e89ffa92/resourceGroups/rg-rsp-devcenter/providers/Microsoft.Network/virtualNetworks/vnet-dbox-rsp-uksouth'

param devopsAccountName = 'HRADataWarehouse'

param localNetworkGatewayName = 'HRADataWarehouseNetworkGateway'

param devVnetId = '/subscriptions/b83b4631-b51b-4961-86a1-295f539c826b/resourceGroups/rg-rsp-networking-spoke-dev-uks/providers/Microsoft.Network/virtualNetworks/vnet-rsp-networking-dev-uks-spoke'

param publicIpName = 'HRADataWarehouseVirtualNetwork-PIP-2'

param remoteLocalGatewayId = '/subscriptions/461016b5-8363-472e-81be-eef6aad08353/resourceGroups/VisualStudioOnline-4140D62E99124BBBABC390FFA33D669D/providers/Microsoft.Network/localNetworkGateways/HRADataWarehouseNetworkGateway'

param remoteVpnGatewayId = '/subscriptions/461016b5-8363-472e-81be-eef6aad08353/resourceGroups/VisualStudioOnline-4140D62E99124BBBABC390FFA33D669D/providers/Microsoft.Network/virtualNetworkGateways/HRADataWarehouseVPNGateway'

param vnetName = 'HRADataWarehouseVirtualNetwork'

param vpnGatewayName = 'HRADataWarehouseVPNGateway'

param GatewayIp = ''

param bgpPeeringAddress = ''
