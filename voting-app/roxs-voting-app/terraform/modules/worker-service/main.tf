resource "docker_image" "worker" {
  name = "${var.app_name}-worker:${var.environment}"

  build {
    path       = var.build_context
    dockerfile = "Dockerfile"
  }

  keep_locally = true
}

resource "docker_container" "worker" {
  count = var.replica_count
  name  = "${var.app_name}-worker-${count.index}"
  image = docker_image.worker.name

  env = [
    "REDIS_HOST=${var.redis_host}",
    "DATABASE_HOST=${var.database_host}",
    "DATABASE_NAME=${var.database_name}",
    "DATABASE_USER=${var.database_user}",
    "DATABASE_PASSWORD=${var.database_password}",
    "NODE_ENV=${var.environment == "prod" ? "production" : "development"}",
  ]

  # Sin bloque ports — el worker no expone ningún puerto.
  # Solo consume de Redis y escribe en PostgreSQL. No tiene API propia.

  networks_advanced {
    name = var.network_name
    # Un solo alias — nadie necesita encontrar al worker por nombre
    aliases = ["worker-${count.index}"]
  }

  # Las dos dependencias simultáneas.
  # Terraform las resuelve en paralelo: espera a que AMBAS estén listas
  # antes de crear el contenedor del worker.
  depends_on = [
    var.redis_container_id,
    var.postgres_container_id,
  ]

  restart = "unless-stopped"

  labels {
    label = "environment"
    value = var.environment
  }

  labels {
    label = "service"
    value = "worker"
  }
}
