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

@description('Enable DevBox SQL replica private endpoints')
param enableDevBoxSqlReplicaEndpoints bool = false

@description('Comma-separated list of replica SQL Server resource IDs for DevBox private endpoints')
param replicaSqlServerResourceId string = ''

@description('Comma-separated list of replica SQL Server names (for private endpoint naming)')
param replicaSqlServerName string = ''

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

@description('Subscription ID where the DW function endpoint should be created')
param dwFunctionAppSubscriptionId string = ''

@description('Resource group containing the VNet for DW private endpoint')
param dwNetworkingResourceGroup string = ''

@description('VNet name for DW private endpoint')
param dwVnetName string = ''

@description('Private endpoint subnet name for DW')
param dwPrivateEndpointSubnetName string = ''

@description('Environment name for DW endpoint naming')
param dwEnvironment string = ''

@description('Deploy DW Function App private endpoints')
param deployDwPrivateEndpoints bool = false

@description('Comma-separated list of secondary region VNet IDs to peer with DevBox VNet')
param devBoxSecondaryVNetIds string = ''

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

var replicaSqlServerResourceIds = !empty(replicaSqlServerResourceId) ? (replicaSqlServerResourceId) : ''
var replicaSqlServerNames = !empty(replicaSqlServerName) ? (replicaSqlServerName) : ''

var devBoxSecondaryVNetIdsArray = !empty(devBoxSecondaryVNetIds) ? split(devBoxSecondaryVNetIds, ',') : []
var devBoxSecondaryVNetInfoArray = [
  for vnetId in devBoxSecondaryVNetIdsArray: {
    subscriptionId: split(vnetId, '/')[2]
    resourceGroupName: split(vnetId, '/')[4]
    vnetName: split(vnetId, '/')[8]
  }
]

@description('Deploy DevBox SQL replica private endpoints')
module devboxSqlReplicaEndpoints 'modules/devbox-sql-replica-endpoints/devbox-sql-replica-endpoints.bicep' = if (enableDevBoxSqlReplicaEndpoints && (replicaSqlServerResourceIds) != '' && (replicaSqlServerNames) != '') {
  name: take('devboxSqlReplicaEndpoints-${environment}', 64)
  scope: subscription(devboxSubscriptionId)
  params: {
    environment: environment
    replicaSqlServerResourceId: replicaSqlServerResourceIds
    replicaSqlServerName: replicaSqlServerNames
    devboxSubscriptionId: devboxSubscriptionId
    devboxResourceGroupName: devboxResourceGroupName
    devboxVNetName: devboxVNetName
    devboxPrivateEndpointSubnetName: devboxPrivateEndpointSubnetName
    location: 'ukwest'
    tags: {}
  }
}

// DevBox VNet Peering to Secondary Region VNets (bidirectional)
// Peering from DevBox VNet to Secondary Region VNets
module devBoxToSecondaryVNetPeering '../shared/bicep/network/peering.bicep' = [for (vnet, i) in devBoxSecondaryVNetInfoArray: {
  name: take('devBox-to-${vnet.vnetName}-peering-${i}', 64)
  scope: resourceGroup(devboxSubscriptionId, devboxResourceGroupName)
  params: {
    localVnetName: devboxVNetName
    remoteVnetName: vnet.vnetName
    remoteRgName: vnet.resourceGroupName
    remoteSubscriptionId: vnet.subscriptionId
    allowGatewayTransit: false
    allowForwardedTraffic: true
    useRemoteGateways: false
  }
}]

// Peering from Secondary Region VNets to DevBox VNet
module secondaryVNetToDevBoxPeering '../shared/bicep/network/peering.bicep' = [for (vnet, i) in devBoxSecondaryVNetInfoArray: {
  name: take('${vnet.vnetName}-to-devBox-peering-${i}', 64)
  scope: resourceGroup(vnet.subscriptionId, vnet.resourceGroupName)
  params: {
    localVnetName: vnet.vnetName
    remoteVnetName: devboxVNetName
    remoteRgName: devboxResourceGroupName
    remoteSubscriptionId: devboxSubscriptionId
    allowGatewayTransit: false
    allowForwardedTraffic: true
    useRemoteGateways: false
  }
  dependsOn: [
    devBoxToSecondaryVNetPeering
  ]
}]

@description('Deploy Data Warehouse Function App private endpoint to the target environment')
module dwFunctionEndpoints 'modules/dw-function-endpoints/dw-function-endpoints.bicep' = if (deployDwPrivateEndpoints && !empty(dwFunctionAppId)) {
  name: take('dwFunctionEndpoints-${deployment().name}', 64)
  params: {
    dwFunctionAppId: dwFunctionAppId
    dwFunctionAppSubscriptionId: dwFunctionAppSubscriptionId
    dwNetworkingResourceGroup: dwNetworkingResourceGroup
    dwVnetName: dwVnetName
    dwPrivateEndpointSubnetName: dwPrivateEndpointSubnetName
    dwEnvironment: dwEnvironment
  }
}

output serviceIDs array = [for serviceId in allserviceIDs: {
  serviceId: serviceId
}]

@description('DW Function App private endpoint IDs created')
output dwFunctionPrivateEndpointIds array = (deployDwPrivateEndpoints && !empty(dwFunctionAppId)) ? dwFunctionEndpoints!.outputs.privateEndpointIds : []

@description('DW Function App private endpoint names created')
output dwFunctionPrivateEndpointNames array = (deployDwPrivateEndpoints && !empty(dwFunctionAppId)) ? dwFunctionEndpoints!.outputs.privateEndpointNames : []
