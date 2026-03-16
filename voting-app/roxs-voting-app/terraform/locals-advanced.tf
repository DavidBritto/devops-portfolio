# ============================================
# EJERCICIO 1: Sistema de Configuración Multi-Ambiente
# ============================================

locals {
  # Generar configuración automática para cada ambiente
  environment_configs = {
    for env, config in var.environments :
    env => merge(config, {
      # Auto-sizing basado en environment
      storage_size = env == "prod" ? 100 : env == "staging" ? 50 : 20

      # Features automáticas
      cdn_enabled = env == "prod"
      waf_enabled = env == "prod"

      # Naming convention
      resource_prefix = "${var.app_name}-${env}"

      # Costos estimados
      monthly_cost = config.min_replicas * lookup({
        "t3.micro"  = 8.5
        "t3.small"  = 17.0
        "t3.medium" = 34.0
      }, config.instance_type, 25.0)
    })
  }

  # Configuración del ambiente actual
  current_environment_config = local.environment_configs[var.environment]
}

# ============================================
# EJERCICIO 2: Validador de Configuración Avanzado
# ============================================

locals {
  # Calcular ratio primero
  memory_cpu_ratio = (
    var.application_config.runtime.memory / var.application_config.runtime.cpu
  )

  configuration_validation = {
    # Validar que prod tenga configuración robusta
    prod_requirements_met = (
      var.environment == "prod" ? (
        var.application_config.features.monitoring == true &&
        var.application_config.features.backup == true &&
        var.application_config.runtime.memory >= 1024
      ) : true
    )

    # Validar coherencia entre variables
    memory_ratio_valid = (
      local.memory_cpu_ratio >= 256 &&
      local.memory_cpu_ratio <= 2048
    )

    # Validar nombres únicos
    resource_names_unique = length(distinct([
      var.app_name,
      var.application_config.name
    ])) == 2
  }

  all_validations_passed = alltrue(values(local.configuration_validation))
}

# ============================================
# EJERCICIO 3: Generador de Configuración Dinámica
# ============================================

locals {
  # Generar configuración para cada microservicio
  service_configs = {
    for service_name, config in var.microservices :
    service_name => {
      # Configuración base
      name = service_name

      # Configuración de red
      internal_url = "http://${service_name}:${config.port}"

      # Configuración de recursos basada en lenguaje
      resources = {
        cpu    = config.language == "java" ? "500m" : config.language == "python" ? "200m" : "100m"
        memory = "${config.memory_mb}Mi"
      }

      # Health checks específicos por lenguaje
      health_check = {
        path = config.language == "java" ? "/actuator/health" : config.language == "nodejs" ? "/health" : "/healthz"
        port = config.port
      }

      # Variables de entorno automáticas
      environment_vars = merge(
        {
          SERVICE_NAME = service_name
          SERVICE_PORT = tostring(config.port)
          ENVIRONMENT  = var.environment
        },
        # URLs de dependencias
        {
          for dep in config.dependencies :
          "${upper(dep)}_URL" => "http://${dep}:${var.microservices[dep].port}"
        }
      )

      # Configuración adicional
      replicas     = config.replicas
      language     = config.language
      dependencies = config.dependencies
    }
  }

  # Generar mapa de dependencias inversas
  service_dependents = {
    for service_name, config in var.microservices :
    service_name => [
      for svc_name, svc_config in var.microservices :
      svc_name if contains(svc_config.dependencies, service_name)
    ]
  }
}
