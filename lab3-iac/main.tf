# =====================================================================
#  Lab 3 — Infrastructure as Code: Networking & Compute
#  RG -> VNet -> Subnet -> NSG (RDP/SSH from your IP only) -> PIP -> NIC -> VM
# =====================================================================

resource "azurerm_resource_group" "lab3" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-lab3"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.lab3.location
  resource_group_name = azurerm_resource_group.lab3.name
  tags                = var.tags
}

resource "azurerm_subnet" "workload" {
  name                 = "snet-workload"
  resource_group_name  = azurerm_resource_group.lab3.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_prefix]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-lab3"
  location            = azurerm_resource_group.lab3.location
  resource_group_name = azurerm_resource_group.lab3.name
  tags                = var.tags

  security_rule {
    name                       = "Allow-RDP-From-Admin"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.admin_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH-From-Admin"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.admin_ip
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "assoc" {
  subnet_id                 = azurerm_subnet.workload.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_public_ip" "pip" {
  name                = "pip-lab3-vm"
  location            = azurerm_resource_group.lab3.location
  resource_group_name = azurerm_resource_group.lab3.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_interface" "nic" {
  name                = "nic-lab3-vm"
  location            = azurerm_resource_group.lab3.location
  resource_group_name = azurerm_resource_group.lab3.name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.workload.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                = "vm-lab3"
  resource_group_name = azurerm_resource_group.lab3.name
  location            = azurerm_resource_group.lab3.location
  size                = "Standard_B2s" # small/cheap; destroy when done
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [azurerm_network_interface.nic.id]
  tags                  = var.tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
}
