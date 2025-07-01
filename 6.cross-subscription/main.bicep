targetScope = 'managementGroup'

// ------------------
//    PARAMETERS
// ------------------

@description('The location where the resources will be created.')
param paramvnetPeerings array

@description('Deploy VNet Peering')
module vnetpeeringmodule 'modules/vnetpeering/vnetpeering.bicep' = {
  name: take('01-vnetPeering-${deployment().name}', 64)
  scope: subscription(paramvnetPeerings[0].sourceVnet.subscriptionId)
  params: {
    vnetPeerings: paramvnetPeerings
  }
}
