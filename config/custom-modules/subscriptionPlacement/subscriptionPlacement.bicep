targetScope = 'managementGroup'

metadata name = 'ALZ Bicep - Subscription Placement module'
metadata description = 'Module used to place subscriptions in management groups'

@sys.description('Array of Subscription Ids that should be moved to the new management group.')
param parSubscriptionIds array = []

// @sys.description('Target management group for the subscription. This management group must exist.')
 param parTargetManagementGroupId string

// @sys.description('Target management group for the subscription. This management group must exist.')
// param parTargetManagementGroupName string

@sys.description('Set Parameter to true to Opt-out of deployment telemetry.')
param parTelemetryOptOut bool = false

// Customer Usage Attribution Id
var varCuaid = '3dfa9e81-f0cf-4b25-858e-167937fd380b'

resource targetManagementGroup 'Microsoft.Management/managementGroups@2023-04-01' existing = {
  scope: tenant()
  name: parTargetManagementGroupId
}

resource resSubscriptionPlacement 'Microsoft.Management/managementGroups/subscriptions@2023-04-01' = [for subscriptionId in parSubscriptionIds: {
  name: '${subscriptionId}'
  parent: targetManagementGroup
}]

// Optional Deployment for Customer Usage Attribution
module modCustomerUsageAttribution '../../custom-modules/CRML/customerUsageAttribution/cuaIdManagementGroup.bicep' = if (!parTelemetryOptOut) {
  #disable-next-line no-loc-expr-outside-params //Only to ensure telemetry data is stored in same location as deployment. See https://github.com/Azure/ALZ-Bicep/wiki/FAQ#why-are-some-linter-rules-disabled-via-the-disable-next-line-bicep-function for more information
  name: 'pid-${varCuaid}-${uniqueString(deployment().location)}'
  params: {}
}
