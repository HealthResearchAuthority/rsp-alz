# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

This is the **Revenue Scotland Portal (RSP) Azure Landing Zone** - a multi-tier application infrastructure following Azure Landing Zone architecture patterns with hub-and-spoke network topology.

### Core Structure
- **1.core-services/**: Management groups, logging, and core Azure services
- **3.sub-placement/**: Subscription placement and organizational structure  
- **5.spoke-network/**: Main application workload (PRIMARY FOCUS)
- **shared/bicep/**: Reusable Bicep modules for all deployments

### Key Application Components
The spoke network deploys a microservices architecture with:
- **Container Apps**: IRAS Service, User Management, Question Set, RTS Service
- **App Services**: IRAS Portal (Linux), RTS Data Sync Function, Notify Function, Malware Function
- **Data Layer**: SQL Server with private endpoints, Document Upload Storage
- **Supporting**: App Configuration, Key Vault, Container Registry, Application Insights

## Development Commands

### Bicep Development
```bash
# Lint and build Bicep templates
az bicep build --file ./5.spoke-network/main.application.bicep
az bicep build --file ./5.spoke-network/main.network.bicep

# Validate deployments
az deployment sub validate --location uksouth \
  --template-file ./5.spoke-network/main.application.bicep \
  --parameters ./5.spoke-network/app-parameters/dev.parameters.bicepparam

# Preview changes (What-If)
az deployment sub what-if --location uksouth \
  --template-file ./5.spoke-network/main.application.bicep \
  --parameters ./5.spoke-network/app-parameters/dev.parameters.bicepparam

# Deploy to subscription
az deployment sub create --location uksouth \
  --template-file ./5.spoke-network/main.application.bicep \
  --parameters ./5.spoke-network/app-parameters/dev.parameters.bicepparam
```

### Environment-Specific Deployments
Parameter files exist for 7 environments: `dev`, `systemtest_manual`, `systemtest_auto`, `systemtest_int`, `uat`, `pre_prod`, `production`, `shared`

## Key Architectural Patterns

### Module Structure
All service modules follow this pattern:
```bicep
module serviceName 'modules/XX-service-name/deploy.service-name.bicep' = [
  for i in range(0, length(parSpokeNetworks)): {
    name: take('serviceName-${deployment().name}-deployment', 64)
    scope: resourceGroup(parSpokeNetworks[i].subscriptionId, parSpokeNetworks[i].rgTarget)
    params: {
      location: location
      tags: tags
      // service-specific parameters
    }
  }
]
```

### Naming Conventions
- Storage Account: `st-rsp-{workload}-{uniqueId}-{env}-{region}` (24 char limit)
- Resource Groups: `rg-rsp-{service}-spoke-{env}-{region}`
- Managed Identity: `id-{resource}-{role}`
- Private Endpoint: `pep-{resource}`

Naming is centralized in `shared/bicep/naming/naming.module.bicep` with abbreviations in `naming-rules.jsonc`.

### Resource Organization
Services are deployed across 4 resource groups per environment:
- `rg-rsp-networking-spoke-{env}-uks`: Network resources (VNet, NSGs, subnets)
- `rg-rsp-storage-spoke-{env}-uks`: Storage accounts and SQL Server
- `rg-rsp-applications-spoke-{env}-uks`: Container Apps and App Services
- `rg-rsp-sharedservices-spoke-{env}-uks`: Key Vault, App Config, Container Registry

### Security Architecture
- **Private Networking**: All services use private endpoints where possible
- **Network Security**: NSGs control traffic flow between subnets
- **Identity**: Managed identities for service-to-service authentication
- **Secrets**: Centralized in Key Vault with RBAC access
- **Malware Protection**: Defender for Storage with policy-based enablement

### Defender for Storage Implementation
- **Subscription Level**: Basic protection (Activity Monitoring) via Azure Policy
- **Storage Account Level**: Enhanced protection (Malware Scanning) with account-specific overrides
- **Event Response**: Event Grid + Function Apps for automated file quarantine/approval
- **Logging**: Scan results sent to Log Analytics for compliance

## CI/CD Pipeline Structure

### Pipeline Stages
1. **Lint**: Bicep template validation (`az bicep build`)
2. **Validate**: ARM template validation (`az deployment validate`)
3. **Preview**: What-If analysis for change preview
4. **Deploy**: Actual resource deployment

### Pipeline Files
- `application-deployment.yml`: Deploys all application resources
- `network-deployment.yml`: Deploys VNet, subnets, NSGs
- `alz-bicep-pr1-build.yml`: PR validation builds
- `alz-bicep-pr2-lint.yml`: PR linting checks

Pipelines auto-trigger on PR creation/merge and default to Dev environment. Manual runs support environment selection.

## Development Guidelines

### Adding New Services
1. Create `modules/XX-service-name/deploy.service-name.bicep`
2. Add module call to `main.application.bicep` 
3. Update environment parameter files if needed
4. Follow existing patterns for dependencies and outputs
5. Use shared modules from `shared/bicep/` when possible

### Security Requirements
- All storage accounts must use private endpoints
- Managed identities required for service authentication
- Network ACLs must deny public access by default
- Role assignments must follow principle of least privilege

### Configuration Management
- Environment-specific parameters in `.bicepparam` files
- Shared configuration in `shared/bicep/` modules
- Tags applied consistently across all resources
- Dependencies explicitly declared with `dependsOn`

### Common Role Definitions
- Storage Blob Data Contributor: `ba92f5b4-2d11-453d-a403-e96b0029c9fe`
- Key Vault Reader: `21090545-7ca7-4776-b22c-e363652d74d2`
- App Configuration Data Reader: `516239f1-63e1-4d78-a4de-a74fb236a071`

## Integration Points

### External Systems
- **Gov UK One Login**: External authentication provider
- **IDG**: Internal authentication system
- **App Configuration**: Centralized configuration management

### Authentication Flow
The application supports dual authentication modes integrated through App Configuration service, with Container Apps and App Services retrieving authentication settings dynamically.

This codebase represents a production-ready, enterprise-grade Azure Landing Zone with comprehensive security controls, modular design, and automated deployment capabilities.