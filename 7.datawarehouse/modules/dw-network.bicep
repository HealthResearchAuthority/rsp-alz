@description('Name of the local network gateway')
param localNetworkGatewayName string

@description('Name of the public IP address')
param publicIpName string

@description('Name of the virtual network')
param vnetName string

@description('Name of the VPN gateway')
param vpnGatewayName string

@description('Connection name for VPN')
param connectionName string

@description('Remote VNet ID for Devbox')
param devboxVnetId string

@description('Remote VNet ID for Manual Test')
param devVnetId string

@description('Remote VNet ID for Managed Devops Pool')
param manageddevopspoolVnetId string

@description('External ID of the remote VPN Gateway')
param remoteVpnGatewayId string

@description('External ID of the remote Local Network Gateway')
param remoteLocalGatewayId string

@description('Gateway IP address')
param GatewayIp string

@description('BGP Peering Address')
param bgpPeeringAddress string

@description('Local network gateway address space')
param LocalGatewayAddressPrefix string = '10.10.1.0/24'

@description('Address space for VNet')
param vnetAddressPrefix string = '172.18.0.0/16'

@description('Subnet address prefixes')
var dataSubnetPrefix = '172.18.0.0/24'
var gatewaySubnetPrefix = '172.18.1.0/27'
var bastionSubnetPrefix = '172.18.2.0/26'
var privateEndpointSubnetPrefix = '172.18.3.0/26'
var functionAppSubnetPrefix = '172.18.4.0/26'

module vnet '../../shared/bicep/network/vnet.bicep' = {
  name: 'vnet-datawarehouse-deployment'
  params: {
    name: vnetName
    location: resourceGroup().location
    tags: {}
    vnetAddressPrefixes: [vnetAddressPrefix ]
    subnets: [
      {
        name: 'HRADataWarehouseVirtualNetworkSubnet'
        properties: {
          addressPrefix: dataSubnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
        }        
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: gatewaySubnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: bastionSubnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: 'snet-privateendpoints'
        properties: {
          addressPrefix: privateEndpointSubnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: 'snet-functionapps'
        properties: {
          addressPrefix: functionAppSubnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          delegations: [
            {
              name: 'Microsoft.Web.serverFarms'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
    ]
  }
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: publicIpName
  location: resourceGroup().location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource localGateway 'Microsoft.Network/localNetworkGateways@2024-05-01' = {
  name: localNetworkGatewayName
  location: resourceGroup().location
  properties: {
    gatewayIpAddress: GatewayIp
    localNetworkAddressSpace: {
      addressPrefixes: [ LocalGatewayAddressPrefix ]
    }
  }
}

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2024-05-01' = {
  name: vpnGatewayName
  location: resourceGroup().location
  properties: {
    blockUpgradeOfMigratedLegacyGateways: false
    enableHighBandwidthVpnGateway: false
    isMigrateToCSES: false
    isMigratedLegacySKU: false
    packetCaptureDiagnosticState: 'None'
    enablePrivateIpAddress: false
    remoteVirtualNetworkPeerings: [
      {
        id: '/subscriptions/9ef9a127-7a6e-452e-b18d-d2e2e89ffa92/resourceGroups/rg-rsp-devcenter/providers/Microsoft.Network/virtualNetworks/vnet-dbox-rsp-uksouth/virtualNetworkPeerings/dw-devbox-link'
      }
      {
        id: '/subscriptions/b83b4631-b51b-4961-86a1-295f539c826b/resourceGroups/rg-rsp-networking-spoke-dev-uks/providers/Microsoft.Network/virtualNetworks/vnet-rsp-networking-dev-uks-spoke/virtualNetworkPeerings/dev-dw-link'
      }
    ]
    virtualNetworkGatewayMigrationStatus: {
      phase: 'None'
      state: 'None'
    }
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          publicIPAddress: {
            id: publicIp.id
          }
          subnet: {
            id: '/subscriptions/461016b5-8363-472e-81be-eef6aad08353/resourceGroups/VisualStudioOnline-4140D62E99124BBBABC390FFA33D669D/providers/Microsoft.Network/virtualNetworks/HRADataWarehouseVirtualNetwork/subnets/GatewaySubnet'
          }
        }
        type: 'Microsoft.Network/virtualNetworkGateways/ipConfigurations'
      }
    ]
    enableBgpRouteTranslationForNat: false
    disableIPSecReplayProtection: false
    sku: {
      name: 'VpnGw1'
      tier: 'VpnGw1'
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: false
    activeActive: false
    bgpSettings: {
      asn: 65515
      bgpPeeringAddress: bgpPeeringAddress
      peerWeight: 0
      bgpPeeringAddresses: [
        {
          ipconfigurationId: resourceId('Microsoft.Network/virtualNetworkGateways/ipConfigurations', vpnGatewayName, 'default')
          customBgpIpAddresses: []
        }
      ]
    }
    vpnGatewayGeneration: 'Generation1'
    allowRemoteVnetTraffic: false
    allowVirtualWanTraffic: false
  }
}

resource connection 'Microsoft.Network/connections@2024-05-01' = {
  name: connectionName
  location: resourceGroup().location
  properties: {
    authenticationType: 'PSK'
    packetCaptureDiagnosticState: 'None'
    virtualNetworkGateway1: {
      id: remoteVpnGatewayId
      properties: {}
    }
    localNetworkGateway2: {
      id: remoteLocalGatewayId
      properties: {}
    }
    connectionType: 'IPsec'
    connectionProtocol: 'IKEv2'
    routingWeight: 0
    enableBgp: false
    useLocalAzureIpAddress: false
    usePolicyBasedTrafficSelectors: false
    expressRouteGatewayBypass: false
    enablePrivateLinkFastPath: false
    dpdTimeoutSeconds: 45
    connectionMode: 'Default'
  }
}

resource vnetResource 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: vnetName
  dependsOn: [
    vnet
  ]
}

resource devboxPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: vnetResource
  name: 'devbox-dw-link'
  properties: {
    peeringSyncLevel: 'FullyInSync'
    remoteVirtualNetwork: {
      id: devboxVnetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    doNotVerifyRemoteGateways: false
    peerCompleteVnets: true
    remoteAddressSpace: {
      addressPrefixes: [ '10.0.0.0/16' ]
    }
    remoteVirtualNetworkAddressSpace: {
      addressPrefixes: [ '10.0.0.0/16' ]
    }
  }
}

resource devPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: vnetResource
  name: 'dev-dw-link'
  properties: {
    peeringSyncLevel: 'FullyInSync'
    remoteVirtualNetwork: {
      id: devVnetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    doNotVerifyRemoteGateways: false
    peerCompleteVnets: true
    remoteAddressSpace: {
      addressPrefixes: [ '10.1.0.0/19' ]
    }
    remoteVirtualNetworkAddressSpace: {
      addressPrefixes: [ '10.1.0.0/19' ]
    }
  }
}

resource managedDevopsPoolPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: vnetResource
  name: 'peerTo-vnet-rsp-networking-devopspool'
  properties: {
    peeringSyncLevel: 'FullyInSync'
    remoteVirtualNetwork: {
      id: manageddevopspoolVnetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    doNotVerifyRemoteGateways: false
    peerCompleteVnets: true
    remoteAddressSpace: {
      addressPrefixes: [ '10.1.192.0/19' ]
    }
    remoteVirtualNetworkAddressSpace: {
      addressPrefixes: [ '10.1.192.0/19' ]
    }
  }
}

// resource devopsAccount 'Microsoft.VisualStudio/account@2014-04-01-preview' = {
//   name: devopsAccountName
//   location: resourceGroup().location
//   properties: {
//     AccountURL: 'https://dev.azure.com/${devopsAccountName}/'
//   }
// }
