targetScope = 'subscription'

param sourceVNetID string

@description('The IDs of the Azure services to be used for the private endpoints.')
param serviceIds array

param managementSubscriptionId string
param managementResourceGroupName string

var sourceVNetTokens = split(sourceVNetID, '/')
var sourceVNetName = sourceVNetTokens[8]

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
  'Microsoft.Web': 'privatelink.azurewebsites.net'
}

var subResourceNamesMap = {
  'Microsoft.ContainerRegistry': 'registry'
  'Microsoft.Web': 'sites'
}

resource vnetSpoke 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  scope: resourceGroup(managementSubscriptionId,managementResourceGroupName)
  name: sourceVNetName
}

resource managementPEPSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' existing = {
  parent: vnetSpoke
  name: 'snet-privateendpoints'
}

// Create private endpoints for each service using the original working approach
module privateNetworking '../../../shared/bicep/network/private-networking-spoke.bicep' = [for serviceId in serviceIds: {
  name: take('serviceNetworkDeployment-${last(split(serviceId, '/'))}', 64)
  scope: resourceGroup(managementSubscriptionId,managementResourceGroupName)
  params: {
    location: deployment().location
    azServicePrivateDnsZoneName: privateDNSMap[split(serviceId, '/')[6]]
    azServiceId: serviceId
    privateEndpointSubResourceName: subResourceNamesMap[split(serviceId, '/')[6]]
    virtualNetworkLinks: vNetLinksDefault
    subnetId: managementPEPSubnet.id
    privateEndpointName: 'pep-${last(split(serviceId, '/'))}-management'
  }
}]
