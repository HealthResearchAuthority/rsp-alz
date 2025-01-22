using '../main.network.bicep'

param parSpokeNetworks = [
  {
    subscriptionId: ''
    ipRange: '10.6.0.0/16'
    parEnvironment: 'preprod'
    zoneRedundancy: true
    configurePrivateDNS: true
    devBoxPeering: false
    rgNetworking: 'rg-rsp-networking-spoke-preprod-uks'
    subnets: {
      infraSubnet: {
        addressPrefix: '10.6.0.0/18'
      }
      webAppSubnet: {
        addressPrefix: '10.6.128.0/18'
      }
      appGatewaySubnet: {
        addressPrefix: '10.6.64.0/24'
      }
      privateEndPointSubnet: {
        addressPrefix: '10.6.65.0/24'
      }
    }
  }
]
