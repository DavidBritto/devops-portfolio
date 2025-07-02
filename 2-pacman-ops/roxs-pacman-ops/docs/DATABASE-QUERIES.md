# 🗃️ MongoDB & Redis Queries Guide

Guía completa de queries y operaciones para MongoDB y Redis en el proyecto Pacman DevOps Challenge.

## 📋 Tabla de Contenidos

- [🍃 MongoDB Queries](#-mongodb-queries)
  - [Conexión y Configuración](#conexión-y-configuración)
  - [Colecciones y Esquemas](#colecciones-y-esquemas)
  - [Operaciones CRUD](#operaciones-crud)
  - [Queries Avanzadas](#queries-avanzadas)
  - [Agregaciones](#agregaciones)
  - [Índices y Performance](#índices-y-performance)
- [⚡ Redis Operations](#-redis-operations)
  - [Conexión y Configuración](#conexión-y-configuración-redis)
  - [Tipos de Datos](#tipos-de-datos)
  - [Operaciones de Cache](#operaciones-de-cache)
  - [Sesiones de Usuario](#sesiones-de-usuario)
  - [Leaderboard en Tiempo Real](#leaderboard-en-tiempo-real)
- [🛠️ Herramientas de Administración](#%EF%B8%8F-herramientas-de-administración)
- [📊 Monitoreo y Performance](#-monitoreo-y-performance)

---

## 🍃 MongoDB Queries

### Conexión y Configuración

#### Acceso Directo al Contenedor
```bash
# Conectar al contenedor MongoDB
docker exec -it pacman-mongodb mongosh

# Conectar a la base de datos específica
docker exec -it pacman-mongodb mongosh pacman-devops
```

#### Conexión desde la Aplicación
```javascript
// URI de conexión utilizada por el backend
const MONGODB_URI = "mongodb://mongodb:27017/pacman-devops"

// Ejemplo de conexión con Mongoose
const mongoose = require('mongoose');
mongoose.connect(MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true
});
```

### Colecciones y Esquemas

#### 👤 Colección: `users`
```javascript
// Estructura del documento usuario
{
  _id: ObjectId,
  username: String,        // 3-15 caracteres, único
  password: String,        // Hash bcrypt
  email: String,           // Email válido, único
  fullName: String,        // Nombre completo
  team: String,           // Equipo DevOps
  isParticipant: Boolean, // Participante del challenge
  containerInfo: {
    platform: String,      // "docker", "kubernetes", etc.
    hostname: String,       // Nombre del contenedor
    environment: String    // "development", "production"
  },
  registrationDate: Date,
  devOpsChallenge: String, // "90DaysWithRoxs"
  lastLogin: Date,
  profileImage: String,
  achievements: [String],
  stats: {
    totalGames: Number,
    totalScore: Number,
    averageScore: Number,
    bestScore: Number,
    totalPlayTime: Number
  }
}
```

#### 🏆 Colección: `scores`
```javascript
// Estructura del documento puntuación
{
  _id: ObjectId,
  userId: ObjectId,        // Referencia a users._id
  username: String,        // Denormalizado para performance
  score: Number,          // Puntuación del juego
  level: Number,          // Nivel alcanzado
  gameTime: Number,       // Tiempo de juego en segundos
  pelletsEaten: Number,   // Pellets comidos
  ghostsEaten: Number,    // Fantasmas comidos
  lives: Number,          // Vidas restantes
  gameMode: String,       // "classic", "challenge", "tournament"
  deviceInfo: {
    platform: String,     // "web", "mobile"
    userAgent: String,    // User agent del navegador
    screenResolution: String
  },
  gameplayStats: {
    moveCount: Number,     // Número de movimientos
    powerUpsUsed: Number, // Power-ups utilizados
    perfectLevels: Number // Niveles completados perfectamente
  },
  timestamp: Date,
  challengeId: String     // ID del challenge DevOps
}
```

#### 🔑 Colección: `sessions`
```javascript
// Estructura del documento sesión
{
  _id: String,            // Session ID
  userId: ObjectId,       // Usuario asociado
  data: Object,          // Datos de la sesión
  expiresAt: Date,       // Expiración automática
  lastAccess: Date,
  ipAddress: String,
  userAgent: String
}
```

### Operaciones CRUD

#### Create (Insertar)
```javascript
// Crear nuevo usuario
db.users.insertOne({
  username: "devops_player",
  password: "$2b$10$hashedPassword",
  email: "player@90dayswithroxs.com",
  fullName: "DevOps Player",
  team: "Team Roxs",
  isParticipant: true,
  containerInfo: {
    platform: "docker",
    hostname: "pacman-backend",
    environment: "development"
  },
  registrationDate: new Date(),
  devOpsChallenge: "90DaysWithRoxs",
  achievements: [],
  stats: {
    totalGames: 0,
    totalScore: 0,
    averageScore: 0,
    bestScore: 0,
    totalPlayTime: 0
  }
});

// Insertar múltiples puntuaciones
db.scores.insertMany([
  {
    userId: ObjectId("user_id_1"),
    username: "devops_player",
    score: 2500,
    level: 3,
    gameTime: 180,
    pelletsEaten: 150,
    ghostsEaten: 4,
    lives: 2,
    gameMode: "classic",
    timestamp: new Date(),
    challengeId: "90DaysWithRoxs"
  },
  {
    userId: ObjectId("user_id_2"),
    username: "roxs_fan",
    score: 3200,
    level: 4,
    gameTime: 240,
    pelletsEaten: 200,
    ghostsEaten: 6,
    lives: 1,
    gameMode: "challenge",
    timestamp: new Date(),
    challengeId: "90DaysWithRoxs"
  }
]);
```

#### Read (Consultar)
```javascript
// Buscar usuario por username
db.users.findOne({ username: "devops_player" });

// Buscar todas las puntuaciones de un usuario
db.scores.find({ userId: ObjectId("user_id") }).sort({ timestamp: -1 });

// Top 10 puntuaciones globales
db.scores.find({})
  .sort({ score: -1 })
  .limit(10);

// Usuarios participantes del challenge
db.users.find({ 
  isParticipant: true,
  devOpsChallenge: "90DaysWithRoxs"
});

// Puntuaciones de la última semana
db.scores.find({
  timestamp: {
    $gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
  }
}).sort({ score: -1 });
```

#### Update (Actualizar)
```javascript
// Actualizar estadísticas del usuario después de un juego
db.users.updateOne(
  { _id: ObjectId("user_id") },
  {
    $inc: { 
      "stats.totalGames": 1,
      "stats.totalScore": 2500,
      "stats.totalPlayTime": 180
    },
    $max: { "stats.bestScore": 2500 },
    $set: { lastLogin: new Date() }
  }
);

// Calcular y actualizar promedio de puntuación
db.users.updateOne(
  { _id: ObjectId("user_id") },
  [{
    $set: {
      "stats.averageScore": {
        $cond: {
          if: { $gt: ["$stats.totalGames", 0] },
          then: { $divide: ["$stats.totalScore", "$stats.totalGames"] },
          else: 0
        }
      }
    }
  }]
);

// Agregar achievement
db.users.updateOne(
  { _id: ObjectId("user_id") },
  { $addToSet: { achievements: "FIRST_WIN" } }
);
```

#### Delete (Eliminar)
```javascript
// Eliminar puntuaciones antiguas (más de 1 año)
db.scores.deleteMany({
  timestamp: {
    $lt: new Date(Date.now() - 365 * 24 * 60 * 60 * 1000)
  }
});

// Eliminar sesiones expiradas
db.sessions.deleteMany({
  expiresAt: { $lt: new Date() }
});
```

### Queries Avanzadas

#### Búsquedas Complejas
```javascript
// Buscar jugadores con mejores estadísticas
db.users.find({
  "stats.bestScore": { $gte: 5000 },
  "stats.totalGames": { $gte: 10 },
  isParticipant: true
}).sort({ "stats.bestScore": -1 });

// Puntuaciones por rango de fechas y nivel
db.scores.find({
  timestamp: {
    $gte: ISODate("2025-01-01"),
    $lte: ISODate("2025-12-31")
  },
  level: { $gte: 5 },
  gameMode: "classic"
}).sort({ score: -1 });

// Buscar por texto en múltiples campos
db.users.find({
  $or: [
    { username: { $regex: "devops", $options: "i" } },
    { fullName: { $regex: "devops", $options: "i" } },
    { team: { $regex: "devops", $options: "i" } }
  ]
});
```

#### Queries con Projection
```javascript
// Solo obtener campos específicos
db.users.find(
  { isParticipant: true },
  { 
    username: 1, 
    fullName: 1, 
    team: 1, 
    "stats.bestScore": 1 
  }
);

// Excluir campos sensibles
db.users.find(
  {},
  { 
    password: 0, 
    email: 0 
  }
);
```

### Agregaciones

#### Pipeline de Agregación para Leaderboard
```javascript
// Top jugadores con estadísticas completas
db.users.aggregate([
  {
    $match: { 
      isParticipant: true,
      "stats.totalGames": { $gte: 1 }
    }
  },
  {
    $lookup: {
      from: "scores",
      localField: "_id",
      foreignField: "userId",
      as: "recentScores"
    }
  },
  {
    $addFields: {
      recentScores: {
        $slice: [
          { $sortArray: { input: "$recentScores", sortBy: { timestamp: -1 } } },
          5
        ]
      }
    }
  },
  {
    $project: {
      username: 1,
      fullName: 1,
      team: 1,
      stats: 1,
      recentScores: {
        score: 1,
        level: 1,
        timestamp: 1
      }
    }
  },
  {
    $sort: { "stats.bestScore": -1 }
  },
  {
    $limit: 20
  }
]);
```

#### Estadísticas por Equipo
```javascript
db.users.aggregate([
  {
    $match: { isParticipant: true }
  },
  {
    $group: {
      _id: "$team",
      totalPlayers: { $sum: 1 },
      totalGames: { $sum: "$stats.totalGames" },
      totalScore: { $sum: "$stats.totalScore" },
      averageScore: { $avg: "$stats.averageScore" },
      bestScore: { $max: "$stats.bestScore" },
      totalPlayTime: { $sum: "$stats.totalPlayTime" }
    }
  },
  {
    $sort: { bestScore: -1 }
  }
]);
```

#### Análisis de Actividad por Fecha
```javascript
db.scores.aggregate([
  {
    $group: {
      _id: {
        year: { $year: "$timestamp" },
        month: { $month: "$timestamp" },
        day: { $dayOfMonth: "$timestamp" }
      },
      totalGames: { $sum: 1 },
      averageScore: { $avg: "$score" },
      uniquePlayers: { $addToSet: "$userId" }
    }
  },
  {
    $addFields: {
      uniquePlayersCount: { $size: "$uniquePlayers" }
    }
  },
  {
    $sort: { "_id.year": -1, "_id.month": -1, "_id.day": -1 }
  }
]);
```

### Índices y Performance

#### Crear Índices Importantes
```javascript
// Índices únicos
db.users.createIndex({ "username": 1 }, { unique: true });
db.users.createIndex({ "email": 1 }, { unique: true });

// Índices compuestos para queries frecuentes
db.scores.createIndex({ "userId": 1, "timestamp": -1 });
db.scores.createIndex({ "score": -1, "timestamp": -1 });
db.scores.createIndex({ "gameMode": 1, "level": 1 });

// Índice de texto para búsquedas
db.users.createIndex({
  "username": "text",
  "fullName": "text",
  "team": "text"
});

// Índice TTL para sesiones
db.sessions.createIndex(
  { "expiresAt": 1 }, 
  { expireAfterSeconds: 0 }
);

// Ver todos los índices
db.users.getIndexes();
db.scores.getIndexes();
```

#### Optimización de Queries
```javascript
// Explicar plan de ejecución
db.scores.find({ score: { $gte: 5000 } }).explain("executionStats");

// Estadísticas de colección
db.users.stats();
db.scores.stats();

// Validar índices utilizados
db.scores.find({ userId: ObjectId("...") }).hint({ userId: 1, timestamp: -1 });
```

---

## ⚡ Redis Operations

### Conexión y Configuración Redis

#### Acceso Directo al Contenedor
```bash
# Conectar al contenedor Redis
docker exec -it pacman-redis redis-cli

# Conectar con información de la base
docker exec -it pacman-redis redis-cli info

# Monitorear comandos en tiempo real
docker exec -it pacman-redis redis-cli monitor
```

#### Conexión desde la Aplicación
```javascript
// Configuración de conexión Node.js
const redis = require('redis');
const client = redis.createClient({
  host: 'redis',
  port: 6379,
  // password: 'password' // Si se requiere auth
});

// Verificar conexión
client.ping((err, response) => {
  console.log(response); // "PONG"
});
```

### Tipos de Datos

#### Strings (Datos Simples)
```redis
# Guardar datos de usuario temporales
SET user:1001:temp_score 2500
GET user:1001:temp_score

# Con expiración (30 minutos)
SETEX user:1001:game_session 1800 "active"

# Incrementar contadores
INCR daily_games_count
INCR user:1001:games_played

# Múltiples operaciones
MSET user:1001:level 3 user:1001:lives 2 user:1001:powerups 1
MGET user:1001:level user:1001:lives user:1001:powerups
```

#### Hashes (Objetos)
```redis
# Datos de sesión de usuario
HSET user:1001:session username "devops_player" team "Team Roxs" score 2500
HGET user:1001:session username
HGETALL user:1001:session

# Estadísticas de juego en tiempo real
HSET game:session:abc123 player_id 1001 current_score 1500 level 2 lives 3
HINCRBY game:session:abc123 current_score 100
HINCRBY game:session:abc123 pelletsEaten 1

# Configuración de la aplicación
HSET app:config max_players 100 game_duration 300 difficulty_level 2
HGET app:config max_players
```

#### Lists (Listas Ordenadas)
```redis
# Historial de puntuaciones por usuario
LPUSH user:1001:score_history 2500
LPUSH user:1001:score_history 2800
LRANGE user:1001:score_history 0 9  # Últimas 10 puntuaciones

# Cola de eventos de juego
LPUSH game:events "user:1001:level_completed:3"
LPUSH game:events "user:1002:powerup_collected:ghost_eater"
RPOP game:events  # Procesar eventos

# Log de actividades
LPUSH activity:log "$(date): User devops_player completed level 3"
LTRIM activity:log 0 999  # Mantener solo últimas 1000 entradas
```

#### Sets (Conjuntos)
```redis
# Usuarios activos en línea
SADD online_users user:1001 user:1002 user:1003
SCARD online_users  # Contar usuarios en línea
SISMEMBER online_users user:1001
SMEMBERS online_users

# Achievements por usuario
SADD user:1001:achievements "FIRST_WIN" "SPEED_DEMON" "GHOST_HUNTER"
SCARD user:1001:achievements
SINTER user:1001:achievements user:1002:achievements  # Achievements comunes

# Participantes del challenge
SADD challenge:90dayswithRoxs:participants user:1001 user:1002
SCARD challenge:90dayswithRoxs:participants
```

#### Sorted Sets (Conjuntos Ordenados)
```redis
# Leaderboard global (por puntuación)
ZADD global_leaderboard 2500 user:1001
ZADD global_leaderboard 2800 user:1002
ZADD global_leaderboard 3200 user:1003

# Top 10 jugadores
ZREVRANGE global_leaderboard 0 9 WITHSCORES

# Ranking de un usuario específico
ZREVRANK global_leaderboard user:1001

# Leaderboard por tiempo de juego
ZADD time_leaderboard 180 user:1001  # 3 minutos
ZADD time_leaderboard 240 user:1002  # 4 minutos

# Jugadores en un rango de puntuación
ZRANGEBYSCORE global_leaderboard 2000 3000 WITHSCORES
```

### Operaciones de Cache

#### Cache de Datos Frecuentes
```redis
# Cache de información de usuario
SET cache:user:1001 '{"username":"devops_player","team":"Team Roxs","level":5}' EX 3600

# Cache de leaderboard (actualizar cada 5 minutos)
SET cache:leaderboard:global '[{"user":"player1","score":5000},{"user":"player2","score":4800}]' EX 300

# Cache de configuración del juego
HSET cache:game_config max_level 10 base_score 100 bonus_multiplier 1.5
EXPIRE cache:game_config 1800
```

#### Invalidación de Cache
```redis
# Invalidar cache específico
DEL cache:user:1001
DEL cache:leaderboard:global

# Invalidar múltiples caches
DEL cache:user:1001 cache:user:1002 cache:user:1003

# Buscar y eliminar patrones
# (Nota: usar con cuidado en producción)
redis-cli --scan --pattern "cache:user:*" | xargs redis-cli DEL
```

### Sesiones de Usuario

#### Gestión de Sesiones
```redis
# Crear sesión de usuario
HSET session:abc123 user_id 1001 username "devops_player" login_time "2025-06-27T10:00:00Z"
EXPIRE session:abc123 7200  # 2 horas

# Validar sesión
EXISTS session:abc123
HGET session:abc123 user_id

# Renovar sesión
EXPIRE session:abc123 7200

# Eliminar sesión (logout)
DEL session:abc123

# Múltiples sesiones por usuario
SADD user:1001:sessions session:abc123 session:def456
SCARD user:1001:sessions  # Contar sesiones activas
```

#### Tokens JWT en Cache
```redis
# Blacklist de tokens JWT
SADD jwt:blacklist "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
SISMEMBER jwt:blacklist "token_here"

# Rate limiting por token
INCR rate_limit:token:abc123
EXPIRE rate_limit:token:abc123 60  # 1 minuto
```

### Leaderboard en Tiempo Real

#### Implementación Completa de Leaderboard
```redis
# Agregar/actualizar puntuación
ZADD leaderboard:daily 2500 user:1001
ZADD leaderboard:weekly 2500 user:1001
ZADD leaderboard:monthly 2500 user:1001
ZADD leaderboard:alltime 2500 user:1001

# Obtener top jugadores con información adicional
ZREVRANGE leaderboard:daily 0 9 WITHSCORES

# Script Lua para actualización atómica
EVAL "
local user = ARGV[1]
local score = tonumber(ARGV[2])
local current = redis.call('ZSCORE', 'leaderboard:daily', user)
if not current or score > current then
    redis.call('ZADD', 'leaderboard:daily', score, user)
    return 1
else
    return 0
end
" 0 user:1001 2800
```

#### Leaderboards Específicos
```redis
# Por nivel
ZADD leaderboard:level:1 1500 user:1001
ZADD leaderboard:level:2 2500 user:1001
ZADD leaderboard:level:3 3500 user:1001

# Por equipo
ZADD leaderboard:team:roxs 2500 user:1001
ZADD leaderboard:team:devops 2800 user:1002

# Por modo de juego
ZADD leaderboard:classic 2500 user:1001
ZADD leaderboard:challenge 3200 user:1001

# Combinación de leaderboards (intersección)
ZINTERSTORE leaderboard:team_challenge 2 leaderboard:team:roxs leaderboard:challenge
```

#### Estadísticas en Tiempo Real
```redis
# Contadores globales
INCR stats:total_games
INCR stats:total_players
INCRBY stats:total_score 2500

# Estadísticas por período
INCR stats:$(date +%Y-%m-%d):games
INCR stats:$(date +%Y-%m):games
INCR stats:$(date +%Y):games

# Promedios móviles (usando sorted sets con timestamp)
ZADD avg_scores:hourly $(date +%s) 2500
ZREMRANGEBYSCORE avg_scores:hourly 0 $(($(date +%s) - 3600))  # Mantener última hora
```

### Pub/Sub para Eventos en Tiempo Real

#### Sistema de Notificaciones
```redis
# Suscribirse a canales
SUBSCRIBE game:events
SUBSCRIBE user:1001:notifications
SUBSCRIBE leaderboard:updates

# Publicar eventos
PUBLISH game:events '{"type":"level_completed","user":"user:1001","level":3}'
PUBLISH leaderboard:updates '{"type":"new_highscore","user":"user:1001","score":5000}'
PUBLISH user:1001:notifications '{"type":"achievement","achievement":"FIRST_WIN"}'
```

#### Patrones de Suscripción
```redis
# Suscribirse a patrones
PSUBSCRIBE user:*:notifications
PSUBSCRIBE game:level:*:events
PSUBSCRIBE team:*:updates

# Publicar a patrones específicos
PUBLISH user:1001:notifications '{"message":"Welcome back!"}'
PUBLISH game:level:3:events '{"type":"boss_defeated"}'
```

---

## 🛠️ Herramientas de Administración

### MongoDB Compass (GUI)
```bash
# Acceder a Mongo Express (interfaz web)
open http://localhost:8081

# Credenciales por defecto
Username: admin
Password: admin
```

### Redis Commander (GUI)
```bash
# Instalar Redis Commander globalmente
npm install -g redis-commander

# Ejecutar (conectar al Redis local)
redis-commander --redis-host localhost --redis-port 6379
```

### Scripts de Administración

#### Backup de MongoDB
```bash
#!/bin/bash
# Script: backup-mongo.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups/mongodb"

# Crear backup
docker exec pacman-mongodb mongodump --db pacman-devops --out /tmp/backup_$DATE

# Copiar del contenedor al host
docker cp pacman-mongodb:/tmp/backup_$DATE $BACKUP_DIR/

echo "Backup completado: $BACKUP_DIR/backup_$DATE"
```

#### Backup de Redis
```bash
#!/bin/bash
# Script: backup-redis.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups/redis"

# Forzar snapshot
docker exec pacman-redis redis-cli BGSAVE

# Copiar archivo RDB
docker cp pacman-redis:/data/dump.rdb $BACKUP_DIR/dump_$DATE.rdb

echo "Backup Redis completado: $BACKUP_DIR/dump_$DATE.rdb"
```

---

## 📊 Monitoreo y Performance

### MongoDB Monitoring

#### Queries de Performance
```javascript
// Ver operaciones lentas
db.setProfilingLevel(2, { slowms: 100 });
db.system.profile.find().sort({ ts: -1 }).limit(5);

// Estadísticas de operaciones
db.serverStatus().opcounters;

// Uso de memoria
db.serverStatus().mem;

// Conexiones activas
db.serverStatus().connections;

// Estadísticas por colección
db.users.stats();
db.scores.stats();
```

#### Alertas y Monitoreo
```bash
# Script de monitoreo de conexiones
#!/bin/bash
connections=$(docker exec pacman-mongodb mongosh --quiet --eval "db.serverStatus().connections.current")
if [ $connections -gt 80 ]; then
    echo "ALERTA: Muchas conexiones MongoDB: $connections"
fi
```

### Redis Monitoring

#### Comandos de Monitoreo
```redis
# Información general del servidor
INFO

# Información específica
INFO memory
INFO stats
INFO replication
INFO clients

# Comandos en tiempo real
MONITOR

# Comandos más lentos
SLOWLOG GET 10

# Uso de memoria por tipo de dato
MEMORY USAGE key_name

# Estadísticas de comandos
INFO commandstats
```

#### Scripts de Monitoreo
```bash
#!/bin/bash
# Script: monitor-redis.sh

# Memoria utilizada
memory_used=$(docker exec pacman-redis redis-cli INFO memory | grep used_memory_human | cut -d: -f2 | tr -d '\r')

# Número de claves
total_keys=$(docker exec pacman-redis redis-cli DBSIZE)

# Conexiones
connected_clients=$(docker exec pacman-redis redis-cli INFO clients | grep connected_clients | cut -d: -f2 | tr -d '\r')

echo "Redis Stats:"
echo "  Memoria: $memory_used"
echo "  Claves: $total_keys"
echo "  Clientes: $connected_clients"
```

### Logs y Debugging

#### MongoDB Logs
```bash
# Ver logs del contenedor
docker logs pacman-mongodb -f

# Logs específicos de queries lentas
docker exec pacman-mongodb mongosh --eval "db.setLogLevel(1, 'query')"
```

#### Redis Logs
```bash
# Ver logs del contenedor
docker logs pacman-redis -f

# Configurar nivel de log
docker exec pacman-redis redis-cli CONFIG SET loglevel notice
```

---

## 🎯 Casos de Uso Específicos del Juego

### Inicialización de Partida
```javascript
// MongoDB: Crear registro de partida
db.games.insertOne({
  gameId: "game_123",
  userId: ObjectId("user_id"),
  startTime: new Date(),
  status: "active",
  initialLives: 3,
  currentLevel: 1
});
```

```redis
# Redis: Cache de estado de juego
HSET game:123 user_id 1001 lives 3 level 1 score 0 powerups 0
EXPIRE game:123 1800  # 30 minutos max
```

### Actualización de Puntuación
```javascript
// MongoDB: Actualizar puntuación final
db.scores.insertOne({
  userId: ObjectId("user_id"),
  gameId: "game_123",
  finalScore: 2500,
  timestamp: new Date()
});
```

```redis
# Redis: Actualizar leaderboard en tiempo real
ZADD leaderboard:realtime 2500 user:1001
PUBLISH leaderboard:updates '{"user":"user:1001","score":2500}'
```

### Sistema de Achievements
```javascript
// MongoDB: Verificar y otorgar achievement
const userStats = db.users.findOne({_id: ObjectId("user_id")});
if (userStats.stats.bestScore >= 5000) {
  db.users.updateOne(
    {_id: ObjectId("user_id")},
    {$addToSet: {achievements: "HIGH_SCORER"}}
  );
}
```

```redis
# Redis: Cache de achievements
SADD user:1001:achievements "HIGH_SCORER"
PUBLISH user:1001:notifications '{"type":"achievement","name":"HIGH_SCORER"}'
```

---

## 🔧 Comandos Útiles de Mantenimiento

### Limpieza Periódica
```javascript
// MongoDB: Limpiar sesiones expiradas
db.sessions.deleteMany({
  expiresAt: { $lt: new Date() }
});

// Limpiar puntuaciones muy antiguas
db.scores.deleteMany({
  timestamp: { 
    $lt: new Date(Date.now() - 365 * 24 * 60 * 60 * 1000) 
  }
});
```

```redis
# Redis: Limpiar datos expirados manualmente
FLUSHDB  # ¡CUIDADO! Elimina toda la base actual

# Limpiar por patrón
redis-cli --scan --pattern "temp:*" | xargs redis-cli DEL
```

### Optimización
```javascript
// MongoDB: Reindexar colecciones
db.users.reIndex();
db.scores.reIndex();

// Compactar base de datos
db.runCommand({compact: "users"});
```

```redis
# Redis: Optimizar memoria
MEMORY PURGE
BGREWRITEAOF  # Reescribir AOF para optimizar
```

---

**¡Happy Coding!** 🚀  
**Parte del 90DaysWithRoxs DevOps Challenge**
