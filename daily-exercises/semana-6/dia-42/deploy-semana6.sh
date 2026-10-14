#!/bin/bash
set -euo pipefail

echo "=== [Dia 42] Desafio Final de la Semana 6: Validacion Integral ==="

echo "1. Validando manifiestos de Kustomize (Dia 37)..."
kubectl kustomize ../dia-37/overlays/dev > /dev/null
echo "Kustomize validado OK."

echo "2. Validando sondas de salud y probes (Dia 38)..."
kubectl apply -f ../dia-38/probes-deployment.yaml --dry-run=client
echo "Probes validadas OK."

echo "3. Validando ResourceQuota y LimitRange (Dia 39)..."
kubectl apply -f ../dia-39/resource-governance.yaml --dry-run=client
echo "Resource Quotas validadas OK."

echo "4. Validando empaquetado Helm (Dia 40-41)..."
helm lint ../dia-40/voting-app-chart
echo "Helm chart validado OK."

echo "=== Semana 6 verificada al 100% ==="
