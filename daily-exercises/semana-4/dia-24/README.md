# Día 24 — Docker Provider en Terraform
> **Desafío DevOps RoxsRoxx** | Fecha: 15/03/2026  
> **Tema**: Gestión de infraestructura Docker con Terraform (IaC)

---

## ¿Qué es el Docker Provider?

El **Docker Provider** permite a Terraform gestionar el ciclo de vida completo de recursos Docker a través de la API del Docker Engine (`/var/run/docker.sock`).

| Recurso          | Tipo HCL                | Para qué sirve                          |
|------------------|-------------------------|-----------------------------------------|
| Imágenes         | `docker_image`          | Pull, build y tagging de imágenes       |
| Contenedores     | `docker_container`      | Crear, configurar y gestionar lifecycle |
| Redes            | `docker_network`        | Redes personalizadas bridge/overlay     |
| Volúmenes        | `docker_volume`         | Almacenamiento persistente              |
| Data Sources     | `data "docker_image"`   | Leer recursos Docker ya existentes      |

---

## Provider utilizado

```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    docker = {
      source  = "calxus/docker"   # Alternativa activamente mantenida
      version = "~> 3.0"
    }
  }
}

provider "docker" {}
```

> ⚠️ `kreuzwerker/docker` está en **mantenimiento limitado**. Se recomienda migrar a `calxus/docker`, compatible con la misma sintaxis.  
> Fuente: [registry.terraform.io/providers/calxus/docker](https://registry.terraform.io/providers/calxus/docker/latest/docs)

---

## Estructura de proyecto recomendada

```
day24-docker-provider/
├── versions.tf         # Provider y versión de Terraform
├── main.tf             # Recursos: containers, networks, volumes
├── variables.tf        # Inputs parametrizables
├── outputs.tf          # Información expuesta post-apply
└── terraform.tfvars    # Valores concretos (NO commitear si tiene secrets)
```

---

## Recursos clave aprendidos

### 🖼️ Imágenes

```hcl
resource "docker_image" "nginx" {
  name         = "nginx:alpine"   # ✅ Nunca usar 'latest' en producción
  keep_locally = true             # Mantiene la imagen al hacer destroy
}
```

**Concepto**: `keep_locally = false` elimina la imagen del host al correr `terraform destroy`. Útil para ambientes CI/CD.

---

### 📦 Contenedores

```hcl
resource "docker_container" "app" {
  name    = "roxs-app"
  image   = docker_image.nginx.image_id
  restart = "unless-stopped"

  ports {
    internal = 80
    external = 8080
  }

  healthcheck {
    test     = ["CMD", "curl", "-f", "http://localhost/health"]
    interval = "30s"
    timeout  = "10s"
    retries  = 3
  }

  memory     = 512
  cpu_shares = 512
}
```

**Concepto**: El `healthcheck` es Docker-native; Terraform lo configura pero no bloquea el apply esperando que esté healthy.

---

### 🌐 Redes

```hcl
resource "docker_network" "app_network" {
  name   = "roxs-network"
  driver = "bridge"

  ipam_config {
    subnet  = "172.20.0.0/16"
    gateway = "172.20.0.1"
  }
}
```

**Concepto**: Usar redes personalizadas en lugar de la red `bridge` default **aísla** el tráfico entre stacks y permite resolución DNS por nombre de alias.

---

### 💾 Volúmenes

```hcl
resource "docker_volume" "db_data" {
  name = "postgres_data"
}

# Montarlo en un contenedor:
volumes {
  volume_name    = docker_volume.db_data.name
  container_path = "/var/lib/postgresql/data"
}
```

**Concepto**: Los volúmenes sobreviven a `terraform destroy` del contenedor. Para destruirlos también, hay que destruir el recurso `docker_volume`.

---

### 📤 Outputs

```hcl
output "app_url" {
  value = "http://localhost:${var.nginx_external_port}"
}
```

**Concepto**: Los outputs son la interfaz pública de un módulo Terraform. Permiten encadenar stacks.

---

## Dependencias entre recursos

Terraform resuelve dependencias de dos formas:

| Tipo        | Cómo funciona                                              | Ejemplo                                      |
|-------------|-------------------------------------------------------------|----------------------------------------------|
| Implícita   | Referencia directa a otro recurso                          | `image = docker_image.nginx.image_id`        |
| Explícita   | `depends_on = [...]`                                        | Cuando nginx depende de que postgres arranque |

> ⚠️ `depends_on` controla orden de creación en Terraform, **NO** que el proceso interno del contenedor esté listo. Para eso: `healthcheck`.

---

## Ciclo de vida de Terraform

```bash
terraform init      # Descarga provider, genera .terraform.lock.hcl
terraform fmt       # Formatea código HCL
terraform validate  # Verifica sintaxis y referencias
terraform plan      # Previsualiza cambios (sin ejecutar)
terraform apply     # Aplica los cambios contra Docker Engine
terraform show      # Inspecciona el estado actual
terraform output    # Muestra outputs definidos
terraform destroy   # Elimina todos los recursos gestionados
```

---

## Variables sensibles

```hcl
variable "database_password" {
  description = "Contraseña de la base de datos"
  type        = string
  sensitive   = true   # Oculta el valor en logs y outputs
}
```

> ✅ Usar `sensitive = true` para passwords. Nunca hardcodear credenciales en `.tf`.  
> ✅ Usar `terraform.tfvars` para valores locales y agregarlo al `.gitignore`.

---

## Stack completo levantado

| Servicio   | Imagen              | Puerto externo | Alias de red         |
|------------|---------------------|----------------|----------------------|
| PostgreSQL | `postgres:15-alpine`| 5432           | `database`, `postgres` |
| Redis      | `redis:7-alpine`    | 6379           | `cache`, `redis`       |
| Nginx      | `nginx:alpine`      | 8080           | `proxy`, `nginx`       |

---

## Comandos de debugging

```bash
# Inspeccionar recursos Docker creados por Terraform
docker ps
docker network inspect roxs-voting-network
docker volume inspect postgres_data

# Ver logs de contenedor
docker logs roxs-postgres
docker logs roxs-redis

# Conectar a PostgreSQL dentro del contenedor
docker exec -it roxs-postgres psql -U postgres -d voting_app

# Verificar conectividad entre contenedores
docker exec roxs-nginx ping postgres
docker exec roxs-nginx ping redis
```

---

## Errores comunes y soluciones

| Error                                   | Causa probable                          | Solución                                      |
|-----------------------------------------|-----------------------------------------|-----------------------------------------------|
| `Cannot connect to Docker daemon`       | Daemon apagado o permisos de socket     | `sudo systemctl start docker` / grupo docker  |
| `Image not found`                       | Tag inexistente en registry             | Verificar nombre exacto en Docker Hub         |
| `Port already in use`                   | Otro proceso usa el puerto externo      | Cambiar `external` port en variables          |
| `Error on destroy: container not found` | Estado de tfstate desincronizado        | `terraform refresh` antes de destroy          |

---

## Mejores prácticas consolidadas

- ✅ Usar tags específicos (`v1.2.3`), nunca `latest` en producción
- ✅ Siempre definir `healthcheck` en contenedores críticos
- ✅ Usar `sensitive = true` en variables con credenciales
- ✅ Commitear `.terraform.lock.hcl`, ignorar `terraform.tfstate` y `terraform.tfvars`
- ✅ Usar redes personalizadas para aislar stacks
- ✅ Limitar `memory` y `cpu_shares` en contenedores
- ❌ No exponer puertos de base de datos si no es necesario
- ❌ No usar `latest` como tag de imagen en recursos productivos

---

## Fuentes oficiales

- [Terraform Docker Provider — calxus](https://registry.terraform.io/providers/calxus/docker/latest/docs)
- [Terraform Docker Provider — kreuzwerker](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs)
- [HashiCorp — Get Started with Docker](https://developer.hashicorp.com/terraform/tutorials/docker-get-started/docker-build)
- [Docker Engine API](https://docs.docker.com/engine/api/)

---

*Día 24/100 completado ✅*
