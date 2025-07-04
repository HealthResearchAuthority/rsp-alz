targetScope = 'resourceGroup'

// ------------------
// PARAMETERS
// ------------------

@description('Storage account resource ID')
param storageAccountId string

@description('Enable malware scanning for this storage account')
param enableMalwareScanning bool = true

@description('Monthly malware scanning cap in GB for this storage account')
param malwareScanningCapGBPerMonth int = 1000

@description('Enable sensitive data discovery for this storage account')
param enableSensitiveDataDiscovery bool = true

@description('Log Analytics workspace resource ID for monitoring (optional)')
param logAnalyticsWorkspaceId string = ''

@description('Custom Event Grid topic resource ID for scan results (optional)')
param customEventGridTopicId string = ''


// ------------------
// VARIABLES
// ------------------

var storageAccountName = split(storageAccountId, '/')[8]

// ------------------
// RESOURCES
// ------------------

// Get reference to the storage account for diagnostic settings
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

// Configure storage account-level Defender for Storage settings with override
resource defenderForStorageSettings 'Microsoft.Security/defenderForStorageSettings@2022-12-01-preview' = if (enableMalwareScanning) {
  scope: storageAccount
  name: 'current'
  properties: {
    isEnabled: true
    malwareScanning: {
      onUpload: {
        isEnabled: enableMalwareScanning
        capGBPerMonth: malwareScanningCapGBPerMonth
      }
      scanResultsEventGridTopicResourceId: !empty(customEventGridTopicId) ? customEventGridTopicId : null
    }
    sensitiveDataDiscovery: {
      isEnabled: enableSensitiveDataDiscovery
    }
    overrideSubscriptionLevelSettings: true
  }
}

// Configure Log Analytics integration for storage account metrics
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

@description('The storage account name configured with Defender')
output configuredStorageAccountName string = storageAccountName

@description('Indicates whether malware scanning is enabled for this storage account')
output malwareScanningEnabled bool = enableMalwareScanning

@description('Monthly malware scanning cap configured for this storage account')
output scanningCapGB int = malwareScanningCapGBPerMonth

@description('Indicates whether sensitive data discovery is enabled for this storage account')
output sensitiveDataDiscoveryEnabled bool = enableSensitiveDataDiscovery

@description('Log Analytics workspace ID configured for monitoring')
output logAnalyticsWorkspaceId string = logAnalyticsWorkspaceId

@description('Log Analytics diagnostic settings name')
output logAnalyticsConfigName string = !empty(logAnalyticsWorkspaceId) ? '${storageAccountName}-monitoring' : ''
