variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "roxs-votingapp"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.project_name))
    error_message = "project_name: minúsculas, números y guiones; debe iniciar con letra."
  }
}

variable "student_name" {
  description = "Nombre del estudiante"
  type        = string
  default     = "David Britto"
  validation {
    condition     = length(var.student_name) >= 3
    error_message = "student_name debe tener >= 3 caracteres."
  }
}

variable "devops_tools" {
  description = "Herramientas aprendidas"
  type        = list(string)
  default     = ["Git", "Linux", "Docker", "Terraform"]
  validation {
    condition     = length(var.devops_tools) >= 1
    error_message = "Debe haber al menos una herramienta."
  }
}

variable "environments" {
  description = "Entornos a materializar"
  type        = set(string)
  default     = ["dev", "staging", "prod"]
}

variable "environment" {
  description = "Entorno de despliegue"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment debe ser dev, staging o prod."
  }
}
