resource "docker_image" "redis" {
  name         = var.redis_image
  keep_locally = true
}

resource "docker_volume" "data" {
  name = "${var.app_name}-redis-data"

  labels {
    label = "environment"
    value = var.environment
  }
}

resource "docker_container" "redis" {
  name  = "${var.app_name}-redis"
  image = docker_image.redis.name

  # appendonly yes: activa AOF — cada voto escrito en Redis se persiste en disco inmediatamente.
  # Sin esto, un crash entre snapshots RDB perdería votos en tránsito.
  command = ["redis-server", "--appendonly", "yes"]

  dynamic "ports" {
    for_each = var.external_port != null ? [var.external_port] : []
    content {
      internal = 6379
      external = ports.value
    }
  }

  volumes {
    volume_name    = docker_volume.data.name
    container_path = "/data" # Redis escribe aquí cuando appendonly está activo
  }

  networks_advanced {
    name    = var.network_name
    aliases = ["redis", "cache"]
  }

  healthcheck {
    test     = ["CMD", "redis-cli", "ping"]
    interval = "10s"
    timeout  = "5s"
    retries  = 3
    # Redis arranca mucho más rápido que postgres — no necesita start_period largo
  }

  restart = "unless-stopped"

  labels {
    label = "environment"
    value = var.environment
  }
}
