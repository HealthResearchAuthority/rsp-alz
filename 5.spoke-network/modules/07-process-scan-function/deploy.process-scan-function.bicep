targetScope = 'resourceGroup'

// ------------------
// PARAMETERS
// ------------------

@description('The location where the resources will be created.')
param location string = resourceGroup().location

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

@description('Function App name')
param functionAppName string

@description('Function App storage account name')
param storageAccountName string

// Note: documentUploadStorageAccountId parameter removed as permissions will be configured separately
// Future: This will be used when managed identity permissions are implemented

@description('Log Analytics workspace resource ID')
param logAnalyticsWorkspaceId string

@description('Subnet ID for VNet integration')
param subnetIdForVnetInjection string

@description('Spoke VNet resource ID')
param spokeVNetId string = ''

@description('Private endpoint subnet ID')
param subnetPrivateEndpointSubnetId string = ''

@description('User assigned identities for the Function App')
param userAssignedIdentities array

// ------------------
// VARIABLES
// ------------------

// ------------------
// RESOURCES
// ------------------

// Function App for processing scan results using existing app-service module
module functionApp '../07-app-service/deploy.app-service.bicep' = {
  name: 'processScanFunctionApp'
  params: {
    appName: functionAppName
    location: location
    tags: tags
    sku: 'B1'
    appServicePlanName: 'asp-rsp-fn-process-scan-${replace(functionAppName, 'func-process-scan-', '')}-uks'
    webAppBaseOs: 'Windows'
    subnetIdForVnetInjection: subnetIdForVnetInjection
    deploySlot: false
    privateEndpointRG: resourceGroup().name
    spokeVNetId: spokeVNetId
    subnetPrivateEndpointSubnetId: subnetPrivateEndpointSubnetId
    kind: 'functionapp'
    storageAccountName: storageAccountName
    deployAppPrivateEndPoint: false
    userAssignedIdentities: userAssignedIdentities
    devOpsPublicIPAddress: ''
    isPrivate: false
    logAnalyticsWsId: logAnalyticsWorkspaceId
  }
}

// Note: Permissions will be configured separately after identity is available
// Configure system-assigned managed identity permissions for blob operations (only if storage account ID is provided)
// module permissions '../../../shared/bicep/role-assignments/process-scan-function-permissions.bicep' = if (!empty(documentUploadStorageAccountId)) {
//   name: 'processScanFunctionPermissions'
//   params: {
//     functionAppPrincipalId: functionApp.outputs.systemAssignedPrincipalId
//     documentUploadStorageAccountId: documentUploadStorageAccountId
//   }
// }

// ------------------
// OUTPUTS
// ------------------

@description('The Function App name.')
output functionAppName string = functionAppName

@description('The default hostname of the Function App.')
output functionAppHostName string = functionApp.outputs.appHostName

@description('The webhook endpoint URL for Event Grid integration.')
output webhookEndpoint string = 'https://${functionApp.outputs.appHostName}/api/ProcessScanResultEventTrigger'

@description('The Function App URL.')
output functionAppUrl string = 'https://${functionApp.outputs.appHostName}'

// Note: Additional outputs like functionAppId and systemAssignedPrincipalId 
// need to be added to the app-service module for full functionality