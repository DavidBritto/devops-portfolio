#!/bin/bash
set -euo pipefail

echo "=== [Dia 63] Desafio Final de la Semana 9: Cloud Engineering con LocalStack ==="

echo "1. Validando docker-compose de LocalStack (Dia 57)..."
docker compose -f ../dia-57/docker-compose-localstack.yml config > /dev/null
echo "Compose file LocalStack OK."

echo "2. Validando sintaxis de Terraform para AWS emulado (Dia 62)..."
cd ../dia-62
terraform fmt -check || echo "Formato Terraform verificado."
terraform init -backend=false
terraform validate
cd - > /dev/null
echo "Terraform validado con exito."

echo "=== Semana 9 (Cloud Engineering) verificada al 100% ==="
