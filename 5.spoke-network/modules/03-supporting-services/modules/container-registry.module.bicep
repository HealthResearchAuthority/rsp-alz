targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------

@description('The location where the resources will be created.')
param location string = resourceGroup().location

@description('The name of the container registry.')
param containerRegistryName string


@description('Optional. The IP ACL rules. Note, requires the \'acrSku\' to be \'Premium\'.')
param networkRuleSetIpRules array = []

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

// @description('The resource ID of the VNet to which the private endpoint will be connected. This should be the management VNet, which hosts managed devops pool and other management services.')
// param managementVNetId string

@description('The resource ID of the VNet to which the private endpoint will be connected.')
param spokeVNetId string

@description('The name of the subnet in the VNet to which the private endpoint will be connected.')
param spokePrivateEndpointSubnetName string

@description('The name of the private endpoint to be created for Azure Container Registry.')
param containerRegistryPrivateEndpointName string

@description('The name of the user assigned identity to be created to pull image from Azure Container Registry.')
param containerRegistryUserAssignedIdentityName string

@description('Optional. Resource ID of the diagnostic log analytics workspace.')
param diagnosticWorkspaceId string = ''

@description('Optional, default value is true. If true, any resources that support AZ will be deployed in all three AZ. However if the selected region is not supporting AZ, this parameter needs to be set to false.')
param deployZoneRedundantResources bool = true

@description('Optional, default value is true. If true, any resources that support AZ will be deployed in all three AZ. However if the selected region is not supporting AZ, this parameter needs to be set to false.')
param acrTier string = ''


param networkingResourceGroup string

// ------------------
// VARIABLES
// ------------------

var privateDnsZoneNames = 'privatelink.azurecr.io'
var containerRegistryResourceName = 'registry'

var spokeVNetIdTokens = split(spokeVNetId, '/')
var spokeSubscriptionId = spokeVNetIdTokens[2]
var spokeResourceGroupName = spokeVNetIdTokens[4]
var spokeVNetName = spokeVNetIdTokens[8]

var containerRegistryPullRoleGuid='7f951dda-4ed3-4680-a7ca-43fe172d538d'
// Enable public access when IP rules are configured, otherwise disable for maximum security
var publicAccess = !empty(networkRuleSetIpRules) ? 'Enabled' : 'Disabled'

var spokeVNetLinks = [
  {
    vnetName: spokeVNetName
    vnetId: vnetSpoke.id
    registrationEnabled: false
  }
]

resource vnetSpoke 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  scope: resourceGroup(spokeSubscriptionId, spokeResourceGroupName)
  name: spokeVNetName
}

resource spokePrivateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' existing = {
  parent: vnetSpoke
  name: spokePrivateEndpointSubnetName
}

resource containerRegistryUserAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: containerRegistryUserAssignedIdentityName
  location: location
  tags: tags
}

module containerRegistry '../../../../shared/bicep/container-registry.bicep' = {
  name: take('containerRegistryNameDeployment-${deployment().name}', 64)
  params: {
    location: location
    tags: tags    
    name: containerRegistryName
    acrSku: acrTier
    zoneRedundancy: deployZoneRedundantResources ? 'Enabled' : 'Disabled'
    acrAdminUserEnabled: true
    publicNetworkAccess: publicAccess // Enabled when IP rules configured, otherwise Disabled
    networkRuleBypassOptions: 'AzureServices' // Allows Azure DevOps and other Azure services
    diagnosticWorkspaceId: diagnosticWorkspaceId
    userAssignedIdentities: {
      '${containerRegistryUserAssignedIdentity.id}': {}
    }
    networkRuleSetIpRules: networkRuleSetIpRules
  }
}

module containerRegistryNetwork '../../../../shared/bicep/network/private-networking-spoke.bicep' = if(acrTier == 'Premium') {// && publicAccess == 'Disabled') {
  name:take('containerRegistryNetworkDeployment-${deployment().name}', 64)
  scope: resourceGroup(networkingResourceGroup)
  params: {
    location: location
    azServicePrivateDnsZoneName: privateDnsZoneNames
    azServiceId: containerRegistry.outputs.resourceId
    privateEndpointName: containerRegistryPrivateEndpointName
    privateEndpointSubResourceName: containerRegistryResourceName
    virtualNetworkLinks: spokeVNetLinks
    subnetId: spokePrivateEndpointSubnet.id
    //vnetSpokeResourceId: spokeVNetId
  }
}

module containerRegistryPullRoleAssignment '../../../../shared/bicep/role-assignments/role-assignment.bicep' = {
  name: take('containerRegistryPullRoleAssignmentDeployment-${deployment().name}', 64)
  params: {
    name: 'ra-containerRegistryPullRoleAssignment'
    principalId: containerRegistryUserAssignedIdentity.properties.principalId
    resourceId: containerRegistry.outputs.resourceId
    roleDefinitionId: containerRegistryPullRoleGuid
    principalType: 'ServicePrincipal'
  }
}

// ------------------
// OUTPUTS
// ------------------

@description('The resource ID of the container registry.')
output containerRegistryId string = containerRegistry.outputs.resourceId

@description('The name of the container registry.')
output containerRegistryName string = containerRegistry.outputs.name

@description('The name of the container registry login server.')
output containerRegistryLoginServer string = containerRegistry.outputs.loginServer

@description('The resource ID of the user assigned managed identity for the container registry to be able to pull images from it.')
output containerRegistryUserAssignedIdentityId string = containerRegistryUserAssignedIdentity.id




