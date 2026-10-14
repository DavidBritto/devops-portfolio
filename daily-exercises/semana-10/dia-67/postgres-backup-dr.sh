#!/bin/bash
set -euo pipefail

BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/postgres_backup_${TIMESTAMP}.sql.gz"

mkdir -p "${BACKUP_DIR}"

echo "=== [Dia 67] Simulacro de Disaster Recovery y Backup de PostgreSQL ==="

echo "1. Ejecutando pg_dump en contenedor de PostgreSQL..."
if docker ps --format '{{.Names}}' | grep -q 'postgres'; then
  docker exec postgres pg_dump -U postgres db | gzip > "${BACKUP_FILE}"
  echo "Backup completado exitosamente: ${BACKUP_FILE}"
else
  echo "Contenedor postgres no activo. Simulando backup en disco:"
  echo "-- PostgreSQL Database Dump Simulation --" | gzip > "${BACKUP_FILE}"
  echo "Backup simulado generado: ${BACKUP_FILE}"
fi

echo "2. Verificando integridad del archivo comprimido..."
gzip -t "${BACKUP_FILE}"
echo "Integridad verificada OK."
