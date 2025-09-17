# Azure Bicep Deployment Repository

This repository contains Azure Bicep templates and Azure DevOps pipelines for deploying and managing Azure resources. The structure is organized to support modular and reusable infrastructure as code (IaC) components.

## Repository Structure

```
.env
README.md
.azuredevops/
    pipelines/
        1.core-services.yaml
        3.sub-placement.yaml
        alz-bicep-pr1-build.yml
        alz-bicep-pr2-lint.yml
        application-deployment.yml
        network-deployment.yml
1.core-services
    main.bicep
    modules/
        logging.bicep
        managementGroups.bicep
        diagnostics/
3.sub-placement
    main.bicep
    modules/
        subPlacementsAll.bicep
5.spoke-network
    main.application.bicep
    main.network.bicep
    README.md
    app-parameters/
    modules/
        network-parameters/
shared/
    bicep/
```

### Key Directories and Files

- **`.azuredevops/pipelines/`**: Contains Azure DevOps pipeline YAML files for CI/CD processes.
  - `alz-bicep-pr1-build.yml`: Pipeline for building Bicep templates.
  - `alz-bicep-pr2-lint.yml`: Pipeline for linting Bicep templates.
  - `application-deployment.yml`: Pipeline for deploying application resources.
  - `network-deployment.yml`: Pipeline for deploying network resources.

- **`1.core-services/`**: Contains Bicep templates for core services.
  - `main.bicep`: Entry point for core services deployment.
  - `modules/`: Submodules for specific core services, such as logging and management groups.

- **`3.sub-placement/`**: Contains Bicep templates for subscription placement.
  - `main.bicep`: Entry point for subscription placement deployment.
  - `modules/`: Submodules for subscription placement logic.

- **`5.spoke-network/`**: Contains Bicep templates for spoke network deployments.
  - `main.application.bicep`: Entry point for application-related resources including web apps, container apps, function apps, and databases.
  - `main.network.bicep`: Entry point for network-related resources.
  - `modules/`: Submodules for network parameters.

- **`shared/bicep/`**: Shared Bicep modules for reuse across deployments.

## Getting Started

### Prerequisites

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Bicep CLI](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install)
- [Azure DevOps](https://azure.microsoft.com/en-us/services/devops/) account for pipeline execution.

### Deployment Steps

1. Clone the repository:
   ```sh
   git clone <repository-url>
   cd <repository-directory>
   ```

2. Authenticate with Azure:
   ```sh
   az login
   ```

3. Deploy a specific Bicep template:
   ```sh
   az deployment group create --resource-group <resource-group-name> --template-file <path-to-bicep-file>
   ```

### Running Pipelines

Azure DevOps pipelines are defined in the `.azuredevops/pipelines/` directory. To run a pipeline:

Pipelines are triggered automatically upon raising the PR and when the PR is merged into main branch. By default, the pipelines are executed against the Dev environment.

To run the pipeline manually to run against a different environment
1. Navigate to your Azure DevOps project.
2. Select the pipeline and click Run Pipeline
3. Select the environment from the drop down
4. Click Run

## Defender for Storage Implementation

This repository implements Microsoft Defender for Storage with malware scanning and automated response capabilities.

### Architecture Overview
- **Subscription Level**: Basic protection (Activity Monitoring) with malware scanning disabled by default
- **Storage Account Level**: Enhanced protection (Malware Scanning) enabled selectively with account-specific overrides
- **Event Response**: Custom Event Grid Topic + Function Apps for automated file quarantine/approval
- **Logging**: Scan results sent to Log Analytics for compliance

### Deployment Strategy

Defender for Storage uses a two-step deployment approach to avoid Event Grid webhook validation issues:

**Step 1 - Infrastructure Deployment:**
- Deploy with `enableEventGridSubscriptions: false` (default)
- Creates Function App infrastructure, Custom Event Grid Topic, and Storage Account with Defender
- No Event Grid subscriptions created (avoids webhook validation failure)

**Step 2 - Event Grid Subscriptions:**
- Deploy Function App code to make webhook endpoint operational
- Change `enableEventGridSubscriptions: true` in main template
- Redeploy to create Event Grid subscriptions with successful webhook validation
- Complete end-to-end malware scanning workflow becomes operational

This approach follows Infrastructure as Code best practices with clean separation between infrastructure and application deployment phases.

## Front Door Configuration

### Private Link Approval Process

When Front Door private link is enabled, the private endpoint connection requires manual approval:

#### Step 1: Navigate to App Service
1. Go to **Azure Portal** (https://portal.azure.com)
2. Search for your App Service: `irasportal-{environment}` 
3. Select your IRAS Portal App Service

#### Step 2: Access Private Endpoint Settings
1. In the left sidebar, click **Settings** → **Networking**
2. Look for **"Private endpoint connections"** section
3. Click **"Configure your private endpoint connections"**

#### Step 3: Approve the Connection
1. You'll see a **pending connection** from Azure Front Door Premium
2. Status will show **"Pending"** with a request from Microsoft/Front Door
3. **Select the pending connection**
4. Click **"Approve"** button
5. Optionally add an approval message
6. Click **"OK"** or **"Save"**

#### Step 4: Wait for Propagation
1. Status changes to **"Approved"** then **"Connected"**
2. **Wait 3-5 minutes** for Azure to propagate the connection
3. Re-deploy if the initial deployment failed due to pending approval

### Configuration

#### Enable Event Grid Subscriptions
To enable Event Grid subscriptions after Function App code deployment:

1. Update the parameter in `5.spoke-network/main.application.bicep`:
   ```bicep
   enableEventGridSubscriptions: true  // Change from false to true
   ```

2. Redeploy the infrastructure:
   ```sh
   az deployment sub create --location uksouth \
     --template-file ./5.spoke-network/main.application.bicep \
     --parameters ./5.spoke-network/app-parameters/dev.parameters.bicepparam
   ```

#### Disable Blob Index Tags (Cost Optimization)
Blob index tags are enabled by default when malware scanning is enabled. To disable them for cost optimization:

1. **Via Azure Portal:**
   - Navigate to Storage Account → Security + Networking → Microsoft Defender for Cloud
   - Click "Settings"
   - Uncheck "Store scan results as Blob Index Tags"
   - Click "Save"

2. **Via REST API:**
   ```bash
   # Note: Specific blob index tags disable property may vary by API version
   # Check current Azure documentation for exact property names
   ```

**Important:** Event Grid integration works independently of blob index tags and will continue to function normally when blob index tags are disabled.

#### Configure Event Grid Topic for Scan Results (Manual Portal Configuration Required)
While the custom Event Grid topic is created via Bicep templates, the "Send scan results to Event Grid topic" setting must be configured manually:

1. **Via Azure Portal:**
   - Navigate to Storage Account → Security + Networking → Microsoft Defender for Cloud
   - Click "Settings"
   - In the "Event Grid custom topic" section, select your custom Event Grid topic
   - Click "Save"

**Note:** The Bicep API does not currently support setting the `scanResultsEventGridTopicResourceId` property, so this configuration must be done post-deployment through the Azure Portal.

## Application Infrastructure

The repository deploys a comprehensive application infrastructure including:

### Web Applications
- **IRAS Portal**: Main web application (`irasportal-${environment}`)
- **Container Apps**: Microservices architecture with dedicated container apps for:
  - IRAS Service (`irasservice`)
  - User Management Service (`usermanagementservice`)
  - RTS Service (`rtsservice`)

### Function Apps
- **Process Scan Function**: Handles malware scanning events and file quarantine/approval (`func-process-scan-${environment}`)
- **RTS Data Sync Function**: Synchronizes RTS data with external systems (`func-rts-data-sync-${environment}`)
- **Notification Function**: Handles notification processing (`func-notify-${environment}`)
- **Document Upload API Function**: Provides .NET API endpoints for document upload processing (`func-document-upload-api-${environment}`)

### Database Infrastructure
- **SQL Server**: Centralized database server with Azure AD authentication
- **Databases**: Multiple databases for different services:
  - `applicationservice`
  - `identityservice`
  - `rtsservice`

### Shared Services
- **Azure App Configuration**: Centralized configuration management
- **Azure Container Registry**: Container image storage
- **Key Vault**: Secrets and certificate management
- **Log Analytics**: Centralized logging and monitoring
- **Application Insights**: Application performance monitoring

### Network Architecture
- **VNet Integration**: All services are connected to the spoke virtual network
- **Private Endpoints**: Database and storage services use private endpoints for secure connectivity
- **Subnet Segmentation**: Dedicated subnets for different service types:
  - `snet-webapp`: Web applications and function apps
  - `snet-pep`: Private endpoints
  - `snet-infra`: Infrastructure services

### Security Features
- **Managed Identity**: All services use Azure AD managed identities for authentication
- **Private Networking**: Database and storage services are accessible only through private endpoints
- **Microsoft Defender**: Advanced threat protection enabled for storage accounts
- **Audit Logging**: SQL Server auditing enabled with Log Analytics integration

### Development and Deployment
- **Infrastructure as Code**: Complete infrastructure defined in Bicep templates
- **Environment Support**: Multi-environment deployment support (dev, test, prod)
- **CI/CD Integration**: Azure DevOps pipelines for automated deployment
- **Modular Design**: Reusable Bicep modules for consistent deployments

## Contributing

Contributions are welcome! Please follow these steps:
1. Fork the repository.
2. Create a feature branch.
3. Submit a pull request.

## License

This project is licensed under the [MIT License](LICENSE).

## Contact

For questions or support, please contact the repository maintainers.
```