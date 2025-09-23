targetScope = 'subscription'

// ------------------
// PARAMETERS
// ------------------

@description('The location where the resources will be created.')
param location string = deployment().location

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

@description('Central Log Analytics Workspace ID')
@secure()
param logAnalyticsWorkspaceId string

@description('Optional, default value is true. If true, Azure Policies will be deployed')
param deployAzurePolicies bool = true

@description('Array of spoke network configurations')
param parSpokeNetworks array = []

// @description('Name of the Network Watcher attached to your subscription. Format: NetworkWatcher_<region_name>')
// param networkWatcherName string = 'NetworkWatcher_${location}'

// param networkWatcherRGName string

param caeFlowLogName string

param pepFlowLogName string

param agwFlowLogName string

param webappFlowLogName string

// ------------------
// RESOURCES
// ------------------
resource networkWatcher 'Microsoft.Network/networkWatchers@2022-01-01' existing = [for i in range(0, length(parSpokeNetworks)): {
  name: parSpokeNetworks[i].networkWatcherName
  scope: resourceGroup(parSpokeNetworks[i].subscriptionId, parSpokeNetworks[i].rgNetworkWatcher)
}]

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
    environment: parSpokeNetworks[i].parEnvironment
    caeFlowLogName: '${networkWatcher[i].name}/${caeFlowLogName}${parSpokeNetworks[i].parEnvironment}'
    pepFlowLogName: '${networkWatcher[i].name}/${pepFlowLogName}${parSpokeNetworks[i].parEnvironment}'
    agwFlowLogName: '${networkWatcher[i].name}/${agwFlowLogName}${parSpokeNetworks[i].parEnvironment}'
    webappFlowLogName: '${networkWatcher[i].name}/${webappFlowLogName}${parSpokeNetworks[i].parEnvironment}'
    rgNetworkWatcher: parSpokeNetworks[i].rgNetworkWatcher
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

