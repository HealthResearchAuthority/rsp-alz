targetScope = 'subscription'

param sourceVNetID string

@description('The IDs of the Azure services to be used for the private endpoints.')
param serviceIds array

param managementSubscriptionId string
param managementResourceGroupName string

var sourceVNetTokens = split(sourceVNetID, '/')
var sourceVNetName = sourceVNetTokens[8]

// Get unique DNS zones needed based on service types
var containerRegistryServices = filter(serviceIds, serviceId => contains(serviceId, 'Microsoft.ContainerRegistry'))
var webAppServices = filter(serviceIds, serviceId => contains(serviceId, 'Microsoft.Web'))

var dnsZonesNeeded = concat(
  length(containerRegistryServices) > 0 ? ['privatelink.azurecr.io'] : [],
  length(webAppServices) > 0 ? ['privatelink.azurewebsites.net'] : []
)

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

// Create DNS zones first (one per type)
module dnsZones '../../../shared/bicep/network/private-dns-zone.bicep' = [for dnsZone in dnsZonesNeeded: {
  name: 'dnsZone-${replace(dnsZone, '.', '-')}'
  scope: resourceGroup(managementSubscriptionId,managementResourceGroupName)
  params: {
    name: dnsZone
    virtualNetworkLinks: vNetLinksDefault
  }
}]

// Create private endpoints for each service
module privateEndpoints '../../../shared/bicep/network/private-endpoint.bicep' = [for serviceId in serviceIds: {
  name: take('privateEndpoint-${last(split(serviceId, '/'))}', 64)
  scope: resourceGroup(managementSubscriptionId,managementResourceGroupName)
  dependsOn: dnsZones
  params: {
    name: 'pep-${last(split(serviceId, '/'))}-management'
    location: deployment().location
    privateDnsZonesId: resourceId(managementSubscriptionId, managementResourceGroupName, 'Microsoft.Network/privateDnsZones', privateDNSMap[split(serviceId, '/')[6]])
    privateLinkServiceId: serviceId
    snetId: managementPEPSubnet.id
    subresource: subResourceNamesMap[split(serviceId, '/')[6]]
  }
}]
