using '../main.network.bicep'

param parSpokeNetworks = [
  {
    subscriptionId: ''
    ipRange: '10.5.0.0/16'
    parEnvironment: 'uat'
    zoneRedundancy: true
    configurePrivateDNS: true
    devBoxPeering: false
    rgNetworking: 'rg-rsp-networking-spoke-uat-uks'
    subnets: {
      infraSubnet: {
        addressPrefix: '10.5.0.0/18'
      }
      webAppSubnet: {
        addressPrefix: '10.5.128.0/18'
      }
      appGatewaySubnet: {
        addressPrefix: '10.5.64.0/24'
      }
      privateEndPointSubnet: {
        addressPrefix: '10.5.65.0/24'
      }
    }
  }
]
