# 🎮 Ejemplos Prácticos de Queries - Pacman Game

Ejemplos específicos de queries para casos de uso reales del juego Pacman.

## 🚀 Casos de Uso del Juego

### 1. 🎯 Registrar Nueva Partida

```javascript
// MongoDB: Crear registro de usuario nuevo
db.users.insertOne({
  username: "pacman_master",
  password: "$2b$10$X8f2vN9...", // hash bcrypt
  email: "master@90dayswithroxs.com",
  fullName: "Pacman Master",
  team: "Team DevOps",
  isParticipant: true,
  containerInfo: {
    platform: "docker",
    hostname: "pacman-backend-prod",
    environment: "production"
  },
  registrationDate: new Date(),
  devOpsChallenge: "90DaysWithRoxs",
  stats: {
    totalGames: 0,
    totalScore: 0,
    averageScore: 0,
    bestScore: 0,
    totalPlayTime: 0
  },
  achievements: []
});
```

```redis
# Redis: Inicializar sesión de juego
HSET game:session:abc123 user_id 1001 username "pacman_master" level 1 score 0 lives 3 powerups 0 start_time $(date +%s)
EXPIRE game:session:abc123 1800  # 30 minutos máximo por partida

# Agregar a usuarios en línea
SADD online_users user:1001
```

### 2. 🏃‍♂️ Actualizar Estado Durante el Juego

```redis
# Incrementar puntuación cuando come pellet
HINCRBY game:session:abc123 score 10
HINCRBY game:session:abc123 pelletsEaten 1

# Usar power-up (comer fantasma)
HINCRBY game:session:abc123 score 200
HINCRBY game:session:abc123 ghostsEaten 1
HSET game:session:abc123 powerup_active true
EXPIRE game:session:abc123 1800

# Perder una vida
HINCRBY game:session:abc123 lives -1

# Subir de nivel
HINCRBY game:session:abc123 level 1
HSET game:session:abc123 score 2500

# Actualizar leaderboard en tiempo real
ZADD leaderboard:realtime 2500 user:1001
ZADD leaderboard:daily 2500 user:1001
```

### 3. 🏆 Finalizar Partida y Guardar Puntuación

```javascript
// MongoDB: Guardar puntuación final
db.scores.insertOne({
  userId: ObjectId("64a1b2c3d4e5f6789abcdef0"),
  username: "pacman_master",
  score: 3500,
  level: 5,
  gameTime: 420, // 7 minutos
  pelletsEaten: 180,
  ghostsEaten: 8,
  lives: 1,
  gameMode: "classic",
  deviceInfo: {
    platform: "web",
    userAgent: "Mozilla/5.0...",
    screenResolution: "1920x1080"
  },
  gameplayStats: {
    moveCount: 850,
    powerUpsUsed: 4,
    perfectLevels: 2
  },
  timestamp: new Date(),
  challengeId: "90DaysWithRoxs"
});

// Actualizar estadísticas del usuario
db.users.updateOne(
  { _id: ObjectId("64a1b2c3d4e5f6789abcdef0") },
  {
    $inc: {
      "stats.totalGames": 1,
      "stats.totalScore": 3500,
      "stats.totalPlayTime": 420
    },
    $max: { "stats.bestScore": 3500 },
    $set: { lastLogin: new Date() }
  }
);

// Recalcular promedio
db.users.updateOne(
  { _id: ObjectId("64a1b2c3d4e5f6789abcdef0") },
  [{
    $set: {
      "stats.averageScore": {
        $divide: ["$stats.totalScore", "$stats.totalGames"]
      }
    }
  }]
);
```

```redis
# Limpiar sesión de juego
DEL game:session:abc123

# Mantener en leaderboard persistente
ZADD global_leaderboard 3500 user:1001
ZADD leaderboard:weekly 3500 user:1001
ZADD leaderboard:monthly 3500 user:1001

# Notificar nuevo récord si aplica
PUBLISH leaderboard:updates '{"type":"new_record","user":"pacman_master","score":3500}'
```

### 4. 🏅 Sistema de Achievements

```javascript
// Verificar y otorgar achievements
const user = db.users.findOne({_id: ObjectId("64a1b2c3d4e5f6789abcdef0")});

// Achievement: Primera victoria
if (user.stats.totalGames === 1) {
  db.users.updateOne(
    {_id: user._id},
    {$addToSet: {achievements: "FIRST_WIN"}}
  );
}

// Achievement: Puntuación alta (5000+)
if (user.stats.bestScore >= 5000) {
  db.users.updateOne(
    {_id: user._id},
    {$addToSet: {achievements: "HIGH_SCORER"}}
  );
}

// Achievement: Jugador frecuente (100+ partidas)
if (user.stats.totalGames >= 100) {
  db.users.updateOne(
    {_id: user._id},
    {$addToSet: {achievements: "VETERAN_PLAYER"}}
  );
}

// Achievement: Speedrun (completar nivel en menos de 60 segundos)
const fastGame = db.scores.findOne({
  userId: user._id,
  gameTime: {$lt: 60},
  level: {$gte: 1}
});

if (fastGame) {
  db.users.updateOne(
    {_id: user._id},
    {$addToSet: {achievements: "SPEED_DEMON"}}
  );
}
```

```redis
# Cache de achievements para acceso rápido
SADD user:1001:achievements "FIRST_WIN" "HIGH_SCORER"

# Notificar achievement
PUBLISH user:1001:notifications '{"type":"achievement","name":"HIGH_SCORER","description":"Reached 5000+ points!"}'
```

### 5. 📊 Consultas para Leaderboard

```javascript
// Top 10 jugadores globales
db.users.aggregate([
  {
    $match: { 
      "stats.totalGames": {$gte: 1}
    }
  },
  {
    $project: {
      username: 1,
      fullName: 1,
      team: 1,
      bestScore: "$stats.bestScore",
      totalGames: "$stats.totalGames",
      averageScore: "$stats.averageScore",
      achievements: {$size: "$achievements"}
    }
  },
  {
    $sort: { bestScore: -1 }
  },
  {
    $limit: 10
  }
]);

// Ranking por equipos
db.users.aggregate([
  {
    $match: { isParticipant: true }
  },
  {
    $group: {
      _id: "$team",
      teamMembers: {$sum: 1},
      totalScore: {$sum: "$stats.totalScore"},
      averageTeamScore: {$avg: "$stats.bestScore"},
      bestTeamScore: {$max: "$stats.bestScore"}
    }
  },
  {
    $sort: { bestTeamScore: -1 }
  }
]);

// Jugadores más activos de la semana
db.scores.aggregate([
  {
    $match: {
      timestamp: {
        $gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
      }
    }
  },
  {
    $group: {
      _id: "$userId",
      username: {$first: "$username"},
      gamesThisWeek: {$sum: 1},
      totalScoreThisWeek: {$sum: "$score"},
      bestScoreThisWeek: {$max: "$score"}
    }
  },
  {
    $sort: { gamesThisWeek: -1 }
  },
  {
    $limit: 15
  }
]);
```

```redis
# Leaderboard en tiempo real (Redis)
ZREVRANGE global_leaderboard 0 9 WITHSCORES

# Leaderboard diario
ZREVRANGE leaderboard:daily 0 9 WITHSCORES

# Ranking de un usuario específico
ZREVRANK global_leaderboard user:1001

# Comparar con otros jugadores del mismo nivel
ZRANGEBYSCORE global_leaderboard 2000 4000 WITHSCORES
```

### 6. 🔍 Análisis de Patrones de Juego

```javascript
// Análisis de horarios de juego más populares
db.scores.aggregate([
  {
    $group: {
      _id: {
        hour: {$hour: "$timestamp"},
        dayOfWeek: {$dayOfWeek: "$timestamp"}
      },
      gamesCount: {$sum: 1},
      averageScore: {$avg: "$score"}
    }
  },
  {
    $sort: { gamesCount: -1 }
  }
]);

// Progresión de dificultad por nivel
db.scores.aggregate([
  {
    $group: {
      _id: "$level",
      averageScore: {$avg: "$score"},
      averageTime: {$avg: "$gameTime"},
      totalGames: {$sum: 1},
      averagePellets: {$avg: "$pelletsEaten"}
    }
  },
  {
    $sort: { _id: 1 }
  }
]);

// Análisis de retención (usuarios que vuelven a jugar)
db.users.aggregate([
  {
    $lookup: {
      from: "scores",
      localField: "_id",
      foreignField: "userId",
      as: "games"
    }
  },
  {
    $addFields: {
      daysSinceFirstGame: {
        $divide: [
          {$subtract: [new Date(), {$min: "$games.timestamp"}]},
          1000 * 60 * 60 * 24
        ]
      },
      daysSinceLastGame: {
        $divide: [
          {$subtract: [new Date(), {$max: "$games.timestamp"}]},
          1000 * 60 * 60 * 24
        ]
      }
    }
  },
  {
    $match: {
      daysSinceLastGame: {$lte: 7}, // Activos en la última semana
      daysSinceFirstGame: {$gte: 30} // Registrados hace más de 30 días
    }
  },
  {
    $project: {
      username: 1,
      daysSinceFirstGame: 1,
      daysSinceLastGame: 1,
      totalGames: "$stats.totalGames"
    }
  }
]);
```

### 7. 🧹 Mantenimiento y Limpieza

```javascript
// Limpiar puntuaciones de usuarios inactivos (6+ meses)
db.scores.deleteMany({
  timestamp: {
    $lt: new Date(Date.now() - 180 * 24 * 60 * 60 * 1000)
  }
});

// Archivar usuarios inactivos
db.users.updateMany(
  {
    lastLogin: {
      $lt: new Date(Date.now() - 365 * 24 * 60 * 60 * 1000)
    }
  },
  {
    $set: { archived: true }
  }
);

// Reindexar para mejor performance
db.scores.reIndex();
db.users.reIndex();
```

```redis
# Limpiar sesiones expiradas manualmente
redis-cli --scan --pattern "game:session:*" | xargs redis-cli DEL

# Limpiar cache temporal
redis-cli --scan --pattern "temp:*" | xargs redis-cli DEL

# Rotar leaderboards diarios
RENAME leaderboard:daily leaderboard:yesterday
DEL leaderboard:daily

# Backup de datos importantes
BGSAVE
```

### 8. 📈 Monitoreo de Performance

```javascript
// Consultas más lentas en MongoDB
db.setProfilingLevel(2, {slowms: 100});
db.system.profile.find().sort({ts: -1}).limit(5);

// Verificar uso de índices
db.scores.find({score: {$gte: 5000}}).explain("executionStats");

// Estadísticas de uso de colecciones
db.users.stats();
db.scores.stats();
```

```redis
# Monitorear comandos Redis
MONITOR

# Ver comandos más lentos
SLOWLOG GET 10

# Estadísticas de memoria por tipo
INFO memory

# Verificar hit ratio del cache
INFO stats
```

### 9. 🎯 Casos Especiales

```javascript
// Detectar posibles trampas (puntuaciones anómalas)
db.scores.find({
  $or: [
    {score: {$gt: 50000}}, // Puntuación suspiciosamente alta
    {gameTime: {$lt: 30}}, // Tiempo demasiado corto
    {level: {$gt: 20}}     // Nivel imposible
  ]
}).sort({timestamp: -1});

// Usuarios con múltiples cuentas (mismo email pattern)
db.users.aggregate([
  {
    $group: {
      _id: {
        emailDomain: {
          $substr: ["$email", {$indexOfCP: ["$email", "@"]}, -1]
        }
      },
      users: {$push: {username: "$username", email: "$email"}},
      count: {$sum: 1}
    }
  },
  {
    $match: {count: {$gt: 5}}
  }
]);
```

### 10. 🚀 Optimización para Producción

```javascript
// Índices optimizados para queries frecuentes
db.scores.createIndex({userId: 1, timestamp: -1});
db.scores.createIndex({score: -1, timestamp: -1});
db.scores.createIndex({timestamp: -1});
db.users.createIndex({username: 1}, {unique: true});
db.users.createIndex({"stats.bestScore": -1});
db.users.createIndex({team: 1, "stats.bestScore": -1});

// TTL para limpieza automática de sesiones
db.sessions.createIndex({expiresAt: 1}, {expireAfterSeconds: 0});
```

```redis
# Configuración optimizada para producción
CONFIG SET maxmemory 2gb
CONFIG SET maxmemory-policy allkeys-lru
CONFIG SET save "900 1 300 10 60 10000"

# Monitoreo automatizado
INFO memory | grep used_memory_peak_human
INFO stats | grep keyspace_hits
```

---

## 🧪 Scripts de Testing

### Datos de Prueba

```javascript
// Generar usuarios de prueba
for (let i = 1; i <= 50; i++) {
  db.users.insertOne({
    username: `testuser${i}`,
    password: "$2b$10$testpassword",
    email: `test${i}@90dayswithroxs.com`,
    fullName: `Test User ${i}`,
    team: `Team ${Math.ceil(i/10)}`,
    isParticipant: true,
    registrationDate: new Date(Date.now() - Math.random() * 90 * 24 * 60 * 60 * 1000),
    devOpsChallenge: "90DaysWithRoxs",
    stats: {
      totalGames: Math.floor(Math.random() * 100),
      totalScore: Math.floor(Math.random() * 50000),
      bestScore: Math.floor(Math.random() * 10000),
      totalPlayTime: Math.floor(Math.random() * 10000)
    },
    achievements: []
  });
}

// Generar puntuaciones de prueba
const users = db.users.find({username: /^testuser/}).toArray();
users.forEach(user => {
  for (let j = 0; j < Math.floor(Math.random() * 20); j++) {
    db.scores.insertOne({
      userId: user._id,
      username: user.username,
      score: Math.floor(Math.random() * 8000) + 500,
      level: Math.floor(Math.random() * 8) + 1,
      gameTime: Math.floor(Math.random() * 600) + 60,
      pelletsEaten: Math.floor(Math.random() * 200) + 50,
      ghostsEaten: Math.floor(Math.random() * 10),
      lives: Math.floor(Math.random() * 3) + 1,
      gameMode: ["classic", "challenge", "tournament"][Math.floor(Math.random() * 3)],
      timestamp: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000),
      challengeId: "90DaysWithRoxs"
    });
  }
});
```

---

**¡Happy Gaming & Coding!** 🎮🚀  
**Parte del 90DaysWithRoxs DevOps Challenge**
