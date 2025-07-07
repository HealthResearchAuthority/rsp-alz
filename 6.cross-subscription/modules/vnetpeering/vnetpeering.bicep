targetScope = 'subscription'
@description('Array of VNet peering configurations')
param vnetPeeringsSpokes array

param managementSubscriptionId string
param managementResourceGroupName string
param managementVNetName string

@description('Module to create VNet peerings from Source to Target VNet')
module vnetPeeringsAtoB '../../../shared/bicep/network/peering.bicep' = [for (peering, i) in vnetPeeringsSpokes: {
  name: take('${managementVNetName}-to-${peering.vnetName}-peering', 64)
  scope: resourceGroup(managementSubscriptionId,managementResourceGroupName)
  params: {
    localVnetName: managementVNetName
    remoteVnetName: peering.vnetName
    remoteRgName: peering.resourceGroupName
    remoteSubscriptionId: peering.subscriptionId
  }
}]

@description('Module to create VNet peerings from target to source VNet')
module vnetPeeringsBtoA '../../../shared/bicep/network/peering.bicep' = [for (peering, i) in vnetPeeringsSpokes: {
  name: take('${peering.vnetName}-to-${managementVNetName}-peering', 64)
  scope: resourceGroup(peering.subscriptionId, peering.resourceGroupName)
  params: {
    localVnetName: peering.vnetName
    remoteVnetName: managementVNetName
    remoteRgName: managementResourceGroupName
    remoteSubscriptionId: managementSubscriptionId
  }
}]
