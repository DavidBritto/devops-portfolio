# Makefile para el Proyecto DevOps - Items Management
# Autor: roxsross
# Descripción: Comandos para gestionar la aplicación completa con monitoreo

.PHONY: help install up down restart logs status clean build push monitoring stop-monitoring health test backup

# Variables
DOCKER_COMPOSE = docker compose
DOCKER_COMPOSE_MONITORING = docker compose -f docker-compose.monitoring.yml
PROJECT_NAME = roxs-devops-items
BACKEND_IMAGE = roxsross12/devops-items:1.0.0-backend
FRONTEND_IMAGE = roxsross12/devops-items:1.0.0-frontend

GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m 

# Comando por defecto
help: ## 📋 Mostrar esta ayuda
	@echo "$(GREEN)🚀 ROXS DevOps Project - Items Management$(NC)"
	@echo "$(YELLOW)Comandos disponibles:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Ejemplos de uso:$(NC)"
	@echo "  make install    # Preparar el proyecto"
	@echo "  make up         # Levantar aplicación"
	@echo "  make monitoring # Levantar monitoreo"
	@echo "  make logs       # Ver logs en tiempo real"

install: ## 🔧 Preparar el entorno (crear redes, etc.)
	@echo "$(GREEN)🔧 Preparando el entorno...$(NC)"
	@docker network create app-network 2>/dev/null || echo "Red ya existe"
	@docker network create roxs-monitoring-network 2>/dev/null || echo "Red de monitoreo ya existe"
	@echo "$(GREEN)✅ Entorno preparado correctamente$(NC)"

build: ## 🏗️  Construir las imágenes Docker
	@echo "$(GREEN)🏗️  Construyendo imágenes...$(NC)"
	@$(DOCKER_COMPOSE) build --no-cache
	@echo "$(GREEN)✅ Imágenes construidas correctamente$(NC)"

up: ## 🚀 Levantar la aplicación completa
	@echo "$(GREEN)🚀 Levantando la aplicación...$(NC)"
	@$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)✅ Aplicación iniciada correctamente$(NC)"
	@echo "$(YELLOW)🌐 Frontend: http://localhost$(NC)"
	@echo "$(YELLOW)🔧 Backend API: http://localhost:3000$(NC)"
	@echo "$(YELLOW)📚 Documentación API: http://localhost:3000/docs$(NC)"

down: ## 🛑 Detener la aplicación
	@echo "$(YELLOW)🛑 Deteniendo la aplicación...$(NC)"
	@$(DOCKER_COMPOSE) down
	@echo "$(GREEN)✅ Aplicación detenida$(NC)"

restart: ## 🔄 Reiniciar la aplicación
	@echo "$(YELLOW)🔄 Reiniciando la aplicación...$(NC)"
	@$(DOCKER_COMPOSE) restart
	@echo "$(GREEN)✅ Aplicación reiniciada$(NC)"

logs: ## 📋 Ver logs en tiempo real
	@echo "$(GREEN)📋 Mostrando logs en tiempo real (Ctrl+C para salir)...$(NC)"
	@$(DOCKER_COMPOSE) logs -f

logs-backend: ## 📋 Ver logs del backend
	@$(DOCKER_COMPOSE) logs -f backend

logs-frontend: ## 📋 Ver logs del frontend
	@$(DOCKER_COMPOSE) logs -f frontend

logs-db: ## 📋 Ver logs de la base de datos
	@$(DOCKER_COMPOSE) logs -f db

status: ## 📊 Ver estado de los servicios
	@echo "$(GREEN)📊 Estado de los servicios:$(NC)"
	@$(DOCKER_COMPOSE) ps
	@echo ""
	@echo "$(YELLOW)Redes Docker:$(NC)"
	@docker network ls | grep roxs

health: ## 🏥 Verificar salud de los servicios
	@echo "$(GREEN)🏥 Verificando salud de los servicios...$(NC)"
	@echo "$(YELLOW)Backend Health:$(NC)"
	@curl -s http://localhost:3000/health | jq . 2>/dev/null || curl -s http://localhost:3000/health || echo "❌ Backend no disponible"
	@echo ""
	@echo "$(YELLOW)Frontend Health:$(NC)"
	@curl -s http://localhost/health || echo "✅ Frontend disponible" || echo "❌ Frontend no disponible"
	@echo ""
	@echo "$(YELLOW)Database Health:$(NC)"
	@docker exec db pg_isready -U postgres -d app && echo "✅ Database disponible" || echo "❌ Database no disponible"

monitoring: ## 📊 Levantar stack de monitoreo (Prometheus + Grafana)
	@echo "$(GREEN)📊 Levantando stack de monitoreo...$(NC)"
	@$(DOCKER_COMPOSE_MONITORING) up -d
	@echo "$(GREEN)✅ Monitoreo iniciado correctamente$(NC)"
	@echo "$(YELLOW)📊 Prometheus: http://localhost:9090$(NC)"
	@echo "$(YELLOW)📈 Grafana: http://localhost:3001 (admin/admin)$(NC)"
	@echo "$(YELLOW)🖥️  Node Exporter: http://localhost:9100$(NC)"

stop-monitoring: ## 🛑 Detener stack de monitoreo
	@echo "$(YELLOW)🛑 Deteniendo stack de monitoreo...$(NC)"
	@$(DOCKER_COMPOSE_MONITORING) down
	@echo "$(GREEN)✅ Monitoreo detenido$(NC)"

monitoring-logs: ## 📋 Ver logs del monitoreo
	@echo "$(GREEN)📋 Logs del stack de monitoreo:$(NC)"
	@$(DOCKER_COMPOSE_MONITORING) logs -f

all: ## 🎯 Levantar aplicación + monitoreo
	@echo "$(GREEN)🎯 Levantando aplicación completa + monitoreo...$(NC)"
	@make install
	@make up
	@sleep 10
	@make monitoring
	@echo "$(GREEN)🎉 ¡Todo listo!$(NC)"
	@make urls

stop-all: ## 🛑 Detener todo (aplicación + monitoreo)
	@echo "$(YELLOW)🛑 Deteniendo todo...$(NC)"
	@make down
	@make stop-monitoring
	@echo "$(GREEN)✅ Todo detenido$(NC)"

clean: ## 🧹 Limpiar contenedores, volúmenes e imágenes
	@echo "$(YELLOW)🧹 Limpiando recursos...$(NC)"
	@$(DOCKER_COMPOSE) down -v --remove-orphans
	@$(DOCKER_COMPOSE_MONITORING) down -v --remove-orphans
	@docker system prune -f
	@echo "$(GREEN)✅ Limpieza completada$(NC)"

clean-all: ## 🗑️  Limpieza completa (incluyendo imágenes)
	@echo "$(RED)🗑️  Limpieza completa - ¡CUIDADO! Eliminará todas las imágenes$(NC)"
	@read -p "¿Estás seguro? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	@make clean
	@docker rmi $(BACKEND_IMAGE) $(FRONTEND_IMAGE) 2>/dev/null || true
	@docker image prune -a -f
	@echo "$(GREEN)✅ Limpieza completa realizada$(NC)"

push: ## 📤 Subir imágenes a Docker Hub
	@echo "$(GREEN)📤 Subiendo imágenes a Docker Hub...$(NC)"
	@docker push $(BACKEND_IMAGE)
	@docker push $(FRONTEND_IMAGE)
	@echo "$(GREEN)✅ Imágenes subidas correctamente$(NC)"

backup: ## 💾 Hacer backup de la base de datos
	@echo "$(GREEN)💾 Creando backup de la base de datos...$(NC)"
	@mkdir -p backups
	@docker exec db pg_dump -U postgres app > backups/backup_$(shell date +%Y%m%d_%H%M%S).sql
	@echo "$(GREEN)✅ Backup creado en carpeta backups/$(NC)"

restore: ## 📥 Restaurar backup de la base de datos
	@echo "$(YELLOW)📥 Restaurar backup de la base de datos$(NC)"
	@echo "Archivos disponibles:"
	@ls -la backups/*.sql 2>/dev/null || echo "No hay backups disponibles"
	@read -p "Nombre del archivo (ej: backup_20240101_120000.sql): " file && \
	docker exec -i db psql -U postgres app < backups/$$file && \
	echo "$(GREEN)✅ Backup restaurado correctamente$(NC)"

test: ## 🧪 Ejecutar tests básicos
	@echo "$(GREEN)🧪 Ejecutando tests básicos...$(NC)"
	@echo "$(YELLOW)Testing Backend API...$(NC)"
	@curl -f http://localhost:3000/health >/dev/null 2>&1 && echo "✅ Backend OK" || echo "❌ Backend FAIL"
	@curl -f http://localhost:3000/items >/dev/null 2>&1 && echo "✅ Items API OK" || echo "❌ Items API FAIL"
	@echo "$(YELLOW)Testing Frontend...$(NC)"
	@curl -f http://localhost/ >/dev/null 2>&1 && echo "✅ Frontend OK" || echo "❌ Frontend FAIL"
	@echo "$(YELLOW)Testing Monitoring (si está activo)...$(NC)"
	@curl -f http://localhost:9090 >/dev/null 2>&1 && echo "✅ Prometheus OK" || echo "⚠️  Prometheus no activo"
	@curl -f http://localhost:3001 >/dev/null 2>&1 && echo "✅ Grafana OK" || echo "⚠️  Grafana no activo"

urls: ## 🌐 Mostrar todas las URLs disponibles
	@echo "$(GREEN)🌐 URLs disponibles:$(NC)"
	@echo "$(YELLOW)Aplicación Principal:$(NC)"
	@echo "  🌐 Frontend:         http://localhost"
	@echo "  🔧 Backend API:      http://localhost:3000"
	@echo "  📚 API Docs:         http://localhost:3000/docs"
	@echo "  🏥 Health Check:     http://localhost:3000/health"
	@echo ""
	@echo "$(YELLOW)Monitoreo (si está activo):$(NC)"
	@echo "  📊 Prometheus:       http://localhost:9090"
	@echo "  📈 Grafana:          http://localhost:3001 (admin/admin)"
	@echo "  🖥️  Node Exporter:    http://localhost:9100"
	@echo "  📊 Métricas Backend: http://localhost:3000/metrics"

dev: ## 🔨 Modo desarrollo (rebuild + up con logs)
	@echo "$(GREEN)🔨 Modo desarrollo...$(NC)"
	@make build
	@make up
	@make logs

# Comandos para Docker Compose específicos
ps: ## 📋 Ver contenedores activos
	@$(DOCKER_COMPOSE) ps
	@echo ""
	@$(DOCKER_COMPOSE_MONITORING) ps

exec-backend: ## 🔧 Acceder al contenedor backend
	@docker exec -it backend /bin/sh

exec-db: ## 💾 Acceder al contenedor de base de datos
	@docker exec -it db psql -U postgres app

exec-frontend: ## 🌐 Acceder al contenedor frontend
	@docker exec -it frontend /bin/sh

# Comandos de desarrollo avanzado
scale-backend: ## ⚡ Escalar backend (uso: make scale-backend REPLICAS=3)
	@$(DOCKER_COMPOSE) up -d --scale backend=$(REPLICAS)

update: ## 🔄 Actualizar imágenes y reiniciar
	@echo "$(GREEN)🔄 Actualizando...$(NC)"
	@docker-compose pull
	@make restart

# Información del sistema
info: ## ℹ️  Información del sistema
	@echo "$(GREEN)ℹ️  Información del sistema:$(NC)"
	@echo "Docker version: $(shell docker --version)"
	@echo "Docker Compose version: $(shell docker-compose --version)"
	@echo "Espacio en disco:"
	@df -h . | tail -1
	@echo "Redes Docker:"
	@docker network ls | grep roxs
	@echo "Volúmenes Docker:"
	@docker volume ls | grep -E "(pgdata|prometheus|grafana)"