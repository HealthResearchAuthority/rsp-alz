targetScope = 'subscription'

param managementSubscriptionId string
param managementResourceGroupName string
param managementVNetName string


param spokeSubscriptionId string
param spokeResourceGroupName string
param spokeVNetName string

@description('Module to create VNet peerings from Source to Target VNet')
module vnetPeeringsAtoB '../../../shared/bicep/network/peering.bicep' = {
  name: take('${managementVNetName}-to-${spokeVNetName}-peering', 64)
  scope: resourceGroup(managementResourceGroupName, managementSubscriptionId)
  params: {
    localVnetName: managementVNetName
    remoteVnetName: spokeVNetName
    remoteRgName: spokeResourceGroupName
    remoteSubscriptionId: spokeSubscriptionId
  }
}

@description('Module to create VNet peerings from target to source VNet')
module vnetPeeringsBtoA '../../../shared/bicep/network/peering.bicep' = {
  name: take('${spokeVNetName}-to-${managementVNetName}-peering', 64)
  scope: resourceGroup(spokeResourceGroupName, spokeSubscriptionId)
  params: {
    localVnetName: spokeVNetName
    remoteVnetName: managementVNetName
    remoteRgName: managementResourceGroupName
    remoteSubscriptionId: managementSubscriptionId
  }
}
