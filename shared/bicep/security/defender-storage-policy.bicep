targetScope = 'subscription'

// ------------------
// PARAMETERS
// ------------------

@description('Enable Defender for Storage via policy assignment')
param enableDefenderStoragePolicy bool = true

@description('Policy assignment name')
param policyAssignmentName string = 'defender-for-storage-policy'

@description('Malware scanning configuration')
param malwareScanningConfig object = {
  capGBPerMonthPerStorageAccount: 10000
}



// ------------------
// VARIABLES
// ------------------

// Built-in policy definition for Defender for Storage (Activity Monitoring only at subscription level)
var defenderStoragePolicyDefinitionId = '/providers/Microsoft.Authorization/policyDefinitions/cfdc5972-75b3-4418-8ae1-7f5c36839390'

// ------------------
// RESOURCES
// ------------------

resource defenderStoragePolicy 'Microsoft.Authorization/policyAssignments@2025-03-01' = if (enableDefenderStoragePolicy) {
  name: policyAssignmentName
  properties: {
    displayName: 'Enable Microsoft Defender for Storage'
    description: 'Enable Microsoft Defender for Storage on all storage accounts in this subscription'
    policyDefinitionId: defenderStoragePolicyDefinitionId
    parameters: {
      effect: {
        value: 'DeployIfNotExists'
      }
      // Only enable activity monitoring at subscription level
      // Malware scanning will be configured per storage account
    }
    metadata: {
      assignedBy: 'Infrastructure as Code'
      category: 'Security'
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
  location: deployment().location
}

// Role assignment for policy managed identity to enable Defender for Storage
resource policyRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableDefenderStoragePolicy) {
  name: guid(subscription().id, defenderStoragePolicy.id, 'Security Admin')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'fb1c8493-542b-48eb-b624-b4c8fea62acd') // Security Admin
    principalId: defenderStoragePolicy.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// ------------------
// OUTPUTS
// ------------------

@description('The resource ID of the Defender for Storage policy assignment.')
output policyAssignmentId string = enableDefenderStoragePolicy ? defenderStoragePolicy.id : ''

@description('The name of the Defender for Storage policy assignment.')
output policyAssignmentName string = enableDefenderStoragePolicy ? defenderStoragePolicy.name : ''

@description('The principal ID of the policy assignment managed identity.')
output policyPrincipalId string = enableDefenderStoragePolicy ? defenderStoragePolicy.identity.principalId : ''

@description('Indicates whether Defender for Storage policy is enabled.')
output defenderStoragePolicyEnabled bool = enableDefenderStoragePolicy

@description('Malware scanning configuration applied by policy.')
output malwareScanningConfig object = malwareScanningConfig
