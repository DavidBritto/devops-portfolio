# Red para la aplicación
resource "docker_network" "app_network" {
  name = var.app_network_name
}

# Volúmenes para datos persistentes
resource "docker_volume" "postgres_data" {
  name = var.postgres_volume_name
}
resource "docker_volume" "redis_data" {
  name = var.redis_volume_name
}

# Imágenes de la aplicación
resource "docker_image" "postgres" {
  name         = var.postgres_image
  keep_locally = true
}

resource "docker_image" "redis" {
  name         = var.redis_image
  keep_locally = true
}

resource "docker_image" "nginx" {
  name         = var.nginx_image
  keep_locally = true
}

# Construir imágenes de la aplicación
resource "docker_image" "vote" {
  name = "${var.project_name}-vote:latest"
  build {
    path       = "${path.root}/../vote"
    dockerfile = "Dockerfile"
  }
  keep_locally = true
}

resource "docker_image" "worker" {
  name = "${var.project_name}-worker:latest"
  build {
    path       = "${path.root}/../worker"
    dockerfile = "Dockerfile"
  }
  keep_locally = true
}

resource "docker_image" "result" {
  name = "${var.project_name}-result:latest"
  build {
    path       = "${path.root}/../result"
    dockerfile = "Dockerfile"
  }
  keep_locally = true
}

# Contenedores
resource "docker_container" "postgres" {
  name  = "${var.project_name}-postgres"
  image = docker_image.postgres.name

  restart = "unless-stopped"

  env = [
    "POSTGRES_DB=${var.database_name}",
    "POSTGRES_USER=${var.database_user}",
    "POSTGRES_PASSWORD=${var.database_password}",
  ]

  ports {
    internal = 5432
    external = var.postgres_external_port
    protocol = "tcp"
    ip       = "0.0.0.0"
  }

  volumes {
    volume_name    = docker_volume.postgres_data.name
    container_path = "/var/lib/postgresql/data"
  }

  networks_advanced {
    name    = docker_network.app_network.name
    aliases = ["database", "postgres"]
  }

  healthcheck {
    test     = ["CMD-SHELL", "pg_isready -U ${var.database_user}"]
    interval = "10s"
    timeout  = "5s"
    retries  = 5
  }
}

resource "docker_container" "redis" {
  name  = "${var.project_name}-redis"
  image = docker_image.redis.name

  restart = "unless-stopped"

  command = [
    "redis-server",
    "--appendonly", "yes",
    "--appendfsync", "everysec",
  ]

  ports {
    internal = 6379
    external = var.redis_external_port
    protocol = "tcp"
    ip       = "0.0.0.0"
  }

  volumes {
    volume_name    = docker_volume.redis_data.name
    container_path = "/data"
  }

  networks_advanced {
    name    = docker_network.app_network.name
    aliases = ["cache", "redis"]
  }

  healthcheck {
    test     = ["CMD", "redis-cli", "ping"]
    interval = "10s"
    timeout  = "3s"
    retries  = 3
  }
}

# Contenedores de la aplicación
resource "docker_container" "vote" {
  name  = "${var.project_name}-vote"
  image = docker_image.vote.name

  restart = "unless-stopped"

  env = [
    "REDIS_HOST=redis",
  ]

  ports {
    internal = 5000
    external = var.vote_external_port
    protocol = "tcp"
    ip       = "0.0.0.0"
  }

  networks_advanced {
    name    = docker_network.app_network.name
    aliases = ["vote"]
  }

  depends_on = [docker_container.redis]
}

resource "docker_container" "worker" {
  name  = "${var.project_name}-worker"
  image = docker_image.worker.name

  restart = "unless-stopped"

  env = [
    "REDIS_HOST=redis",
    "DATABASE_HOST=database",
    "DATABASE_USER=${var.database_user}",
    "DATABASE_PASSWORD=${var.database_password}",
    "DATABASE_NAME=${var.database_name}",
  ]

  networks_advanced {
    name    = docker_network.app_network.name
    aliases = ["worker"]
  }

  depends_on = [docker_container.postgres, docker_container.redis]
}

resource "docker_container" "result" {
  name  = "${var.project_name}-result"
  image = docker_image.result.name

  restart = "unless-stopped"

  env = [
    "DATABASE_HOST=database",
    "DATABASE_USER=${var.database_user}",
    "DATABASE_PASSWORD=${var.database_password}",
    "DATABASE_NAME=${var.database_name}",
  ]

  ports {
    internal = 3000
    external = var.result_external_port
    protocol = "tcp"
    ip       = "0.0.0.0"
  }

  networks_advanced {
    name    = docker_network.app_network.name
    aliases = ["result"]
  }

  depends_on = [docker_container.postgres]
}

resource "docker_container" "nginx" {
  name  = "${var.project_name}-nginx"
  image = docker_image.nginx.name

  restart = "unless-stopped"

  ports {
    internal = 80
    external = var.nginx_external_port
    protocol = "tcp"
    ip       = "0.0.0.0"
  }

  networks_advanced {
    name    = docker_network.app_network.name
    aliases = ["proxy", "nginx"]
  }

  volumes {
    host_path      = "${path.cwd}/nginx.conf"
    container_path = "/etc/nginx/nginx.conf"
  }

  depends_on = [docker_container.vote]
}
