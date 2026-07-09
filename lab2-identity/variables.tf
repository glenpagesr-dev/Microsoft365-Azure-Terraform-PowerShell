variable "location" {
  description = "Azure region for the demo resource group used in RBAC assignment."
  type        = string
  default     = "eastus"
}

variable "domain" {
  description = "Your M365 sandbox domain, e.g. yourtenant.onmicrosoft.com."
  type        = string
}

variable "group_display_name" {
  description = "Security group that receives the least-privilege Reader role."
  type        = string
  default     = "IT-Ops-Test"
}
