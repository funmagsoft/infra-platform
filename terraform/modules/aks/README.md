# AKS (Azure Kubernetes Service) Module

Terraform module for deploying Azure Kubernetes Service with Workload Identity, monitoring, and
auto-scaling support.

## Resources Created

- **AKS Cluster** - Managed Kubernetes cluster
- **System Node Pool** - Critical system pods (3 nodes)
- **User Node Pool** - Application workloads (auto-scaling)
- **ACR Integration** - Automatic AcrPull role assignment

## Features

- **Workload Identity** enabled (OIDC Issuer for Phase 3!)
- **Azure Monitor Container Insights** integration
- **Azure Policy** add-on support
- **Azure CNI** networking with Azure Network Policy
- **Auto-scaling** for user node pool
- **System-assigned managed identity**
- **Private Endpoint** support for API server (optional)

## Usage

```hcl
module "aks" {
  source = "../../modules/aks"

  resource_group_name = "rg-ecare-dev"
  location            = "West Europe"
  environment         = "dev"
  
  kubernetes_version = null  # Use latest stable
  sku_tier           = "Standard"

  # Network configuration
  vnet_subnet_id = var.aks_subnet_id
  network_plugin = "azure"
  network_policy = "azure"
  service_cidr   = "10.2.0.0/16"
  dns_service_ip = "10.2.0.10"

  # System node pool (critical addons only)
  system_node_pool_vm_size    = "Standard_D2s_v3"
  system_node_pool_node_count = 3

  # User node pool (applications)
  user_node_pool_enabled   = true
  user_node_pool_vm_size   = "Standard_A2_v2"
  user_node_pool_min_count = 1
  user_node_pool_max_count = 3
  enable_auto_scaling      = true

  # Features (IMPORTANT for Phase 3!)
  oidc_issuer_enabled       = true  # Required for Workload Identity
  workload_identity_enabled = true  # Required for Phase 3
  azure_policy_enabled      = true

  # Monitoring
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  enable_container_insights  = true

  # ACR integration
  acr_id = module.acr.acr_id
}
```

## Node Pools

### System Node Pool

- Runs critical system pods (CoreDNS, metrics-server, etc.)
- `only_critical_addons_enabled = true`
- Fixed node count (no auto-scaling)
- Recommended: 3 nodes for HA

### User Node Pool

- Runs application workloads
- Auto-scaling enabled (min/max configurable)
- Can be scaled to zero (min_count = 0)
- Multiple user pools supported

## Key Inputs

| Name | Description | Default |
|------|-------------|---------|
| kubernetes_version | K8s version | Latest stable |
| sku_tier | Free or Standard | Standard |
| system_node_pool_vm_size | System pool VM size | Standard_D2s_v3 |
| user_node_pool_vm_size | User pool VM size | Standard_A2_v2 |
| oidc_issuer_enabled | Enable OIDC (for WI) | true |
| workload_identity_enabled | Enable Workload Identity | true |

## Key Outputs

| Name | Description | Sensitive |
|------|-------------|-----------|
| aks_cluster_id | AKS resource ID | no |
| aks_cluster_name | Cluster name | no |
| aks_oidc_issuer_url | **OIDC Issuer URL** (Phase 3!) | no |
| aks_kubelet_identity_object_id | Kubelet identity object ID | no |
| aks_kube_config | Kubeconfig (raw) | yes |

## OIDC Issuer URL (Phase 3)

**CRITICAL**: The `aks_oidc_issuer_url` output is required for Phase 3 (Workload Identity):

```bash
# Export OIDC Issuer URL for Phase 3
terraform output -raw aks_oidc_issuer_url
# Output: https://westeurope.oic.prod-aks.azure.com/00000000-0000-0000-0000-000000000000/...
```

This URL is used to create Federated Identity Credentials for service principals.

## Network Configuration

### Azure CNI

- Each pod gets IP from VNet subnet
- Better network performance
- Requires larger subnet (calculate: nodes * max_pods_per_node)

### Service CIDR

- Must NOT overlap with VNet CIDR
- Default: `10.2.0.0/16`
- Used for Kubernetes services (ClusterIP)

## Getting Credentials

```bash
# User credentials
az aks get-credentials \
  --resource-group rg-ecare-dev \
  --name aks-ecare-dev

# Admin credentials (cluster-admin)
az aks get-credentials \
  --resource-group rg-ecare-dev \
  --name aks-ecare-dev \
  --admin

# Verify
kubectl get nodes
```

## Azure Policy Add-on

When enabled, enforces policies like:

- No privileged containers
- Required labels
- Resource limits
- Image sources (e.g., only from your ACR)

## Container Insights

Integrates with Log Analytics for:

- Container logs
- Performance metrics (CPU, memory)
- Node health
- Live log streaming

Query logs in Log Analytics:

```kusto
ContainerLog
| where TimeGenerated > ago(1h)
| project TimeGenerated, ContainerName, LogEntry
| order by TimeGenerated desc
```

## ACR Integration

The module automatically grants AKS kubelet identity the `AcrPull` role on the specified ACR:

```hcl
acr_id = module.acr.acr_id
```

Now AKS can pull images from ACR without credentials:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  containers:
  - name: my-app
    image: acrecaredev.azurecr.io/my-app:latest
```

## Workload Identity (Phase 3)

This module prepares AKS for Workload Identity by enabling:

1. **OIDC Issuer** - Issues OIDC tokens for pods
2. **Workload Identity** - Allows pods to authenticate as Azure AD identities

In Phase 3, you'll:

1. Create Azure AD App Registrations
2. Create Federated Identity Credentials using `aks_oidc_issuer_url`
3. Deploy pods with service account annotations
4. Pods authenticate to Azure services without secrets!

## Scaling

### Manual Scaling

```bash
# Scale user node pool
az aks nodepool scale \
  --resource-group rg-ecare-dev \
  --cluster-name aks-ecare-dev \
  --name user \
  --node-count 5
```

### Auto-scaling

Auto-scaling is enabled by default for user node pool based on:

- CPU utilization
- Memory utilization
- Pod scheduling failures

## Upgrading Kubernetes

```bash
# List available versions
az aks get-upgrades \
  --resource-group rg-ecare-dev \
  --name aks-ecare-dev

# Upgrade cluster
az aks upgrade \
  --resource-group rg-ecare-dev \
  --name aks-ecare-dev \
  --kubernetes-version 1.28.5
```

## Naming

- AKS Cluster: `aks-{project_name}-{environment}`
- Node Resource Group: `MC_{rg_name}_{aks_name}_{location}`

## Cost Optimization

- Use Burstable VMs (B-series) for dev: `Standard_B2s`
- Use auto-scaling with low min_count
- Use spot instances for non-critical workloads (not in this module)

## Terraform Version

- Terraform >= 1.5.0
- AzureRM Provider ~> 3.0
