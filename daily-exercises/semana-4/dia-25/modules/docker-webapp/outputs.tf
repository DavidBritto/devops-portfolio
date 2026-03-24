output "app_url" {
  description = "URL de acceso a la aplicación"
  value       = "http://localhost:${var.external_port}"
}

output "container_name" {
  description = "Nombre del contenedor creado"
  value       = docker_container.app.name
}

output "network_name" {
  description = "Nombre de la red Docker creada"
  value       = docker_network.app_network.name
}
