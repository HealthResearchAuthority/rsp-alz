targetScope = 'managementGroup'

metadata name = 'ALZ Bicep orchestration - Subscription Placement - ALL'
metadata description = 'Orchestration module that helps to define where all Subscriptions should be placed in the ALZ Management Group Hierarchy'

@sys.description('An array of Subscription IDs to place in the Platform Management Group. Default: Empty Array')
param parPlatformMgSubs array = []

@sys.description('An array of Subscription IDs to place in the (Platform) Management Management Group. Default: Empty Array')
param parPlatformManagementMgSubs array = []

@sys.description('An array of Subscription IDs to place in the (Platform) Connectivity Management Group. Default: Empty Array')
param parPlatformConnectivityMgSubs array = []

@sys.description('An array of Subscription IDs to place in the PROD Management Group. Default: Empty Array')
param parLandingZonesProdMgSubs array = []

@sys.description('An array of Subscription IDs to place in the NONPROD Management Group. Default: Empty Array')
param parLandingZonesNonProdMgSubs array = []

@sys.description('An array of Subscription IDs to place in the NONPROD Management Group. Default: Empty Array')
param parLandingZonesNonProdMgdevelopmentSubs array = []

@sys.description('An array of Subscription IDs to place in the Confidential Corp (Landing Zones) Management Group. Default: Empty Array')
param parDevBoxMgSubs array = []

@sys.description('Set Parameter to true to Opt-out of deployment telemetry.')
param parTelemetryOptOut bool = false

param parMgIds object = {}

var varDeploymentNames = {
  modPlatformMgSubPlacement: take('modPlatformMgSubPlacement-${uniqueString(parMgIds.platform, string(length(parPlatformMgSubs)), deployment().name)}', 64)
  modPlatformManagementMgSubPlacement: take('modPlatformManagementMgSubPlacement-${uniqueString(parMgIds.platformManagement, string(length(parPlatformManagementMgSubs)), deployment().name)}', 64)
  modPlatformConnectivityMgSubPlacement: take('modPlatformConnectivityMgSubPlacement-${uniqueString(parMgIds.platformConnectivity, string(length(parPlatformConnectivityMgSubs)), deployment().name)}', 64)
  modLandingZonesProdMgSubPlacement: take('modLandingZonesProdMgSubPlacement-${uniqueString(parMgIds.landingZonesProd, string(length(parLandingZonesProdMgSubs)), deployment().name)}', 64)
  modLandingZonesNonProdMgSubPlacement: take('modLandingZonesNonProdMgSubPlacement-${uniqueString(parMgIds.landingZonesNonProd, string(length(parLandingZonesNonProdMgSubs)), deployment().name)}', 64)
  modLandingZonesNonProdMgDevelopmentSubPlacement: take('modLandingZonesNonProdMgSubPlacement-${uniqueString(parMgIds.landingZonesNonProdDevelopment, string(length(parLandingZonesNonProdMgdevelopmentSubs)), deployment().name)}', 64)
  modDevBoxMgSubPlacement: take('modDevBoxMgSubPlacement-${uniqueString(parMgIds.DevBox, string(length(parDevBoxMgSubs)), deployment().name)}', 64)
}

// Customer Usage Attribution Id
var varCuaid = 'bb800623-86ff-4ab4-8901-93c2b70967ae'

// Platform Management Groups
module modPlatformMgSubPlacement 'subscriptionPlacement.bicep' = if (!empty(parPlatformMgSubs)) {
  name: varDeploymentNames.modPlatformMgSubPlacement
  scope: managementGroup(parMgIds.platform)
  params: {
    parTargetManagementGroupId: parMgIds.platform
    parSubscriptionIds: parPlatformMgSubs
    parTelemetryOptOut: parTelemetryOptOut
    //parTargetManagementGroupName: varMgNames.platform
  }
}

module modPlatformManagementMgSubPlacement 'subscriptionPlacement.bicep' = if (!empty(parPlatformManagementMgSubs)) {
  name: varDeploymentNames.modPlatformManagementMgSubPlacement
  scope: managementGroup(parMgIds.platformManagement)
  params: {
    parTargetManagementGroupId: parMgIds.platformManagement
    parSubscriptionIds: parPlatformManagementMgSubs
    parTelemetryOptOut: parTelemetryOptOut
    //parTargetManagementGroupName: varMgNames.platformManagement
  }
}

module modplatformConnectivityMgSubPlacement 'subscriptionPlacement.bicep' = if (!empty(parPlatformConnectivityMgSubs)) {
  name: varDeploymentNames.modPlatformConnectivityMgSubPlacement
  scope: managementGroup(parMgIds.platformConnectivity)
  params: {
    parTargetManagementGroupId: parMgIds.platformConnectivity
    parSubscriptionIds: parPlatformConnectivityMgSubs
    parTelemetryOptOut: parTelemetryOptOut
    //parTargetManagementGroupName: varMgNames.platformConnectivity
  }
}

module modLandingZonesProdMgSubPlacement 'subscriptionPlacement.bicep' = if (!empty(parLandingZonesProdMgSubs)) {
  name: varDeploymentNames.modLandingZonesProdMgSubPlacement
  scope: managementGroup(parMgIds.landingZonesProd)
  params: {
    parTargetManagementGroupId: parMgIds.landingZonesProd
    parSubscriptionIds: parLandingZonesProdMgSubs
    parTelemetryOptOut: parTelemetryOptOut
    //parTargetManagementGroupName: varMgNames.landingZones
  }
}

module modLandingZonesNonProdMgSubPlacement 'subscriptionPlacement.bicep' = if (!empty(parLandingZonesNonProdMgSubs)) {
  name: varDeploymentNames.modLandingZonesNonProdMgSubPlacement
  scope: managementGroup(parMgIds.landingZonesNonProd)
  params: {
    parTargetManagementGroupId: parMgIds.landingZonesNonProd
    parSubscriptionIds: parLandingZonesNonProdMgSubs
    parTelemetryOptOut: parTelemetryOptOut
    //parTargetManagementGroupName: varMgNames.landingZonesNonProd
  }
}

module modLandingZonesNonProdMgDevelopmentSubPlacement 'subscriptionPlacement.bicep' = if (!empty(parLandingZonesNonProdMgdevelopmentSubs)) {
  name: varDeploymentNames.modLandingZonesNonProdMgDevelopmentSubPlacement
  scope: managementGroup(parMgIds.landingZonesNonProdDevelopment)
  params: {
    parTargetManagementGroupId: parMgIds.landingZonesNonProdDevelopment
    parSubscriptionIds: parLandingZonesNonProdMgdevelopmentSubs
    parTelemetryOptOut: parTelemetryOptOut
    //parTargetManagementGroupName: varMgNames.landingZonesNonProd
  }
}

// DevBox
module modDevBoxMgSubPlacement 'subscriptionPlacement.bicep' = if (!empty(parDevBoxMgSubs)) {
  name: varDeploymentNames.modDevBoxMgSubPlacement
  scope: managementGroup(parMgIds.DevBox)
  params: {
    parTargetManagementGroupId: parMgIds.DevBox
    parSubscriptionIds: parDevBoxMgSubs
    parTelemetryOptOut: parTelemetryOptOut
  }
}

// Optional Deployment for Customer Usage Attribution
module modCustomerUsageAttribution '../../config/custom-modules/CRML/customerUsageAttribution/cuaIdManagementGroup.bicep' = if (!parTelemetryOptOut) {
  #disable-next-line no-loc-expr-outside-params //Only to ensure telemetry data is stored in same location as deployment. See https://github.com/Azure/ALZ-Bicep/wiki/FAQ#why-are-some-linter-rules-disabled-via-the-disable-next-line-bicep-function for more information
  name: 'pid-${varCuaid}-${uniqueString(deployment().location)}'
  params: {}
}
