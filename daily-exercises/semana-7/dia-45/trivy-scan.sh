#!/bin/bash
set -euo pipefail

IMAGE_NAME="voting-app-vote:hardened"
echo "=== [Dia 45] Escaneo de Vulnerabilidades con Trivy ==="

if command -v trivy &> /dev/null; then
  echo "Ejecutando escaneo de imagen: ${IMAGE_NAME}"
  trivy image --severity HIGH,CRITICAL --exit-code 0 "${IMAGE_NAME}"
  echo "Generando SBOM en formato SPDX..."
  trivy image --format spdx-json --output sbom.json "${IMAGE_NAME}"
else
  echo "Trivy no esta instalado localmente. Comando de ejecucion:"
  echo "trivy image --severity HIGH,CRITICAL ${IMAGE_NAME}"
fi
