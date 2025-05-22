using '../main.network.bicep'

param parSpokeNetworks = [
  {
    subscriptionId: '75875981-b04d-42c7-acc5-073e2e5e2e65'
    ipRange: '10.1.32.0/19'
    parEnvironment: 'automationtest'
    zoneRedundancy: false
    //configurePrivateDNS: false
    devBoxPeering: true
    rgNetworking: 'rg-rsp-networking-spoke-systemtestauto-uks'
    parDevBoxVNetPeeringSubscriptionID: '9ef9a127-7a6e-452e-b18d-d2e2e89ffa92'
    parDevBoxVNetPeeringVNetName: 'vnet-dbox-rsp-uksouth'
    parDevBoxVNetPeeringResourceGroup: 'rg-rsp-devcenter'
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
