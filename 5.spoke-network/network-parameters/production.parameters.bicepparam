using '../main.network.bicep'

param logAnalyticsWorkspaceId = ''

param parEnableFailover = true

param parSecondaryLocation = 'ukwest'

param parSpokeNetworks = [
  {
    subscriptionId: 'd27a0dcc-453d-4bfa-9c3d-1447c6ea0119'
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
    subscriptionId: 'd27a0dcc-453d-4bfa-9c3d-1447c6ea0119'
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

// DevBox VNet Configuration for Secondary Region Peering
param parDevBoxVNetSubscriptionId = '9ef9a127-7a6e-452e-b18d-d2e2e89ffa92'
param parDevBoxVNetResourceGroup = 'rg-rsp-devcenter'
param parDevBoxVNetName = 'vnet-dbox-rsp-uksouth'
