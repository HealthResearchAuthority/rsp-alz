@description('Required. Name given for the hub route table.')
param name string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Optional. An Array of Routes to be established within the hub route table.')
param routes array = []

@description('Optional. Switch to disable BGP route propagation.')
param disableBgpRoutePropagation bool = false

@allowed([
  ''
  'CanNotDelete'
  'ReadOnly'
])
@description('Optional. Specify the type of lock.')
param lock string = ''

@description('Optional. Array of role assignment objects that contain the \'roleDefinitionIdOrName\' and \'principalId\' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
param roleAssignments array = []

@description('Optional. Tags of the resource.')
param tags object = {}

resource routeTable 'Microsoft.Network/routeTables@2022-07-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    routes: routes
    disableBgpRoutePropagation: disableBgpRoutePropagation
  }
}

resource routeTable_lock 'Microsoft.Authorization/locks@2020-05-01' = if (!empty(lock)) {
  name: '${routeTable.name}-${lock}-lock'
  properties: {
    level: any(lock)
    notes: lock == 'CanNotDelete' ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
  }
  scope: routeTable
}

module routeTable_roleAssignments '.bicep/nested_roleAssignments.bicep' = [for (roleAssignment, index) in roleAssignments: {
  name: '${uniqueString(deployment().name, location)}-RouteTable-Rbac-${index}'
  params: {
    //description: contains(roleAssignment, 'description') ? roleAssignment.description : ''
    description: roleAssignment.?description ? roleAssignment.description : ''
    principalIds: roleAssignment.principalIds
    principalType: roleAssignment.?principalType ? roleAssignment.principalType : ''
    roleDefinitionIdOrName: roleAssignment.roleDefinitionIdOrName
    condition: roleAssignment.?condition ? roleAssignment.condition : ''
    delegatedManagedIdentityResourceId: roleAssignment.?delegatedManagedIdentityResourceId ? roleAssignment.delegatedManagedIdentityResourceId : ''
    resourceId: routeTable.id
  }
}]

@description('The resource group the route table was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The name of the route table.')
output name string = routeTable.name

@description('The resource ID of the route table.')
output resourceId string = routeTable.id

@description('The location the resource was deployed into.')
output location string = routeTable.location
