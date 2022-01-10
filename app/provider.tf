terraform {


  backend "azurerm" {
    storage_account_name = "tfstate443590089"
    container_name       = "tfstate"
    key                  = "app.terraform.tfstate"

    # rather than defining this inline, the Access Key can also be sourced
    # from an Environment Variable - more information is available below.
    access_key = "c/v32NRQBtlXQo0Uk2x8hFmwVKLqns1XLVczeYSJPNVwhLHFUYRgMxKdXy9r2T53mI4FmH80w80pZU6pSeMvYQ=="
  }



  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  subscription_id = "d2f5dc28-c6d0-463c-95a9-e5600d95afa3"
}