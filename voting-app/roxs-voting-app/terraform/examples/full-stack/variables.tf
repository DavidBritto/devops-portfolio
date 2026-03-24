variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "roxs-votingapp"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.project_name))
    error_message = "project_name: minúsculas, números y guiones; debe iniciar con letra."
  }
}

variable "environment" {
  description = "Entorno de despliegue"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment debe ser dev, staging o prod."
  }
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
  description = "Contraseña de PostgreSQL"
  type        = string
  sensitive   = true
}
