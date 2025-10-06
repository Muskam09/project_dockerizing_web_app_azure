data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_key_vault" "kv" {
  name                = var.azurerm_key_vault_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_key_vault_secret" "db_user" {
  name         = "DbUsername"
  key_vault_id = data.azurerm_key_vault.kv.id
}

data "azurerm_key_vault_secret" "db_password" {
  name         = "DbPassword"
  key_vault_id = data.azurerm_key_vault.kv.id
}

#creating container registry
resource "azurerm_container_registry" "acr" {
  name                = var.azurerm_container_registry_name
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  sku                 = "Standard"
  admin_enabled       = true
}

#creating service plan
resource "azurerm_service_plan" "app_plan" {
  name                = var.azurerm_service_plan_name
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "frontend" {
  name                      = var.azurerm_linux_web_app_name_frontend_name
  resource_group_name       = data.azurerm_resource_group.rg.name
  location                  = data.azurerm_resource_group.rg.location
  service_plan_id           = azurerm_service_plan.app_plan.id
  virtual_network_subnet_id = azurerm_subnet.app_subnet.id
  site_config {
    application_stack {
      docker_registry_username = azurerm_container_registry.acr.admin_username
      docker_registry_password = azurerm_container_registry.acr.admin_password
      docker_image_name        = var.frontend_docker_image_name
      docker_registry_url      = "https://${azurerm_container_registry.acr.login_server}"
    }
  }
  identity {
    type = "SystemAssigned"
  }
  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = false
  }
}

resource "azurerm_linux_web_app" "backend" {
  name                      = var.azurerm_linux_web_app_name_backend_name
  resource_group_name       = data.azurerm_resource_group.rg.name
  location                  = data.azurerm_resource_group.rg.location
  service_plan_id           = azurerm_service_plan.app_plan.id
  virtual_network_subnet_id = azurerm_subnet.app_subnet.id
  site_config {
    application_stack {
      docker_registry_username = azurerm_container_registry.acr.admin_username
      docker_registry_password = azurerm_container_registry.acr.admin_password
      docker_image_name        = var.backend_docker_image_name
      docker_registry_url      = "https://${azurerm_container_registry.acr.login_server}"
    }
  }
  identity {
    type = "SystemAssigned"
  }
  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = false
  }
}

# --- PostgreSQL Flexible Server ---
resource "azurerm_postgresql_flexible_server" "db_server" {
  name                          = var.azurerm_postgresql_flexible_server_name
  resource_group_name           = data.azurerm_resource_group.rg.name
  location                      = data.azurerm_resource_group.rg.location
  version                       = "14"
  administrator_login           = data.azurerm_key_vault_secret.db_user.value
  administrator_password        = data.azurerm_key_vault_secret.db_password.value
  private_dns_zone_id           = azurerm_private_dns_zone.privat_dns.id
  sku_name                      = "B_Standard_B1ms"
  storage_mb                    = 32768
  public_network_access_enabled = false
  delegated_subnet_id           = azurerm_subnet.postgresql_subnet.id

  tags = {
    "Project" = "CulinaryPlatform"
  }
  depends_on = [
    azurerm_subnet.postgresql_subnet,
  ]
}
