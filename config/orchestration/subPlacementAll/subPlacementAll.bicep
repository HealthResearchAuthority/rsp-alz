targetScope = 'managementGroup'

metadata name = 'ALZ Bicep orchestration - Subscription Placement - ALL'
metadata description = 'Orchestration module that helps to define where all Subscriptions should be placed in the ALZ Management Group Hierarchy'

@sys.description('Prefix used for the management group hierarchy.')
@minLength(2)
@maxLength(10)
param parTopLevelManagementGroupPrefix string = 'mg-rsp'

@sys.description('An array of Subscription IDs to place in the Platform Management Group. Default: Empty Array')
param parPlatformMgSubs array = []

@sys.description('An array of Subscription IDs to place in the (Platform) Management Management Group. Default: Empty Array')
param parPlatformManagementMgSubs array = ['8747cd7f-1a06-4fe4-9dbb-24f612b9dd5a']

@sys.description('An array of Subscription IDs to place in the (Platform) Connectivity Management Group. Default: Empty Array')
param parPlatformConnectivityMgSubs array = ['15642d2a-27a2-4ee8-9eba-788bf7223d95']

@sys.description('An array of Subscription IDs to place in the PROD Management Group. Default: Empty Array')
param parLandingZonesProdMgSubs array = []

@sys.description('An array of Subscription IDs to place in the NONPROD Management Group. Default: Empty Array')
param parLandingZonesNonProdMgSubs array = [
    'b83b4631-b51b-4961-86a1-295f539c826b' //Development
    '66482e26-764b-4717-ae2f-fab6b8dd1379' //System Test Manual
    'c9d1b222-c47a-43fc-814a-33083b8d3375' //System Test integration
    '75875981-b04d-42c7-acc5-073e2e5e2e65' //System Test Automated
]

@sys.description('An array of Subscription IDs to place in the Confidential Corp (Landing Zones) Management Group. Default: Empty Array')
param parDevBoxMgSubs array = ['9ef9a127-7a6e-452e-b18d-d2e2e89ffa92']

@sys.description('Set Parameter to true to Opt-out of deployment telemetry.')
param parTelemetryOptOut bool = false

var varMgIds = {
  intRoot: 'mg-future-iras'
  platform: '${parTopLevelManagementGroupPrefix}-platform'
  platformManagement: '${parTopLevelManagementGroupPrefix}-platform-management'
  platformConnectivity: '${parTopLevelManagementGroupPrefix}-platform-connectivity'
  landingZones: '${parTopLevelManagementGroupPrefix}-workloads'
  landingZonesProd: '${parTopLevelManagementGroupPrefix}-workloads-prod'
  landingZonesNonProd: '${parTopLevelManagementGroupPrefix}-workloads-nonprod'
  DevBox: '${parTopLevelManagementGroupPrefix}-devbox'
}


var varMgNames = {
  intRoot: 'mg-future-iras'
  platform: 'Platform'
  platformManagement: 'Management'
  platformConnectivity: 'Connectivity'
  landingZones: 'Workloads'
  landingZonesProd: 'NonProd'
  landingZonesNonProd: 'Prod'
  DevBox: 'Dev Box'
}

var varDeploymentNames = {
  modPlatformMgSubPlacement: take('modPlatformMgSubPlacement-${uniqueString(varMgIds.platform, string(length(parPlatformMgSubs)), deployment().name)}', 64)
  modPlatformManagementMgSubPlacement: take('modPlatformManagementMgSubPlacement-${uniqueString(varMgIds.platformManagement, string(length(parPlatformManagementMgSubs)), deployment().name)}', 64)
  modPlatformConnectivityMgSubPlacement: take('modPlatformConnectivityMgSubPlacement-${uniqueString(varMgIds.platformConnectivity, string(length(parPlatformConnectivityMgSubs)), deployment().name)}', 64)
  modLandingZonesProdMgSubPlacement: take('modLandingZonesProdMgSubPlacement-${uniqueString(varMgIds.landingZonesProd, string(length(parLandingZonesProdMgSubs)), deployment().name)}', 64)
  modLandingZonesNonProdMgSubPlacement: take('modLandingZonesNonProdMgSubPlacement-${uniqueString(varMgIds.landingZonesNonProd, string(length(parLandingZonesNonProdMgSubs)), deployment().name)}', 64)
  modDevBoxMgSubPlacement: take('modDevBoxMgSubPlacement-${uniqueString(varMgIds.DevBox, string(length(parDevBoxMgSubs)), deployment().name)}', 64)
}

// Customer Usage Attribution Id
var varCuaid = 'bb800623-86ff-4ab4-8901-93c2b70967ae'

// Platform Management Groups
module modPlatformMgSubPlacement '../../custom-modules/subscriptionPlacement/subscriptionPlacement.bicep' = if (!empty(parPlatformMgSubs)) {
  name: varDeploymentNames.modPlatformMgSubPlacement
  scope: managementGroup(varMgIds.platform)
  params: {
    parTargetManagementGroupId: varMgIds.platform
    parSubscriptionIds: parPlatformMgSubs
    parTelemetryOptOut: parTelemetryOptOut
    //parTargetManagementGroupName: varMgNames.platform
  }
}

module modPlatformManagementMgSubPlacement '../../custom-modules/subscriptionPlacement/subscriptionPlacement.bicep' = if (!empty(parPlatformManagementMgSubs)) {
  name: varDeploymentNames.modPlatformManagementMgSubPlacement
  scope: managementGroup(varMgIds.platformManagement)
  params: {
    parTargetManagementGroupId: varMgIds.platformManagement
    parSubscriptionIds: parPlatformManagementMgSubs
    parTelemetryOptOut: parTelemetryOptOut
    //parTargetManagementGroupName: varMgNames.platformManagement
  }
}

module modplatformConnectivityMgSubPlacement '../../custom-modules/subscriptionPlacement/subscriptionPlacement.bicep' = if (!empty(parPlatformConnectivityMgSubs)) {
  name: varDeploymentNames.modPlatformConnectivityMgSubPlacement
  scope: managementGroup(varMgIds.platformConnectivity)
  params: {
    parTargetManagementGroupId: varMgIds.platformConnectivity
    parSubscriptionIds: parPlatformConnectivityMgSubs
    parTelemetryOptOut: parTelemetryOptOut
    //parTargetManagementGroupName: varMgNames.platformConnectivity
  }
}

module modLandingZonesProdMgSubPlacement '../../custom-modules/subscriptionPlacement/subscriptionPlacement.bicep' = if (!empty(parLandingZonesProdMgSubs)) {
  name: varDeploymentNames.modLandingZonesProdMgSubPlacement
  scope: managementGroup(varMgIds.landingZonesProd)
  params: {
    parTargetManagementGroupId: varMgIds.landingZonesProd
    parSubscriptionIds: parLandingZonesProdMgSubs
    parTelemetryOptOut: parTelemetryOptOut
    //parTargetManagementGroupName: varMgNames.landingZones
  }
}

module modLandingZonesNonProdMgSubPlacement '../../custom-modules/subscriptionPlacement/subscriptionPlacement.bicep' = if (!empty(parLandingZonesNonProdMgSubs)) {
  name: varDeploymentNames.modLandingZonesNonProdMgSubPlacement
  scope: managementGroup(varMgIds.landingZonesNonProd)
  params: {
    parTargetManagementGroupId: varMgIds.landingZonesNonProd
    parSubscriptionIds: parLandingZonesNonProdMgSubs
    parTelemetryOptOut: parTelemetryOptOut
    //parTargetManagementGroupName: varMgNames.landingZonesNonProd
  }
}

// // DevBox
// module modDevBoxMgSubPlacement '../../custom-modules/subscriptionPlacement/subscriptionPlacement.bicep' = if (!empty(parDevBoxMgSubs)) {
//   name: varDeploymentNames.modDevBoxMgSubPlacement
//   scope: managementGroup(varMgIds.DevBox)
//   params: {
//     parTargetManagementGroupId: varMgIds.DevBox
//     parSubscriptionIds: parDevBoxMgSubs
//     parTelemetryOptOut: parTelemetryOptOut
//   }
// }

// Optional Deployment for Customer Usage Attribution
module modCustomerUsageAttribution '../../custom-modules/CRML/customerUsageAttribution/cuaIdManagementGroup.bicep' = if (!parTelemetryOptOut) {
  #disable-next-line no-loc-expr-outside-params //Only to ensure telemetry data is stored in same location as deployment. See https://github.com/Azure/ALZ-Bicep/wiki/FAQ#why-are-some-linter-rules-disabled-via-the-disable-next-line-bicep-function for more information
  name: 'pid-${varCuaid}-${uniqueString(deployment().location)}'
  params: {}
}
