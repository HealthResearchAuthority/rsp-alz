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

@description('Name of Azure DevOps account')
param devopsAccountName string

@description('Remote VNet ID for Devbox')
param devboxVnetId string

@description('Remote VNet ID for Manual Test')
param manualTestVnetId string

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

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [ vnetAddressPrefix ]
    }
    privateEndpointVNetPolicies: 'Disabled'
  }
}

resource datawarehouseSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  parent: vnet
  name: 'HRADataWarehouseVirtualNetworkSubnet'
  properties: {
    addressPrefix: dataSubnetPrefix
    privateEndpointNetworkPolicies: 'Disabled'
  }
}

resource gatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  parent: vnet
  name: 'GatewaySubnet'
  properties: {
    addressPrefix: gatewaySubnetPrefix
    privateEndpointNetworkPolicies: 'Disabled'
  }
}

resource bastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  parent: vnet
  name: 'AzureBastionSubnet'
  properties: {
    addressPrefix: bastionSubnetPrefix
    privateEndpointNetworkPolicies: 'Disabled'
  }
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: publicIpName
  location: resourceGroup().location
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
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
            id: gatewaySubnet.id
          }
        }
        type: 'Microsoft.Network/virtualNetworkGateways/ipConfigurations'
      }
    ]
    natRules: []
    virtualNetworkGatewayPolicyGroups: []
    enableBgpRouteTranslationForNat: false
    disableIPSecReplayProtection: false
    sku: {
      name: 'Basic'
      tier: 'Basic'
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
    ipsecPolicies: []
    trafficSelectorPolicies: []
    expressRouteGatewayBypass: false
    enablePrivateLinkFastPath: false
    dpdTimeoutSeconds: 0
    connectionMode: 'Default'
    gatewayCustomBgpIpAddresses: []
  }
}

resource devboxPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: vnet
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

resource manualTestPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: vnet
  name: 'manualtest-dw-link'
  properties: {
    peeringSyncLevel: 'FullyInSync'
    remoteVirtualNetwork: {
      id: manualTestVnetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    doNotVerifyRemoteGateways: false
    peerCompleteVnets: true
    remoteAddressSpace: {
      addressPrefixes: [ '10.2.0.0/16' ]
    }
    remoteVirtualNetworkAddressSpace: {
      addressPrefixes: [ '10.2.0.0/16' ]
    }
  }
}

resource devopsAccount 'Microsoft.VisualStudio/account@2014-04-01-preview' = {
  name: devopsAccountName
  location: resourceGroup().location
  properties: {
    AccountURL: 'https://dev.azure.com/${devopsAccountName}/'
  }
}
