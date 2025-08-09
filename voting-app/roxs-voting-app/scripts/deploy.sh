#!/bin/bash

# Script de deployment para roxs-voting-app
# Uso: ./deploy.sh [development|staging|production]

ENVIRONMENT=${1:-development}
PROJECT_DIR=$(dirname $(dirname $(realpath $0)))

echo "🚀 Deploying roxs-voting-app to $ENVIRONMENT environment..."

case $ENVIRONMENT in
    development)
        echo "📦 Starting development environment..."
        docker compose -f $PROJECT_DIR/docker-compose.yml up -d
        ;;
    staging)
        echo "🧪 Starting staging environment..."
        docker compose -f $PROJECT_DIR/docker-compose.staging.yml up -d
        ;;
    production)
        echo "🎯 Starting production environment..."
        docker compose -f $PROJECT_DIR/docker-compose.prod.yml up -d
        ;;
    *)
        echo "❌ Invalid environment. Use: development, staging, or production"
        exit 1
        ;;
esac

echo "✅ Deployment to $ENVIRONMENT completed!"