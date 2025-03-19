targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------

@description('The location where the resources will be created. This needs to be the same region as the spoke.')
param location string = resourceGroup().location

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

// Spoke
@description('The name of the existing spoke virtual network.')
param spokeVNetName string

@description('The name of the existing spoke infrastructure subnet.')
param spokeInfraSubnetName string

// Telemetry
@description('Enable or disable the createion of Application Insights.')
param enableApplicationInsights bool

@description('Enable sending usage and telemetry feedback to Microsoft.')
param enableTelemetry bool = true

@description('The resource id of an existing Azure Log Analytics Workspace.')
param logAnalyticsWorkspaceId string

@description('Optional, default value is true. If true, any resources that support AZ will be deployed in all three AZ. However if the selected region is not supporting AZ, this parameter needs to be set to false.')
param deployZoneRedundantResources bool = true

// @description('The name of the hub virtual network.')
// param hubVNetName string = ''

param resourcesNames object
param networkRG string

// ------------------
// VARIABLES
// ------------------

var telemetryId = '9b4433d6-924a-4c07-b47c-7478619759c7-${location}-acasb'

// ------------------
// EXISTING RESOURCES
// ------------------

// @description('The existing hub virtual network.')
// resource vnetHub 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
//   scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
//   name: hubVNetName
// }

@description('The existing spoke virtual network.')
resource spokeVNet 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  scope: resourceGroup(networkRG)
  name: spokeVNetName
}

resource spokeInfraSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' existing = {
  name: spokeInfraSubnetName
  parent: spokeVNet
}
// ------------------
// RESOURCES
// ------------------

@description('Azure Application Insights, the workload\' log & metric sink and APM tool')
module applicationInsights '../../../shared/bicep/app-insights.bicep' = if (enableApplicationInsights) {
  name: take('applicationInsights-${uniqueString(resourceGroup().id)}', 64)
  params: {
    name: resourcesNames.applicationInsights
    location: location
    tags: tags
    workspaceResourceId: logAnalyticsWorkspaceId
  }
}

@description('The Azure Container Apps (ACA) cluster.')
module containerAppsEnvironment '../../../shared/bicep/aca-environment.bicep' = {
  name: take('containerAppsEnvironment-${uniqueString(resourceGroup().id)}', 64)
  params: {
    name: resourcesNames.containerAppsEnvironment
    location: location
    tags: tags
    diagnosticWorkspaceId: logAnalyticsWorkspaceId
    subnetId: spokeInfraSubnet.id
    vnetEndpointInternal: true
    zoneRedundant: deployZoneRedundantResources
    infrastructureResourceGroupName: ''
  }
}

@description('The Private DNS zone containing the ACA load balancer IP')
module containerAppsEnvironmentPrivateDnsZone '../../../shared/bicep/network/private-dns-zone.bicep' = {
  scope: resourceGroup(networkRG)
  name: 'containerAppsEnvironmentPrivateDnsZone-${uniqueString(resourceGroup().id)}'
  params: {
    name: containerAppsEnvironment.outputs.containerAppsEnvironmentDefaultDomain
    virtualNetworkLinks: [
      {
        vnetName: spokeVNet.name  /* Link to spoke */
        vnetId: spokeVNet.id
        registrationEnabled: false
      }
      // {
      //   vnetName: vnetHub.name  /* Link to hub */
      //   vnetId: vnetHub.id
      //   registrationEnabled: false
      // }
    ]
    tags: tags
    aRecords: [
      {
        name: '*'
        ipv4Address: containerAppsEnvironment.outputs.containerAppsEnvironmentLoadBalancerIP
      }
    ]
  }
}

@description('Microsoft telemetry deployment.')
#disable-next-line no-deployments-resources
resource telemetrydeployment 'Microsoft.Resources/deployments@2021-04-01' = if (enableTelemetry) {
  name: telemetryId
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#'
      contentVersion: '1.0.0.0'
      resources: {}
    }
  }
}

// ------------------
// OUTPUTS
// ------------------

@description('The resource ID of the Container Apps environment.')
output containerAppsEnvironmentId string = containerAppsEnvironment.outputs.containerAppsEnvironmentNameId

@description('The name of the Container Apps environment.')
output containerAppsEnvironmentName string = containerAppsEnvironment.outputs.containerAppsEnvironmentName

output applicationInsightsName string =  (enableApplicationInsights)? applicationInsights.outputs.appInsNname : ''
