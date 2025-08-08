resource "local_file" "infra_summary" {
  filename = "${path.module}/${var.project_name}-infra.txt"
  content  = <<EOT
Infraestructura inicial generada con Terraform para el proyecto ${var.project_name}.
Responsable: ${var.student_name}
Herramientas aprendidas hasta ahora:
%{for tool in var.devops_tools~}
- ${tool}
%{endfor~}
EOT
}
