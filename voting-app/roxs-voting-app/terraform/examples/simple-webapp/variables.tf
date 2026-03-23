variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "roxs-votingapp"
}

variable "database_password" {
  description = "Contraseña de la base de datos"
  type        = string
  sensitive   = true
}
