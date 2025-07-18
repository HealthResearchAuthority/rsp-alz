// ------------------
// PARAMETERS
// ------------------

@description('Required. Name of the route.')
param name string

@description('Required. The name of the Front Door profile.')
param frontDoorProfileName string

@description('Required. The name of the Front Door endpoint.')
param frontDoorEndpointName string

@description('Required. The resource ID of the origin group.')
param originGroupId string

@description('Optional. The custom domains for the route.')
param customDomains array = []

@description('Optional. The supported protocols.')
@allowed([
  'Http'
  'Https'
])
param supportedProtocols array = ['Http', 'Https']

@description('Optional. The patterns to match for the route.')
param patternsToMatch array = ['/*']

@description('Optional. The forwarding protocol.')
@allowed([
  'HttpOnly'
  'HttpsOnly'
  'MatchRequest'
])
param forwardingProtocol string = 'HttpsOnly'

@description('Optional. Link to the default domain.')
param linkToDefaultDomain bool = true

@description('Optional. Whether HTTPS redirect is enabled.')
param httpsRedirect bool = true

@description('Optional. Caching configuration.')
param caching object = {
  cachingEnabled: true
  queryStringCachingBehavior: 'IgnoreQueryString'
  compressionEnabled: true
  cacheDuration: 'P1D'
}

@description('Optional. The resource ID of the WAF policy.')
param wafPolicyId string = ''

@description('Optional. The resource ID of the rule set.')
param ruleSetId string = ''

// ------------------
// RESOURCES
// ------------------

resource frontDoorProfile 'Microsoft.Cdn/profiles@2023-05-01' existing = {
  name: frontDoorProfileName
}

resource frontDoorEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2023-05-01' existing = {
  name: frontDoorEndpointName
  parent: frontDoorProfile
}

resource route 'Microsoft.Cdn/profiles/afdEndpoints/routes@2023-05-01' = {
  name: name
  parent: frontDoorEndpoint
  properties: {
    customDomains: [for domain in customDomains: {
      id: domain.id
    }]
    originGroup: {
      id: originGroupId
    }
    supportedProtocols: supportedProtocols
    patternsToMatch: patternsToMatch
    forwardingProtocol: forwardingProtocol
    linkToDefaultDomain: linkToDefaultDomain ? 'Enabled' : 'Disabled'
    httpsRedirect: httpsRedirect ? 'Enabled' : 'Disabled'
    cacheConfiguration: caching.cachingEnabled ? {
      queryStringCachingBehavior: caching.queryStringCachingBehavior
      compressionSettings: {
        contentTypesToCompress: [
          'application/eot'
          'application/font'
          'application/font-sfnt'
          'application/javascript'
          'application/json'
          'application/opentype'
          'application/otf'
          'application/pkcs7-mime'
          'application/truetype'
          'application/ttf'
          'application/vnd.ms-fontobject'
          'application/xhtml+xml'
          'application/xml'
          'application/xml+rss'
          'application/x-font-opentype'
          'application/x-font-truetype'
          'application/x-font-ttf'
          'application/x-httpd-cgi'
          'application/x-javascript'
          'application/x-mpegurl'
          'application/x-opentype'
          'application/x-otf'
          'application/x-perl'
          'application/x-ttf'
          'font/eot'
          'font/ttf'
          'font/otf'
          'font/opentype'
          'image/svg+xml'
          'text/css'
          'text/csv'
          'text/html'
          'text/javascript'
          'text/js'
          'text/plain'
          'text/richtext'
          'text/tab-separated-values'
          'text/xml'
          'text/x-script'
          'text/x-component'
          'text/x-java-source'
        ]
        isCompressionEnabled: caching.compressionEnabled
      }
    } : null
    ruleSets: !empty(ruleSetId) ? [
      {
        id: ruleSetId
      }
    ] : []
    enabledState: 'Enabled'
  }
}

// Associate WAF policy if provided
resource securityPolicy 'Microsoft.Cdn/profiles/securityPolicies@2023-05-01' = if (!empty(wafPolicyId)) {
  name: '${name}-security-policy'
  parent: frontDoorProfile
  properties: {
    parameters: {
      type: 'WebApplicationFirewall'
      wafPolicy: {
        id: wafPolicyId
      }
      associations: [
        {
          domains: [
            {
              id: frontDoorEndpoint.id
            }
          ]
          patternsToMatch: patternsToMatch
        }
      ]
    }
  }
}

// ------------------
// OUTPUTS
// ------------------

@description('The resource ID of the route.')
output resourceId string = route.id

@description('The name of the route.')
output name string = route.name

@description('The resource group the route was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The resource ID of the security policy.')
output securityPolicyId string = !empty(wafPolicyId) ? securityPolicy.id : ''