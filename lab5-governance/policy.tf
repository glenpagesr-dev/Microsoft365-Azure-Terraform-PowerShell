# =====================================================================
#  Lab 5 — Governance as Code: require environment + owner tags on RGs
# =====================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_subscription" "current" {}

variable "required_tags" {
  description = "Tags every resource group must carry."
  type        = list(string)
  default     = ["environment", "owner"]
}

resource "azurerm_policy_definition" "require_tags" {
  name         = "require-rg-tags"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Require environment + owner tags on resource groups"

  metadata = jsonencode({ category = "Tags" })

  policy_rule = jsonencode({
    if = {
      allOf = [
        { field = "type", equals = "Microsoft.Resources/subscriptions/resourceGroups" },
        {
          anyOf = [
            for t in var.required_tags : {
              field  = "tags['${t}']"
              exists = "false"
            }
          ]
        }
      ]
    }
    # Use "deny" to block, or "audit" to only flag. Start with audit.
    then = { effect = "audit" }
  })
}

resource "azurerm_subscription_policy_assignment" "require_tags" {
  name                 = "require-rg-tags"
  display_name         = "Require environment + owner tags on resource groups"
  policy_definition_id = azurerm_policy_definition.require_tags.id
  subscription_id      = data.azurerm_subscription.current.id
}
