provider "azurerm" {
  version = "~>2.0"
  features {}
}

resource "azurerm_resource_group" "factorio" {
  name     = "factorio"
  location = "UK South"
}

resource "azurerm_storage_account" "factoriosavefiles" {
  resource_group_name      = azurerm_resource_group.factorio.name
  name                     = "factoriosavefiles"
  location                 = azurerm_resource_group.factorio.location
  account_tier             = "Standard"
  account_replication_type = "GZRS"
}

resource "azurerm_storage_share" "factorioshare" {
  storage_account_name = azurerm_storage_account.factoriosavefiles.name
  name                 = "factorioshare"
  quota                = 1
}

resource "azurerm_container_group" "factorio" {
  name                = "factorio"
  location            = azurerm_resource_group.factorio.location
  resource_group_name = azurerm_resource_group.factorio.name
  ip_address_type     = "public"
  dns_name_label      = "factorio"
  os_type             = "Linux"
  restart_policy      = "OnFailure"

  container {
    name   = "factorio"
    image  = "factoriotools/factorio:stable"
    cpu    = "1"
    memory = "7" # Adam said so

    ports {
      port     = 34197
      protocol = "UDP"
    }

    environment_variables = {
      "UPDATE_MODS_ON_START" = "true"
    }

    volume {
        name        = "saves"
        mount_path  = "/factorio"
        share_name  = azurerm_storage_share.factorioshare.name

        storage_account_name = azurerm_storage_account.factoriosavefiles.name
        storage_account_key  = azurerm_storage_account.factoriosavefiles.primary_access_key
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