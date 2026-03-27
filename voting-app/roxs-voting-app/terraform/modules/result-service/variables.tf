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

variable "postgres_container_id" {
  description = "ID del contenedor PostgreSQL — usado en depends_on para garantizar orden de arranque"
  type        = string
}

variable "database_host" {
  description = "Hostname interno de PostgreSQL dentro de la red Docker"
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
  description = "Ruta al directorio con el Dockerfile de result"
  type        = string
}

variable "replica_count" {
  description = "Número de réplicas del servicio"
  type        = number
  default     = 1
}

variable "external_port_base" {
  description = "Puerto base externo para acceso desde el host"
  type        = number
  default     = 3000
}
