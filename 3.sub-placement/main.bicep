targetScope = 'managementGroup'

// ------------------
//    Variables
// ------------------

param topLevelManagementGroupPrefix string = 'mg-rsp'
var topLevelManagementGroupId = 'mg-future-iras'
var platformManagementMgSubs = ['8747cd7f-1a06-4fe4-9dbb-24f612b9dd5a']
var platformConnectivityMgSubs = ['15642d2a-27a2-4ee8-9eba-788bf7223d95']
var landingZonesNonProdMgSubs = [
  '66482e26-764b-4717-ae2f-fab6b8dd1379' //System Test Manual
  'c9d1b222-c47a-43fc-814a-33083b8d3375' //System Test integration
  '75875981-b04d-42c7-acc5-073e2e5e2e65' //System Test Automated
]
var landingZonesNonProdMgdevelopmentSubs  = [
  'b83b4631-b51b-4961-86a1-295f539c826b' //Development
]
var devBoxMgSubs = ['9ef9a127-7a6e-452e-b18d-d2e2e89ffa92']

var varMgIds = {
  intRoot: topLevelManagementGroupId
  platform: '${topLevelManagementGroupPrefix}-platform'
  platformManagement: '${topLevelManagementGroupPrefix}-platform-management'
  platformConnectivity: '${topLevelManagementGroupPrefix}-platform-connectivity'
  landingZones: '${topLevelManagementGroupPrefix}-workloads'
  landingZonesProd: '${topLevelManagementGroupPrefix}-workloads-prod'
  landingZonesNonProd: '${topLevelManagementGroupPrefix}-workloads-nonprod'
  landingZonesNonProdDevelopment: '${topLevelManagementGroupPrefix}-workloads-nonprod-development'
  DevBox: '${topLevelManagementGroupPrefix}-devbox'
}


@description('Deploy Management Groups')
module managementGroup 'modules/subPlacementsAll.bicep' = {
  name: take('01-managementGroup-${deployment().name}', 64)
  params: {
    parPlatformManagementMgSubs: platformManagementMgSubs
    parPlatformConnectivityMgSubs: platformConnectivityMgSubs
    parLandingZonesNonProdMgSubs: landingZonesNonProdMgSubs
    parLandingZonesNonProdMgdevelopmentSubs: landingZonesNonProdMgdevelopmentSubs
    parDevBoxMgSubs: devBoxMgSubs
    parMgIds: varMgIds
  }
}


