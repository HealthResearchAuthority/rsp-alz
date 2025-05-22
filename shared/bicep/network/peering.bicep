@description('The name of the local Virtual Network')
param localVnetName string

@description('The name of the remote Virtual Network')
param remoteVnetName string

@description('The name of the resource group of the remote virtual netowrk')
param remoteRgName string

@description('The id of the subscription of the remote virtual netowrk')
param remoteSubscriptionId string

resource localVnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: localVnetName
}

resource vnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-08-01' = {
  parent: localVnet
  name: '${localVnetName}-peerTo-${remoteVnetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowGatewayTransit: false
    allowForwardedTraffic: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: resourceId(remoteSubscriptionId, remoteRgName, 'Microsoft.Network/virtualNetworks', remoteVnetName)
    }
  }
}
