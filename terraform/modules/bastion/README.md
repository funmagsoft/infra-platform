# Bastion VM Module

Terraform module for deploying a Bastion (jump host) VM with pre-installed management tools for accessing private Azure resources.

## Resources
- Linux VM (Ubuntu 22.04 LTS)
- Static Public IP (Standard)
- Network Interface in the management subnet
- Network Security Group with SSH allow rule
- SSH key (generated or provided)

## Key Inputs
- `resource_group_name`, `location`
- `environment`, `project_name`
- `subnet_id` (mgmt subnet)
- `vm_size` (default: `Standard_D2als_v6`)
- `admin_username` (default: `azureuser`)
- `admin_ssh_public_key` (optional; otherwise generated)
- `allowed_ssh_source_ips` (list, default `["0.0.0.0/0"]`; restrict in prod)
- `install_tools` (default: `true`)
- `enable_system_assigned_identity` (default: `true`)

## Key Outputs
- `bastion_vm_id`, `bastion_public_ip`, `bastion_private_ip`
- `bastion_ssh_private_key` (sensitive, when generated)
- `bastion_principal_id` (managed identity)

## Features
- Installs tools via cloud-init: Azure CLI, kubectl (+completion), Helm (+completion), psql, jq, git, curl, wget.
- Preconfigured aliases and helper functions.
- Custom MOTD with quick instructions.
- NSG rules for SSH, outbound AKS API, and PostgreSQL.

## Usage

```hcl
module "bastion" {
  source = "../../modules/bastion"

  resource_group_name = "rg-ecare-dev"
  location            = "West Europe"
  environment         = "dev"
  
  subnet_id      = var.mgmt_subnet_id
  vm_size        = "Standard_B1s"
  admin_username = "azureuser"
  ubuntu_sku     = "22_04-lts-gen2"

  allowed_ssh_source_ips = ["203.0.113.0/24"]  # Your office IP
  
  enable_system_assigned_identity = true
  install_tools                  = true
}
```

## Key Inputs

| Name | Description | Default |
|------|-------------|---------|
| vm_size | VM size | Standard_B1s |
| admin_username | SSH username | azureuser |
| ubuntu_sku | Ubuntu version | 22_04-lts-gen2 |
| allowed_ssh_source_ips | Allowed SSH source IPs | ["0.0.0.0/0"] |
| admin_ssh_public_key | SSH public key (optional) | auto-generated |
| install_tools | Install tools via cloud-init | true |

## Key Outputs

| Name | Description | Sensitive |
|------|-------------|-----------|
| bastion_vm_id | VM resource ID | no |
| bastion_public_ip | Public IP address | no |
| bastion_private_ip | Private IP address | no |
| bastion_ssh_private_key | Generated SSH private key | yes |
| bastion_principal_id | Managed identity principal ID | no |

## Installed Tools

The cloud-init script automatically installs:

1. **Azure CLI** - Manage Azure resources
2. **kubectl** - Kubernetes command-line tool
3. **Helm** - Kubernetes package manager
4. **PostgreSQL client (psql)** - Database access
5. **jq** - JSON processor
6. **git** - Version control
7. **curl, wget** - HTTP tools

## Pre-configured Aliases

```bash
# Kubernetes shortcuts
k='kubectl'
kgp='kubectl get pods'
kgs='kubectl get services'
kgn='kubectl get nodes'
kd='kubectl describe'
kl='kubectl logs'

# Azure shortcuts
azls='az account show'
azrg='az group list -o table'

# Helper functions
kexec <pod>        # Execute shell in pod
kport <pod> <port> # Port forward
```

## Connecting to Bastion

### Using SSH

```bash
# Get public IP
BASTION_IP=$(terraform output -raw bastion_public_ip)

# Connect using generated key
terraform output -raw bastion_ssh_private_key > bastion_key.pem
chmod 600 bastion_key.pem
ssh -i bastion_key.pem azureuser@$BASTION_IP

# Or using your own key
ssh azureuser@$BASTION_IP
```

### Using Azure CLI

```bash
# Using Azure CLI (requires Azure Bastion Service, not this VM)
az ssh vm \
  --resource-group rg-ecare-dev \
  --name vm-bastion-ecare-dev
```

## Post-Deployment Setup

After VM is provisioned, login and configure Azure access:

```bash
# Login with managed identity
az login --identity

# Get AKS credentials
az aks get-credentials \
  --resource-group rg-ecare-dev \
  --name aks-ecare-dev

# Verify kubectl access
kubectl get nodes

# Test PostgreSQL connection
psql -h psql-ecare-dev.postgres.database.azure.net \
     -U psqladmin \
     -d postgres
```

## Granting Access to Resources

The module output `bastion_principal_id` is used to grant RBAC roles:

```hcl
# Automatic in main.tf
resource "azurerm_role_assignment" "bastion_aks_user" {
  principal_id         = module.bastion.bastion_principal_id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  scope                = module.aks.aks_cluster_id
}

resource "azurerm_role_assignment" "bastion_acr_pull" {
  principal_id         = module.bastion.bastion_principal_id
  role_definition_name = "AcrPull"
  scope                = module.acr.acr_id
}
```

## Security

### Network Security Group Rules

**Inbound:**

- SSH (port 22) from `allowed_ssh_source_ips`

**Outbound:**

- HTTPS (port 443) to AKS API server
- PostgreSQL (port 5432) to database
- All other Azure services

### Best Practices

1. **Restrict SSH source IPs** - Use specific IP ranges, not `0.0.0.0/0`
2. **Use SSH keys only** - Disable password authentication
3. **Managed identity** - No need to store Azure credentials
4. **Regular updates** - Keep VM and tools updated
5. **Audit access** - Monitor SSH login attempts

## VM Sizes

| Size | vCPU | Memory | Cost | Use Case |
|------|------|--------|------|----------|
| Standard_B1s | 1 | 1 GiB | Lowest | Dev/Test |
| Standard_B2s | 2 | 4 GiB | Low | Small teams |
| Standard_D2s_v3 | 2 | 8 GiB | Medium | Production |

**Recommendation**: `Standard_B1s` is sufficient for bastion usage.

## Cloud-init Script

Located at `scripts/cloud-init.tpl`, the script:

1. Updates package lists
2. Installs all tools
3. Configures bash completion
4. Creates helpful aliases
5. Sets up custom MOTD
6. Enables managed identity login script

## Troubleshooting

### Cannot SSH to Bastion

1. Check NSG rules allow your IP
2. Verify public IP is assigned
3. Check VM is running: `az vm get-instance-view`

### Tools not installed

1. Check cloud-init logs: `cat /var/log/cloud-init-output.log`
2. Manually run: `sudo bash /var/lib/cloud/instance/scripts/part-001`

### Cannot access AKS

1. Verify managed identity role assignment
2. Run: `az login --identity`
3. Get credentials: `az aks get-credentials ...`

## Naming

- VM: `vm-bastion-{project_name}-{environment}`
- Public IP: `pip-bastion-{project_name}-{environment}`
- NIC: `nic-bastion-{project_name}-{environment}`
- NSG: `nsg-bastion-{project_name}-{environment}`

## Terraform Version

- Terraform >= 1.5.0
- AzureRM Provider ~> 3.0
- TLS Provider ~> 4.0 (for SSH key generation)

