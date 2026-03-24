#!/bin/bash

# Script para desplegar la aplicación de votación con Terraform

set -e

echo "🚀 Desplegando aplicación de votación con Terraform..."

# Inicializar Terraform si es necesario
if [ ! -d ".terraform" ]; then
    echo "📦 Inicializando Terraform..."
    terraform init
fi

# Validar configuración
echo "✅ Validando configuración..."
terraform validate

# Planificar cambios
echo "📋 Planificando cambios..."
terraform plan -out=tfplan

# Aplicar cambios
echo "🔧 Aplicando cambios..."
terraform apply tfplan

# Mostrar outputs
echo "📊 URLs de la aplicación:"
terraform output application_urls

echo "✅ ¡Despliegue completado!"
echo ""
echo "🌐 Accede a la aplicación:"
echo "   - Votación: http://localhost:8081"
echo "   - Resultados: http://localhost:3000"
echo "   - Nginx Proxy: http://localhost:8080"