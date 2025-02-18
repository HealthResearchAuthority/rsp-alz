targetScope = 'subscription'

// ------------------
//    PARAMETERS
// ------------------

@description('The location where the resources will be created.')
param location string =  deployment().location

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

//Hub
param hubVNetId string = '/subscriptions/15642d2a-27a2-4ee8-9eba-788bf7223d95/resourceGroups/rg-hra-connectivity/providers/Microsoft.Network/virtualHubs/vhub-rsp-uksouth'

// @description('Virtual Appliance IP Address. Firewall IP Address')
// param networkApplianceIpAddress string = '10.1.64.4' //Hub firewall IP Address


//DevBox
// @description('DevBox Subscription ID')
// param parDevBoxVNetPeeringSubscriptionID string = ''

// @description('DevBox Vnet RG Name')
// param parDevBoxVNetPeeringResourceGroup string = ''

// @description('DevBox Vnet Name')
// param parDevBoxVNetPeeringVNetName string = ''

// Spoke
@description('Central Log Analytics Workspace ID')
param logAnalyticsWorkspaceId string = '/subscriptions/8747cd7f-1a06-4fe4-9dbb-24f612b9dd5a/resourceGroups/rg-hra-operationsmanagement/providers/Microsoft.OperationalInsights/workspaces/hra-rsp-log-analytics'

@description('The FQDN of the Application Gateway. Must match the TLS Certificate.')
param applicationGatewayFqdn string

@description('Enable or disable Application Gateway Certificate (PFX).')
param enableApplicationGatewayCertificate bool

@description('The name of the certificate key to use for Application Gateway certificate.')
param applicationGatewayCertificateKeyName string

@description('Client Key for IDG Authentication')
param parClientID string

@secure()
@description('Client secret for IDG Authentication')
param parClientSecret string

// @description('Enable usage and telemetry feedback to Microsoft.')
// param enableTelemetry bool = true

// @description('Optional, default value is true. If true, any resources that support AZ will be deployed in all three AZ. However if the selected region is not supporting AZ, this parameter needs to be set to false.')
// param deployZoneRedundantResources bool = true

//Database
param parAdminLogin string = ''
param parSqlAdminPhrase string

type spokesType = ({
  @description('SubscriptionId for spokeNetworking')
  subscriptionId: string

  @description('Address prefix (CIDR) for spokeNetworking')
  ipRange: string

  @description('managementGroup for subscription placement')
  workloadName: string

  @description('Subnet information')
  subnets: object

  @description('Name of environment')
  parEnvironment: string

  @description('Name of networking resource group')
  rgNetworking: string

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

  @description('Boolean to indicate Spoke Vnet Peering with DevBox Vnet')
  devBoxPeering: bool

  @description('Boolean to indicate to deploy web app slot')
  deployWebAppSlot: bool
  
})[]

@description('Optional, default value is true. If true, Azure Policies will be deployed')
param deployAzurePolicies bool = true


param parSpokeNetworks spokesType = [
  {
    subscriptionId: 'b83b4631-b51b-4961-86a1-295f539c826b' //Development
    ipRange: '10.2.0.0/16'
    parEnvironment: 'dev'
    workloadName: 'container-app'
    zoneRedundancy: false
    ddosProtectionEnabled: 'Disabled'
    containerRegistryTier: 'Premium'
    deploy: true
    configurePrivateDNS: true
    devBoxPeering: true
    rgNetworking: 'rg-rsp-networking-spoke-dev-uks'
    rgapplications: 'rg-rsp-applications-spoke-dev-uks'
    rgSharedServices: 'rg-rsp-sharedservices-spoke-dev-uks'
    rgStorage: 'rg-rsp-storage-spoke-dev-uks'
    deployWebAppSlot: false
    subnets: {
      infraSubnet: {
        addressPrefix: '10.2.0.0/18'
      }
      webAppSubnet: {
        addressPrefix: '10.2.128.0/18'
      }
      appGatewaySubnet: {
        addressPrefix: '10.2.64.0/24'
      }
      privateEndPointSubnet: {
        addressPrefix: '10.2.65.0/24'
      }
    }
  }
  // {
  //   subscriptionId: '66482e26-764b-4717-ae2f-fab6b8dd1379' //System Test Manual
  //   ipRange: '10.3.0.0/16'
  //   parEnvironment: 'manualtest'
  //   workloadName: 'container-app'
  //   zoneRedundancy: false
  //   ddosProtectionEnabled: 'Disabled'
  //   containerRegistryTier: 'Premium'
  //   deploy: false
  //   configurePrivateDNS: true
  //   devBoxPeering: false
  //   rgNetworking: 'rg-rsp-networking-spoke-systemtest-uks'
  //   rgapplications: 'rg-rsp-applications-spoke-systemtest-uks'
  //   rgSharedServices: 'rg-rsp-sharedservices-spoke-systemtest-uks'
  //   rgStorage: 'rg-rsp-storage-spoke-systemtest-uks'
  //   deployWebAppSlot: true
  //   subnets: {
  //     infraSubnet: {
  //       addressPrefix: '10.3.0.0/18'
  //     }
  //     webAppSubnet: {
  //       addressPrefix: '10.3.128.0/18'
  //     }
  //     appGatewaySubnet: {
  //       addressPrefix: '10.3.64.0/24'
  //     }
  //     privateEndPointSubnet: {
  //       addressPrefix: '10.3.65.0/24'
  //     }
  //   }
  // }
  // {
  //   subscriptionId: '75875981-b04d-42c7-acc5-073e2e5e2e65' //System Test Automated
  //   ipRange: '10.1.32.0/19'
  //   parEnvironment: 'automationtest'
  //   workloadName: 'container-app'
  //   zoneRedundancy: false
  //   ddosProtectionEnabled: 'Disabled'
  //   containerRegistryTier: 'Premium'
  //   deploy: false
  //   configurePrivateDNS: false
  //   rgNetworking: 'rg-rsp-networking-spoke-systemtestauto-uks'
  //   rgapplications: 'rg-rsp-applications-spoke-systemtestauto-uks'
  //   rgSharedServices: 'rg-rsp-sharedservices-spoke-systemtestauto-uks'
  //   rgStorage: 'rg-rsp-storage-spoke-systemtestauto-uks'
  //   deployWebAppSlot: false
  //   devBoxPeering: false
  //   subnets: {
  //     infraSubnet: {
  //       addressPrefix: '10.1.32.0/20'
  //     }
  //     appGatewaySubnet: {
  //       addressPrefix: '10.1.63.0/24'
  //     }
  //     webAppSubnet: {
  //       addressPrefix: '10.1.48.0/22'
  //     }
  //     privateEndPointSubnet: {
  //       addressPrefix: '10.1.62.0/24'
  //     }  
  //   }
  // }
  // {
  //   subscriptionId: 'c9d1b222-c47a-43fc-814a-33083b8d3375' //System Test Integration
  //   ipRange: '10.4.0.0/16'
  //   parEnvironment: 'integrationtest'
  //   workloadName: 'container-app'
  //   zoneRedundancy: false
  //   ddosProtectionEnabled: 'Disabled'
  //   containerRegistryTier: 'Premium'
  //   deploy: false
  //   configurePrivateDNS: false
  // rgNetworking: 'rg-rsp-networking-spoke-systemtestint-uks'
    // rgapplications: 'rg-rsp-applications-spoke-systemtestint-uks'
    // rgSharedServices: 'rg-rsp-sharedservices-spoke-systemtestint-uks'
    // rgStorage: 'rg-rsp-storage-spoke-systemtestint-uks'
  //   subnets: {
  //     infraSubnet: {
  //       addressPrefix: '10.4.0.0/18'
  //     }
  //     appGatewaySubnet: {
  //       addressPrefix: '10.4.64.0/24'
  //     }
  //     privateEndPointSubnet: {
  //       addressPrefix: '10.4.65.0/24'
  //     }
  //   }
  // }
  // {
  //   subscriptionId: '' //UAT
  //   ipRange: '10.5.0.0/16'
  //   parEnvironment: 'uat'
  //   workloadName: 'container-app'
  //   zoneRedundancy: true
  //   ddosProtectionEnabled: 'Enabled'
  //   containerRegistryTier: 'Premium'
  //   deploy: false
  //   configurePrivateDNS: true
  // rgNetworking: 'rg-rsp-networking-spoke-uat-uks'
    // rgapplications: 'rg-rsp-applications-spoke-uat-uks'
    // rgSharedServices: 'rg-rsp-sharedservices-spoke-uat-uks'
    // rgStorage: 'rg-rsp-storage-spoke-uat-uks'
  //   subnets: {
  //     infraSubnet: {
  //       addressPrefix: '10.5.0.0/18'
  //     }
  //     appGatewaySubnet: {
  //       addressPrefix: '10.5.64.0/24'
  //     }
  //     privateEndPointSubnet: {
  //       addressPrefix: '10.5.65.0/24'
  //     }
  //   }
  // }
  // {
  //   subscriptionId: '' //PreProd
  //   ipRange: '10.6.0.0/16'
  //   parEnvironment: 'preprod'
  //   workloadName: 'container-app'
  //   zoneRedundancy: true
  //   ddosProtectionEnabled: 'Enabled'
  //   containerRegistryTier: 'Premium'
  //   deploy: false
  //   configurePrivateDNS: true
  // rgNetworking: 'rg-rsp-networking-spoke-preprod-uks'
    // rgapplications: 'rg-rsp-applications-spoke-preprod-uks'
    // rgSharedServices: 'rg-rsp-sharedservices-spoke-preprod-uks'
    // rgStorage: 'rg-rsp-storage-spoke-preprod-uks'
  //   subnets: {
  //     infraSubnet: {
  //       addressPrefix: '10.6.0.0/18'
  //     }
  //     appGatewaySubnet: {
  //       addressPrefix: '10.6.64.0/24'
  //     }
  //     privateEndPointSubnet: {
  //       addressPrefix: '10.6.65.0/24'
  //     }
  //   }
  // }
  // {
  //   subscriptionId: '' //Prod
  //   ipRange: '10.7.0.0/16'
  //   parEnvironment: 'prod'
  //   workloadName: 'container-app'
  //   zoneRedundancy: true
  //   ddosProtectionEnabled: 'Enabled'
  //   containerRegistryTier: 'Premium'
  //   deploy: false
  //   configurePrivateDNS: true
  // rgNetworking: 'rg-rsp-networking-spoke-prod-uks'
    // rgapplications: 'rg-rsp-applications-spoke-prod-uks'
    // rgSharedServices: 'rg-rsp-sharedservices-spoke-prod-uks'
    // rgStorage: 'rg-rsp-storage-spoke-prod-uks'
  //   subnets: {
  //     infraSubnet: {
  //       addressPrefix: '10.7.0.0/18'
  //     }
  //     appGatewaySubnet: {
  //       addressPrefix: '10.7.64.0/24'
  //     }
  //     privateEndPointSubnet: {
  //       addressPrefix: '10.7.65.0/24'
  //     }
  //   }
  // }
]

// ------------------
// VARIABLES
// ------------------

var varVirtualHubResourceGroup = (!empty(hubVNetId) && contains(hubVNetId, '/providers/Microsoft.Network/virtualHubs/') ? split(hubVNetId, '/')[4] : '')
var varVirtualHubSubscriptionId = (!empty(hubVNetId) && contains(hubVNetId, '/providers/Microsoft.Network/virtualHubs/') ? split(hubVNetId, '/')[2] : '')
//var varHubVirtualNetworkName = (!empty(hubVNetId) && contains(hubVNetId, '/providers/Microsoft.Network/virtualHubs/') ? split(hubVNetId, '/')[8] : '')

var sqlServerNamePrefix = 'rspsqlserver'
// ------------------
// RESOURCES
// ------------------

module networkingRG '../shared/bicep/resourceGroup.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  name: take('networkingRG-${deployment().name}', 64)
  scope: subscription(parSpokeNetworks[i].subscriptionId)
  params:{
    parLocation: location
    parResourceGroupName: parSpokeNetworks[i].rgNetworking
  }
}]

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

@description('User-configured naming rules')
module networkingnaming '../shared/bicep/naming/naming.module.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  name: take('03-sharedNamingDeployment-${deployment().name}', 64)
  scope: resourceGroup(parSpokeNetworks[i].subscriptionId,parSpokeNetworks[i].rgNetworking)
  params: {
    uniqueId: uniqueString(networkingRG[i].outputs.outResourceGroupId)
    environment: parSpokeNetworks[i].parEnvironment
    workloadName: 'networking'
    location: location
  }
}]

@description('User-configured naming rules')
module sharedServicesNaming '../shared/bicep/naming/naming.module.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  name: take('sharedNamingDeployment-${deployment().name}', 64)
  scope: resourceGroup(parSpokeNetworks[i].subscriptionId,parSpokeNetworks[i].rgSharedServices)
  params: {
    uniqueId: uniqueString(sharedServicesRG[i].outputs.outResourceGroupId)
    environment: parSpokeNetworks[i].parEnvironment
    workloadName: 'shared'
    location: location
  }
}]

@description('User-configured naming rules')
module storageServicesNaming '../shared/bicep/naming/naming.module.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  name: take('storageServicesNaming-${deployment().name}', 64)
  scope: resourceGroup(parSpokeNetworks[i].subscriptionId,parSpokeNetworks[i].rgStorage)
  params: {
    uniqueId: uniqueString(storageRG[i].outputs.outResourceGroupId)
    environment: parSpokeNetworks[i].parEnvironment
    workloadName: 'storage'
    location: location
  }
}]

@description('User-configured naming rules')
module applicationServicesNaming '../shared/bicep/naming/naming.module.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  name: take('applicationServicesNaming-${deployment().name}', 64)
  scope: resourceGroup(parSpokeNetworks[i].subscriptionId,parSpokeNetworks[i].rgapplications)
  params: {
    uniqueId: uniqueString(applicationsRG[i].outputs.outResourceGroupId)
    environment: parSpokeNetworks[i].parEnvironment
    workloadName: 'applications'
    location: location
  }
}]

module spoke 'modules/02-spoke/deploy.spoke.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  name: take('spoke-${deployment().name}-deployment-${i}', 64)
  scope: subscription(parSpokeNetworks[i].subscriptionId)
  params: {
    location: location
    tags: tags
    spokeApplicationGatewaySubnetAddressPrefix: parSpokeNetworks[i].subnets.appGatewaySubnet.addressPrefix
    spokeInfraSubnetAddressPrefix: parSpokeNetworks[i].subnets.infraSubnet.addressPrefix
    spokePrivateEndpointsSubnetAddressPrefix: parSpokeNetworks[i].subnets.privateEndPointSubnet.addressPrefix
    spokeWebAppSubnetAddressPrefix: parSpokeNetworks[i].subnets.webAppSubnet.addressPrefix
    spokeVNetAddressPrefixes: [parSpokeNetworks[i].ipRange]
    //networkApplianceIpAddress: networkApplianceIpAddress
    deployAzurePolicies: deployAzurePolicies
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    // parHubResourceGroup: varVirtualHubResourceGroup
    // parHubSubscriptionId: varVirtualHubSubscriptionId
    // parHubResourceId: hubVNetId
    resourcesNames: networkingnaming[i].outputs.resourcesNames
    spokeNetworkingRGName: parSpokeNetworks[i].rgNetworking
  }
}]

module supportingServices 'modules/03-supporting-services/deploy.supporting-services.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  name: take('supportingServices-${deployment().name}-deployment-${i}', 64)
  scope: resourceGroup(parSpokeNetworks[i].subscriptionId,parSpokeNetworks[i].rgSharedServices)
  params: {
    location: location
    tags: tags
    spokePrivateEndpointSubnetName: spoke[i].outputs.spokePrivateEndpointsSubnetName
    spokeVNetId: spoke[i].outputs.spokeVNetId
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    deployZoneRedundantResources: parSpokeNetworks[i].zoneRedundancy
    containerRegistryTier: parSpokeNetworks[i].containerRegistryTier
    privateDNSEnabled: parSpokeNetworks[i].configurePrivateDNS
    resourcesNames: sharedServicesNaming[i].outputs.resourcesNames
    sqlServerName: '${sqlServerNamePrefix}${parSpokeNetworks[i].parEnvironment}'
    networkingResourcesNames: networkingnaming[i].outputs.resourcesNames
    networkingResourceGroup: parSpokeNetworks[i].rgNetworking
    jwksURI: 'irasportal-${parSpokeNetworks[i].parEnvironment}.azurewebsites.net'
    IDGENV: ''
    clientID: parClientID
    clientSecret: parClientSecret
  }
}]

module containerAppsEnvironment 'modules/04-container-apps-environment/deploy.aca-environment.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  name: take('containerAppsEnvironment-${deployment().name}-deployment', 64)
  scope: resourceGroup(parSpokeNetworks[i].subscriptionId,parSpokeNetworks[i].rgapplications)
  params: {
    location: location
    tags: tags
    spokeVNetName: spoke[i].outputs.spokeVNetName
    spokeInfraSubnetName: spoke[i].outputs.spokeInfraSubnetName
    enableApplicationInsights: true
    enableTelemetry: false
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    hubResourceGroupName: varVirtualHubResourceGroup
    hubSubscriptionId: varVirtualHubSubscriptionId
    //hubVNetName: varHubVirtualNetworkName
    deployZoneRedundantResources: parSpokeNetworks[i].zoneRedundancy
    privateDNSEnabled: parSpokeNetworks[i].configurePrivateDNS
    resourcesNames: applicationServicesNaming[i].outputs.resourcesNames
    networkRG: parSpokeNetworks[i].rgNetworking
  }
}]

module databaseserver 'modules/05-database/deploy.database.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  name: take('database-${deployment().name}-deployment', 64)
  scope: resourceGroup(parSpokeNetworks[i].subscriptionId,parSpokeNetworks[i].rgStorage)
  params: {
    location: location
    sqlServerName: '${sqlServerNamePrefix}${parSpokeNetworks[i].parEnvironment}'
    adminLogin: parAdminLogin
    adminPassword: parSqlAdminPhrase
    databases : ['applicationservice','identityservice','questionsetservice','rtsservice']
    environment: parSpokeNetworks[i].parEnvironment
    spokePrivateEndpointSubnetName: spoke[i].outputs.spokePrivateEndpointsSubnetName
    spokeVNetId: spoke[i].outputs.spokeVNetId
    sqlServerUAIName: storageServicesNaming[i].outputs.resourcesNames.sqlServerUserAssignedIdentity
    networkingResourcesNames: networkingnaming[i].outputs.resourcesNames
    networkingResourceGroup: parSpokeNetworks[i].rgNetworking
  }
}]

module irasserviceapp 'modules/06-container-app/deploy.container-app.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  name: take('iraserviceapp-${deployment().name}-deployment', 64)
  scope: resourceGroup(parSpokeNetworks[i].subscriptionId,parSpokeNetworks[i].rgapplications)
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
    //containertag: 'loggingversion'
    configStoreName: sharedServicesNaming[i].outputs.resourcesNames.azureappconfigurationstore
    webAppURLConfigKey: 'AppSettings:ApplicationsServiceUri'
    sharedservicesRG: parSpokeNetworks[i].rgSharedServices
    //acrName: supportingServices[i].outputs.containerRegistryName
  }
  dependsOn: [
    databaseserver
  ]
}]

module usermanagementapp 'modules/06-container-app/deploy.container-app.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  name: take('usermanagementapp-${deployment().name}-deployment', 64)
  scope: resourceGroup(parSpokeNetworks[i].subscriptionId,parSpokeNetworks[i].rgapplications)
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
    //containertag: 'updatedversion2'
    configStoreName: sharedServicesNaming[i].outputs.resourcesNames.azureappconfigurationstore
    webAppURLConfigKey: 'AppSettings:UsersServiceUri'
    sharedservicesRG: parSpokeNetworks[i].rgSharedServices
    //acrName: supportingServices[i].outputs.containerRegistryName
  }
  dependsOn: [
    databaseserver
  ]
}]

module questionsetapp 'modules/06-container-app/deploy.container-app.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  name: take('questionsetapp-${deployment().name}-deployment', 64)
  scope: resourceGroup(parSpokeNetworks[i].subscriptionId,parSpokeNetworks[i].rgapplications)
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
    //containertag: '1955'
    configStoreName: sharedServicesNaming[i].outputs.resourcesNames.azureappconfigurationstore
    webAppURLConfigKey: 'AppSettings:QuestionSetServiceUri'
    sharedservicesRG: parSpokeNetworks[i].rgSharedServices
    //acrName: supportingServices[i].outputs.containerRegistryName
  }
  dependsOn: [
    databaseserver
  ]
}]

module webApp 'modules/07-app-service/deploy.app-service.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  scope: resourceGroup(parSpokeNetworks[i].subscriptionId,parSpokeNetworks[i].rgapplications)
  name: take('webApp-${deployment().name}-deployment', 64)
  params: {
    tags: {}
    sku: 'B1'
    logAnalyticsWsId: logAnalyticsWorkspaceId
    location: location
    appServicePlanName: applicationServicesNaming[i].outputs.resourcesNames.appServicePlan
    webAppName: 'irasportal-${parSpokeNetworks[i].parEnvironment}'
    webAppBaseOs: 'Linux'
    subnetIdForVnetInjection: spoke[i].outputs.spokeWebAppSubnetId
    appConfigmanagedIdentityId: supportingServices[i].outputs.appConfigurationUserAssignedIdentityId
    deploySlot: parSpokeNetworks[i].deployWebAppSlot
    privateEndpointRG: parSpokeNetworks[i].rgNetworking
    spokeVNetId: spoke[i].outputs.spokeVNetId
    subnetPrivateEndpointSubnetId: spoke[i].outputs.spokePepSubnetId
  }
}]

module applicationGateway 'modules/08-application-gateway/deploy.app-gateway.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  name: take('applicationGateway-${deployment().name}-deployment', 64)
  scope: resourceGroup(parSpokeNetworks[i].subscriptionId,parSpokeNetworks[i].rgNetworking)
  params: {
    location: location
    tags: tags
    applicationGatewayCertificateKeyName: applicationGatewayCertificateKeyName
    applicationGatewayFqdn: applicationGatewayFqdn
    applicationGatewayPrimaryBackendEndFqdn: webApp[i].outputs.webAppHostName //(deployInitialRevision) ? irasserviceapp[i].outputs.containerAppFqdn : '' // To fix issue when hello world is not deployed
    applicationGatewaySubnetId: spoke[i].outputs.spokeApplicationGatewaySubnetId
    enableApplicationGatewayCertificate: enableApplicationGatewayCertificate
    keyVaultId: supportingServices[i].outputs.keyVaultId
    deployZoneRedundantResources: parSpokeNetworks[i].zoneRedundancy
    ddosProtectionMode: 'Disabled'
    applicationGatewayLogAnalyticsId: logAnalyticsWorkspaceId
    networkingResourceNames: networkingnaming[i].outputs.resourcesNames
  }
}]
// The resources below this needs to be moved to main.application.bicep

// module redisCache '../shared/bicep/redis.bicep' = [for i in range(0, length(parSpokeNetworks)): {
//   name: take('rediscache-${deployment().name}-deployment', 64)
//   scope: resourceGroup(parSpokeNetworks[i].subscriptionId,parSpokeNetworks[i].rgStorage)
//   params: {
//     name: 'iras-redis-cache'
//     keyvaultName: supportingServices[i].outputs.keyVaultName
//     diagnosticWorkspaceId: logAnalyticsWorkspaceId
//   }
// }]

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
    configStoreName: sharedServicesNaming[i].outputs.resourcesNames.azureappconfigurationstore
    webAppURLConfigKey: 'AppSettings:RtsServiceUri'
    sharedservicesRG: parSpokeNetworks[i].rgSharedServices
  }
  dependsOn: [
    databaseserver
  ]
}]

module rtsdatapullfunction '../shared/bicep/app-services/function-app.bicep' = [for i in range(0, length(parSpokeNetworks)): {
  name: take('functionapp-${deployment().name}-deployment', 64)
  scope: resourceGroup(parSpokeNetworks[i].subscriptionId, parSpokeNetworks[i].rgapplications)
  params: {
    functionAppName: 'rts-data-pull-function'
    location: location
    storageAccountName: 'irasrtsdatapullsa'
    appSettings: [
      {
        name: 'ExampleSetting'
        value: 'ExampleValue'
      }
    ]
  }
}]

// ------------------
// OUTPUTS
// ------------------

// Spoke
@description('The  resource ID of the Spoke Virtual Network.')
output spokeVNetIds array = [for i in range(0, length(parSpokeNetworks)): {
  Name: spoke[i].outputs.spokeVNetId
}]

@description('The name of the Spoke Virtual Network.')
output spokeVnetNames array = [for i in range(0, length(parSpokeNetworks)): {
  Name: spoke[i].outputs.spokeVNetName
}]

@description('The resource ID of the Spoke Infrastructure Subnet.')
output spokeInfraSubnetIds array = [for i in range(0, length(parSpokeNetworks)): {
  Name: spoke[i].outputs.spokeInfraSubnetId
}]

@description('The name of the Spoke Infrastructure Subnet.')
output spokeInfraSubnetNames array = [for i in range(0, length(parSpokeNetworks)): {
  Name: spoke[i].outputs.spokeInfraSubnetName
}]

@description('The name of the Spoke Private Endpoints Subnet.')
output spokePrivateEndpointsSubnetNames array = [for i in range(0, length(parSpokeNetworks)): {
  Name: spoke[i].outputs.spokePrivateEndpointsSubnetName
}]

@description('The resource ID of the Spoke Application Gateway Subnet. If "spokeApplicationGatewaySubnetAddressPrefix" is empty, the subnet will not be created and the value returned is empty.')
output spokeApplicationGatewaySubnetIds array = [for i in range(0, length(parSpokeNetworks)): {
  Name: spoke[i].outputs.spokeApplicationGatewaySubnetId
}]

@description('The name of the Spoke Application Gateway Subnet.  If "spokeApplicationGatewaySubnetAddressPrefix" is empty, the subnet will not be created and the value returned is empty.')
output spokeApplicationGatewaySubnetNames array = [for i in range(0, length(parSpokeNetworks)): {
  Name: spoke[i].outputs.spokeApplicationGatewaySubnetName
}]

// Supporting Services
// @description('The resource ID of the container registry.')
// output containerRegistryIds array = [for i in range(0, length(parSpokeNetworks)): {
//   Name: supportingServices[i].outputs.containerRegistryId
// }]

// @description('The name of the container registry.')
// output containerRegistryNames array = [for i in range(0, length(parSpokeNetworks)): {
//   Name: supportingServices[i].outputs.containerRegistryName
// }]

// @description('The name of the container registry login server.')
// output containerRegistryLoginServers array = [for i in range(0, length(parSpokeNetworks)): {
//   Name: supportingServices[i].outputs.containerRegistryLoginServer
// }]

// @description('The resource ID of the user assigned managed identity for the container registry to be able to pull images from it.')
// output containerRegistryUserAssignedIdentityIds array = [for i in range(0, length(parSpokeNetworks)): {
//   Name: supportingServices[i].outputs.containerRegistryUserAssignedIdentityId
// }]

@description('The resource ID of the key vault.')
output keyVaultIds array = [for i in range(0, length(parSpokeNetworks)): {
  Name: supportingServices[i].outputs.keyVaultId
}]

@description('The name of the key vault.')
output keyVaultNames array = [for i in range(0, length(parSpokeNetworks)): {
  Name: supportingServices[i].outputs.keyVaultName
}]

// Container Apps Environment
// @description('The resource ID of the container apps environment.')
// output containerAppsEnvironmentId string = containerAppsEnvironment.outputs.containerAppsEnvironmentId

// @description('The name of the container apps environment.')
// output containerAppsEnvironmentName string = containerAppsEnvironment.outputs.containerAppsEnvironmentName

// @description(' The name of application Insights instance.')
// output applicationInsightsName string =  (enableApplicationInsights)? containerAppsEnvironment.outputs.applicationInsightsName : ''
