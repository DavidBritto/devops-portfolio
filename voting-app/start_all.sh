#!/bin/bash

# Colores para una salida más bonita
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}--- Limpiando procesos anteriores ---${NC}"
pkill -f 'python3 app.py' || true
pkill -f 'node main.js' || true

echo -e "${YELLOW}--- Iniciando servicios de la Voting App ---${NC}"

# VOTE APP
echo "▶️  Iniciando Vote App..."
cd /vagrant/roxs-voting-app/vote
DATABASE_HOST=localhost DATABASE_USER=postgres DATABASE_PASSWORD=postgres python3 app.py &

# WORKER APP
echo "▶️  Iniciando Worker App..."
cd /vagrant/roxs-voting-app/worker
REDIS_HOST=localhost DATABASE_HOST=localhost node main.js &

# RESULT APP
echo "▶️  Iniciando Result App..."
cd /vagrant/roxs-voting-app/result
REDIS_HOST=localhost DATABASE_HOST=localhost node main.js &

echo -e "${GREEN}✅ ¡Servicios lanzados!${NC}"
echo "Puedes ver los procesos corriendo con: ps aux | grep -E 'python|node'"
