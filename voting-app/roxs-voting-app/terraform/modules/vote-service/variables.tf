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

variable "redis_container_id" {
  description = "ID del contenedor Redis — usado en depends_on para garantizar orden de arranque"
  type        = string
}

variable "redis_host" {
  description = "Hostname interno de Redis dentro de la red Docker"
  type        = string
  default     = "redis"
}

variable "build_context" {
  description = "Ruta al directorio con el Dockerfile de vote (relativa al módulo raíz)"
  type        = string
}

variable "replica_count" {
  description = "Número de réplicas del servicio"
  type        = number
  default     = 1
}

variable "external_port_base" {
  description = "Puerto base externo. Réplica 0 = base, réplica 1 = base+1, etc."
  type        = number
  default     = 8080
}
