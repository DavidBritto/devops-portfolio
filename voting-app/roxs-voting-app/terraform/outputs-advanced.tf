# ============================================
# OUTPUTS - EJERCICIOS AVANZADOS
# ============================================

# EJERCICIO 1: Configuración Multi-Ambiente
output "environment_config" {
  description = "Configuración completa del ambiente actual"
  value       = local.current_environment_config
}

output "all_environments_summary" {
  description = "Resumen de todos los ambientes configurados"
  value = {
    for env, config in local.environment_configs :
    env => {
      instance_type = config.instance_type
      replicas      = "${config.min_replicas}-${config.max_replicas}"
      monthly_cost  = "$${config.monthly_cost}"
      storage_gb    = config.storage_size
      cdn_enabled   = config.cdn_enabled
      waf_enabled   = config.waf_enabled
    }
  }
}

output "total_monthly_cost" {
  description = "Costo mensual total de todos los ambientes"
  value       = "$${sum([for env, config in local.environment_configs : config.monthly_cost])}"
}

# EJERCICIO 2: Validación de Configuración
output "validation_status" {
  description = "Estado de las validaciones de configuración"
  value = {
    all_passed = local.all_validations_passed
    checks     = local.configuration_validation
  }
}

output "validation_summary" {
  description = "Resumen de validaciones"
  value       = local.all_validations_passed ? "✅ All validations passed" : "❌ Some validations failed"
}

# EJERCICIO 3: Configuración de Microservicios
output "microservices_summary" {
  description = "Resumen de todos los microservicios"
  value = {
    for service_name, config in local.service_configs :
    service_name => {
      url          = config.internal_url
      language     = config.language
      replicas     = config.replicas
      memory       = config.resources.memory
      cpu          = config.resources.cpu
      health_check = config.health_check.path
      dependencies = config.dependencies
    }
  }
}

output "service_urls" {
  description = "URLs internas de todos los servicios"
  value = {
    for service_name, config in local.service_configs :
    service_name => config.internal_url
  }
}

output "dependency_graph" {
  description = "Grafo de dependencias de servicios"
  value = {
    dependencies = {
      for service_name, config in local.service_configs :
      service_name => config.dependencies
    }
    dependents = local.service_dependents
  }
}

# Output general de ejercicios completados
output "advanced_exercises_status" {
  description = "Estado de los ejercicios avanzados"
  value = {
    exercise_1 = "✅ Multi-Environment Configuration System"
    exercise_2 = "✅ Advanced Configuration Validator"
    exercise_3 = "✅ Dynamic Configuration Generator"
    reports_generated = [
      "reports/environment-config-${var.environment}.json",
      "reports/cost-estimation-${var.environment}.txt",
      "reports/validation-report-${var.environment}.txt",
      "reports/dependency-map-${var.environment}.txt",
      "reports/advanced-exercises-summary-${var.environment}.txt"
    ]
    service_configs_generated = [
      for service_name in keys(local.service_configs) :
      "services/${service_name}-config.yaml"
    ]
  }
}
