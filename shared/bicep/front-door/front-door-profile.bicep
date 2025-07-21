// ------------------
// PARAMETERS
// ------------------

@description('Required. Name of the Front Door profile.')
param name string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Optional. The pricing tier of the Front Door profile.')
@allowed([
  'Standard_AzureFrontDoor'
  'Premium_AzureFrontDoor'
])
param skuName string = 'Premium_AzureFrontDoor'

@description('Optional. Tags of the resource.')
param tags object?

@description('Optional. The response timeout in seconds for origins.')
param originResponseTimeoutSeconds int = 60


@description('Optional. The identity type of the Front Door profile.')
@allowed([
  'SystemAssigned'
  'UserAssigned'
  'SystemAssigned,UserAssigned'
])
param identityType string = 'SystemAssigned'

@description('Optional. The user assigned identities for the Front Door profile.')
param userAssignedIdentities object = {}

// ------------------
// RESOURCES
// ------------------

resource frontDoorProfile 'Microsoft.Cdn/profiles@2023-05-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  identity: {
    type: identityType
    userAssignedIdentities: !empty(userAssignedIdentities) ? userAssignedIdentities : null
  }
  properties: {
    originResponseTimeoutSeconds: originResponseTimeoutSeconds
  }
}

// ------------------
// OUTPUTS
// ------------------

@description('The resource ID of the Front Door profile.')
output resourceId string = frontDoorProfile.id

@description('The name of the Front Door profile.')
output name string = frontDoorProfile.name

@description('The location the resource was deployed into.')
output location string = frontDoorProfile.location

@description('The host name of the Front Door profile.')
output hostName string = frontDoorProfile.properties.frontDoorId

@description('The resource group the Front Door profile was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The principal ID of the system assigned identity.')
output systemAssignedMIPrincipalId string = (identityType == 'SystemAssigned' || identityType == 'SystemAssigned,UserAssigned') ? frontDoorProfile.identity.principalId : ''