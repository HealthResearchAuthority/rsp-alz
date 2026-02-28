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

@description('Indicates whether to use One Login for the application')
param useOneLogin bool

@description('Optional. Whether to create Key Vault secrets with placeholder values. Set to false to skip secret creation after initial deployment.')
param createSecretsWithPlaceholders bool = false

@description('Optional, default value is true. If true, any resources that support AZ will be deployed in all three AZ. However if the selected region is not supporting AZ, this parameter needs to be set to false.')
param containerRegistryTier string = ''

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

@description('Valid token issuers for Gov UK One Login')
param oneLoginIssuers array

@description('Allowed hosts for the application to be used when the Web App is behind Front Door')
param allowedHosts string

@description('Indicates whether to use Front Door for the application')
param useFrontDoor bool

@description('Enable Key Vault private endpoints')
param enableKeyVaultPrivateEndpoints bool = false

@description('Enable App Configuration private endpoints')
param enableAppConfigPrivateEndpoints bool = false

@description('IP addresses to be whitelisted for users to access Key Vault')
param paramWhitelistIPs string = ''

@secure()
@description('The key for the Microsot Clarity project this is associated with.')
param clarityProjectId string

@description('Key Vault SKU')
param keyVaultSku string = 'standard'

@description('App Configuration SKU')
param appConfigurationSku string = 'standard'

@description('App Configuration encryption configuration')
param appConfigEncryptionConfig object = {
  enabled: false
  keyName: ''
  keyRotationEnabled: true
}

@secure()
@description('The key for the Google Analytics project this is associated with.')
param googleTagId string

@description('The URI of the CMS where content related to this application is managed')
param cmsUri string

@description('The URL of the Portal application')
param portalUrl string

@description('The URL to redirect to on logout from auth provider')
param logoutUrl string

@description('Maximum concurrent API requests')
param apiRequestMaxConcurrency int

@description('API request page size')
param apiRequestPageSize int

@description('Base URL for RTS API')
param rtsApiBaseUrl string

@description('Base URL for RTS authentication API')
param rtsAuthApiBaseUrl string

param parMicrosoftEntraAudience string

@description('Client ID of the managed identity to be used for the Document Upload Function App')
param processDocuUploadManagedIdentityClientId string

param parMicrosoftEntraAuthority string

@description('Environment name for constructing storage account names')
param environment string

@description('SQL query for retrieving HARP project records')
param harpProjectRecordsQuery string

@description('BGO database IP address')
param bgodatabase string

@description('BGO harp database user')
param bgodatabaseuser string

@description('User password for BGO harp database')
@secure()
param bgodatabasepassword string

// ------------------
// Varaibles
// ------------------

var keyVaultPrivateDnsZoneName = 'privatelink.vaultcore.azure.net'

var varWhitelistIPs = filter(split(paramWhitelistIPs, ','), ip => !empty(ip))
var devOpsIPRule = {
  action: 'Allow'
  value: '${devOpsPublicIPAddress}/32'
}
var whitelistIPRules = [
  for ip in varWhitelistIPs: {
    action: 'Allow'
    value: contains(ip, '/') ? ip : '${ip}/32' // '${ip}/32'
  }
]
var allAllowedIPs = !empty(devOpsPublicIPAddress) ? concat([devOpsIPRule], whitelistIPRules) : whitelistIPRules

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
    networkRuleSetIpRules: allAllowedIPs // DevOps IP + whitelist IPs
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
    privateDNSEnabled: enableKeyVaultPrivateEndpoints
    privateDnsZoneName: keyVaultPrivateDnsZoneName
    keyVaultUserAssignedIdentityName: resourcesNames.keyVaultUserAssignedIdentity
    networkRuleSetIpRules: allAllowedIPs
    keyVaultSku: keyVaultSku
  }
}

@description('Key Vault secrets deployment with placeholder values for OneLogin integration.')
module keyVaultSecrets './modules/key-vault-secrets.bicep' = {
  name: 'keyVaultSecrets-${uniqueString(resourceGroup().id)}'
  params: {
    keyVaultName: resourcesNames.keyVault
    tags: tags
    createSecretsWithPlaceholders: createSecretsWithPlaceholders
  }
  dependsOn: [keyVault]
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
    oneLoginIssuers: oneLoginIssuers
    allowedHosts: allowedHosts
    useFrontDoor: useFrontDoor
    enablePrivateEndpoints: enableAppConfigPrivateEndpoints
    useOneLogin: useOneLogin
    clarityProjectId: clarityProjectId
    appConfigurationSku: appConfigurationSku
    googleTagId: googleTagId
    cmsUri: cmsUri
    portalUrl: portalUrl
    logoutUrl: logoutUrl
    apiRequestMaxConcurrency: apiRequestMaxConcurrency
    apiRequestPageSize: apiRequestPageSize
    rtsApiBaseUrl: rtsApiBaseUrl
    rtsAuthApiBaseUrl: rtsAuthApiBaseUrl
    parMicrosoftEntraAudience: parMicrosoftEntraAudience
    processDocuUploadManagedIdentityClientId: processDocuUploadManagedIdentityClientId
    keyVaultSecretUris: {
      oneLoginClientIdSecretUri: keyVaultSecrets.outputs.oneLoginClientIdSecretUri
      oneLoginPrivateKeyPemSecret: keyVaultSecrets.outputs.oneLoginPrivateKeyPemSecret
      rtsApiClientIdSecretUri: keyVaultSecrets.outputs.rtsApiClientIdSecretUri
      rtsApiClientSecretSecretUri: keyVaultSecrets.outputs.rtsApiClientSecretSecretUri
    }
    environment: environment
    parMicrosoftEntraAuthority: parMicrosoftEntraAuthority
    harpProjectRecordsQuery: harpProjectRecordsQuery
    bgodatabase: bgodatabase
    bgodatabaseuser: bgodatabaseuser
    bgodatabasepassword: bgodatabasepassword
    appConfigEncryptionConfig: appConfigEncryptionConfig
    keyVaultId: keyVault.outputs.keyVaultId
  }
}

@description('Role assignment for App Configuration managed identity to read Key Vault secrets.')
module appConfigKeyVaultAccess '../../../shared/bicep/role-assignments/role-assignment.bicep' = {
  name: 'appConfigKeyVaultAccess-${uniqueString(resourceGroup().id)}'
  params: {
    name: 'appConfig-keyVault-secretsUser-role-assignment'
    principalId: appConfiguration.outputs.appConfigurationUserAssignedIdentityPrincipalId
    resourceId: keyVault.outputs.keyVaultId
    roleDefinitionId: '4633458b-17de-408a-b874-0445c86b69e6' // Key Vault Secrets User
    principalType: 'ServicePrincipal'
  }
}

@description('User-assigned managed identity for the Process Scan Function App.')
module processScanFunctionIdentity '../../../shared/bicep/managed-identity.bicep' = {
  name: 'processScanFunctionIdentity-${uniqueString(resourceGroup().id)}'
  params: {
    name: 'id-func-processscan-${resourceGroup().location}'
    location: location
    tags: tags
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

@description('The resource ID of the user-assigned managed identity for the Process Scan Function App.')
output processScanFunctionUserAssignedIdentityId string = processScanFunctionIdentity.outputs.id

@description('The principal ID of the user-assigned managed identity for the Process Scan Function App.')
output processScanFunctionUserAssignedIdentityPrincipalId string = processScanFunctionIdentity.outputs.principalId

// output serviceBusReceiverManagedIdentityID string = serviceBus.outputs.serviceBusReceiverManagedIdentityId
// output serviceBusSenderManagedIdentity string = serviceBus.outputs.serviceBusSenderManagedIdentityId
