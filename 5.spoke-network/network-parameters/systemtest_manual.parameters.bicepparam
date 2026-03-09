using '../main.network.bicep'

param parSpokeNetworks = [
  {
    subscriptionId: '66482e26-764b-4717-ae2f-fab6b8dd1379'
    ipRange: '10.3.0.0/16'
    parEnvironment: 'manualtest'
    zoneRedundancy: false
    //configurePrivateDNS: true
    devBoxPeering: false
    rgNetworking: 'rg-rsp-networking-spoke-systemtest-uks'
    subnets: {
      infraSubnet: {
        addressPrefix: '10.3.0.0/18'
      }
      webAppSubnet: {
        addressPrefix: '10.3.128.0/18'
      }
      appGatewaySubnet: {
        addressPrefix: '10.3.64.0/24'
      }
      privateEndPointSubnet: {
        addressPrefix: '10.3.65.0/24'
      }
    }
  }
]

param logAnalyticsWorkspaceId =  ''

param parEnableFailover = true

param parSecondaryLocation = 'ukwest'

param parSecondarySpokeNetworks = [
  {
    subscriptionId: '66482e26-764b-4717-ae2f-fab6b8dd1379'
    ipRange: '10.13.0.0/16' // Secondary region IP range: 10.13.0.0 – 10.13.255.255
    parEnvironment: 'manualtest'
    zoneRedundancy: false
    devBoxPeering: false
    rgNetworking: 'rg-rsp-networking-spoke-systemtest-ukw'
    subnets: {
      infraSubnet: {
        addressPrefix: '10.13.0.0/18' // 16384 IPs
      }
      webAppSubnet: {
        addressPrefix: '10.13.128.0/18' // 16384 IPs
      }
      appGatewaySubnet: {
        addressPrefix: '10.13.64.0/24' // 256 IPs
      }
      privateEndPointSubnet: {
        addressPrefix: '10.13.65.0/24' // 256 IPs
      }
    }
  }
]
