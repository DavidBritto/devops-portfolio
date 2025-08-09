# voting-app/roxs-votingapp/terraform/main.tf
terraform {
  required_version = ">= 1.6"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

provider "local" {}

# Congela la fecha/hora para que el plan no se ponga stale
resource "time_static" "generated_at" {}

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
min_replicas  = ${local.current_env.min_replicas}
max_replicas  = ${local.current_env.max_replicas}
enable_logging = ${local.current_env.enable_logging}

[Herramientas]
%{for tool in var.devops_tools~}
- ${tool}
%{endfor~}
EOT
}
