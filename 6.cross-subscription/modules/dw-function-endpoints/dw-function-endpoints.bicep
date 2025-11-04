targetScope = 'managementGroup'

// ------------------
// PARAMETERS
// ------------------

@description('Resource ID of the DW Function App (func-validate-irasid)')
param dwFunctionAppId string

// ------------------
// VARIABLES
// ------------------

var subscriptionConfigs = [
  { subscriptionId: 'b83b4631-b51b-4961-86a1-295f539c826b', environment: 'dev', rgSuffix: 'dev' }
  { subscriptionId: '66482e26-764b-4717-ae2f-fab6b8dd1379', environment: 'manualtest', rgSuffix: 'systemtest' }
  { subscriptionId: '75875981-b04d-42c7-acc5-073e2e5e2e65', environment: 'automationtest', rgSuffix: 'systemtestauto' }
  { subscriptionId: 'e1a1a4ff-2db5-4de3-b7e5-6d51413f6390', environment: 'uat', rgSuffix: 'uat' }
  { subscriptionId: 'be1174fc-09c8-470f-9409-d0054ab9586a', environment: 'preprod', rgSuffix: 'preprod' }
  { subscriptionId: 'd27a0dcc-453d-4bfa-9c3d-1447c6ea0119', environment: 'prod', rgSuffix: 'prod' }
]

var appSubscriptions = [for config in subscriptionConfigs: {
  subscriptionId: config.subscriptionId
  environment: config.environment
  networkingResourceGroup: 'rg-rsp-networking-spoke-${config.rgSuffix}-uks'
  vnetName: 'vnet-rsp-networking-${config.environment}-uks-spoke'
  privateEndpointSubnetName: 'snet-pep'
}]

// ------------------
// MODULES
// ------------------

module appSubscriptionEndpoints 'app-subscription-endpoint.bicep' = [for (appSub, index) in appSubscriptions: if (!empty(dwFunctionAppId)) {
  name: take('dwFuncEndpoint-${appSub.environment}-${uniqueString(deployment().name)}', 64)
  scope: subscription(appSub.subscriptionId)
  params: {
    dwFunctionAppId: dwFunctionAppId
    networkingResourceGroup: appSub.networkingResourceGroup
    vnetName: appSub.vnetName
    privateEndpointSubnetName: appSub.privateEndpointSubnetName
    environment: appSub.environment
  }
}]

// ------------------
// OUTPUTS
// ------------------

@description('Private endpoint resource IDs created')
output privateEndpointIds array = [for (appSub, index) in appSubscriptions: !empty(dwFunctionAppId) ? appSubscriptionEndpoints[index]!.outputs.privateEndpointId : '']

@description('Private endpoint names created')
output privateEndpointNames array = [for (appSub, index) in appSubscriptions: !empty(dwFunctionAppId) ? appSubscriptionEndpoints[index]!.outputs.privateEndpointName : '']
