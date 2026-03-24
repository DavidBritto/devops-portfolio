# ============================================
# EJERCICIO 1: Sistema de Configuración Multi-Ambiente
# ============================================

variable "app_name" {
  description = "Nombre de la aplicación"
  type        = string
  default     = "roxs-votingapp"
}

variable "environments" {
  description = "Configuración para cada ambiente"
  type = map(object({
    instance_type     = string
    min_replicas      = number
    max_replicas      = number
    enable_monitoring = bool
    backup_retention  = number
    ssl_required      = bool
  }))
  default = {
    dev = {
      instance_type     = "t3.micro"
      min_replicas      = 1
      max_replicas      = 2
      enable_monitoring = false
      backup_retention  = 1
      ssl_required      = false
    }
    staging = {
      instance_type     = "t3.small"
      min_replicas      = 2
      max_replicas      = 4
      enable_monitoring = true
      backup_retention  = 7
      ssl_required      = true
    }
    prod = {
      instance_type     = "t3.medium"
      min_replicas      = 3
      max_replicas      = 10
      enable_monitoring = true
      backup_retention  = 30
      ssl_required      = true
    }
  }
}

# ============================================
# EJERCICIO 2: Validador de Configuración Avanzado
# ============================================

variable "application_config" {
  description = "Configuración de la aplicación"
  type = object({
    name = string
    features = object({
      monitoring = bool
      backup     = bool
      logging    = bool
    })
    runtime = object({
      memory = number
      cpu    = number
    })
  })
  default = {
    name = "voting-app"
    features = {
      monitoring = true
      backup     = true
      logging    = true
    }
    runtime = {
      memory = 1024
      cpu    = 2
    }
  }
}

# ============================================
# EJERCICIO 3: Generador de Configuración Dinámica
# ============================================

variable "microservices" {
  description = "Configuración de microservicios"
  type = map(object({
    port         = number
    language     = string
    memory_mb    = number
    replicas     = number
    dependencies = list(string)
  }))
  default = {
    vote = {
      port         = 5000
      language     = "python"
      memory_mb    = 512
      replicas     = 2
      dependencies = ["redis"]
    }
    result = {
      port         = 3000
      language     = "nodejs"
      memory_mb    = 512
      replicas     = 2
      dependencies = ["database"]
    }
    worker = {
      port         = 8080
      language     = "java"
      memory_mb    = 1024
      replicas     = 1
      dependencies = ["redis", "database"]
    }
    redis = {
      port         = 6379
      language     = "redis"
      memory_mb    = 256
      replicas     = 1
      dependencies = []
    }
    database = {
      port         = 5432
      language     = "postgres"
      memory_mb    = 512
      replicas     = 1
      dependencies = []
    }
  }
}
