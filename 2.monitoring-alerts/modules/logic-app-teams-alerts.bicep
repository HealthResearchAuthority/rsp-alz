targetScope = 'resourceGroup'

@description('Location for the Logic App')
param location string = resourceGroup().location

@description('Environment name (e.g., dev, prod)')
param environment string

@description('Organization prefix for naming')
param organizationPrefix string = 'hra'

@description('Optional Logic App name override')
param logicAppName string = '${organizationPrefix}-${environment}-teams-alerts-la'

@description('Tags to apply to the Logic App')
param tags object = {}

var defaultTags = union(tags, {
  Environment: environment
  Purpose: 'Azure Monitor Alerts to Teams'
})

resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  tags: defaultTags
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {}
      triggers: {}
      actions: {}
      outputs: {}
}
    parameters: {}
  }
}

@description('The Logic App resource ID')
output logicAppId string = logicApp.id


