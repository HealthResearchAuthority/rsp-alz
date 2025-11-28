@description('The name of the local Virtual Network')
param localVnetName string

@description('The name of the remote Virtual Network')
param remoteVnetName string

@description('The name of the resource group of the remote virtual netowrk')
param remoteRgName string

@description('The id of the subscription of the remote virtual netowrk')
param remoteSubscriptionId string

@description('Allow traffic pass through VPN Gateway')
param allowGatewayTransit bool = false

@description('Allow traffic to be received from remote peered network')
param allowForwardedTraffic bool = false

@description('Allow the use of the remote peered VPN Gateway')
param useRemoteGateways bool = false

resource vnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-08-01' = {
  name: '${localVnetName}/peerTo-${remoteVnetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowGatewayTransit: allowGatewayTransit
    allowForwardedTraffic: allowForwardedTraffic
    useRemoteGateways: useRemoteGateways
    remoteVirtualNetwork: {
      id: resourceId(remoteSubscriptionId, remoteRgName, 'Microsoft.Network/virtualNetworks', remoteVnetName)
    }
  }
}
