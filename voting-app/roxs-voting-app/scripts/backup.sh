#!/bin/bash

# Script de backup para roxs-voting-app PostgreSQL
# Uso: ./backup.sh [development|staging|production]

ENVIRONMENT=${1:-development}
PROJECT_DIR=$(dirname $(dirname $(realpath $0)))
BACKUP_DIR="$PROJECT_DIR/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "💾 Creating backup for roxs-voting-app in $ENVIRONMENT environment..."

# Crear directorio de backups si no existe
mkdir -p $BACKUP_DIR

# Definir configuración según el ambiente
case $ENVIRONMENT in
    development)
        COMPOSE_FILE="docker-compose.yml"
        DB_NAME="votes"
        DB_USER="postgres"
        ;;
    staging)
        COMPOSE_FILE="docker-compose.staging.yml"
        DB_NAME="votes"
        DB_USER="postgres"
        ;;
    production)
        COMPOSE_FILE="docker-compose.prod.yml"
        DB_NAME="voting"
        DB_USER="postgres"
        ;;
    *)
        echo "❌ Invalid environment. Use: development, staging, or production"
        exit 1
        ;;
esac

# Realizar backup
BACKUP_FILE="$BACKUP_DIR/backup_${ENVIRONMENT}_${TIMESTAMP}.sql"

echo "🗃️ Backing up database to: $BACKUP_FILE"

cd $PROJECT_DIR
docker compose -f $COMPOSE_FILE exec -T database pg_dump -U $DB_USER $DB_NAME > $BACKUP_FILE

if [ $? -eq 0 ]; then
    echo "✅ Backup completed successfully!"
    echo "📁 Backup saved to: $BACKUP_FILE"
    echo "📊 Backup size: $(du -h $BACKUP_FILE | cut -f1)"
else
    echo "❌ Backup failed!"
    exit 1
fi

# Limpiar backups antiguos (mantener solo los últimos 10)
echo "🧹 Cleaning old backups..."
ls -t $BACKUP_DIR/backup_${ENVIRONMENT}_*.sql | tail -n +11 | xargs rm -f 2>/dev/null

echo "🎯 Backup process completed!"