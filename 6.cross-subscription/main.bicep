targetScope = 'managementGroup'

// ------------------
//    PARAMETERS
// ------------------

@description('The location where the resources will be created.')
param paramvnetPeeringsVNetIDs string

@description('The IDs of the Azure service to be used for the private endpoint.')
param paramserviceIds string

@description('VNet ID under managed devops pool subscription where the VNet peering will be created.')
param manageddevopspoolVnetID string

var managementVNetIdTokens = split(manageddevopspoolVnetID, '/')
var managementSubscriptionId = managementVNetIdTokens[2]
var managementResourceGroupName = managementVNetIdTokens[4]
var managementVNetName = managementVNetIdTokens[8]

var peeringVNetIds = split(paramvnetPeeringsVNetIDs, ',')

// Loop through each VNet ID and extract subscriptionId and resourceGroupName
var vnetInfoArray = [
  for vnetId in peeringVNetIds: {
    subscriptionId: split(vnetId, '/')[2]
    resourceGroupName: split(vnetId, '/')[4]
    vnetName: split(vnetId, '/')[8]
  }
]

var pepServiceIDArray = split(paramserviceIds, ',')

@description('Deploy VNet Peering')
module vnetpeeringmodule 'modules/vnetpeering/vnetpeering.bicep' = {
  name: take('01-vnetPeering-${deployment().name}', 64)
  scope: subscription(managementSubscriptionId)
  params: {
    vnetPeeringsSpokes: vnetInfoArray
    managementSubscriptionId: managementSubscriptionId
    managementResourceGroupName: managementResourceGroupName
    managementVNetName: managementVNetName
  }
}

module privateNetworking 'modules/privatenetworking/privatenetworking.bicep' = [for (serviceId, i) in pepServiceIDArray: {
  name: take('privateNetworking-${last(split(serviceId, '/'))}', 64)
  scope: subscription(managementSubscriptionId)
  params: {
    sourceVNetID: manageddevopspoolVnetID
    serviceId: serviceId
    managementSubscriptionId: managementSubscriptionId
    managementResourceGroupName: managementResourceGroupName
  }
}]

output serviceIDs array = [for serviceId in pepServiceIDArray: {
  serviceId: serviceId
}]
