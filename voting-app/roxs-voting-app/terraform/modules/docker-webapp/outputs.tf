output "application_urls" {
  description = "URLs de acceso a la aplicación."
  value = {
    vote_app    = "http://localhost:${var.vote_external_port}"
    result_app  = "http://localhost:${var.result_external_port}"
    nginx_proxy = "http://localhost:${var.nginx_external_port}"
    postgres    = "postgresql://${var.database_user}@localhost:${var.postgres_external_port}/${var.database_name}"
    redis       = "redis://localhost:${var.redis_external_port}"
  }
}

output "postgres_connection_string" {
  description = "Cadena de conexión completa de Postgres (sensible)."
  value       = "postgresql://${var.database_user}:${var.database_password}@localhost:${var.postgres_external_port}/${var.database_name}"
  sensitive   = true
}
