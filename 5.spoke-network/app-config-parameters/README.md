# App Configuration Parameters

Environment-specific parameter files for updating Azure App Configuration without redeploying the full landing zone.

## Quick Start

1. **Edit parameter file** for your environment (e.g., `dev.parameters.bicepparam`)
2. **Add/update key-values** in the `parAppConfigurationValues` array
3. **Create PR** for review
4. **Run pipeline**: `.azuredevops/pipelines/appconfig-update.yml`


---

## Parameter File Structure

```bicep
using '../main.appconfig-update.bicep'

param parEnvironment = 'dev'
param parSharedServicesSubscriptionId = '<subscription-id>'
param parSharedServicesResourceGroup = 'rg-rsp-sharedservices-spoke-dev-uks'
param parAppConfigurationStoreName = 'appcs-rsp-shared-xxxxx-dev-uks'

param parAppConfigurationValues = [
  {
    key: 'AppSettings:RtsApiBaseUrl'
    label: ''              // Empty string = no label
    value: 'https://api.example.com'
    contentType: null      // Usually null
  }
]
```

---

## Key-Value Properties

| Property | Required | Description | Example |
|----------|----------|-------------|---------|
| `key` | Yes | Configuration key | `'AppSettings:RtsApiBaseUrl'` |
| `label` | No | Optional label (empty = null label) | `'portal'` or `''` |
| `value` | Yes | Configuration value (always string) | `'https://api.example.com'` |
| `contentType` | No | MIME type (usually null) | `null` or `'text/plain'` |

**Label Convention:** In Azure portal, labeled keys appear as `key$label` (e.g., `AppSettings:Timeout$portal`)

---

## Common Examples

### Update API URL
```bicep
{
  key: 'AppSettings:RtsApiBaseUrl'
  label: ''
  value: 'https://api-rts-dev.example.com'
  contentType: null
}
```

### Update Timeout with Label
```bicep
{
  key: 'AppSettings:SessionTimeout'
  label: 'portal'
  value: '3600'
  contentType: null
}
```

### Key Vault Reference
```bicep
{
  key: 'AppSettings:ApiSecret'
  label: ''
  value: '{"uri":"https://kv-name.vault.azure.net/secrets/apiSecret"}'
  contentType: 'application/vnd.microsoft.appconfig.keyvaultref+json;charset=utf-8'
}
```

---

## Environment Setup

Before first use, update each parameter file with actual values:

```bash
# Find subscription ID
az account list --query "[].{Name:name, ID:id}" -o table

# Find App Config store name
az appconfig list --resource-group rg-rsp-sharedservices-spoke-<env>-uks --query "[0].name" -o tsv
```

---

## Security

- ❌ **Never commit secrets** (passwords, API keys, etc.)
- ✅ Use Key Vault references for sensitive values
- ✅ Use Azure DevOps variable groups for secrets passed during deployment

---

## Troubleshooting

**Apps not picking up changes?**
- Wait 30 seconds (default refresh interval)
- Check Application Insights for refresh logs

**Deployment fails with "store not found"?**
- Verify `parAppConfigurationStoreName` matches actual resource name
- Run: `az appconfig list --resource-group <rg-name> --query "[0].name" -o tsv`

**Need to force app refresh?**
- Update sentinel value: `AppSettings:Sentinel$portal` (increment number)

---

## Pipeline

**Pipeline:** `.azuredevops/pipelines/appconfig-update.yml`

**Parameters:**
- `env` - Environment (dev, uat, production, etc.)
- `app_config_variable_group` - Optional variable group for secrets
- `location` - Deployment location (default: uksouth)

**Stages:**
1. **PR Validation** - Lint, validate, what-if (runs on PR)
2. **Manual Deployment** - Actual deployment (post-merge, requires approval)
