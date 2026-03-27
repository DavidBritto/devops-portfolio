output "application_urls" {
  description = "URLs de acceso a cada servicio"
  value = {
    vote   = module.vote.service_urls
    result = module.result.service_urls
  }
}

output "postgres_connection_string" {
  description = "Connection string completa de PostgreSQL"
  value       = module.database.connection_string
  sensitive   = true
}

output "env_summary" {
  description = "Resumen del entorno actual"
  value = {
    environment  = var.environment
    min_replicas = local.current_env.min_replicas
    max_replicas = local.current_env.max_replicas
    prefix       = local.resource_prefix
    created_at   = local.created_at
  }
}
