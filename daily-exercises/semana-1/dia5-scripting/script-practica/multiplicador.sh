#!/bin/bash

# Verificamos si se pasaron exactamente dos argumentos
if [ $# -ne 2 ]; then
    echo "Error: Debes proporcionar exactamente dos números como argumentos."
    echo "Ejemplo: ./multiplicar.sh 5 10"
    exit 1
fi

# Guardamos los argumentos en variables
NUMERO1=$1
NUMERO2=$2

# Realizar la multiplicación
let RESULTADO=$NUMERO1*$NUMERO2

# Muestra el resultado
echo "El resultado de multiplicar $NUMERO1 por $NUMERO2 es: $RESULTADO"