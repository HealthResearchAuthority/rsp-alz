targetScope = 'managementGroup'

metadata name = 'ALZ Bicep orchestration - Management Group Diagnostic Settings - ALL'
metadata description = 'Orchestration module that helps enable Diagnostic Settings on the Management Group hierarchy as was defined during the deployment of the Management Group module'

@sys.description('Prefix used for the management group hierarchy.')
@maxLength(10)
param parTopLevelManagementGroupPrefix string = ''

@sys.description('Log Analytics Workspace Resource ID.')
param parLogAnalyticsWorkspaceResourceId string

@sys.description('Diagnostic Settings Name.')
param parDiagnosticSettingsName string = 'toLa'

var varMgIds = {
  intRoot: 'mg-future-iras'
  platform: '${parTopLevelManagementGroupPrefix}-platform'
}

var varLandingZoneMgChildrenAlzDefault = {
  workloadsProd: '${parTopLevelManagementGroupPrefix}-workloads-prod'
  workloadsNonProd: '${parTopLevelManagementGroupPrefix}-workloads-nonprod'
}

var varPlatformMgChildrenAlzDefault = {
  platformManagement: '${parTopLevelManagementGroupPrefix}-platform-management'
  platformConnectivity: '${parTopLevelManagementGroupPrefix}-platform-connectivity'
}


module modMgDiagSet 'mgDiagSettings.bicep' = [for mgId in items(varMgIds): {
  scope: managementGroup(mgId.value)
  name: 'mg-diag-set-${mgId.value}'
  params: {
    parLogAnalyticsWorkspaceResourceId: parLogAnalyticsWorkspaceResourceId
    parDiagnosticSettingsName: parDiagnosticSettingsName
  }
}]

// Default Children Landing Zone Management Groups
module modMgLandingZonesDiagSet 'mgDiagSettings.bicep' = [for childMg in items(varLandingZoneMgChildrenAlzDefault): {
  scope: managementGroup(childMg.value)
  name: 'mg-diag-set-${childMg.value}'
  params: {
    parLogAnalyticsWorkspaceResourceId: parLogAnalyticsWorkspaceResourceId
    parDiagnosticSettingsName: parDiagnosticSettingsName
  }
}]

// Default Children Platform Management Groups
module modMgPlatformDiagSet 'mgDiagSettings.bicep' = [for childMg in items(varPlatformMgChildrenAlzDefault): {
  scope: managementGroup(childMg.value)
  name: 'mg-diag-set-${childMg.value}'
  params: {
    parLogAnalyticsWorkspaceResourceId: parLogAnalyticsWorkspaceResourceId
    parDiagnosticSettingsName: parDiagnosticSettingsName
  }
}]
