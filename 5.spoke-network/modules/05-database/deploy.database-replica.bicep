targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------

@description('Name of the secondary SQL Server (e.g., rspsqlserverdevreplica)')
param secondarySqlServerName string

@description('The location where the secondary resources will be created (secondary region).')
param secondaryLocation string = resourceGroup().location

@description('Admin login for SQL Server (must match primary)')
@minLength(1)
param adminLogin string

@secure()
@description('Admin password for SQL Server (must match primary)')
param adminPassword string

@description('Enable or disable SQL Server password authentication (default: false)')
param enableSqlAdminLogin bool = false

@description('Array of primary database resource IDs to replicate')
param primaryDatabaseIds array

@description('Array of database names (must match primary databases)')
param databases array = []

@description('The resource ID of the secondary region VNet to which the private endpoint will be connected.')
param secondaryVNetId string

@description('The name of the subnet in the secondary VNet to which the private endpoint will be connected.')
param secondaryPrivateEndpointSubnetName string

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

@description('Name of the SQL Server User Assigned Identity')
param sqlServerUAIName string = ''

@description('Networking resources names object')
param networkingResourcesNames object

@description('The name of the networking resource group in the secondary region')
param networkingResourceGroup string

@description('How long to keep audit logs (default: 30 days)')
param auditRetentionDays int = 30

@description('Enable or disable SQL Server auditing (default: true)')
param enableSqlServerAuditing bool = true

@description('The resource id of an existing Log Analytics Workspace.')
param logAnalyticsWorkspaceId string

@description('SQL Database SKU configuration (must match primary)')
param sqlDatabaseSkuConfig object = {
  name: 'GP_S_Gen5'
  tier: 'GeneralPurpose'
  family: 'Gen5'
  capacity: 12
  minCapacity: 6
  storageSize: '6GB'
  zoneRedundant: false
}

// ------------------
// VARIABLES
// ------------------

var privateDnsZoneNames = 'privatelink${az.environment().suffixes.sqlServerHostname}'
var sqlServerResourceName = 'sqlServer'

var secondaryVNetIdTokens = split(secondaryVNetId, '/')
var secondarySubscriptionId = secondaryVNetIdTokens[2]
var secondaryResourceGroupName = secondaryVNetIdTokens[4]
var secondaryVNetName = secondaryVNetIdTokens[8]

var sqlServerContributorRoleGuid = '9b7fa17d-e63e-47b0-bb0a-15c516ac86ec'

var secondaryVNetLinks = [
  {
    vnetName: secondaryVNetName
    vnetId: secondaryVNetSpoke.id
    registrationEnabled: false
  }
]

// ------------------
//    Resources
// ------------------

resource secondaryVNetSpoke 'Microsoft.Network/virtualNetworks@2024-07-01' existing = {
  scope: resourceGroup(secondarySubscriptionId, secondaryResourceGroupName)
  name: secondaryVNetName
}

resource secondaryPrivateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' existing = {
  parent: secondaryVNetSpoke
  name: secondaryPrivateEndpointSubnetName
}

resource sqlServerUserAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: sqlServerUAIName
  location: secondaryLocation
  tags: tags
}

// Secondary SQL Server Resource
resource SecondarySQL_Server 'Microsoft.Sql/servers@2024-05-01-preview' = {
  name: secondarySqlServerName
  location: secondaryLocation
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${sqlServerUserAssignedIdentity.id}': {}
    }
  }
  properties: {
    administratorLogin: adminLogin
    administratorLoginPassword: adminPassword
    publicNetworkAccess: 'Disabled'
    primaryUserAssignedIdentityId: sqlServerUserAssignedIdentity.id
  }
}

// Set Azure AD Administrator (must match primary)
resource azureADAdmin 'Microsoft.Sql/servers/administrators@2024-05-01-preview' = {
  name: 'activeDirectory'
  parent: SecondarySQL_Server
  properties: {
    login: 'nikhil.bharathesh_PA@hra.nhs.uk'
    tenantId: '8e1f0aca-d87d-4f20-939e-36243d574267'
    sid: '9a3eae88-0bf5-41d8-8791-92ddfe098a0b'
    administratorType: 'ActiveDirectory'
  }
}

// Enable Azure AD-only authentication (disables SQL authentication)
resource azureADOnlyAuth 'Microsoft.Sql/servers/azureADOnlyAuthentications@2024-05-01-preview' = if (!enableSqlAdminLogin) {
  name: 'Default'
  parent: SecondarySQL_Server
  properties: {
    azureADOnlyAuthentication: true
  }
  dependsOn: [
    azureADAdmin
  ]
}

module sqlserveradminRoleAssignment '../../../shared/bicep/role-assignments/role-assignment.bicep' = {
  name: take('sqlServerContributorRoleAssignmentDeployment-${deployment().name}', 64)
  params: {
    name: 'ra-sqlServerContributorRoleAssignment'
    principalId: sqlServerUserAssignedIdentity.properties.principalId
    resourceId: SecondarySQL_Server.id
    roleDefinitionId: sqlServerContributorRoleGuid
    principalType: 'ServicePrincipal'
  }
}

resource masterDb 'Microsoft.Sql/servers/databases@2021-11-01-preview' = {
  parent: SecondarySQL_Server
  location: secondaryLocation
  name: 'master'
  properties: {}
}

// Secondary databases with createMode: 'Secondary' for Active Geo-Replication
// Note: batchSize(1) ensures databases are created sequentially to avoid "Server is busy" conflicts
// dependsOn azureADOnlyAuth to ensure Azure AD configuration completes before geo-replication starts
@batchSize(1)
resource secondaryDatabases 'Microsoft.Sql/servers/databases@2024-05-01-preview' = [for i in range(0, length(primaryDatabaseIds)): {
  name: databases[i]
  parent: SecondarySQL_Server
  location: secondaryLocation
  sku: {
    name: sqlDatabaseSkuConfig.name
    tier: sqlDatabaseSkuConfig.tier
    family: sqlDatabaseSkuConfig.family
    capacity: sqlDatabaseSkuConfig.capacity
    size: sqlDatabaseSkuConfig.storageSize
  }
  properties: {
    createMode: 'Secondary'
    sourceDatabaseId: primaryDatabaseIds[i]
    requestedBackupStorageRedundancy: 'Local'
  }
  dependsOn: [
    azureADOnlyAuth  // Wait for Azure AD async operations to complete before starting geo-replication
  ]
}]

resource advancedThreatProtection 'Microsoft.Sql/servers/advancedThreatProtectionSettings@2024-05-01-preview' = {
  name: 'default'
  parent: SecondarySQL_Server
  properties: {
    state: 'Enabled'
  }
}

resource serverSecurityAlertPolicy 'Microsoft.Sql/servers/securityAlertPolicies@2022-11-01-preview' = {
  parent: SecondarySQL_Server
  name: 'Default'
  properties: {
    state: 'Enabled'
    retentionDays: 90
    emailAccountAdmins: true
    emailAddresses: [
      'nikhil.bharathesh_pa@hra.nhs.uk'
    ]
  }
  dependsOn: [
    advancedThreatProtection
  ]
}

resource sqlVulnerabilityAssessment 'Microsoft.Sql/servers/sqlVulnerabilityAssessments@2022-11-01-preview' = {
  name: 'default'
  parent: SecondarySQL_Server
  properties: {
    state: 'Enabled'
  }
  dependsOn: [
    serverSecurityAlertPolicy
  ]
}

resource sqlAuditingSetting 'Microsoft.Sql/servers/auditingSettings@2024-05-01-preview' = if (enableSqlServerAuditing) {
  parent: SecondarySQL_Server
  name: 'default'
  properties: {
    state: 'Enabled'
    isAzureMonitorTargetEnabled: true
    retentionDays: auditRetentionDays
  }
}

// Diagnostic settings for master database
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'SQLSecurityAuditLogs'
  scope: masterDb
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'SQLSecurityAuditEvents'
        enabled: true
      }
    ]
  }
}

// Private endpoint for secondary SQL Server
module sqlServerNetwork '../../../shared/bicep/network/private-networking-spoke.bicep' = {
  name: 'sqlServerNetwork-${uniqueString(SecondarySQL_Server.id)}'
  scope: resourceGroup(secondarySubscriptionId, networkingResourceGroup)
  params: {
    location: secondaryLocation
    azServicePrivateDnsZoneName: privateDnsZoneNames
    azServiceId: SecondarySQL_Server.id
    privateEndpointName: networkingResourcesNames.azuresqlserverpep
    privateEndpointSubResourceName: sqlServerResourceName
    virtualNetworkLinks: secondaryVNetLinks
    subnetId: secondaryPrivateEndpointSubnet.id
  }
  dependsOn: [
    secondaryDatabases  // Wait for geo-replication to complete before exposing via private endpoint
  ]
}

// ------------------
// OUTPUTS
// ------------------

output sqlServer_name string = SecondarySQL_Server.name
output sqlServer_id string = SecondarySQL_Server.id
output outputsqlServerUAIID string = sqlServerUserAssignedIdentity.id
output outputsqlServerUAIName string = sqlServerUserAssignedIdentity.name
output outputsqlServerUAIClientID string = sqlServerUserAssignedIdentity.properties.clientId

output database_names array = [for i in range(0, length(databases)): {
  name: databases[i]
  id: secondaryDatabases[i].id
}]

