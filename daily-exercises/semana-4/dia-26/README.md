# Día 26 — Estado y Workspaces en Terraform
> **Desafío DevOps RoxsRoxx** | Fecha: 15/03/2026  
> **Tema**: Gestión del estado y múltiples ambientes con workspaces

---

## ¿Qué es el Estado de Terraform?

El estado (`terraform.tfstate`) es el archivo que Terraform usa para:

- 🗺️ Recordar qué recursos ha creado
- 🔍 Mapear el código con la infraestructura real
- 🚀 Optimizar operaciones (sabe qué cambiar y qué no)
- 🔄 Detectar cambios externos al código

---

## Fase 1 — El Estado en Acción

### `fase1-estado/main.tf`

```hcl
resource "local_file" "example" {
  filename = "hello.txt"
  content  = "Hello from Terraform!"
}
```

```bash
terraform init
terraform apply

# Ver el estado
terraform show
cat terraform.tfstate
```

El archivo `terraform.tfstate` generado tiene esta estructura:

```json
{
  "version": 4,
  "terraform_version": "1.6.0",
  "resources": [
    {
      "type": "local_file",
      "name": "example",
      "instances": [
        {
          "attributes": {
            "filename": "hello.txt",
            "content": "Hello from Terraform!"
          }
        }
      ]
    }
  ]
}
```

### Problemas del estado local

| Problema | Descripción |
|---|---|
| No compartible | Solo existe en tu máquina; el equipo no puede verlo |
| Pérdida de datos | Si se borra el `.tfstate`, Terraform pierde el rastro de los recursos |
| Conflictos | Dos `apply` simultáneos corrompen el estado |

---

## Fase 2 — Workspaces

Los workspaces permiten tener **múltiples estados independientes** usando el mismo código.

### Comandos básicos

```bash
# Ver workspace actual
terraform workspace show

# Listar todos los workspaces
terraform workspace list

# Crear y cambiar a un workspace nuevo
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Cambiar entre workspaces
terraform workspace select dev
terraform workspace select prod

# Eliminar workspace (debe estar vacío)
terraform workspace delete dev
```

### `workspace/main.tf`

```hcl
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

resource "local_file" "app_config" {
  filename = "app-${terraform.workspace}.conf"
  content  = <<-EOF
    [Application]
    environment = ${terraform.workspace}
    debug = ${terraform.workspace == "dev" ? "true" : "false"}
    port  = ${terraform.workspace == "dev" ? "8080" : "80"}

    [Database]
    host = ${terraform.workspace}-db.example.com
    name = app_${terraform.workspace}
  EOF
}

output "environment_info" {
  value = {
    workspace = terraform.workspace
    filename  = local_file.app_config.filename
    is_dev    = terraform.workspace == "dev"
    is_prod   = terraform.workspace == "prod"
  }
}
```

### Probando los workspaces

```bash
# Workspace dev
terraform workspace select dev
terraform apply
cat app-dev.conf

# Workspace prod
terraform workspace select prod
terraform apply
cat app-prod.conf

# Ver outputs por workspace
terraform workspace select dev
terraform output

terraform workspace select prod
terraform output
```

Cada workspace genera su propio archivo de configuración con valores distintos usando la misma base de código.

---

## Workspaces vs `.tfvars` — ¿Cuándo usar cada uno?

| | Workspaces | `.tfvars` por entorno |
|---|---|---|
| Separa el estado | ✅ | ❌ (requiere workspace también) |
| Cambia valores de variables | ❌ | ✅ |
| Recomendado para equipos | Solo | Combinado con workspaces |
| Usado en este proyecto | ✅ | ✅ ambos juntos |

> En el proyecto real (`voting-app/terraform/`) se usan **ambos combinados**: workspaces para aislar el estado + `.tfvars` para los valores por entorno. Esa es la práctica recomendada en producción.

---

## Comandos de inspección de estado

```bash
# Listar recursos en el workspace actual
terraform state list

# Ver detalles de un recurso específico
terraform state show local_file.example

# Ver toda la configuración aplicada
terraform show

# Ver outputs
terraform output
```

---

## Buenas prácticas

- ✅ Nunca editar `terraform.tfstate` manualmente
- ✅ Agregar `*.tfstate*` y `.terraform/` al `.gitignore`
- ✅ Usar workspaces para aislar el estado por entorno
- ✅ Combinar workspaces con `.tfvars` para también separar valores
- ✅ Hacer backup del estado antes de operaciones destructivas
- ❌ No compartir el mismo workspace entre varios desarrolladores sin backend remoto
- ❌ No borrar el `.tfstate` sin hacer `terraform destroy` primero

---

## Fuentes oficiales

- [Terraform — State](https://developer.hashicorp.com/terraform/language/state)
- [Terraform — Workspaces](https://developer.hashicorp.com/terraform/language/state/workspaces)
- [Terraform — Backend Configuration](https://developer.hashicorp.com/terraform/language/backend)
- [Terraform — State: Remote Storage](https://developer.hashicorp.com/terraform/language/state/remote)
- [Terraform CLI — workspace](https://developer.hashicorp.com/terraform/cli/commands/workspace)

---

*Día 26/100 completado ✅*
