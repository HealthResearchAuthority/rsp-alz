@description('Required. Name of the private endpoint.')
@minLength(2)
@maxLength(64)
param privateEndpointName string

@description('Required. Location for the private endpoint.')
param location string

@description('Optional. Tags of the resource.')
param tags object = {}

@description('Required. The subnet resource ID where the private endpoint NIC will be attached.')
param subnetId string

@description('Required. The resource ID of the Azure service for private link connection.')
param privateLinkServiceId string

@description('Required. The subresource name for the private link connection (e.g., sites, blob, registry).')
param groupId string

@description('Required. The resource ID of the existing private DNS zone.')
param privateDnsZoneId string

@description('Optional. Custom DNS configuration name.')
param dnsConfigName string = 'default'

// ------------------
// RESOURCES
// ------------------

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: privateEndpointName
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'connection-${privateEndpointName}'
        properties: {
          privateLinkServiceId: privateLinkServiceId
          groupIds: [groupId]
        }
      }
    ]
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: dnsConfigName
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

// ------------------
// OUTPUTS
// ------------------

@description('The resource ID of the private endpoint.')
output privateEndpointId string = privateEndpoint.id

@description('The name of the private endpoint.')
output privateEndpointName string = privateEndpoint.name

@description('The resource ID of the private DNS zone group.')
output privateDnsZoneGroupId string = privateDnsZoneGroup.id