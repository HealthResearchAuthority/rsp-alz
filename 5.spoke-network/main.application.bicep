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

param parAdminLogin string = ''
param parSqlAdminPhrase string

param hubVNetId string = '/subscriptions/15642d2a-27a2-4ee8-9eba-788bf7223d95/resourceGroups/rg-hra-connectivity/providers/Microsoft.Network/virtualHubs/vhub-rsp-uksouth'

type spokesType = ({
  @description('SubscriptionId for spokeNetworking')
  subscriptionId: string
  @description('managementGroup for subscription placement')
  workloadName: string
  @description('Name of environment')
  parEnvironment: string
  @description('Name of networking resource group')
  rgNetworking: string
  @description('Name of Virtual network')
  vnet: string
  @description('Name of Shared Services resource group')
  rgSharedServices: string
  @description('Name of storage resource group')
  rgStorage: string
  @description('Name of applications resource group')
  rgapplications: string
  @description('Boolean to indicate deploy Zone redundancy')
  zoneRedundancy: bool
  @description('Name of environment. Allowed Valued: "Disabled","Enabled", "VirtualNetworkInherited", "null"')
  ddosProtectionEnabled: string
  @description('Name of environment. Allowed Valued: "Basic","Standard", "Premium"')
  containerRegistryTier: string
  @description('Boolean variable to indicate deploy this spoke or not')
  deploy: bool
  @description('Boolean to indicate deploy private DNS or not')
  configurePrivateDNS: bool
  @description('Boolean to indicate to deploy web app slot')
  deployWebAppSlot: bool
  @description('Boolean to indicate Spoke Vnet Peering with DevBox Vnet')
  devBoxPeering: bool
})[]

param parSpokeNetworks spokesType = [
  // {
  //   subscriptionId: 'b83b4631-b51b-4961-86a1-295f539c826b' //Development
  //   parEnvironment: 'dev'
  //   workloadName: 'container-app'
  //   zoneRedundancy: false
  //   ddosProtectionEnabled: 'Disabled'
  //   containerRegistryTier: 'Premium'
  //   deploy: true
  //   configurePrivateDNS: true
  //   devBoxPeering: true
  //   rgNetworking: 'rg-rsp-networking-spoke-dev-uks'
  //   vnet: 'vnet-rsp-networking-dev-uks-spoke'
  //   rgapplications: 'rg-rsp-applications-spoke-dev-uks'
  //   rgSharedServices: 'rg-rsp-sharedservices-spoke-dev-uks'
  //   rgStorage: 'rg-rsp-storage-spoke-dev-uks'
  //   deployWebAppSlot: false
  // }
  {
    subscriptionId: '66482e26-764b-4717-ae2f-fab6b8dd1379' //System Test Manual
    parEnvironment: 'manualtest'
    workloadName: 'container-app'
    zoneRedundancy: false
    ddosProtectionEnabled: 'Disabled'
    containerRegistryTier: 'Premium'
    deploy: false
    configurePrivateDNS: false
    devBoxPeering: false
    rgNetworking: 'rg-rsp-networking-spoke-systemtest-uks'
    vnet: 'vnet-rsp-networking-manualtest-uks-spoke'
    rgapplications: 'rg-rsp-applications-spoke-systemtest-uks'
    rgSharedServices: 'rg-rsp-sharedservices-spoke-systemtest-uks'
    rgStorage: 'rg-rsp-storage-spoke-systemtest-uks'
    deployWebAppSlot: false
  }
  // {
  //   subscriptionId: '75875981-b04d-42c7-acc5-073e2e5e2e65' //System Test Automated
  //   parEnvironment: 'automationtest'
  //   workloadName: 'container-app'
  //   zoneRedundancy: false
  //   ddosProtectionEnabled: 'Disabled'
  //   containerRegistryTier: 'Premium'
  //   deploy: false
  //   configurePrivateDNS: false
  //   rgNetworking: 'rg-rsp-networking-spoke-systemtestauto-uks'
  //   vnet: 'vnet-rsp-networking-systemtestauto-uks-spoke'
  //   rgapplications: 'rg-rsp-applications-spoke-systemtestauto-uks'
  //   rgSharedServices: 'rg-rsp-sharedservices-spoke-systemtestauto-uks'
  //   rgStorage: 'rg-rsp-storage-spoke-systemtestauto-uks'
  //   deployWebAppSlot: false
  //   devBoxPeering: false
  // }
  // {
  //   subscriptionId: 'c9d1b222-c47a-43fc-814a-33083b8d3375' //System Test Integration
  //   parEnvironment: 'integrationtest'
  //   workloadName: 'container-app'
  //   zoneRedundancy: false
  //   ddosProtectionEnabled: 'Disabled'
  //   containerRegistryTier: 'Premium'
  //   deploy: false
  //   configurePrivateDNS: false
  //   rgNetworking: 'rg-rsp-networking-spoke-systemtestint-uks'
  //   vnet: 'vnet-rsp-networking-systemtestint-uks-spoke'
    // rgapplications: 'rg-rsp-applications-spoke-systemtestint-uks'
    // rgSharedServices: 'rg-rsp-sharedservices-spoke-systemtestint-uks'
    // rgStorage: 'rg-rsp-storage-spoke-systemtestint-uks'
  // }
  // {
  //   subscriptionId: '' //UAT
  //   parEnvironment: 'uat'
  //   workloadName: 'container-app'
  //   zoneRedundancy: true
  //   ddosProtectionEnabled: 'Enabled'
  //   containerRegistryTier: 'Premium'
  //   deploy: false
  //   configurePrivateDNS: true
  // rgNetworking: 'rg-rsp-networking-spoke-uat-uks'
  //   vnet: 'vnet-rsp-networking-systemtestint-uks-spoke'
    // rgapplications: 'rg-rsp-applications-spoke-uat-uks'
    // rgSharedServices: 'rg-rsp-sharedservices-spoke-uat-uks'
    // rgStorage: 'rg-rsp-storage-spoke-uat-uks'
  // }
  // {
  //   subscriptionId: '' //PreProd
  //   parEnvironment: 'preprod'
  //   workloadName: 'container-app'
  //   zoneRedundancy: true
  //   ddosProtectionEnabled: 'Enabled'
  //   containerRegistryTier: 'Premium'
  //   deploy: false
  //   configurePrivateDNS: true
  // rgNetworking: 'rg-rsp-networking-spoke-preprod-uks'
  //   vnet: 'vnet-rsp-networking-systemtestint-uks-spoke'
    // rgapplications: 'rg-rsp-applications-spoke-preprod-uks'
    // rgSharedServices: 'rg-rsp-sharedservices-spoke-preprod-uks'
    // rgStorage: 'rg-rsp-storage-spoke-preprod-uks'
  // }
  // {
  //   subscriptionId: '' //Prod
  //   parEnvironment: 'prod'
  //   workloadName: 'container-app'
  //   zoneRedundancy: true
  //   ddosProtectionEnabled: 'Enabled'
  //   containerRegistryTier: 'Premium'
  //   deploy: false
  //   configurePrivateDNS: true
  // rgNetworking: 'rg-rsp-networking-spoke-prod-uks'
  //   vnet: 'vnet-rsp-networking-systemtestint-uks-spoke'
    // rgapplications: 'rg-rsp-applications-spoke-prod-uks'
    // rgSharedServices: 'rg-rsp-sharedservices-spoke-prod-uks'
    // rgStorage: 'rg-rsp-storage-spoke-prod-uks'
  //   }
  // }
]

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
    databases : ['applicationservice','identityservice','questionsetservice']
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
    configStoreName: sharedServicesNaming[i].outputs.resourcesNames.azureappconfigurationstore
    webAppURLConfigKey: 'AppSettings:UsersServiceUri'
    sharedservicesRG: parSpokeNetworks[i].rgSharedServices
  }
  dependsOn: [
    databaseserver
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
    configStoreName: sharedServicesNaming[i].outputs.resourcesNames.azureappconfigurationstore
    webAppURLConfigKey: 'AppSettings:QuestionSetServiceUri'
    sharedservicesRG: parSpokeNetworks[i].rgSharedServices
  }
  dependsOn: [
    databaseserver
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
