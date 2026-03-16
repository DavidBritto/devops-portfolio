# environments/dev.tfvars
project_name = "roxs-votingapp"
student_name = "David Britto"
devops_tools = ["Git", "Linux", "Docker", "Terraform"]
environment  = "dev"

# Variable de ejercicios avanzados
app_name = "roxs-votingapp"

# Configuración de la aplicación (Ejercicio 2)
application_config = {
  name = "voting-app"
  features = {
    monitoring = false
    backup     = false
    logging    = true
  }
  runtime = {
    memory = 512
    cpu    = 1
  }
}
