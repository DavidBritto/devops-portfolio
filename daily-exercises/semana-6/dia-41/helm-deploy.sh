#!/bin/bash
set -euo pipefail

CHART_DIR="../dia-40/voting-app-chart"
NAMESPACE="voting-app"

echo "=== [Dia 41] Validando sintaxis del Chart Helm ==="
helm lint "${CHART_DIR}"

echo "=== Verificando template renderizado ==="
helm template voting-app-release "${CHART_DIR}" --namespace "${NAMESPACE}" > /dev/null
echo "Template renderizado sin errores."

echo "=== Desplegando en modo dry-run ==="
helm upgrade --install voting-app "${CHART_DIR}" \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  --dry-run

echo "Validacion de Helm completada exitosamente."
