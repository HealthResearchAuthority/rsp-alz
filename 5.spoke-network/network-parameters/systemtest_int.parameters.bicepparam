using '../main.network.bicep'

param parSpokeNetworks = [
  {
    subscriptionId: ''
    ipRange: '10.4.0.0/16'
    parEnvironment: 'integrationtest'
    zoneRedundancy: false
    configurePrivateDNS: false
    devBoxPeering: false
    rgNetworking: 'rg-rsp-networking-spoke-systemtestint-uks'
    subnets: {
      infraSubnet: {
        addressPrefix: '10.4.0.0/18'
      }
      webAppSubnet: {
        addressPrefix: '10.4.128.0/18'
      }
      appGatewaySubnet: {
        addressPrefix: '10.4.64.0/24'
      }
      privateEndPointSubnet: {
        addressPrefix: '10.4.65.0/24'
      }
    }
  }
]
