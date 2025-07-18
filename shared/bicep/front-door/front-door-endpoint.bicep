// ------------------
// PARAMETERS
// ------------------

@description('Required. Name of the Front Door endpoint.')
param name string

@description('Required. The name of the Front Door profile.')
param frontDoorProfileName string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Optional. Tags of the resource.')
param tags object?

@description('Optional. Whether the endpoint is enabled.')
param enabled bool = true


@description('Optional. The custom domains for the endpoint.')
param customDomains array = []

@description('Optional. Enable managed TLS certificates.')
param enableManagedTls bool = true

@description('Optional. The minimum TLS version.')
@allowed([
  'TLS10'
  'TLS12'
])
param minimumTlsVersion string = 'TLS12'

// ------------------
// RESOURCES
// ------------------

resource frontDoorProfile 'Microsoft.Cdn/profiles@2023-05-01' existing = {
  name: frontDoorProfileName
}

resource frontDoorEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2023-05-01' = {
  name: name
  parent: frontDoorProfile
  location: location
  tags: tags
  properties: {
    enabledState: enabled ? 'Enabled' : 'Disabled'
  }
}

// Create custom domains if specified
resource customDomain 'Microsoft.Cdn/profiles/customDomains@2023-05-01' = [for domain in customDomains: {
  name: domain.name
  parent: frontDoorProfile
  properties: {
    hostName: domain.hostName
    tlsSettings: enableManagedTls ? {
      certificateType: 'ManagedCertificate'
      minimumTlsVersion: minimumTlsVersion
    } : null
    azureDnsZone: contains(domain, 'azureDnsZone') ? {
      id: domain.azureDnsZone.id
    } : null
    preValidatedCustomDomainResourceId: contains(domain, 'preValidatedCustomDomainResourceId') ? {
      id: domain.preValidatedCustomDomainResourceId
    } : null
  }
}]

// ------------------
// OUTPUTS
// ------------------

@description('The resource ID of the Front Door endpoint.')
output resourceId string = frontDoorEndpoint.id

@description('The name of the Front Door endpoint.')
output name string = frontDoorEndpoint.name

@description('The location the resource was deployed into.')
output location string = frontDoorEndpoint.location

@description('The host name of the Front Door endpoint.')
output hostName string = frontDoorEndpoint.properties.hostName

@description('The resource group the Front Door endpoint was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The custom domains created.')
output customDomains array = [for (domain, i) in customDomains: {
  name: customDomain[i].name
  hostName: customDomain[i].properties.hostName
  resourceId: customDomain[i].id
}]