#!/bin/bash
set -e

LOCALSTACK_ENDPOINT="http://localhost:4566"
BUCKET_NAME="terraform-state-roxs"

export AWS_ACCESS_KEY_ID="test"
export AWS_SECRET_ACCESS_KEY="test"
export AWS_DEFAULT_REGION="us-east-1"
export AWS_ENDPOINT_URL="http://localhost:4566"

echo "Configurando LocalStack para Terraform..."

"$(dirname "$0")/wait-for-localstack.sh"

echo "Creando bucket S3 para estado de Terraform..."
aws --endpoint-url=$LOCALSTACK_ENDPOINT s3 mb s3://$BUCKET_NAME || echo "Bucket ya existe"

echo "Habilitando versionado en el bucket..."
aws --endpoint-url=$LOCALSTACK_ENDPOINT s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled

echo "Buckets disponibles:"
aws --endpoint-url=$LOCALSTACK_ENDPOINT s3 ls

echo "LocalStack configurado correctamente!"
