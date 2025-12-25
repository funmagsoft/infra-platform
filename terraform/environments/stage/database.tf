#------------------------------------------------------------------------------
# Module: PostgreSQL Flexible Server (with Private Endpoint)
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
  vnet_id                    = local.vnet_id
  vnet_name                  = data.terraform_remote_state.foundation.outputs.vnet_name

  tags = local.common_tags
}

