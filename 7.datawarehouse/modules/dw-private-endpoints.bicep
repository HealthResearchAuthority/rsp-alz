@description('Location for all resources')
param location string

@description('VNet ID where private endpoints will be created')
param vnetId string

@description('Private endpoint subnet name')
param privateEndpointSubnetName string

@description('Environment name')
param environment string

@description('Tags to apply to all resources')
param tags object = {}

var resourceTags = union(tags, {
  Environment: environment
})

// SQL Server private endpoint parameters
// @description('SQL Server resource ID for private endpoint creation')
// param sqlServerResourceId string = ''

// @description('SQL Server name for private endpoint naming')
// param sqlServerName string = ''

// Function App private endpoint parameters
@description('Array of Function App resource IDs for private endpoint creation')
param functionAppResourceIds array = []

@description('Array of Function App names for private endpoint naming')
param functionAppNames array = []

// Storage Account private endpoint parameters
@description('Array of Storage Account resource IDs for private endpoint creation')
param storageAccountResourceIds array = []

@description('Array of Storage Account names for private endpoint naming')
param storageAccountNames array = []

// Reference existing Vnet and subnet

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: split(vnetId, '/')[8]
}

resource privateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: vnet
  name: privateEndpointSubnetName
}

// resource sqlPrivateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = if (!empty(sqlServerResourceId)) {
//   name: 'privatelink$(az.environment().suffixes.sqlServerHostname)'
//   location: 'global'
//   tags: resourceTags
// }

// resource sqlDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (!empty(sqlServerResourceId)) {
//   parent: sqlPrivateDnsZone
//   name: '${vnet.name}-link'
//   location: 'global'
//   properties: {
//     registrationEnabled: false
//     virtualNetwork: {
//       id: vnetId
//     }
//   }
//   tags: resourceTags
// }

// Function Apps DNS Zones and Vnet Links
resource functionAppsPrivateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = if (length(functionAppResourceIds) > 0) {
  name: 'privatelink.azurewebsites.net'
  location: 'global'
  tags: resourceTags
}

resource functionAppsDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (length(functionAppResourceIds) > 0) {
  parent: functionAppsPrivateDnsZone
  name: '${vnet.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
  tags: resourceTags
}

// Storage Blob DNS Zones and Vnet Links
resource storageBlobPrivateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = if (length(storageAccountResourceIds) > 0) {
  name: 'privatelink.blob.${az.environment().suffixes.storage}'
  location: 'global'
  tags: resourceTags
}

resource storageBlobDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (length(storageAccountResourceIds) > 0) {
  parent: storageBlobPrivateDnsZone
  name: '${vnet.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
  tags: resourceTags
}

// Storage File DNS Zones and Vnet Links
resource storageFilePrivateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = if (length(storageAccountResourceIds) > 0) {
  name: 'privatelink.file.${az.environment().suffixes.storage}'
  location: 'global'
  tags: resourceTags
}

resource storageFileDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (length(storageAccountResourceIds) > 0) {
  parent: storageFilePrivateDnsZone
  name: '${vnet.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
  tags: resourceTags
}

// --------------------
//  PRIVATE ENDPOINTS
// --------------------

// resource sqlServerPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = if (!empty(sqlServerResourceId)) {
//   name: 'pep-${sqlServerName}'
//   location: location
//   tags: resourceTags
//   properties: {
//     subnet: {
//       id: privateEndpointSubnet.id
//     }
//     privateLinkServiceConnections: [
//       {
//         name: 'pep-${sqlServerName}'
//         properties: {
//           privateLinkServiceId: sqlServerResourceId
//           groupIds: [
//             'sqlServer'
//           ]
//         }
//       }
//     ]
//   }
// }

// resource sqlServerPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = if (!empty(sqlServerResourceId)) {
//   parent: sqlServerPrivateEndpoint
//   name: 'default'
//   properties: {
//     privateDnsZoneConfigs: [
//       {
//         name: 'privatelink-database-windows-net'
//         properties: {
//           privateDnsZoneId: sqlPrivateDnsZone.id
//         }
//       }
//     ]
//   }
// }

resource functionAppPrivateEndpoints 'Microsoft.Network/privateEndpoints@2024-05-01' = [for (functionAppId, index) in functionAppResourceIds: {
  name: 'pep-${functionAppNames[index]}'
  location: location
  tags: resourceTags
  properties: {
    subnet: {
      id: privateEndpointSubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: 'pep-${functionAppNames[index]}'
        properties: {
          privateLinkServiceId: functionAppId
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }
}]

resource functionAppPrivateDnsZoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = [for (functionAppId, index) in functionAppResourceIds: {
  parent: functionAppPrivateEndpoints[index]
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-azurewebsites-net'
        properties: {
          privateDnsZoneId: functionAppsPrivateDnsZone.id
        }
      }
    ]
  }
}]

resource storageAccountBlobPrivateEndpoints 'Microsoft.Network/privateEndpoints@2024-05-01' = [for (storageAccountId, index) in storageAccountResourceIds: {
  name: 'pep-${storageAccountNames[index]}-blob'
  location: location
  tags: resourceTags
  properties: {
    subnet: {
      id: privateEndpointSubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: 'pep-${storageAccountNames[index]}-blob'
        properties: {
          privateLinkServiceId: storageAccountId
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}]

resource storageAccountBlobPrivateDnsZoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = [for (storageAccountId, index) in storageAccountResourceIds: {
  parent: storageAccountBlobPrivateEndpoints[index]
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-blob-core-windows-net'
        properties: {
          privateDnsZoneId: storageBlobPrivateDnsZone.id
        }
      }
    ]
  }
}]

resource storageAccountFilePrivateEndpoints 'Microsoft.Network/privateEndpoints@2024-05-01' = [for (storageAccountId, index) in storageAccountResourceIds: {
  name: 'pep-${storageAccountNames[index]}-file'
  location: location
  tags: resourceTags
  properties: {
    subnet: {
      id: privateEndpointSubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: 'pep-${storageAccountNames[index]}-file'
        properties: {
          privateLinkServiceId: storageAccountId
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}]

resource storageAccountFilePrivateDnsZoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = [for (storageAccountId, index) in storageAccountResourceIds: {
  parent: storageAccountFilePrivateEndpoints[index]
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-file-core-windows-net'
        properties: {
          privateDnsZoneId: storageFilePrivateDnsZone.id
        }
      }
    ]
  }
}]


// -------------------
//    OUTPUTS
// -------------------

// @description('SQL Server private endpoint resource ID')
// output sqlServerPrivateEndpointId string = !empty(sqlServerResourceId) ? sqlServerPrivateEndpoint.id : ''

@description('Function App private endpoint resource IDs')
output functionAppPrivateEndpointIds array = [for (functionAppId, index) in functionAppResourceIds: functionAppPrivateEndpoints[index].id]

@description('Storage Account blob private endpoint resource IDs')
output storageAccountBlobPrivateEndpointIds array = [for (storageAccountId, index) in storageAccountResourceIds: storageAccountBlobPrivateEndpoints[index].id]

@description('Storage Account file private endpoint resource IDs')
output storageAccountFilePrivateEndpointIds array = [for (storageAccountId, index) in storageAccountResourceIds: storageAccountFilePrivateEndpoints[index].id]

@description('Private DNS Zone resource IDs')
output privateDnsZoneIds object = {
  // sqlServer: !empty(sqlServerResourceId) ? sqlPrivateDnsZone.id : ''
  functionApps: length(functionAppResourceIds) > 0 ? functionAppsPrivateDnsZone.id : ''
  storageBlob: length(storageAccountResourceIds) > 0 ? storageBlobPrivateDnsZone.id : ''
  storageFile: length(storageAccountResourceIds) > 0 ? storageFilePrivateDnsZone.id : ''
}
