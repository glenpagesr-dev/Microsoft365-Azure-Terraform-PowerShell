variable "location" {
  description = "Azure region."
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Resource group for the Lab 3 network + VM."
  type        = string
  default     = "rg-lab3-iac"
}

variable "vnet_address_space" {
  description = "VNet CIDR."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_prefix" {
  description = "Workload subnet CIDR."
  type        = string
  default     = "10.0.1.0/24"
}

variable "admin_ip" {
  description = "Your public IP (CIDR) allowed to RDP/SSH. Find it with: curl ifconfig.me"
  type        = string
  # example: "203.0.113.10/32"
}

variable "admin_username" {
  description = "VM local admin username."
  type        = string
  default     = "azureadmin"
}

variable "admin_password" {
  description = "VM local admin password. Do NOT hardcode — pass via tfvars/env or Key Vault."
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Resource tags (Lab 5 policy enforces environment + owner)."
  type        = map(string)
  default = {
    environment = "lab"
    owner       = "glen"
  }
}
