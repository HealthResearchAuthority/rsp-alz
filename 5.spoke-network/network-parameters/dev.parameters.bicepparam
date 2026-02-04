using '../main.network.bicep'

param logAnalyticsWorkspaceId = ''

param parSpokeNetworks = [
  {
    subscriptionId: 'b83b4631-b51b-4961-86a1-295f539c826b'
    ipRange: '10.10.0.0/16' // 65536 IPs: 10.10.0.0 – 10.10.255.255
    parEnvironment: 'dev'
    zoneRedundancy: false
    //configurePrivateDNS: true
    devBoxPeering: true
    rgNetworking: 'rg-rsp-networking-spoke-dev-uks'
    subnets: {
      infraSubnet: {
        addressPrefix: '10.10.0.0/18' // 16384 IPs
      }
      webAppSubnet: {
        addressPrefix: '10.10.128.0/18' // 16384 IPs
      }
      appGatewaySubnet: {
        addressPrefix: '10.10.64.0/24' // 256 IPs
      }
      privateEndPointSubnet: {
        addressPrefix: '10.10.65.0/24' // 256 IPs
      }
    }
  }
]

