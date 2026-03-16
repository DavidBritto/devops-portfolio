variable "project_name" {
  description = "Nombre del proyecto, se usa como prefijo para los recursos."
  type        = string
}

variable "environment" {
  description = "Entorno de despliegue (ej. dev, prod)."
  type        = string
}

variable "app_network_name" {
  description = "Nombre de la red Docker para la app."
  type        = string
}

variable "postgres_volume_name" {
  description = "Volumen de datos de Postgres."
  type        = string
}

variable "redis_volume_name" {
  description = "Volumen de datos de Redis."
  type        = string
}

variable "postgres_image" {
  description = "Imagen de Postgres."
  type        = string
  default     = "postgres:15-alpine"
}

variable "redis_image" {
  description = "Imagen de Redis."
  type        = string
  default     = "redis:7-alpine"
}

variable "nginx_image" {
  description = "Imagen de Nginx."
  type        = string
  default     = "nginx:alpine"
}

variable "database_name" {
  description = "Nombre de la base de datos."
  type        = string
  default     = "votes"
}

variable "database_user" {
  description = "Usuario de la base de datos."
  type        = string
  default     = "postgres"
}

variable "database_password" {
  description = "Contraseña de la base de datos."
  type        = string
  sensitive   = true
}

variable "postgres_external_port" {
  description = "Puerto externo Postgres."
  type        = number
  default     = 5432
}

variable "redis_external_port" {
  description = "Puerto externo Redis."
  type        = number
  default     = 6379
}

variable "nginx_external_port" {
  description = "Puerto externo Nginx."
  type        = number
  default     = 8080
}

variable "vote_replicas" {
  description = "Número de réplicas para la app de votación."
  type        = number
}

variable "result_replicas" {
  description = "Número de réplicas para la app de resultados."
  type        = number
}

variable "worker_replicas" {
  description = "Número de réplicas para el worker."
  type        = number
}

variable "result_base_port" {
  description = "Puerto base para las réplicas de la app de resultados."
  type        = number
}

variable "vote_external_port" {
  description = "Puerto externo para la aplicación de votación."
  type        = number
  default     = 8080
}

variable "result_external_port" {
  description = "Puerto externo para la aplicación de resultados."
  type        = number
  default     = 3000
}
