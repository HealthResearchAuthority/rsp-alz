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
  containerName: 'document-uploads'
  sku: 'Standard_LRS'
  accessTier: 'Hot'
  allowPublicAccess: false
}

@description('Microsoft Defender for Storage configuration')
param parDefenderForStorageConfig object = {
  enabled: true
  enableMalwareScanning: true
  enableSensitiveDataDiscovery: true
  malwareScanningCapGBPerMonth: 1000
}

// ------------------
// VARIABLES
// ------------------

var sqlServerNamePrefix = 'rspsqlserver'


// ------------------
// RESOURCES
// ------------------

module defenderStorage '../shared/bicep/security/defender-storage.bicep' = if (parDefenderForStorageConfig.enabled) {
  name: take('defenderStorage-${deployment().name}', 64)
  scope: subscription()
  params: {
    enableDefenderForStorage: parDefenderForStorageConfig.enabled
    enableMalwareScanning: parDefenderForStorageConfig.enableMalwareScanning
    enableSensitiveDataDiscovery: parDefenderForStorageConfig.enableSensitiveDataDiscovery
    malwareScanningCapGBPerMonth: parDefenderForStorageConfig.malwareScanningCapGBPerMonth
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
      functionAppName: 'func-process-scan-${parSpokeNetworks[i].parEnvironment}'
      location: location
      tags: tags
      storageAccountName: 'stprocessscan${parSpokeNetworks[i].parEnvironment}'
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
      enableMalwareScanning: parDefenderForStorageConfig.enableMalwareScanning
      customEventGridTopicId: '' // Optional: Add custom Event Grid topic ID for additional automation
      logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
      enableEventGridIntegration: true
      processScanWebhookEndpoint: processScanFnApp[i].outputs.webhookEndpoint
    }
    dependsOn: [
      defenderStorage
      storageRG
      processScanFnApp
    ]
  }
]

// Note: Function App permissions will be configured once system assigned identity is available
// Configure process scan Function App permissions after document upload storage is created
// module processScanFnAppPermissions '../shared/bicep/role-assignments/process-scan-function-permissions.bicep' = [
//   for i in range(0, length(parSpokeNetworks)): {
//     scope: resourceGroup(parSpokeNetworks[i].subscriptionId, parSpokeNetworks[i].rgStorage)
//     name: take('processScanFnAppPermissions-${deployment().name}-deployment', 64)
//     params: {
//       functionAppPrincipalId: processScanFnApp[i].outputs.systemAssignedPrincipalId
//       documentUploadStorageAccountId: documentUpload[i].outputs.storageAccountId
//     }
//     dependsOn: [
//       processScanFnApp
//       documentUpload
//     ]
//   }
// ]

module databaseserver 'modules/05-database/deploy.database.bicep' = [
  for i in range(0, length(parSpokeNetworks)): {
    name: take('database-${deployment().name}-deployment', 64)
    scope: resourceGroup(parSpokeNetworks[i].subscriptionId, parSpokeNetworks[i].rgStorage)
    params: {
      location: location
      sqlServerName: '${sqlServerNamePrefix}${parSpokeNetworks[i].parEnvironment}'
      adminLogin: parAdminLogin
      adminPassword: parSqlAdminPhrase
      databases: ['applicationservice', 'identityservice', 'questionsetservice', 'rtsservice']
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
      deployAppPrivateEndPoint: false
      userAssignedIdentities: [
        supportingServices[i].outputs.appConfigurationUserAssignedIdentityId
      ]
      devOpsPublicIPAddress: parDevOpsPublicIPAddress
      isPrivate: false
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


// module applicationGateway 'modules/08-application-gateway/deploy.app-gateway.bicep' = [for i in range(0, length(parSpokeNetworks)): {
//   name: take('applicationGateway-${deployment().name}-deployment', 64)
//   scope: resourceGroup(parSpokeNetworks[i].subscriptionId, parSpokeNetworks[i].rgNetworking)
//   params: {
//     location: location
//     tags: tags
//     applicationGatewayCertificateKeyName: applicationGatewayCertificateKeyName
//     applicationGatewayFqdn: applicationGatewayFqdn
//     applicationGatewayPrimaryBackendEndFqdn: webApp[i].outputs.appHostName
//     applicationGatewaySubnetId: agwSubnet[i].id  // spoke[i].outputs.spokeApplicationGatewaySubnetId
//     enableApplicationGatewayCertificate: enableApplicationGatewayCertificate
//     keyVaultId: supportingServices[i].outputs.keyVaultId
//     deployZoneRedundantResources: parSpokeNetworks[i].zoneRedundancy
//     ddosProtectionMode: 'Disabled'
//     applicationGatewayLogAnalyticsId: logAnalyticsWorkspaceId
//     networkingResourceNames: networkingnaming[i].outputs.resourcesNames
//   }
// }]

//output inputdevopsIP string = parDevOpsPublicIPAddress
