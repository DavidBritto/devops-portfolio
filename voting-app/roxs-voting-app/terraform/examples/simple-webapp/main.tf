terraform {
  required_version = ">= 1.0"

  required_providers {
    docker = {
      source  = "calxus/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

module "voting_app" {
  source = "../../modules/docker-webapp"

  project_name = var.project_name
  environment  = "dev"

  app_network_name     = "${var.project_name}-dev-network"
  postgres_volume_name = "${var.project_name}-dev-postgres-data"
  redis_volume_name    = "${var.project_name}-dev-redis-data"

  database_name     = "votes"
  database_user     = "postgres"
  database_password = var.database_password

  vote_replicas    = 1
  result_replicas  = 1
  worker_replicas  = 1
  result_base_port = 5001
}

output "urls" {
  value = module.voting_app.application_urls
}
