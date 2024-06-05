targetScope = 'subscription'

// ------------------
//    PARAMETERS
// ------------------
@description('The name of the workload that is being deployed. Up to 10 characters long.')
@minLength(2)
@maxLength(10)
param workloadName string = 'aca'

@description('The location where the resources will be created.')
param location string =  deployment().location

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

//Hub
param hubVNetId string = '/subscriptions/15642d2a-27a2-4ee8-9eba-788bf7223d95/resourceGroups/rg-hra-connectivity/providers/Microsoft.Network/virtualHubs/vhub-rsp-uksouth'

@description('Virtual Appliance IP Address. Firewall IP Address')
param networkApplianceIpAddress string = '10.0.64.4' //Hub firewall IP Address


// Spoke
@description('Optional. The name of the resource group to create the resources in. If set, it overrides the name generated by the template.')
param spokeResourceGroupName string = ''

@description('Central Log Analytics Workspace ID')
param logAnalyticsWorkspaceId string = '/subscriptions/8747cd7f-1a06-4fe4-9dbb-24f612b9dd5a/resourceGroups/rg-hra-operationsmanagement/providers/Microsoft.OperationalInsights/workspaces/hra-rsp-log-analytics'

@description('Enable or disable the deployment of the Hello World Sample App. If disabled, the Application Gateway will not be deployed.')
param deployHelloWorldSample bool

@description('The FQDN of the Application Gateway. Must match the TLS Certificate.')
param applicationGatewayFqdn string

@description('Enable or disable Application Gateway Certificate (PFX).')
param enableApplicationGatewayCertificate bool

@description('The name of the certificate key to use for Application Gateway certificate.')
param applicationGatewayCertificateKeyName string

// @description('Enable usage and telemetry feedback to Microsoft.')
// param enableTelemetry bool = true

// @description('Optional, default value is true. If true, any resources that support AZ will be deployed in all three AZ. However if the selected region is not supporting AZ, this parameter needs to be set to false.')
// param deployZoneRedundantResources bool = true


type spokesType = ({
  @description('SubscriptionId for spokeNetworking')
  subscriptionId: string

  @description('Address prefix (CIDR) for spokeNetworking')
  ipRange: string

  @description('managementGroup for subscription placement')
  workloadName: string

  @description('Subnet information')
  subnets: object

  @description('Name of environment')
  parEnvironment: string

  @description('Name of environment')
  rgSpokeName: string

  @description('Name of environment')
  zoneRedundancy: bool

  @description('Name of environment. Allowed Valued: "Disabled","Enabled", "VirtualNetworkInherited", "null"')
  ddosProtectionEnabled: string

  @description('Name of environment. Allowed Valued: "Basic","Standard", "Premium"')
  containerRegistryTier: string

  @description('Boolean variable to indicate deploy this spoke or not')
  deploy: bool

  @description('Boolean to indicate deploy private DNS or not')
  configurePrivateDNS: bool
  
})[]

@description('Optional, default value is true. If true, Azure Policies will be deployed')
param deployAzurePolicies bool = true

param parSpokeNetworks spokesType = [
  {
    subscriptionId: 'b83b4631-b51b-4961-86a1-295f539c826b' //Development
    ipRange: '10.1.0.0/16'
    parEnvironment: 'dev'
    workloadName: 'container-app'
    zoneRedundancy: false
    ddosProtectionEnabled: 'Disabled'
    containerRegistryTier: 'Premium'
    deploy: true
    configurePrivateDNS: true
    rgSpokeName: !empty(spokeResourceGroupName) ? spokeResourceGroupName : 'rg-rsp-${workloadName}-spoke-dev-uks'
    subnets: {
      infraSubnet: {
        addressPrefix: '10.1.0.0/18'
      }
      appGatewaySubnet: {
        addressPrefix: '10.1.64.0/24'
      }
      privateEndPointSubnet: {
        addressPrefix: '10.1.65.0/24'
      }
    }
  }
  // {
  //   subscriptionId: '66482e26-764b-4717-ae2f-fab6b8dd1379' //System Test Manual
  //   ipRange: '10.2.0.0/16'
  //   parEnvironment: 'manualtest'
  //   workloadName: 'container-app'
  //   zoneRedundancy: false
  //   ddosProtectionEnabled: 'Disabled'
  //   containerRegistryTier: 'Premium'
  //   deploy: false
  //   configurePrivateDNS: false
  //   rgSpokeName: !empty(spokeResourceGroupName) ? spokeResourceGroupName : 'rg-rsp-${workloadName}-spoke-manualtest-uks'
  //   subnets: {
  //     infraSubnet: {
  //       addressPrefix: '10.2.0.0/18'
  //     }
  //     appGatewaySubnet: {
  //       addressPrefix: '10.2.64.0/24'
  //     }
  //     privateEndPointSubnet: {
  //       addressPrefix: '10.2.65.0/24'
  //     }
  //   }
  // }
  // {
  //   subscriptionId: '75875981-b04d-42c7-acc5-073e2e5e2e65' //System Test Automated
  //   ipRange: '10.3.0.0/16'
  //   parEnvironment: 'automationtest'
  //   workloadName: 'container-app'
  //   zoneRedundancy: false
  //   ddosProtectionEnabled: 'Disabled'
  //   containerRegistryTier: 'Premium'
  //   deploy: false
  //   configurePrivateDNS: false
  //   rgSpokeName: !empty(spokeResourceGroupName) ? spokeResourceGroupName : 'rg-rsp-${workloadName}-spoke-automationtest-uks'
  //   subnets: {
  //     infraSubnet: {
  //       addressPrefix: '10.3.0.0/18'
  //     }
  //     appGatewaySubnet: {
  //       addressPrefix: '10.3.64.0/24'
  //     }
  //     privateEndPointSubnet: {
  //       addressPrefix: '10.3.65.0/24'
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
  //   rgSpokeName: !empty(spokeResourceGroupName) ? spokeResourceGroupName : 'rg-rsp-${workloadName}-spoke-integrationtest-uks'
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
  //   rgSpokeName: !empty(spokeResourceGroupName) ? spokeResourceGroupName : 'rg-rsp-${workloadName}-spoke-uat-uks'
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
  //   rgSpokeName: !empty(spokeResourceGroupName) ? spokeResourceGroupName : 'rg-rsp-${workloadName}-spoke-preprod-uks'
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
  //   rgSpokeName: !empty(spokeResourceGroupName) ? spokeResourceGroupName : 'rg-rsp-${workloadName}-spoke-prod-uks'
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

// ------------------
// VARIABLES
// ------------------

var varVirtualHubResourceGroup = (!empty(hubVNetId) && contains(hubVNetId, '/providers/Microsoft.Network/virtualHubs/') ? split(hubVNetId, '/')[4] : '')
var varVirtualHubSubscriptionId = (!empty(hubVNetId) && contains(hubVNetId, '/providers/Microsoft.Network/virtualHubs/') ? split(hubVNetId, '/')[2] : '')
var varHubVirtualNetworkName = (!empty(hubVNetId) && contains(hubVNetId, '/providers/Microsoft.Network/virtualHubs/') ? split(hubVNetId, '/')[8] : '')

// ------------------
// RESOURCES
// ------------------

resource spokeResourceGroup 'Microsoft.Resources/resourceGroups@2020-06-01' = [for i in range(0, length(parSpokeNetworks)): {
  name: parSpokeNetworks[i].rgSpokeName
  location: location
  tags: tags
}]

module spoke 'modules/02-spoke/deploy.spoke.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  name: take('spoke-${deployment().name}-deployment-${i}', 64)
  scope: subscription(parSpokeNetworks[i].subscriptionId)
  params: {
    spokeResourceGroupName: spokeResourceGroup[i].name
    location: location
    tags: tags
    environment: parSpokeNetworks[i].parEnvironment
    workloadName: workloadName
    spokeApplicationGatewaySubnetAddressPrefix: parSpokeNetworks[i].subnets.appGatewaySubnet.addressPrefix
    spokeInfraSubnetAddressPrefix: parSpokeNetworks[i].subnets.infraSubnet.addressPrefix
    spokePrivateEndpointsSubnetAddressPrefix: parSpokeNetworks[i].subnets.privateEndPointSubnet.addressPrefix
    spokeVNetAddressPrefixes: [parSpokeNetworks[i].ipRange]
    networkApplianceIpAddress: networkApplianceIpAddress
    deployAzurePolicies: deployAzurePolicies
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    parHubResourceGroup: varVirtualHubResourceGroup
    parHubSubscriptionId: varVirtualHubSubscriptionId
    parHubResourceId: hubVNetId
  }
}]

module supportingServices 'modules/03-supporting-services/deploy.supporting-services.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  name: take('supportingServices-${deployment().name}-deployment-${i}', 64)
  scope: resourceGroup(parSpokeNetworks[i].subscriptionId,parSpokeNetworks[i].rgSpokeName)
  params: {
    location: location
    tags: tags
    spokePrivateEndpointSubnetName: spoke[i].outputs.spokePrivateEndpointsSubnetName
    environment: parSpokeNetworks[i].parEnvironment
    workloadName: workloadName
    spokeVNetId: spoke[i].outputs.spokeVNetId
    hubVNetId: hubVNetId
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    deployZoneRedundantResources: parSpokeNetworks[i].zoneRedundancy
    containerRegistryTier: parSpokeNetworks[i].containerRegistryTier
    privateDNSEnabled: parSpokeNetworks[i].configurePrivateDNS
  }
}]

module containerAppsEnvironment 'modules/04-container-apps-environment/deploy.aca-environment.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  name: take('containerAppsEnvironment-${deployment().name}-deployment', 64)
  scope: resourceGroup(parSpokeNetworks[i].subscriptionId,parSpokeNetworks[i].rgSpokeName)
  params: {
    location: location
    tags: tags
    environment: parSpokeNetworks[i].parEnvironment
    workloadName: workloadName
    spokeVNetName: spoke[i].outputs.spokeVNetName
    spokeInfraSubnetName: spoke[i].outputs.spokeInfraSubnetName
    enableApplicationInsights: true
    //enableDaprInstrumentation: false
    enableTelemetry: false
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    hubResourceGroupName: varVirtualHubResourceGroup
    hubSubscriptionId: varVirtualHubSubscriptionId
    //hubVNetName: varHubVirtualNetworkName
    deployZoneRedundantResources: parSpokeNetworks[i].zoneRedundancy
    privateDNSEnabled: parSpokeNetworks[i].configurePrivateDNS
  }
}]

module helloWorlSampleApp 'modules/05-hello-world-sample-app/deploy.hello-world.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  name: take('helloWorlSampleApp-${deployment().name}-deployment', 64)
  scope: resourceGroup(parSpokeNetworks[i].subscriptionId,parSpokeNetworks[i].rgSpokeName)
  params: {
    location: location
    tags: tags
    containerRegistryUserAssignedIdentityId: supportingServices[i].outputs.containerRegistryUserAssignedIdentityId
    containerAppsEnvironmentId: containerAppsEnvironment[i].outputs.containerAppsEnvironmentId
  }
}]

module applicationGateway 'modules/06-application-gateway/deploy.app-gateway.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  name: take('applicationGateway-${deployment().name}-deployment', 64)
  scope: resourceGroup(parSpokeNetworks[i].subscriptionId,parSpokeNetworks[i].rgSpokeName)
  params: {
    location: location
    tags: tags
    environment: parSpokeNetworks[i].parEnvironment
    workloadName: workloadName
    applicationGatewayCertificateKeyName: applicationGatewayCertificateKeyName
    applicationGatewayFqdn: applicationGatewayFqdn
    applicationGatewayPrimaryBackendEndFqdn: (deployHelloWorldSample) ? helloWorlSampleApp[i].outputs.helloWorldAppFqdn : '' // To fix issue when hello world is not deployed
    applicationGatewaySubnetId: spoke[i].outputs.spokeApplicationGatewaySubnetId
    enableApplicationGatewayCertificate: enableApplicationGatewayCertificate
    keyVaultId: supportingServices[i].outputs.keyVaultId
    deployZoneRedundantResources: parSpokeNetworks[i].zoneRedundancy
    ddosProtectionMode: 'Disabled'
    applicationGatewayLogAnalyticsId: logAnalyticsWorkspaceId
  }
}]

// ------------------
// OUTPUTS
// ------------------

// Spoke
@description('The  resource ID of the Spoke Virtual Network.')
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

@description('The name of the Spoke Application Gateway Subnet.  If "spokeApplicationGatewaySubnetAddressPrefix" is empty, the subnet will not be created and the value returned is empty.')
output spokeApplicationGatewaySubnetNames array = [for i in range(0, length(parSpokeNetworks)): {
  Name: spoke[i].outputs.spokeApplicationGatewaySubnetName
}]

// Supporting Services
// @description('The resource ID of the container registry.')
// output containerRegistryIds array = [for i in range(0, length(parSpokeNetworks)): {
//   Name: supportingServices[i].outputs.containerRegistryId
// }]

// @description('The name of the container registry.')
// output containerRegistryNames array = [for i in range(0, length(parSpokeNetworks)): {
//   Name: supportingServices[i].outputs.containerRegistryName
// }]

// @description('The name of the container registry login server.')
// output containerRegistryLoginServers array = [for i in range(0, length(parSpokeNetworks)): {
//   Name: supportingServices[i].outputs.containerRegistryLoginServer
// }]

// @description('The resource ID of the user assigned managed identity for the container registry to be able to pull images from it.')
// output containerRegistryUserAssignedIdentityIds array = [for i in range(0, length(parSpokeNetworks)): {
//   Name: supportingServices[i].outputs.containerRegistryUserAssignedIdentityId
// }]

@description('The resource ID of the key vault.')
output keyVaultIds array = [for i in range(0, length(parSpokeNetworks)): {
  Name: supportingServices[i].outputs.keyVaultId
}]

@description('The name of the key vault.')
output keyVaultNames array = [for i in range(0, length(parSpokeNetworks)): {
  Name: supportingServices[i].outputs.keyVaultName
}]

// Container Apps Environment
// @description('The resource ID of the container apps environment.')
// output containerAppsEnvironmentId string = containerAppsEnvironment.outputs.containerAppsEnvironmentId

// @description('The name of the container apps environment.')
// output containerAppsEnvironmentName string = containerAppsEnvironment.outputs.containerAppsEnvironmentName

// @description(' The name of application Insights instance.')
// output applicationInsightsName string =  (enableApplicationInsights)? containerAppsEnvironment.outputs.applicationInsightsName : ''
