terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Data source: Read outputs from Phase 1 (infra-foundation)
data "terraform_remote_state" "foundation" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-ecare-${var.environment}"
    storage_account_name = "tfstatefmsecare${var.environment}"
    container_name       = "tfstate"
    key                  = "infra-foundation/terraform.tfstate"
    use_azuread_auth     = true
  }
}

# Data source: Current Azure client configuration
data "azurerm_client_config" "current" {}

# Data source: Resource Group (created in Phase 0)
data "azurerm_resource_group" "main" {
  name = "rg-${var.project_name}-${var.environment}"
}

# Local variables
locals {
  common_tags = {
    Environment   = var.environment
    Project       = var.project_name
    ManagedBy     = "Terraform"
    Phase         = "Platform"
    GitRepository = "infra-platform"
    TerraformPath = "terraform/environments/${var.environment}"
  }

  # Extract foundation outputs
  vnet_id           = data.terraform_remote_state.foundation.outputs.vnet_id
  aks_subnet_id     = data.terraform_remote_state.foundation.outputs.aks_subnet_id
  data_subnet_id    = data.terraform_remote_state.foundation.outputs.data_subnet_id
  mgmt_subnet_id    = data.terraform_remote_state.foundation.outputs.mgmt_subnet_id
  private_dns_zones = data.terraform_remote_state.foundation.outputs.private_dns_zones
}

#------------------------------------------------------------------------------
# Module 1: Monitoring (Log Analytics + Application Insights)
#------------------------------------------------------------------------------

module "monitoring" {
  source = "../../modules/monitoring"

  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  environment         = var.environment
  project_name        = var.project_name

  log_analytics_sku            = var.log_analytics_sku
  log_analytics_retention_days = var.log_analytics_retention_days
  application_insights_type    = var.application_insights_type

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# Module 2: Storage Account (with Private Endpoints)
#------------------------------------------------------------------------------

module "storage" {
  source = "../../modules/storage"

  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  environment         = var.environment
  project_name        = var.project_name

  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_replication_type
  containers               = var.storage_containers

  enable_versioning                      = var.storage_enable_versioning
  enable_soft_delete_blob                = var.storage_enable_soft_delete_blob
  blob_soft_delete_retention_days        = var.storage_blob_soft_delete_retention_days
  enable_soft_delete_container           = var.storage_enable_soft_delete_container
  container_soft_delete_retention_days   = var.storage_container_soft_delete_retention_days

  # Private Endpoint configuration
  subnet_id = local.data_subnet_id
  private_dns_zone_ids = {
    blob = local.private_dns_zones.blob
    file = local.private_dns_zones.file
  }

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# Module 3: Key Vault (with Private Endpoint)
#------------------------------------------------------------------------------

module "key_vault" {
  source = "../../modules/key-vault"

  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  environment         = var.environment
  project_name        = var.project_name

  sku_name                   = var.key_vault_sku
  purge_protection_enabled   = var.key_vault_purge_protection_enabled
  soft_delete_retention_days = var.key_vault_soft_delete_retention_days

  # Private Endpoint configuration
  subnet_id           = local.data_subnet_id
  private_dns_zone_id = local.private_dns_zones.keyvault

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# Module 4: Azure Container Registry (with Private Endpoint)
#------------------------------------------------------------------------------

module "acr" {
  source = "../../modules/acr"

  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  environment         = var.environment
  project_name        = var.project_name

  sku                  = var.acr_sku
  zone_redundancy_enabled = var.acr_zone_redundancy_enabled
  retention_days       = var.acr_retention_days

  # Private Endpoint configuration
  subnet_id           = local.data_subnet_id
  private_dns_zone_id = local.private_dns_zones.acr

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# Module 5: PostgreSQL Flexible Server (with Private Endpoint)
#------------------------------------------------------------------------------

module "postgresql" {
  source = "../../modules/postgresql"

  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  environment         = var.environment
  project_name        = var.project_name

  postgresql_version = var.postgresql_version
  sku_name           = var.postgresql_sku_name
  storage_mb         = var.postgresql_storage_mb

  backup_retention_days        = var.postgresql_backup_retention_days
  geo_redundant_backup_enabled = var.postgresql_geo_redundant_backup_enabled
  high_availability_enabled    = var.postgresql_high_availability_enabled
  high_availability_mode       = var.postgresql_high_availability_mode

  administrator_login    = var.postgresql_admin_username
  administrator_password = var.postgresql_admin_password

  # Private Endpoint configuration
  private_endpoint_subnet_id = local.data_subnet_id
  private_dns_zone_id        = local.private_dns_zones.postgresql

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# Module 6: Service Bus (with Private Endpoint)
#------------------------------------------------------------------------------

module "service_bus" {
  source = "../../modules/service-bus"

  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  environment         = var.environment
  project_name        = var.project_name

  sku            = var.service_bus_sku
  capacity       = var.service_bus_capacity
  zone_redundant = var.service_bus_zone_redundant

  # Private Endpoint configuration
  subnet_id           = local.data_subnet_id
  private_dns_zone_id = local.private_dns_zones.servicebus

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# Module 7: AKS Cluster (with Workload Identity)
#------------------------------------------------------------------------------

module "aks" {
  source = "../../modules/aks"

  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  environment         = var.environment
  project_name        = var.project_name

  kubernetes_version = var.aks_kubernetes_version
  sku_tier           = var.aks_sku_tier

  # Network configuration
  vnet_subnet_id = local.aks_subnet_id
  network_plugin = var.aks_network_plugin
  network_policy = var.aks_network_policy
  service_cidr   = var.aks_service_cidr
  dns_service_ip = var.aks_dns_service_ip

  # System node pool
  system_node_pool_vm_size      = var.aks_system_node_pool_vm_size
  system_node_pool_node_count   = var.aks_system_node_pool_node_count
  system_node_pool_os_disk_size_gb = var.aks_system_node_pool_os_disk_size_gb

  # User node pool
  user_node_pool_enabled       = var.aks_user_node_pool_enabled
  user_node_pool_vm_size       = var.aks_user_node_pool_vm_size
  user_node_pool_min_count     = var.aks_user_node_pool_min_count
  user_node_pool_max_count     = var.aks_user_node_pool_max_count
  user_node_pool_os_disk_size_gb = var.aks_user_node_pool_os_disk_size_gb
  enable_auto_scaling          = var.aks_enable_auto_scaling

  # Features
  oidc_issuer_enabled       = var.aks_oidc_issuer_enabled
  workload_identity_enabled = var.aks_workload_identity_enabled
  azure_policy_enabled      = var.aks_azure_policy_enabled

  # Monitoring
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  enable_container_insights  = var.aks_enable_container_insights

  tags = local.common_tags

  depends_on = [
    module.monitoring
  ]
}

#------------------------------------------------------------------------------
# Module 8: Bastion VM (with tools)
#------------------------------------------------------------------------------

module "bastion" {
  source = "../../modules/bastion"

  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  environment         = var.environment
  project_name        = var.project_name

  subnet_id      = local.mgmt_subnet_id
  vm_size        = var.bastion_vm_size
  admin_username = var.bastion_admin_username
  ubuntu_sku     = var.bastion_ubuntu_sku

  allowed_ssh_source_ips       = var.bastion_allowed_ssh_source_ips
  enable_system_assigned_identity = true
  install_tools                = true

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# RBAC Role Assignments
#------------------------------------------------------------------------------

# Grant Bastion VM access to AKS
resource "azurerm_role_assignment" "bastion_aks_user" {
  principal_id         = module.bastion.bastion_principal_id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  scope                = module.aks.aks_cluster_id

  depends_on = [module.bastion, module.aks]
}

# Grant Bastion VM access to ACR
resource "azurerm_role_assignment" "bastion_acr_pull" {
  principal_id         = module.bastion.bastion_principal_id
  role_definition_name = "AcrPull"
  scope                = module.acr.acr_id

  depends_on = [module.bastion, module.acr]
}

# Grant AKS kubelet identity access to ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = module.aks.aks_kubelet_identity_object_id
  role_definition_name             = "AcrPull"
  scope                            = module.acr.acr_id
  skip_service_principal_aad_check = true

  depends_on = [module.aks, module.acr]
}

