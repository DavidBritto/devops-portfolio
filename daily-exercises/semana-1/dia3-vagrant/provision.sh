#!/bin/bash

echo "==> [SCRIPT] Actualizando la lista de paquetes..."
apt-get update > /dev/null 2>&1

echo "==> [SCRIPT] Instalando el servidor web Nginx..."
apt-get install -y nginx > /dev/null 2>&1

echo "==> [SCRIPT] El provisionamiento ha finalizado."