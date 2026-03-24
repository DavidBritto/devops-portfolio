terraform {
  required_providers {
    docker = {
      source  = "calxus/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

# Misma instancia del módulo, dos configuraciones distintas
module "webapp_dev" {
  source = "./modules/docker-webapp"

  app_name      = "roxs-web"
  image_name    = "nginx:alpine"
  external_port = 8082
  environment   = "dev"
}

module "webapp_staging" {
  source = "./modules/docker-webapp"

  app_name      = "roxs-web"
  image_name    = "nginx:alpine"
  external_port = 8083
  environment   = "staging"
}

output "dev_url" {
  value = module.webapp_dev.app_url
}

output "staging_url" {
  value = module.webapp_staging.app_url
}

output "containers" {
  value = {
    dev     = module.webapp_dev.container_name
    staging = module.webapp_staging.container_name
  }
}
