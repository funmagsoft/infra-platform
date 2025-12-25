#------------------------------------------------------------------------------
# Module: Storage Account (with Private Endpoints)
#------------------------------------------------------------------------------

module "storage" {
  source = "../../modules/storage"

  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  environment         = var.environment
  organization_name   = var.organization_name
  project_name        = var.project_name

  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_replication_type
  containers               = var.storage_containers

  enable_versioning                    = var.storage_enable_versioning
  enable_soft_delete_blob              = var.storage_enable_soft_delete_blob
  blob_soft_delete_retention_days      = var.storage_blob_soft_delete_retention_days
  enable_soft_delete_container         = var.storage_enable_soft_delete_container
  container_soft_delete_retention_days = var.storage_container_soft_delete_retention_days

  # Private Endpoint configuration
  subnet_id = local.data_subnet_id
  vnet_id   = local.vnet_id
  vnet_name = data.terraform_remote_state.foundation.outputs.vnet_name

  tags = local.common_tags
}

