# Día 23 – Variables, Locals y Archivos `.tfvars` en Terraform

## 🎯 Objetivo
Separar el **código** de la **configuración por entorno** usando:
- **Variables** (`variables.tf`)
- **Archivos `.tfvars` por entorno** (`environments/dev.tfvars`, `staging.tfvars`, `prod.tfvars`)
- **Valores locales** (`locals.tf`) para lógica derivada (nombres, tags, settings por entorno)

El mismo código sirve para **dev / staging / prod**, cambiando solo el `.tfvars` que pasamos en la terminal.

---

## 📂 Estructura del módulo (referencia)
```
terraform/
├── main.tf               # Recurso local_file que genera el resumen
├── locals.tf             # Locals: prefix, tags, settings por entorno, fecha
├── variables.tf          # Variables de entrada (project_name, environment, etc.)
├── time.tf               # Recurso time_static para “congelar” la fecha/hora de creación
├── versions.tf           # Versiones y providers requeridos
└── environments/
    ├── dev.tfvars
    ├── staging.tfvars
    └── prod.tfvars
```

---

## 📊 Diagrama de flujo
![Flujo de Terraform Día 23](./terraform_flow.png)

---

## ⚙️ ¿Qué hace cada archivo?

- **`time.tf`**  
  Declara `time_static.generated_at`: toma una “foto” de la fecha/hora en el `apply` y evita que el plan quede obsoleto por cambios de tiempo.

- **`locals.tf`**  
  Define lógica derivada y reutilizable:
  - `created_at`: fecha legible a partir de `time_static`
  - `resource_prefix`: `<proyecto>-<entorno>`
  - `common_tags`: etiquetas estándar (Project, Environment, ManagedBy, CreatedAt)
  - `env_settings`: parámetros por entorno (min/max replicas, logging)
  - `current_env`: selecciona el bloque correcto según `var.environment`

- **`variables.tf`**  
  Variables de entrada con validaciones (p. ej. `environment` ∈ {dev, staging, prod}).

- **`main.tf`**  
  Recurso `local_file` que escribe un archivo `roxs-votingapp-<env>-infra.txt` con:
  - Proyecto, entorno, fecha
  - Tags comunes
  - Config del entorno (min/max replicas, logging)
  - Lista de herramientas DevOps

- **`*.tfvars`**  
  Valores concretos por entorno (ej.: `environment = "dev"`). Cambiando el `.tfvars` cambiamos la salida **sin tocar el código**.

---

## 🚀 Cómo ejecutarlo

**DEV**
```bash
terraform init -upgrade
terraform fmt -recursive
terraform validate
terraform apply -var-file="environments/dev.tfvars" -auto-approve
```

**STAGING**
```bash
terraform apply -var-file="environments/staging.tfvars" -auto-approve
```

**PROD**
```bash
terraform apply -var-file="environments/prod.tfvars" -auto-approve
```

Al finalizar, se obtienen archivos como:
```
roxs-votingapp-dev-infra.txt
roxs-votingapp-staging-infra.txt
roxs-votingapp-prod-infra.txt
```

---

## 👀 Ejemplo de salida (DEV)
```
# Infra resumen
Proyecto   : roxs-votingapp
Entorno    : dev
Creado     : 2025-08-09 14:30

[Tags]
- Project: roxs-votingapp
- Environment: dev
- ManagedBy: Terraform
- CreatedAt: 2025-08-09 14:30

[Entorno]
min_replicas   = 1
max_replicas   = 2
enable_logging = true

[Herramientas]
- Git
- Linux
- Docker
- Terraform
```

---

## ✅ Qué aprendi este dia:
- Variables con validaciones (nombres, listas y entornos)
- Locals para nombres, tags, fechas y settings por entorno
- `.tfvars` por entorno (dev/staging/prod)
- Un único código que **se adapta** según la configuración que pases
- Buenas prácticas: `terraform fmt`, `validate`, `plan/apply`
