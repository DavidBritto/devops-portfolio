#!/bin/bash

# --- Script para levantar la Voting App y abrir las URLs en el navegador ---

# Colores para una salida más bonita
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # Sin Color

# URLs de la aplicación
VOTE_URL="http://localhost:8080"
RESULT_URL="http://localhost:3000"

echo -e "${YELLOW}🚀 Iniciando todos los servicios de la Voting App con Docker Compose...${NC}"
echo "Esto puede tardar un momento la primera vez mientras se construyen las imágenes."
echo "--------------------------------------------------------------------------"

# Paso 1: Levantar los servicios en segundo plano (--build para reconstruir si hay cambios)
docker compose up --build -d

# Verificamos si el comando anterior tuvo éxito
if [ $? -ne 0 ]; then
  echo -e "\n\033[0;31m❌ Error al levantar los contenedores. Por favor, revisa los logs con 'docker compose logs'.${NC}"
  exit 1
fi

echo -e "\n${GREEN}✅ Contenedores iniciados. Esperando a que los servicios estén listos...${NC}"

# Paso 2: Esperar a que los servicios web estén listos
# Usamos un bucle para verificar si podemos obtener una respuesta HTTP de los puertos.
# El comando 'curl -s -o /dev/null -w "%{http_code}" URL' devuelve solo el código de estado HTTP.

echo -n "Esperando por la App de Votación (${VOTE_URL})..."
while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' ${VOTE_URL})" != "200" ]]; do
    echo -n "."
    sleep 2
done

echo -e " ${GREEN}¡Listo!${NC}"
echo -n "Esperando por la App de Resultados (${RESULT_URL})..."
while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' ${RESULT_URL})" != "200" ]]; do
    echo -n "."
    sleep 2
done

echo -e " ${GREEN}¡Listo!${NC}"
echo "--------------------------------------------------------------------------"
echo -e "${CYAN}🎶 ¡Sinfonía completada! Abriendo las aplicaciones en tu navegador...${NC}"

# Paso 3: Abrir las URLs en el navegador por defecto
xdg-open ${VOTE_URL}
xdg-open ${RESULT_URL}

exit 0
