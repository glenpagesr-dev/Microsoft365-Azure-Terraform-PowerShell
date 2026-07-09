output "resource_group" {
  description = "Resource group name."
  value       = azurerm_resource_group.lab3.name
}

output "vm_public_ip" {
  description = "Public IP to RDP/SSH into (allowed only from var.admin_ip)."
  value       = azurerm_public_ip.pip.ip_address
}

output "vm_name" {
  value = azurerm_windows_virtual_machine.vm.name
}
