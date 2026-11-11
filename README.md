# %project.name% Configurations

This repository contains all the configuration resources required for the %project.name% project to function properly and expose its business features.

## Repository Structure

- **`configuration/`** - Base Kubernetes configurations and resources
- **`environments/`** - Environment-specific configuration templates
- **`overlays/`** - Environment-specific customizations using Kustomize
- **`mlp.yaml`** - MLP cli specific configuration for secrets and deployment settings
- **`.github/workflows/`** - CI/CD pipeline definitions for automated deployment

## Environment Configuration

The project uses Kustomize for managing environment-specific configurations.

Each environment includes:
- Ingress routing configuration via Traefik IngressRoute
- Custom middleware for security headers
- API Gateway service exposure on port 8080

## Deployment

Deployments run through the GitHub Actions workflow in [`.github/workflows/pipeline.yml`](.github/workflows/pipeline.yml), triggered by the deployment event that Mia-Platform Console creates when you deploy an environment.

The workflow reads these repository secrets: `KUBE_URL`, `KUBE_TOKEN`, `KUBE_CA_PEM`, `NEXUS_USER`, `NEXUS_TOKEN`, `NEXUS_URL`.

## Application secrets

Application secrets are stored in Azure Key Vault. Console generates the resources that let the External Secrets Operator create the `akv-secret` Kubernetes Secret in the project namespace; microservices read values from it through environment variables of type "from secret".

## Prerequisites

- Kubernetes cluster with Traefik ingress controller
- External Secrets Operator installed in the cluster, with Workload Identity access to Azure Key Vault
- Mia-Platform Console access, with an Azure Key Vault provider configured for the project
- Nexus registry credentials for container image
