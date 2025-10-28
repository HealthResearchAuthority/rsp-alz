targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------

@description('The location where the resources will be created.')
param location string = resourceGroup().location

@description('The name of the container registry.')
param serviceBusNamespaceName string

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

@description('The resource ID of the VNet to which the private endpoint will be connected.')
param spokeVNetId string

@description('The name of the subnet in the VNet to which the private endpoint will be connected.')
param spokePrivateEndpointSubnetName string

@description('The name of the private endpoint to be created for Azure Container Registry.')
param serviceBusPrivateEndpointName string

@description('The name of the user assigned identity to be created to receive messages from Service Bus.')
param serviceBusReceiverUserAssignedIdentityName string

@description('The name of the user assigned identity to be created to send messages to Service Bus')
param serviceBusSenderUserAssignedIdentityName string

@description('Optional. Resource ID of the diagnostic log analytics workspace.')
param diagnosticWorkspaceId string = ''

@description('Optional, default value is true. If true, any resources that support AZ will be deployed in all three AZ. However if the selected region is not supporting AZ, this parameter needs to be set to false.')
param deployZoneRedundantResources bool = true

// ------------------
// VARIABLES
// ------------------

var privateDnsZoneNames = 'privatelink.servicebus.windows.net'
var serviceBusSubResourceName = 'namespace'

var spokeVNetIdTokens = split(spokeVNetId, '/')
var spokeSubscriptionId = spokeVNetIdTokens[2]
var spokeResourceGroupName = spokeVNetIdTokens[4]
var spokeVNetName = spokeVNetIdTokens[8]

var serviceBusDataReceiverRoleGuid='4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0'
var serviceBusDataSenderRoleGuid='69a216fc-b8fb-44d8-bc22-1f3c2cd27a39'
var queuename = 'sendEmail'

var spokeVNetLinks = [
  {
    vnetName: spokeVNetName
    vnetId: vnetSpoke.id
    registrationEnabled: false
  }
]

// ------------------
// RESOURCES
// ------------------

resource vnetSpoke 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  scope: resourceGroup(spokeSubscriptionId, spokeResourceGroupName)
  name: spokeVNetName
}

resource spokePrivateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' existing = {
  parent: vnetSpoke
  name: spokePrivateEndpointSubnetName
}

resource serviceBusReceiverUserAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: serviceBusReceiverUserAssignedIdentityName
  location: location
  tags: tags
}

resource serviceBusSenderUserAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: serviceBusSenderUserAssignedIdentityName
  location: location
  tags: tags
}


module servicebus '../../../../shared/bicep/service-bus.bicep' = { 
  name: take('serviceBusNameDeployment-${deployment().name}', 64)
  params: {
    name: serviceBusNamespaceName
    tags: {}
    workspaceId: diagnosticWorkspaceId
    deadLetteringOnMessageExpiration: true
    publicNetworkAccess: 'Disabled'
    queueNames: [
      queuename
    ]
    skuName: 'Premium'
    zoneRedundant: deployZoneRedundantResources
    userAssignedIdentities: {
      '${serviceBusSenderUserAssignedIdentity.id}': {}
      '${serviceBusReceiverUserAssignedIdentity.id}': {}
    }
  }
}

module serviceBusNetwork '../../../../shared/bicep/network/private-networking-spoke.bicep' = {
  name:take('containerRegistryNetworkDeployment-${deployment().name}', 64)
  params: {
    location: location
    azServicePrivateDnsZoneName: privateDnsZoneNames
    azServiceId: servicebus.outputs.id
    privateEndpointName: serviceBusPrivateEndpointName
    privateEndpointSubResourceName: serviceBusSubResourceName
    virtualNetworkLinks: spokeVNetLinks
    subnetId: spokePrivateEndpointSubnet.id
  }
}

module serviceBusReceiverRoleAssignment '../../../../shared/bicep/role-assignments/role-assignment.bicep' = {
  name: take('serviceBusReceiverRoleAssignmentDeployment-${deployment().name}', 64)
  params: {
    name: 'ra-serviceBusReceiverRoleAssignmentDeployment'
    principalId: serviceBusReceiverUserAssignedIdentity.properties.principalId
    resourceId: servicebus.outputs.id
    roleDefinitionId: serviceBusDataReceiverRoleGuid
    principalType: 'ServicePrincipal'
  }
}

module serviceBusSenderRoleAssignment '../../../../shared/bicep/role-assignments/role-assignment.bicep' = {
  name: take('serviceBusSenderRoleAssignmentDeployment-${deployment().name}', 64)
  params: {
    name: 'ra-serviceBusSenderRoleAssignmentDeployment'
    principalId: serviceBusSenderUserAssignedIdentity.properties.principalId
    resourceId: servicebus.outputs.id
    roleDefinitionId: serviceBusDataSenderRoleGuid
    principalType: 'ServicePrincipal'
  }
}

// ------------------
// OUTPUTS
// ------------------

output serviceBusId string = servicebus.outputs.id
output serviceBusReceiverManagedIdentityId string = serviceBusReceiverUserAssignedIdentity.id
output serviceBusSenderManagedIdentityId string = serviceBusSenderUserAssignedIdentity.id




