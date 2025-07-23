targetScope = 'subscription'

param sourceVNetID string

@description('The ID of the Azure service to be used for the private endpoint.')
param serviceId string

param managementSubscriptionId string
param managementResourceGroupName string

var sourceVNetTokens = split(sourceVNetID, '/')
var sourceVNetName = sourceVNetTokens[8]

var serviceTokens = split(serviceId, '/')
var sourceResourceType = serviceTokens[6]
var serviceName = serviceTokens[8]

//Vnet of Management DevOps Pool 
var vNetLinksDefault = [
  {
    vnetId: sourceVNetID
    vnetName: sourceVNetName
    registrationEnabled: false
  }
]

var privateDNSMap = {
  'Microsoft.ContainerRegistry': 'privatelink.azurecr.io'
}

var subResourceNamesMap = {
  'Microsoft.ContainerRegistry': 'registry'
}

var privateDNSName = privateDNSMap[?sourceResourceType] ?? ''
var subResourceName = subResourceNamesMap[?sourceResourceType] ?? ''

resource vnetSpoke 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  scope: resourceGroup(managementSubscriptionId,managementResourceGroupName)
  name: sourceVNetName
}

resource managementPEPSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' existing = {
  parent: vnetSpoke
  name: 'snet-privateendpoints'
}


module privateNetworking '../../../shared/bicep/network/private-networking-spoke.bicep' = {
  name:take('containerRegistryNetworkDeployment-${deployment().name}', 64)
  scope: resourceGroup(managementSubscriptionId,managementResourceGroupName)
  params: {
    location: deployment().location
    azServicePrivateDnsZoneName: privateDNSName
    azServiceId: serviceId
    privateEndpointSubResourceName: subResourceName
    virtualNetworkLinks: vNetLinksDefault
    subnetId: managementPEPSubnet.id
    privateEndpointName: 'pep-${serviceName}-management' //Should be in this format: pep-<resourcename>-management
  }
}
