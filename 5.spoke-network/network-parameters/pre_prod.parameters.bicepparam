using '../main.network.bicep'

param logAnalyticsWorkspaceId = ''

param parEnableFailover = true

param parSecondaryLocation = 'ukwest'

param parSpokeNetworks = [
  {
    subscriptionId: 'be1174fc-09c8-470f-9409-d0054ab9586a'
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

param parSecondarySpokeNetworks = [
  {
    subscriptionId: 'be1174fc-09c8-470f-9409-d0054ab9586a'
    ipRange: '10.16.0.0/16' // Secondary region VNet for preprod
    parEnvironment: 'preprod'
    zoneRedundancy: true
    configurePrivateDNS: true
    devBoxPeering: false
    rgNetworking: 'rg-rsp-networking-spoke-preprod-ukw'
    subnets: {
      infraSubnet: {
        addressPrefix: '10.16.0.0/18'
      }
      webAppSubnet: {
        addressPrefix: '10.16.128.0/18'
      }
      appGatewaySubnet: {
        addressPrefix: '10.16.64.0/24'
      }
      privateEndPointSubnet: {
        addressPrefix: '10.16.65.0/24'
      }
    }
  }
]
