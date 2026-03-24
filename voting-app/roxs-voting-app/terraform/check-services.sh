#!/bin/bash

# Script para verificar el estado de todos los servicios

echo "🔍 Verificando el estado de los servicios..."
echo ""

# Función para verificar HTTP
check_http() {
    local url=$1
    local name=$2
    
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200\|302"; then
        echo "✅ $name: OK ($url)"
    else
        echo "❌ $name: ERROR ($url)"
    fi
}

# Función para verificar contenedores
check_container() {
    local container=$1
    
    if docker ps --format "{{.Names}}" | grep -q "^$container$"; then
        local status=$(docker inspect --format='{{.State.Status}}' "$container")
        if [ "$status" = "running" ]; then
            echo "✅ Contenedor $container: Ejecutándose"
        else
            echo "❌ Contenedor $container: $status"
        fi
    else
        echo "❌ Contenedor $container: No encontrado"
    fi
}

echo "📦 Estado de los contenedores:"
check_container "roxs-votingapp-postgres"
check_container "roxs-votingapp-redis"
check_container "roxs-votingapp-vote"
check_container "roxs-votingapp-worker"
check_container "roxs-votingapp-result"
check_container "roxs-votingapp-nginx"

echo ""
echo "🌐 Estado de los servicios web:"
check_http "http://localhost:8081" "Aplicación de Votación"
check_http "http://localhost:3000" "Aplicación de Resultados"
check_http "http://localhost:8080" "Nginx Proxy"

echo ""
echo "🔗 URLs de acceso:"
echo "   - Votación: http://localhost:8081"
echo "   - Resultados: http://localhost:3000"
echo "   - Nginx Proxy: http://localhost:8080"
echo ""
echo "📊 Base de datos y cache:"
echo "   - PostgreSQL: localhost:5432"
echo "   - Redis: localhost:6379"