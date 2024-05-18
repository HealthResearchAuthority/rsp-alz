targetScope = 'resourceGroup'

metadata name = 'ALZ Bicep - Container App Module'
metadata description = 'ALZ Bicep Module to configure Container App'

@sys.description('Prefix used for the management group hierarchy. This management group will be created as part of the deployment.')
param parlocation string = ''

@sys.description('Name of the environment')
param parEnvironment string = ''

@sys.description('list of registries')
param parRegistries []

@sys.description('list of containers')
param parContainers []

// @sys.description('Name of the Log Analyticws workspace')
// var logAnalyticsWorkspaceName = 'hra-rsp-log-analytics'

resource environment 'Microsoft.App/managedEnvironments@2023-11-02-preview' = {
  name: 'cae-rsp-${parEnvironment}'
  location: parlocation
  properties: {}
  // properties: {
  //   appLogsConfiguration: {
  //     destination: 'log-analytics'
  //     logAnalyticsConfiguration: {
  //       customerId: logAnalyticWorkspace.list().properties.customerId
  //       sharedKey: logAnalyticWorkspace.listKeys().primarySharedKey
  //     }
  //   }
  // }
}

resource containerapp 'Microsoft.App/containerApps@2023-11-02-preview' = {
  name: 'ca-rsp-applicationservice-${parEnvironment}'
  location: parlocation
  properties: {
    environmentId: environment.id
    configuration: {
      registries: parRegistries
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 80
      }
    }
    template: {
      containers: parContainers
      scale: {
        minReplicas: 0
      }
    }
  }
}

// resource logAnalyticWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
//   name: logAnalyticsWorkspaceName
//   scope: resourceGroup('rg-hra-operationsmanagement')
// }
