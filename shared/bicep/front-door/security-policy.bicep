// ------------------
// PARAMETERS
// ------------------

@description('Required. Name of the security policy.')
param name string

@description('Required. The name of the Front Door profile.')
param frontDoorProfileName string

@description('Required. The resource ID of the WAF policy.')
param wafPolicyId string

@description('Required. The resource ID of the Front Door endpoint.')
param endpointId string

@description('Required. The patterns to match for the security policy.')
param patternsToMatch array

// ------------------
// RESOURCES
// ------------------

resource frontDoorProfile 'Microsoft.Cdn/profiles@2023-05-01' existing = {
  name: frontDoorProfileName
}

resource securityPolicy 'Microsoft.Cdn/profiles/securityPolicies@2023-05-01' = {
  name: name
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
              id: endpointId
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

@description('The resource ID of the security policy.')
output resourceId string = securityPolicy.id

@description('The name of the security policy.')
output name string = securityPolicy.name

@description('The resource group the security policy was deployed into.')
output resourceGroupName string = resourceGroup().name
