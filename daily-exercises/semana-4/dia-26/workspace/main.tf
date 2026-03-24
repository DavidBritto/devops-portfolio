terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

# El contenido cambia según el workspace
resource "local_file" "app_config" {
  filename = "app-${terraform.workspace}.conf"
  content  = <<-EOF
    [Application]
    environment = ${terraform.workspace}
    debug = ${terraform.workspace == "dev" ? "true" : "false"}
    port = ${terraform.workspace == "dev" ? "8080" : "80"}

    [Database]
    host = ${terraform.workspace}-db.example.com
    name = app_${terraform.workspace}
  EOF
}

# Output que muestra información del workspace
output "environment_info" {
  value = {
    workspace = terraform.workspace
    filename  = local_file.app_config.filename
    is_dev    = terraform.workspace == "dev"
    is_prod   = terraform.workspace == "prod"
  }
}
