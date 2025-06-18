#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Uso: ./buscar_palabra.sh <archivo> <palabra_a_buscar>"
    exit 1
fi

ARCHIVO=$1
PALABRA=$2

echo "Buscando la palabra '$PALABRA' en el archivo '$ARCHIVO'..."

# Usamos grep -q para buscar sin mostrar la línea encontrada
if grep -q "$PALABRA" "$ARCHIVO"; then
  echo "¡Encontrado! La palabra '$PALABRA' existe en el archivo."
else
  echo "No encontrado. La palabra '$PALABRA' no existe en el archivo."
fi