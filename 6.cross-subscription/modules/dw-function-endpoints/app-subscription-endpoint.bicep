targetScope = 'subscription'

// ------------------
// PARAMETERS
// ------------------

@description('Resource ID of the DW Function App (func-validate-irasid)')
param dwFunctionAppId string

@description('Resource group containing the VNet for private endpoint')
param networkingResourceGroup string

@description('VNet name')
param vnetName string

@description('Private endpoint subnet name')
param privateEndpointSubnetName string

@description('Environment name for naming (e.g., dev, manualtest, automationtest, uat, preprod, prod)')
param environment string

// ------------------
// VARIABLES
// ------------------

var functionAppName = last(split(dwFunctionAppId, '/'))
var functionAppBaseName = replace(substring(functionAppName, 5), '-', '')
var privateEndpointName = 'pep-func-${functionAppBaseName}-${environment}'

// ------------------
// EXISTING RESOURCES
// ------------------

resource vnet 'Microsoft.Network/virtualNetworks@2024-07-01' existing = {
  scope: resourceGroup(networkingResourceGroup)
  name: vnetName
}

resource pepSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' existing = {
  parent: vnet
  name: privateEndpointSubnetName
}

// ------------------
// MODULE
// ------------------

module functionAppEndpoint '../../../shared/bicep/network/private-networking-spoke.bicep' = {
  name: take('dwFuncPE-${environment}-${uniqueString(deployment().name)}', 64)
  scope: resourceGroup(networkingResourceGroup)
  params: {
    azServicePrivateDnsZoneName: 'privatelink.azurewebsites.net'
    azServiceId: dwFunctionAppId
    privateEndpointName: privateEndpointName
    privateEndpointSubResourceName: 'sites'
    virtualNetworkLinks: [
      {
        vnetName: vnetName
        vnetId: vnet.id
        registrationEnabled: false
      }
    ]
    subnetId: pepSubnet.id
  }
}

// ------------------
// OUTPUTS
// ------------------

@description('Private endpoint resource ID')
output privateEndpointId string = resourceId(subscription().subscriptionId, networkingResourceGroup, 'Microsoft.Network/privateEndpoints', privateEndpointName)

@description('Private endpoint name')
output privateEndpointName string = privateEndpointName

@description('Environment deployed to')
output environment string = environment
