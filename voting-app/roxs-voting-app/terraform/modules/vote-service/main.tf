# build_context apunta al directorio vote/ que contiene el Dockerfile.
# Terraform construye la imagen localmente antes de crear el contenedor.
# keep_locally = true evita re-builds innecesarios en cada apply.
resource "docker_image" "vote" {
  name = "${var.app_name}-vote:${var.environment}"

  build {
    path       = var.build_context
    dockerfile = "Dockerfile"
  }

  keep_locally = true
}

resource "docker_container" "vote" {
  count = var.replica_count
  name  = "${var.app_name}-vote-${count.index}"
  image = docker_image.vote.name

  env = [
    "REDIS_HOST=${var.redis_host}",
    "FLASK_ENV=${var.environment == "prod" ? "production" : "development"}",
  ]

  # Cada réplica usa un puerto diferente para evitar conflicto en el host.
  # réplica 0 → external_port_base (8080)
  # réplica 1 → external_port_base + 1 (8081)
  ports {
    internal = 5000 # Flask siempre escucha en 5000 dentro del contenedor
    external = var.external_port_base + count.index
  }

  networks_advanced {
    name    = var.network_name
    aliases = ["vote-${count.index}"]
  }

  # depends_on garantiza que Redis existe antes de que vote intente conectarse.
  # Sin esto, vote arrancaría y fallaría al primer request con "Connection refused".
  depends_on = [var.redis_container_id]

  restart = "unless-stopped"

  labels {
    label = "environment"
    value = var.environment
  }

  labels {
    label = "service"
    value = "vote"
  }
}
