targetScope = 'managementGroup'

metadata name = 'ALZ Bicep - Subscription Placement module'
metadata description = 'Module used to place subscriptions in management groups'

@sys.description('Array of Subscription Ids that should be moved to the new management group.')
param parSubscriptionIds array = []

 @sys.description('Target management group for the subscription. This management group must exist.')
 param parTargetManagementGroupId string

resource targetManagementGroup 'Microsoft.Management/managementGroups@2023-04-01' existing = {
  scope: tenant()
  name: parTargetManagementGroupId
}

resource resSubscriptionPlacement 'Microsoft.Management/managementGroups/subscriptions@2023-04-01' = [for subscriptionId in parSubscriptionIds: {
  name: '${subscriptionId}'
  parent: targetManagementGroup
}]
