targetScope = 'resourceGroup'

metadata name = 'ALZ Bicep - Action Groups Deployment'
metadata description = 'Module used to deploy multiple Action Groups for different alert categories'

// ------------------
// PARAMETERS
// ------------------

@description('Action group names for different categories')
param actionGroupNames object

@description('Email recipients for security alerts')
param securityEmailRecipients array = []

@description('Email recipients for policy alerts')
param policyEmailRecipients array = []

@description('Email recipients for administrative alerts')
param adminEmailRecipients array = []

@description('Environment name')
param environment string

@description('Tags to apply to all resources')
param tags object = {}

// ------------------
// VARIABLES
// ------------------

var defaultTags = union(tags, {
  Environment: environment
  Purpose: 'Monitoring Alerts'
})

// ------------------
// RESOURCES
// ------------------

// Security Action Group
module securityActionGroup '../../shared/bicep/monitoring/action-group.bicep' = if (!empty(securityEmailRecipients)) {
  name: 'deploy-security-action-group'
  params: {
    actionGroupName: actionGroupNames.security
    shortName: 'SecOpsAlert'
    emailRecipients: securityEmailRecipients
    enabled: true
    tags: defaultTags
  }
}

// Policy Action Group
module policyActionGroup '../../shared/bicep/monitoring/action-group.bicep' = if (!empty(policyEmailRecipients)) {
  name: 'deploy-policy-action-group'
  params: {
    actionGroupName: actionGroupNames.policy
    shortName: 'PolicyAlert'
    emailRecipients: policyEmailRecipients
    enabled: true
    tags: defaultTags
  }
}

// Administrative Action Group
module adminActionGroup '../../shared/bicep/monitoring/action-group.bicep' = if (!empty(adminEmailRecipients)) {
  name: 'deploy-admin-action-group'
  params: {
    actionGroupName: actionGroupNames.admin
    shortName: 'AdminAlert'
    emailRecipients: adminEmailRecipients
    enabled: true
    tags: defaultTags
  }
}

// ------------------
// OUTPUTS
// ------------------

@description('Action group resource IDs and information')
output actionGroups object = {
  security: !empty(securityEmailRecipients) ? {
    id: securityActionGroup.outputs.actionGroupId
    name: securityActionGroup.outputs.actionGroupName
  } : {}
  policy: !empty(policyEmailRecipients) ? {
    id: policyActionGroup.outputs.actionGroupId
    name: policyActionGroup.outputs.actionGroupName
  } : {}
  admin: !empty(adminEmailRecipients) ? {
    id: adminActionGroup.outputs.actionGroupId
    name: adminActionGroup.outputs.actionGroupName
  } : {}
}
