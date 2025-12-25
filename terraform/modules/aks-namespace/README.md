# AKS Namespace Module

Terraform module for creating a Kubernetes namespace in an AKS cluster.

## Resources Created

- **Kubernetes Namespace** - Namespace in the AKS cluster

## Features

- Simple namespace creation with labels
- Environment and project name labeling
- Support for additional custom labels

## Usage

```hcl
module "aks_namespace" {
  source = "../../modules/aks-namespace"

  environment  = "dev"
  project_name = "ecare"
  namespace    = "ecare"

  labels = {
    team = "platform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| namespace | Kubernetes namespace to create | `string` | `"ecare"` | no |
| environment | Environment name (dev, test, stage, prod) | `string` | - | yes |
| project_name | Project name for labeling | `string` | `"ecare"` | no |
| labels | Additional labels to apply to the namespace | `map(string)` | `{}` | no |

## Outputs

| Name | Description | Sensitive |
|------|-------------|-----------|
| namespace_name | Name of the created namespace | no |

## Naming Convention

Resources follow this naming pattern:

- **Namespace**: User-defined (default: `ecare`)

## Prerequisites

From Phase 1 (infra-foundation):

- AKS cluster must be deployed and accessible
- Kubernetes provider must be configured

## Terraform Version

- Terraform >= 1.5.0
- Kubernetes Provider ~> 2.0
