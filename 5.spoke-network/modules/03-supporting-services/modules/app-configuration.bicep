targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------

@description('Specifies the name of the App Configuration store.')
param configStoreName string

@description('Specifies the Azure location where the app configuration store should be created.')
param location string = resourceGroup().location

@description('Adds tags for the key-value resources. It\'s optional')
param tags object = {}

param appConfigurationUserUserAssignedIdentityName string = ''
param sqlServerName string

param networkingResourcesNames object
param networkingResourceGroup string

@description('The resource ID of the VNet to which the private endpoint will be connected.')
param spokeVNetId string

@description('The name of the subnet in the VNet to which the private endpoint will be connected.')
param spokePrivateEndpointSubnetName string

@description('JWKS URi for backend services to validate a request')
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

@description('Allowed hosts for the application to be used when the Web App is behind Front Door')
param allowedHosts string

@description('Indicates whether to use Front Door for the application')
param useFrontDoor bool

@description('Enable private endpoints for App Configuration')
param enablePrivateEndpoints bool = false


@description('Indicates whether to use One Login for the application')
param useOneLogin bool

@secure()
@description('The key for the Microsot Clarity project this is associated with.')
param clarityProjectId string

@description('App Configuration SKU name')
param appConfigurationSku string = 'standard'

@secure()
@description('The key for the Google Analytics project this is associated with.')
param googleTagId string

@description('The URI of the CMS where content related to this application is managed')
param cmsUri string

@description('The URL to redirect to on logout from auth provider')
param logoutUrl string

var appConfigurationDataReaderRoleGUID = '516239f1-63e1-4d78-a4de-a74fb236a071'

var keyValues = [
  {
    name: 'AppSettings:AllowedHosts$portal' // Allowed hosts for the portal to be used when the Web App is behind Front Door
    value: allowedHosts
    contentType: null
  }
  {
    name: 'AppSettings:AuthSettings:Authority'
    value: 'https://${IDGENV}.id.nihr.ac.uk:443/oauth2/token'
    contentType: null
  }
  {
    name: 'AppSettings:AuthSettings:Issuers'
    value: '["https://${IDGENV}.id.nihr.ac.uk:443/oauth2/token","https://${IDGENV}.id.nihr.ac.uk/oauth2/token"]'
    contentType: 'application/json'
  }
  {
    name: 'AppSettings:AuthSettings:ClientId'
    value: clientID
    contentType: null
  }
  {
    name: 'AppSettings:AuthSettings:ClientSecret'
    value: clientSecret
    contentType: null
  }
  {
    name: 'AppSettings:AuthSettings:JwksUri'
    value: 'https://${jwksURI}/jwks'
    contentType: null
  }
  {
    name: 'AppSettings:AuthSettings:AuthCookieTimeout$portal' // Auth cookie timeout in seconds
    value: 3600
    contentType: null
  }
  {
    name: 'ConnectionStrings:IrasServiceDatabaseConnection'
    value: 'Server=tcp:${sqlServerName}${az.environment().suffixes.sqlServerHostname},1433;Database=applicationservice;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;Authentication=\'Active Directory Default\';'
    contentType: null
  }
  {
    name: 'ConnectionStrings:IdentityDbConnection'
    value: 'Server=tcp:${sqlServerName}${az.environment().suffixes.sqlServerHostname},1433;Database=identityservice;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;Authentication=\'Active Directory Default\';'
    contentType: null
  }
  {
    name: 'ConnectionStrings:RTSDatabaseConnection'
    value: 'Server=tcp:${sqlServerName}${az.environment().suffixes.sqlServerHostname},1433;Database=RtsService;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;Authentication=\'Active Directory Default\';'
    contentType: null
  }
  {
    name: 'ConnectionStrings:cmsPortalDatabaseConnection'
    value: 'Server=tcp:${sqlServerName}${az.environment().suffixes.sqlServerHostname},1433;Database=cmsservice;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;Authentication=\'Active Directory Default\';'
    contentType: null
  }
  {
    name: 'AppSettings:Sentinel$applicationservice'
    value: '0'
    contentType: null
  }
  {
    name: 'AppSettings:Sentinel$portal'
    value: '0'
    contentType: null
  }
  {
    name: 'AppSettings:Sentinel$rtsservice'
    value: '0'
    contentType: null
  }
  {
    name: 'AppSettings:Sentinel$usersservice'
    value: '0'
    contentType: null
  }
  {
    name: 'AppSettings:OneLogin:Authority$portal'
    value: oneLoginAuthority
    contentType: null
  }
  {
    name: 'AppSettings:OneLogin:PrivateKeyPem$portal'
    value: oneLoginPrivateKeyPem
    contentType: null
  }
  {
    name: 'AppSettings:OneLogin:AuthCookieTimeout$portal' // Auth cookie timeout for Gov UK One Login in seconds
    value: 3600
    contentType: null
  }
  {
    name: 'AppSettings:OneLogin:ClientId'
    value: oneLoginClientId
    contentType: null
  }
  {
    name: 'AppSettings:OneLogin:Issuers'
    value: oneLoginIssuers
    contentType: 'application/json'
  }
  {
    name: 'AppSettings:SessionTimeout$portal' // Session timeout in seconds
    value: 3600
    contentType: null
  }
  {
    name: 'AppSettings:WarningBeforeSeconds$portal' // Warning before session timeout in seconds
    value: 120
    contentType: null
  }
  {
    name: 'AppSettings:DatabaseCommandTimeout$rtsimportfunction' // Warning before session timeout in seconds
    value: 500
    contentType: null
  }
  {
    name: 'AppSettings:BulkCopyTimeout$rtsimportfunction' // Warning before session timeout in seconds
    value: 500
    contentType: null
  }
  {
    name: 'AppSettings:Azure:DocumentStorage:Blob:ConnectionString$portal'
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccountKey};EndpointSuffix=${az.environment().suffixes.storage};'
    contentType: null
  }
  {
    name: 'AppSettings:ClarityProjectId$portal'
    value: clarityProjectId
    contentType: null
  }
  {
    name: 'AppSettings:GoogleTagId$portal'
    value: googleTagId
    contentType: null
  }
  {
    name: 'AppSettings:CmsUri$portal'
    value: cmsUri
    contentType: null
  }
  {
    name: 'AppSettings:AuthSettings:LogoutUrl$portal'
    value: logoutUrl
    contentType: null
  }
]

var featureFlags = [
  {
    id: 'Action.ProceedToSubmit'
    label: 'portal'
    description: 'When disabled Proceed To Submit button won\'t appear.'
    enabled: true
  }
  {
    id: 'Logging.InterceptedLogging'
    description: 'If enabled, all action methods and services will have start/end logging using Interceptors.'
    label: null
    enabled: true
  }
  {
    id: 'Navigation.Admin'
    description: 'When disabled the Admin menu won\'t appear.'
    label: 'portal'
    enabled: true
  }
  {
    id: 'Navigation.MyApplications'
    description: 'When disabled My Applications men won\'t appear.'
    label: 'portal'
    enabled: true
  }
  {
    id: 'Navigation.ReviewApplications'
    description: 'When disabled the Review Applications menu won\'t appear.'
    label: 'portal'
    enabled: true
  }
  {
    id: 'UX.ProgressiveEnhancement'
    description: 'If this flag is enabled, and javascript is enabled, will provide an enhanced user experience.'
    label: 'portal'
    enabled: true
  }
  {
    id: 'UX.MyResearchPage'
    description: 'If this flag is enabled, show projects added to new service in my research dashboard'
    label: 'portal'
    enabled: true
  }
  {
    id: 'Auth.UseOneLogin'
    description: 'When enabled, Gov UK One Login will be used for authentication'
    label: null
    enabled: useOneLogin
  }
  {
    id: 'WebApp.UseFrontDoor'
    description: 'When enabled, it will use the AllowedHosts to Front Door URL.'
    label: 'portal'
    enabled: useFrontDoor
  }
]

var privateDnsZoneNames = 'privatelink.azconfig.io'
var appConfigResourceName = 'configurationStores'

var spokeVNetIdTokens = split(spokeVNetId, '/')
var spokeSubscriptionId = spokeVNetIdTokens[2]
var spokeResourceGroupName = spokeVNetIdTokens[4]
var spokeVNetName = spokeVNetIdTokens[8]

var spokeVNetLinks = [
  {
    vnetName: spokeVNetName
    vnetId: vnetSpoke.id
    registrationEnabled: false
  }
  // {
  //   vnetName: vnetHub.name
  //   vnetId: vnetHub.id
  //   registrationEnabled: false
  // }
]

resource vnetSpoke 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  scope: resourceGroup(spokeSubscriptionId, spokeResourceGroupName)
  name: spokeVNetName
}

resource spokePrivateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' existing = {
  parent: vnetSpoke
  name: spokePrivateEndpointSubnetName
}

resource appConfigurationUserAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: appConfigurationUserUserAssignedIdentityName
  location: location
  tags: tags
}

resource configStore 'Microsoft.AppConfiguration/configurationStores@2024-05-01' = {
  name: configStoreName
  location: location
  sku: {
    name: appConfigurationSku
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${appConfigurationUserAssignedIdentity.id}': {}
    }
  }
  properties: {
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: true
    dataPlaneProxy: {
      authenticationMode: 'Pass-through'
      privateLinkDelegation: 'Enabled'
    }
  }
}

resource configStoreKeyValue 'Microsoft.AppConfiguration/configurationStores/keyValues@2023-03-01' = [
  for keyValue in keyValues: {
    parent: configStore
    name: keyValue.name
    properties: {
      value: string(keyValue.value)
      contentType: keyValue.contentType
    }
  }
]

// TODO: KeyVault reference will be implemented later
// resource configStoreWithKeyVaultRef 'Microsoft.AppConfiguration/configurationStores/keyValues@2024-05-01' = [
//   for keyValue in keyValues: {
//     parent: configStore
//     name: keyValue
//     properties: {
//       value: string(keyVaultRef)
//       contentType: 'application/vnd.microsoft.appconfig.keyvaultref+json;charset=utf-8'
//     }
//   }
// ]

resource configStoreFeatureflag 'Microsoft.AppConfiguration/configurationStores/keyValues@2024-05-01' = [
  for feature in featureFlags: {
    parent: configStore
    name: '.appconfig.featureflag~2F${feature.id}$${feature.label}'
    properties: {
      value: string(feature)
      contentType: 'application/vnd.microsoft.appconfig.ff+json;charset=utf-8'
    }
  }
]

module appConfigurationDataReaderAssignment '../../../../shared/bicep/role-assignments/role-assignment.bicep' = {
  name: take('appConfigurationDataReaderAssignmentDeployment-${deployment().name}', 64)
  params: {
    name: 'ra-appConfigurationDataReaderRoleAssignment'
    principalId: appConfigurationUserAssignedIdentity.properties.principalId
    resourceId: configStore.id
    roleDefinitionId: appConfigurationDataReaderRoleGUID
    principalType: 'ServicePrincipal'
  }
}

module appConfigNetwork '../../../../shared/bicep/network/private-networking-spoke.bicep' = if (enablePrivateEndpoints) {
  name: 'appConfigNetwork-${uniqueString(configStore.id)}'
  scope: resourceGroup(networkingResourceGroup)
  params: {
    location: location
    azServicePrivateDnsZoneName: privateDnsZoneNames
    azServiceId: configStore.id
    privateEndpointName: networkingResourcesNames.azureappconfigurationstorepep
    privateEndpointSubResourceName: appConfigResourceName
    virtualNetworkLinks: spokeVNetLinks
    subnetId: spokePrivateEndpointSubnet.id
  }
}


@description('The resource ID of the user assigned managed identity for the App Configuration to be able to read configurations from it.')
output appConfigurationUserAssignedIdentityId string = appConfigurationUserAssignedIdentity.id

@description('The principal ID of the user assigned managed identity for the App Configuration.')
output appConfigurationUserAssignedIdentityPrincipalId string = appConfigurationUserAssignedIdentity.properties.principalId

output appConfigURL string = configStore.properties.endpoint
output appConfigMIClientID string = appConfigurationUserAssignedIdentity.properties.clientId
