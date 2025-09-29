# Azure Monitor Alert Rules for Azure Landing Zone

This module deploys Azure Monitor Alert Rules for Security Operations, Policy Operations, and Administrative Operations across Azure subscriptions.

## Overview

The monitoring alerts deployment creates:

- **Action Groups**: Email notification groups for different alert categories
- **Activity Log Alerts**: Subscription-level alerts for critical operations
- **Scalable Architecture**: Easily add new alert rules and notification channels

## Architecture

```
2.monitoring-alerts/
├── main.bicep                          # Main orchestration template
├── modules/
│   ├── action-groups.bicep             # Action group deployment
│   └── alert-rules.bicep               # Alert rules deployment
├── parameters/
│   ├── dev.parameters.bicepparam       # Development environment
│   ├── prod.parameters.bicepparam      # Production environment
│   └── shared.parameters.bicepparam    # Shared services environment
└── README.md                           # This file

shared/bicep/monitoring/                 # Reusable modules
├── action-group.bicep                  # Single action group module
├── activity-log-alert.bicep            # Activity log alert module
└── scheduled-query-rule.bicep          # KQL-based alert module
```

## Deployment

### Prerequisites

1. **Log Analytics Workspace**: Must exist and be accessible
2. **Subscription Access**: Contributor or Owner role on target subscription
3. **Email Addresses**: Valid email addresses for notifications

### Quick Start

1. **Update Parameters**: Edit the parameter file for your environment:
   ```bicep
   // Update Log Analytics workspace ID
   param logAnalyticsWorkspaceId = '/subscriptions/{your-subscription-id}/resourceGroups/{resource-group}/providers/Microsoft.OperationalInsights/workspaces/{workspace-name}'
   
   // Configure email recipients
   param securityEmailRecipients = [
     {
       name: 'Security Team'
       address: 'security@yourorg.com'
       useCommonAlertSchema: true
     }
   ]
   ```

2. **Deploy to Subscription**:
   ```bash
   az deployment sub create \
     --location uksouth \
     --template-file ./2.monitoring-alerts/main.bicep \
     --parameters ./2.monitoring-alerts/parameters/dev.parameters.bicepparam
   ```

### Environment-Specific Deployment

**Development Environment:**
```bash
az deployment sub create \
  --location uksouth \
  --template-file ./2.monitoring-alerts/main.bicep \
  --parameters ./2.monitoring-alerts/parameters/dev.parameters.bicepparam
```

**Production Environment:**
```bash
az deployment sub create \
  --location uksouth \
  --template-file ./2.monitoring-alerts/main.bicep \
  --parameters ./2.monitoring-alerts/parameters/prod.parameters.bicepparam
```

## Configuration

### Alert Severity Levels

The deployment only creates alerts for Critical, Error, and Warning levels:

```bicep
param alertSeverityLevels = [0, 1, 2]  // Critical, Error, Warning
```

### Enabling/Disabling Alert Categories

Control which alert categories are deployed:

```bicep
param enableSecurityAlerts = true
param enablePolicyAlerts = true  
param enableAdminAlerts = true
```

## Extending the Solution

### Adding New Alert Rules

1. **Edit alert-rules.bicep**: Add new module calls for additional alert rules
2. **Update alertRuleNames**: Add new alert rule names to the variable
3. **Configure Parameters**: Add any new parameters needed

Example:
```bicep
// Add to alertRuleNames variable
var alertRuleNames = {
  security: {
    // existing rules...
    customSecurityAlert: '${namingPrefix}-custom-security-alert'
  }
}

// Add new module
module customSecurityAlert '../../shared/bicep/monitoring/activity-log-alert.bicep' = {
  name: 'deploy-custom-security-alert'
  params: {
    alertRuleName: alertRuleNames.security.customSecurityAlert
    displayName: 'Custom Security Alert'
    description: 'Custom security alert description'
    // ... other parameters
  }
}
```

### Adding New Notification Channels

The action group module supports multiple notification types:

- **Email**: Already configured
- **SMS**: Add `smsRecipients` parameter
- **Webhooks**: Add `webhookRecipients` parameter  
- **Azure Functions**: Add `azureFunctionRecipients` parameter
- **Logic Apps**: Add `logicAppRecipients` parameter

Example SMS configuration:
```bicep
param smsRecipients = [
  {
    name: 'On-Call Engineer'
    countryCode: '44'
    phoneNumber: '1234567890'
  }
]
```

### Creating Environment-Specific Rules

Create new parameter files for additional environments:

1. **Copy existing parameter file**: `cp dev.parameters.bicepparam test.parameters.bicepparam`
2. **Update environment-specific values**: Modify emails, resource names, etc.
3. **Deploy**: Use the new parameter file for deployment

## Monitoring and Maintenance

### Updating Email Recipients

To update email recipients without redeploying:

1. **Update parameter file**: Modify email addresses in the parameter file
2. **Redeploy**: Run the deployment command again
3. **Verify**: Check that action groups were updated
