@description('Required. Name of the rule set.')
param name string

@description('Required. The name of the Front Door profile.')
param frontDoorProfileName string

@description('Optional. Rules for the rule set. Each rule must specify at minimum a name and actions.')
param rules array = []

resource frontDoorProfile 'Microsoft.Cdn/profiles@2023-05-01' existing = {
  name: frontDoorProfileName
}

resource ruleSet 'Microsoft.Cdn/profiles/ruleSets@2023-05-01' = {
  name: name
  parent: frontDoorProfile
}

resource rule 'Microsoft.Cdn/profiles/ruleSets/rules@2023-05-01' = [for (ruleConfig, idx) in rules: {
  name: ruleConfig.name
  parent: ruleSet
  properties: {
    order: contains(ruleConfig, 'order') ? ruleConfig.order : (idx + 1)
    conditions: contains(ruleConfig, 'conditions') ? ruleConfig.conditions : []
    actions: ruleConfig.actions
    matchProcessingBehavior: contains(ruleConfig, 'matchProcessingBehavior') ? ruleConfig.matchProcessingBehavior : 'Continue'
  }
}]

@description('The resource ID of the rule set.')
output resourceId string = ruleSet.id

@description('The name of the rule set.')
output name string = ruleSet.name

@description('The resource group the rule set was deployed into.')
output resourceGroupName string = resourceGroup().name
