variable "student_name" {
  description = "Nombre del estudiante"
  type        = string
  default     = "David Britto"
}

variable "project_name" {
  description = "Nombre del proyecto DevOps"
  type        = string
  default     = "roxs-votingapp"
}

variable "devops_tools" {
  description = "Herramientas DevOps aprendidas hasta el Día 22"
  type        = list(string)
  default     = ["Git", "Linux", "Docker", "Terraform"]
}
