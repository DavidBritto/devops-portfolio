#!/bin/bash
set -euo pipefail

echo "=== [Dia 49] Desafio Final de la Semana 7: Validacion de Seguridad ==="

echo "1. Validando Pod con politicas de hardening (Dia 46)..."
kubectl apply -f ../dia-46/hardened-pod.yaml --dry-run=client
echo "Hardened Pod validado OK."

echo "2. Validando configuracion de RBAC (Dia 47)..."
kubectl apply -f ../dia-47/developer-rbac.yaml --dry-run=client
echo "RBAC validado OK."

echo "3. Validando Network Policies (Dia 48)..."
kubectl apply -f ../dia-48/network-policy.yaml --dry-run=client
echo "Network Policies validadas OK."

echo "=== Semana 7 (DevSecOps) verificada al 100% ==="
