provider "azurerm" {
  features {}
  subscription_id = "12100be1-d71d-4710-8cf2-d85c7a999be1"
}

resource "azurerm_resource_group" "example" {
  name     = "win-vm-rg"
  location = "East US"
}

resource "azurerm_virtual_network" "example" {
  name                = "win-vm-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "win-vm-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "example" {
  name                = "win-vm-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example.id # Assign public IP here
  }
}


resource "azurerm_public_ip" "example" {
  name                = "win-vm-pip"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"
  sku                 = "Basic"
}

resource "azurerm_network_security_group" "example" {
  name                = "win-vm-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "winrm"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5985"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
resource "azurerm_virtual_machine" "example" {
  name                  = "win-vm"
  location              = azurerm_resource_group.example.location
  resource_group_name   = azurerm_resource_group.example.name
  network_interface_ids = [azurerm_network_interface.example.id]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "win-vm-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "win-vm"
    admin_username = "adminuser"
    admin_password = "P@ssw0rd1234!"
  }

  os_profile_windows_config {
    enable_automatic_upgrades = true
    provision_vm_agent        = true
  }
}

resource "azurerm_virtual_machine_extension" "win_vm_init" {
  name                 = "init-script"
  virtual_machine_id   = azurerm_virtual_machine.example.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    commandToExecute = "powershell.exe -Command \"Set-ExecutionPolicy Bypass -Scope CurrentUser -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')); Enable-PSRemoting -Force; Set-Item -Path 'WSMan:\\localhost\\Service\\Auth\\Basic' -Value $true; Set-Item -Path 'WSMan:\\localhost\\Service\\AllowUnencrypted' -Value $true\""
  })
}
