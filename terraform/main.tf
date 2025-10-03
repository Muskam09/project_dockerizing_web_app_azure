resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

#creating container registry
resource "azurerm_container_registry" "acr" {
  name                = var.azurerm_container_registry_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  admin_enabled       = true
}

#creating service plan
resource "azurerm_service_plan" "app_plan" {
  name                = var.azurerm_service_plan_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "frontend" {
  name                      = var.azurerm_linux_web_app_name_frontend_name
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = azurerm_resource_group.rg.location
  service_plan_id           = azurerm_service_plan.app_plan.id
  virtual_network_subnet_id = azurerm_subnet.app_subnet.id
  site_config {
    application_stack {
      docker_registry_username = azurerm_container_registry.acr.admin_username
      docker_registry_password = azurerm_container_registry.acr.admin_password
      docker_image_name = var.frontend_docker_image_name
      docker_registry_url = "https://${azurerm_container_registry.acr.login_server}"
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
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = azurerm_resource_group.rg.location
  service_plan_id           = azurerm_service_plan.app_plan.id
  virtual_network_subnet_id = azurerm_subnet.app_subnet.id
  site_config {
    application_stack {
      docker_registry_username = azurerm_container_registry.acr.admin_username
      docker_registry_password = azurerm_container_registry.acr.admin_password
      docker_image_name = var.backend_docker_image_name
      docker_registry_url = "https://${azurerm_container_registry.acr.login_server}"
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
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  version                       = "14"
  administrator_login           = var.db_login
  administrator_password        = var.db_password
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

/*
# Отримання поточної конфігурації клієнта Azure для tenant_id
data "azurerm_client_config" "current" {}
# 1. Створення Azure Key Vault
resource "azurerm_key_vault" "kv" {
  name                        = "${var.resource_group_name}-kv"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  # Налаштування для мінімальної вартості та простоти, у продакшн використовуйте 90+ днів
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
}

# 2. Збереження логіну БД як секрету
resource "azurerm_key_vault_secret" "db_username" {
  name         = "DbUsername"
  # Використовуємо змінну Terraform для значення, але воно зберігається у KV, а не в App Service
  value        = var.db_login 
  key_vault_id = azurerm_key_vault.kv.id
  content_type = "PostgreSQL Admin Username"
}

# 3. Збереження пароля БД як секрету
resource "azurerm_key_vault_secret" "db_password" {
  name         = "DbPassword"
  value        = var.db_password
  key_vault_id = azurerm_key_vault.kv.id
  content_type = "PostgreSQL Admin Password"
}

# 4. Надання системній ідентичності Backend-додатка дозволу на читання секретів
resource "azurerm_key_vault_access_policy" "backend_access" {
  key_vault_id = azurerm_key_vault.kv.id
  
  # Використовуємо principal_id (ID Managed Identity) Backend Web App
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_web_app.backend.identity[0].principal_id 

  # Додаток повинен мати можливість отримувати (Get) значення секретів з Key Vault
  secret_permissions = ["Get"]
}*/