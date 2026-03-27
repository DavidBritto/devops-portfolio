output "container_name" {
  description = "Nombre del contenedor — usado como DATABASE_HOST por worker y result"
  value       = docker_container.postgres.name
}

output "container_id" {
  description = "ID interno del contenedor Docker"
  value       = docker_container.postgres.id
}

output "volume_name" {
  description = "Nombre del volumen de datos"
  value       = docker_volume.data.name
}

output "connection_string" {
  description = "String de conexión para debugging (sin password)"
  value       = "postgresql://${var.database_user}@${docker_container.postgres.name}:5432/${var.database_name}"
}

output "internal_host" {
  description = "Hostname interno para que otros servicios se conecten"
  value       = "postgres" # Alias fijo — más estable que el nombre del contenedor
}
