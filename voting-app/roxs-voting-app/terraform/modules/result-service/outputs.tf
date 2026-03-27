output "container_ids" {
  description = "IDs de todos los contenedores de result"
  value       = docker_container.result[*].id
}

output "container_names" {
  description = "Nombres de todos los contenedores de result"
  value       = docker_container.result[*].name
}

output "service_urls" {
  description = "URLs accesibles desde el host, una por réplica"
  value       = [for i in range(var.replica_count) : "http://localhost:${var.external_port_base + i}"]
}
