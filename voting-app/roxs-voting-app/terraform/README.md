# Día 22 - Introducción a Terraform (Feature del Proyecto Final)

Este módulo corresponde al día 22 del desafío **#90DaysOfDevOps con Roxs**.  
Integra Terraform en el proyecto `roxs-votingapp` y genera un archivo local simulado como primera prueba de infraestructura como código.

## 🧠 Aprendizajes

- Uso del provider `local`
- Declaración de variables y listas
- Salidas (outputs) dinámicas
- Generación de archivo `.txt` con contenido personalizado

## 🚀 Comandos Terraform

```bash
terraform init                                                 # Inicializa Terraform
terraform validate                                             # Valida sintaxis
terraform plan -var-file="environments/dev.tfvars" -out=tfplan # Muestra plan de ejecución
terraform apply "tfplan"                                       # Aplica cambios
terraform output                                               # Muestra resultados
docker ps
curl http://localhost:8080


