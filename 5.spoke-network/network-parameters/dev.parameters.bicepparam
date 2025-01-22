using '../main.network.bicep'

param parSpokeNetworks = [
  {
    subscriptionId: 'b83b4631-b51b-4961-86a1-295f539c826b'
    ipRange: '10.2.0.0/16'
    parEnvironment: 'dev'
    zoneRedundancy: false
    configurePrivateDNS: true
    devBoxPeering: true
    rgNetworking: 'rg-rsp-networking-spoke-dev-uks'
    subnets: {
      infraSubnet: {
        addressPrefix: '10.2.0.0/18'
      }
      webAppSubnet: {
        addressPrefix: '10.2.128.0/18'
      }
      appGatewaySubnet: {
        addressPrefix: '10.2.64.0/24'
      }
      privateEndPointSubnet: {
        addressPrefix: '10.2.65.0/24'
      }
    }
  }
]
