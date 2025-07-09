// ------------------
// PARAMETERS
// ------------------

@description('Required. Name of the WAF policy.')
param name string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Optional. Tags of the resource.')
param tags object?

@description('Optional. The pricing tier of the WAF policy.')
@allowed([
  'Standard_AzureFrontDoor'
  'Premium_AzureFrontDoor'
])
param skuName string = 'Premium_AzureFrontDoor'

@description('Optional. The WAF policy mode.')
@allowed([
  'Detection'
  'Prevention'
])
param policyMode string = 'Prevention'

@description('Optional. Whether the WAF policy is enabled.')
param enabled bool = true


@description('Optional. Enable Microsoft managed rules.')
param enableManagedRules bool = true

@description('Optional. Enable rate limiting.')
param enableRateLimiting bool = true

@description('Optional. Rate limit threshold for requests per minute.')
param rateLimitThreshold int = 1000

@description('Optional. Custom rules for the WAF policy.')
param customRules array = []

// ------------------
// VARIABLES
// ------------------

var managedRuleSets = enableManagedRules ? [
  {
    ruleSetType: 'Microsoft_DefaultRuleSet'
    ruleSetVersion: '2.1'
    ruleSetAction: 'Block'
    exclusions: []
    ruleGroupOverrides: []
  }
  {
    ruleSetType: 'Microsoft_BotManagerRuleSet'
    ruleSetVersion: '1.0'
    ruleSetAction: 'Block'
    exclusions: []
    ruleGroupOverrides: []
  }
] : []

var rateLimitRule = enableRateLimiting ? [
  {
    name: 'RateLimitRule'
    priority: 1
    ruleType: 'RateLimitRule'
    rateLimitDurationInMinutes: 1
    rateLimitThreshold: rateLimitThreshold
    matchConditions: [
      {
        matchVariable: 'RemoteAddr'
        selector: null
        operator: 'IPMatch'
        negateCondition: false
        matchValue: [
          '0.0.0.0/0'
        ]
      }
    ]
    action: 'Block'
    transforms: []
  }
] : []

var allCustomRules = concat(customRules, rateLimitRule)

// ------------------
// RESOURCES
// ------------------

resource wafPolicy 'Microsoft.Network/frontDoorWebApplicationFirewallPolicies@2022-05-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  properties: {
    policySettings: {
      enabledState: enabled ? 'Enabled' : 'Disabled'
      mode: policyMode
      customBlockResponseStatusCode: 403
      customBlockResponseBody: 'VGhlIHJlcXVlc3QgaGFzIGJlZW4gYmxvY2tlZCBieSBBenVyZSBGcm9udCBEb29yIFdBRi4='
      redirectUrl: null
      requestBodyCheck: 'Enabled'
    }
    customRules: {
      rules: allCustomRules
    }
    managedRules: {
      managedRuleSets: managedRuleSets
    }
  }
}

// ------------------
// OUTPUTS
// ------------------

@description('The resource ID of the WAF policy.')
output resourceId string = wafPolicy.id

@description('The name of the WAF policy.')
output name string = wafPolicy.name

@description('The location the resource was deployed into.')
output location string = wafPolicy.location

@description('The resource group the WAF policy was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The WAF policy properties.')
output policyProperties object = wafPolicy.properties