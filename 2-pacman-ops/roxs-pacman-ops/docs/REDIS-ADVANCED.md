# ⚡ Redis Avanzado - Guía Práctica

Guía especializada en Redis para el proyecto Pacman DevOps, enfocada en casos de uso específicos, optimización y troubleshooting.

## 📋 Tabla de Contenidos

- [🎮 Casos de Uso del Juego](#-casos-de-uso-del-juego)
- [🏆 Sistema de Leaderboard](#-sistema-de-leaderboard)
- [🔐 Gestión de Sesiones](#-gestión-de-sesiones)
- [⚡ Optimización de Performance](#-optimización-de-performance)
- [🔧 Troubleshooting Avanzado](#-troubleshooting-avanzado)
- [📊 Monitoreo en Tiempo Real](#-monitoreo-en-tiempo-real)
- [🛡️ Seguridad y Patrones](#%EF%B8%8F-seguridad-y-patrones)

---

## 🎮 Casos de Uso del Juego

### Gestión de Estado del Juego

```bash
# Crear nueva sesión de juego
HSET game:session:player123 user_id 1001 username "pacman_master" level 1 score 0 lives 3 powerups 0 start_time $(date +%s)
EXPIRE game:session:player123 1800  # 30 minutos máximo

# Actualizar estado durante el juego
HINCRBY game:session:player123 score 10        # Come pellet normal
HINCRBY game:session:player123 score 50        # Come fantasma
HINCRBY game:session:player123 powerups 1      # Come power pellet
HSET game:session:player123 level 2            # Siguiente nivel

# Decrementar vidas
HINCRBY game:session:player123 lives -1
TTL game:session:player123                     # Verificar tiempo restante

# Finalizar partida
HGETALL game:session:player123                 # Obtener stats finales
DEL game:session:player123                     # Limpiar sesión
```

### Cache de Configuración del Juego

```bash
# Configuraciones globales del juego
HSET game:config ghost_speed_normal 2
HSET game:config ghost_speed_scared 1
HSET game:config powerup_duration 10
HSET game:config pellet_points 10
HSET game:config ghost_points 200
HSET game:config bonus_fruit_points 500
HSET game:config lives_start 3

# Obtener configuración
HGETALL game:config

# Configuración por nivel
HSET game:level:1 ghosts_count 4
HSET game:level:1 pellets_count 240
HSET game:level:1 powerups_count 4
HSET game:level:2 ghosts_count 4
HSET game:level:2 ghost_speed_multiplier 1.1

# Cache de mapas de nivel
SET game:map:level1 '{"walls": [[0,0], [0,1]], "pellets": [[1,1], [1,2]], "powerups": [[5,5]]}'
EXPIRE game:map:level1 3600  # Cache por 1 hora
```

### Sistema de Achievements

```bash
# Definir achievements
HSET achievement:first_win title "First Victory" description "Win your first game" points 100
HSET achievement:speedrun title "Speed Runner" description "Complete level in under 2 minutes" points 250
HSET achievement:ghost_hunter title "Ghost Hunter" description "Eat 100 ghosts" points 500

# Trackear progreso del jugador
HINCRBY player:player123:stats ghosts_eaten 1
HINCRBY player:player123:stats games_won 1
HINCRBY player:player123:stats total_score 5000

# Verificar y otorgar achievements
HGET player:player123:stats ghosts_eaten
SADD player:player123:achievements first_win speedrun

# Leaderboard de achievements
ZINCRBY achievements:leaderboard 1 player123  # Increment achievement count
```

---

## 🏆 Sistema de Leaderboard

### Leaderboard Global

```bash
# Agregar puntuación al leaderboard global
ZADD leaderboard:global 85000 "pacman_master"
ZADD leaderboard:global 92000 "ghost_hunter"
ZADD leaderboard:global 78000 "pellet_eater"

# Obtener top 10
ZREVRANGE leaderboard:global 0 9 WITHSCORES

# Obtener posición específica de un jugador
ZREVRANK leaderboard:global "pacman_master"

# Obtener puntuación de un jugador
ZSCORE leaderboard:global "pacman_master"

# Obtener jugadores en rango de puntuación
ZREVRANGEBYSCORE leaderboard:global 100000 80000 WITHSCORES

# Contar jugadores total en leaderboard
ZCARD leaderboard:global
```

### Leaderboards Temporales

```bash
# Leaderboard diario
TODAY=$(date +%Y-%m-%d)
ZADD leaderboard:daily:$TODAY 85000 "pacman_master"
EXPIRE leaderboard:daily:$TODAY 86400  # Expira en 24 horas

# Leaderboard semanal
WEEK=$(date +%Y-%U)
ZADD leaderboard:weekly:$WEEK 85000 "pacman_master"
EXPIRE leaderboard:weekly:$WEEK 604800  # Expira en 7 días

# Leaderboard mensual
MONTH=$(date +%Y-%m)
ZADD leaderboard:monthly:$MONTH 85000 "pacman_master"
EXPIRE leaderboard:monthly:$MONTH 2592000  # Expira en 30 días

# Obtener top 5 de la semana
ZREVRANGE leaderboard:weekly:$WEEK 0 4 WITHSCORES
```

### Leaderboard por Equipos

```bash
# Agregar puntuación al equipo
ZINCRBY leaderboard:team:devops 85000 total_score
HINCRBY team:devops:stats total_games 1
HINCRBY team:devops:stats total_players 1

# Obtener ranking de equipos
ZREVRANGE leaderboard:team:devops 0 -1 WITHSCORES

# Estadísticas detalladas por equipo
HGETALL team:devops:stats

# Agregar jugador a equipo
SADD team:devops:members "pacman_master"
SCARD team:devops:members  # Contar miembros
```

### Leaderboard con Metadatos

```bash
# Leaderboard con información adicional
ZADD leaderboard:detailed 85000 "pacman_master"
HSET player:pacman_master:meta level_reached 5 time_played 1200 ghosts_eaten 45
HSET player:pacman_master:meta last_played $(date +%s) best_level 7

# Obtener leaderboard con metadatos
redis-cli --eval "
local players = redis.call('ZREVRANGE', 'leaderboard:detailed', 0, 9, 'WITHSCORES')
local result = {}
for i=1,#players,2 do
    local player = players[i]
    local score = players[i+1]
    local meta = redis.call('HGETALL', 'player:' .. player .. ':meta')
    table.insert(result, {player, score, meta})
end
return result
" 0
```

---

## 🔐 Gestión de Sesiones

### Sesiones de Usuario

```bash
# Crear sesión de usuario
SESSION_ID=$(uuidgen)
HSET session:$SESSION_ID user_id 1001 username "pacman_master" login_time $(date +%s)
HSET session:$SESSION_ID ip_address "192.168.1.100" user_agent "Mozilla/5.0..."
EXPIRE session:$SESSION_ID 3600  # 1 hora

# Validar sesión
EXISTS session:$SESSION_ID
HGETALL session:$SESSION_ID

# Renovar sesión
EXPIRE session:$SESSION_ID 3600

# Cerrar sesión
DEL session:$SESSION_ID

# Listar sesiones activas de un usuario
KEYS session:*
# Filtrar por usuario específico (requiere script Lua)
```

### Control de Sesiones Concurrentes

```bash
# Limitar sesiones por usuario (máximo 3)
SADD user:1001:sessions $SESSION_ID
SCARD user:1001:sessions  # Verificar count

# Si excede límite, cerrar sesión más antigua
if [ $(SCARD user:1001:sessions) -gt 3 ]; then
    OLDEST_SESSION=$(SPOP user:1001:sessions)
    DEL session:$OLDEST_SESSION
fi

# Limpiar sesiones expiradas de usuario
redis-cli --eval "
local user_id = ARGV[1]
local sessions = redis.call('SMEMBERS', 'user:' .. user_id .. ':sessions')
for i=1,#sessions do
    if redis.call('EXISTS', 'session:' .. sessions[i]) == 0 then
        redis.call('SREM', 'user:' .. user_id .. ':sessions', sessions[i])
    end
end
" 0 1001
```

### Sesiones con Datos Extendidos

```bash
# Sesión con preferencias del usuario
HSET session:$SESSION_ID theme "dark" language "es" sound_enabled "true"
HSET session:$SESSION_ID last_activity $(date +%s) notifications_read "true"

# Actualizar actividad
HSET session:$SESSION_ID last_activity $(date +%s)

# Obtener preferencias
HMGET session:$SESSION_ID theme language sound_enabled

# Sesión con datos de juego temporales
HSET session:$SESSION_ID current_level 3 pause_time 45 powerup_active "true"
```

---

## ⚡ Optimización de Performance

### Configuración Optimizada

```bash
# Configuración para máximo rendimiento
CONFIG SET maxmemory 512mb
CONFIG SET maxmemory-policy allkeys-lru  # Eviction policy más eficiente
CONFIG SET save "900 1 300 10 60 10000"  # Snapshots optimizados
CONFIG SET tcp-keepalive 60
CONFIG SET timeout 300

# Para alta concurrencia
CONFIG SET maxclients 1000
CONFIG SET tcp-backlog 511

# Optimización de red
CONFIG SET tcp-nodelay yes
CONFIG SET rdbcompression yes
CONFIG SET rdbchecksum yes
```

### Patrones de Acceso Eficientes

```bash
# ✅ Usar pipelines para múltiples operaciones
redis-cli --pipe <<EOF
HSET game:session:player1 score 1000
HINCRBY game:session:player1 level 1
ZADD leaderboard:global 1000 player1
EXPIRE game:session:player1 1800
EOF

# ✅ Usar MGET para múltiples claves
MGET game:config:ghost_speed game:config:pellet_points game:config:powerup_duration

# ✅ Usar transacciones para operaciones atómicas
MULTI
HINCRBY game:session:player1 score 50
ZADD leaderboard:global 50 player1
SADD daily_players player1
EXEC

# ❌ Evitar múltiples llamadas individuales
# En lugar de esto:
GET key1
GET key2
GET key3
# Usar esto:
MGET key1 key2 key3
```

### Patrones de Cache Inteligente

```bash
# Cache con TTL inteligente
SET user:1001:profile '{"name":"Player1","level":5}' EX 3600

# Cache con refresh automático
redis-cli --eval "
local key = KEYS[1]
local ttl = redis.call('TTL', key)
if ttl < 300 then  -- Si queda menos de 5 minutos
    redis.call('EXPIRE', key, 3600)  -- Renovar por 1 hora
    return 'refreshed'
end
return 'ok'
" 1 user:1001:profile

# Cache de resultados de queries pesadas
SET leaderboard:top100:cache "$(mongo_query_top_100)" EX 300  # Cache por 5 minutos

# Invalidación de cache inteligente
redis-cli --eval "
local pattern = ARGV[1]
local keys = redis.call('KEYS', pattern)
for i=1,#keys do
    redis.call('DEL', keys[i])
end
return #keys
" 0 "leaderboard:*"
```

---

## 🔧 Troubleshooting Avanzado

### Debugging de Performance

```bash
# Monitor comandos en tiempo real
MONITOR

# Analizar comandos más lentos
CONFIG SET slowlog-log-slower-than 10000  # 10ms
SLOWLOG GET 10

# Ver estadísticas detalladas
INFO commandstats

# Analizar uso de memoria por tipo de clave
redis-cli --eval "
local info = {}
local keys = redis.call('KEYS', '*')
for i=1,#keys do
    local key = keys[i]
    local type = redis.call('TYPE', key)
    local size = redis.call('MEMORY', 'USAGE', key)
    if not info[type] then info[type] = {count=0, memory=0} end
    info[type].count = info[type].count + 1
    info[type].memory = info[type].memory + size
end
return info
" 0
```

### Debugging de Conexiones

```bash
# Ver clientes conectados
CLIENT LIST

# Matar cliente específico
CLIENT KILL id 12345

# Ver información de cliente actual
CLIENT INFO

# Estadísticas de conexiones
INFO clients

# Monitorear patrones de conexión
redis-cli --eval "
local clients = redis.call('CLIENT', 'LIST')
local patterns = {}
for line in string.gmatch(clients, '[^\r\n]+') do
    local addr = string.match(line, 'addr=([%d%.]+):%d+')
    if addr then
        patterns[addr] = (patterns[addr] or 0) + 1
    end
end
return patterns
" 0
```

### Recovery de Datos

```bash
# Backup manual antes de operaciones críticas
BGSAVE
LASTSAVE  # Verificar último save

# Verificar integridad de datos
redis-cli --eval "
local issues = {}
local sessions = redis.call('KEYS', 'session:*')
for i=1,#sessions do
    local session = sessions[i]
    local ttl = redis.call('TTL', session)
    if ttl == -1 then  -- Sin TTL
        table.insert(issues, session .. ' has no TTL')
    end
    local data = redis.call('HGETALL', session)
    if #data == 0 then  -- Vacío
        table.insert(issues, session .. ' is empty')
    end
end
return issues
" 0

# Reparar datos inconsistentes
redis-cli --eval "
local fixed = 0
local sessions = redis.call('KEYS', 'session:*')
for i=1,#sessions do
    local session = sessions[i]
    local ttl = redis.call('TTL', session)
    if ttl == -1 then
        redis.call('EXPIRE', session, 1800)  -- 30 minutos default
        fixed = fixed + 1
    end
end
return 'Fixed ' .. fixed .. ' sessions'
" 0
```

---

## 📊 Monitoreo en Tiempo Real

### Dashboard de Métricas

```bash
#!/bin/bash
# redis-dashboard.sh

watch -n 2 '
echo "⚡ Redis Dashboard - $(date)"
echo "=================================="

echo "🏥 Health:"
redis-cli ping

echo ""
echo "💾 Memory:"
redis-cli info memory | grep -E "(used_memory_human|maxmemory_human|mem_fragmentation_ratio)"

echo ""
echo "👥 Connections:"
redis-cli info clients | grep connected_clients

echo ""
echo "📊 Operations:"
redis-cli info stats | grep -E "(instantaneous_ops_per_sec|total_commands_processed)"

echo ""
echo "🎮 Game Stats:"
echo "Active Sessions: $(redis-cli eval "return #redis.call(\"keys\", \"session:*\")" 0)"
echo "Leaderboard Size: $(redis-cli zcard leaderboard:global)"
echo "Daily Players: $(redis-cli scard daily_players:$(date +%Y-%m-%d) 2>/dev/null || echo 0)"

echo ""
echo "🔑 Keyspace:"
redis-cli info keyspace

echo ""
echo "⚠️  Slow Queries:"
redis-cli slowlog get 3 | head -20
'
```

### Alertas Automáticas

```bash
#!/bin/bash
# redis-alerts.sh

check_redis_health() {
    local memory_usage=$(redis-cli info memory | grep used_memory_rss: | cut -d: -f2)
    local max_memory=536870912  # 512MB en bytes
    
    if [ "$memory_usage" -gt "$max_memory" ]; then
        echo "ALERT: Redis memory usage high: $(($memory_usage / 1048576))MB"
        # Limpiar cache si es necesario
        redis-cli eval "
            local expired = 0
            local sessions = redis.call('KEYS', 'session:*')
            for i=1,#sessions do
                if redis.call('TTL', sessions[i]) < 60 then
                    redis.call('DEL', sessions[i])
                    expired = expired + 1
                end
            end
            return expired
        " 0
    fi
    
    local connections=$(redis-cli info clients | grep connected_clients: | cut -d: -f2)
    if [ "$connections" -gt 100 ]; then
        echo "ALERT: High connection count: $connections"
    fi
    
    local slow_queries=$(redis-cli slowlog len)
    if [ "$slow_queries" -gt 10 ]; then
        echo "ALERT: High number of slow queries: $slow_queries"
        redis-cli slowlog reset
    fi
}

# Ejecutar cada 30 segundos
while true; do
    check_redis_health
    sleep 30
done
```

### Métricas Personalizadas

```bash
# Crear métricas personalizadas del juego
redis-cli --eval "
-- Calcular estadísticas de rendimiento del juego
local stats = {}

-- Sesiones activas por nivel
local sessions = redis.call('KEYS', 'session:*')
local levels = {}
for i=1,#sessions do
    local level = redis.call('HGET', sessions[i], 'level') or '1'
    levels[level] = (levels[level] or 0) + 1
end
stats.sessions_by_level = levels

-- Distribución de puntuaciones en leaderboard
local scores = redis.call('ZRANGE', 'leaderboard:global', 0, -1, 'WITHSCORES')
local score_ranges = {low=0, medium=0, high=0, expert=0}
for i=2,#scores,2 do
    local score = tonumber(scores[i])
    if score < 10000 then score_ranges.low = score_ranges.low + 1
    elseif score < 50000 then score_ranges.medium = score_ranges.medium + 1
    elseif score < 100000 then score_ranges.high = score_ranges.high + 1
    else score_ranges.expert = score_ranges.expert + 1
    end
end
stats.score_distribution = score_ranges

return stats
" 0
```

---

## 🛡️ Seguridad y Patrones

### Validación de Datos

```bash
# Validar datos de sesión antes de usar
redis-cli --eval "
local session_id = ARGV[1]
local session_data = redis.call('HGETALL', 'session:' .. session_id)

-- Verificar que existen campos requeridos
local required_fields = {'user_id', 'username', 'login_time'}
for i=1,#required_fields do
    local found = false
    for j=1,#session_data,2 do
        if session_data[j] == required_fields[i] then
            found = true
            break
        end
    end
    if not found then
        return 'ERROR: Missing required field: ' .. required_fields[i]
    end
end

-- Validar tipos de datos
for i=1,#session_data,2 do
    local key = session_data[i]
    local value = session_data[i+1]
    
    if key == 'user_id' and not string.match(value, '^%d+$') then
        return 'ERROR: Invalid user_id format'
    end
    
    if key == 'score' and tonumber(value) and tonumber(value) < 0 then
        return 'ERROR: Invalid score (negative)'
    end
end

return 'VALID'
" 0 abc123
```

### Prevención de Ataques

```bash
# Rate limiting por IP
redis-cli --eval "
local ip = ARGV[1]
local limit = tonumber(ARGV[2]) or 100  -- 100 requests per minute
local window = 60  -- 1 minute

local key = 'rate_limit:' .. ip .. ':' .. math.floor(os.time() / window)
local current = redis.call('INCR', key)
redis.call('EXPIRE', key, window)

if current > limit then
    return 'RATE_LIMITED'
else
    return 'OK'
end
" 0 192.168.1.100 50

# Detectar patrones sospechosos
redis-cli --eval "
local suspicious = {}

-- Detectar múltiples sesiones desde la misma IP
local sessions = redis.call('KEYS', 'session:*')
local ip_counts = {}
for i=1,#sessions do
    local ip = redis.call('HGET', sessions[i], 'ip_address')
    if ip then
        ip_counts[ip] = (ip_counts[ip] or 0) + 1
        if ip_counts[ip] > 5 then  -- Más de 5 sesiones desde la misma IP
            table.insert(suspicious, 'Multiple sessions from IP: ' .. ip)
        end
    end
end

-- Detectar puntuaciones anormalmente altas
local top_scores = redis.call('ZREVRANGE', 'leaderboard:global', 0, 9, 'WITHSCORES')
for i=2,#top_scores,2 do
    local score = tonumber(top_scores[i])
    if score > 500000 then  -- Umbral sospechoso
        table.insert(suspicious, 'Suspicious high score: ' .. top_scores[i-1] .. ' (' .. score .. ')')
    end
end

return suspicious
" 0
```

### Limpieza y Mantenimiento Automático

```bash
# Script de limpieza automática
redis-cli --eval "
local cleaned = {sessions=0, expired=0, invalid=0}

-- Limpiar sesiones expiradas manualmente
local sessions = redis.call('KEYS', 'session:*')
for i=1,#sessions do
    local ttl = redis.call('TTL', sessions[i])
    if ttl == -2 then  -- Clave expirada pero no eliminada
        redis.call('DEL', sessions[i])
        cleaned.expired = cleaned.expired + 1
    elseif ttl == -1 then  -- Sin TTL, aplicar TTL por defecto
        redis.call('EXPIRE', sessions[i], 1800)
        cleaned.sessions = cleaned.sessions + 1
    end
end

-- Limpiar datos inválidos en leaderboard
local members = redis.call('ZRANGE', 'leaderboard:global', 0, -1)
for i=1,#members do
    local member = members[i]
    -- Si el username tiene caracteres sospechosos
    if string.find(member, '[<>\"\\']') then
        redis.call('ZREM', 'leaderboard:global', member)
        cleaned.invalid = cleaned.invalid + 1
    end
end

return cleaned
" 0

# Programar limpieza automática con cron
# 0 */6 * * * /path/to/redis-cleanup.sh
```

---

## 🎯 Scripts de Utilidad

### Script de Migración de Datos

```bash
#!/bin/bash
# migrate-redis-data.sh

migrate_leaderboard_format() {
    echo "Migrating leaderboard format..."
    
    # Migrar de formato antiguo a nuevo
    redis-cli --eval "
        -- Migrar leaderboard simple a formato con metadatos
        local old_board = redis.call('ZRANGE', 'old_leaderboard', 0, -1, 'WITHSCORES')
        for i=1,#old_board,2 do
            local player = old_board[i]
            local score = old_board[i+1]
            
            -- Agregar al nuevo leaderboard
            redis.call('ZADD', 'leaderboard:global', score, player)
            
            -- Crear metadatos
            redis.call('HSET', 'player:' .. player .. ':meta', 
                'best_score', score,
                'migration_date', os.time(),
                'legacy_player', 'true'
            )
        end
        
        -- Renombrar leaderboard antiguo
        redis.call('RENAME', 'old_leaderboard', 'backup_old_leaderboard')
        return 'Migration completed'
    " 0
}

migrate_session_format() {
    echo "Migrating session format..."
    
    redis-cli --eval "
        local migrated = 0
        local sessions = redis.call('KEYS', 'session:*')
        
        for i=1,#sessions do
            local session = sessions[i]
            local data = redis.call('HGETALL', session)
            local needs_migration = false
            
            -- Verificar si necesita migración
            for j=1,#data,2 do
                if data[j] == 'old_field_name' then
                    needs_migration = true
                    break
                end
            end
            
            if needs_migration then
                -- Realizar migración
                redis.call('HDEL', session, 'old_field_name')
                redis.call('HSET', session, 'new_field_name', 'default_value')
                migrated = migrated + 1
            end
        end
        
        return 'Migrated ' .. migrated .. ' sessions'
    " 0
}

# Ejecutar migraciones
migrate_leaderboard_format
migrate_session_format
```

### Script de Testing

```bash
#!/bin/bash
# test-redis-operations.sh

test_session_operations() {
    echo "Testing session operations..."
    
    # Crear sesión de prueba
    SESSION_ID="test_$(date +%s)"
    redis-cli HSET session:$SESSION_ID user_id 9999 username "test_user" score 0
    redis-cli EXPIRE session:$SESSION_ID 60
    
    # Verificar creación
    if redis-cli EXISTS session:$SESSION_ID | grep -q "1"; then
        echo "✅ Session creation: PASS"
    else
        echo "❌ Session creation: FAIL"
        return 1
    fi
    
    # Probar operaciones
    redis-cli HINCRBY session:$SESSION_ID score 100
    SCORE=$(redis-cli HGET session:$SESSION_ID score)
    
    if [ "$SCORE" = "100" ]; then
        echo "✅ Score increment: PASS"
    else
        echo "❌ Score increment: FAIL (got $SCORE)"
    fi
    
    # Limpiar
    redis-cli DEL session:$SESSION_ID
    echo "✅ Test cleanup: PASS"
}

test_leaderboard_operations() {
    echo "Testing leaderboard operations..."
    
    # Agregar scores de prueba
    redis-cli ZADD test_leaderboard 1000 "player1" 2000 "player2" 1500 "player3"
    
    # Verificar top 3
    TOP_PLAYER=$(redis-cli ZREVRANGE test_leaderboard 0 0)
    if [ "$TOP_PLAYER" = "player2" ]; then
        echo "✅ Leaderboard ranking: PASS"
    else
        echo "❌ Leaderboard ranking: FAIL (got $TOP_PLAYER)"
    fi
    
    # Verificar puntuación
    SCORE=$(redis-cli ZSCORE test_leaderboard "player2")
    if [ "$SCORE" = "2000" ]; then
        echo "✅ Score retrieval: PASS"
    else
        echo "❌ Score retrieval: FAIL (got $SCORE)"
    fi
    
    # Limpiar
    redis-cli DEL test_leaderboard
    echo "✅ Test cleanup: PASS"
}

# Ejecutar tests
test_session_operations
test_leaderboard_operations
echo "All tests completed!"
```

---

**💡 Tip**: Siempre usar TTL en claves temporales y monitorear el uso de memoria regularmente.

**🔗 Enlaces Relacionados**:
- [DATABASE-QUERIES.md](DATABASE-QUERIES.md) - Guía general de MongoDB y Redis
- [DATABASE-TROUBLESHOOTING.md](DATABASE-TROUBLESHOOTING.md) - Troubleshooting completo
- [../scripts/db-helper.sh](../scripts/db-helper.sh) - Script básico de queries
- [../scripts/db-troubleshooting.sh](../scripts/db-troubleshooting.sh) - Script avanzado de troubleshooting

---

<div align="center">
<b>⚡ Redis Avanzado - Pacman DevOps Challenge by roxsross</b><br>
<i>90DaysWithRoxs - Aprende DevOps de forma práctica</i>
</div>
