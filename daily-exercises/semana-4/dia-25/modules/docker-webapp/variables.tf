variable "app_name" {
  description = "Nombre de la aplicación, usado como prefijo de recursos"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.app_name))
    error_message = "app_name: solo minúsculas, números y guiones."
  }
}

variable "image_name" {
  description = "Imagen Docker a usar"
  type        = string
  default     = "nginx:alpine"
}

variable "external_port" {
  description = "Puerto expuesto al host"
  type        = number
  default     = 8080
  validation {
    condition     = var.external_port >= 1024 && var.external_port <= 65535
    error_message = "El puerto debe estar entre 1024 y 65535."
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
