targetScope = 'resourceGroup'

metadata name = 'ALZ Bicep - Container App Module'
metadata description = 'ALZ Bicep Module to configure Container App'

@sys.description('Prefix used for the management group hierarchy. This management group will be created as part of the deployment.')
param parlocation string = ''

@sys.description('Name of the environment')
param parEnvironment string = ''

// @sys.description('Name of the Log Analyticws workspace')
var logAnalyticsWorkspaceName = 'hra-rsp-log-analytics'

resource logAnalyticWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsWorkspaceName
  scope: resourceGroup('8747cd7f-1a06-4fe4-9dbb-24f612b9dd5a','rg-hra-operationsmanagement')
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appin-ca-rsp-dev'
  location: parlocation
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId:logAnalyticWorkspace.id
  }
}

resource acrResource 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: 'acrrsp${parEnvironment}'
  location: parlocation
  sku: {
    name: 'standard'
  }
  properties: {
    adminUserEnabled: false
  }
}

// Create identtiy
resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview'  = {
  name: 'id-rsp-applicationservice-user-${parEnvironment}'
  location: parlocation
}

// Create role assignment
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: 'ra-rsp-containerapp-useridentity'
  scope: acrResource
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') //RoleID from: https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/containers#acrpull
    principalId: identity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

 resource environment 'Microsoft.App/managedEnvironments@2023-11-02-preview' = {
  name: 'cae-rsp-${parEnvironment}'
  location: parlocation
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticWorkspace.properties.customerId
        sharedKey: logAnalyticWorkspace.listKeys().primarySharedKey
      }
    }
  }
}

resource containerapp 'Microsoft.App/containerApps@2023-11-02-preview' = {
  dependsOn: [
    roleAssignment
  ]
  name: 'ca-rsp-applicationservice-${parEnvironment}'
  location: parlocation
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity.id}': {}
    }
  }
  properties: {
    environmentId: environment.id
    configuration: {
      registries: [ 
        {
          server: acrResource.properties.loginServer
          identity: identity.id
        }
      ]
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 80
      }
    }
    template: {
      containers: [
        {
          name: 'simple-hello-world-container'
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
        }
      ]
      scale: {
        minReplicas: 0
      }
    }
  }
}


