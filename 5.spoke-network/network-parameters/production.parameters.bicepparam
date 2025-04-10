using '../main.network.bicep'

param parSpokeNetworks = [
  {
    subscriptionId: ''
    ipRange: '10.7.0.0/16'
    parEnvironment: 'prod'
    zoneRedundancy: true
    configurePrivateDNS: true
    devBoxPeering: false
    rgNetworking: 'rg-rsp-networking-spoke-prod-uks'
    subnets: {
      infraSubnet: {
        addressPrefix: '10.7.0.0/18'
      }
      webAppSubnet: {
        addressPrefix: '10.3.128.0/18'
      }
      appGatewaySubnet: {
        addressPrefix: '10.7.64.0/24'
      }
      privateEndPointSubnet: {
        addressPrefix: '10.7.65.0/24'
      }
    }
  }
]
