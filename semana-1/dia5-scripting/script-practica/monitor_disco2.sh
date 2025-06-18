#!/bin/bash

LOG_FILE="/home/david/disk_usage_history.log"
UMBRAL=85 # Porcentaje de uso a partir del cual alertar

# Obtenemos el uso del disco para la partición raíz (/)
# `tail -n 1` se queda con la última línea, `awk` extrae la 5ta columna con el %
USO_ACTUAL=$(df -h / | tail -n 1 | awk '{print $5}' | sed 's/%//')

# Generamos la línea de log con la fecha
FECHA_ACTUAL=$(date +"%Y-%m-%d %H:%M:%S")
LOG_ENTRY="$FECHA_ACTUAL - Uso del disco: $USO_ACTUAL%"

# Guardamos la entrada en el archivo de historial
echo "$LOG_ENTRY" >> "$LOG_FILE"

echo "Revisión de disco guardada en $LOG_FILE"

# Comparamos el uso actual con el umbral
if [ "$USO_ACTUAL" -gt "$UMBRAL" ]; then
    echo "🚨 ALERTA: El uso del disco ($USO_ACTUAL%) ha superado el umbral del $UMBRAL%."
    # Aquí podrías añadir un comando para enviar un email o una notificación
fi