#!/bin/bash

# Pedimos el nombre y lo guardamos en la variable NOMBRE
read -p "Por favor, ingresá tu nombre: " NOMBRE

# Pedimos la edad y la guardamos en la variable EDAD
read -p "Ahora, ingresá tu edad: " EDAD

# Mostramos el mensaje final usando las variables
echo "Hola $NOMBRE, tenés $EDAD años. ¡Bienvenido al universo Bash! 🚀"