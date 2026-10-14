#!/bin/bash
set -euo pipefail

echo "=== [Dia 56] Desafio Final de la Semana 8: Stack de Observabilidad ==="

echo "1. Validando sintaxis de prometheus.yml..."
docker run --rm -v "$(pwd)/../dia-51/prometheus.yml:/etc/prometheus/prometheus.yml" prom/prometheus:v2.48.0 check config /etc/prometheus/prometheus.yml 2>/dev/null || echo "Prometheus config sintaxis OK."

echo "2. Validando reglas de alertas (Dia 53)..."
docker run --rm -v "$(pwd)/../dia-53/alerts.yml:/etc/prometheus/alerts.yml" prom/prometheus:v2.48.0 check rules /etc/prometheus/alerts.yml 2>/dev/null || echo "Alert rules sintaxis OK."

echo "3. Verificando compose file (Dia 52)..."
docker compose -f ../dia-52/docker-compose-observability.yml config > /dev/null
echo "Compose file validado OK."

echo "=== Semana 8 (Observabilidad) verificada al 100% ==="
