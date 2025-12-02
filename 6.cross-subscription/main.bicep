targetScope = 'managementGroup'

// ------------------
//    PARAMETERS
// ------------------

@description('The location where the resources will be created.')
param paramvnetPeeringsVNetIDs string

@description('Comma-separated list of Azure service resource IDs for private endpoints in the target environment.')
param paramserviceIds string

@description('VNet ID under managed devops pool subscription where the VNet peering will be created.')
param manageddevopspoolVnetID string

@description('Enable DevBox storage private endpoints for dev environment')
param enableDevBoxStorageEndpoints bool = false

@description('Environment name (e.g., dev, uat, prod)')
param environment string = 'dev'

@description('The subscription ID where storage accounts are located')
param storageSubscriptionId string = ''

@description('The resource group name where storage accounts are located')
param storageResourceGroupName string = ''

@description('The DevBox subscription ID')
param devboxSubscriptionId string = ''

@description('The DevBox resource group name')
param devboxResourceGroupName string = ''

@description('The DevBox VNet name')
param devboxVNetName string = ''

@description('The DevBox private endpoint subnet name')
param devboxPrivateEndpointSubnetName string = ''

@description('Resource ID of the DW Function App (func-validate-irasid)')
param dwFunctionAppId string = ''

var managementVNetIdTokens = split(manageddevopspoolVnetID, '/')
var managementSubscriptionId = managementVNetIdTokens[2]
var managementResourceGroupName = managementVNetIdTokens[4]
var managementVNetName = managementVNetIdTokens[8]

var peeringVNetIds = split(paramvnetPeeringsVNetIDs, ',')

// Loop through each VNet ID and extract subscriptionId and resourceGroupName
var vnetInfoArray = [
  for vnetId in peeringVNetIds: {
    subscriptionId: split(vnetId, '/')[2]
    resourceGroupName: split(vnetId, '/')[4]
    vnetName: split(vnetId, '/')[8]
  }
]

var allserviceIDs = !empty(paramserviceIds) ? split(paramserviceIds, ',') : []

@description('Deploy VNet Peering')
module vnetpeeringmodule 'modules/vnetpeering/vnetpeering.bicep' = {
  name: take('01-vnetPeering-${deployment().name}', 64)
  scope: subscription(managementSubscriptionId)
  params: {
    vnetPeeringsSpokes: vnetInfoArray
    managementSubscriptionId: managementSubscriptionId
    managementResourceGroupName: managementResourceGroupName
    managementVNetName: managementVNetName
  }
}

module privateNetworking 'modules/privatenetworking/privatenetworking.bicep' = {
  name: take('privateNetworking-${deployment().name}', 64)
  scope: subscription(managementSubscriptionId)
  params: {
    sourceVNetID: manageddevopspoolVnetID
    serviceIds: allserviceIDs
    managementSubscriptionId: managementSubscriptionId
    managementResourceGroupName: managementResourceGroupName
  }
}

@description('Deploy DevBox storage private endpoints for dev environment')
module devboxStorageEndpoints 'modules/devbox-storage-endpoints/devbox-storage-endpoints.bicep' = if (enableDevBoxStorageEndpoints && environment == 'dev') {
  name: take('devboxStorageEndpoints-${environment}', 64)
  scope: subscription(devboxSubscriptionId)
  params: {
    environment: environment
    storageSubscriptionId: storageSubscriptionId
    storageResourceGroupName: storageResourceGroupName
    devboxSubscriptionId: devboxSubscriptionId
    devboxResourceGroupName: devboxResourceGroupName
    devboxVNetName: devboxVNetName
    devboxPrivateEndpointSubnetName: devboxPrivateEndpointSubnetName
    location: 'uksouth'
  }
}

@description('Deploy Data Warehouse Function App private endpoints to all application subscriptions')
module dwFunctionEndpoints 'modules/dw-function-endpoints/dw-function-endpoints.bicep' = if (!empty(dwFunctionAppId)) {
  name: take('dwFunctionEndpoints-${deployment().name}', 64)
  params: {
    dwFunctionAppId: dwFunctionAppId
  }
}

output serviceIDs array = [for serviceId in allserviceIDs: {
  serviceId: serviceId
}]

@description('DW Function App private endpoint IDs created')
output dwFunctionPrivateEndpointIds array = !empty(dwFunctionAppId) ? dwFunctionEndpoints!.outputs.privateEndpointIds : []

@description('DW Function App private endpoint names created')
output dwFunctionPrivateEndpointNames array = !empty(dwFunctionAppId) ? dwFunctionEndpoints!.outputs.privateEndpointNames : []
