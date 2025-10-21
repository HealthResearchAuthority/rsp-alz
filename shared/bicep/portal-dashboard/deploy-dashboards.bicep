// ------------------
// PARAMETERS
// ------------------

@description('Required. The resource ID of the IRAS Portal Application Insights instance.')
param irasPortalAppInsightsId string

@description('Required. The resource ID of the IRAS Services Application Insights instance (container apps).')
param irasServicesAppInsightsId string

@description('Required. Environment name for resource naming.')
param environment string

@description('Required. Location for all resources.')
param location string

@description('Optional. Tags for all resources.')
param tags object = {}

// ------------------
// VARIABLES
// ------------------

var irasPortalDashboardName = 'dashboard-irasportal-${environment}'
var irasServicesDashboardName = 'dashboard-irasservices-${environment}'

// Template hardcoded resource IDs to replace
var portalTemplateAppInsightsId = '/subscriptions/66482e26-764b-4717-ae2f-fab6b8dd1379/resourceGroups/rg-rsp-applications-spoke-systemtest-uks/providers/Microsoft.Insights/components/appi-irasportal-manualtest'
var servicesTemplateAppInsightsId = '/subscriptions/66482e26-764b-4717-ae2f-fab6b8dd1379/resourceGroups/rg-rsp-applications-spoke-systemtest-uks/providers/Microsoft.Insights/components/appi-rsp-applications-manualtest-uks'

// Load dashboard templates and convert to string for replacement
var irasPortalTemplateString = string(loadJsonContent('iras-portal-dashboard-template.json').properties)
var irasServicesTemplateString = string(loadJsonContent('iras-service-dashboard-template.json').properties)

// Replace resource IDs in templates
var irasPortalPropertiesString = replace(irasPortalTemplateString, portalTemplateAppInsightsId, irasPortalAppInsightsId)
var irasServicesPropertiesString = replace(irasServicesTemplateString, servicesTemplateAppInsightsId, irasServicesAppInsightsId)

// Parse back to JSON
var irasPortalProperties = json(irasPortalPropertiesString)
var irasServicesProperties = json(irasServicesPropertiesString)

// ------------------
// RESOURCES
// ------------------

resource irasPortalDashboard 'Microsoft.Portal/dashboards@2022-12-01-preview' = {
  name: irasPortalDashboardName
  location: location
  tags: union(tags, {
    'hidden-title': 'IRAS Portal - ${environment}'
  })
  properties: irasPortalProperties
}

resource irasServicesDashboard 'Microsoft.Portal/dashboards@2022-12-01-preview' = {
  name: irasServicesDashboardName
  location: location
  tags: union(tags, {
    'hidden-title': 'IRAS Services - ${environment}'
  })
  properties: irasServicesProperties
}

// ------------------
// OUTPUTS
// ------------------

@description('The resource ID of the IRAS Portal dashboard.')
output irasPortalDashboardId string = irasPortalDashboard.id

@description('The resource ID of the IRAS Services dashboard.')
output irasServicesDashboardId string = irasServicesDashboard.id
