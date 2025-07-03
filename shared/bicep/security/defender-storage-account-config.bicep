targetScope = 'resourceGroup'

// ------------------
// PARAMETERS
// ------------------

@description('Storage account resource ID')
param storageAccountId string

@description('Log Analytics workspace resource ID for monitoring (optional)')
param logAnalyticsWorkspaceId string = ''


// ------------------
// VARIABLES
// ------------------

var storageAccountName = split(storageAccountId, '/')[8]

// ------------------
// RESOURCES
// ------------------

// Note: Defender for Storage configuration is handled by the subscription-level resource
// This module focuses on Log Analytics integration for storage account monitoring

// Get reference to the storage account for diagnostic settings
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

// Configure Log Analytics integration for storage account metrics only
// Note: Defender for Storage handles security logging automatically
resource storageAccountLogAnalyticsConfig 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  scope: storageAccount
  name: '${storageAccountName}-monitoring'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
      {
        category: 'Capacity'
        enabled: true
      }
    ]
  }
}

// ------------------
// OUTPUTS
// ------------------

@description('The storage account name configured with monitoring')
output configuredStorageAccountName string = storageAccountName

@description('Log Analytics workspace ID configured for monitoring')
output logAnalyticsWorkspaceId string = logAnalyticsWorkspaceId

@description('Log Analytics diagnostic settings name')
output logAnalyticsConfigName string = !empty(logAnalyticsWorkspaceId) ? '${storageAccountName}-monitoring' : ''
