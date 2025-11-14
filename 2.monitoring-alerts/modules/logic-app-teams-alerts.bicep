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
      parameters: {
        // '$connections': {
        //   defaultValue: {}
        //   type: 'Object'
        // }
      }
      triggers: {
          When_an_HTTP_request_is_received: {
          type: 'Request'
          kind: 'Http'
        }
      }
      actions: {
        // Post_message_in_a_chat_or_channel: {
        //   runAfter: {}
        //   type: 'ApiConnection'
        //   inputs: {
        //     host: {
        //       connection: {
        //         name: '@parameters(\'$connections\')[\'teams\'][\'connectionId\']'
        //       }
        //     }
        //     method: 'post'
        //     body: {
        //       recipient: {
        //         groupId: '489c85b8-47a9-4a63-83d1-3516c96d581a'
        //         channelId: '19:fe6b0d23ff984adc94deaeeb89d95688@thread.tacv2'
        //       }
        //       messageBody: '<p class="editor-paragraph"><i><b><strong class="editor-text-bold editor-text-italic">Azure Monitor Alert</strong></b></i><br><br>@{concat(\'🚨 \', triggerBody()?[\'data\']?[\'alertContext\']?[\'condition\']?[\'allOf\']?[0]?[\'dimensions\']?[0]?[\'value\'], \'<br><br>\', \'<strong>Severity:</strong> \', triggerBody()?[\'data\']?[\'essentials\']?[\'severity\'], \'<br><br>\', \'<strong>Fired At:</strong> \', triggerBody()?[\'data\']?[\'essentials\']?[\'firedDateTime\'], \'<br><br>\', \'<strong>Description:</strong> \', triggerBody()?[\'data\']?[\'essentials\']?[\'description\'], \'<br><br>\', \'---\', \'<br><br>\', \'<strong>AffectedService:</strong> \', triggerBody()?[\'data\']?[\'alertContext\']?[\'condition\']?[\'allOf\']?[0]?[\'dimensions\']?[0]?[\'value\'], \'<br><br>\', \'<strong>Message:</strong> \', triggerBody()?[\'data\']?[\'alertContext\']?[\'condition\']?[\'allOf\']?[0]?[\'dimensions\']?[2]?[\'value\'], \'<br><br>\', \'<strong>🔗 Link to Search Results:</strong> <a href="\', triggerBody()?[\'data\']?[\'alertContext\']?[\'condition\']?[\'allOf\']?[0]?[\'linkToFilteredSearchResultsUI\'], \'">Click here to view</a>\')}</p>'
        //     }
        //     path: '/beta/teams/conversation/message/poster/Flow bot/location/@{encodeURIComponent(\'Channel\')}'
        //   }
        // }
      }
      outputs: {}
    }
    parameters: {
      // '$connections': {
      //   type: 'Object'
      //   value: {
      //     teams: {
      //       id: '/subscriptions/b83b4631-b51b-4961-86a1-295f539c826b/providers/Microsoft.Web/locations/uksouth/managedApis/teams'
      //       connectionId: '/subscriptions/b83b4631-b51b-4961-86a1-295f539c826b/resourceGroups/rg-hra-monitoring-dev/providers/Microsoft.Web/connections/teams'
      //       connectionName: 'teams'
      //     }
      //   }
      // }
    }
  }
}

@description('The Logic App resource ID')
output logicAppId string = logicApp.id


