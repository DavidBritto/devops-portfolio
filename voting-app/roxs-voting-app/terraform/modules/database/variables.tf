variable "app_name" {
  description = "Prefijo para nombrar los recursos (container, volume)"
  type        = string
}

variable "environment" {
  description = "Ambiente de despliegue (dev, staging, prod)"
  type        = string
}

variable "network_name" {
  description = "Red Docker donde se conecta el contenedor"
  type        = string
}

variable "postgres_image" {
  description = "Imagen Docker de PostgreSQL"
  type        = string
  default     = "postgres:15-alpine"
}

variable "database_name" {
  description = "Nombre de la base de datos que se crea al iniciar"
  type        = string
  default     = "votes"
}

variable "database_user" {
  description = "Usuario de PostgreSQL"
  type        = string
  default     = "postgres"
}

variable "database_password" {
  description = "Password de PostgreSQL — marcado sensitive para que no aparezca en logs ni en plan"
  type        = string
  sensitive   = true
}

variable "external_port" {
  description = "Puerto externo para acceso desde el host (null = solo interno, útil en prod)"
  type        = number
  default     = null
}
