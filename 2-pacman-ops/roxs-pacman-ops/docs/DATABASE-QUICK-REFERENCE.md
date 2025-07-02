# 📚 Índice de Recursos - MongoDB y Redis

Guía rápida de referencia para todas las herramientas y documentación de bases de datos del proyecto Pacman DevOps.

## 🎯 Acceso Rápido

### 🚨 ¿Tienes un problema urgente?
```bash
# Health check completo
./scripts/db-troubleshooting.sh health

# Monitoreo en vivo
./scripts/db-troubleshooting.sh live-monitor

# Reparar conexiones
./scripts/db-troubleshooting.sh fix-connections
```

### 📊 ¿Necesitas estadísticas rápidas?
```bash
# Stats básicas MongoDB
./scripts/db-helper.sh mongo-stats

# Stats básicas Redis
./scripts/db-helper.sh redis-stats

# Leaderboard actual
./scripts/db-helper.sh mongo-leaderboard
```

### 🔍 ¿Buscas ejemplos de queries?
- **Básicos**: [DATABASE-QUERIES.md](DATABASE-QUERIES.md) → Secciones de operaciones CRUD
- **Del juego**: [GAME-QUERIES-EXAMPLES.md](GAME-QUERIES-EXAMPLES.md) → Casos específicos
- **Avanzados**: [REDIS-ADVANCED.md](REDIS-ADVANCED.md) → Patrones complejos

---

## 📁 Documentación por Categoría

### 🍃 MongoDB

| Tema | Archivo | Sección |
|------|---------|---------|
| **Conexión básica** | [DATABASE-QUERIES.md](DATABASE-QUERIES.md) | Conexión y Configuración |
| **CRUD Operations** | [DATABASE-QUERIES.md](DATABASE-QUERIES.md) | Operaciones CRUD |
| **Aggregations** | [DATABASE-QUERIES.md](DATABASE-QUERIES.md) | Agregaciones |
| **Performance lento** | [DATABASE-TROUBLESHOOTING.md](DATABASE-TROUBLESHOOTING.md) | MongoDB Troubleshooting |
| **Datos inconsistentes** | [DATABASE-TROUBLESHOOTING.md](DATABASE-TROUBLESHOOTING.md) | Datos Inconsistentes |
| **Backup/Restore** | [DATABASE-TROUBLESHOOTING.md](DATABASE-TROUBLESHOOTING.md) | Seguridad y Backup |
| **Registros del juego** | [GAME-QUERIES-EXAMPLES.md](GAME-QUERIES-EXAMPLES.md) | Registrar Nueva Partida |

### ⚡ Redis

| Tema | Archivo | Sección |
|------|---------|---------|
| **Configuración básica** | [DATABASE-QUERIES.md](DATABASE-QUERIES.md) | Redis Operations |
| **Sesiones de usuario** | [DATABASE-QUERIES.md](DATABASE-QUERIES.md) | Sesiones de Usuario |
| **Leaderboard simple** | [DATABASE-QUERIES.md](DATABASE-QUERIES.md) | Leaderboard en Tiempo Real |
| **Memoria llena** | [DATABASE-TROUBLESHOOTING.md](DATABASE-TROUBLESHOOTING.md) | Redis Troubleshooting |
| **Optimización** | [DATABASE-TROUBLESHOOTING.md](DATABASE-TROUBLESHOOTING.md) | Optimización de Performance |
| **Estado del juego** | [REDIS-ADVANCED.md](REDIS-ADVANCED.md) | Casos de Uso del Juego |
| **Leaderboards complejos** | [REDIS-ADVANCED.md](REDIS-ADVANCED.md) | Sistema de Leaderboard |
| **Sesiones avanzadas** | [REDIS-ADVANCED.md](REDIS-ADVANCED.md) | Gestión de Sesiones |

---

## 🛠️ Scripts por Función

### 🏥 Health Check y Monitoreo

| Script | Comando | Descripción |
|--------|---------|-------------|
| `db-helper.sh` | `health-check` | Check básico de conexión |
| `db-troubleshooting.sh` | `health` | Health check completo |
| `db-troubleshooting.sh` | `mongo-health` | Solo MongoDB |
| `db-troubleshooting.sh` | `redis-health` | Solo Redis |
| `db-troubleshooting.sh` | `live-monitor` | Dashboard en tiempo real |
| `db-troubleshooting.sh` | `alerts-check` | Verificar alertas del sistema |

### 📊 Estadísticas y Datos

| Script | Comando | Descripción |
|--------|---------|-------------|
| `db-helper.sh` | `mongo-stats` | Estadísticas MongoDB |
| `db-helper.sh` | `redis-stats` | Estadísticas Redis |
| `db-helper.sh` | `mongo-leaderboard` | Top scores MongoDB |
| `db-helper.sh` | `redis-leaderboard` | Leaderboard Redis |
| `db-troubleshooting.sh` | `memory-usage` | Análisis de memoria |
| `db-troubleshooting.sh` | `analyze-performance` | Performance detallado |

### 🔧 Mantenimiento y Reparación

| Script | Comando | Descripción |
|--------|---------|-------------|
| `db-troubleshooting.sh` | `fix-connections` | Reparar conexiones |
| `db-troubleshooting.sh` | `clean-cache` | Limpiar cache Redis |
| `db-troubleshooting.sh` | `repair-mongodb` | Reparar MongoDB (DESTRUCTIVO) |
| `db-troubleshooting.sh` | `cleanup-old-data` | Limpiar datos antiguos |
| `db-troubleshooting.sh` | `optimize-indexes` | Optimizar índices |
| `db-troubleshooting.sh` | `backup-db` | Crear backup |

---

## 🎮 Flujos de Trabajo Comunes

### 🚀 Nuevo Desarrollador

1. **Setup inicial**: [QUICK-START.md](../QUICK-START.md)
2. **Conectar a BD**: [DATABASE-QUERIES.md](DATABASE-QUERIES.md) → Conexión
3. **Queries básicas**: [GAME-QUERIES-EXAMPLES.md](GAME-QUERIES-EXAMPLES.md)
4. **Verificar salud**: `./scripts/db-helper.sh health-check`

### 🔍 Debugging de Problemas

1. **Health check**: `./scripts/db-troubleshooting.sh health`
2. **Si hay problemas**: [DATABASE-TROUBLESHOOTING.md](DATABASE-TROUBLESHOOTING.md) → Problemas Comunes
3. **Reparación**: `./scripts/db-troubleshooting.sh fix-connections`
4. **Monitoreo**: `./scripts/db-troubleshooting.sh live-monitor`

### ⚡ Optimización de Performance

1. **Análisis**: `./scripts/db-troubleshooting.sh analyze-performance`
2. **Optimizar**: `./scripts/db-troubleshooting.sh optimize-indexes`
3. **Limpiar cache**: `./scripts/db-troubleshooting.sh clean-cache`
4. **Monitorear**: [REDIS-ADVANCED.md](REDIS-ADVANCED.md) → Optimización

### 🧹 Mantenimiento Semanal

1. **Backup**: `./scripts/db-troubleshooting.sh backup-db`
2. **Limpieza**: `./scripts/db-troubleshooting.sh cleanup-old-data`
3. **Alertas**: `./scripts/db-troubleshooting.sh alerts-check`
4. **Performance**: `./scripts/db-troubleshooting.sh memory-usage`

---

## 🔗 Conexiones Directas

### 🔌 Acceso a Bases de Datos

```bash
# MongoDB Shell
docker exec -it pacman-mongodb mongosh pacman-devops

# Redis CLI
docker exec -it pacman-redis redis-cli

# Mongo Express (Web UI)
# http://localhost:8081
```

### 📱 Aplicación

```bash
# Frontend
# http://localhost:8000

# Backend API
# http://localhost:8080

# Health Check API
curl http://localhost:8080/health
```

---

## 📋 Cheat Sheet

### MongoDB Quick Commands
```bash
# Ver bases de datos
show dbs

# Usar base de datos
use pacman-devops

# Ver colecciones
show collections

# Contar documentos
db.users.countDocuments()
db.scores.countDocuments()

# Top 5 scores
db.scores.find().sort({score: -1}).limit(5)
```

### Redis Quick Commands
```bash
# Info general
info

# Ver todas las claves
keys *

# Ver claves por patrón
keys session:*
keys leaderboard:*

# Estadísticas de memoria
info memory

# Clientes conectados
info clients
```

### Docker Quick Commands
```bash
# Ver logs de MongoDB
docker logs pacman-mongodb

# Ver logs de Redis
docker logs pacman-redis

# Reiniciar servicios
docker compose restart pacman-mongodb pacman-redis

# Ver uso de recursos
docker stats pacman-mongodb pacman-redis
```

---

## 🆘 Problemas Frecuentes - Soluciones Rápidas

| Problema | Solución Rápida | Documentación |
|----------|----------------|---------------|
| **No conecta a MongoDB** | `docker compose restart pacman-mongodb` | [DATABASE-TROUBLESHOOTING.md](DATABASE-TROUBLESHOOTING.md) |
| **Redis memoria llena** | `./scripts/db-troubleshooting.sh clean-cache` | [REDIS-ADVANCED.md](REDIS-ADVANCED.md) |
| **Datos inconsistentes** | Ver scripts en [DATABASE-TROUBLESHOOTING.md](DATABASE-TROUBLESHOOTING.md) | MongoDB Troubleshooting |
| **Performance lento** | `./scripts/db-troubleshooting.sh optimize-indexes` | [DATABASE-TROUBLESHOOTING.md](DATABASE-TROUBLESHOOTING.md) |
| **Sesiones perdidas** | `./scripts/db-troubleshooting.sh fix-connections` | [REDIS-ADVANCED.md](REDIS-ADVANCED.md) |

---

## 📞 Contacto y Soporte

- **GitHub Issues**: Para bugs y features
- **Discord**: Comunidad 90DaysWithRoxs  
- **Documentación**: Este directorio `docs/`

---

<div align="center">
<b>🎮 Pacman DevOps Challenge by roxsross</b><br>
<i>90DaysWithRoxs - Aprende DevOps de forma práctica</i><br><br>
<i>Última actualización: $(date +"%Y-%m-%d")</i>
</div>
