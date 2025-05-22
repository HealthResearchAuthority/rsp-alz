using '../main.network.bicep'

param parSpokeNetworks = [
  {
    subscriptionId: 'b83b4631-b51b-4961-86a1-295f539c826b'
    ipRange: '10.1.0.0/19' // 8192 IPs: 10.1.0.0 – 10.1.31.255
    parEnvironment: 'dev'
    zoneRedundancy: false
    //configurePrivateDNS: true
    devBoxPeering: true
    rgNetworking: 'rg-rsp-networking-spoke-dev-uks'
    parDevBoxVNetPeeringSubscriptionID: '9ef9a127-7a6e-452e-b18d-d2e2e89ffa92'
    parDevBoxVNetPeeringVNetName: 'vnet-dbox-rsp-uksouth'
    parDevBoxVNetPeeringResourceGroup: 'rg-rsp-devcenter'
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
