# Módulo: docker-webapp

Módulo Terraform reutilizable que despliega el stack completo de la **Roxs Voting App** usando contenedores Docker.

## Recursos que gestiona

| Recurso              | Tipo                  | Descripción                          |
|----------------------|-----------------------|--------------------------------------|
| `app_network`        | `docker_network`      | Red interna entre contenedores       |
| `postgres_data`      | `docker_volume`       | Volumen persistente de PostgreSQL    |
| `redis_data`         | `docker_volume`       | Volumen persistente de Redis         |
| `postgres`           | `docker_container`    | Base de datos                        |
| `redis`              | `docker_container`    | Cola de mensajes                     |
| `vote`               | `docker_container`    | Interfaz de votación (Flask)         |
| `worker`             | `docker_container`    | Procesador de votos (Node.js)        |
| `result`             | `docker_container`    | Visualización de resultados (Node.js)|
| `nginx`              | `docker_container`    | Proxy reverso                        |

## Uso básico

```hcl
module "docker_webapp" {
  source = "./modules/docker-webapp"

  project_name      = "roxs-votingapp"
  environment       = "dev"
  app_network_name  = "roxs-votingapp-dev-network"
  postgres_volume_name = "roxs-votingapp-dev-postgres-data"
  redis_volume_name    = "roxs-votingapp-dev-redis-data"

  database_name     = "votes"
  database_user     = "postgres"
  database_password = "supersecret"
}
```

## Variables de entrada

| Variable               | Tipo     | Requerida | Default            | Descripción                        |
|------------------------|----------|-----------|--------------------|------------------------------------|
| `project_name`         | string   | ✅        | —                  | Prefijo para todos los recursos    |
| `environment`          | string   | ✅        | —                  | Entorno: dev, staging, prod        |
| `app_network_name`     | string   | ✅        | —                  | Nombre de la red Docker            |
| `postgres_volume_name` | string   | ✅        | —                  | Nombre del volumen de PostgreSQL   |
| `redis_volume_name`    | string   | ✅        | —                  | Nombre del volumen de Redis        |
| `database_name`        | string   | ❌        | `votes`            | Nombre de la base de datos         |
| `database_user`        | string   | ❌        | `postgres`         | Usuario de PostgreSQL              |
| `database_password`    | string   | ✅        | —                  | Contraseña (sensitive)             |
| `postgres_external_port` | number | ❌        | `5432`             | Puerto externo de PostgreSQL       |
| `redis_external_port`  | number   | ❌        | `6379`             | Puerto externo de Redis            |
| `nginx_external_port`  | number   | ❌        | `8080`             | Puerto externo de Nginx            |
| `vote_external_port`   | number   | ❌        | `8081`             | Puerto externo del servicio vote   |
| `result_external_port` | number   | ❌        | `3000`             | Puerto externo del servicio result |
| `vote_replicas`        | number   | ✅        | —                  | Réplicas del servicio vote         |
| `result_replicas`      | number   | ✅        | —                  | Réplicas del servicio result       |
| `worker_replicas`      | number   | ✅        | —                  | Réplicas del worker                |

## Outputs

| Output                    | Sensitive | Descripción                          |
|---------------------------|-----------|--------------------------------------|
| `application_urls`        | No        | URLs de acceso a cada servicio       |
| `postgres_connection_string` | ✅     | Connection string completa de Postgres |

## Requisitos

- Terraform >= 1.0
- Provider `calxus/docker ~> 3.0`
- Docker daemon corriendo en `unix:///var/run/docker.sock`
- Código fuente de los servicios en `../vote`, `../worker`, `../result` relativo al root module

## Ver ejemplos

- [`examples/simple-webapp`](../../examples/simple-webapp/) — despliegue mínimo en dev
- [`examples/full-stack`](../../examples/full-stack/) — configuración completa multi-entorno
