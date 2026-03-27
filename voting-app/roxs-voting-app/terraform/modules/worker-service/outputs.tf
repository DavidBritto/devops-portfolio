output "container_ids" {
  description = "IDs de todos los contenedores del worker"
  value       = docker_container.worker[*].id
}

output "container_names" {
  description = "Nombres de todos los contenedores del worker"
  value       = docker_container.worker[*].name
}

# Sin service_urls — el worker no tiene endpoint accesible.
# El output útil para monitoreo es saber si los contenedores existen.
