# ACR (Azure Container Registry) Module

Terraform module for deploying Azure Container Registry with Private Endpoint for secure container
image storage and distribution.

## Resources Created

- **Azure Container Registry** - Private container registry (Premium SKU)
- **Private Endpoint** - Private network access to ACR

## Features

- Public network access disabled by default
- Premium SKU with zone redundancy support
- Retention policy for untagged manifests
- Content trust policy support (Premium)
- Private Endpoint integration
- Automatic AcrPull role assignment for AKS

## Usage

```hcl
module "acr" {
  source = "../../modules/acr"

  resource_group_name = "rg-ecare-dev"
  location            = "West Europe"
  environment         = "dev"
  
  sku                     = "Premium"
  zone_redundancy_enabled = false  # true for production
  retention_days          = 7

  subnet_id           = var.data_subnet_id
  private_dns_zone_id = var.acr_dns_zone_id
}
```

## Key Inputs

- `sku`: Basic, Standard, or Premium (Premium recommended for production)
- `zone_redundancy_enabled`: HA across availability zones (Premium only)
- `retention_days`: Cleanup untagged manifests after N days
- `admin_enabled`: Use managed identity instead (default: false)

## Key Outputs

- `acr_id`: ACR resource ID
- `acr_name`: Registry name
- `acr_login_server`: Login server URL (e.g., `acrecaredev.azurecr.io`)
- `private_endpoint_ip`: Private IP address

## Naming

- ACR: `acr{project_name}{environment}` (e.g., `acrecaredev`)
- Must be globally unique, 5-50 alphanumeric characters

## Integration with AKS

```hcl
# AKS automatically gets AcrPull role on this ACR
module "aks" {
  acr_id = module.acr.acr_id
  # ...
}
```

## Docker Login

```bash
# Using Azure CLI (Managed Identity)
az acr login --name acrecaredev

# Or using Docker
docker login acrecaredev.azurecr.io
```

## Terraform Version

- Terraform >= 1.5.0
- AzureRM Provider ~> 3.0
