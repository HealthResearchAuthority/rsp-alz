# Azure Monitor Alert Rules for Azure Landing Zone

This module deploys Azure Monitor Alert Rules for Security Operations, Policy Operations, and Administrative Operations across Azure subscriptions.

## Overview

The monitoring alerts deployment creates:

- **Action Groups**: Email notification groups for different alert categories
- **Activity Log Alerts**: Subscription-level alerts for critical operations
- **Scalable Architecture**: Easily add new alert rules and notification channels

## Alert Categories

### 🔒 Security Operations Alerts
- Microsoft Defender for Cloud alerts
- Key Vault access and modification events
- Storage account security configuration changes
- Network Security Group rule modifications

### 📋 Policy Operations Alerts
- Azure Policy assignment changes
- Policy compliance state changes
- Policy exemption creation or modification

### ⚙️ Administrative Operations Alerts
- Resource group creation, modification, or deletion
- RBAC role assignment changes
- Subscription-level configuration changes

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

### Email Recipients Configuration

Configure different email groups for each alert category:

```bicep
param securityEmailRecipients = [
  {
    name: 'Security Team'
    address: 'security@yourorg.com'
    useCommonAlertSchema: true
  }
]

param policyEmailRecipients = [
  {
    name: 'Governance Team'  
    address: 'governance@yourorg.com'
    useCommonAlertSchema: true
  }
]

param adminEmailRecipients = [
  {
    name: 'Platform Team'
    address: 'platform@yourorg.com'
    useCommonAlertSchema: true
  }
]
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

### Verify Deployment

Check that resources were created successfully:

```bash
# List action groups
az monitor action-group list --resource-group rg-hra-dev-monitoring-alerts

# List activity log alerts  
az monitor activity-log alert list --resource-group rg-hra-dev-monitoring-alerts
```

### Test Notifications

Trigger a test alert to verify email delivery:

```bash
# Create a test resource group to trigger administrative alert
az group create --name test-alert-rg --location uksouth

# Delete the test resource group
az group delete --name test-alert-rg --yes --no-wait
```

### Updating Email Recipients

To update email recipients without redeploying:

1. **Update parameter file**: Modify email addresses in the parameter file
2. **Redeploy**: Run the deployment command again
3. **Verify**: Check that action groups were updated

## Troubleshooting

### Common Issues

**1. Log Analytics Workspace Not Found**
- Verify the workspace resource ID is correct
- Ensure the workspace exists in the specified subscription/resource group

**2. Insufficient Permissions**
- Ensure you have Contributor or Owner role on the subscription
- Check that the deployment identity has required permissions

**3. Email Notifications Not Received**
- Verify email addresses are correct
- Check spam/junk folders
- Confirm action groups are enabled

**4. Alert Rules Not Triggering**
- Verify alert rules are enabled
- Check that the monitored operations are occurring
- Review activity logs for the specific operations

### Validation

Use Azure Resource Graph to query deployed resources:

```kql
resources
| where type == "microsoft.insights/actiongroups" or type == "microsoft.insights/activitylogalerts"
| where resourceGroup startswith "rg-hra"
| project name, type, location, resourceGroup
```

## Cost Considerations

- **Action Groups**: No direct cost, charged per notification sent
- **Activity Log Alerts**: No cost for the rules themselves
- **Notifications**: Email notifications are free, SMS and voice calls incur charges

## Security Considerations

- **Email Security**: Use organizational email addresses only
- **Access Control**: Limit who can modify alert rules and action groups  
- **Sensitive Data**: Avoid including sensitive information in alert descriptions
- **Review Recipients**: Regularly review and update notification recipients

## Support

For questions or issues:

1. **Review Logs**: Check Azure Activity Log for deployment errors
2. **Validate Configuration**: Ensure parameter files are correctly configured
3. **Test Incrementally**: Deploy to development environment first
4. **Documentation**: Refer to [Azure Monitor documentation](https://docs.microsoft.com/en-us/azure/azure-monitor/)
