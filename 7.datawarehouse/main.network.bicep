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


@description('Remote VNet ID for Devbox')
param devboxVnetId string

@description('Remote VNet ID for Manual Test')
param devVnetId string

@description('Remote VNet ID for Managed Devops Pool')
param manageddevopspoolVnetId string

@description('External ID of the remote VPN Gateway')
param remoteVpnGatewayId string

@description('External ID of the remote Local Network Gateway')
param remoteLocalGatewayId string

@description('Gateway IP address')
param GatewayIp string

@description('BGP Peering Address')
param bgpPeeringAddress string

@description('The location where the resources will be created.')
param paramvnetPeeringsVNetIDs string

@description('VNet ID under managed devops pool subscription where the VNet peering will be created.')
param datawarehouseVnetID string

var datawarehouseVNetIdTokens = split(datawarehouseVnetID, '/')
var datawarehouseSubscriptionId = datawarehouseVNetIdTokens[2]
var dwNetworkingResourceGroupName = targetRg.name
var datawarehouseVNetName = datawarehouseVNetIdTokens[8]

var peeringVNetIds = split(paramvnetPeeringsVNetIDs, ',')

// Loop through each VNet ID and extract subscriptionId and resourceGroupName
var vnetInfoArray = [
  for vnetId in peeringVNetIds: {
    subscriptionId: split(vnetId, '/')[2]
    resourceGroupName: split(vnetId, '/')[4]
    vnetName: split(vnetId, '/')[8]
  }
]

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
    localNetworkGatewayName: localNetworkGatewayName
    devVnetId: devVnetId
    manageddevopspoolVnetId: manageddevopspoolVnetId
    remoteLocalGatewayId: remoteLocalGatewayId
    remoteVpnGatewayId: remoteVpnGatewayId
    GatewayIp: GatewayIp
    bgpPeeringAddress: bgpPeeringAddress
  }
}

@description('Deploy VNet Peering')
module vnetpeeringmodule 'modules/vnetpeering.bicep' = {
  name: take('01-vnetPeering-${deployment().name}', 64)
  scope: subscription(datawarehouseSubscriptionId)
  params: {
    vnetPeeringsSpokes: vnetInfoArray
    datawarehouseSubscriptionId: datawarehouseSubscriptionId
    dwNetworkingResourceGroupName: dwNetworkingResourceGroupName
    datawarehouseVNetName: datawarehouseVNetName
  }
}
