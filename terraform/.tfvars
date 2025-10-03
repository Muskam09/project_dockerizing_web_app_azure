#Назва ресурсної групи
resource_group_name = "smachno-container"

# Назва плану служби ACR
azurerm_container_registry_name = "acrsmachno"

# Назва плану служби додатків Azure (Azure App Service Plan)
azurerm_service_plan_name = "smachno-service-plan-container"

# Назва Linux-додатку (WebApp) для бекенду
azurerm_linux_web_app_name_backend_name = "smachno-backend-app-container"

# Назва Linux-додатку (WebApp) для фронтенду
azurerm_linux_web_app_name_frontend_name = "smachno-frontend-app-container"

frontend_docker_image_name = "front-container"
backend_docker_image_name = "django-docker"
azurerm_postgresql_flexible_server_name = "smachno-db-with-container"


db_login = "postgresqluser123"
db_password = "ZCz6EqYzA2La"

