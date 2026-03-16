using '../main.network.bicep'

param parSubscriptionId = ''

param logAnalyticsWorkspaceId = ''

param parSpokeNetworks = [
  {
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

param parEnableFailover = true

param parSecondaryLocation = 'ukwest'

param parSecondarySpokeNetworks = [
  {
    ipRange: '10.15.0.0/16' // Secondary region IP range: 10.15.0.0 – 10.15.255.255
    parEnvironment: 'uat'
    zoneRedundancy: true
    devBoxPeering: false
    rgNetworking: 'rg-rsp-networking-spoke-uat-ukw'
    subnets: {
      infraSubnet: {
        addressPrefix: '10.15.0.0/18' // 16384 IPs
      }
      webAppSubnet: {
        addressPrefix: '10.15.128.0/18' // 16384 IPs
      }
      appGatewaySubnet: {
        addressPrefix: '10.15.64.0/24' // 256 IPs
      }
      privateEndPointSubnet: {
        addressPrefix: '10.15.65.0/24' // 256 IPs
      }
    }
  }
]
