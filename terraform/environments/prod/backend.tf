terraform {
  backend "azurerm" {
    resource_group_name  = "rg-ecare-prod"
    storage_account_name = "tfstatefmsecareprod"
    container_name       = "tfstate"
    key                  = "infra-platform/terraform.tfstate"
    use_azuread_auth     = true
  }
}
