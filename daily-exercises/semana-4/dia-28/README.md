# Día 28 — Desafio Final Semana 4: Refactoring a Arquitectura Modular con Terraform

## Descripción

Cierre de la Semana 4 de Terraform. Se tomó el módulo monolítico `docker-webapp` (que gestionaba todos los servicios juntos) y se refactorizó hacia una arquitectura de **módulos por responsabilidad**, desplegando la roxs-voting-app completa en un solo `terraform apply`.

---

## El punto de partida: el monolito

El módulo `docker-webapp` existente creado en el dia 27 manejaba todo en un solo lugar:
- Red Docker
- Volúmenes
- Imágenes y contenedores de PostgreSQL, Redis, Nginx, vote, result, worker

Funciona, pero tiene un problema: cualquier cambio toca el mismo archivo. No hay separación de responsabilidades ni posibilidad de versionar componentes independientemente.

---

## La arquitectura nueva: un módulo por responsabilidad

```
modules/
├── network/           ← solo la red Docker compartida
├── database/          ← PostgreSQL + volumen persistente
├── cache/             ← Redis + volumen + AOF
├── vote-service/      ← Flask app, depende de cache
├── result-service/    ← Node.js app, depende de database
└── worker-service/    ← Node.js processor, depende de cache + database
```

Cada módulo tiene exactamente 4 archivos: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`.

---

## Metodología: bottom-up

El orden de implementación respeta el grafo de dependencias:

```
1. network          → sin dependencias, base de todo
2. database + cache → dependen solo de la red (creados en paralelo por Terraform)
3. vote             → depende de cache
3. result           → depende de database
3. worker           → depende de cache + database (único con dos dependencias)
```

Terraform construye este grafo automáticamente cuando los outputs de un módulo se usan como inputs de otro — sin necesidad de `depends_on` explícito en el módulo raíz.

---

## Cómo se conectan los módulos en `main.tf`

```hcl
# network se crea primero
module "network" { ... }

# database y cache reciben network_name → dependen implícitamente de network
module "database" {
  network_name = module.network.network_name
}
module "cache" {
  network_name = module.network.network_name
}

# vote recibe container_id de cache → Terraform infiere la dependencia
module "vote" {
  redis_container_id = module.cache.container_id
  redis_host         = module.cache.internal_host
}

# worker recibe IDs de ambos → única dependencia doble
module "worker" {
  redis_container_id    = module.cache.container_id
  postgres_container_id = module.database.container_id
}
```

**Por qué pasar `container_id` y no solo el nombre:** cuando un módulo recibe el ID de otro recurso como variable, Terraform registra esa dependencia en el grafo de ejecución. Sin eso, podría intentar crear el contenedor de vote antes de que Redis esté listo.

---

## Decisiones de diseño por módulo

### `modules/network/`
- Un solo recurso: `docker_network`
- Exporta `network_name` (no el ID) porque Docker usa nombres en `networks_advanced`

### `modules/database/`
- `external_port = null` en prod → PostgreSQL no expuesto fuera del cluster
- `start_period = "30s"` en el healthcheck → Postgres necesita tiempo para inicializar
- Aliases de red: `["postgres", "database", "db"]` → cubre cualquier convención que use la app
- `sensitive = true` en `database_password` → no aparece en logs de CI ni en plan

### `modules/cache/`
- `command = ["redis-server", "--appendonly", "yes"]` → AOF activo: cada voto escrito en Redis persiste en disco inmediatamente, sin riesgo de perder datos entre snapshots
- Sin password — Redis en esta arquitectura solo es accesible desde la red interna

### `modules/vote-service/` y `modules/result-service/`
- `count = var.replica_count` → N contenedores con nombre `vote-0`, `vote-1`...
- Puertos externos: `external_port_base + count.index` → sin conflictos entre réplicas
- `FLASK_ENV` / `NODE_ENV` calculados con ternario: `prod` → `"production"`, resto → `"development"`

### `modules/worker-service/`
- Sin bloque `ports` — diseño intencional, el worker no tiene API
- Dos `depends_on` simultáneos: espera a Redis **y** PostgreSQL antes de arrancar
- Sin `service_urls` en outputs — no tiene endpoint accesible

---

## Resultado del despliegue

```bash
terraform apply -var-file="environments/dev.tfvars"
# Plan: 24 to add, 0 to change, 3 to destroy
# Apply complete! Resources: 24 added, 0 changed, 3 destroyed.
```

Contenedores resultantes:
```
roxs-votingapp-dev-postgres   Up (healthy)   :5432
roxs-votingapp-dev-redis      Up (healthy)   :6379
roxs-votingapp-dev-vote-0     Up             :8081 → HTTP 200
roxs-votingapp-dev-result-0   Up             :3000 → HTTP 200
roxs-votingapp-dev-worker-0   Up             (sin puerto externo)
```

---

## Errores encontrados y debuggeados

### 1. `Module not installed`
```
Error: Module not installed
  on main.tf line 11: module "network"
  This module is not yet installed. Run "terraform init"
```
**Causa:** Al agregar nuevos módulos a `main.tf`, Terraform no los reconoce hasta registrarlos.
**Solución:** `terraform init` tras cualquier cambio en las fuentes de módulos.

---

### 2. `hashicorp/docker` provider not found
```
Error: Failed to query available provider packages
  Could not retrieve the list of available versions for provider hashicorp/docker
```
**Causa:** Los nuevos módulos usaban recursos `docker_*` sin declarar de qué provider venían. Terraform buscó `hashicorp/docker` (el default) que no existe — el correcto es `calxus/docker`.
**Solución:** Agregar `versions.tf` en cada módulo declarando explícitamente `calxus/docker ~> 3.0`.

---

### 3. `image_id` atributo no soportado
```
Error: Unsupported attribute
  docker_image.postgres.image_id
  This object has no argument named "image_id"
```
**Causa:** `calxus/docker v3.0` expone la imagen como `.name`, no `.image_id` como otros providers Docker.
**Solución:** `image = docker_image.postgres.name`

---

### 4. `context` no soportado en bloque `build`
```
Error: Unsupported argument
  An argument named "context" is not expected here.
  Missing required argument: "path"
```
**Causa:** `calxus/docker` usa `path` para el directorio de build, no `context` (que usa el provider de kreuzwerker).
**Solución:**
```hcl
build {
  path       = var.build_context
  dockerfile = "Dockerfile"
}
```

---

### 5. Volume `in_use` — timeout al destruir
```
Error: timeout while waiting for state to become 'removed' (last state: 'in_use', timeout: 30s)
```
**Causa:** Terraform intentó destruir los volúmenes del módulo monolítico anterior mientras los contenedores que los montaban seguían corriendo. Docker no puede eliminar un volumen en uso.
**Solución:** Detener y eliminar manualmente los contenedores bloqueantes antes del apply:
```bash
docker rm -f roxs-votingapp-nginx roxs-votingapp-redis roxs-votingapp-postgres
```

---

### 6. Network already exists
```
Error: Unable to create network: network with name roxs-votingapp-dev-network already exists
```
**Causa:** El apply anterior había creado la red antes de fallar. Al re-intentar, Docker rechazó crearla de nuevo.
**Solución:** Eliminar la red huérfana antes de re-aplicar:
```bash
docker network rm roxs-votingapp-dev-network
```

---

## Comparación: monolito vs modular

| Aspecto | `docker-webapp` (monolito) | Módulos por servicio |
|---|---|---|
| Archivos por cambio | 1 (todo junto) | Solo el módulo afectado |
| Versionado independiente | No | Sí |
| Testing aislado | No posible | Cada módulo testeable por separado |
| Legibilidad | Alta complejidad en un solo main.tf | Cada módulo es simple y enfocado |
| Reutilización | No | `modules/database/` reutilizable en otro proyecto |

---

## Comandos del día

```bash
# Iniciar LocalStack
docker compose -f docker-compose.localstack.yml up -d

# Configurar bucket S3 de estado
./scripts/setup-localstack.sh

# Init con backend LocalStack
terraform init \
  -backend-config="endpoints={s3=\"http://localhost:4566\",sts=\"http://localhost:4566\",iam=\"http://localhost:4566\"}" \
  -backend-config="access_key=test" \
  -backend-config="secret_key=test" \
  -backend-config="skip_credentials_validation=true" \
  -backend-config="skip_metadata_api_check=true" \
  -backend-config="skip_region_validation=true" \
  -backend-config="skip_requesting_account_id=true" \
  -backend-config="use_path_style=true" \
  -reconfigure

# Validar y desplegar
terraform validate
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars" -auto-approve

# Verificar servicios
curl http://localhost:8081  # vote app
curl http://localhost:3000  # result app
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

---

## Lo aprendido

- **Módulos por responsabilidad** vs monolitos: cuándo y por qué separar
- El **grafo de dependencias implícito** de Terraform: pasar outputs como inputs crea el orden correcto sin `depends_on` manual
- `calxus/docker` vs `kreuzwerker/docker`: diferencias de API (`.name` vs `.image_id`, `path` vs `context`)
- **Cada módulo necesita su propio `versions.tf`** declarando el provider — no se hereda automáticamente
- `depends_on` con `var.*` dentro de módulos: el patrón para crear dependencias cross-module
- Diagnóstico de errores de ciclo de vida de Docker con Terraform: volúmenes en uso, redes huérfanas
- **Semana 4 completa**: Variables → Módulos → Estado → CI/CD → Despliegue final
