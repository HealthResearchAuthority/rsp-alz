targetScope = 'resourceGroup'

@description('Name of the private DNS zone to link to')
param privateDnsZoneName string

@description('Virtual network resource ID to link')
param vnetId string

@description('Name for the virtual network link')
param vnetName string

@description('Whether registration is enabled for this virtual network link')
param registrationEnabled bool = false

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' existing = {
  name: privateDnsZoneName
}

resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: privateDnsZone
  name: vnetName
  location: 'global'
  properties: {
    registrationEnabled: registrationEnabled
    virtualNetwork: {
      id: vnetId
    }
  }
}

output linkId string = vnetLink.id