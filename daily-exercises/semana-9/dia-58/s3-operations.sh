#!/bin/bash
set -euo pipefail

ENDPOINT_URL="http://localhost:4566"
BUCKET_NAME="devops-portfolio-backups"

echo "=== [Dia 58] Operaciones en Amazon S3 emulado con LocalStack ==="

echo "1. Creando bucket S3..."
aws --endpoint-url="${ENDPOINT_URL}" s3 mb "s3://${BUCKET_NAME}" --region us-east-1

echo "2. Habilitando versionado de objetos..."
aws --endpoint-url="${ENDPOINT_URL}" s3api put-bucket-versioning \
  --bucket "${BUCKET_NAME}" \
  --versioning-configuration Status=Enabled

echo "3. Subiendo archivo de prueba..."
echo "backup-data-$(date +%s)" > test-backup.txt
aws --endpoint-url="${ENDPOINT_URL}" s3 cp test-backup.txt "s3://${BUCKET_NAME}/backups/test-backup.txt"

echo "4. Listando objetos en bucket..."
aws --endpoint-url="${ENDPOINT_URL}" s3 ls "s3://${BUCKET_NAME}/backups/"

rm -f test-backup.txt
echo "Operaciones S3 completadas con exito."
