# =====================================================================
#  Lab 2 — Identity Foundations (Terraform slice)
#  Creates a security group and a demo resource group, then assigns the
#  group a least-privilege Reader role. This is the first cross-provider
#  config: azuread (identity) + azurerm (Azure RBAC).
# =====================================================================

# --- Security group (azuread) ----------------------------------------
resource "azuread_group" "it_ops_test" {
  display_name     = var.group_display_name
  security_enabled = true
  # NOTE: if you created this group in the portal first, import it:
  #   terraform import azuread_group.it_ops_test <object-id>
}

# Example: a Terraform-managed user added to the group.
resource "azuread_user" "demo" {
  user_principal_name   = "tf.demo@${var.domain}"
  display_name          = "TF Demo User"
  password              = "ChangeMe-${random_password.demo.result}" # rotate on first login
  force_password_change = true
}

resource "random_password" "demo" {
  length  = 16
  special = true
}

resource "azuread_group_member" "demo_membership" {
  group_object_id  = azuread_group.it_ops_test.object_id
  member_object_id = azuread_user.demo.object_id
}

# --- Demo resource group + RBAC (azurerm) ----------------------------
resource "azurerm_resource_group" "lab2" {
  name     = "rg-lab2-identity"
  location = var.location
  tags = {
    environment = "lab"
    owner       = "glen"
  }
}

resource "azurerm_role_assignment" "reader" {
  scope                = azurerm_resource_group.lab2.id
  role_definition_name = "Reader"
  principal_id         = azuread_group.it_ops_test.object_id
}
