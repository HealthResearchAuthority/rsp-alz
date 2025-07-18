// targetScope = 'subscription'

// param sourceVNetID string

// @description('The ID of the Azure service to be used for the private endpoint.')
// param serviceId string

// var sourceVNetTokens = split(sourceVNetID, '/')
// var sourceVNetName = sourceVNetTokens[8]

// var serviceTokens = split(serviceId, '/')
// var sourceResourceType = serviceTokens[6]

// @description('The resource ID of the existing spoke virtual network to which the private endpoint will be connected.')
// param spokeVNetLinks array = []

// var spokeVNetLinksDefault = [
//   {
//     vnetId: sourceVNetID
//     vnetName: sourceVNetName
//     registrationEnabled: false
//   }
// ]

// var privateDNSMap = {
//   'Microsoft.ContainerRegistry': 'privatelink.azurecr.io'
// }

// var privateDNSName = privateDNSMap[?sourceResourceType] ?? ''

// module containerRegistryNetwork '../../../shared/bicep/network/private-networking-spoke.bicep' = {
//   name:take('containerRegistryNetworkDeployment-${deployment().name}', 64)
//   scope: resourceGroup(networkingResourceGroup)
//   params: {
//     location: deployment().location
//     azServicePrivateDnsZoneName: privateDNSName
//     azServiceId: serviceId
//     privateEndpointSubResourceName: containerRegistryResourceName
//     virtualNetworkLinks: spokeVNetLinksDefault
//     subnetId: spokePrivateEndpointSubnet.id
//     //vnetSpokeResourceId: spokeVNetId
//   }
// }
