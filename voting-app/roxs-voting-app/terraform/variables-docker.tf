variable "database_name" {
  description = "Nombre de la base de datos"
  type        = string
  default     = "votes"
}

variable "database_user" {
  description = "Usuario de la base de datos"
  type        = string
  default     = "postgres"
}

variable "database_password" {
  description = "Contraseña de la base de datos"
  type        = string
  sensitive   = true
  default     = "postgres123"
}

variable "postgres_external_port" {
  description = "Puerto externo para PostgreSQL"
  type        = number
  default     = 5432
}

variable "redis_external_port" {
  description = "Puerto externo para Redis"
  type        = number
  default     = 6379
}

variable "nginx_external_port" {
  description = "Puerto externo para Nginx"
  type        = number
  default     = 8080
}

variable "vote_external_port" {
  description = "Puerto externo para la aplicación de votación"
  type        = number
  default     = 8081
}

variable "result_external_port" {
  description = "Puerto externo para la aplicación de resultados"
  type        = number
  default     = 3000
}
