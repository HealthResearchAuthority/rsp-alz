using '../main.network.bicep'

param parSubscriptionId = ''

param logAnalyticsWorkspaceId = ''

param parEnableFailover = true

param parSecondaryLocation = 'ukwest'

param parSpokeNetworks = [
  {
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
        addressPrefix: '10.7.128.0/18'
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

param parSecondarySpokeNetworks = [
  {
    ipRange: '10.17.0.0/16'
    parEnvironment: 'prod'
    zoneRedundancy: true
    configurePrivateDNS: true
    devBoxPeering: false
    rgNetworking: 'rg-rsp-networking-spoke-prod-ukw'
    subnets: {
      infraSubnet: {
        addressPrefix: '10.17.0.0/18'
      }
      webAppSubnet: {
        addressPrefix: '10.17.128.0/18'
      }
      appGatewaySubnet: {
        addressPrefix: '10.17.64.0/24'
      }
      privateEndPointSubnet: {
        addressPrefix: '10.17.65.0/24'
      }
    }
  }
]
