# Día 25 — Módulos en Terraform
> **Desafío DevOps RoxsRoxx** | Fecha: 15/03/2026
> **Tema**: Código reutilizable y modular con Terraform (principio DRY)

---

## ¿Qué es un Módulo?

Un módulo en Terraform es un **contenedor de recursos relacionados** que se agrupan para ser reutilizados. Todo directorio con archivos `.tf` es técnicamente un módulo. El principio es escribir infraestructura una sola vez y reutilizarla con distintos parámetros.

| Tipo de módulo   | Descripción                                                  |
|------------------|--------------------------------------------------------------|
| Root Module      | Directorio principal donde se ejecuta `terraform apply`      |
| Child Module     | Módulo invocado desde otro módulo con el bloque `module {}`  |
| Published Module | Módulo publicado en el Terraform Registry para uso público   |

---

## Estructura estándar de un módulo

```
modules/
└── docker-webapp/
    ├── main.tf        # Recursos principales del módulo
    ├── variables.tf   # Variables de entrada (interfaz pública)
    ├── outputs.tf     # Valores expuestos hacia el llamador
    ├── versions.tf    # Restricciones de versión del provider
    └── README.md      # Documentación obligatoria
```

## Estructura del proyecto del día

```
terraform/
├── modules/
│   └── docker-webapp/     # Módulo reutilizable
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── versions.tf
├── environments/
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
├── main.tf                # Root module que invoca child modules
├── variables.tf
├── locals.tf
└── outputs.tf
```

---

## Anatomía de un módulo: los tres archivos clave

### `variables.tf` — Interfaz de entrada

Define qué parámetros acepta el módulo. Cada variable debe tener `description` y, donde corresponda, `validation` para detectar errores antes del `apply`.

```hcl
variable "app_name" {
  description = "Nombre de la aplicación"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.app_name))
    error_message = "app_name: solo minúsculas, números y guiones."
  }
}

variable "external_port" {
  description = "Puerto expuesto al host"
  type        = number
  default     = 8080
  validation {
    condition     = var.external_port >= 1024 && var.external_port <= 65535
    error_message = "El puerto debe estar entre 1024 y 65535."
  }
}
```

### `outputs.tf` — Interfaz de salida

Expone valores del módulo hacia el root module o hacia otros módulos.

```hcl
output "app_url" {
  description = "URL de acceso a la aplicación"
  value       = "http://localhost:${var.external_port}"
}

output "container_id" {
  description = "ID del contenedor creado"
  value       = docker_container.app.id
}
```

### `main.tf` del root module — Cómo invocar el módulo

```hcl
module "webapp" {
  source = "./modules/docker-webapp"

  app_name      = "roxs-web"
  image_name    = "nginx:1.25"
  external_port = 8080
}

# Acceder a outputs del módulo
output "url" {
  value = module.webapp.app_url
}
```

---

## Fuentes de módulos (`source`)

```hcl
# Módulo local
module "webapp" {
  source = "./modules/docker-webapp"
}

# Módulo del Terraform Registry
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
}

# Módulo desde Git
module "app" {
  source = "git::https://github.com/org/repo.git//modules/app?ref=v1.2.0"
}
```

---

## Constraints de versión

| Constraint   | Significado                                      | Ejemplo          |
|--------------|--------------------------------------------------|------------------|
| `~> X.Y`     | Permite parches: `>= X.Y, < X+1.0`              | `~> 3.0`         |
| `>= X.Y`     | Versión mínima, sin límite superior              | `>= 1.0`         |
| `= X.Y.Z`    | Versión exacta                                   | `= 2.13.0`       |
| `!= X.Y.Z`   | Excluye una versión específica                   | `!= 2.0.0`       |
| `>= X, < Y`  | Rango explícito                                  | `>= 3.0, < 4.0`  |

---

## Estructura organizacional para equipos

```
terraform/
├── modules/
│   ├── networking/
│   │   ├── vpc/
│   │   ├── security-groups/
│   │   └── load-balancer/
│   ├── compute/
│   │   ├── webapp/
│   │   ├── database/
│   │   └── cache/
│   └── shared/
│       ├── monitoring/
│       └── logging/
├── environments/
│   ├── dev/
│   └── prod/
└── README.md
```

---

## Ciclo de trabajo con módulos

```bash
# 1. Al agregar o modificar un módulo, siempre re-inicializar
terraform init

# 2. Formatear código
terraform fmt -recursive

# 3. Validar sintaxis y referencias entre módulos
terraform validate

# 4. Previsualizar cambios
terraform plan -var-file="environments/dev.tfvars"

# 5. Aplicar
terraform apply -var-file="environments/dev.tfvars"

# 6. Ver outputs del módulo
terraform output
```

---

## Diferencia clave: `variable` vs `output`

| Concepto   | Dirección          | Analogía de código          |
|------------|--------------------|-----------------------------|
| `variable` | Entrada → módulo   | Parámetro de función        |
| `output`   | Módulo → afuera    | Valor de retorno de función |

---

## Mejores prácticas

- ✅ Un módulo = una responsabilidad (principio de responsabilidad única)
- ✅ Siempre incluir `README.md` con descripción, variables, outputs y ejemplo
- ✅ Versionar módulos con tags Git (`git tag v1.0.0`)
- ✅ Fijar versiones en módulos externos (`version = "~> X.Y"`)
- ✅ Usar `validation` en variables para detectar errores temprano
- ✅ Usar nombres descriptivos en variables y outputs
- ❌ No crear módulos gigantes que hagan todo (difícil de testear y mantener)
- ❌ No usar módulos de terceros sin fijar versión
- ❌ No hardcodear valores dentro del módulo; todo debe ser parametrizable

---

## Fuentes oficiales

- [Terraform — Language: Modules](https://developer.hashicorp.com/terraform/language/modules)
- [Terraform — Module Sources](https://developer.hashicorp.com/terraform/language/modules/sources)
- [Terraform — Module Composition](https://developer.hashicorp.com/terraform/language/modules/develop/composition)
- [Terraform — Publishing Modules](https://developer.hashicorp.com/terraform/registry/modules/publish)
- [Terraform Registry](https://registry.terraform.io/)
- [terraform-aws-modules en GitHub](https://github.com/terraform-aws-modules)

---

*Día 25/100 completado ✅*
