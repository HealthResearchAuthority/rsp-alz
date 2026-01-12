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
var remoteDbSubnetPrefix = '10.10.1.0/24'
var devboxSubnetPrefix = '10.0.0.0/24'
var devSubnetPrefix = '10.1.8.0/22'
var manualtestSubnetPrefix = '10.3.128.0/18'
var automationtestSubnetPrefix = '10.1.48.0/22'
var uatSubnetPrefix = '10.5.128.0/18'
var preprodSubnetPrefeix = '10.6.128.0/18'
var prodSubnetPrefix = '10.7.128.0/18'
var dataGatewaySubnetPrefix = '172.18.5.0/26'

var allLocalAddressRanges = [
  functionAppSubnetPrefix
  devboxSubnetPrefix
  dataSubnetPrefix
  devSubnetPrefix
  manualtestSubnetPrefix
  automationtestSubnetPrefix
  uatSubnetPrefix
  preprodSubnetPrefeix
  prodSubnetPrefix
  dataGatewaySubnetPrefix
]

module functionAppsNSG '../../shared/bicep/network/nsg.bicep' = {
  name: 'functionapps-nsg'
  scope: resourceGroup('VisualStudioOnline-4140D62E99124BBBABC390FFA33D669D')
  params: {
    name: 'nsg-function-apps-dev-uks'
    location: resourceGroup().location
    tags: {}
    securityRules: []
  }
}

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
          networkSecurityGroup: {
            id: functionAppsNSG.outputs.nsgId
          }
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
      {
        name: 'DataGatewaySubnet'
        properties: {
          addressPrefix: dataGatewaySubnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          delegations: [
            {
              name: 'Microsoft.PowerPlatform/vnetaccesslinks'
              properties: {
                serviceName: 'Microsoft.PowerPlatform/vnetaccesslinks'
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
    usePolicyBasedTrafficSelectors: true
    expressRouteGatewayBypass: false
    enablePrivateLinkFastPath: false
    dpdTimeoutSeconds: 45
    connectionMode: 'Default'
    trafficSelectorPolicies: [for localAddressRange in allLocalAddressRanges : {
      localAddressRanges: [
        localAddressRange
    ]
      remoteAddressRanges: [
        remoteDbSubnetPrefix
      ]
    }]
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
