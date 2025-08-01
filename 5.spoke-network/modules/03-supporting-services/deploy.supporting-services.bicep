targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------

@description('The location where the resources will be created. This needs to be the same region as the spoke.')
param location string = resourceGroup().location

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

@description('DevOps Public IP Address')
param devOpsPublicIPAddress string

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

param privateDNSEnabled bool = true

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

@description('Token issuing authority for Gov UK One Login')
param oneLoginAuthority string

@secure()
@description('Private RSA key for signing the token')
param oneLoginPrivateKeyPem string

@description('ClientId for the registered service in Gov UK One Login')
param oneLoginClientId string

@description('Valid token issuers for Gov UK One Login')
param oneLoginIssuers array

param storageAccountName string
@secure()
@description('The key for the storage account where the blob connection string will be stored.')
param storageAccountKey string

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
    networkingResourceGroup: networkingResourceGroup
    spokePrivateEndpointSubnetName: spokePrivateEndpointSubnetName
    containerRegistryPrivateEndpointName: resourcesNames.containerRegistryPep
    containerRegistryUserAssignedIdentityName: resourcesNames.containerRegistryUserAssignedIdentity
    diagnosticWorkspaceId: logAnalyticsWorkspaceId
    deployZoneRedundantResources: deployZoneRedundantResources
    //managementVNetId: '/subscriptions/8747cd7f-1a06-4fe4-9dbb-24f612b9dd5a/resourceGroups/rg-hra-manageddevopspool/providers/Microsoft.Network/virtualNetworks/vnet-rsp-networking-devopspool'
    networkRuleSetIpRules: [
      // {
      //   action: 'Allow'
      //   value: '${devOpsPublicIPAddress}/32'  // Specific IP or CIDR block to allow
      // }
    ]
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
    networkRuleSetIpRules: [
      {
        action: 'Allow'
        value: '${devOpsPublicIPAddress}/32' // Specific IP or CIDR block to allow
      }
    ]
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
    oneLoginAuthority: oneLoginAuthority
    oneLoginPrivateKeyPem: oneLoginPrivateKeyPem
    oneLoginClientId: oneLoginClientId
    oneLoginIssuers: oneLoginIssuers
    storageAccountName: storageAccountName
    storageAccountKey: storageAccountKey
  }
}

// module serviceBus './modules/service-bus.module.bicep' = {
//   name: 'serviceBus-${uniqueString(resourceGroup().id)}'
//   params: {
//     serviceBusNamespaceName: resourcesNames.serviceBus
//     serviceBusPrivateEndpointName: resourcesNames.serviceBusPep
//     serviceBusReceiverUserAssignedIdentityName: resourcesNames.serviceBusReceiverUserAssignedIdentity
//     serviceBusSenderUserAssignedIdentityName: resourcesNames.serviceBusSenderUserAssignedIdentity
//     spokePrivateEndpointSubnetName: spokePrivateEndpointSubnetName
//     spokeVNetId: spokeVNetId
//     diagnosticWorkspaceId: logAnalyticsWorkspaceId
//   }
// }

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

@description('The principal ID of the user assigned managed identity for the App Configuration.')
output appConfigurationUserAssignedIdentityPrincipalId string = appConfiguration.outputs.appConfigurationUserAssignedIdentityPrincipalId

@description('The resource ID of the user assigned managed identity for the Key Vault to be able to read Secrets from it.')
output keyVaultUserAssignedIdentityId string = keyVault.outputs.keyVaultUserAssignedIdentityId

output appConfigURL string = appConfiguration.outputs.appConfigURL
output appConfigIdentityClientID string = appConfiguration.outputs.appConfigMIClientID
// output serviceBusReceiverManagedIdentityID string = serviceBus.outputs.serviceBusReceiverManagedIdentityId
// output serviceBusSenderManagedIdentity string = serviceBus.outputs.serviceBusSenderManagedIdentityId
