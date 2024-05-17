targetScope = 'resourceGroup'

metadata name = 'ALZ Bicep - Management Groups Module'
metadata description = 'ALZ Bicep Module to configure Container App'

@sys.description('Prefix used for the management group hierarchy. This management group will be created as part of the deployment.')
param parlocation string = ''

@sys.description('Name of the environment')
param parEnvironment string = ''

@sys.description('Name of the Log Analyticws workspace')
var logAnalyticsWorkspaceName = readEnvironmentVariable('LOG_ANALYTICS_WORKSPACE_NAME')

resource name_resource 'Microsoft.App/containerApps@2023-11-02-preview' = {
  name: 'ca-rsp-applicationservice-${parEnvironment}'
  location: parlocation
  properties: {
    environmentId: environment.id
    configuration: {
      registries: registries
      activeRevisionsMode: 'Single'
      ingress: ingress
    }
    template: {
      containers: containers
      scale: {
        minReplicas: 0
      }
    }
  }
  dependsOn: [
    environment
  ]
}

resource environment 'Microsoft.App/managedEnvironments@2023-11-02-preview' = {
  name: 'cae-rsp-${parEnvironment}'
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: reference('Microsoft.OperationalInsights/workspaces/${logAnalyticsWorkspaceName}', '2020-08-01').customerId
        sharedKey: listKeys('Microsoft.OperationalInsights/workspaces/${logAnalyticsWorkspaceName}', '2020-08-01').primarySharedKey
      }
    }
  }
  sku: {
    name: 'Consumption'
  }
}
