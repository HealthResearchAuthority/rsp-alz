targetScope = 'subscription'
@description('Array of VNet peering configurations')
param vnetPeeringsSpokes array

param datawarehouseSubscriptionId string
param dwNetworkingResourceGroupName string
param datawarehouseVNetName string

@description('Module to create VNet peerings from Source to Target VNet')
module vnetPeeringsAtoB '../../shared/bicep/network/peering.bicep' = [for (peering, i) in vnetPeeringsSpokes: {
  name: take('dw-${peering.vnetName}-link', 64)
  scope: resourceGroup(datawarehouseSubscriptionId,dwNetworkingResourceGroupName)
  params: {
    localVnetName: datawarehouseVNetName
    remoteVnetName: peering.vnetName
    remoteRgName: peering.resourceGroupName
    remoteSubscriptionId: peering.subscriptionId
    allowGatewayTransit: true
    allowForwardedTraffic: true
  }
}]

@description('Module to create VNet peerings from target to source VNet')
module vnetPeeringsBtoA '../../shared/bicep/network/peering.bicep' = [for (peering, i) in vnetPeeringsSpokes: {
  name: take('${peering.vnetName}-dw-link', 64)
  scope: resourceGroup(peering.subscriptionId, peering.resourceGroupName)
  params: {
    localVnetName: peering.vnetName
    remoteVnetName: datawarehouseVNetName
    remoteRgName: dwNetworkingResourceGroupName
    remoteSubscriptionId: datawarehouseSubscriptionId
    allowForwardedTraffic: true
    useRemoteGateways: true
  }
}]
