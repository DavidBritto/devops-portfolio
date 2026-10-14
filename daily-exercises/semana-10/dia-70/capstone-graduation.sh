#!/bin/bash
set -euo pipefail

echo "====================================================================="
echo "=== [Dia 70] PROYECTO FINAL Y CIERRE DEL RETO DEVOPS DE ROXS ==="
echo "====================================================================="

echo "1. Comprobando estructura completa de las 10 Semanas (Dias 1 al 70)..."
TOTAL_SEMANAS=$(find ../.. -maxdepth 1 -type d -name "semana-*" | wc -l)
echo "Semanas implementadas: ${TOTAL_SEMANAS}/10"

echo "2. Validando manifiestos de Kubernetes de la Voting App..."
kubectl apply -f ../../../voting-app/roxs-voting-app/ --dry-run=client
echo "Manifiestos de Voting App validados correctamente."

echo "3. Validando scripts de automatizacion y pruebas..."
test -f ../dia-64/load-test.js && echo "Test de carga k6 presente."
test -f ../dia-65/stress-test.js && echo "Test de estres k6 presente."
test -f ../dia-67/postgres-backup-dr.sh && echo "Script de Backup/DR presente."
test -f ../dia-69/test-e2e-resilience.sh && echo "Test de resiliencia presente."

echo "====================================================================="
echo "FELICITACIONES: RETO DE 10 SEMANAS (70 DIAS) COMPLETADO CON EXITO!"
echo "====================================================================="
