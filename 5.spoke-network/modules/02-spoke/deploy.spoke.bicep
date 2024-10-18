targetScope = 'subscription'

// ------------------
//    PARAMETERS
// ------------------

@description('The location where the resources will be created. This should be the same region as the hub.')
param location string = deployment().location

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

// Spoke
@description('CIDR of the spoke virtual network. For most landing zone implementations, the spoke network would have been created by your platform team.')
param spokeVNetAddressPrefixes array

@description('Optional. The name of the subnet to create for the spoke infrastructure. If set, it overrides the name generated by the template.')
param spokeInfraSubnetName string = 'snet-infra'

@description('CIDR of the spoke infrastructure subnet.')
param spokeInfraSubnetAddressPrefix string

@description('Optional. The name of the subnet to create for the spoke private endpoints. If set, it overrides the name generated by the template.')
param spokePrivateEndpointsSubnetName string = 'snet-pep'

@description('CIDR of the spoke private endpoints subnet.')
param spokePrivateEndpointsSubnetAddressPrefix string

@description('Optional. The name of the subnet to create for the spoke application gateway. If set, it overrides the name generated by the template.')
param spokeApplicationGatewaySubnetName string = 'snet-agw'

@description('CIDR of the spoke Application Gateway subnet. If the value is empty, this subnet will not be created.')
param spokeApplicationGatewaySubnetAddressPrefix string

@description('Optional. The name of the subnet to create for the spoke application gateway. If set, it overrides the name generated by the template.')
param spokeWebAppSubnetName string = 'snet-webapp'

@description('CIDR of the spoke Application Gateway subnet. If the value is empty, this subnet will not be created.')
param spokeWebAppSubnetAddressPrefix string

@description('The IP address of the network appliance (e.g. firewall) that will be used to route traffic to the internet.')
param networkApplianceIpAddress string

@description('Central Log Analytics Workspace ID')
param logAnalyticsWorkspaceId string

@description('Optional, default value is true. If true, Azure Policies will be deployed')
param deployAzurePolicies bool = true

@description('Hub Subscription ID')
param parHubSubscriptionId string

@description('Hub Subscription ID')
param parHubResourceGroup string

@description('Hub Subscription ID')
param parHubResourceId string

@description('resource Names')
param resourcesNames object

param spokeNetworkingRGName string
// @description('Boolean indicating if Spoke VNet to be peered with DevBox VNet')
// param parDevBoxVNetPeering bool

// @description('DevBox Subscription ID')
// param parDevBoxVNetPeeringSubscriptionID string = ''

// @description('DevBox Vnet RG Name')
// param parDevBoxVNetPeeringResourceGroup string = ''

// @description('DevBox Vnet Name')
// param parDevBoxVNetPeeringVNetName string = ''

// ------------------
// VARIABLES
// ------------------

//Destination Service Tag for AzureCloud for Central France is centralfrance, but location is francecentral
var locationVar = location == 'francecentral' ? 'centralfrance' : location

// load as text (and not as Json) to replace <location> placeholder in the nsg rules
var nsgCaeRules = json( replace( loadTextContent('./nsgContainerAppsEnvironment.jsonc') , '<location>', locationVar) )
var nsgAppGwRules = loadJsonContent('./nsgAppGwRules.jsonc', 'securityRules')

// Subnet definition taking in consideration feature flags
var defaultSubnets = [
  {
    name: spokeInfraSubnetName
    properties: {
      addressPrefix: spokeInfraSubnetAddressPrefix
      networkSecurityGroup: {
        id: nsgContainerAppsEnvironment.outputs.nsgId
      }
      // routeTable: {
      //   id: egressLockdownUdr.outputs.resourceId
      // }
      delegations: [
        {
          name: 'envdelegation'
          properties: {
            serviceName: 'Microsoft.App/environments'
          }
        }
      ]
    }
  }
  {
    name: spokePrivateEndpointsSubnetName
    properties: {
      addressPrefix: spokePrivateEndpointsSubnetAddressPrefix
      networkSecurityGroup: {
        id: nsgPep.outputs.nsgId
      }
    }
  }
  {
    name: spokeWebAppSubnetName
    properties: {
      addressPrefix: spokeWebAppSubnetAddressPrefix
      networkSecurityGroup: {
        id: nsgWebApp.outputs.nsgId
      }
      delegations: [
        {
          name: 'envdelegation'
          properties: {
            serviceName: 'Microsoft.Web/serverfarms'
          }
        }
      ]
    }
  }
]

// Append optional application gateway subnet, if required
var appGwAndDefaultSubnets = !empty(spokeApplicationGatewaySubnetAddressPrefix) ? concat(defaultSubnets, [
    {
      name: spokeApplicationGatewaySubnetName
      properties: {
        addressPrefix: spokeApplicationGatewaySubnetAddressPrefix
        networkSecurityGroup: {
          id: nsgAppGw.outputs.nsgId
        }
      }
    }
  ]) : defaultSubnets

// ------------------
// RESOURCES
// ------------------

@description('The spoke resource group. This would normally be already provisioned by your subscription vending process.')
resource spokeNetworkingResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: spokeNetworkingRGName
  location: location
  tags: tags
}

@description('The spoke virtual network in which the workload will run from. This virtual network would normally already be provisioned by your subscription vending process, and only the subnets would need to be configured.')
module vnetSpoke '../../../shared/bicep/network/vnet.bicep' = {
  name: take('vnetSpoke-${deployment().name}', 64)
  scope: spokeNetworkingResourceGroup
  params: {
    name: resourcesNames.vnetSpoke
    location: location
    tags: tags
    subnets: appGwAndDefaultSubnets
    vnetAddressPrefixes: spokeVNetAddressPrefixes
  }
}

@description('Network security group rules for the Container Apps cluster.')
module nsgContainerAppsEnvironment '../../../shared/bicep/network/nsg.bicep' = {
  name: take('nsgContainerAppsEnvironment-${deployment().name}', 64)
  scope: spokeNetworkingResourceGroup
  params: {
    name: resourcesNames.containerAppsEnvironmentNsg
    location: location
    tags: tags
    securityRules: nsgCaeRules.securityRules
    diagnosticWorkspaceId: logAnalyticsWorkspaceId
  }
}

@description('NSG Rules for the Application Gateway.')
module nsgAppGw '../../../shared/bicep/network/nsg.bicep' = if (!empty(spokeApplicationGatewaySubnetAddressPrefix)) {
  name: take('nsgAppGw-${deployment().name}', 64)
  scope: spokeNetworkingResourceGroup
  params: {
    name: resourcesNames.applicationGatewayNsg
    location: location
    tags: tags
    securityRules: nsgAppGwRules
    diagnosticWorkspaceId: logAnalyticsWorkspaceId
  }
}

@description('NSG Rules for the private enpoint subnet.')
module nsgPep '../../../shared/bicep/network/nsg.bicep' = {
  name: take('nsgPep-${deployment().name}', 64)
  scope: spokeNetworkingResourceGroup
  params: {
    name: resourcesNames.pepNsg
    location: location
    tags: tags
    securityRules: []
    diagnosticWorkspaceId: logAnalyticsWorkspaceId
  }
}

@description('NSG Rules for App service.')
module nsgWebApp '../../../shared/bicep/network/nsg.bicep' = {
  name: take('nsgWebApp-${deployment().name}', 64)
  scope: spokeNetworkingResourceGroup
  params: {
    name: resourcesNames.webAppNsg
    location: location
    tags: tags
    securityRules: []
    diagnosticWorkspaceId: logAnalyticsWorkspaceId
  }
}

// @description('The Route Table deployment')
// module egressLockdownUdr '../../../shared/bicep/routeTables/main.bicep' = {
//   name: take('egressLockdownUdr-${uniqueString(spokeNetworkingResourceGroup.id)}', 64)
//   scope: spokeNetworkingResourceGroup
//   params: {
//     name: resourcesNames.routeTable
//     location: location
//     tags: tags
//     routes: [
//       {
//         name: 'defaultEgressLockdown'
//         properties: {
//           addressPrefix: '0.0.0.0/0'
//           nextHopType: 'VirtualAppliance'
//           nextHopIpAddress: networkApplianceIpAddress
//         }
//       }
//     ]
//   }
// }

// // Module -  Spoke to Azure Virtual WAN Hub peering.
// module modhubVirtualNetworkConnection '../../../shared/bicep/network/hubVirtualNetworkConnection.bicep' = {
//   scope: resourceGroup(parHubSubscriptionId, parHubResourceGroup)
//   name: take('vWanPeering-${deployment().name}', 64)
//   params: {
//     parVirtualWanHubResourceId: parHubResourceId
//     parRemoteVirtualNetworkResourceId: vnetSpoke.outputs.vnetId
//     parEnableInternetSecurity: false
//   }
// }

// module spoketoDevBoxPeering '../../../shared/bicep/network/peering.bicep' = if(parDevBoxVNetPeering) {
//   scope: resourceGroup(spokeResourceGroupName)
//   name:take('spoketoDevBoxPeering-${deployment().name}', 64)
//   params: {
//     localVnetName: vnetSpoke.outputs.vnetName
//     remoteSubscriptionId: parDevBoxVNetPeeringSubscriptionID
//     remoteRgName: parDevBoxVNetPeeringResourceGroup
//     remoteVnetName: parDevBoxVNetPeeringVNetName
//   }
// }

// module devBoxToSpokePeering '../../../shared/bicep/network/peering.bicep' = if(parDevBoxVNetPeering) {
//   scope: resourceGroup(parDevBoxVNetPeeringSubscriptionID, parDevBoxVNetPeeringResourceGroup)
//   name:take('devBoxToSpokePeering-${deployment().name}', 64)
//   params: {
//     localVnetName: parDevBoxVNetPeeringVNetName
//     remoteSubscriptionId: last(split(subscription().id, '/'))!
//     remoteRgName: spokeResourceGroupName
//     remoteVnetName: vnetSpoke.name
//   }
// }

@description('Assign built-in and custom (container-apps related) policies to the spoke subscription.')
module policyAssignments './modules/policy/policy-definition.module.bicep' = if (deployAzurePolicies) {
  name: take('policyAssignments-${deployment().name}', 64)
  scope: spokeNetworkingResourceGroup
  params: {
    location: location   
    containerRegistryName: resourcesNames.containerRegistry 
  }
}

// ------------------
// OUTPUTS
// ------------------

resource vnetSpokeCreated 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: vnetSpoke.outputs.vnetName
  scope: spokeNetworkingResourceGroup

  resource spokeInfraSubnet 'subnets' existing = {
    name: spokeInfraSubnetName
  }

  resource spokePrivateEndpointsSubnet 'subnets' existing = {
    name: spokePrivateEndpointsSubnetName
  }

  resource spokeApplicationGatewaySubnet 'subnets' existing = if (!empty(spokeApplicationGatewaySubnetAddressPrefix)) {
    name: spokeApplicationGatewaySubnetName
  }

  resource spokeWebAppSubnet 'subnets' existing = if (!empty(spokeApplicationGatewaySubnetAddressPrefix)) {
    name: spokeWebAppSubnetName
  }
}

@description('The name of the spoke resource group.')
output spokeResourceGroupName string = spokeNetworkingResourceGroup.name

@description('The resource ID of the spoke virtual network.')
output spokeVNetId string = vnetSpokeCreated.id

@description('The name of the spoke virtual network.')
output spokeVNetName string = vnetSpokeCreated.name

@description('The resource ID of the spoke infrastructure subnet.')
output spokePepSubnetId string = vnetSpokeCreated::spokePrivateEndpointsSubnet.id

@description('The resource ID of the spoke infrastructure subnet.')
output spokeInfraSubnetId string = vnetSpokeCreated::spokeInfraSubnet.id

@description('The name of the spoke infrastructure subnet.')
output spokeInfraSubnetName string = vnetSpokeCreated::spokeInfraSubnet.name

@description('The resource ID of the spoke WebApp subnet.')
output spokeWebAppSubnetId string = vnetSpokeCreated::spokeWebAppSubnet.id

@description('The name of the spoke WebApp subnet.')
output spokeWebAppSubnetName string = vnetSpokeCreated::spokeWebAppSubnet.name

@description('The name of the spoke private endpoints subnet.')
output spokePrivateEndpointsSubnetName string = vnetSpokeCreated::spokePrivateEndpointsSubnet.name

@description('The resource ID of the spoke Application Gateway subnet. This is \'\' if the subnet was not created.')
output spokeApplicationGatewaySubnetId string = (!empty(spokeApplicationGatewaySubnetAddressPrefix)) ? vnetSpokeCreated::spokeApplicationGatewaySubnet.id : ''

@description('The name of the spoke Application Gateway subnet.  This is \'\' if the subnet was not created.')
output spokeApplicationGatewaySubnetName string = (!empty(spokeApplicationGatewaySubnetAddressPrefix)) ? vnetSpokeCreated::spokeApplicationGatewaySubnet.name : ''
