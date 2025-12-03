# Cross-Subscription Networking

This directory contains the infrastructure-as-code for cross-subscription networking resources, including VNet peering and private endpoint configurations across multiple Azure subscriptions.

## What Does This Deploy?

The cross-subscription deployment creates:

- **VNet Peering**: Connects application environment VNets with the managed DevOps pool VNet
- **Private Endpoints**: Establishes private network connectivity for Azure services across subscriptions
- **DevBox Storage Endpoints**: Configures private endpoints for storage accounts in development environments (optional)
- **Data Warehouse Function Endpoints**: Sets up private connectivity to data warehouse function apps (controlled via checkbox parameter)

## Directory Structure

```
6.cross-subscription/
├── main.bicep                    # Main Bicep template
├── main.parameters.bicepparam    # Parameter file with default values
├── modules/                      # Reusable Bicep modules
│   ├── vnetpeering/             # VNet peering module
│   ├── privatenetworking/       # Private endpoint module
│   ├── devbox-storage-endpoints/ # DevBox storage configuration
│   └── dw-function-endpoints/   # Data warehouse function endpoints
├── README.md                     # This file
└── ../.azuredevops/pipelines/
    ├── 6.cross-subscription.yaml # Main pipeline definition
    └── templates/
        └── cross-subscription-deployment-stage.yaml # Reusable stage template
```

## How It Works

### Environment Selection

The pipeline uses an **environment parameter** to control which environment gets deployed. When you run the pipeline, you select an environment from a dropdown:

- `dev` - Development environment
- `systemtest_manual` - Manual testing environment
- `systemtest_auto` - Automated testing environment
- `uat` - User acceptance testing
- `pre_prod` - Pre-production environment
- `production` - Production environment
- `dw` - Data warehouse environment


### Variable Groups

Each environment has its own Azure DevOps variable group named `CrossSubscription-{environment}`. For example:

- `CrossSubscription-dev` for development
- `CrossSubscription-production` for production
- `CrossSubscription-dw` for data warehouse

**Required Variables in Each Group:**
- `location` - Azure region (e.g., `uksouth`)
- `management-group-id` - Management group ID for deployment scope
- `azureServiceConnection` - Azure DevOps service connection name
- `paramvnetPeeringsVNetIDs` - Comma-separated VNet IDs to peer
- `manageddevopspoolVnetID` - Managed DevOps pool VNet ID
- `paramserviceIds` - Comma-separated service resource IDs for private endpoints

**Optional DW Function App Variables** (only if deploying DW private endpoints):
- `dwFunctionAppId` - DW function app resource ID
- `dwFunctionAppSubscriptionId` - Subscription where endpoint should be created
- `dwNetworkingResourceGroup` - Resource group containing target VNet
- `dwVnetName` - Target VNet name
- `dwPrivateEndpointSubnetName` - Target subnet name (usually `snet-pep`)
- `dwEnvironment` - Environment name for resource naming (e.g., `dev`, `preprod`)

**Note**: DevBox storage endpoint configuration (dev only) is managed via the parameter file defaults and doesn't require variable group configuration.

## Running the Pipeline

### Prerequisites

1. **Variable Groups**: Ensure environment-specific variable groups exist in Azure DevOps Library
2. **Service Connections**: Azure DevOps service connections configured for each environment
3. **Permissions**: Pipeline must have access to the variable groups and ability to deploy to management group scope

### Steps to Deploy

1. Navigate to the pipeline in Azure DevOps
2. Click **Run pipeline**
3. **Select environment** from the dropdown (e.g., `dev`, `uat`, `production`)
4. **Check deployment options**:
   - **Deploy DW Function App Private Endpoints**: Check this box only when you need to create/update DW function app private endpoints (typically only on first deployment or when changing DW configuration)
5. Review the **What-If analysis** in the validation stage
6. **Approve** the deployment if changes look correct
7. Monitor the deployment progress

### Pipeline Stages

The pipeline uses a **template-based architecture** following Azure DevOps best practices to avoid code duplication. Each environment has its own dedicated stage for clear visibility in Azure DevOps portal.

**1. PR Validation** (runs on pull requests only)
   - Builds and validates Bicep templates
   - Runs SAST security analysis (Checkov, Template Analyzer)
   - Executes validation and what-if deployments
   - All jobs run in parallel for faster feedback

**2. Environment-Specific Deployment Stages** (runs on manual trigger)

When you select an environment from the dropdown, **only that environment's stage executes**. All other stages are skipped. This provides clear visual indication of which environment is being deployed in the Azure DevOps portal.

Available stages:
- **Deploy to Development** (`dev`)
- **Deploy to System Test (Manual)** (`systemtest_manual`)
- **Deploy to System Test (Auto)** (`systemtest_auto`)
- **Deploy to UAT** (`uat`)
- **Deploy to Pre-Production** (`pre_prod`)
- **Deploy to Production** (`production`)
- **Deploy to Data Warehouse** (`dw`)

Each stage executes the following jobs:
1. **Setup** - Checkout code and install Bicep CLI
2. **FinalWhatIf** - Performs final what-if analysis before deployment
3. **Deploy** - Deploys cross-subscription resources and outputs results

### How Stage Selection Works

The pipeline creates all 7 stages, but **only the selected environment runs**. For example:

- If you select `dev`: Only "Deploy to Development" stage runs, all others are skipped
- If you select `production`: Only "Deploy to Production" stage runs, all others are skipped

## Key Files Explained

### main.bicep

The main Bicep template that orchestrates all cross-subscription resources. It:
- Accepts parameters for VNets, service IDs, and configuration
- Deploys VNet peering between environments
- Creates private endpoints for services
- Conditionally deploys DevBox and data warehouse endpoints

**Key Parameters:**
- `paramvnetPeeringsVNetIDs` - VNet IDs to peer (comma-separated)
- `paramserviceIds` - Service resource IDs for private endpoints (comma-separated)
- `manageddevopspoolVnetID` - Managed DevOps pool VNet ID
- `environment` - Target environment name
- `enableDevBoxStorageEndpoints` - Enable DevBox storage (dev only)
- `deployDwPrivateEndpoints` - Control DW function app private endpoint deployment
- `dwFunctionAppId` - Data warehouse function app ID

### main.parameters.bicepparam

Parameter file with default values. Values are overridden at runtime by the pipeline using variables from the environment-specific variable group.

### Pipeline (.azuredevops/pipelines/6.cross-subscription.yaml)

Azure DevOps pipeline that:
- Provides environment selection dropdown
- Provides checkbox to control DW private endpoint deployment
- Loads environment-specific variable groups
- Validates and deploys Bicep templates
- Runs security scanning (SAST)
- Performs what-if analysis before deployment
- Uses reusable stage templates to eliminate code duplication

**Pipeline Parameters:**
- `env` - Environment selection dropdown (default: `dev`)
  - Options: `dev`, `systemtest_manual`, `systemtest_auto`, `uat`, `pre_prod`, `production`, `dw`
- `deploy_dw_private_endpoints` - Checkbox to control DW function app private endpoint deployment (default: `false`)

**When to check "Deploy DW Function App Private Endpoints":**
- ✅ First deployment to an environment (initial setup)
- ✅ When DW function app configuration changes (new function app, different subscription, etc.)
- ✅ When DW networking configuration changes (VNet, subnet, resource group)
- ❌ Regular deployments for VNet peering or other service private endpoints (keep unchecked)
- ❌ When deploying to `dw` environment (no DW endpoints needed for DW itself)

### Pipeline Template (.azuredevops/pipelines/templates/cross-subscription-deployment-stage.yaml)

Reusable stage template that defines the deployment logic for all environments. This follows Azure DevOps best practices by:
- Defining deployment logic once (setup, what-if, deploy jobs)
- Accepting parameters for environment-specific values
- Being invoked once per environment with different parameters
- Eliminating code duplication across stages

**Template Parameters:**
- `environmentName` - Target environment name (e.g., `dev`, `uat`)
- `displayName` - Stage display name in Azure DevOps UI
- `deployDwPrivateEndpoints` - Boolean flag for DW endpoint deployment
- `selectedEnvironment` - User-selected environment from dropdown

The template automatically:
- Loads correct variable group (`CrossSubscription-{environmentName}`)
- Runs only when selected environment matches stage environment
- Executes setup, what-if, and deployment jobs in sequence
- Outputs deployment results with full Bicep output

## Best Practices

### Deployment Best Practices
1. **Test in Dev First**: Always test changes in the dev environment before deploying to production
2. **Review What-If**: Carefully review what-if analysis output before approving deployments
3. **Single Environment Deployment**: The pipeline deploys to only the selected environment - verify you've selected the correct one
4. **Monitor Deployments**: Watch deployment logs for errors or warnings in the Azure DevOps portal
5. **Use DW Checkbox Wisely**: Only check "Deploy DW Private Endpoints" when necessary to avoid unnecessary deployments

