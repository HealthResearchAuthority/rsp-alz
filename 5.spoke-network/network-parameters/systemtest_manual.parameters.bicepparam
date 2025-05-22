using '../main.network.bicep'

param parSpokeNetworks = [
  {
    subscriptionId: '66482e26-764b-4717-ae2f-fab6b8dd1379'
    ipRange: '10.3.0.0/16'
    parEnvironment: 'manualtest'
    zoneRedundancy: false
    //configurePrivateDNS: true
    devBoxPeering: true
    parDevBoxVNetPeeringSubscriptionID: '9ef9a127-7a6e-452e-b18d-d2e2e89ffa92'
    parDevBoxVNetPeeringVNetName: 'vnet-dbox-rsp-uksouth'
    parDevBoxVNetPeeringResourceGroup: 'rg-rsp-devcenter'
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
