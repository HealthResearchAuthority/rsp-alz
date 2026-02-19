using '../main.network.bicep'

param logAnalyticsWorkspaceId = ''

param parSpokeNetworks = [
  {
    subscriptionId: '75875981-b04d-42c7-acc5-073e2e5e2e65'
    ipRange: '10.2.0.0/16' // 65536 IPs: 10.2.0.0 – 10.2.255.255
    parEnvironment: 'automationtest'
    zoneRedundancy: false
    //configurePrivateDNS: false
    devBoxPeering: false
    rgNetworking: 'rg-rsp-networking-spoke-systemtestauto-uks'
    subnets: {
      infraSubnet: {
        addressPrefix: '10.2.0.0/18' // 16384 IPs
      }
      webAppSubnet: {
        addressPrefix: '10.2.128.0/18' // 16384 IPs
      }
      appGatewaySubnet: {
        addressPrefix: '10.2.64.0/24' // 256 IPs
      }
      privateEndPointSubnet: {
        addressPrefix: '10.2.65.0/24' // 256 IPs
      }
    }
  }
]
