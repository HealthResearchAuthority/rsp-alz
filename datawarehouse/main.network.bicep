targetScope = 'subscription'

param targetRgName string = 'VisualStudioOnline-4140D62E99124BBBABC390FFA33D669D'

@description('Name of the local network gateway')
param localNetworkGatewayName string

@description('Name of the public IP address')
param publicIpName string

@description('Name of the virtual network')
param vnetName string

@description('Name of the VPN gateway')
param vpnGatewayName string

@description('Connection name for VPN')
param connectionName string

@description('Name of Azure DevOps account')
param devopsAccountName string

@description('Remote VNet ID for Devbox')
param devboxVnetId string

@description('Remote VNet ID for Manual Test')
param manualTestVnetId string

@description('External ID of the remote VPN Gateway')
param remoteVpnGatewayId string

@description('External ID of the remote Local Network Gateway')
param remoteLocalGatewayId string

@description('Gateway IP address')
param GatewayIp string

@description('BGP Peering Address')
param bgpPeeringAddress string

resource targetRg 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name: targetRgName
}

module dw_network './modules/dw-network.bicep' = {
  name: 'deployNetwork'
  scope: targetRg
  params: {
    vnetName: vnetName
    connectionName: connectionName
    publicIpName: publicIpName
    vpnGatewayName: vpnGatewayName
    devboxVnetId: devboxVnetId
    devopsAccountName: devopsAccountName
    localNetworkGatewayName: localNetworkGatewayName
    manualTestVnetId: manualTestVnetId
    remoteLocalGatewayId: remoteLocalGatewayId
    remoteVpnGatewayId: remoteVpnGatewayId
    GatewayIp: GatewayIp
    bgpPeeringAddress: bgpPeeringAddress
  }
}
