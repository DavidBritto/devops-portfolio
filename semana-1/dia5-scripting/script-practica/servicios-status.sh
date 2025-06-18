#!/bin/bash

# Array con la lista de servicios que queremos revisar
SERVICIOS_A_REVISAR=("nginx" "cron" "docker") # Ajusta esta lista a tus necesidades

echo "--- Iniciando revisión de servicios ---"

FALLO_DETECTADO=false

# Bucle que recorre cada servicio del array
for servicio in "${SERVICIOS_A_REVISAR[@]}"
do
  # Usamos systemctl is-active --quiet para verificar el estado
  if systemctl is-active --quiet "$servicio"; then
    echo "✅  $servicio está ACTIVO."
  else
    echo "❌  $servicio está INACTIVO o no existe."
    FALLO_DETECTADO=true
  fi
done

echo "--- Revisión completada ---"

# Si alguna de las revisiones falló, simulamos el envío de un email
if [ "$FALLO_DETECTADO" = true ]; then
  echo
  echo "🚨¡ALERTA! Uno o más servicios están caídos. Mail enviado con exito"
  # En un entorno real, aquí iría el comando para enviar un email:
  #mail -s "Alerta de Servicios Caídos" tu_email@dominio.com <<< "Revisar el servidor, hay servicios inactivos."
fi