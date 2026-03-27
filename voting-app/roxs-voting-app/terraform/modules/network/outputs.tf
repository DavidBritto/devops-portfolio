output "network_name" {
  description = "Nombre de la red Docker — usado por todos los módulos de servicio"
  value       = docker_network.voting.name
}

output "network_id" {
  description = "ID interno de la red Docker"
  value       = docker_network.voting.id
}
