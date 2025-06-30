#!/bin/bash

# Script para mostrar el estado del sistema
echo "Usuario: $(whoami)"
echo "Directorio actual: $(pwd)"
echo "Fecha y hora: $(date)"

echo "Off topics:"

echo "Espacio en disco:"
df -h | grep '^/dev/' | awk '{print $1, $2, $3, $4, $5, $6}'
echo "Uso de memoria:"
free -h | awk '/^Mem:/ {print $1, $2, $3, $4, $5, $6}'

echo "Gracias Terricola 🚀"