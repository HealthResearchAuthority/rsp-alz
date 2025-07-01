targetScope = 'managementGroup'

// ------------------
//    PARAMETERS
// ------------------

@description('The location where the resources will be created.')
param paramDevVNetID string

@description('VNet ID under managed devops pool subscription where the VNet peering will be created.')
param manageddevopspoolVnetID string


var devVNetVNetIdTokens = split(paramDevVNetID, '/')
var devSubscriptionId = devVNetVNetIdTokens[2]
var devResourceGroupName = devVNetVNetIdTokens[4]
var devVNetName = devVNetVNetIdTokens[8]

var managementVNetIdTokens = split(manageddevopspoolVnetID, '/')
var managementSubscriptionId = managementVNetIdTokens[2]
var managementResourceGroupName = managementVNetIdTokens[4]
var managementVNetName = managementVNetIdTokens[8]

//This param should be a string with comma separated Sub ID's of the subscriptions where the VNet peerings will be created. 
//This then need to be split on "," which will give array of all sub ID's which then needs to be split on "/" to extract SUb ID, 
//RG and VNetName
//Another param with just Management VNet ID


@description('Deploy VNet Peering with DevOps Subscription VNet')
module vnetpeeringmodule 'modules/vnetpeering/vnetpeering.bicep' = {
  name: take('01-vnetPeeringCore-${deployment().name}', 64)
  scope: subscription(managementSubscriptionId)
  params: {
    managementSubscriptionId: managementSubscriptionId
    managementResourceGroupName: managementResourceGroupName
    managementVNetName: managementVNetName
    spokeResourceGroupName: devResourceGroupName
    spokeSubscriptionId: devSubscriptionId
    spokeVNetName: devVNetName
  }
}


output managementSubscriptionId string = managementSubscriptionId
output managementResourceGroupName string = managementResourceGroupName
output managementVNetName string = managementVNetName
output devSubscriptionId string = devSubscriptionId
output devResourceGroupName string = devResourceGroupName
output devVNetName string = devVNetName
output devVNetId string = paramDevVNetID
output manageddevopspoolVnetID string = manageddevopspoolVnetID
