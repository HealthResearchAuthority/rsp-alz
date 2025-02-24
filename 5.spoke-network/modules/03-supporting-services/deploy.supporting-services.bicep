targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------

@description('The location where the resources will be created. This needs to be the same region as the spoke.')
param location string = resourceGroup().location

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

// Spoke
@description('The resource ID of the existing spoke virtual network to which the private endpoint will be connected.')
param spokeVNetId string

@description('The name of the existing subnet in the spoke virtual to which the private endpoint will be connected.')
param spokePrivateEndpointSubnetName string

@description('Optional. Resource ID of the diagnostic log analytics workspace. If left empty, no diagnostics settings will be defined.')
param logAnalyticsWorkspaceId string = ''

param deployZoneRedundantResources bool = true

@description('Optional, default value is true. If true, any resources that support AZ will be deployed in all three AZ. However if the selected region is not supporting AZ, this parameter needs to be set to false.')
param containerRegistryTier string = ''

param privateDNSEnabled bool = false

param resourcesNames object
param sqlServerName string
param networkingResourcesNames object
param networkingResourceGroup string
param jwksURI string

@description('Environment Value for IDG Authentication URL')
param IDGENV string

@description('Client ID for IDG Authentication')
param clientID string

@secure()
@description('Client secret for IDG Authentication')
param clientSecret string

// ------------------
// Varaibles
// ------------------

var keyVaultPrivateDnsZoneName = 'privatelink.vaultcore.azure.net'

// ------------------
// RESOURCES
// ------------------

@description('Azure Container Registry, where all workload images should be pulled from.')
module containerRegistry './modules/container-registry.module.bicep' = {
  name: 'containerRegistry-rsp-${uniqueString(resourceGroup().id)}'
  params: {
    containerRegistryName: resourcesNames.containerRegistry
    location: location
    tags: tags
    spokeVNetId: spokeVNetId
    acrTier: containerRegistryTier
    spokePrivateEndpointSubnetName: spokePrivateEndpointSubnetName
    containerRegistryPrivateEndpointName: resourcesNames.containerRegistryPep
    containerRegistryUserAssignedIdentityName: resourcesNames.containerRegistryUserAssignedIdentity
    diagnosticWorkspaceId: logAnalyticsWorkspaceId
    deployZoneRedundantResources: deployZoneRedundantResources
  }
}

@description('Azure Key Vault used to hold items like TLS certs and application secrets that your workload will need.')
module keyVault './modules/key-vault.bicep' = {
  name: 'keyVault-${uniqueString(resourceGroup().id)}'
  params: {
    keyVaultName: resourcesNames.keyVault
    location: location
    tags: tags
    spokeVNetId: spokeVNetId
    spokePrivateEndpointSubnetName: spokePrivateEndpointSubnetName
    keyVaultPrivateEndpointName: resourcesNames.keyVaultPep
    diagnosticWorkspaceId: logAnalyticsWorkspaceId
    privateDNSEnabled: privateDNSEnabled
    privateDnsZoneName: keyVaultPrivateDnsZoneName
    keyVaultUserAssignedIdentityName: resourcesNames.keyVaultUserAssignedIdentity
  }
}

@description('Azure App configuration to hold information required at the application for various environments')
module appConfiguration './modules/app-configuration.bicep' = {
  name: 'appConfiguration-${uniqueString(resourceGroup().id)}'
  scope: resourceGroup(resourceGroup().name)
  params: {
    location: location
    tags: tags
    configStoreName: resourcesNames.azureappconfigurationstore
    appConfigurationUserUserAssignedIdentityName: resourcesNames.azureappconfigurationstoreUserAssignedIdentity
    sqlServerName: sqlServerName
    networkingResourcesNames: networkingResourcesNames
    networkingResourceGroup: networkingResourceGroup
    spokeVNetId: spokeVNetId
    spokePrivateEndpointSubnetName: spokePrivateEndpointSubnetName
    jwksURI: jwksURI
    IDGENV: IDGENV
    clientID: clientID
    clientSecret: clientSecret
  }
}

module serviceBus './modules/service-bus.module.bicep' = {
  name: 'serviceBus-${uniqueString(resourceGroup().id)}'
  params: {
    serviceBusNamespaceName: resourcesNames.serviceBus
    serviceBusPrivateEndpointName: resourcesNames.serviceBusPep
    serviceBusReceiverUserAssignedIdentityName: resourcesNames.serviceBusReceiverUserAssignedIdentity
    serviceBusSenderUserAssignedIdentityName: resourcesNames.serviceBusSenderUserAssignedIdentity
    spokePrivateEndpointSubnetName: spokePrivateEndpointSubnetName
    spokeVNetId: spokeVNetId
    diagnosticWorkspaceId: logAnalyticsWorkspaceId
  }
}

// ------------------
// OUTPUTS
// ------------------

@description('The resource ID of the Azure Container Registry.')
output containerRegistryId string = containerRegistry.outputs.containerRegistryId

@description('The name of the Azure Container Registry.')
output containerRegistryName string = containerRegistry.outputs.containerRegistryName

@description('The name of the container registry login server.')
output containerRegistryLoginServer string = containerRegistry.outputs.containerRegistryLoginServer

 @description('The resource ID of the user-assigned managed identity for the Azure Container Registry to be able to pull images from it.')
 output containerRegistryUserAssignedIdentityId string = containerRegistry.outputs.containerRegistryUserAssignedIdentityId

@description('The resource ID of the Azure Key Vault.')
output keyVaultId string = keyVault.outputs.keyVaultId

@description('The name of the Azure Key Vault.')
output keyVaultName string = keyVault.outputs.keyVaultName

@description('The resource ID of the user assigned managed identity for the App Configuration to be able to read configurations from it.')
 output appConfigurationUserAssignedIdentityId string = appConfiguration.outputs.appConfigurationUserAssignedIdentityId

@description('The resource ID of the user assigned managed identity for the Key Vault to be able to read Secrets from it.')
output keyVaultUserAssignedIdentityId string = keyVault.outputs.keyVaultUserAssignedIdentityId

 output appConfigURL string = appConfiguration.outputs.appConfigURL
 output appConfigIdentityClientID string = appConfiguration.outputs.appConfigMIClientID
 output serviceBusReceiverManagedIdentityID string = serviceBus.outputs.serviceBusReceiverManagedIdentityId
 output serviceBusSenderManagedIdentity string = serviceBus.outputs.serviceBusSenderManagedIdentityId
