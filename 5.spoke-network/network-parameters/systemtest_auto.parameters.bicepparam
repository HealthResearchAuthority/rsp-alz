using '../main.network.bicep'

param parSpokeNetworks = [
  {
    subscriptionId: '75875981-b04d-42c7-acc5-073e2e5e2e65'
    ipRange: '10.1.32.0/19'
    parEnvironment: 'automationtest'
    zoneRedundancy: false
    //configurePrivateDNS: false
    devBoxPeering: false
    rgNetworking: 'rg-rsp-networking-spoke-systemtestauto-uks'
    subnets: {
      infraSubnet: {
        addressPrefix: '10.1.32.0/20'
      }
      webAppSubnet: {
        addressPrefix: '10.1.48.0/22'
      }
      appGatewaySubnet: {
        addressPrefix: '10.1.63.0/24'
      }
      privateEndPointSubnet: {
        addressPrefix: '10.1.62.0/24'
      }
    }
  }
]

param parEnableFailover = true

param parSecondaryLocation = 'ukwest'

param parSecondarySpokeNetworks = [
  {
    subscriptionId: '75875981-b04d-42c7-acc5-073e2e5e2e65'
    ipRange: '10.11.32.0/19' // Secondary region IP range: 10.11.32.0 – 10.11.63.255
    parEnvironment: 'automationtest'
    zoneRedundancy: false
    devBoxPeering: false
    rgNetworking: 'rg-rsp-networking-spoke-systemtestauto-ukw'
    subnets: {
      infraSubnet: {
        addressPrefix: '10.11.32.0/20' // 4096 IPs
      }
      webAppSubnet: {
        addressPrefix: '10.11.48.0/22' // 1024 IPs
      }
      appGatewaySubnet: {
        addressPrefix: '10.11.63.0/24' // 256 IPs
      }
      privateEndPointSubnet: {
        addressPrefix: '10.11.62.0/24' // 256 IPs
      }
    }
  }
]
