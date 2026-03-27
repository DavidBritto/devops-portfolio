output "container_ids" {
  description = "IDs de todos los contenedores de vote (uno por réplica)"
  value       = docker_container.vote[*].id
}

output "container_names" {
  description = "Nombres de todos los contenedores de vote"
  value       = docker_container.vote[*].name
}

output "service_urls" {
  description = "URLs accesibles desde el host, una por réplica"
  value       = [for i in range(var.replica_count) : "http://localhost:${var.external_port_base + i}"]
}
