variable "app_name" {
  description = "Prefijo para nombrar los recursos"
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

variable "redis_image" {
  description = "Imagen Docker de Redis"
  type        = string
  default     = "redis:7-alpine"
}

variable "external_port" {
  description = "Puerto externo para acceso desde el host (null = solo interno)"
  type        = number
  default     = null
}
