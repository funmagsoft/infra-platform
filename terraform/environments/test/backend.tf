terraform {
  backend "azurerm" {
    resource_group_name  = "rg-ecare-test"
    storage_account_name = "tfstatefmsecaretest"
    container_name       = "tfstate"
    key                  = "infra-platform/terraform.tfstate"
    use_azuread_auth     = true
  }
}
