# Key Vault Secret Management

Environment-specific parameter files for updating Azure Key Vault secrets without redeploying the full landing zone.

## Quick Start

1. **Add/update secrets** in Azure DevOps variable group (`{env}-key-vault`)
2. **Update secret list** in `{env}.secrets.json` if adding new secrets
3. **Create PR** for review
4. **Run pipeline**: `.azuredevops/pipelines/keyvault-update.yml`

---

## File Structure

Each environment has two files:

```
keyvault-parameters/
├── dev.parameters.bicepparam       # Bicep parameters (subscription, resource group, Key Vault name)
├── dev.secrets.json                # Secret definitions (name, optional contentType/variableName)
├── systemtest_manual.parameters.bicepparam
├── systemtest_manual.secrets.json
... (repeated for each environment)
```

---

## Parameter File Structure

**{env}.parameters.bicepparam:**
```bicep
using '../main.keyvault-update.bicep'

param parSharedServicesSubscriptionId = '<subscription-id>'
param parSharedServicesResourceGroup = 'rg-rsp-sharedservices-spoke-{env}-uks'
param parKeyVaultName = 'kv-rsp-shared-xxxxx-{env}-uks'
param parKeyVaultSecrets = loadJsonContent('./{env}.secrets.json')
```

**{env}.secrets.json:**
```json
[
  { "name": "oneLoginClientId" },
  { "name": "rtsApiClientSecret" }
]
```

---

## Secret Definition Properties

| Property | Required | Description | Example |
|----------|----------|-------------|---------|
| `name` | Yes | Secret name in Key Vault | `"rtsApiClientSecret"` |
| `variableName` | No | Variable name in ADO variable group (defaults to `name`) | `"RTS_API_SECRET"` |
| `contentType` | No | MIME type (usually omit for plain text) | `"text/plain"` |

**Default Behavior:**
- If `variableName` is omitted, uses `name` to look up variable in ADO variable group
- If `contentType` is omitted, Key Vault uses default behavior (no content type)

---

## Common Examples

### Simple Secret (Default)
```json
{ "name": "rtsApiClientSecret" }
```
Looks for variable `rtsApiClientSecret` in ADO variable group `{env}-key-vault`.

### Secret with Different Variable Name
```json
{
  "name": "api-secret",
  "variableName": "API_SECRET"
}
```
Secret stored as `api-secret` in Key Vault, but reads from variable `API_SECRET` in ADO.

### Key Vault Reference (Advanced)
```json
{
  "name": "sqlConnectionString",
  "contentType": "application/vnd.microsoft.appconfig.keyvaultref+json;charset=utf-8"
}
```

---

## Azure DevOps Variable Groups

**Required Variable Groups:**

Each environment needs a variable group named `{env}-key-vault` containing secret values:

- `dev-key-vault`
- `systemtest_manual-key-vault`
- `systemtest_auto-key-vault`
- `uat-key-vault`
- `pre_prod-key-vault`
- `production-key-vault`

**Variable Group Setup:**
1. Navigate to Azure DevOps → Pipelines → Library
2. Create variable group with naming convention `{env}-key-vault`
3. Add variables matching secret names in `.secrets.json`
4. Mark each variable as **secret** (lock icon)

**Example** (`dev-key-vault`):
```
oneLoginClientId (secret)
oneLoginPrivateKeyPem (secret)
rtsApiClientId (secret)
rtsApiClientSecret (secret)
...
```

---

## Pipeline

**Pipeline:** `.azuredevops/pipelines/keyvault-update.yml`

**Parameters:**
- `env` - Environment (dev, uat, production, etc.) - **Automatically uses `{env}-key-vault` variable group**
- `location` - Deployment location (default: uksouth)

**Variable Group Resolution:**
The pipeline automatically uses the variable group named `{env}-key-vault` based on the selected environment:
- Select `dev` → Uses `dev-key-vault`
- Select `uat` → Uses `uat-key-vault`
- Select `production` → Uses `production-key-vault`

**Stages:**
1. **PR Validation** - Lint, validate, what-if (runs on PR)
2. **Manual Deployment** - Actual deployment (post-merge, requires approval)

---

## Workflow

### Adding New Secrets

1. **Add to ADO variable group** (`{env}-key-vault`):
   - Library → Variable Group → Add variable
   - Mark as secret

2. **Update `.secrets.json`**:
   ```json
   { "name": "newSecretName" }
   ```

3. **Update pipeline YAML** (`.azuredevops/pipelines/keyvault-update.yml`):
   - Add the new secret to the `env:` section in **all three bash tasks** (validate job, preview job, deploy job)
   - Find sections with `displayName: 'Prepare Key Vault secret values'`
   - Add your new environment variable mapping:
   ```yaml
   env:
     oneLoginClientId: $(oneLoginClientId)
     # ... existing mappings ...
     newSecretName: $(newSecretName)  # Add this line
   ```

4. **Create PR** for review

5. **Run pipeline** after merge

### Updating Existing Secrets

1. **Update value in ADO variable group** (`{env}-key-vault`)

2. **Run pipeline** (no code changes needed)

---

## Security

- ✅ All secrets marked with `@secure()` in Bicep
- ✅ Secrets never stored in git (only names)
- ✅ Secrets passed at runtime from ADO variable groups
- ✅ Variable groups secured with RBAC
- ✅ Secrets never logged in pipeline output

---

## Troubleshooting

**Pipeline fails with "secret value not found"?**
- Verify variable exists in ADO variable group
- Check variable name matches `variableName` (or `name` if `variableName` omitted)
- Ensure variable is marked as secret in ADO

**Need to use different variable group?**
- Set `keyvault_variable_group` parameter to specific group name
- Default `auto` uses `{env}-key-vault`

**Key Vault not found?**
- Verify `parKeyVaultName` in `.parameters.bicepparam` matches actual Key Vault
- Run: `az keyvault list --resource-group <rg-name> --query "[].name" -o tsv`

---

## Python Script

**Location:** `.azuredevops/scripts/build-kv-secret-values.py`

**Purpose:** Builds JSON object of secret values from environment variables (populated by ADO variable group)

**Usage:**
```bash
python3 build-kv-secret-values.py <secrets.json> <output.json>
```

**Input:** Manifest file (`.secrets.json`) with secret definitions
**Output:** JSON object `{ "secretName": "secretValue", ... }`

The script reads environment variables using the `variableName` (or `name` if not specified) and creates a secure JSON object passed to Bicep deployment.
