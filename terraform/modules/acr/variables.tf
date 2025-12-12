variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, test, stage, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "ecare"
}

variable "sku" {
  description = "SKU for ACR (Basic, Standard, Premium)"
  type        = string
  default     = "Premium"
}

variable "admin_enabled" {
  description = "Enable admin user"
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = false
}

variable "zone_redundancy_enabled" {
  description = "Enable zone redundancy (Premium SKU only)"
  type        = bool
  default     = false
}

variable "retention_days" {
  description = "Retention policy in days for untagged manifests"
  type        = number
  default     = 7
}

variable "trust_policy_enabled" {
  description = "Enable content trust policy"
  type        = bool
  default     = false
}

# Private Endpoint configuration
variable "subnet_id" {
  description = "Subnet ID for Private Endpoint"
  type        = string
}

variable "private_dns_zone_id" {
  description = "Private DNS Zone ID for ACR"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

