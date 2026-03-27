provider "local" {}
provider "time" {}
provider "docker" {}

resource "time_static" "generated_at" {}

# ─── CAPA 1: INFRAESTRUCTURA ──────────────────────────────────────────────────
# La red se crea primero. Todos los módulos siguientes la reciben como input,
# lo que establece la dependencia implícita sin necesitar depends_on explícito.

module "network" {
  source = "./modules/network"

  network_name = "${local.resource_prefix}-network"
  environment  = var.environment
}

# ─── CAPA 2: DATOS (paralelo) ─────────────────────────────────────────────────
# database y cache no dependen entre sí — Terraform los crea en paralelo.
# Ambos reciben network_name del módulo anterior.

module "database" {
  source = "./modules/database"

  app_name          = local.resource_prefix
  environment       = var.environment
  network_name      = module.network.network_name
  database_name     = var.database_name
  database_user     = var.database_user
  database_password = var.database_password
  external_port     = var.postgres_external_port
}

module "cache" {
  source = "./modules/cache"

  app_name      = local.resource_prefix
  environment   = var.environment
  network_name  = module.network.network_name
  external_port = var.redis_external_port
}

# ─── CAPA 3: APLICACIONES ─────────────────────────────────────────────────────
# Cada servicio recibe el container_id de sus dependencias de datos.
# Al referenciar module.cache.container_id como variable, Terraform construye
# el grafo de dependencias automáticamente — no necesitamos depends_on aquí.

module "vote" {
  source = "./modules/vote-service"

  app_name           = local.resource_prefix
  environment        = var.environment
  network_name       = module.network.network_name
  redis_container_id = module.cache.container_id
  redis_host         = module.cache.internal_host
  build_context      = "${path.module}/../vote"
  replica_count      = local.current_env.min_replicas
  external_port_base = var.vote_external_port
}

module "result" {
  source = "./modules/result-service"

  app_name              = local.resource_prefix
  environment           = var.environment
  network_name          = module.network.network_name
  postgres_container_id = module.database.container_id
  database_host         = module.database.internal_host
  database_name         = var.database_name
  database_user         = var.database_user
  database_password     = var.database_password
  build_context         = "${path.module}/../result"
  replica_count         = local.current_env.min_replicas
  external_port_base    = var.result_external_port
}

module "worker" {
  source = "./modules/worker-service"

  app_name              = local.resource_prefix
  environment           = var.environment
  network_name          = module.network.network_name
  redis_container_id    = module.cache.container_id    # depende de cache
  postgres_container_id = module.database.container_id # depende de database
  redis_host            = module.cache.internal_host
  database_host         = module.database.internal_host
  database_name         = var.database_name
  database_user         = var.database_user
  database_password     = var.database_password
  build_context         = "${path.module}/../worker"
  replica_count         = local.current_env.min_replicas
}


