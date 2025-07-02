# 🔧 Troubleshooting y Operaciones Avanzadas de Base de Datos

Guía práctica para resolver problemas comunes y realizar operaciones avanzadas en MongoDB y Redis del proyecto Pacman DevOps.

## 📋 Tabla de Contenidos

- [🚨 Problemas Comunes](#-problemas-comunes)
- [🍃 MongoDB Troubleshooting](#-mongodb-troubleshooting)
- [⚡ Redis Troubleshooting](#-redis-troubleshooting)
- [📊 Monitoreo Avanzado](#-monitoreo-avanzado)
- [🔧 Mantenimiento](#-mantenimiento)
- [📈 Optimización de Performance](#-optimización-de-performance)
- [🛡️ Seguridad y Backup](#%EF%B8%8F-seguridad-y-backup)

---

## 🚨 Problemas Comunes

### Conexión Rechazada

**Problema**: Error de conexión a MongoDB o Redis
```bash
Error: connect ECONNREFUSED 127.0.0.1:27017
```

**Solución**:
```bash
# Verificar que los contenedores estén ejecutándose
docker ps | grep -E "(mongodb|redis)"

# Reiniciar servicios si es necesario
docker compose restart pacman-mongodb pacman-redis

# Verificar logs de los contenedores
docker logs pacman-mongodb
docker logs pacman-redis

# Verificar conectividad de red
docker exec pacman-backend ping mongodb
docker exec pacman-backend ping redis
```

### Pérdida de Datos de Sesión

**Problema**: Los usuarios son desconectados constantemente

**Diagnóstico Redis**:
```bash
# Conectar a Redis
docker exec -it pacman-redis redis-cli

# Verificar configuración de timeout
CONFIG GET timeout

# Ver todas las claves de sesión
KEYS session:*

# Verificar TTL de una sesión específica
TTL session:abc123

# Ver estadísticas de memoria
INFO memory
```

**Solución**:
```bash
# Aumentar timeout de sesión (en segundos)
CONFIG SET timeout 1800

# Verificar política de eviction
CONFIG GET maxmemory-policy

# Cambiar política si es necesario
CONFIG SET maxmemory-policy allkeys-lru
```

### Base de Datos Corrupta

**Problema**: MongoDB no inicia correctamente

**Diagnóstico**:
```bash
# Verificar logs detallados
docker logs pacman-mongodb --tail 100

# Entrar al contenedor para verificar archivos
docker exec -it pacman-mongodb bash
ls -la /data/db/

# Verificar espacio en disco
df -h
```

**Solución**:
```bash
# Reparar base de datos (solo en desarrollo)
docker exec -it pacman-mongodb mongosh --eval "db.runCommand({repairDatabase: 1})"

# Si es necesario, recrear volumen (PERDERÁS DATOS)
docker compose down
docker volume rm pacman-ops_mongodb_data
docker compose up -d
```

---

## 🍃 MongoDB Troubleshooting

### Performance Lento

**Diagnóstico**:
```javascript
// Conectar a MongoDB
docker exec -it pacman-mongodb mongosh pacman-devops

// Ver operaciones lentas actuales
db.currentOp({"secs_running": {$gte: 5}})

// Habilitar profiling para queries lentas (>100ms)
db.setProfilingLevel(2, {slowms: 100})

// Ver queries más lentas
db.system.profile.find().sort({ts: -1}).limit(10).pretty()

// Estadísticas de colecciones
db.stats()
db.users.stats()
db.scores.stats()
```

**Solución**:
```javascript
// Crear índices para mejorar performance
db.users.createIndex({username: 1})
db.users.createIndex({email: 1})
db.scores.createIndex({score: -1})
db.scores.createIndex({username: 1, score: -1})
db.scores.createIndex({date: -1})

// Verificar índices creados
db.users.getIndexes()
db.scores.getIndexes()

// Analizar plan de ejecución de una query
db.scores.find({username: "player1"}).explain("executionStats")
```

### Datos Inconsistentes

**Diagnóstico y Limpieza**:
```javascript
// Buscar usuarios sin puntuaciones
db.users.aggregate([
  {
    $lookup: {
      from: "scores",
      localField: "username",
      foreignField: "username",
      as: "scores"
    }
  },
  {
    $match: {
      "scores": {$size: 0}
    }
  }
])

// Buscar puntuaciones huérfanas (sin usuario)
db.scores.aggregate([
  {
    $lookup: {
      from: "users",
      localField: "username",
      foreignField: "username",
      as: "user"
    }
  },
  {
    $match: {
      "user": {$size: 0}
    }
  }
])

// Limpiar datos duplicados
db.users.aggregate([
  {$group: {
    _id: "$username",
    count: {$sum: 1},
    docs: {$push: "$_id"}
  }},
  {$match: {count: {$gt: 1}}}
]).forEach(function(doc) {
  doc.docs.shift();
  db.users.deleteMany({_id: {$in: doc.docs}});
})
```

### Migración de Datos

```javascript
// Agregar campo nuevo a todos los usuarios existentes
db.users.updateMany(
  {team: {$exists: false}},
  {$set: {team: "General", joinDate: new Date()}}
)

// Migrar estructura de puntuaciones
db.scores.updateMany(
  {gameMode: {$exists: false}},
  {$set: {gameMode: "classic", difficulty: "normal"}}
)

// Crear colección de backup antes de cambios importantes
db.users.aggregate([{$out: "users_backup"}])
db.scores.aggregate([{$out: "scores_backup"}])
```

---

## ⚡ Redis Troubleshooting

### Memoria Llena

**Diagnóstico**:
```bash
# Conectar a Redis
docker exec -it pacman-redis redis-cli

# Ver uso de memoria
INFO memory

# Ver configuración de memoria máxima
CONFIG GET maxmemory

# Ver política de eviction
CONFIG GET maxmemory-policy

# Ver las claves que más memoria consumen
MEMORY USAGE session:abc123
MEMORY USAGE leaderboard:daily
```

**Solución**:
```bash
# Limpiar sesiones expiradas manualmente
EVAL "local keys = redis.call('keys', 'session:*') for i=1,#keys do if redis.call('ttl', keys[i]) == -1 then redis.call('del', keys[i]) end end" 0

# Configurar política de eviction apropiada
CONFIG SET maxmemory-policy allkeys-lru

# Aumentar memoria máxima (si es posible)
CONFIG SET maxmemory 256mb

# Limpiar cache de leaderboard antiguo
DEL leaderboard:weekly:$(date -d 'last week' +%Y-%U)
DEL leaderboard:monthly:$(date -d 'last month' +%Y-%m)
```

### Conexiones Perdidas

**Diagnóstico**:
```bash
# Ver información de conexiones
INFO clients

# Ver configuración de timeout
CONFIG GET timeout

# Ver clientes conectados
CLIENT LIST

# Monitorear comandos en tiempo real
MONITOR
```

**Solución**:
```bash
# Aumentar timeout de conexión
CONFIG SET timeout 300

# Configurar keep-alive
CONFIG SET tcp-keepalive 60

# Limitar número de conexiones si es necesario
CONFIG SET maxclients 100
```

### Pérdida de Datos en Cache

**Prevención y Recuperación**:
```bash
# Habilitar persistencia (AOF)
CONFIG SET appendonly yes
CONFIG SET appendfsync everysec

# Crear snapshot manual
BGSAVE

# Ver último save
LASTSAVE

# Recuperar datos críticos desde MongoDB
# (ejecutar desde aplicación Node.js)
```

```javascript
// Script para regenerar cache desde MongoDB
const regenerateCache = async () => {
  // Regenerar leaderboard
  const topScores = await db.scores.find()
    .sort({score: -1})
    .limit(10)
    .toArray();
  
  await redis.del('leaderboard:global');
  for (let i = 0; i < topScores.length; i++) {
    await redis.zadd('leaderboard:global', topScores[i].score, topScores[i].username);
  }
  
  // Regenerar estadísticas
  const totalUsers = await db.users.countDocuments();
  const totalGames = await db.scores.countDocuments();
  
  await redis.hset('stats:global', {
    totalUsers,
    totalGames,
    lastUpdate: Date.now()
  });
};
```

---

## 📊 Monitoreo Avanzado

### Scripts de Monitoreo Automático

```bash
#!/bin/bash
# monitoring.sh - Script de monitoreo automático

# Función para check de salud MongoDB
check_mongodb() {
  local result=$(docker exec pacman-mongodb mongosh --quiet --eval "db.adminCommand('ping').ok")
  if [ "$result" = "1" ]; then
    echo "✅ MongoDB: Healthy"
  else
    echo "❌ MongoDB: Unhealthy"
    return 1
  fi
}

# Función para check de salud Redis
check_redis() {
  local result=$(docker exec pacman-redis redis-cli ping)
  if [ "$result" = "PONG" ]; then
    echo "✅ Redis: Healthy"
  else
    echo "❌ Redis: Unhealthy"
    return 1
  fi
}

# Métricas de performance
get_performance_metrics() {
  echo "📊 Performance Metrics:"
  
  # MongoDB metrics
  echo "🍃 MongoDB:"
  docker exec pacman-mongodb mongosh --quiet --eval "
    const stats = db.serverStatus();
    print('  Connections: ' + stats.connections.current + '/' + stats.connections.available);
    print('  Operations/sec: ' + stats.opcounters.query + ' queries, ' + stats.opcounters.insert + ' inserts');
    print('  Memory: ' + Math.round(stats.mem.resident) + 'MB resident');
  "
  
  # Redis metrics
  echo "⚡ Redis:"
  docker exec pacman-redis redis-cli info stats | grep -E "(instantaneous_ops_per_sec|connected_clients|used_memory_human)"
}

# Alertas automáticas
check_alerts() {
  # Verificar uso de memoria de Redis
  local redis_memory=$(docker exec pacman-redis redis-cli info memory | grep used_memory_rss: | cut -d: -f2 | tr -d '\r')
  local max_memory=268435456  # 256MB en bytes
  
  if [ "$redis_memory" -gt "$max_memory" ]; then
    echo "🚨 ALERT: Redis memory usage high: $(($redis_memory / 1048576))MB"
  fi
  
  # Verificar conexiones de MongoDB
  local mongo_connections=$(docker exec pacman-mongodb mongosh --quiet --eval "db.serverStatus().connections.current")
  if [ "$mongo_connections" -gt 50 ]; then
    echo "🚨 ALERT: MongoDB connections high: $mongo_connections"
  fi
}

# Ejecutar checks
check_mongodb
check_redis
get_performance_metrics
check_alerts
```

### Dashboard en Tiempo Real

```bash
#!/bin/bash
# dashboard.sh - Dashboard simple en terminal

watch -n 5 '
echo "🎮 PACMAN DEVOPS - Database Dashboard"
echo "$(date)"
echo ""

echo "🏥 Health Status:"
docker exec pacman-mongodb mongosh --quiet --eval "print(\"MongoDB: \" + (db.adminCommand(\"ping\").ok ? \"✅ UP\" : \"❌ DOWN\"))"
docker exec pacman-redis redis-cli ping > /dev/null && echo "Redis: ✅ UP" || echo "Redis: ❌ DOWN"

echo ""
echo "👥 User Stats:"
docker exec pacman-mongodb mongosh --quiet pacman-devops --eval "
const totalUsers = db.users.countDocuments();
const activeToday = db.scores.distinct(\"username\", {date: {\$gte: new Date(Date.now() - 24*60*60*1000)}}).length;
print(\"Total Users: \" + totalUsers);
print(\"Active Today: \" + activeToday);
"

echo ""
echo "🏆 Top Scores Today:"
docker exec pacman-mongodb mongosh --quiet pacman-devops --eval "
db.scores.find({date: {\$gte: new Date(Date.now() - 24*60*60*1000)}})
  .sort({score: -1})
  .limit(5)
  .forEach(doc => print(doc.username + \": \" + doc.score));
"

echo ""
echo "⚡ Redis Cache:"
docker exec pacman-redis redis-cli info keyspace | grep -E "db0"
docker exec pacman-redis redis-cli eval "return #redis.call(\"keys\", \"session:*\")" 0 | xargs -I {} echo "Active Sessions: {}"
'
```

---

## 🔧 Mantenimiento

### Limpieza Automática de Datos Antiguos

```javascript
// cleanup.js - Script de limpieza automática

// Eliminar puntuaciones muy antiguas (más de 1 año)
db.scores.deleteMany({
  date: {
    $lt: new Date(Date.now() - 365 * 24 * 60 * 60 * 1000)
  }
});

// Eliminar usuarios inactivos (sin puntuaciones en 6 meses)
const sixMonthsAgo = new Date(Date.now() - 6 * 30 * 24 * 60 * 60 * 1000);
const inactiveUsers = db.scores.aggregate([
  {
    $group: {
      _id: "$username",
      lastScore: {$max: "$date"}
    }
  },
  {
    $match: {
      lastScore: {$lt: sixMonthsAgo}
    }
  }
]).map(doc => doc._id);

db.users.deleteMany({
  username: {$in: inactiveUsers}
});

// Compactar colecciones después de limpieza
db.runCommand({compact: "users"});
db.runCommand({compact: "scores"});
```

### Rotación de Logs

```bash
#!/bin/bash
# rotate_logs.sh - Rotación de logs de contenedores

# Crear directorio de logs archivados
mkdir -p /var/log/pacman-archive

# Archivar logs actuales
docker logs pacman-mongodb > "/var/log/pacman-archive/mongodb-$(date +%Y%m%d).log" 2>&1
docker logs pacman-redis > "/var/log/pacman-archive/redis-$(date +%Y%m%d).log" 2>&1
docker logs pacman-backend > "/var/log/pacman-archive/backend-$(date +%Y%m%d).log" 2>&1

# Limpiar logs de contenedores (requiere restart)
echo "Rotating logs requires container restart..."
docker compose restart

# Eliminar logs archivados más antiguos a 30 días
find /var/log/pacman-archive -name "*.log" -mtime +30 -delete
```

---

## 📈 Optimización de Performance

### Índices Optimizados

```javascript
// Crear índices compuestos para queries comunes
db.scores.createIndex(
  {username: 1, date: -1},
  {name: "user_recent_scores"}
);

db.scores.createIndex(
  {score: -1, date: -1},
  {name: "leaderboard_by_date"}
);

db.users.createIndex(
  {team: 1, "stats.bestScore": -1},
  {name: "team_leaderboard"}
);

// Índice para búsquedas de texto en usernames
db.users.createIndex(
  {username: "text", fullName: "text"},
  {name: "user_search"}
);

// Índice TTL para sesiones (auto-cleanup)
db.sessions.createIndex(
  {createdAt: 1},
  {expireAfterSeconds: 1800, name: "session_ttl"}
);
```

### Configuración Redis Optimizada

```bash
# Configuración para máximo performance
CONFIG SET maxmemory-policy allkeys-lru
CONFIG SET maxmemory 512mb
CONFIG SET save "900 1 300 10 60 10000"  # Snapshots automáticos
CONFIG SET tcp-keepalive 60
CONFIG SET timeout 300

# Para alta concurrencia
CONFIG SET maxclients 1000
CONFIG SET tcp-backlog 511

# Optimización de red
CONFIG SET tcp-nodelay yes
```

### Query Optimization

```javascript
// ❌ Query lenta - evitar
db.scores.find({score: {$gt: 1000}}).sort({date: -1});

// ✅ Query optimizada
db.scores.find({score: {$gt: 1000}}).sort({score: -1, date: -1}).limit(50);

// ❌ Aggregation lenta
db.scores.aggregate([
  {$group: {_id: "$username", avgScore: {$avg: "$score"}}},
  {$sort: {avgScore: -1}}
]);

// ✅ Aggregation con índices
db.scores.aggregate([
  {$match: {date: {$gte: new Date(Date.now() - 30*24*60*60*1000)}}},
  {$group: {_id: "$username", avgScore: {$avg: "$score"}}},
  {$sort: {avgScore: -1}},
  {$limit: 20}
]);
```

---

## 🛡️ Seguridad y Backup

### Backup Automático

```bash
#!/bin/bash
# backup.sh - Script de backup automático

BACKUP_DIR="/backups/pacman-$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

echo "🔄 Creating MongoDB backup..."
docker exec pacman-mongodb mongodump --db pacman-devops --out /tmp/backup
docker cp pacman-mongodb:/tmp/backup/pacman-devops "$BACKUP_DIR/mongodb"

echo "🔄 Creating Redis backup..."
docker exec pacman-redis redis-cli SAVE
docker cp pacman-redis:/data/dump.rdb "$BACKUP_DIR/redis-dump.rdb"

echo "🔄 Compressing backup..."
tar -czf "$BACKUP_DIR.tar.gz" -C "$BACKUP_DIR" .
rm -rf "$BACKUP_DIR"

echo "✅ Backup completed: $BACKUP_DIR.tar.gz"

# Limpiar backups antiguos (mantener 7 días)
find /backups -name "pacman-*.tar.gz" -mtime +7 -delete
```

### Restauración desde Backup

```bash
#!/bin/bash
# restore.sh - Script de restauración

BACKUP_FILE="$1"

if [ -z "$BACKUP_FILE" ]; then
  echo "Usage: $0 <backup-file.tar.gz>"
  exit 1
fi

RESTORE_DIR="/tmp/restore-$(date +%s)"
mkdir -p "$RESTORE_DIR"

echo "🔄 Extracting backup..."
tar -xzf "$BACKUP_FILE" -C "$RESTORE_DIR"

echo "🔄 Stopping services..."
docker compose stop pacman-backend

echo "🔄 Restoring MongoDB..."
docker cp "$RESTORE_DIR/mongodb" pacman-mongodb:/tmp/restore
docker exec pacman-mongodb mongorestore --db pacman-devops --drop /tmp/restore

echo "🔄 Restoring Redis..."
docker compose stop pacman-redis
docker cp "$RESTORE_DIR/redis-dump.rdb" pacman-redis:/data/dump.rdb
docker compose start pacman-redis

echo "🔄 Starting services..."
docker compose start pacman-backend

echo "✅ Restore completed!"
rm -rf "$RESTORE_DIR"
```

### Auditoría de Seguridad

```javascript
// Auditoría de datos sensibles
db.users.find({}, {password: 0}).forEach(user => {
  if (!user.email || !user.email.includes('@')) {
    print('Invalid email for user: ' + user.username);
  }
  
  if (!user.registrationDate) {
    print('Missing registration date for user: ' + user.username);
  }
});

// Verificar integridad de puntuaciones
db.scores.find({
  $or: [
    {score: {$lt: 0}},
    {score: {$gt: 1000000}},
    {username: {$exists: false}},
    {date: {$exists: false}}
  ]
}).forEach(score => {
  print('Suspicious score: ' + JSON.stringify(score));
});
```

---

## 🎯 Casos de Uso Específicos

### Detectar Cheating

```javascript
// Detectar puntuaciones sospechosamente altas
db.scores.find({
  score: {$gt: 100000}
}).sort({score: -1});

// Detectar múltiples puntuaciones altas del mismo usuario en poco tiempo
db.scores.aggregate([
  {
    $match: {
      date: {$gte: new Date(Date.now() - 24*60*60*1000)}
    }
  },
  {
    $group: {
      _id: "$username",
      scores: {$push: {score: "$score", date: "$date"}},
      count: {$sum: 1},
      avgScore: {$avg: "$score"},
      maxScore: {$max: "$score"}
    }
  },
  {
    $match: {
      $and: [
        {count: {$gt: 10}},
        {avgScore: {$gt: 50000}}
      ]
    }
  }
]);
```

### Análisis de Patrones de Juego

```javascript
// Análisis de actividad por horas
db.scores.aggregate([
  {
    $group: {
      _id: {$hour: "$date"},
      totalGames: {$sum: 1},
      avgScore: {$avg: "$score"}
    }
  },
  {
    $sort: {_id: 1}
  }
]);

// Jugadores más activos por día de la semana
db.scores.aggregate([
  {
    $group: {
      _id: {
        username: "$username",
        dayOfWeek: {$dayOfWeek: "$date"}
      },
      gamesPlayed: {$sum: 1}
    }
  },
  {
    $group: {
      _id: "$_id.dayOfWeek",
      players: {
        $push: {
          username: "$_id.username",
          games: "$gamesPlayed"
        }
      },
      totalGames: {$sum: "$gamesPlayed"}
    }
  }
]);
```

---

**💡 Tip**: Siempre realizar backups antes de ejecutar scripts de mantenimiento o limpieza.

**🔗 Enlaces Relacionados**:
- [DATABASE-QUERIES.md](DATABASE-QUERIES.md) - Queries básicas y operaciones CRUD
- [GAME-QUERIES-EXAMPLES.md](GAME-QUERIES-EXAMPLES.md) - Ejemplos específicos del juego
- [../scripts/db-helper.sh](../scripts/db-helper.sh) - Script automatizado para queries comunes

---

<div align="center">
<b>🎮 Pacman DevOps Challenge by roxsross</b><br>
<i>90DaysWithRoxs - Aprende DevOps de forma práctica</i>
</div>
