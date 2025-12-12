terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Service Bus Namespace
resource "azurerm_servicebus_namespace" "this" {
  name                          = "sb-${var.project_name}-${var.environment}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  sku                           = var.sku
  capacity                      = var.sku == "Premium" ? var.capacity : null
  premium_messaging_partitions  = var.sku == "Premium" && var.zone_redundant ? 1 : 0
  public_network_access_enabled = var.public_network_access_enabled
  minimum_tls_version           = var.minimum_tls_version

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "service-bus"
    }
  )
}

# Private Endpoint for Service Bus (Premium SKU only)
resource "azurerm_private_endpoint" "this" {
  count = var.sku == "Premium" ? 1 : 0

  name                = "${azurerm_servicebus_namespace.this.name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${azurerm_servicebus_namespace.this.name}-psc"
    private_connection_resource_id = azurerm_servicebus_namespace.this.id
    is_manual_connection           = false
    subresource_names              = ["namespace"]
  }

  private_dns_zone_group {
    name                 = "servicebus-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "service-bus"
    }
  )
}

