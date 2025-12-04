targetScope = 'managementGroup'

// ------------------
// PARAMETERS
// ------------------

@description('Resource ID of the DW Function App (func-validate-irasid)')
param dwFunctionAppId string

@description('Subscription ID where the DW function endpoint should be created')
param dwFunctionAppSubscriptionId string

@description('Resource group containing the VNet for private endpoint')
param dwNetworkingResourceGroup string

@description('VNet name for private endpoint')
param dwVnetName string

@description('Private endpoint subnet name')
param dwPrivateEndpointSubnetName string

@description('Environment name for naming (e.g., dev, manualtest, automationtest, uat, preprod, prod)')
param dwEnvironment string

// ------------------
// VARIABLES
// ------------------

var appSubscriptions = !empty(dwFunctionAppSubscriptionId) && !empty(dwNetworkingResourceGroup) ? [{
  subscriptionId: dwFunctionAppSubscriptionId
  environment: dwEnvironment
  networkingResourceGroup: dwNetworkingResourceGroup
  vnetName: dwVnetName
  privateEndpointSubnetName: dwPrivateEndpointSubnetName
}] : []

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
