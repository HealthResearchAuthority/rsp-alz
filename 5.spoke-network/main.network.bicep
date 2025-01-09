targetScope = 'subscription'

// ------------------
// PARAMETERS
// ------------------

@description('The location where the resources will be created.')
param location string = deployment().location

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

@description('Central Log Analytics Workspace ID')
param logAnalyticsWorkspaceId string = '/subscriptions/8747cd7f-1a06-4fe4-9dbb-24f612b9dd5a/resourceGroups/rg-hra-operationsmanagement/providers/Microsoft.OperationalInsights/workspaces/hra-rsp-log-analytics'

@description('Optional, default value is true. If true, Azure Policies will be deployed')
param deployAzurePolicies bool = true

type spokesType = ({
  @description('SubscriptionId for spokeNetworking')
  subscriptionId: string
  @description('Address prefix (CIDR) for spokeNetworking')
  ipRange: string
  @description('Name of environment')
  parEnvironment: string
  @description('Name of networking resource group')
  rgNetworking: string
  @description('Boolean to indicate deploy Zone redundancy')
  zoneRedundancy: bool
  @description('Boolean to indicate deploy private DNS or not')
  configurePrivateDNS: bool
  @description('Boolean to indicate Spoke Vnet Peering with DevBox Vnet')
  devBoxPeering: bool
  @description('Subnet information')
  subnets: object
})[]

param parSpokeNetworks spokesType = [
  // {
  //   subscriptionId: 'b83b4631-b51b-4961-86a1-295f539c826b' //Development
  //   ipRange: '10.2.0.0/16'
  //   parEnvironment: 'dev'
  //   workloadName: 'container-app'
  //   zoneRedundancy: false
  //   ddosProtectionEnabled: 'Disabled'
  //   containerRegistryTier: 'Premium'
  //   deploy: true
  //   configurePrivateDNS: true
  //   devBoxPeering: true
  //   rgNetworking: 'rg-rsp-networking-spoke-dev-uks'
  //   rgapplications: 'rg-rsp-applications-spoke-dev-uks'
  //   rgSharedServices: 'rg-rsp-sharedservices-spoke-dev-uks'
  //   rgStorage: 'rg-rsp-storage-spoke-dev-uks'
  //   deployWebAppSlot: false
  //   subnets: {
  //     infraSubnet: {
  //       addressPrefix: '10.2.0.0/18'
  //     }
  //     webAppSubnet: {
  //       addressPrefix: '10.2.128.0/18'
  //     }
  //     appGatewaySubnet: {
  //       addressPrefix: '10.2.64.0/24'
  //     }
  //     privateEndPointSubnet: {
  //       addressPrefix: '10.2.65.0/24'
  //     }
  //   }
  // }
  {
    subscriptionId: '66482e26-764b-4717-ae2f-fab6b8dd1379' //System Test Manual
    ipRange: '10.3.0.0/16'
    parEnvironment: 'manualtest'
    zoneRedundancy: false
    configurePrivateDNS: true
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
  // {
  //   subscriptionId: '75875981-b04d-42c7-acc5-073e2e5e2e65' //System Test Automated
  //   ipRange: '10.1.32.0/19'
  //   parEnvironment: 'automationtest'
  //   workloadName: 'container-app'
  //   zoneRedundancy: false
  //   ddosProtectionEnabled: 'Disabled'
  //   containerRegistryTier: 'Premium'
  //   deploy: false
  //   configurePrivateDNS: false
  //   rgNetworking: 'rg-rsp-networking-spoke-systemtestauto-uks'
  //   rgapplications: 'rg-rsp-applications-spoke-systemtestauto-uks'
  //   rgSharedServices: 'rg-rsp-sharedservices-spoke-systemtestauto-uks'
  //   rgStorage: 'rg-rsp-storage-spoke-systemtestauto-uks'
  //   deployWebAppSlot: false
  //   devBoxPeering: false
  //   subnets: {
  //     infraSubnet: {
  //       addressPrefix: '10.1.32.0/20'
  //     }
  //     appGatewaySubnet: {
  //       addressPrefix: '10.1.63.0/24'
  //     }
  //     webAppSubnet: {
  //       addressPrefix: '10.1.48.0/22'
  //     }
  //     privateEndPointSubnet: {
  //       addressPrefix: '10.1.62.0/24'
  //     }  
  //   }
  // }
  // {
  //   subscriptionId: 'c9d1b222-c47a-43fc-814a-33083b8d3375' //System Test Integration
  //   ipRange: '10.4.0.0/16'
  //   parEnvironment: 'integrationtest'
  //   workloadName: 'container-app'
  //   zoneRedundancy: false
  //   ddosProtectionEnabled: 'Disabled'
  //   containerRegistryTier: 'Premium'
  //   deploy: false
  //   configurePrivateDNS: false
  // rgNetworking: 'rg-rsp-networking-spoke-systemtestint-uks'
    // rgapplications: 'rg-rsp-applications-spoke-systemtestint-uks'
    // rgSharedServices: 'rg-rsp-sharedservices-spoke-systemtestint-uks'
    // rgStorage: 'rg-rsp-storage-spoke-systemtestint-uks'
  //   subnets: {
  //     infraSubnet: {
  //       addressPrefix: '10.4.0.0/18'
  //     }
  //     appGatewaySubnet: {
  //       addressPrefix: '10.4.64.0/24'
  //     }
  //     privateEndPointSubnet: {
  //       addressPrefix: '10.4.65.0/24'
  //     }
  //   }
  // }
  // {
  //   subscriptionId: '' //UAT
  //   ipRange: '10.5.0.0/16'
  //   parEnvironment: 'uat'
  //   workloadName: 'container-app'
  //   zoneRedundancy: true
  //   ddosProtectionEnabled: 'Enabled'
  //   containerRegistryTier: 'Premium'
  //   deploy: false
  //   configurePrivateDNS: true
  // rgNetworking: 'rg-rsp-networking-spoke-uat-uks'
    // rgapplications: 'rg-rsp-applications-spoke-uat-uks'
    // rgSharedServices: 'rg-rsp-sharedservices-spoke-uat-uks'
    // rgStorage: 'rg-rsp-storage-spoke-uat-uks'
  //   subnets: {
  //     infraSubnet: {
  //       addressPrefix: '10.5.0.0/18'
  //     }
  //     appGatewaySubnet: {
  //       addressPrefix: '10.5.64.0/24'
  //     }
  //     privateEndPointSubnet: {
  //       addressPrefix: '10.5.65.0/24'
  //     }
  //   }
  // }
  // {
  //   subscriptionId: '' //PreProd
  //   ipRange: '10.6.0.0/16'
  //   parEnvironment: 'preprod'
  //   workloadName: 'container-app'
  //   zoneRedundancy: true
  //   ddosProtectionEnabled: 'Enabled'
  //   containerRegistryTier: 'Premium'
  //   deploy: false
  //   configurePrivateDNS: true
  // rgNetworking: 'rg-rsp-networking-spoke-preprod-uks'
    // rgapplications: 'rg-rsp-applications-spoke-preprod-uks'
    // rgSharedServices: 'rg-rsp-sharedservices-spoke-preprod-uks'
    // rgStorage: 'rg-rsp-storage-spoke-preprod-uks'
  //   subnets: {
  //     infraSubnet: {
  //       addressPrefix: '10.6.0.0/18'
  //     }
  //     appGatewaySubnet: {
  //       addressPrefix: '10.6.64.0/24'
  //     }
  //     privateEndPointSubnet: {
  //       addressPrefix: '10.6.65.0/24'
  //     }
  //   }
  // }
  // {
  //   subscriptionId: '' //Prod
  //   ipRange: '10.7.0.0/16'
  //   parEnvironment: 'prod'
  //   workloadName: 'container-app'
  //   zoneRedundancy: true
  //   ddosProtectionEnabled: 'Enabled'
  //   containerRegistryTier: 'Premium'
  //   deploy: false
  //   configurePrivateDNS: true
  // rgNetworking: 'rg-rsp-networking-spoke-prod-uks'
    // rgapplications: 'rg-rsp-applications-spoke-prod-uks'
    // rgSharedServices: 'rg-rsp-sharedservices-spoke-prod-uks'
    // rgStorage: 'rg-rsp-storage-spoke-prod-uks'
  //   subnets: {
  //     infraSubnet: {
  //       addressPrefix: '10.7.0.0/18'
  //     }
  //     appGatewaySubnet: {
  //       addressPrefix: '10.7.64.0/24'
  //     }
  //     privateEndPointSubnet: {
  //       addressPrefix: '10.7.65.0/24'
  //     }
  //   }
  // }
]

module networkingRG '../shared/bicep/resourceGroup.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  name: take('networkingRG-${deployment().name}', 64)
  scope: subscription(parSpokeNetworks[i].subscriptionId)
  params:{
    parLocation: location
    parResourceGroupName: parSpokeNetworks[i].rgNetworking
  }
}]

module networkingnaming '../shared/bicep/naming/naming.module.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  name: take('03-sharedNamingDeployment-${deployment().name}', 64)
  scope: resourceGroup(parSpokeNetworks[i].subscriptionId, parSpokeNetworks[i].rgNetworking)
  params: {
    uniqueId: uniqueString(networkingRG[i].outputs.outResourceGroupId)
    environment: parSpokeNetworks[i].parEnvironment
    workloadName: 'networking'
    location: location
  }
}]

module spoke 'modules/02-spoke/deploy.spoke.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  name: take('spoke-${deployment().name}-deployment-${i}', 64)
  scope: subscription(parSpokeNetworks[i].subscriptionId)
  params: {
    location: location
    tags: tags
    spokeApplicationGatewaySubnetAddressPrefix: parSpokeNetworks[i].subnets.appGatewaySubnet.addressPrefix
    spokeInfraSubnetAddressPrefix: parSpokeNetworks[i].subnets.infraSubnet.addressPrefix
    spokePrivateEndpointsSubnetAddressPrefix: parSpokeNetworks[i].subnets.privateEndPointSubnet.addressPrefix
    spokeWebAppSubnetAddressPrefix: parSpokeNetworks[i].subnets.webAppSubnet.addressPrefix
    spokeVNetAddressPrefixes: [parSpokeNetworks[i].ipRange]
    deployAzurePolicies: deployAzurePolicies
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    resourcesNames: networkingnaming[i].outputs.resourcesNames
    spokeNetworkingRGName: parSpokeNetworks[i].rgNetworking
  }
}]

// ------------------
// OUTPUTS
// ------------------

@description('The resource ID of the Spoke Virtual Network.')
output spokeVNetIds array = [for i in range(0, length(parSpokeNetworks)): {
  Name: spoke[i].outputs.spokeVNetId
}]

@description('The name of the Spoke Virtual Network.')
output spokeVnetNames array = [for i in range(0, length(parSpokeNetworks)): {
  Name: spoke[i].outputs.spokeVNetName
}]

@description('The resource ID of the Spoke Infrastructure Subnet.')
output spokeInfraSubnetIds array = [for i in range(0, length(parSpokeNetworks)): {
  Name: spoke[i].outputs.spokeInfraSubnetId
}]

@description('The name of the Spoke Infrastructure Subnet.')
output spokeInfraSubnetNames array = [for i in range(0, length(parSpokeNetworks)): {
  Name: spoke[i].outputs.spokeInfraSubnetName
}]

@description('The name of the Spoke Private Endpoints Subnet.')
output spokePrivateEndpointsSubnetNames array = [for i in range(0, length(parSpokeNetworks)): {
  Name: spoke[i].outputs.spokePrivateEndpointsSubnetName
}]

@description('The resource ID of the Spoke Application Gateway Subnet. If "spokeApplicationGatewaySubnetAddressPrefix" is empty, the subnet will not be created and the value returned is empty.')
output spokeApplicationGatewaySubnetIds array = [for i in range(0, length(parSpokeNetworks)): {
  Name: spoke[i].outputs.spokeApplicationGatewaySubnetId
}]

@description('The name of the Spoke Application Gateway Subnet. If "spokeApplicationGatewaySubnetAddressPrefix" is empty, the subnet will not be created and the value returned is empty.')
output spokeApplicationGatewaySubnetNames array = [for i in range(0, length(parSpokeNetworks)): {
  Name: spoke[i].outputs.spokeApplicationGatewaySubnetName
}]
