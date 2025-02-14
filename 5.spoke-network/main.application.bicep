targetScope = 'subscription'
// ------------------
// PARAMETERS
// ------------------

@description('The location where the resources will be created.')
param location string = deployment().location

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

@description('Central Log Analytics Workspace ID')
param logAnalyticsWorkspaceId string = '/subscriptions/8747cd7f-1a06-4fe4-9dbb-24f612b9dd5a/resourceGroups/rg-hra-operationsmanagement/providers/Microsoft.OperationalInsights/workspaces/hra-rsp-log-analytics'

// @description('The FQDN of the Application Gateway. Must match the TLS Certificate.')
// param applicationGatewayFqdn string

// @description('Enable or disable Application Gateway Certificate (PFX).')
// param enableApplicationGatewayCertificate bool 

// @description('The name of the certificate key to use for Application Gateway certificate.')
// param applicationGatewayCertificateKeyName string

@description('Admin login for SQL Server')
param parAdminLogin string = ''

@description('SQL Admin Password')
param parSqlAdminPhrase string

@description('Iras Service Container image tag.')
param parIrasContainerImageTag string 

@description('User Service Container image tag.')
param parUserServiceContainerImageTag string 

@description('QuestionSet Service Container image tag.')
param parQuestionSetContainerImageTag string 

@description('RTS Service Container image tag.')
param parRtsContainerImageTag string 

@description('Client Key for IDG Authentication')
param parClientID string

@secure()
@description('Client secret for IDG Authentication')
param parClientSecret string

@description('Hub Virtual Network ID')
param hubVNetId string = '/subscriptions/15642d2a-27a2-4ee8-9eba-788bf7223d95/resourceGroups/rg-hra-connectivity/providers/Microsoft.Network/virtualHubs/vhub-rsp-uksouth'

@description('Spoke Networks Configuration')
param parSpokeNetworks array

// ------------------
// VARIABLES
// ------------------

var sqlServerNamePrefix = 'rspsqlserver'
var varVirtualHubResourceGroup = (!empty(hubVNetId) && contains(hubVNetId, '/providers/Microsoft.Network/virtualHubs/') ? split(hubVNetId, '/')[4] : '')
var varVirtualHubSubscriptionId = (!empty(hubVNetId) && contains(hubVNetId, '/providers/Microsoft.Network/virtualHubs/') ? split(hubVNetId, '/')[2] : '')
//var varHubVirtualNetworkName = (!empty(hubVNetId) && contains(hubVNetId, '/providers/Microsoft.Network/virtualHubs/') ? split(hubVNetId, '/')[8] : '')


// ------------------
// RESOURCES
// ------------------

module sharedServicesRG '../shared/bicep/resourceGroup.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  name: take('sharedServicesRG-${deployment().name}', 64)
  scope: subscription(parSpokeNetworks[i].subscriptionId)
  params:{
    parLocation: location
    parResourceGroupName: parSpokeNetworks[i].rgSharedServices
  }
}]

module storageRG '../shared/bicep/resourceGroup.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  name: take('storageRG-${deployment().name}', 64)
  scope: subscription(parSpokeNetworks[i].subscriptionId)
  params:{
    parLocation: location
    parResourceGroupName: parSpokeNetworks[i].rgStorage
  }
}]

module applicationsRG '../shared/bicep/resourceGroup.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  name: take('applicationsRG-${deployment().name}', 64)
  scope: subscription(parSpokeNetworks[i].subscriptionId)
  params:{
    parLocation: location
    parResourceGroupName: parSpokeNetworks[i].rgapplications
  }
}]

resource networkRgResource 'Microsoft.Resources/resourceGroups@2023-07-01' existing = {
  name: parSpokeNetworks[0].rgNetworking
  scope: subscription(parSpokeNetworks[0].subscriptionId) 
}


@description('User-configured naming rules')
module networkingnaming '../shared/bicep/naming/naming.module.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  name: take('03-sharedNamingDeployment-${deployment().name}', 64)
  scope: resourceGroup(parSpokeNetworks[i].subscriptionId,parSpokeNetworks[i].rgNetworking)
  params: {
    uniqueId: uniqueString(networkRgResource.id)
    environment: parSpokeNetworks[i].parEnvironment
    workloadName: 'networking'
    location: location
  }
}]

resource existingVnet 'Microsoft.Network/virtualNetworks@2024-03-01' existing = [for i in range(0, length(parSpokeNetworks)): {
  name: parSpokeNetworks[i].vnet
  scope: resourceGroup(parSpokeNetworks[i].rgNetworking)
}]

resource infraSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-03-01' existing = [for i in range(0, length(parSpokeNetworks)): {
  name: 'snet-infra'
  parent: existingVnet[i]
}]

resource pepSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-03-01' existing = [for i in range(0, length(parSpokeNetworks)): {
  name: 'snet-pep'
  parent: existingVnet[i]
}]

resource webAppSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-03-01' existing = [for i in range(0, length(parSpokeNetworks)): {
  name: 'snet-webapp'
  parent: existingVnet[i]
}]

// resource agwSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-03-01' existing = [for i in range(0, length(parSpokeNetworks)): {
//   name: 'snet-agw'
//   parent: existingVnet[i]
// }]

module sharedServicesNaming '../shared/bicep/naming/naming.module.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  name: take('sharedNamingDeployment-${deployment().name}', 64)
  scope: resourceGroup(parSpokeNetworks[i].subscriptionId, parSpokeNetworks[i].rgSharedServices)
  params: {
    uniqueId: uniqueString(sharedServicesRG[i].outputs.outResourceGroupId)
    environment: parSpokeNetworks[i].parEnvironment
    workloadName: 'shared'
    location: location
  }
}]

module storageServicesNaming '../shared/bicep/naming/naming.module.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  name: take('storageServicesNaming-${deployment().name}', 64)
  scope: resourceGroup(parSpokeNetworks[i].subscriptionId, parSpokeNetworks[i].rgStorage)
  params: {
    uniqueId: uniqueString(storageRG[i].outputs.outResourceGroupId)
  environment: parSpokeNetworks[i].parEnvironment
  workloadName: 'storage'
  location: location
  }
}]

module applicationServicesNaming '../shared/bicep/naming/naming.module.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  name: take('applicationServicesNaming-${deployment().name}', 64)
  scope: resourceGroup(parSpokeNetworks[i].subscriptionId, parSpokeNetworks[i].rgapplications)
  params: {
    uniqueId: uniqueString(applicationsRG[i].outputs.outResourceGroupId)
    environment: parSpokeNetworks[i].parEnvironment
    workloadName: 'applications'
    location: location
  }
}]

module supportingServices 'modules/03-supporting-services/deploy.supporting-services.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  name: take('supportingServices-${deployment().name}-deployment-${i}', 64)
  scope: resourceGroup(parSpokeNetworks[i].subscriptionId, parSpokeNetworks[i].rgSharedServices)
  params: {
    location: location
    tags: tags
    spokePrivateEndpointSubnetName: pepSubnet[i].name // spoke[i].outputs.spokePrivateEndpointsSubnetName
    spokeVNetId: existingVnet[i].id // spoke[i].outputs.spokeVNetId
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    deployZoneRedundantResources: parSpokeNetworks[i].zoneRedundancy
    containerRegistryTier: parSpokeNetworks[i].containerRegistryTier
    privateDNSEnabled: parSpokeNetworks[i].configurePrivateDNS
    resourcesNames: sharedServicesNaming[i].outputs.resourcesNames
    sqlServerName: '${sqlServerNamePrefix}${parSpokeNetworks[i].parEnvironment}'
    networkingResourcesNames: networkingnaming[i].outputs.resourcesNames
    networkingResourceGroup: parSpokeNetworks[i].rgNetworking
    jwksURI: 'irasportal-${parSpokeNetworks[i].parEnvironment}.azurewebsites.net'
    IDGENV: parSpokeNetworks[i].IDGENV
    clientID: parClientID
    clientSecret: parClientSecret
  }
}]

module containerAppsEnvironment 'modules/04-container-apps-environment/deploy.aca-environment.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  name: take('containerAppsEnvironment-${deployment().name}-deployment', 64)
  scope: resourceGroup(parSpokeNetworks[i].subscriptionId, parSpokeNetworks[i].rgapplications)
  params: {
    location: location
    tags: tags
    spokeVNetName: existingVnet[i].name // spoke[i].outputs.spokeVNetName
    spokeInfraSubnetName: infraSubnet[i].name // spoke[i].outputs.spokeInfraSubnetName
    enableApplicationInsights: true
    enableTelemetry: false
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    hubResourceGroupName: varVirtualHubResourceGroup
    hubSubscriptionId: varVirtualHubSubscriptionId
    deployZoneRedundantResources: parSpokeNetworks[i].zoneRedundancy
    privateDNSEnabled: parSpokeNetworks[i].configurePrivateDNS
    resourcesNames: applicationServicesNaming[i].outputs.resourcesNames
    networkRG: parSpokeNetworks[i].rgNetworking
  }
}]

module databaseserver 'modules/05-database/deploy.database.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  name: take('database-${deployment().name}-deployment', 64)
  scope: resourceGroup(parSpokeNetworks[i].subscriptionId, parSpokeNetworks[i].rgStorage)
  params: {
    location: location
    sqlServerName: '${sqlServerNamePrefix}${parSpokeNetworks[i].parEnvironment}'
    adminLogin: parAdminLogin
    adminPassword: parSqlAdminPhrase
    databases : ['applicationservice','identityservice','questionsetservice','rtsservice']
    environment: parSpokeNetworks[i].parEnvironment
    spokePrivateEndpointSubnetName: pepSubnet[i].name // spoke[i].outputs.spokePrivateEndpointsSubnetName
    spokeVNetId: existingVnet[i].id // spoke[i].outputs.spokeVNetId
    sqlServerUAIName: storageServicesNaming[i].outputs.resourcesNames.sqlServerUserAssignedIdentity
    networkingResourcesNames: networkingnaming[i].outputs.resourcesNames
    networkingResourceGroup: parSpokeNetworks[i].rgNetworking
  }
}]

module irasserviceapp 'modules/06-container-app/deploy.container-app.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  name: take('iraserviceapp-${deployment().name}-deployment', 64)
  scope: resourceGroup(parSpokeNetworks[i].subscriptionId, parSpokeNetworks[i].rgapplications)
  params: {
    location: location
    tags: tags
    containerRegistryUserAssignedIdentityId: supportingServices[i].outputs.containerRegistryUserAssignedIdentityId
    sqlServerUserAssignedIdentityName: databaseserver[i].outputs.outputsqlServerUAIName
    containerAppsEnvironmentId: containerAppsEnvironment[i].outputs.containerAppsEnvironmentId
    appConfigurationUserAssignedIdentityId: supportingServices[i].outputs.appConfigurationUserAssignedIdentityId
    storageRG: parSpokeNetworks[i].rgStorage
    appConfigURL: supportingServices[i].outputs.appConfigURL
    appConfigIdentityClientID: supportingServices[i].outputs.appConfigIdentityClientID
    containerRegistryLoginServer: supportingServices[i].outputs.containerRegistryLoginServer
    containerAppName: 'irasservice'
    containerImageTag: '${supportingServices[i].outputs.containerRegistryLoginServer}/${parIrasContainerImageTag}'
    containerImageName: 'irasservice'
    configStoreName: sharedServicesNaming[i].outputs.resourcesNames.azureappconfigurationstore
    webAppURLConfigKey: 'AppSettings:ApplicationsServiceUri'
    sharedservicesRG: parSpokeNetworks[i].rgSharedServices
  }
  dependsOn: [
    databaseserver
  ]
}]

module usermanagementapp 'modules/06-container-app/deploy.container-app.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  name: take('usermanagementapp-${deployment().name}-deployment', 64)
  scope: resourceGroup(parSpokeNetworks[i].subscriptionId, parSpokeNetworks[i].rgapplications)
  params: {
    location: location
    tags: tags
    containerRegistryUserAssignedIdentityId: supportingServices[i].outputs.containerRegistryUserAssignedIdentityId
    sqlServerUserAssignedIdentityName: databaseserver[i].outputs.outputsqlServerUAIName
    containerAppsEnvironmentId: containerAppsEnvironment[i].outputs.containerAppsEnvironmentId
    appConfigurationUserAssignedIdentityId: supportingServices[i].outputs.appConfigurationUserAssignedIdentityId
    storageRG: parSpokeNetworks[i].rgStorage
    appConfigURL: supportingServices[i].outputs.appConfigURL
    appConfigIdentityClientID: supportingServices[i].outputs.appConfigIdentityClientID
    containerRegistryLoginServer: supportingServices[i].outputs.containerRegistryLoginServer
    containerAppName: 'usermanagementservice'
    containerImageTag: '${supportingServices[i].outputs.containerRegistryLoginServer}/${parUserServiceContainerImageTag}'
    containerImageName: 'usermanagementservice'
    configStoreName: sharedServicesNaming[i].outputs.resourcesNames.azureappconfigurationstore
    webAppURLConfigKey: 'AppSettings:UsersServiceUri'
    sharedservicesRG: parSpokeNetworks[i].rgSharedServices
  }
  dependsOn: [
    databaseserver
    irasserviceapp
  ]
}]

module questionsetapp 'modules/06-container-app/deploy.container-app.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  name: take('questionsetapp-${deployment().name}-deployment', 64)
  scope: resourceGroup(parSpokeNetworks[i].subscriptionId, parSpokeNetworks[i].rgapplications)
  params: {
    location: location
    tags: tags
    containerRegistryUserAssignedIdentityId: supportingServices[i].outputs.containerRegistryUserAssignedIdentityId
    sqlServerUserAssignedIdentityName: databaseserver[i].outputs.outputsqlServerUAIName
    containerAppsEnvironmentId: containerAppsEnvironment[i].outputs.containerAppsEnvironmentId
    appConfigurationUserAssignedIdentityId: supportingServices[i].outputs.appConfigurationUserAssignedIdentityId
    storageRG: parSpokeNetworks[i].rgStorage
    appConfigURL: supportingServices[i].outputs.appConfigURL
    appConfigIdentityClientID: supportingServices[i].outputs.appConfigIdentityClientID
    containerRegistryLoginServer: supportingServices[i].outputs.containerRegistryLoginServer
    containerAppName: 'questionsetservice'
    containerImageTag: '${supportingServices[i].outputs.containerRegistryLoginServer}/${parQuestionSetContainerImageTag}'
    containerImageName: 'questionsetservice'
    configStoreName: sharedServicesNaming[i].outputs.resourcesNames.azureappconfigurationstore
    webAppURLConfigKey: 'AppSettings:QuestionSetServiceUri'
    sharedservicesRG: parSpokeNetworks[i].rgSharedServices
  }
  dependsOn: [
    databaseserver
    irasserviceapp
    usermanagementapp
  ]
}]

module rtsserviceapp 'modules/06-container-app/deploy.container-app.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  name: take('rtsserviceapp-${deployment().name}-deployment', 64)
  scope: resourceGroup(parSpokeNetworks[i].subscriptionId, parSpokeNetworks[i].rgapplications)
  params: {
    location: location
    tags: tags
    containerRegistryUserAssignedIdentityId: supportingServices[i].outputs.containerRegistryUserAssignedIdentityId
    sqlServerUserAssignedIdentityName: databaseserver[i].outputs.outputsqlServerUAIName
    containerAppsEnvironmentId: containerAppsEnvironment[i].outputs.containerAppsEnvironmentId
    appConfigurationUserAssignedIdentityId: supportingServices[i].outputs.appConfigurationUserAssignedIdentityId
    storageRG: parSpokeNetworks[i].rgStorage
    appConfigURL: supportingServices[i].outputs.appConfigURL
    appConfigIdentityClientID: supportingServices[i].outputs.appConfigIdentityClientID
    containerRegistryLoginServer: supportingServices[i].outputs.containerRegistryLoginServer
    containerAppName: 'rtsservice'
    containerImageTag: '${supportingServices[i].outputs.containerRegistryLoginServer}/${parRtsContainerImageTag}'
    containerImageName: 'rtsservice'
    configStoreName: sharedServicesNaming[i].outputs.resourcesNames.azureappconfigurationstore
    webAppURLConfigKey: 'AppSettings:RtsServiceUri'
    sharedservicesRG: parSpokeNetworks[i].rgSharedServices
  }
  dependsOn: [
    databaseserver
    irasserviceapp
    usermanagementapp
    questionsetapp
  ]
}]

module webApp 'modules/07-app-service/deploy.app-service.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  scope: resourceGroup(parSpokeNetworks[i].subscriptionId, parSpokeNetworks[i].rgapplications)
  name: take('webApp-${deployment().name}-deployment', 64)
  params: {
    tags: {}
    sku: 'B1'
    logAnalyticsWsId: logAnalyticsWorkspaceId
    location: location
    appServicePlanName: applicationServicesNaming[i].outputs.resourcesNames.appServicePlan
    webAppName: 'irasportal-${parSpokeNetworks[i].parEnvironment}'
    webAppBaseOs: 'Linux'
    subnetIdForVnetInjection: webAppSubnet[i].id  // spoke[i].outputs.spokeWebAppSubnetId
    appConfigmanagedIdentityId: supportingServices[i].outputs.appConfigurationUserAssignedIdentityId
    deploySlot: parSpokeNetworks[i].deployWebAppSlot
    privateEndpointRG: parSpokeNetworks[i].rgNetworking
    spokeVNetId: existingVnet[i].id // spoke[i].outputs.spokeVNetId
    subnetPrivateEndpointSubnetId: pepSubnet[i].id // spoke[i].outputs.spokePepSubnetId
  }
}]

// module applicationGateway 'modules/08-application-gateway/deploy.app-gateway.bicep' = [for i in range(0, length(parSpokeNetworks)): {
//   name: take('applicationGateway-${deployment().name}-deployment', 64)
//   scope: resourceGroup(parSpokeNetworks[i].subscriptionId, parSpokeNetworks[i].rgNetworking)
//   params: {
//     location: location
//     tags: tags
//     applicationGatewayCertificateKeyName: applicationGatewayCertificateKeyName
//     applicationGatewayFqdn: applicationGatewayFqdn
//     applicationGatewayPrimaryBackendEndFqdn: webApp[i].outputs.webAppHostName
//     applicationGatewaySubnetId: agwSubnet[i].id  // spoke[i].outputs.spokeApplicationGatewaySubnetId
//     enableApplicationGatewayCertificate: enableApplicationGatewayCertificate
//     keyVaultId: supportingServices[i].outputs.keyVaultId
//     deployZoneRedundantResources: parSpokeNetworks[i].zoneRedundancy
//     ddosProtectionMode: 'Disabled'
//     applicationGatewayLogAnalyticsId: logAnalyticsWorkspaceId
//     networkingResourceNames: networkingnaming[i].outputs.resourcesNames
//   }
// }]
