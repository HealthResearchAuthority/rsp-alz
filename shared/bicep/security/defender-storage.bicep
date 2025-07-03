targetScope = 'subscription'

// ------------------
// PARAMETERS
// ------------------

@description('Enable Microsoft Defender for Storage')
param enableDefenderForStorage bool = true

@description('Enable malware scanning for storage accounts')
param enableMalwareScanning bool = true

@description('Enable sensitive data discovery for storage accounts')
param enableSensitiveDataDiscovery bool = true

@description('Monthly malware scanning cap in GB per storage account')
param malwareScanningCapGBPerMonth int = 1000

// ------------------
// RESOURCES
// ------------------

// Enable Microsoft Defender for Storage at subscription level
resource defenderForStorage 'Microsoft.Security/pricings@2023-01-01' = if (enableDefenderForStorage) {
  name: 'StorageAccounts'
  properties: {
    pricingTier: 'Standard'
    subPlan: 'DefenderForStorageV2'
    extensions: [
      {
        name: 'OnUploadMalwareScanning'
        isEnabled: enableMalwareScanning ? 'True' : 'False'
        additionalExtensionProperties: {
          CapGBPerMonthPerStorageAccount: string(malwareScanningCapGBPerMonth)
        }
      }
      {
        name: 'SensitiveDataDiscovery'
        isEnabled: enableSensitiveDataDiscovery ? 'True' : 'False'
      }
    ]
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

@description('Monthly malware scanning cap in GB per storage account')
output malwareScanningCapGB int = malwareScanningCapGBPerMonth

@description('The resource ID of the Defender for Storage configuration')
output defenderForStorageId string = enableDefenderForStorage ? defenderForStorage.id : ''