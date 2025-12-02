# Cross-Subscription Networking

This directory contains the infrastructure-as-code for cross-subscription networking resources, including VNet peering and private endpoint configurations across multiple Azure subscriptions.

## What Does This Deploy?

The cross-subscription deployment creates:

- **VNet Peering**: Connects application environment VNets with the managed DevOps pool VNet
- **Private Endpoints**: Establishes private network connectivity for Azure services across subscriptions
- **DevBox Storage Endpoints**: Configures private endpoints for storage accounts in development environments (optional)
- **Data Warehouse Function Endpoints**: Sets up private connectivity to data warehouse function apps

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
└── README.md                     # This file
```

## How It Works

### Environment Selection

The pipeline uses an **environment parameter** to control which environment gets deployed. When you run the pipeline, you select an environment from a dropdown:

- `dev` - Development environment
- `systemtest_manual` - Manual testing environment
- `systemtest_auto` - Automated testing environment
- `systemtest_int` - Integration testing environment
- `uat` - User acceptance testing
- `pre_prod` - Pre-production environment
- `production` - Production environment
- `dw` - Data warehouse environment


### Variable Groups

Each environment has its own Azure DevOps variable group named `CrossSubscription-{environment}`. For example:

- `CrossSubscription-dev` for development
- `CrossSubscription-production` for production
- `CrossSubscription-dw` for data warehouse

These variable groups contain environment-specific configuration like:
- VNet resource IDs to peer
- Service resource IDs for private endpoints
- Azure service connection names
- DevBox configuration (dev only)

## Running the Pipeline

### Prerequisites

1. **Variable Groups**: Ensure environment-specific variable groups exist in Azure DevOps Library
2. **Service Connections**: Azure DevOps service connections configured for each environment
3. **Permissions**: Pipeline must have access to the variable groups and ability to deploy to management group scope

### Steps to Deploy

1. Navigate to the pipeline in Azure DevOps
2. Click **Run pipeline**
3. **Select environment** from the dropdown (e.g., `dev`, `uat`, `production`)
4. Review the **What-If analysis** in the validation stage
5. **Approve** the deployment if changes look correct
6. Monitor the deployment progress

### Pipeline Stages

1. **PR Validation** (runs on pull requests)
   - Builds and validates Bicep templates
   - Runs SAST security analysis
   - Executes validation and what-if deployments

2. **Manual Deployment** (runs on manual trigger)
   - Performs final what-if analysis
   - Deploys cross-subscription resources
   - Outputs deployment results

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
- `dwFunctionAppId` - Data warehouse function app ID

### main.parameters.bicepparam

Parameter file with default values. Values are overridden at runtime by the pipeline using variables from the environment-specific variable group.

### Pipeline (.azuredevops/pipelines/6.cross-subscription.yaml)

Azure DevOps pipeline that:
- Provides environment selection dropdown
- Loads environment-specific variable groups
- Validates and deploys Bicep templates
- Runs security scanning (SAST)
- Performs what-if analysis before deployment

## Best Practices

1. **Test in Dev First**: Always test changes in the dev environment before deploying to production
2. **Review What-If**: Carefully review what-if analysis output before approving deployments
3. **Use Descriptive Service IDs**: Organize service IDs logically in the variable group
4. **Document Changes**: Update variable groups and this README when adding new resources
5. **Monitor Deployments**: Watch deployment logs for errors or warnings
6. **Keep Groups Updated**: Regularly review and update variable group values

## Additional Resources

- [Azure Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [VNet Peering Overview](https://learn.microsoft.com/azure/virtual-network/virtual-network-peering-overview)
- [Private Endpoints](https://learn.microsoft.com/azure/private-link/private-endpoint-overview)
- [Azure DevOps Variable Groups](https://learn.microsoft.com/azure/devops/pipelines/library/variable-groups)
