targetScope = 'subscription'

// ------------------
// PARAMETERS
// ------------------

@description('Enable Microsoft Defender for Storage')
param enableDefenderForStorage bool = true

@description('Enable malware scanning for storage accounts')
param enableMalwareScanning bool = false

@description('Enable sensitive data discovery for storage accounts')
param enableSensitiveDataDiscovery bool = true

// Note: Malware scanning caps are configured at storage account level via defenderForStorageSettings

// ------------------
// RESOURCES
// ------------------

// Enable Microsoft Defender for Storage at subscription level
resource defenderForStorage 'Microsoft.Security/pricings@2023-01-01' = {
  name: 'StorageAccounts'
  properties: enableDefenderForStorage ? {
    pricingTier: 'Standard'
    subPlan: 'DefenderForStorageV2'
    extensions: [
      {
        name: 'OnUploadMalwareScanning'
        isEnabled: enableMalwareScanning ? 'True' : 'False'
      }
      {
        name: 'SensitiveDataDiscovery'
        isEnabled: enableSensitiveDataDiscovery ? 'True' : 'False'
      }
    ]
  } : {
    pricingTier: 'Free'
  }
}

// ------------------
// OUTPUTS
// ------------------

@description('Indicates whether Microsoft Defender for Storage is enabled')
output defenderForStorageEnabled bool = enableDefenderForStorage

@description('Indicates whether malware scanning is enabled')
output malwareScanningEnabled bool = enableMalwareScanning

@description('Indicates whether sensitive data discovery is enabled')
output sensitiveDataDiscoveryEnabled bool = enableSensitiveDataDiscovery

// Note: Malware scanning caps are managed at storage account level

@description('The resource ID of the Defender for Storage configuration')
output defenderForStorageId string = defenderForStorage.id