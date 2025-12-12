terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Storage Account
resource "azurerm_storage_account" "this" {
  name                     = "st${var.project_name}${var.environment}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  min_tls_version          = var.min_tls_version
  https_traffic_only_enabled = var.enable_https_traffic_only

  # Network rules - allow during deployment (can be restricted later via network_rules)
  public_network_access_enabled = true
  
  # Network rules commented out during initial deployment to allow Terraform access
  # Can be enabled after deployment via separate configuration
  # network_rules {
  #   default_action = "Deny"
  #   bypass         = ["AzureServices"]
  # }

  # Blob properties
  blob_properties {
    versioning_enabled = var.enable_versioning

    dynamic "delete_retention_policy" {
      for_each = var.enable_soft_delete_blob ? [1] : []
      content {
        days = var.blob_soft_delete_retention_days
      }
    }

    dynamic "container_delete_retention_policy" {
      for_each = var.enable_soft_delete_container ? [1] : []
      content {
        days = var.container_soft_delete_retention_days
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "storage"
    }
  )
}

# Storage Containers
resource "azurerm_storage_container" "containers" {
  for_each              = toset(var.containers)
  name                  = each.value
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

# Private Endpoint for Blob
resource "azurerm_private_endpoint" "blob" {
  name                = "${azurerm_storage_account.this.name}-blob-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${azurerm_storage_account.this.name}-blob-psc"
    private_connection_resource_id = azurerm_storage_account.this.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "blob-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_ids.blob]
  }

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "storage"
    }
  )
}

# Private Endpoint for File
resource "azurerm_private_endpoint" "file" {
  name                = "${azurerm_storage_account.this.name}-file-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${azurerm_storage_account.this.name}-file-psc"
    private_connection_resource_id = azurerm_storage_account.this.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }

  private_dns_zone_group {
    name                 = "file-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_ids.file]
  }

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "storage"
    }
  )
}

