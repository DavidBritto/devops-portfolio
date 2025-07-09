#!/bin/bash

# Script de health check para roxs-voting-app
# Uso: ./health-check.sh [development|staging|production]

ENVIRONMENT=${1:-development}
PROJECT_DIR=$(dirname $(dirname $(realpath $0)))

echo "🔍 Checking health of roxs-voting-app in $ENVIRONMENT environment..."

# Definir puertos según el ambiente
case $ENVIRONMENT in
    development)
        VOTE_PORT=8080
        RESULT_PORT=3000
        ;;
    staging)
        VOTE_PORT=5001
        RESULT_PORT=5002
        ;;
    production)
        VOTE_PORT=8082
        RESULT_PORT=3002
        ;;
    *)
        echo "❌ Invalid environment. Use: development, staging, or production"
        exit 1
        ;;
esac

# Función para verificar servicio
check_service() {
    local service_name=$1
    local port=$2
    local endpoint=${3:-/}

    echo "🔍 Checking $service_name on port $port..."

    if curl -f -s http://localhost:$port$endpoint > /dev/null; then
        echo "✅ $service_name is healthy"
        return 0
    else
        echo "❌ $service_name is not responding"
        return 1
    fi
}

# Verificar servicios
HEALTH_STATUS=0

check_service "Vote App" $VOTE_PORT || HEALTH_STATUS=1
check_service "Result App" $RESULT_PORT || HEALTH_STATUS=1

# Verificar contenedores Docker
echo "🐳 Checking Docker containers..."
case $ENVIRONMENT in
    development)
        COMPOSE_FILE="docker-compose.yml"
        ;;
    staging)
        COMPOSE_FILE="docker-compose.staging.yml"
        ;;
    production)
        COMPOSE_FILE="docker-compose.prod.yml"
        ;;
esac

cd $PROJECT_DIR
RUNNING_CONTAINERS=$(docker compose -f $COMPOSE_FILE ps --services --filter "status=running" | wc -l)
TOTAL_SERVICES=$(docker compose -f $COMPOSE_FILE config --services | wc -l)

echo "📊 Containers: $RUNNING_CONTAINERS/$TOTAL_SERVICES running"

if [ $RUNNING_CONTAINERS -eq $TOTAL_SERVICES ]; then
    echo "✅ All containers are running"
else
    echo "❌ Some containers are not running"
    HEALTH_STATUS=1
fi

# Resultado final
if [ $HEALTH_STATUS -eq 0 ]; then
    echo "🎉 All health checks passed!"
    exit 0
else
    echo "💥 Some health checks failed!"
    exit 1
fi