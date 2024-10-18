targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------

@description('The location where the resources will be created. This needs to be the same region as the Azure Container Apps instances.')
param location string = resourceGroup().location

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

@description('Optional. The name of the Container App. If set, it overrides the name generated by the template.')
@minLength(2)
@maxLength(32)
param containerAppName string

@description('The resource ID of the existing Container Apps environment in which the Container App will be deployed.')
param containerAppsEnvironmentId string

param sqlServerUserAssignedIdentityName string = ''
param containerRegistryUserAssignedIdentityId string = ''
param appConfigurationUserAssignedIdentityId string = ''
param storageRG string
param appConfigURL string
param appConfigIdentityClientID string
param containerRegistryLoginServer string
param containertag string

param configStoreName string
param webAppURLConfigKey string
param sharedservicesRG string

// @description('Name of the container registry from which Container App to pull images')
// param acrName string

// ------------------
// RESOURCES
// ------------------

// resource registry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
//   name: acrName
// }

resource sqlServerUserAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: sqlServerUserAssignedIdentityName
  scope: resourceGroup(storageRG)
}

resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: containerAppName
  location: location
  tags: tags
  identity: { 
    type: 'UserAssigned'
    userAssignedIdentities: {
        '${sqlServerUserAssignedIdentity.id}': {}
        '${containerRegistryUserAssignedIdentityId}': {}
        '${appConfigurationUserAssignedIdentityId}': {}
    }
  }
  properties: {
    configuration: {
      activeRevisionsMode: 'single'
      ingress: {
        allowInsecure: false
        external: true
        targetPort: 8080
        transport: 'auto'
        stickySessions: {
          affinity: 'none'
        }
      }
      registries: [
        {
          server: containerRegistryLoginServer
          identity: containerRegistryUserAssignedIdentityId
        }
      ]
    }
    environmentId: containerAppsEnvironmentId
    workloadProfileName: 'Consumption'
    template: {
      containers: [
        {
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          name: 'simple-hello-world-container'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: [
            {
              name: 'AZURE_CLIENT_ID'
              value: sqlServerUserAssignedIdentity.properties.clientId
            }
            {
              name: 'AZURE_TENANT_ID'
              value: tenant().tenantId
            }
            {
              name: 'AppSettings__AzureAppConfiguration__Endpoint'
              value: appConfigURL
            }
            {
              name: 'AppSettings__AzureAppConfiguration__IdentityClientID'
              value: appConfigIdentityClientID
            }
          ]
          probes: [
            {
              failureThreshold: 3
              httpGet: {
                path: '/probes/liveness'
                port: 8080
                scheme: 'http'
              }
              initialDelaySeconds: 10
              periodSeconds: 10
              successThreshold: 1
              timeoutSeconds: 1
              type: 'Liveness'
            }
            {
              failureThreshold: 3
              httpGet: {
                path: '/probes/readiness'
                port: 8080
                scheme: 'http'
              }
              initialDelaySeconds: 10
              periodSeconds: 10
              successThreshold: 1
              timeoutSeconds: 1
              type: 'readiness'
            }
            {
              failureThreshold: 3
              httpGet: {
                path: '/probes/startup'
                port: 8080
                scheme: 'http'
              }
              initialDelaySeconds: 10
              periodSeconds: 10
              successThreshold: 1
              timeoutSeconds: 1
              type: 'startup'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 10
      }
      volumes: []
    }
  }
}

module containerAppURLConfig '../../../shared/bicep/app-configuration/app-config-key-values.bicep' = {
  scope: resourceGroup(sharedservicesRG)
  name: take('containerAppURLConfig-${guid(resourceGroup().id)}-${uniqueString(resourceGroup().id)}',64)
  params: {
    configStoreName: configStoreName
    webAppURLConfigKey: webAppURLConfigKey
    webAppURLConfigValue: 'https://${containerApp.properties.configuration.ingress.fqdn}'
  }
}

// ------------------
// OUTPUTS
// ------------------

output containerAppFqdn string = containerApp.properties.configuration.ingress.fqdn
