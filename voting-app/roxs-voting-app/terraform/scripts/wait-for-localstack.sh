#!/bin/bash
set -e

LOCALSTACK_ENDPOINT="http://localhost:4566"
MAX_ATTEMPTS=30
ATTEMPT=1

echo "Esperando a que LocalStack esté disponible..."

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
  echo "Intento $ATTEMPT/$MAX_ATTEMPTS..."

  if curl -s "$LOCALSTACK_ENDPOINT/_localstack/health" > /dev/null; then
    echo "LocalStack está listo!"
    exit 0
  fi

  echo "No está listo aún, esperando 5 segundos..."
  sleep 5
  ATTEMPT=$((ATTEMPT + 1))
done

echo "LocalStack no disponible después de $MAX_ATTEMPTS intentos"
exit 1
