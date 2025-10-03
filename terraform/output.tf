output "backend_url" {
  value = azurerm_linux_web_app.backend.default_hostname
}

output "frontend_url" {
  value = azurerm_linux_web_app.frontend.default_hostname
}