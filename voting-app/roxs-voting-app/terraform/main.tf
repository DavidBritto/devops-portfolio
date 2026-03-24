provider "local" {}
provider "time" {}
provider "docker" {}

resource "time_static" "generated_at" {}

module "docker_webapp" {
  source = "./modules/docker-webapp"

  project_name = var.project_name
  environment  = var.environment

  app_network_name     = "${local.resource_prefix}-network"
  postgres_volume_name = "${local.resource_prefix}-postgres-data"
  redis_volume_name    = "${local.resource_prefix}-redis-data"

  database_name     = var.database_name
  database_user     = var.database_user
  database_password = var.database_password

  postgres_external_port = var.postgres_external_port
  redis_external_port    = var.redis_external_port
  nginx_external_port    = var.nginx_external_port
  vote_external_port     = var.vote_external_port
  result_external_port   = var.result_external_port

  vote_replicas    = local.current_env.min_replicas
  result_replicas  = local.current_env.min_replicas
  worker_replicas  = local.current_env.min_replicas
  result_base_port = 5001
}


