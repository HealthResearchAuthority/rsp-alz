using '../main.network.bicep'

param logAnalyticsWorkspaceId = ''

param parEnableFailover = true

param parSecondaryLocation = 'ukwest'

param parSpokeNetworks = [
  {
    subscriptionId: 'b83b4631-b51b-4961-86a1-295f539c826b'
    ipRange: '10.1.0.0/19' // 8192 IPs: 10.1.0.0 – 10.1.31.255
    parEnvironment: 'dev'
    zoneRedundancy: false
    //configurePrivateDNS: true
    devBoxPeering: true
    rgNetworking: 'rg-rsp-networking-spoke-dev-uks'
    subnets: {
      infraSubnet: {
        addressPrefix: '10.1.0.0/21' // 2048 IPs
      }
      webAppSubnet: {
        addressPrefix: '10.1.8.0/22' // 1024 IPs
      }
      appGatewaySubnet: {
        addressPrefix: '10.1.12.0/27' // 32 IPs
      }
      privateEndPointSubnet: {
        addressPrefix: '10.1.12.32/27' // 32 IPs
      }
    }
  }
]

param parSecondarySpokeNetworks = [
  {
    subscriptionId: 'b83b4631-b51b-4961-86a1-295f539c826b'
    ipRange: '10.11.0.0/19' // 8192 IPs: 10.11.0.0 – 10.11.31.255
    parEnvironment: 'dev'
    zoneRedundancy: false
    //configurePrivateDNS: true
    devBoxPeering: false
    rgNetworking: 'rg-rsp-networking-spoke-dev-ukw'
    subnets: {
      infraSubnet: {
        addressPrefix: '10.11.0.0/21' // 2048 IPs
      }
      webAppSubnet: {
        addressPrefix: '10.11.8.0/22' // 1024 IPs
      }
      appGatewaySubnet: {
        addressPrefix: '10.11.12.0/27' // 32 IPs
      }
      privateEndPointSubnet: {
        addressPrefix: '10.11.12.32/27' // 32 IPs
      }
    }
  }
]

