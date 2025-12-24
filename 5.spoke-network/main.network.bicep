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

@description('Enable failover/DR networking deployment for secondary region')
param parEnableFailover bool = false

@description('Secondary region location (e.g., ukwest)')
param parSecondaryLocation string = ''

@description('Array of secondary region spoke network configurations (for DR/failover)')
param parSecondarySpokeNetworks array = []


// ------------------
// RESOURCES
// ------------------

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

// Secondary region networking for DR/failover
module secondaryNetworkingRG '../shared/bicep/resourceGroup.bicep' = [for i in range(0, length(parSecondarySpokeNetworks)): if (parEnableFailover && length(parSecondarySpokeNetworks) > 0) {
  name: take('secondaryNetworkingRG-${deployment().name}-${i}', 64)
  scope: subscription(parSecondarySpokeNetworks[i].subscriptionId)
  params: {
    parLocation: parSecondaryLocation
    parResourceGroupName: parSecondarySpokeNetworks[i].rgNetworking
  }
}]

module secondaryNetworkingnaming '../shared/bicep/naming/naming.module.bicep' = [for i in range(0, length(parSecondarySpokeNetworks)): if (parEnableFailover && length(parSecondarySpokeNetworks) > 0) {
  name: take('secondaryNetworkingNaming-${deployment().name}-${i}', 64)
  scope: resourceGroup(parSecondarySpokeNetworks[i].subscriptionId, parSecondarySpokeNetworks[i].rgNetworking)
  params: {
    uniqueId: uniqueString(secondaryNetworkingRG[i].?outputs.outResourceGroupId)
    environment: parSecondarySpokeNetworks[i].parEnvironment
    workloadName: 'networking'
    location: parSecondaryLocation
  }
  dependsOn: [
    secondaryNetworkingRG
  ]
}]

module secondarySpoke 'modules/02-spoke/deploy.spoke.bicep' = [for i in range(0, length(parSecondarySpokeNetworks)): if (parEnableFailover && length(parSecondarySpokeNetworks) > 0) {
  name: take('secondarySpoke-${deployment().name}-deployment-${i}', 64)
  scope: subscription(parSecondarySpokeNetworks[i].subscriptionId)
  params: {
    location: parSecondaryLocation
    tags: tags
    spokeApplicationGatewaySubnetAddressPrefix: parSecondarySpokeNetworks[i].subnets.appGatewaySubnet.addressPrefix
    spokeInfraSubnetAddressPrefix: parSecondarySpokeNetworks[i].subnets.infraSubnet.addressPrefix
    spokePrivateEndpointsSubnetAddressPrefix: parSecondarySpokeNetworks[i].subnets.privateEndPointSubnet.addressPrefix
    spokeWebAppSubnetAddressPrefix: parSecondarySpokeNetworks[i].subnets.webAppSubnet.addressPrefix
    spokeVNetAddressPrefixes: [parSecondarySpokeNetworks[i].ipRange]
    deployAzurePolicies: deployAzurePolicies
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    resourcesNames: secondaryNetworkingnaming[i].?outputs.resourcesNames
    spokeNetworkingRGName: parSecondarySpokeNetworks[i].rgNetworking
  }
  dependsOn: [
    secondaryNetworkingnaming
  ]
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

// Secondary region outputs (only populated when failover is enabled)
@description('The resource ID of the Secondary Region Spoke Virtual Network.')
output secondarySpokeVNetIds array = []

@description('The name of the Secondary Region Spoke Virtual Network.')
output secondarySpokeVnetNames array = []

@description('The resource ID of the Secondary Region Spoke Private Endpoints Subnet.')
output secondarySpokePrivateEndpointsSubnetIds array = []

@description('The name of the Secondary Region Spoke Private Endpoints Subnet.')
output secondarySpokePrivateEndpointsSubnetNames array = []

