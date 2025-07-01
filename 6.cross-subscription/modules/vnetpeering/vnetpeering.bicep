targetScope = 'subscription'
@description('Array of VNet peering configurations')
param vnetPeerings array

@description('Module to create VNet peerings from Source to Target VNet')
module vnetPeeringsAtoB '../../../shared/bicep/network/peering.bicep' = [for (peering, i) in vnetPeerings: {
  name: take('${peering.sourceVnet.name}-to-${peering.targetVnet.name}-peering', 64)
  scope: resourceGroup(peering.sourceVnet.resourceGroup, peering.sourceVnet.subscriptionId)
  params: {
    localVnetName: peering.sourceVnet.name
    remoteVnetName: peering.targetVnet.name
    remoteRgName: peering.targetVnet.resourceGroup
    remoteSubscriptionId: peering.targetVnet.subscriptionId
  }
}]

@description('Module to create VNet peerings from target to source VNet')
module vnetPeeringsBtoA '../../../shared/bicep/network/peering.bicep' = [for (peering, i) in vnetPeerings: {
  name: take('${peering.targetVnet.name}-to-${peering.sourceVnet.name}-peering', 64)
  scope: resourceGroup(peering.targetVnet.resourceGroup, peering.targetVnet.subscriptionId)
  params: {
    localVnetName: peering.targetVnet.name
    remoteVnetName: peering.sourceVnet.name
    remoteRgName: peering.sourceVnet.resourceGroup
    remoteSubscriptionId: peering.sourceVnet.subscriptionId
  }
}]
