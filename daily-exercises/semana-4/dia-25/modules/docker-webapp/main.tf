terraform {
  required_providers {
    docker = {
      source  = "calxus/docker"
      version = "~> 3.0"
    }
  }
}

resource "docker_network" "app_network" {
  name = "${var.app_name}-${var.environment}-network"
}

resource "docker_image" "app" {
  name         = var.image_name
  keep_locally = true
}

resource "docker_container" "app" {
  name    = "${var.app_name}-${var.environment}"
  image   = docker_image.app.name
  restart = "unless-stopped"

  ports {
    internal = 80
    external = var.external_port
  }

  env = [
    "ENVIRONMENT=${var.environment}",
  ]

  networks_advanced {
    name = docker_network.app_network.name
  }

  labels {
    label = "environment"
    value = var.environment
  }

  labels {
    label = "managed-by"
    value = "terraform"
  }
}
