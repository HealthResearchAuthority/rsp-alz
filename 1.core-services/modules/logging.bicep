targetScope = 'resourceGroup'

metadata name = 'ALZ Bicep - Logging Module'
metadata description = 'ALZ Bicep Module used to set up Logging'

type lockType = {
  @description('Optional. Specify the name of lock.')
  name: string?

  @description('Optional. The lock settings of the service.')
  kind: ('CanNotDelete' | 'ReadOnly' | 'None')

  @description('Optional. Notes about this lock.')
  notes: string?
}

@sys.description('''Global Resource Lock Configuration used for all resources deployed in this module.

- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.

''')
param parGlobalResourceLock lockType = {
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Logging Module.'
}

@sys.description('Log Analytics Workspace name.')
param parLogAnalyticsWorkspaceName string = ''

@sys.description('Log Analytics region name - Ensure the regions selected is a supported mapping as per: https://docs.microsoft.com/azure/automation/how-to/region-mappings.')
param parLogAnalyticsWorkspaceLocation string = resourceGroup().location

@allowed([
  'CapacityReservation'
  'Free'
  'LACluster'
  'PerGB2018'
  'PerNode'
  'Premium'
  'Standalone'
  'Standard'
])
@sys.description('Log Analytics Workspace sku name.')
param parLogAnalyticsWorkspaceSkuName string = 'PerGB2018'

@allowed([
  100
  200
  300
  400
  500
  1000
  2000
  5000
])
@sys.description('Log Analytics Workspace Capacity Reservation Level. Only used if parLogAnalyticsWorkspaceSkuName is set to CapacityReservation.')
param parLogAnalyticsWorkspaceCapacityReservationLevel int = 100

@minValue(30)
@maxValue(730)
@sys.description('Number of days of log retention for Log Analytics Workspace.')
param parLogAnalyticsWorkspaceLogRetentionInDays int = 365

@sys.description('''Resource Lock Configuration for Log Analytics Workspace.

- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.

''')
param parLogAnalyticsWorkspaceLock lockType = {
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Logging Module.'
}

@allowed([
  'AgentHealthAssessment'
  'AntiMalware'
  'ChangeTracking'
  'Security'
  'SecurityInsights'
  'ServiceMap'
  'SQLAdvancedThreatProtection'
  'SQLVulnerabilityAssessment'
  'SQLAssessment'
  'Updates'
  'VMInsights'
])
@sys.description('Solutions that will be added to the Log Analytics Workspace.')
param parLogAnalyticsWorkspaceSolutions array = [
  'AgentHealthAssessment'
  'AntiMalware'
  'ChangeTracking'
  'Security'
  'SQLAdvancedThreatProtection'
  'SQLVulnerabilityAssessment'
  'SQLAssessment'
  'Updates'
]

@sys.description('''Resource Lock Configuration for Log Analytics Workspace Solutions.

- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.

''')
param parLogAnalyticsWorkspaceSolutionsLock lockType = {
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Logging Module.'
}

@sys.description('Log Analytics Workspace should be linked with the automation account.')
param parLogAnalyticsWorkspaceLinkAutomationAccount bool = true

@sys.description('Automation account name.')
param parAutomationAccountName string = ''

@sys.description('Automation Account region name. - Ensure the regions selected is a supported mapping as per: https://docs.microsoft.com/azure/automation/how-to/region-mappings.')
param parAutomationAccountLocation string = resourceGroup().location

@sys.description('Automation Account - use managed identity.')
param parAutomationAccountUseManagedIdentity bool = true

@sys.description('Automation Account - Public network access.')
param parAutomationAccountPublicNetworkAccess bool = true

@sys.description('''Resource Lock Configuration for Automation Account.

- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.

''')
param parAutomationAccountLock lockType = {
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Logging Module.'
}

@sys.description('Tags you would like to be applied to all resources in this module.')
param parTags object = {}

@sys.description('Tags you would like to be applied to Automation Account.')
param parAutomationAccountTags object = parTags

@sys.description('Tags you would like to be applied to Log Analytics Workspace.')
param parLogAnalyticsWorkspaceTags object = parTags

@sys.description('Log Analytics LinkedService name for Automation Account.')
param parLogAnalyticsLinkedServiceAutomationAccountName string = ''

resource resAutomationAccount 'Microsoft.Automation/automationAccounts@2022-08-08' = {
  name: parAutomationAccountName
  location: parAutomationAccountLocation
  tags: parAutomationAccountTags
  identity: parAutomationAccountUseManagedIdentity ? {
    type: 'SystemAssigned'
  } : null
  properties: {
    encryption: {
      keySource: 'Microsoft.Automation'
    }
    publicNetworkAccess: parAutomationAccountPublicNetworkAccess
    sku: {
      name: 'Basic'
    }
  }
}

// Create a resource lock for the automation account if parGlobalResourceLock.kind != 'None' or if parAutomationAccountLock.kind != 'None'
resource resAutomationAccountLock 'Microsoft.Authorization/locks@2020-05-01' = if (parAutomationAccountLock.kind != 'None' || parGlobalResourceLock.kind != 'None') {
  scope: resAutomationAccount
  name: parAutomationAccountLock.?name ?? '${resAutomationAccount.name}-lock'
  properties: {
    level: (parGlobalResourceLock.kind != 'None') ? parGlobalResourceLock.kind : parAutomationAccountLock.kind
    notes: (parGlobalResourceLock.kind != 'None') ? parGlobalResourceLock.?notes : parAutomationAccountLock.?notes
  }
}

resource resLogAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: parLogAnalyticsWorkspaceName
  location: parLogAnalyticsWorkspaceLocation
  tags: parLogAnalyticsWorkspaceTags
  properties: {
    sku: {
      name: parLogAnalyticsWorkspaceSkuName
      capacityReservationLevel: parLogAnalyticsWorkspaceSkuName == 'CapacityReservation' ? parLogAnalyticsWorkspaceCapacityReservationLevel : null
    }
    retentionInDays: parLogAnalyticsWorkspaceLogRetentionInDays
  }
}

// Create a resource lock for the log analytics workspace if parGlobalResourceLock.kind != 'None' or if parLogAnalyticsWorkspaceLock.kind != 'None'
resource resLogAnalyticsWorkspaceLock 'Microsoft.Authorization/locks@2020-05-01' = if (parLogAnalyticsWorkspaceLock.kind != 'None' || parGlobalResourceLock.kind != 'None') {
  scope: resLogAnalyticsWorkspace
  name: parLogAnalyticsWorkspaceLock.?name ?? '${resLogAnalyticsWorkspace.name}-lock'
  properties: {
    level: (parGlobalResourceLock.kind != 'None') ? parGlobalResourceLock.kind : parLogAnalyticsWorkspaceLock.kind
    notes: (parGlobalResourceLock.kind != 'None') ? parGlobalResourceLock.?notes : parLogAnalyticsWorkspaceLock.?notes
  }
}

resource resLogAnalyticsWorkspaceSolutions 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = [for solution in parLogAnalyticsWorkspaceSolutions: {
  name: '${solution}(${resLogAnalyticsWorkspace.name})'
  location: parLogAnalyticsWorkspaceLocation
  tags: parTags
  properties: {
    workspaceResourceId: resLogAnalyticsWorkspace.id
  }
  plan: {
    name: '${solution}(${resLogAnalyticsWorkspace.name})'
    product: 'OMSGallery/${solution}'
    publisher: 'Microsoft'
    promotionCode: ''
  }
}]

// Create a resource lock for each log analytics workspace solutions in parLogAnalyticsWorkspaceSolutions if parGlobalResourceLock.kind != 'None' or if parLogAnalyticsWorkspaceSolutionsLock.kind != 'None'
resource resLogAnalyticsWorkspaceSolutionsLock 'Microsoft.Authorization/locks@2020-05-01' = [for (solution, index) in parLogAnalyticsWorkspaceSolutions: if (parLogAnalyticsWorkspaceSolutionsLock.kind != 'None' || parGlobalResourceLock.kind != 'None') {
  scope: resLogAnalyticsWorkspaceSolutions[index]
  name: parLogAnalyticsWorkspaceSolutionsLock.?name ?? '${resLogAnalyticsWorkspaceSolutions[index].name}-lock'
  properties: {
    level: (parGlobalResourceLock.kind != 'None') ? parGlobalResourceLock.kind : parLogAnalyticsWorkspaceSolutionsLock.kind
    notes: (parGlobalResourceLock.kind != 'None') ? parGlobalResourceLock.?notes : parLogAnalyticsWorkspaceSolutionsLock.?notes
  }
}]

resource resLogAnalyticsLinkedServiceForAutomationAccount 'Microsoft.OperationalInsights/workspaces/linkedServices@2020-08-01' = if (parLogAnalyticsWorkspaceLinkAutomationAccount) {
  parent: resLogAnalyticsWorkspace
  name: parLogAnalyticsLinkedServiceAutomationAccountName
  properties: {
    resourceId: resAutomationAccount.id
  }
}

output outLogAnalyticsWorkspaceName string = resLogAnalyticsWorkspace.name
output outLogAnalyticsWorkspaceId string = resLogAnalyticsWorkspace.id
output outLogAnalyticsCustomerId string = resLogAnalyticsWorkspace.properties.customerId
output outLogAnalyticsSolutions array = parLogAnalyticsWorkspaceSolutions

output outAutomationAccountName string = resAutomationAccount.name
output outAutomationAccountId string = resAutomationAccount.id
