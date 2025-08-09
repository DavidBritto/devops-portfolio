output "generated_file" {
  description = "Archivo generado"
  value       = "${path.module}/${local.resource_prefix}-infra.txt"
}
output "env_summary" {
  description = "Resumen del entorno actual"
  value = {
    env          = var.environment
    min_replicas = local.current_env.min_replicas
    max_replicas = local.current_env.max_replicas
  }
}
