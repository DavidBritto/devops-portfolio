# URLs sin credenciales
output "application_urls" {
  description = "URLs de acceso a la app (sin credenciales)"
  value = {
    nginx    = "http://localhost:${var.nginx_external_port}"
    postgres = "postgresql://${var.database_user}@localhost:${var.postgres_external_port}/${var.database_name}"
    redis    = "redis://localhost:${var.redis_external_port}"
  }
}

# Cadena de conexión completa (SENSIBLE)
output "postgres_connection_string" {
  description = "Connection string de Postgres con password"
  value       = "postgresql://${var.database_user}:${var.database_password}@localhost:${var.postgres_external_port}/${var.database_name}"
  sensitive   = true
}
