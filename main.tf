provider "azurerm" {
  version = "~>2.0"
  features {}
}

resource "azurerm_resource_group" "factorio" {
  name     = "factorio"
  location = "UK South"
}

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