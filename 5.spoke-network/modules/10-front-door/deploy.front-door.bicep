// ------------------
// PARAMETERS
// ------------------

@description('Required. Location for all resources.')
param location string

@description('Optional. Tags for all resources.')
param tags object = {}

@description('Required. Names for all resources.')
param resourcesNames object

@description('Required. The hostname of the origin (web app).')
param originHostName string

@description('Required. The name of the web app for origin configuration.')
param webAppName string

@description('Optional. Enable WAF policy.')
param enableWaf bool = true

@description('Optional. WAF policy mode.')
@allowed([
  'Detection'
  'Prevention'
])
param wafMode string = 'Prevention'


@description('Optional. Enable rate limiting.')
param enableRateLimiting bool = true

@description('Optional. Rate limit threshold.')
param rateLimitThreshold int = 1000

@description('Optional. Custom domains for the Front Door.')
param customDomains array = []

@description('Optional. Enable caching.')
param enableCaching bool = true

@description('Optional. Cache duration.')
param cacheDuration string = 'P1D'

@description('Optional. Enable HTTPS redirect.')
param enableHttpsRedirect bool = true

@description('Optional. Enable managed TLS certificates.')
param enableManagedTls bool = true

@description('Optional. The resource ID of the web app for Private Link.')
param webAppResourceId string = ''

@description('Optional. Enable Private Link to origin.')
param enablePrivateLink bool = false

// ------------------
// VARIABLES
// ------------------

var frontDoorProfileName = resourcesNames.frontDoor
var frontDoorEndpointName = resourcesNames.frontDoorEndpoint
var originGroupName = resourcesNames.frontDoorOriginGroup
var routeName = resourcesNames.frontDoorRoute
var wafPolicyName = resourcesNames.frontDoorWaf

var originConfig = {
  name: webAppName
  hostName: originHostName
  priority: 1
  weight: 1000
  enabled: true
  enforceCertificateNameCheck: true
  privateLinkResourceId: enablePrivateLink ? webAppResourceId : null
  privateLinkLocation: enablePrivateLink ? location : null
  privateLinkRequestMessage: enablePrivateLink ? 'Request access for Front Door to ${webAppName}' : null
}

var cachingConfig = {
  cachingEnabled: enableCaching
  queryStringCachingBehavior: 'IgnoreQueryString'
  compressionEnabled: true
  cacheDuration: cacheDuration
}

// ------------------
// RESOURCES
// ------------------

// WAF Policy
module wafPolicy '../../../shared/bicep/front-door/waf-policy.bicep' = if (enableWaf) {
  name: take('waf-policy-${deployment().name}', 64)
  params: {
    name: wafPolicyName
    location: location
    tags: tags
    skuName: 'Premium_AzureFrontDoor'
    policyMode: wafMode
    enabled: true
    enableManagedRules: true
    enableRateLimiting: enableRateLimiting
    rateLimitThreshold: rateLimitThreshold
    customRules: []
  }
}

// Front Door Profile
module frontDoorProfile '../../../shared/bicep/front-door/front-door-profile.bicep' = {
  name: take('front-door-profile-${deployment().name}', 64)
  params: {
    name: frontDoorProfileName
    location: location
    tags: tags
    skuName: 'Premium_AzureFrontDoor'
    identityType: 'SystemAssigned'
    originResponseTimeoutSeconds: 60
  }
}

// Front Door Endpoint
module frontDoorEndpoint '../../../shared/bicep/front-door/front-door-endpoint.bicep' = {
  name: take('front-door-endpoint-${deployment().name}', 64)
  params: {
    name: frontDoorEndpointName
    frontDoorProfileName: frontDoorProfile.outputs.name
    location: location
    tags: tags
    enabled: true
    customDomains: customDomains
    enableManagedTls: enableManagedTls
    minimumTlsVersion: 'TLS12'
  }
}

// Origin Group
module originGroup '../../../shared/bicep/front-door/origin-group.bicep' = {
  name: take('origin-group-${deployment().name}', 64)
  params: {
    name: originGroupName
    frontDoorProfileName: frontDoorProfile.outputs.name
    origins: [originConfig]
    sessionAffinityState: 'Disabled'
    trafficRestorationTimeToHealedOrNewEndpointsInMinutes: 10
  }
}

// Route
module route '../../../shared/bicep/front-door/route.bicep' = {
  name: take('route-${deployment().name}', 64)
  params: {
    name: routeName
    frontDoorProfileName: frontDoorProfile.outputs.name
    frontDoorEndpointName: frontDoorEndpoint.outputs.name
    originGroupId: originGroup.outputs.resourceId
    customDomains: []
    supportedProtocols: ['Http', 'Https']
    patternsToMatch: ['/*']
    forwardingProtocol: 'HttpsOnly'
    linkToDefaultDomain: true
    httpsRedirect: enableHttpsRedirect
    caching: cachingConfig
    wafPolicyId: enableWaf ? wafPolicy.outputs.resourceId : ''
  }
}

// ------------------
// OUTPUTS
// ------------------

@description('The resource ID of the Front Door profile.')
output frontDoorProfileId string = frontDoorProfile.outputs.resourceId

@description('The name of the Front Door profile.')
output frontDoorProfileName string = frontDoorProfile.outputs.name

@description('The resource ID of the Front Door endpoint.')
output frontDoorEndpointId string = frontDoorEndpoint.outputs.resourceId

@description('The hostname of the Front Door endpoint.')
output frontDoorEndpointHostName string = frontDoorEndpoint.outputs.hostName

@description('The resource ID of the origin group.')
output originGroupId string = originGroup.outputs.resourceId

@description('The resource ID of the WAF policy.')
output wafPolicyId string = enableWaf ? wafPolicy.outputs.resourceId : ''

@description('The URL of the Front Door endpoint.')
output frontDoorUrl string = 'https://${frontDoorEndpoint.outputs.hostName}'