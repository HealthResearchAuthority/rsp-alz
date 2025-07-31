targetScope = 'resourceGroup'

@description('Required. Virtual network information for DNS zone linking.')
param virtualNetworkInfo object

@description('Optional. Tags to be applied to all resources.')
param tags object = {}

@description('Optional. Location for the private DNS zones.')
param location string = 'global'

// Define all private DNS zones used in this project
var privateDnsZones = [
  'privatelink.azurewebsites.net'           // App Services & Function Apps
  'privatelink.database.${environment().suffixes.sqlServerHostname}'  // SQL Database
  'privatelink.azurecr.io'                  // Container Registry
  'privatelink.blob.${environment().suffixes.storage}'  // Storage Blob
  'privatelink.file.${environment().suffixes.storage}'  // Storage File
  'privatelink.azconfig.io'                 // App Configuration
  'privatelink.servicebus.windows.net'      // Service Bus
  'privatelink.vaultcore.azure.net'         // Key Vault
]

// Create private DNS zones
resource privateDnsZones_resource 'Microsoft.Network/privateDnsZones@2024-06-01' = [for zone in privateDnsZones: {
  name: zone
  location: location
  tags: tags
}]

// Create virtual network links for each DNS zone
resource privateDnsZoneLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = [for (zone, zoneIndex) in privateDnsZones: {
  parent: privateDnsZones_resource[zoneIndex]
  name: '${virtualNetworkInfo.name}-link'
  location: location
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworkInfo.id
    }
  }
}]

// ------------------
// OUTPUTS
// ------------------

@description('Private DNS Zone resource IDs mapped by service type.')
output privateDnsZoneIds object = {
  appServices: privateDnsZones_resource[0].id
  sqlDatabase: privateDnsZones_resource[1].id
  containerRegistry: privateDnsZones_resource[2].id
  storageBlob: privateDnsZones_resource[3].id
  storageFile: privateDnsZones_resource[4].id
  appConfiguration: privateDnsZones_resource[5].id
  serviceBus: privateDnsZones_resource[6].id
  keyVault: privateDnsZones_resource[7].id
}

@description('All private DNS zone resource IDs as an array.')
output allPrivateDnsZoneIds array = [for (zone, zoneIndex) in privateDnsZones: privateDnsZones_resource[zoneIndex].id]

@description('Private DNS zone names mapped by service type.')
output privateDnsZoneNames object = {
  appServices: privateDnsZones_resource[0].name
  sqlDatabase: privateDnsZones_resource[1].name
  containerRegistry: privateDnsZones_resource[2].name
  storageBlob: privateDnsZones_resource[3].name
  storageFile: privateDnsZones_resource[4].name
  appConfiguration: privateDnsZones_resource[5].name
  serviceBus: privateDnsZones_resource[6].name
  keyVault: privateDnsZones_resource[7].name
}