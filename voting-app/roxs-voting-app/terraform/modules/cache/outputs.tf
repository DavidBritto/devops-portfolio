output "container_name" {
  description = "Nombre del contenedor Redis"
  value       = docker_container.redis.name
}

output "container_id" {
  description = "ID interno del contenedor Docker"
  value       = docker_container.redis.id
}

output "internal_host" {
  description = "Hostname interno para que vote y worker se conecten"
  value       = "redis" # Alias fijo — vote usa REDIS_HOST=redis
}
