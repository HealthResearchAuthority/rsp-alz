
@description('Required. Name of the App Service Plan.')
@minLength(1)
@maxLength(40)
param appServicePlanName string

@description('Required. Name of the web app.')
@maxLength(60)
param appName string 

@description('Optional S1 is default. Defines the name, tier, size, family and capacity of the App Service Plan. Plans ending to _AZ, are deploying at least three instances in three Availability Zones. EP* is only for functions. WS1 is for Logic Apps Standard.')
@allowed([ 'B1','B3','S1', 'S2', 'S3', 'P1V3', 'P2V3', 'P3V3', 'P1V3_AZ', 'P2V3_AZ', 'P3V3_AZ', 'EP1', 'EP2', 'EP3', 'ASE_I1V2_AZ', 'ASE_I2V2_AZ', 'ASE_I3V2_AZ', 'ASE_I1V2', 'ASE_I2V2', 'ASE_I3V2', 'WS1' ])
param sku string

@description('Optional. Location for all resources.')
param location string

@description('Resource tags that we might need to add to all resources (i.e. Environment, Cost center, application name etc)')
param tags object

@description('Optional. The IP ACL rules. Note, requires the \'acrSku\' to be \'Premium\'.')
param paramWhitelistIPs string = ''

param subnetPrivateEndpointSubnetId string

@description('Resource Group where PEP and PEP DNS needs to be deployed')
param privateEndpointRG string

@description('The resource ID of the VNet to which the private endpoint will be connected.')
param spokeVNetId string

@description('Kind of server OS of the App Service Plan')
@allowed([ 'Windows', 'Linux'])
param webAppBaseOs string

@description('An existing Log Analytics WS Id for creating app Insights, diagnostics etc.')
param logAnalyticsWsId string

@description('The subnet ID that is dedicated to Web Server, for Vnet Injection of the web app. If deployAseV3=true then this is the subnet dedicated to the ASE v3')
param subnetIdForVnetInjection string

@description('Name of the storage account if deploying Function App or Logic App')
@maxLength(24)
param storageAccountName string = ''

@description('Webapp, functionapp, or logicapp')
@allowed(['functionapp','app','logicapp'])
param kind string

@description('Client ID of the managed identity to be used for the SQL DB connection string. For Function App Only')
param sqlDBManagedIdentityClientId string = ''

param deploySlot bool

param deployAppPrivateEndPoint bool
param userAssignedIdentities array
param eventGridServiceTagRestriction bool = false

// Logic App workflow-specific parameters (only used when kind == 'logicapp')
@description('SQL query to execute (Logic App only)')
param sqlQuery string = ''

@description('SharePoint site URL (Logic App only)')
param sharePointSiteUrl string = ''

@description('SharePoint folder path (Logic App only)')
param sharePointFolderPath string = ''

@description('Time zone for schedule. Example: GMT Standard Time (Logic App only)')
param scheduleTimeZone string = 'GMT Standard Time'

@description('Daily schedule time (HH:mm, 24h) (Logic App only)')
param scheduleTime string = '08:00'

@description('Optional filename/environment prefix for CSV output, e.g. "dev-" (Logic App only)')
param envPrefix string = ''


var slotName = 'staging'

var varWhitelistIPs = filter(split(paramWhitelistIPs, ','), ip => !empty(trim(ip)))
var contentShareName = (kind == 'functionapp' || kind == 'logicapp') ? take(replace(toLower('${appName}-content'), '_', '-'), 63) : ''
var storageAccountSanitized = toLower(replace(storageAccountName, '-', ''))
var storageAccountResourceName = length(storageAccountSanitized) > 24 ? substring(storageAccountSanitized, 0, 24) : storageAccountSanitized

var spokeVNetIdTokens = split(spokeVNetId, '/')
var spokeSubscriptionId = spokeVNetIdTokens[2]
var spokeResourceGroupName = spokeVNetIdTokens[4]
var spokeVNetName = spokeVNetIdTokens[8]
var networkAcls = deployAppPrivateEndPoint ? {
  defaultAction: 'Deny'
  bypass: 'AzureServices'
  virtualNetworkRules: [
    {
      id: subnetIdForVnetInjection
      action: 'Allow'
    }
  ]
} : {
  defaultAction: 'Allow'
  bypass: 'AzureServices'
}

module appInsights '../../../shared/bicep/app-insights.bicep' = {
  name: take('${appName}-appInsights-Deployment', 64)
  params: {
    name: 'appi-${appName}'
    location: location
    tags: tags
    workspaceResourceId: logAnalyticsWsId
  }
}

module appSvcPlan '../../../shared/bicep/app-services/app-service-plan.bicep' = {
  name: take('appSvcPlan-${appServicePlanName}-Deployment', 64) 
  params: {
    name: appServicePlanName
    location: location
    tags: tags
    sku: sku
    serverOS: (webAppBaseOs =~ 'linux') ? 'Linux' : 'Windows'
    diagnosticWorkspaceId: logAnalyticsWsId
  }
}

module webApp '../../../shared/bicep/app-services/web-app.bicep' = if(kind == 'app') {
  name: take('${appName}-webApp-Deployment', 64)
  params: {
    kind: (webAppBaseOs =~ 'linux') ? 'app,linux' : 'app'
    name:  appName
    location: location
    serverFarmResourceId: appSvcPlan.outputs.resourceId
    diagnosticWorkspaceId: logAnalyticsWsId   
    virtualNetworkSubnetId: subnetIdForVnetInjection
    appInsightId: appInsights.outputs.appInsResourceId
    operatingSystem:  (webAppBaseOs =~ 'linux') ? 'linuxNet9' : 'windowsNet9'
    hasPrivateLink: deployAppPrivateEndPoint
    systemAssignedIdentity: false
    userAssignedIdentities:  {
      type: 'UserAssigned'
      userAssignedIdentities: reduce(userAssignedIdentities, {}, (result, id) => union(result, { '${id}': {} }))
    }
    slots: deploySlot ? [
      {
        name: slotName
      }
    ] : []
    networkRuleSetIpRules: [for (ip, index) in varWhitelistIPs: {
        ipAddress: contains(ip, '/') ? ip : '${ip}/32'
        action: 'Allow'
        name: 'Allow-IP-${index + 1}'
        priority: 100 + index
      }]
  }
}

module fnstorage '../../../shared/bicep/storage/storage.bicep' = if(kind == 'functionapp' || kind == 'logicapp') {
  name: take('fnAppStoragePrivateNetwork-${deployment().name}', 64)
  params: {
    name: storageAccountName
    location: location
    sku: 'Standard_LRS'
    kind: 'StorageV2'
    supportsHttpsTrafficOnly: true
    tags: {}
    networkAcls: networkAcls 
  }
}

resource storageFileService 'Microsoft.Storage/storageAccounts/fileServices@2022-09-01' = if(kind == 'functionapp' || kind == 'logicapp') {
  name: '${storageAccountResourceName}/default'
  dependsOn: [
    fnstorage
  ]
}

resource storageContentShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = if((kind == 'functionapp' || kind == 'logicapp') && !empty(contentShareName)) {
  parent: storageFileService
  name: contentShareName
  properties: {
    enabledProtocols: 'SMB'
    shareQuota: 10240
  }
}

module storageBlobPrivateNetwork '../../../shared/bicep/network/private-networking-spoke.bicep' = if((kind == 'functionapp' || kind == 'logicapp') && deployAppPrivateEndPoint == true) {
  name:take('rtsfnStorageBlobPrivateNetwork-${deployment().name}', 64)
  scope: resourceGroup(privateEndpointRG)
  params: {
    location: location
    azServicePrivateDnsZoneName: 'privatelink.blob.${environment().suffixes.storage}'
    azServiceId: fnstorage!.outputs.id
    privateEndpointName: take('pep-${storageAccountName}-blob', 64)
    privateEndpointSubResourceName: 'blob'
    virtualNetworkLinks: [
      {
        vnetName: spokeVNetName
        vnetId: vnetSpoke.id
        registrationEnabled: false
      }
    ]
    subnetId: subnetPrivateEndpointSubnetId
    //vnetSpokeResourceId: spokeVNetId
  }
}

module storageFilesPrivateNetwork '../../../shared/bicep/network/private-networking-spoke.bicep' = if((kind == 'functionapp' || kind == 'logicapp') && deployAppPrivateEndPoint == true) {
  name:take('fnStorageFilePrivateNetwork-${storageAccountName}', 64)
  scope: resourceGroup(privateEndpointRG)
  params: {
    location: location
    azServicePrivateDnsZoneName: 'privatelink.file.${environment().suffixes.storage}'
    azServiceId: fnstorage!.outputs.id
    privateEndpointName: take('pep-${storageAccountName}-file', 64)
    privateEndpointSubResourceName: 'file'
    virtualNetworkLinks: [
      {
        vnetName: spokeVNetName
        vnetId: vnetSpoke.id
        registrationEnabled: false
      }
    ]
    subnetId: subnetPrivateEndpointSubnetId
  }
  dependsOn: [
    storageBlobPrivateNetwork
  ]
}

module fnApp '../../../shared/bicep/app-services/function-app.bicep' = if(kind == 'functionapp' || kind == 'logicapp') {
  name: take('${appName}-webApp-Deployment', 64)
  params: {
    kind: kind == 'logicapp' ? 'functionapp,workflowapp' : 'functionapp'
    functionAppName:  appName
    location: location
    serverFarmResourceId: appSvcPlan.outputs.resourceId
    //diagnosticWorkspaceId: logAnalyticsWsId
    virtualNetworkSubnetId: subnetIdForVnetInjection
    appInsightId: appInsights.outputs.appInsResourceId
    userAssignedIdentities:  {
      type: 'UserAssigned'
      userAssignedIdentities: reduce(userAssignedIdentities, {}, (result, id) => union(result, { '${id}': {} }))
    }
    storageAccountName: storageAccountName
    contentShareName: contentShareName
    hasPrivateEndpoint: deployAppPrivateEndPoint
    sqlDBManagedIdentityClientId: sqlDBManagedIdentityClientId
    eventGridServiceTagRestriction: eventGridServiceTagRestriction
  }
  dependsOn: [
    fnstorage
  ]
}

resource vnetSpoke 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  scope: resourceGroup(spokeSubscriptionId, spokeResourceGroupName)
  name: spokeVNetName
}

// Private endpoint for App Service/Function App/Logic App using existing private-networking-spoke module
module appServicePrivateEndpoint '../../../shared/bicep/network/private-networking-spoke.bicep' = if(deployAppPrivateEndPoint) {
  name: take('appServicePrivateEndpoint-${deployment().name}', 64)
  scope: resourceGroup(privateEndpointRG)
  params: {
    location: location
    azServicePrivateDnsZoneName: 'privatelink.azurewebsites.net'
    azServiceId: kind == 'app' ? webApp!.outputs.resourceId : fnApp!.outputs.functionAppId
    privateEndpointName: kind == 'app' ? take('pep-${webApp!.outputs.name}', 64) : take('pep-${fnApp!.outputs.functionAppName}', 64)
    privateEndpointSubResourceName: 'sites'
    virtualNetworkLinks: [
      {
        vnetName: spokeVNetName
        vnetId: vnetSpoke.id
        registrationEnabled: false
      }
    ]
    subnetId: subnetPrivateEndpointSubnetId
    //vnetSpokeResourceId: spokeVNetId
  }
}

// Logic App workflow resource (only for logicapp kind)
// IMPORTANT: This workflow references connections by name ('sql' and 'sharepointonline').
// Connections are NOT created or deleted by this deployment - they are separate resources.
// Connections created in the portal will persist across deployments and will NOT be overwritten.
resource workflow 'Microsoft.Web/sites/workflows@2022-09-01' = if(kind == 'logicapp' && !empty(sqlQuery)) {
  name: '${appName}/daily-csv-export'
  properties: {
    stateType: 'Stateful'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      triggers: {
        Recurrence: {
          type: 'Recurrence'
          recurrence: {
            interval: 1
            frequency: 'Day'
            timeZone: scheduleTimeZone
            schedule: {
              hours: [int(split(scheduleTime, ':')[0])]
              minutes: [int(split(scheduleTime, ':')[1])]
            }
          }
        }
      }
      actions: {
        Execute_query: {
          type: 'ServiceProvider'
          inputs: {
            parameters: {
              query: sqlQuery
            }
            serviceProviderConfiguration: {
              connectionName: 'sql'
              operationId: 'executeQuery'
              serviceProviderId: '/serviceProviders/sql'
            }
          }
          runAfter: {}
        }
        Create_CSV_table: {
          type: 'Table'
          inputs: {
            from: '@first(body(\'Execute_query\'))'
            format: 'CSV'
          }
          runAfter: {
            Execute_query: ['SUCCEEDED']
          }
        }
        Initialize_variables: {
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'FileName'
                type: 'string'
                value: '@{concat(\'${envPrefix}Tactical_Report_\', formatDateTime(utcNow(), \'dd-MM-yyyy\'), \'.csv\')}'
              }
            ]
          }
          runAfter: {
            Create_CSV_table: ['SUCCEEDED']
          }
        }
        Create_file: {
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                referenceName: 'sharepointonline'
              }
            }
            method: 'post'
            body: '@body(\'Create_CSV_table\')'
            path: '/datasets/@{encodeURIComponent(encodeURIComponent(\'${sharePointSiteUrl}\'))}/files'
            queries: {
              folderPath: sharePointFolderPath
              name: '@variables(\'FileName\')'
              queryParametersSingleEncoded: true
            }
          }
          runAfter: {
            Initialize_variables: ['SUCCEEDED']
          }
          runtimeConfiguration: {
            contentTransfer: {
              transferMode: 'Chunked'
            }
          }
        }
      }
      outputs: {}
    }
  }
  dependsOn: [
    fnApp
  ]
}

output appName string = appName
output appHostName string = (kind == 'app') ? webApp!.outputs.defaultHostname: fnApp!.outputs.defaultHostName
output webAppResourceId string = (kind == 'app') ? webApp!.outputs.resourceId : fnApp!.outputs.functionAppId
output systemAssignedPrincipalId string = (kind == 'app') ? webApp!.outputs.systemAssignedPrincipalId : fnApp!.outputs.systemAssignedPrincipalId
output appInsightsResourceId string = appInsights.outputs.appInsResourceId
output logicAppName string = kind == 'logicapp' ? fnApp!.outputs.functionAppName : ''
output logicAppId string = kind == 'logicapp' ? fnApp!.outputs.functionAppId : ''





