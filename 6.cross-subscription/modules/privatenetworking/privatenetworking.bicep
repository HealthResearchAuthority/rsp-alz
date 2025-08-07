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

var dnsZoneInfo = {
  'privatelink.azurecr.io': {
    needed: length(containerRegistryServices) > 0
    // Container Registry DNS zones are typically in shared services subscription
    targetSubscriptionId: length(containerRegistryServices) > 0 ? split(containerRegistryServices[0], '/')[2] : ''
    targetResourceGroup: length(containerRegistryServices) > 0 ? split(containerRegistryServices[0], '/')[4] : ''
  }
  'privatelink.azurewebsites.net': {
    needed: length(webAppServices) > 0
    // Web App DNS zones are in the dev subscription where the apps are deployed
    targetSubscriptionId: length(webAppServices) > 0 ? split(webAppServices[0], '/')[2] : ''
    targetResourceGroup: length(webAppServices) > 0 ? 'rg-rsp-networking-spoke-${split(split(webAppServices[0], '/')[4], '-')[3]}-${split(split(webAppServices[0], '/')[4], '-')[4]}' : ''
  }
}


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

// Link management VNet to existing DNS zones (instead of creating new ones)
module dnsZoneLinks '../../../shared/bicep/network/private-dns-zone-vnet-link.bicep' = [for (dnsZoneName, i) in items(dnsZoneInfo): if (dnsZoneName.value.needed) {
  name: 'dnsZoneLink-${replace(dnsZoneName.key, '.', '-')}-${i}'
  scope: resourceGroup(dnsZoneName.value.targetSubscriptionId, dnsZoneName.value.targetResourceGroup)
  params: {
    privateDnsZoneName: dnsZoneName.key
    vnetId: sourceVNetID
    vnetName: '${sourceVNetName}-management-link'
    registrationEnabled: false
  }
}]

// Create private endpoints for each service
module privateEndpoints '../../../shared/bicep/network/private-endpoint.bicep' = [for serviceId in serviceIds: {
  name: take('privateEndpoint-${last(split(serviceId, '/'))}', 64)
  scope: resourceGroup(managementSubscriptionId,managementResourceGroupName)
  dependsOn: dnsZoneLinks
  params: {
    name: 'pep-${last(split(serviceId, '/'))}-management'
    location: deployment().location
    privateDnsZonesId: resourceId(
      dnsZoneInfo[privateDNSMap[split(serviceId, '/')[6]]].targetSubscriptionId,
      dnsZoneInfo[privateDNSMap[split(serviceId, '/')[6]]].targetResourceGroup,
      'Microsoft.Network/privateDnsZones',
      privateDNSMap[split(serviceId, '/')[6]]
    )
    privateLinkServiceId: serviceId
    snetId: managementPEPSubnet.id
    subresource: subResourceNamesMap[split(serviceId, '/')[6]]
  }
}]
