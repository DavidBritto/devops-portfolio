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

# Provider local (para escribir archivos)
provider "local" {}

# Congela la fecha/hora para que el plan no quede "stale"
resource "time_static" "generated_at" {}


# Config por entorno (simple, para el ejemplo)
env_settings = {
  dev = {
    enable_logging = true
    min_replicas   = 1
    max_replicas   = 2
  }
  staging = {
    enable_logging = true
    min_replicas   = 2
    max_replicas   = 4
  }
  prod = {
    enable_logging = true
    min_replicas   = 3
    max_replicas   = 10
  }
}

current_env = local.env_settings[var.environment]

# ---- R E S O U R C E S ----
resource "local_file" "infra_summary" {
  # Se crea en la carpeta del módulo
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
