targetScope = 'subscription'

param sourceVNetID string

@description('The IDs of the Azure services to be used for the private endpoints.')
param serviceIds array

param managementSubscriptionId string
param managementResourceGroupName string

var sourceVNetTokens = split(sourceVNetID, '/')
var sourceVNetName = sourceVNetTokens[8]

//Vnet of Management DevOps Pool 
var vNetLinksDefault = [
  {
    vnetId: sourceVNetID
    vnetName: sourceVNetName
    registrationEnabled: false
  }
]

var privateDNSMap = {
  'Microsoft.ContainerRegistry': 'privatelink.azurecr.io'
  'Microsoft.KeyVault': 'privatelink.vaultcore.azure.net'
  'Microsoft.Sql': 'privatelink${environment().suffixes.sqlServerHostname}'
  'Microsoft.AppConfiguration': 'privatelink.azconfig.io'
  'Microsoft.Storage': 'privatelink.blob.${environment().suffixes.storage}'
  'Microsoft.Web': 'privatelink.azurewebsites.net'
  'Microsoft.ServiceBus': 'privatelink.servicebus.windows.net'
  'Microsoft.App': 'privatelink.${deployment().location}.azurecontainerapps.io'
}

var subResourceNamesMap = {
  'Microsoft.ContainerRegistry': 'registry'
  'Microsoft.KeyVault': 'vault'
  'Microsoft.Sql': 'sqlServer'
  'Microsoft.AppConfiguration': 'configurationStore'
  'Microsoft.Storage': 'blob'
  'Microsoft.Web': 'sites'
  'Microsoft.ServiceBus': 'namespace'
  'Microsoft.App': 'managedEnvironments'
}

resource vnetSpoke 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  scope: resourceGroup(managementSubscriptionId,managementResourceGroupName)
  name: sourceVNetName
}

resource managementPEPSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' existing = {
  parent: vnetSpoke
  name: 'snet-privateendpoints'
}

// Create private endpoints for each service using sequential deployment to avoid race conditions
@batchSize(1)
module privateNetworking '../../../shared/bicep/network/private-networking-spoke.bicep' = [for serviceId in serviceIds: {
  name: take('serviceNetworkDeployment-${last(split(serviceId, '/'))}', 64)
  scope: resourceGroup(managementSubscriptionId,managementResourceGroupName)
  params: {
    location: deployment().location
    azServicePrivateDnsZoneName: privateDNSMap[split(serviceId, '/')[6]]
    azServiceId: serviceId
    privateEndpointSubResourceName: subResourceNamesMap[split(serviceId, '/')[6]]
    virtualNetworkLinks: vNetLinksDefault
    subnetId: managementPEPSubnet.id
    privateEndpointName: 'pep-${last(split(serviceId, '/'))}-management'
  }
}]
