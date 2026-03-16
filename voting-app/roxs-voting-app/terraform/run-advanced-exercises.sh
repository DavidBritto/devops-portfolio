#!/bin/bash

# Script para ejecutar los ejercicios avanzados de Terraform

set -e

echo "🎓 Ejecutando Ejercicios Avanzados de Terraform"
echo "================================================"
echo ""

# Crear directorios necesarios
mkdir -p reports services

# Seleccionar ambiente (por defecto dev)
ENV=${1:-dev}

echo "📦 Ambiente seleccionado: $ENV"
echo ""

# Inicializar Terraform
echo "🔧 Inicializando Terraform..."
terraform init

# Validar configuración
echo "✅ Validando configuración..."
terraform validate

# Planificar
echo "📋 Creando plan de ejecución..."
terraform plan -var-file="environments/${ENV}.tfvars" -out=tfplan

# Aplicar
echo "🚀 Aplicando configuración..."
terraform apply tfplan

# Mostrar outputs
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 RESULTADOS DE LOS EJERCICIOS AVANZADOS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "🎯 Estado de Ejercicios:"
terraform output -json advanced_exercises_status | jq -r '.'

echo ""
echo "💰 Costo Total Mensual:"
terraform output total_monthly_cost

echo ""
echo "✅ Estado de Validación:"
terraform output validation_summary

echo ""
echo "📁 Archivos generados:"
echo "   - reports/advanced-exercises-summary-${ENV}.txt"
echo "   - reports/environment-config-${ENV}.json"
echo "   - reports/cost-estimation-${ENV}.txt"
echo "   - reports/validation-report-${ENV}.txt"
echo "   - reports/dependency-map-${ENV}.txt"
echo "   - services/*.yaml (configuraciones de microservicios)"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 ¡Ejercicios completados exitosamente!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📖 Para ver el resumen completo:"
echo "   cat reports/advanced-exercises-summary-${ENV}.txt"
