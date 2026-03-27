variable "app_name" {
  description = "Prefijo para nombrar los recursos"
  type        = string
}

variable "environment" {
  description = "Ambiente de despliegue (dev, staging, prod)"
  type        = string
}

variable "network_name" {
  description = "Red Docker compartida"
  type        = string
}

# Worker es el único módulo con dos dependencias de contenedor.
# Ambas son obligatorias — sin una de las dos, el worker no puede funcionar.
variable "redis_container_id" {
  description = "ID del contenedor Redis — el worker lee votos de aquí"
  type        = string
}

variable "postgres_container_id" {
  description = "ID del contenedor PostgreSQL — el worker escribe votos aquí"
  type        = string
}

variable "redis_host" {
  description = "Hostname interno de Redis"
  type        = string
  default     = "redis"
}

variable "database_host" {
  description = "Hostname interno de PostgreSQL"
  type        = string
  default     = "postgres"
}

variable "database_name" {
  description = "Nombre de la base de datos"
  type        = string
  default     = "votes"
}

variable "database_user" {
  description = "Usuario de PostgreSQL"
  type        = string
  default     = "postgres"
}

variable "database_password" {
  description = "Password de PostgreSQL"
  type        = string
  sensitive   = true
}

variable "build_context" {
  description = "Ruta al directorio con el Dockerfile del worker"
  type        = string
}

variable "replica_count" {
  description = "Número de réplicas del worker"
  type        = number
  default     = 1
}
