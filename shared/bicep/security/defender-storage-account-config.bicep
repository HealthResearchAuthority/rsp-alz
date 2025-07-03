targetScope = 'resourceGroup'

// ------------------
// PARAMETERS
// ------------------

@description('Storage account resource ID')
param storageAccountId string

@description('Enable malware scanning for this storage account')
param enableMalwareScanning bool = true

@description('Enable sensitive data discovery for this storage account')
param enableSensitiveDataDiscovery bool = true

@description('Monthly scanning cap in GB for this storage account')
param malwareScanningCapGBPerMonth int = 1000

@description('Event Grid custom topic resource ID for scan results')
param eventGridCustomTopicId string = ''

@description('Log Analytics workspace resource ID for scan results (optional)')
param logAnalyticsWorkspaceId string = ''


// ------------------
// VARIABLES
// ------------------

var storageAccountName = split(storageAccountId, '/')[8]

// ------------------
// RESOURCES
// ------------------

// Note: Defender for Storage configuration is handled by the subscription-level policy
// Individual storage account configuration will be applied via the policy assignment
// This module focuses on Log Analytics integration for scan results

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
        retentionPolicy: {
          enabled: true
          days: 180
        }
      }
      {
        category: 'Capacity'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 180
        }
      }
    ]
  }
}

// ------------------
// OUTPUTS
// ------------------

@description('The storage account name configured with Defender')
output configuredStorageAccountName string = storageAccountName

@description('Indicates whether malware scanning is enabled')
output malwareScanningEnabled bool = enableMalwareScanning

@description('Monthly scanning cap configured')
output scanningCapGB int = malwareScanningCapGBPerMonth

@description('Log Analytics workspace ID configured for scan results')
output logAnalyticsWorkspaceId string = logAnalyticsWorkspaceId

@description('Log Analytics diagnostic settings name')
output logAnalyticsConfigName string = !empty(logAnalyticsWorkspaceId) ? '${storageAccountName}-defender-logs' : ''
