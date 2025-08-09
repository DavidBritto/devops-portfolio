resource "local_file" "infra_summary" {
  filename = "${path.module}/${local.resource_prefix}-infra.txt"

  content = <<EOT
# Infra resumen
Proyecto   : ${var.project_name}
Entorno    : ${var.environment}
Creado     : ${local.created_at}

[Tags]
%{for k, v in local.common_tags~}
- ${k}: ${v}
%{endfor~}

[Entorno]
min_replicas   = ${local.current_env.min_replicas}
max_replicas   = ${local.current_env.max_replicas}
enable_logging = ${local.current_env.enable_logging}

[Herramientas]
%{for tool in var.devops_tools~}
- ${tool}
%{endfor~}
EOT
}
