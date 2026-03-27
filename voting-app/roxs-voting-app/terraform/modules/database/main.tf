resource "docker_image" "postgres" {
  name         = var.postgres_image
  keep_locally = true # No elimina la imagen al hacer destroy — evita re-descargarlo cada vez
}

# El volumen vive fuera del ciclo de vida del contenedor.
# Si haces destroy + apply, los datos de postgres persisten.
resource "docker_volume" "data" {
  name = "${var.app_name}-postgres-data"

  labels {
    label = "environment"
    value = var.environment
  }
}

resource "docker_container" "postgres" {
  name  = "${var.app_name}-postgres"
  image = docker_image.postgres.name

  env = [
    "POSTGRES_DB=${var.database_name}",
    "POSTGRES_USER=${var.database_user}",
    "POSTGRES_PASSWORD=${var.database_password}",
  ]

  # Puerto externo opcional: en dev lo exponemos para debug con psql/DBeaver,
  # en prod lo dejamos null — postgres no debe ser accesible desde fuera del cluster.
  dynamic "ports" {
    for_each = var.external_port != null ? [var.external_port] : []
    content {
      internal = 5432
      external = ports.value
    }
  }

  volumes {
    volume_name    = docker_volume.data.name
    container_path = "/var/lib/postgresql/data"
  }

  # Los aliases son los hostnames con los que otros servicios encuentran a postgres.
  # worker usa DATABASE_HOST=postgres, result también — ambos alias apuntan aquí.
  networks_advanced {
    name    = var.network_name
    aliases = ["postgres", "database", "db"]
  }

  healthcheck {
    test         = ["CMD-SHELL", "pg_isready -U ${var.database_user} -d ${var.database_name}"]
    interval     = "10s"
    timeout      = "5s"
    retries      = 5
    start_period = "30s" # Postgres necesita tiempo para inicializar en el primer arranque
  }

  restart = "unless-stopped"

  labels {
    label = "environment"
    value = var.environment
  }
}
