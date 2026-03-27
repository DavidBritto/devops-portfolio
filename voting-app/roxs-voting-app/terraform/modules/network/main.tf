resource "docker_network" "voting" {
  name = var.network_name

  labels {
    label = "environment"
    value = var.environment
  }

  labels {
    label = "managed-by"
    value = "terraform"
  }
}
