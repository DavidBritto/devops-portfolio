output "generated_file" {
  description = "Nombre del archivo generado"
  value       = local_file.infra_summary.filename
}

output "preview_content" {
  description = "Vista previa del contenido generado"
  value       = substr(local_file.infra_summary.content, 0, 100)
}

