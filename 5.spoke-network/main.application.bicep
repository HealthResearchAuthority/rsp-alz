targetScope = 'subscription'
// ------------------
// PARAMETERS
// ------------------

@description('The location where the resources will be created.')
param location string = deployment().location

@description('DevOps Public IP Address')
param parDevOpsPublicIPAddress string = ''

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

@description('Central Log Analytics Workspace ID')
param logAnalyticsWorkspaceId string = '/subscriptions/8747cd7f-1a06-4fe4-9dbb-24f612b9dd5a/resourceGroups/rg-hra-operationsmanagement/providers/Microsoft.OperationalInsights/workspaces/hra-rsp-log-analytics'

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

@description('Token issuing authority for Gov UK One Login')
param parOneLoginAuthority string

@secure()
@description('Private RSA key for signing the token')
param parOneLoginPrivateKeyPem string

@description('ClientId for the registered service in Gov UK One Login')
param parOneLoginClientId string

@description('Valid token issuers for Gov UK One Login')
param parOneLoginIssuers array

@description('How long to keep SQL audit logs in days (default: 15 days)')
param parSqlAuditRetentionDays int = 15

@description('Spoke Networks Configuration')
param parSpokeNetworks array

@description('File upload storage account configuration')
param parFileUploadStorageConfig object = {
  containerName: 'staging'
  sku: 'Standard_LRS'
  accessTier: 'Hot'
  allowPublicAccess: false
}

@description('Enable Azure Front Door deployment')
param parEnableFrontDoor bool = true

@description('Front Door WAF policy mode')
@allowed([
  'Detection'
  'Prevention'
])
param parFrontDoorWafMode string = 'Prevention'

@description('Enable Front Door rate limiting')
param parEnableFrontDoorRateLimiting bool = true

@description('Front Door rate limit threshold (requests per minute)')
param parFrontDoorRateLimitThreshold int = 1000

@description('Enable Front Door caching')
param parEnableFrontDoorCaching bool = true

@description('Front Door cache duration')
param parFrontDoorCacheDuration string = 'P1D'

@description('Enable Front Door HTTPS redirect')
param parEnableFrontDoorHttpsRedirect bool = true

@description('Enable Front Door Private Link to origin')
param parEnableFrontDoorPrivateLink bool = false

@description('Front Door custom domains configuration')
param parFrontDoorCustomDomains array = []


@description('Microsoft Defender for Storage configuration')
param parDefenderForStorageConfig object = {
  enabled: false
  enableMalwareScanning: false
  enableSensitiveDataDiscovery: false
  enforce: false
}

@description('Override subscription level settings for storage account level defender configuration')
param parOverrideSubscriptionLevelSettings bool = false

// ------------------
// VARIABLES
// ------------------

var sqlServerNamePrefix = 'rspsqlserver'



// ------------------
// RESOURCES
// ------------------

module defenderStorage '../shared/bicep/security/defender-storage.bicep' = {
  name: take('defenderStorage-${deployment().name}', 64)
  scope: subscription()
  params: {
    enableDefenderForStorage: parDefenderForStorageConfig.enabled
    enableMalwareScanning: parDefenderForStorageConfig.enableMalwareScanning
    enableSensitiveDataDiscovery: parDefenderForStorageConfig.enableSensitiveDataDiscovery
    enforce: parDefenderForStorageConfig.enforce
  }
}

module sharedServicesRG '../shared/bicep/resourceGroup.bicep' = [
  for i in range(0, length(parSpokeNetworks)): {
    name: take('sharedServicesRG-${deployment().name}', 64)
    scope: subscription(parSpokeNetworks[i].subscriptionId)
    params: {
      parLocation: location
      parResourceGroupName: parSpokeNetworks[i].rgSharedServices
    }
  }
]

module storageRG '../shared/bicep/resourceGroup.bicep' = [
  for i in range(0, length(parSpokeNetworks)): {
    name: take('storageRG-${deployment().name}', 64)
    scope: subscription(parSpokeNetworks[i].subscriptionId)
    params: {
      parLocation: location
      parResourceGroupName: parSpokeNetworks[i].rgStorage
    }
  }
]

module applicationsRG '../shared/bicep/resourceGroup.bicep' = [
  for i in range(0, length(parSpokeNetworks)): {
    name: take('applicationsRG-${deployment().name}', 64)
    scope: subscription(parSpokeNetworks[i].subscriptionId)
    params: {
      parLocation: location
      parResourceGroupName: parSpokeNetworks[i].rgapplications
    }
  }
]

resource networkRgResource 'Microsoft.Resources/resourceGroups@2023-07-01' existing = {
  name: parSpokeNetworks[0].rgNetworking
  scope: subscription(parSpokeNetworks[0].subscriptionId)
}

@description('User-configured naming rules')
module networkingnaming '../shared/bicep/naming/naming.module.bicep' = [
  for i in range(0, length(parSpokeNetworks)): {
    name: take('03-sharedNamingDeployment-${deployment().name}', 64)
    scope: resourceGroup(parSpokeNetworks[i].subscriptionId, parSpokeNetworks[i].rgNetworking)
    params: {
      uniqueId: uniqueString(networkRgResource.id)
      environment: parSpokeNetworks[i].parEnvironment
      workloadName: 'networking'
      location: location
    }
  }
]

resource existingVnet 'Microsoft.Network/virtualNetworks@2024-03-01' existing = [
  for i in range(0, length(parSpokeNetworks)): {
    name: parSpokeNetworks[i].vnet
    scope: resourceGroup(parSpokeNetworks[i].rgNetworking)
  }
]

resource infraSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-03-01' existing = [
  for i in range(0, length(parSpokeNetworks)): {
    name: 'snet-infra'
    parent: existingVnet[i]
  }
]

resource pepSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-03-01' existing = [
  for i in range(0, length(parSpokeNetworks)): {
    name: 'snet-pep'
    parent: existingVnet[i]
  }
]

resource webAppSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-03-01' existing = [
  for i in range(0, length(parSpokeNetworks)): {
    name: 'snet-webapp'
    parent: existingVnet[i]
  }
]

// resource agwSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-03-01' existing = [for i in range(0, length(parSpokeNetworks)): {
//   name: 'snet-agw'
//   parent: existingVnet[i]
// }]

module sharedServicesNaming '../shared/bicep/naming/naming.module.bicep' = [
  for i in range(0, length(parSpokeNetworks)): {
    name: take('sharedNamingDeployment-${deployment().name}', 64)
    scope: resourceGroup(parSpokeNetworks[i].subscriptionId, parSpokeNetworks[i].rgSharedServices)
    params: {
      uniqueId: uniqueString(sharedServicesRG[i].outputs.outResourceGroupId)
      environment: parSpokeNetworks[i].parEnvironment
      workloadName: 'shared'
      location: location
    }
  }
]

module storageServicesNaming '../shared/bicep/naming/naming.module.bicep' = [
  for i in range(0, length(parSpokeNetworks)): {
    name: take('storageServicesNaming-${deployment().name}', 64)
    scope: resourceGroup(parSpokeNetworks[i].subscriptionId, parSpokeNetworks[i].rgStorage)
    params: {
      uniqueId: uniqueString(storageRG[i].outputs.outResourceGroupId)
      environment: parSpokeNetworks[i].parEnvironment
      workloadName: 'storage'
      location: location
    }
  }
]

module applicationServicesNaming '../shared/bicep/naming/naming.module.bicep' = [
  for i in range(0, length(parSpokeNetworks)): {
    name: take('applicationServicesNaming-${deployment().name}', 64)
    scope: resourceGroup(parSpokeNetworks[i].subscriptionId, parSpokeNetworks[i].rgapplications)
    params: {
      uniqueId: uniqueString(applicationsRG[i].outputs.outResourceGroupId)
      environment: parSpokeNetworks[i].parEnvironment
      workloadName: 'applications'
      location: location
    }
  }
]

module supportingServices 'modules/03-supporting-services/deploy.supporting-services.bicep' = [
  for i in range(0, length(parSpokeNetworks)): {
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
      //privateDNSEnabled: parSpokeNetworks[i].configurePrivateDNS
      resourcesNames: sharedServicesNaming[i].outputs.resourcesNames
      sqlServerName: '${sqlServerNamePrefix}${parSpokeNetworks[i].parEnvironment}'
      networkingResourcesNames: networkingnaming[i].outputs.resourcesNames
      networkingResourceGroup: parSpokeNetworks[i].rgNetworking
      jwksURI: 'irasportal-${parSpokeNetworks[i].parEnvironment}.azurewebsites.net'
      IDGENV: parSpokeNetworks[i].IDGENV
      clientID: parClientID
      clientSecret: parClientSecret
      devOpsPublicIPAddress: parDevOpsPublicIPAddress
      oneLoginAuthority: parOneLoginAuthority
      oneLoginPrivateKeyPem: parOneLoginPrivateKeyPem
      oneLoginClientId: parOneLoginClientId
      oneLoginIssuers: parOneLoginIssuers
    }
  }
]

module containerAppsEnvironment 'modules/04-container-apps-environment/deploy.aca-environment.bicep' = [
  for i in range(0, length(parSpokeNetworks)): {
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
      deployZoneRedundantResources: parSpokeNetworks[i].zoneRedundancy
      //privateDNSEnabled: parSpokeNetworks[i].configurePrivateDNS
      resourcesNames: applicationServicesNaming[i].outputs.resourcesNames
      networkRG: parSpokeNetworks[i].rgNetworking
    }
  }
]

// Process scan Function App (created first to get webhook endpoint for Event Grid)
module processScanFnApp 'modules/07-process-scan-function/deploy.process-scan-function.bicep' = [
  for i in range(0, length(parSpokeNetworks)): {
    scope: resourceGroup(parSpokeNetworks[i].subscriptionId, parSpokeNetworks[i].rgapplications)
    name: take('processScanFnApp-${deployment().name}-deployment', 64)
    params: {
      functionAppName: 'func-processdocupload-${parSpokeNetworks[i].parEnvironment}'
      location: location
      tags: tags
      appServicePlanName: 'asp-rsp-fnprocessdoc-${parSpokeNetworks[i].parEnvironment}-uks'
      storageAccountName: 'stprocessdocupld${parSpokeNetworks[i].parEnvironment}'
      logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
      subnetIdForVnetInjection: webAppSubnet[i].id
      spokeVNetId: existingVnet[i].id
      subnetPrivateEndpointSubnetId: pepSubnet[i].id
      userAssignedIdentities: [
        supportingServices[i].outputs.appConfigurationUserAssignedIdentityId
      ]
    }
    dependsOn: [
      applicationsRG
    ]
  }
]

// Document upload storage with malware scanning enabled (other storage accounts inherit subscription-level settings)
module documentUpload 'modules/09-document-upload/deploy.document-upload.bicep' = [
  for i in range(0, length(parSpokeNetworks)): {
    name: take('documentUpload-${deployment().name}-deployment', 64)
    scope: resourceGroup(parSpokeNetworks[i].subscriptionId, parSpokeNetworks[i].rgStorage)
    params: {
      location: location
      tags: tags
      spokeVNetId: existingVnet[i].id
      spokePrivateEndpointSubnetName: pepSubnet[i].name
      storageConfig: parFileUploadStorageConfig
      resourcesNames: storageServicesNaming[i].outputs.resourcesNames
      networkingResourceGroup: parSpokeNetworks[i].rgNetworking
      environment: parSpokeNetworks[i].parEnvironment
      enableMalwareScanning: true
      overrideSubscriptionLevelSettings: parOverrideSubscriptionLevelSettings
      logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
      enableEventGridIntegration: true
      enableEventGridSubscriptions: false  // Set to true only after Function App code is deployed and webhook endpoint is ready
      processScanWebhookEndpoint: processScanFnApp[i].outputs.webhookEndpoint
    }
    dependsOn: [
      defenderStorage
      storageRG
      processScanFnApp
    ]
  }
]

module databaseserver 'modules/05-database/deploy.database.bicep' = [
  for i in range(0, length(parSpokeNetworks)): {
    name: take('database-${deployment().name}-deployment', 64)
    scope: resourceGroup(parSpokeNetworks[i].subscriptionId, parSpokeNetworks[i].rgStorage)
    params: {
      location: location
      sqlServerName: '${sqlServerNamePrefix}${parSpokeNetworks[i].parEnvironment}'
      adminLogin: parAdminLogin
      adminPassword: parSqlAdminPhrase
      databases: ['applicationservice', 'identityservice', 'questionsetservice', 'rtsservice', 'cmsdatabase']
      spokePrivateEndpointSubnetName: pepSubnet[i].name // spoke[i].outputs.spokePrivateEndpointsSubnetName
      spokeVNetId: existingVnet[i].id // spoke[i].outputs.spokeVNetId
      sqlServerUAIName: storageServicesNaming[i].outputs.resourcesNames.sqlServerUserAssignedIdentity
      networkingResourcesNames: networkingnaming[i].outputs.resourcesNames
      networkingResourceGroup: parSpokeNetworks[i].rgNetworking
      auditRetentionDays: parSqlAuditRetentionDays
      enableSqlServerAuditing: true
      logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    }
  }
]

module irasserviceapp 'modules/06-container-app/deploy.container-app.bicep' = [
  for i in range(0, length(parSpokeNetworks)): {
    name: take('iraserviceapp-${deployment().name}-deployment', 64)
    scope: resourceGroup(parSpokeNetworks[i].subscriptionId, parSpokeNetworks[i].rgapplications)
    params: {
      location: location
      tags: tags
      containerRegistryUserAssignedIdentityId: supportingServices[i].outputs.containerRegistryUserAssignedIdentityId
      sqlServerUserAssignedIdentityName: databaseserver[i].outputs.outputsqlServerUAIName
      containerAppsEnvironmentId: containerAppsEnvironment[i].outputs.containerAppsEnvironmentId
      //appConfigurationUserAssignedIdentityId: supportingServices[i].outputs.appConfigurationUserAssignedIdentityId
      storageRG: parSpokeNetworks[i].rgStorage
      appConfigURL: supportingServices[i].outputs.appConfigURL
      appConfigIdentityClientID: supportingServices[i].outputs.appConfigIdentityClientID
      appInsightsConnectionString: parSpokeNetworks[i].appInsightsConnectionString
      containerRegistryLoginServer: supportingServices[i].outputs.containerRegistryLoginServer
      containerAppName: 'irasservice'
      containerImageTag: '${supportingServices[i].outputs.containerRegistryLoginServer}/${parIrasContainerImageTag}'
      containerImageName: 'irasservice'
      configStoreName: sharedServicesNaming[i].outputs.resourcesNames.azureappconfigurationstore
      webAppURLConfigKey: 'AppSettings:ApplicationsServiceUri'
      sharedservicesRG: parSpokeNetworks[i].rgSharedServices
      userAssignedIdentities: [
        supportingServices[i].outputs.appConfigurationUserAssignedIdentityId
        supportingServices[i].outputs.containerRegistryUserAssignedIdentityId
        //supportingServices[i].outputs.serviceBusSenderManagedIdentity
        databaseserver[i].outputs.outputsqlServerUAIID
      ]
    }
    dependsOn: [
      databaseserver
    ]
  }
]

module usermanagementapp 'modules/06-container-app/deploy.container-app.bicep' = [
  for i in range(0, length(parSpokeNetworks)): {
    name: take('usermanagementapp-${deployment().name}-deployment', 64)
    scope: resourceGroup(parSpokeNetworks[i].subscriptionId, parSpokeNetworks[i].rgapplications)
    params: {
      location: location
      tags: tags
      containerRegistryUserAssignedIdentityId: supportingServices[i].outputs.containerRegistryUserAssignedIdentityId
      sqlServerUserAssignedIdentityName: databaseserver[i].outputs.outputsqlServerUAIName
      containerAppsEnvironmentId: containerAppsEnvironment[i].outputs.containerAppsEnvironmentId
      //appConfigurationUserAssignedIdentityId: supportingServices[i].outputs.appConfigurationUserAssignedIdentityId
      storageRG: parSpokeNetworks[i].rgStorage
      appConfigURL: supportingServices[i].outputs.appConfigURL
      appConfigIdentityClientID: supportingServices[i].outputs.appConfigIdentityClientID
      appInsightsConnectionString: parSpokeNetworks[i].appInsightsConnectionString
      containerRegistryLoginServer: supportingServices[i].outputs.containerRegistryLoginServer
      containerAppName: 'usermanagementservice'
      containerImageTag: '${supportingServices[i].outputs.containerRegistryLoginServer}/${parUserServiceContainerImageTag}'
      containerImageName: 'usermanagementservice'
      configStoreName: sharedServicesNaming[i].outputs.resourcesNames.azureappconfigurationstore
      webAppURLConfigKey: 'AppSettings:UsersServiceUri'
      sharedservicesRG: parSpokeNetworks[i].rgSharedServices
      userAssignedIdentities: [
        supportingServices[i].outputs.appConfigurationUserAssignedIdentityId
        supportingServices[i].outputs.containerRegistryUserAssignedIdentityId
        databaseserver[i].outputs.outputsqlServerUAIID
      ]
    }
    dependsOn: [
      databaseserver
      irasserviceapp
    ]
  }
]

module questionsetapp 'modules/06-container-app/deploy.container-app.bicep' = [
  for i in range(0, length(parSpokeNetworks)): {
    name: take('questionsetapp-${deployment().name}-deployment', 64)
    scope: resourceGroup(parSpokeNetworks[i].subscriptionId, parSpokeNetworks[i].rgapplications)
    params: {
      location: location
      tags: tags
      containerRegistryUserAssignedIdentityId: supportingServices[i].outputs.containerRegistryUserAssignedIdentityId
      sqlServerUserAssignedIdentityName: databaseserver[i].outputs.outputsqlServerUAIName
      containerAppsEnvironmentId: containerAppsEnvironment[i].outputs.containerAppsEnvironmentId
      //appConfigurationUserAssignedIdentityId: supportingServices[i].outputs.appConfigurationUserAssignedIdentityId
      storageRG: parSpokeNetworks[i].rgStorage
      appConfigURL: supportingServices[i].outputs.appConfigURL
      appConfigIdentityClientID: supportingServices[i].outputs.appConfigIdentityClientID
      appInsightsConnectionString: parSpokeNetworks[i].appInsightsConnectionString
      containerRegistryLoginServer: supportingServices[i].outputs.containerRegistryLoginServer
      containerAppName: 'questionsetservice'
      containerImageTag: '${supportingServices[i].outputs.containerRegistryLoginServer}/${parQuestionSetContainerImageTag}'
      containerImageName: 'questionsetservice'
      configStoreName: sharedServicesNaming[i].outputs.resourcesNames.azureappconfigurationstore
      webAppURLConfigKey: 'AppSettings:QuestionSetServiceUri'
      sharedservicesRG: parSpokeNetworks[i].rgSharedServices
      userAssignedIdentities: [
        supportingServices[i].outputs.appConfigurationUserAssignedIdentityId
        supportingServices[i].outputs.containerRegistryUserAssignedIdentityId
        databaseserver[i].outputs.outputsqlServerUAIID
      ]
    }
    dependsOn: [
      databaseserver
      irasserviceapp
      usermanagementapp
    ]
  }
]

module rtsserviceapp 'modules/06-container-app/deploy.container-app.bicep' = [
  for i in range(0, length(parSpokeNetworks)): {
    name: take('rtsserviceapp-${deployment().name}-deployment', 64)
    scope: resourceGroup(parSpokeNetworks[i].subscriptionId, parSpokeNetworks[i].rgapplications)
    params: {
      location: location
      tags: tags
      containerRegistryUserAssignedIdentityId: supportingServices[i].outputs.containerRegistryUserAssignedIdentityId
      sqlServerUserAssignedIdentityName: databaseserver[i].outputs.outputsqlServerUAIName
      containerAppsEnvironmentId: containerAppsEnvironment[i].outputs.containerAppsEnvironmentId
      //appConfigurationUserAssignedIdentityId: supportingServices[i].outputs.appConfigurationUserAssignedIdentityId
      storageRG: parSpokeNetworks[i].rgStorage
      appConfigURL: supportingServices[i].outputs.appConfigURL
      appConfigIdentityClientID: supportingServices[i].outputs.appConfigIdentityClientID
      appInsightsConnectionString: parSpokeNetworks[i].appInsightsConnectionString
      containerRegistryLoginServer: supportingServices[i].outputs.containerRegistryLoginServer
      containerAppName: 'rtsservice'
      containerImageTag: '${supportingServices[i].outputs.containerRegistryLoginServer}/${parRtsContainerImageTag}'
      containerImageName: 'rtsservice'
      configStoreName: sharedServicesNaming[i].outputs.resourcesNames.azureappconfigurationstore
      webAppURLConfigKey: 'AppSettings:RtsServiceUri'
      sharedservicesRG: parSpokeNetworks[i].rgSharedServices
      userAssignedIdentities: [
        supportingServices[i].outputs.appConfigurationUserAssignedIdentityId
        supportingServices[i].outputs.containerRegistryUserAssignedIdentityId
        databaseserver[i].outputs.outputsqlServerUAIID
      ]
    }
    dependsOn: [
      databaseserver
      irasserviceapp
      usermanagementapp
      questionsetapp
    ]
  }
]

module webApp 'modules/07-app-service/deploy.app-service.bicep' = [
  for i in range(0, length(parSpokeNetworks)): {
    scope: resourceGroup(parSpokeNetworks[i].subscriptionId, parSpokeNetworks[i].rgapplications)
    name: take('webApp-${deployment().name}-deployment', 64)
    params: {
      tags: {}
      sku: 'B1'
      logAnalyticsWsId: logAnalyticsWorkspaceId
      location: location
      appServicePlanName: applicationServicesNaming[i].outputs.resourcesNames.appServicePlan
      appName: 'irasportal-${parSpokeNetworks[i].parEnvironment}'
      webAppBaseOs: 'Linux'
      subnetIdForVnetInjection: webAppSubnet[i].id // spoke[i].outputs.spokeWebAppSubnetId
      deploySlot: parSpokeNetworks[i].deployWebAppSlot
      privateEndpointRG: parSpokeNetworks[i].rgNetworking
      spokeVNetId: existingVnet[i].id // spoke[i].outputs.spokeVNetId
      subnetPrivateEndpointSubnetId: pepSubnet[i].id // spoke[i].outputs.spokePepSubnetId
      kind: 'app'
      deployAppPrivateEndPoint: parEnableFrontDoorPrivateLink
      userAssignedIdentities: [
        supportingServices[i].outputs.appConfigurationUserAssignedIdentityId
      ]
      devOpsPublicIPAddress: parDevOpsPublicIPAddress
      isPrivate: parEnableFrontDoorPrivateLink
    }
  }
]

module umbracoCMS 'modules/07-app-service/deploy.app-service.bicep' = [
  for i in range(0, length(parSpokeNetworks)): {
    scope: resourceGroup(parSpokeNetworks[i].subscriptionId, parSpokeNetworks[i].rgapplications)
    name: take('cmsApp-${deployment().name}-deployment', 64)
    params: {
      tags: {}
      sku: 'B1'
      logAnalyticsWsId: logAnalyticsWorkspaceId
      location: location
      appServicePlanName: applicationServicesNaming[i].outputs.resourcesNames.appServicePlan
      appName: 'cmsportal-${parSpokeNetworks[i].parEnvironment}'
      webAppBaseOs: 'Linux'
      subnetIdForVnetInjection: webAppSubnet[i].id // spoke[i].outputs.spokeWebAppSubnetId
      deploySlot: parSpokeNetworks[i].deployWebAppSlot
      privateEndpointRG: parSpokeNetworks[i].rgNetworking
      spokeVNetId: existingVnet[i].id // spoke[i].outputs.spokeVNetId
      subnetPrivateEndpointSubnetId: pepSubnet[i].id // spoke[i].outputs.spokePepSubnetId
      kind: 'app'
      deployAppPrivateEndPoint: parEnableFrontDoorPrivateLink
      userAssignedIdentities: [
        supportingServices[i].outputs.appConfigurationUserAssignedIdentityId
      ]
      devOpsPublicIPAddress: parDevOpsPublicIPAddress
      isPrivate: parEnableFrontDoorPrivateLink
    }
  }
]

module rtsfnApp 'modules/07-app-service/deploy.app-service.bicep' = [
  for i in range(0, length(parSpokeNetworks)): {
    scope: resourceGroup(parSpokeNetworks[i].subscriptionId, parSpokeNetworks[i].rgapplications)
    name: take('rtsfnApp-${deployment().name}-deployment', 64)
    params: {
      tags: {}
      sku: 'B1'
      logAnalyticsWsId: logAnalyticsWorkspaceId
      location: location
      appServicePlanName: 'asp-rsp-fnsyncrtsApp-manualtest-uks'
      appName: 'func-rts-data-sync-${parSpokeNetworks[i].parEnvironment}'
      webAppBaseOs: 'Windows'
      subnetIdForVnetInjection: webAppSubnet[i].id // spoke[i].outputs.spokeWebAppSubnetId
      deploySlot: parSpokeNetworks[i].deployWebAppSlot
      privateEndpointRG: parSpokeNetworks[i].rgNetworking
      spokeVNetId: existingVnet[i].id // spoke[i].outputs.spokeVNetId
      subnetPrivateEndpointSubnetId: pepSubnet[i].id // spoke[i].outputs.spokePepSubnetId
      kind: 'functionapp'
      storageAccountName: 'strtssync${parSpokeNetworks[i].parEnvironment}'
      deployAppPrivateEndPoint: false
      userAssignedIdentities: [
        supportingServices[i].outputs.appConfigurationUserAssignedIdentityId
        databaseserver[i].outputs.outputsqlServerUAIID
      ]
      sqlDBManagedIdentityClientId: databaseserver[i].outputs.outputsqlServerUAIClientID
      devOpsPublicIPAddress: parDevOpsPublicIPAddress
      isPrivate: false
    }
    dependsOn: [
      webApp
    ]
  }
]

module fnNotifyApp 'modules/07-app-service/deploy.app-service.bicep' = [
  for i in range(0, length(parSpokeNetworks)): {
    scope: resourceGroup(parSpokeNetworks[i].subscriptionId, parSpokeNetworks[i].rgapplications)
    name: take('fnNotifyApp-${deployment().name}-deployment', 64)
    params: {
      tags: {}
      sku: 'B1'
      logAnalyticsWsId: logAnalyticsWorkspaceId
      location: location
      appServicePlanName: 'asp-rsp-fnNotifyApp-manualtest-uks'
      appName: 'func-notify-${parSpokeNetworks[i].parEnvironment}'
      webAppBaseOs: 'Windows'
      subnetIdForVnetInjection: webAppSubnet[i].id // spoke[i].outputs.spokeWebAppSubnetId
      deploySlot: parSpokeNetworks[i].deployWebAppSlot
      privateEndpointRG: parSpokeNetworks[i].rgNetworking
      spokeVNetId: existingVnet[i].id // spoke[i].outputs.spokeVNetId
      subnetPrivateEndpointSubnetId: pepSubnet[i].id // spoke[i].outputs.spokePepSubnetId
      kind: 'functionapp'
      storageAccountName: 'stfnnotify${parSpokeNetworks[i].parEnvironment}'
      deployAppPrivateEndPoint: false
      userAssignedIdentities: [
        supportingServices[i].outputs.appConfigurationUserAssignedIdentityId
        // supportingServices[i].outputs.serviceBusReceiverManagedIdentityID
      ]
      devOpsPublicIPAddress: parDevOpsPublicIPAddress
      isPrivate: false
    }
    dependsOn: [
      rtsfnApp
    ]
  }
]

module frontDoor 'modules/10-front-door/deploy.front-door.bicep' = [
  for i in range(0, length(parSpokeNetworks)): if (parEnableFrontDoor) {
    scope: resourceGroup(parSpokeNetworks[i].subscriptionId, parSpokeNetworks[i].rgapplications)
    name: take('frontDoor-${deployment().name}-deployment', 64)
    params: {
      location: location
      tags: tags
      resourcesNames: applicationServicesNaming[i].outputs.resourcesNames
      originHostName: webApp[i].outputs.appHostName
      webAppName: 'irasportal-${parSpokeNetworks[i].parEnvironment}'
      enableWaf: true
      wafMode: parFrontDoorWafMode
      enableRateLimiting: parEnableFrontDoorRateLimiting
      rateLimitThreshold: parFrontDoorRateLimitThreshold
      customDomains: parFrontDoorCustomDomains
      enableCaching: parEnableFrontDoorCaching
      cacheDuration: parFrontDoorCacheDuration
      enableHttpsRedirect: parEnableFrontDoorHttpsRedirect
      enableManagedTls: true
      webAppResourceId: webApp[i].outputs.webAppResourceId
      enablePrivateLink: parEnableFrontDoorPrivateLink
    }
    dependsOn: [
      webApp
    ]
  }
]

module fnDocumentApiApp 'modules/07-app-service/deploy.app-service.bicep' = [
  for i in range(0, length(parSpokeNetworks)): {
    scope: resourceGroup(parSpokeNetworks[i].subscriptionId, parSpokeNetworks[i].rgapplications)
    name: take('fnDocumentApiApp-${deployment().name}-deployment', 64)
    params: {
      tags: {}
      sku: 'B1'
      logAnalyticsWsId: logAnalyticsWorkspaceId
      location: location
      appServicePlanName: 'asp-rsp-fnDocApi-${parSpokeNetworks[i].parEnvironment}-uks'
      appName: 'func-documentapi-${parSpokeNetworks[i].parEnvironment}'
      webAppBaseOs: 'Windows'
      subnetIdForVnetInjection: webAppSubnet[i].id
      deploySlot: parSpokeNetworks[i].deployWebAppSlot
      privateEndpointRG: parSpokeNetworks[i].rgNetworking
      spokeVNetId: existingVnet[i].id
      subnetPrivateEndpointSubnetId: pepSubnet[i].id
      kind: 'functionapp'
      storageAccountName: 'stdocapi${parSpokeNetworks[i].parEnvironment}'
      deployAppPrivateEndPoint: false
      userAssignedIdentities: [
        supportingServices[i].outputs.appConfigurationUserAssignedIdentityId
        databaseserver[i].outputs.outputsqlServerUAIID
      ]
      sqlDBManagedIdentityClientId: databaseserver[i].outputs.outputsqlServerUAIClientID
      devOpsPublicIPAddress: parDevOpsPublicIPAddress
      isPrivate: false
    }
    dependsOn: [
      fnNotifyApp
      databaseserver
    ]
  }
]
