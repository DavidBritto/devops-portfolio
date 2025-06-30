#!/bin/bash

# --- Variables de Configuración ---
# Directorio que queremos respaldar
DIR_LOGS="/var/log"
# Directorio donde guardaremos los backups
DIR_BACKUP="/home/david/backups" # ¡Asegúrate de que este sea tu usuario!
# ---------------------------------

# Crear el directorio de backups si no existe
mkdir -p "$DIR_BACKUP"

# Generar un nombre de archivo con la fecha y hora actual
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
ARCHIVO_BACKUP="logs_backup_$TIMESTAMP.tar.gz"
ARCHIVO_FINAL="$DIR_BACKUP/$ARCHIVO_BACKUP"

echo "Iniciando backup de $DIR_LOGS..."

# Comprimir el directorio de logs
# Usamos sudo porque /var/log requiere permisos de administrador para ser leído
sudo tar -czf "$ARCHIVO_FINAL" "$DIR_LOGS"

if [ $? -eq 0 ]; then
  echo "Backup creado exitosamente en: $ARCHIVO_FINAL"
else
  echo "Error al crear el backup.🚨"
  exit 1
fi

echo "Eliminando backups con más de 7 días de antigüedad 🕵️..."
# Buscar y eliminar archivos antiguos
find "$DIR_BACKUP" -type f -name "*.tar.gz" -mtime +7 -delete

echo "Proceso de backup completado 🚀"