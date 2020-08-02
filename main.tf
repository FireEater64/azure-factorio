# Configure the Azure Provider
provider "azurerm" {
  version = "~>2.0"
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "factorio" {
  name     = "factorio"
  location = "UK South"
}

/* # Create a virtual network within the resource group
resource "azurerm_virtual_network" "factorio" {
  name                = "factorio"
  resource_group_name = azurerm_resource_group.factorio.name
  location            = azurerm_resource_group.factorio.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "factorio" {
    name                 = "factorio"
    resource_group_name  = azurerm_resource_group.factorio.name
    virtual_network_name = azurerm_virtual_network.factorio.name
    address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "factorio" {
    name                = "factorio"
    location            = azurerm_resource_group.factorio.location
    resource_group_name = azurerm_resource_group.factorio.name
    allocation_method   = "Dynamic"
}

resource "azurerm_network_security_group" "factorio" {
    name                = "factorio-nsg"
    location            = azurerm_resource_group.factorio.location
    resource_group_name = azurerm_resource_group.factorio.name
    
    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "Factorio"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Udp"
        source_port_range          = "*"
        destination_port_range     = "34197"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "RCON"
        priority                   = 1003
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "27015"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

resource "azurerm_network_interface" "factorio" {
    name                        = "myNIC"
    location                    = azurerm_resource_group.factorio.location
    resource_group_name         = azurerm_resource_group.factorio.name

    ip_configuration {
        name                          = "factorio"
        subnet_id                     = azurerm_subnet.factorio.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.factorio.id
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "factorio" {
    network_interface_id      = azurerm_network_interface.factorio.id
    network_security_group_id = azurerm_network_security_group.factorio.id
}

resource "azurerm_linux_virtual_machine" "factorio" {
    name                  = "factorio"
    location              = azurerm_resource_group.factorio.location
    resource_group_name   = azurerm_resource_group.factorio.name
    network_interface_ids = [azurerm_network_interface.factorio.id]
    size                  = "Standard_F2s_v2"

    os_disk {
        name                    = "factorio"
        caching                 = "ReadWrite"
        storage_account_type    = "Standard_LRS"
    }

    source_image_reference {
        publisher = "OpenLogic"
        offer     = "CentOS"
        sku       = "8_2"
        version   = "latest"
    }

    computer_name  = "factorio"
    admin_username = "george"
    disable_password_authentication = true
        
    admin_ssh_key {
        username       = "george"
        public_key     = file("~/.ssh/georgeserve.pub")
    }
} */

resource "azurerm_storage_account" "factorio" {
  resource_group_name      = azurerm_resource_group.factorio.name
  name                     = "factoriosavestorage"
  location                 = azurerm_resource_group.factorio.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

resource "azurerm_storage_share" "factorio" {
  storage_account_name = azurerm_storage_account.factorio.name
  name                 = "factorio-saves"
  quota                = 1
}

resource "azurerm_container_group" "factorio" {
  name                = "factorio"
  location            = azurerm_resource_group.factorio.location
  resource_group_name = azurerm_resource_group.factorio.name
  ip_address_type     = "public"
  dns_name_label      = "factorio"
  os_type             = "Linux"

  container {
    name   = "factorio"
    image  = "factoriotools/factorio:stable"
    cpu    = "2"
    memory = "2"

    ports {
      port     = 34197
      protocol = "UDP"
    }

    volume {
        name        = "saves"
        mount_path  = "/factorio"
        share_name  = azurerm_storage_share.factorio.name

        storage_account_name = azurerm_storage_account.factorio.name
        storage_account_key  = azurerm_storage_account.factorio.primary_access_key
    }
  }
}

resource "azurerm_dns_cname_record" "factorio" {
  name                = "factorio"
  zone_name           = "cloud.vanburgh.me"
  resource_group_name = "cloud.vanburgh.me"
  ttl                 = 300
  record             = azurerm_container_group.factorio.fqdn
}

output "server_url" { value = azurerm_dns_cname_record.factorio.fqdn }