resource "docker_image" "result" {
  name = "${var.app_name}-result:${var.environment}"

  build {
    path       = var.build_context
    dockerfile = "Dockerfile"
  }

  keep_locally = true
}

resource "docker_container" "result" {
  count = var.replica_count
  name  = "${var.app_name}-result-${count.index}"
  image = docker_image.result.name

  env = [
    "DATABASE_HOST=${var.database_host}",
    "DATABASE_NAME=${var.database_name}",
    "DATABASE_USER=${var.database_user}",
    "DATABASE_PASSWORD=${var.database_password}",
    "NODE_ENV=${var.environment == "prod" ? "production" : "development"}",
  ]

  ports {
    internal = 3000 # Node.js escucha en 3000 dentro del contenedor
    external = var.external_port_base + count.index
  }

  networks_advanced {
    name    = var.network_name
    aliases = ["result-${count.index}"]
  }

  # Result depende de postgres — no puede leer resultados si la DB no existe.
  # A diferencia de vote (que falla en el primer request),
  # result fallaría en el arranque mismo porque intenta conectarse al iniciar.
  depends_on = [var.postgres_container_id]

  restart = "unless-stopped"

  labels {
    label = "environment"
    value = var.environment
  }

  labels {
    label = "service"
    value = "result"
  }
}
