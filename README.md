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

Deployments are automated through GitHub Actions pipeline defined in [`.github/workflows/pipeline.yml`](.github/workflows/pipeline.yml), which triggers on every push to the repository.

## Prerequisites

- Kubernetes cluster with Traefik ingress controller
- Mia-Platform Console access
- Nexus registry credentials for container image
