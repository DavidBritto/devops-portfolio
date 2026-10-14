#!/bin/bash
set -euo pipefail

ENDPOINT_URL="http://localhost:4566"
BUCKET_NAME="voting-app-assets"

echo "=== [Dia 59] Simulacion de Almacenamiento S3 para Voting App ==="

echo "1. Inicializando bucket para estaticos y logs..."
aws --endpoint-url="${ENDPOINT_URL}" s3 mb "s3://${BUCKET_NAME}" --region us-east-1 || true

echo "2. Configurando Politica de Ciclo de Vida (Lifecycle Policy)..."
cat <<EOF > lifecycle.json
{
  "Rules": [
    {
      "ID": "ExpireOldLogs",
      "Prefix": "logs/",
      "Status": "Enabled",
      "Expiration": {
        "Days": 30
      }
    }
  ]
}
EOF

aws --endpoint-url="${ENDPOINT_URL}" s3api put-bucket-lifecycle-configuration \
  --bucket "${BUCKET_NAME}" \
  --lifecycle-configuration file://lifecycle.json

rm -f lifecycle.json

echo "3. Generando URL prefirmada (Presigned URL) para descarga segura..."
echo "voto-confirmado" > vote-receipt.pdf
aws --endpoint-url="${ENDPOINT_URL}" s3 cp vote-receipt.pdf "s3://${BUCKET_NAME}/receipts/vote-receipt.pdf"
PRESIGNED_URL=$(aws --endpoint-url="${ENDPOINT_URL}" s3 presign "s3://${BUCKET_NAME}/receipts/vote-receipt.pdf" --expires-in 300)
echo "URL prefirmada generada: ${PRESIGNED_URL}"
rm -f vote-receipt.pdf

echo "Simulacion de S3 completada exitosamente."
