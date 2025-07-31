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

@description('Required. Name of the App Service Plan.')
@minLength(1)
@maxLength(40)
param appServicePlanName string

@description('Enable private endpoint for function app')
param deployAppPrivateEndPoint bool = false

@description('Resource Group where PEP and PEP DNS needs to be deployed')
param privateEndpointRG string = resourceGroup().name

@description('SQL Database managed identity client ID for database access')
param sqlDBManagedIdentityClientId string = ''


// Note: Storage permissions are handled separately in main.application.bicep

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
    appServicePlanName: appServicePlanName
    webAppBaseOs: 'Windows'
    subnetIdForVnetInjection: subnetIdForVnetInjection
    deploySlot: false
    privateEndpointRG: privateEndpointRG
    spokeVNetId: spokeVNetId
    subnetPrivateEndpointSubnetId: subnetPrivateEndpointSubnetId
    kind: 'functionapp'
    storageAccountName: storageAccountName
    deployAppPrivateEndPoint: deployAppPrivateEndPoint
    userAssignedIdentities: userAssignedIdentities
    sqlDBManagedIdentityClientId: sqlDBManagedIdentityClientId
    logAnalyticsWsId: logAnalyticsWorkspaceId
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

@description('The system-assigned managed identity principal ID of the Function App.')
output systemAssignedPrincipalId string = functionApp.outputs.systemAssignedPrincipalId
