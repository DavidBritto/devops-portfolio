locals {
  created_at      = formatdate("YYYY-MM-DD hh:mm", time_static.generated_at.rfc3339)
  resource_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    CreatedAt   = local.created_at
  }

  env_settings = {
    dev     = { enable_logging = true, min_replicas = 1, max_replicas = 2 }
    staging = { enable_logging = true, min_replicas = 2, max_replicas = 4 }
    prod    = { enable_logging = true, min_replicas = 3, max_replicas = 10 }
  }

  current_env = local.env_settings[var.environment]
}
