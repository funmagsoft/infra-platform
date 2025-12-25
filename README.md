# Infra Platform

Platform (AKS, PostgreSQL, Storage, Key Vault, Service Bus, ACR, Bastion) for the ecare project.

## Purpose

This repository contains Terraform code for:

- AKS (with Workload Identity and OIDC)
- PostgreSQL (Flexible Server) with Private Endpoint
- Storage Accounts with Private Endpoint
- Key Vault with Private Endpoint
- Service Bus (Standard/Premium) with Private Endpoint (when supported)
- ACR with Private Endpoint
- Bastion VM
- Shared AKS namespace `ecare`

## Structure

```console
terraform/
├── modules/
│   ├── aks/
│   ├── postgresql/
│   ├── storage/
│   ├── key-vault/
│   ├── service-bus/
│   ├── acr/
│   ├── monitoring/
│   ├── bastion/
│   └── aks-namespace/
└── environments/
    ├── dev/
    ├── test/
    ├── stage/
    └── prod/
```

## Getting Started

1. Review infra documentation [README.md](https://github.com/funmagsoft/infra-documentation/blob/main/README.md)

## Prerequisites

Make sure Phase 0 (infra-foundation) is deployed (RG, state storage, access). You need:

- Azure CLI logged in (`az login`)
- Correct subscription selected (`az account set --subscription <id>`)
- Terraform >= 1.5.0 installed

## Pre-commit Hooks

This repository uses pre-commit hooks to ensure code quality and consistency. The hooks automatically:

- Format Terraform files (`terraform fmt`)
- Validate Terraform syntax (`terraform validate`)
- Check for security issues (`checkov`)
- Lint Terraform code (`tflint`)
- Ensure files end with exactly one newline
- Remove trailing whitespace
- Validate YAML/JSON syntax

### Installation

1. Install pre-commit:

```bash
# Using pip (recommended)
pip install pre-commit

# Or using Homebrew (macOS)
brew install pre-commit
```

1. Install the hooks in this repository:

```bash
cd /path/to/infra-platform
pre-commit install
```

1. Install hook dependencies (downloads tools automatically):

```bash
pre-commit install-hooks
```

### Usage

Hooks run automatically on `git commit`. To run manually:

```bash
# Run on all files
pre-commit run --all-files

# Run only on staged files
pre-commit run

# Run a specific hook
pre-commit run terraform_fmt --all-files
```

### Updating Hooks

To update hooks to the latest versions:

```bash
pre-commit autoupdate
```

### Skipping Hooks (Not Recommended)

Only skip hooks in exceptional circumstances:

```bash
git commit --no-verify -m "message"
```

## Running Terraform

### 1. Navigate to the environment directory

```bash
cd terraform/environments/dev  # or test, stage, prod
```

### 2. Configure Terraform variables

Copy the example variables file and customize it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and configure (per environment):

- AKS settings (kubernetes version, node pool sizes/counts, network)
- PostgreSQL sizing and HA/backup
- Storage settings (replication, soft-delete, containers)
- Key Vault settings (SKU, purge protection)
- Service Bus SKU/capacity (Standard/Premium)
- Bastion settings (vm_size, SSH source IPs)

**Important**: `terraform.tfvars` is in `.gitignore` and should not be committed. Use `terraform.tfvars.example` as a template.

### 3. Initialize Terraform

```bash
terraform init
```

This will:

- Download required providers
- Configure the backend to use the Storage Account from Phase 0
- Use Azure AD auth (`use_azuread_auth = true`) if you are logged in with `az login`

### 4. Review the execution plan

```bash
terraform plan
```

### 5. Apply the configuration

```bash
terraform apply
```

### 6. Verify deployment

- Check Azure Portal for created resources
- Review Terraform outputs: `terraform output`

## Important Notes

- **State Management**: Terraform state is stored remotely in the Storage Account configured in `backend.tf`. Never commit `.tfstate` files to git.
- **Environment Isolation**: Each environment (dev, test, stage, prod) has separate state files and Resource Groups.
- **Authentication**: Terraform uses Azure AD authentication (backend `use_azuread_auth = true`). Ensure `az login` or GitHub OIDC is configured.
- **Backend Configuration**: `backend.tf` points to the Storage Accounts created by Phase 0. If names change, update `backend.tf`.

## Networking and Private Access

- AKS, PostgreSQL, Storage, Key Vault, Service Bus, and ACR use Private Endpoints (where supported).
- DNS for Private Endpoints is managed inside each resource module (per-service Private DNS Zones in platform modules).
- Bastion is placed in the mgmt subnet; NSG allows SSH only from configured source IPs.

## AKS Namespace

- Shared namespace `ecare` created in every environment (module `aks-namespace`).
- Intended for workload identity-enabled workloads and application services.

## Modules Overview

- **aks**: AKS with OIDC, Workload Identity, monitoring, RBAC to ACR.
- **postgresql**: Flexible Server + Private Endpoint + Private DNS.
- **storage**: Storage Account + Private Endpoint + Private DNS.
- **key-vault**: Key Vault + Private Endpoint + Private DNS + correct `enable_rbac_authorization`.
- **service-bus**: Standard/Premium; Private Endpoint for Premium; public network access auto-adjusted by SKU.
- **acr**: Container Registry + Private Endpoint + Private DNS.
- **bastion**: Bastion VM (SSH key, tooling), NSG with allowed source IP list.
- **aks-namespace**: Creates the shared `ecare` namespace.

## Cleanup

Use `terraform destroy` in a given environment if you need to remove platform resources. Be careful with shared components (e.g., ACR, Service Bus) and dependencies with workload identity.
