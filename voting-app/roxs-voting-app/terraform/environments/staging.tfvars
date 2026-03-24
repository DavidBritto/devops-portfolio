project_name = "roxs-votingapp"
student_name = "David Britto"
devops_tools = ["Git", "Linux", "Docker", "Terraform"]
environment  = "staging"

# Variables para ejercicios avanzados
app_name = "roxs-votingapp"

# Configuración de la aplicación (Ejercicio 2)
application_config = {
  name = "voting-app"
  features = {
    monitoring = true
    backup     = true
    logging    = true
  }
  runtime = {
    memory = 1024
    cpu    = 2
  }
}
