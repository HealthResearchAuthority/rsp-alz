targetScope = 'managementGroup'

metadata name = 'ALZ Bicep orchestration - Management Group Diagnostic Settings - ALL'
metadata description = 'Orchestration module that helps enable Diagnostic Settings on the Management Group hierarchy as was defined during the deployment of the Management Group module'

@sys.description('Prefix used for the management group hierarchy.')
@minLength(2)
@maxLength(10)
param parTopLevelManagementGroupPrefix string = 'mg-rsp'

@sys.description('Log Analytics Workspace Resource ID.')
param parLogAnalyticsWorkspaceResourceId string

@sys.description('Diagnostic Settings Name.')
param parDiagnosticSettingsName string = 'toLa'

@sys.description('Set Parameter to true to Opt-out of deployment telemetry.')
param parTelemetryOptOut bool = false

var varMgIds = {
  intRoot: 'mg-future-iras'
  platform: '${parTopLevelManagementGroupPrefix}-platform'
  landingZones: '${parTopLevelManagementGroupPrefix}-landingzones'
}

var varLandingZoneMgChildrenAlzDefault = {
  workloadsProd: '${parTopLevelManagementGroupPrefix}-workloads-prod'
  workloadsNonProd: '${parTopLevelManagementGroupPrefix}-workloads-nonprod'
}

var varPlatformMgChildrenAlzDefault = {
  platformManagement: '${parTopLevelManagementGroupPrefix}-platform-management'
  platformConnectivity: '${parTopLevelManagementGroupPrefix}-platform-connectivity'
}

// Customer Usage Attribution Id
var varCuaid = 'f49c8dfb-c0ce-4ee0-b316-5e4844474dd0'

module modMgDiagSet '../../custom-modules/mgDiagSettings/mgDiagSettings.bicep' = [for mgId in items(varMgIds): {
  scope: managementGroup(mgId.value)
  name: 'mg-diag-set-${mgId.value}'
  params: {
    parLogAnalyticsWorkspaceResourceId: parLogAnalyticsWorkspaceResourceId
    parDiagnosticSettingsName: parDiagnosticSettingsName
    parTelemetryOptOut: parTelemetryOptOut
  }
}]

// Default Children Landing Zone Management Groups
module modMgLandingZonesDiagSet '../../custom-modules/mgDiagSettings/mgDiagSettings.bicep' = [for childMg in items(varLandingZoneMgChildrenAlzDefault): {
  scope: managementGroup(childMg.value)
  name: 'mg-diag-set-${childMg.value}'
  params: {
    parLogAnalyticsWorkspaceResourceId: parLogAnalyticsWorkspaceResourceId
    parDiagnosticSettingsName: parDiagnosticSettingsName
    parTelemetryOptOut: parTelemetryOptOut
  }
}]

// Default Children Platform Management Groups
module modMgPlatformDiagSet '../../custom-modules/mgDiagSettings/mgDiagSettings.bicep' = [for childMg in items(varPlatformMgChildrenAlzDefault): {
  scope: managementGroup(childMg.value)
  name: 'mg-diag-set-${childMg.value}'
  params: {
    parLogAnalyticsWorkspaceResourceId: parLogAnalyticsWorkspaceResourceId
    parDiagnosticSettingsName: parDiagnosticSettingsName
    parTelemetryOptOut: parTelemetryOptOut
  }
}]

// Optional Deployment for Customer Usage Attribution
module modCustomerUsageAttribution '../../custom-modules/CRML/customerUsageAttribution/cuaIdManagementGroup.bicep' = if (!parTelemetryOptOut) {
  #disable-next-line no-loc-expr-outside-params //Only to ensure telemetry data is stored in same location as deployment. See https://github.com/Azure/ALZ-Bicep/wiki/FAQ#why-are-some-linter-rules-disabled-via-the-disable-next-line-bicep-function for more information //Only to ensure telemetry data is stored in same location as deployment. See https://github.com/Azure/ALZ-Bicep/wiki/FAQ#why-are-some-linter-rules-disabled-via-the-disable-next-line-bicep-function for more information
  name: 'pid-${varCuaid}-${uniqueString(deployment().location)}'
  scope: managementGroup()
  params: {}
}
