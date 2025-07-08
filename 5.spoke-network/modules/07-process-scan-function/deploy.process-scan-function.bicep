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

// Function App for processing scan results
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
    createPrivateDnsZones: false
  }
}

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
