@description('Required. Name of your Private Endpoint. Must begin with a letter or number, end with a letter, number or underscore, and may contain only letters, numbers, underscores, periods, or hyphens.')
@minLength(2)
@maxLength(64)
param name string

@description('Location for all resources.')
param location string

@description('Optional. Tags of the resource.')
param tags object = {}

@description('The subnet resource ID where the nic of the PE will be attached to')
param snetId string

@description('The resource id of private link service. The resource ID of the Az Resource that we need to attach the pe to.')
param privateLinkServiceId string

@description('The resource that the Private Endpoint will be attached to, as shown in https://learn.microsoft.com/azure/private-link/private-endpoint-overview#private-link-resource')
param subresource string

@description('Id of the relevant private DNS Zone, so that the PE can create an A record for the implicitly created nic')
param privateDnsZonesId string
param customNICName string = ''

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    subnet: {
      id: snetId
    }
    customNetworkInterfaceName: customNICName
    privateLinkServiceConnections: [
      {
        name: 'pl-${name}'
        properties: {
          privateLinkServiceId: privateLinkServiceId
          groupIds: [
            subresource
          ]
        }
      }
    ]
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  //name: '${privateEndpoint.name}/dnsgroupname'
  parent: privateEndpoint
  name: 'dnsgroupname'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZonesId
        }
      }
    ]
  }
}
