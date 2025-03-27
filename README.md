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
  - `main.application.bicep`: Entry point for application-related resources.
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