terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }

  # Remote state in Azure Storage. Create the storage account + container
  # FIRST (see the bootstrap snippet in the Lab 3 section of the README),
  # otherwise `terraform init` will fail.
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstatelab3" # must be globally unique — change this
    container_name       = "tfstate"
    key                  = "lab3.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}
