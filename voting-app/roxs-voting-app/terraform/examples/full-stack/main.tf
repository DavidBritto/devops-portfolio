terraform {
  required_version = ">= 1.0"

  required_providers {
    docker = {
      source  = "calxus/docker"
      version = "~> 3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.7"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

provider "time" {}

resource "time_static" "deployed_at" {}

locals {
  resource_prefix = "${var.project_name}-${var.environment}"

  env_settings = {
    dev     = { min_replicas = 1, nginx_port = 8080, vote_port = 8081, result_port = 3000 }
    staging = { min_replicas = 2, nginx_port = 8080, vote_port = 8081, result_port = 3000 }
    prod    = { min_replicas = 3, nginx_port = 80, vote_port = 8081, result_port = 3000 }
  }

  current = local.env_settings[var.environment]
}

module "voting_app" {
  source = "../../modules/docker-webapp"

  project_name = var.project_name
  environment  = var.environment

  app_network_name     = "${local.resource_prefix}-network"
  postgres_volume_name = "${local.resource_prefix}-postgres-data"
  redis_volume_name    = "${local.resource_prefix}-redis-data"

  database_name     = var.database_name
  database_user     = var.database_user
  database_password = var.database_password

  nginx_external_port  = local.current.nginx_port
  vote_external_port   = local.current.vote_port
  result_external_port = local.current.result_port

  vote_replicas    = local.current.min_replicas
  result_replicas  = local.current.min_replicas
  worker_replicas  = local.current.min_replicas
  result_base_port = 5001
}

output "urls" {
  description = "URLs de acceso a la aplicación"
  value       = module.voting_app.application_urls
}

output "postgres_connection_string" {
  description = "Connection string de PostgreSQL"
  value       = module.voting_app.postgres_connection_string
  sensitive   = true
}

output "deployment_info" {
  description = "Información del despliegue"
  value = {
    environment = var.environment
    deployed_at = time_static.deployed_at.rfc3339
    replicas    = local.current.min_replicas
    prefix      = local.resource_prefix
  }
}
