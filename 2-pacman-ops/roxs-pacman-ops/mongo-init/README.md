# 🗃️ MongoDB Initialization

![](https://media.licdn.com/dms/image/v2/D4D16AQF4ND-cC_uxZg/profile-displaybackgroundimage-shrink_350_1400/profile-displaybackgroundimage-shrink_350_1400/0/1731367727725?e=1753920000&v=beta&t=80SZ4IOx4V_VDcCBli7aFjYuMhzMos9SRFq8GnV8zc4)

> **Proyecto educativo de DevOps** creado por **roxsross** para aprender conceptos fundamentales de desarrollo, contenedores, orquestación y monitoreo.

Scripts de inicialización para la base de datos MongoDB del proyecto Pacman.

## 📋 Descripción

Este directorio contiene los scripts que se ejecutan automáticamente cuando se inicializa el contenedor de MongoDB por primera vez.

## 📦 Archivos

- `init-db.js` - Script principal de inicialización de la base de datos

## 🚀 Funcionalidad

### init-db.js

Configura la base de datos inicial con:

- **Base de datos**: `pacman-devops`
- **Colecciones**:
  - `users` - Usuarios del juego
  - `scores` - Puntuaciones y records
  - `sessions` - Sesiones activas

### Datos Iniciales

El script crea:
- Índices optimizados para consultas
- Usuarios de prueba (en desarrollo)
- Configuración inicial de la base de datos

## 🔧 Uso

### Con Docker Compose

Los scripts se ejecutan automáticamente cuando MongoDB se inicia por primera vez:

```bash
# Los scripts se montan como volumen
volumes:
  - ./mongo-init:/docker-entrypoint-initdb.d:ro
```

### Ejecución Manual

```bash
# Conectar a MongoDB
mongosh pacman-devops

# Ejecutar script manualmente
load('/docker-entrypoint-initdb.d/init-db.js')
```

## 🏗️ Estructura de Datos

### Colección: users

```javascript
{
  _id: ObjectId,
  username: String,
  email: String,
  passwordHash: String,
  createdAt: Date,
  lastLogin: Date,
  totalGames: Number,
  bestScore: Number
}
```

### Colección: scores

```javascript
{
  _id: ObjectId,
  userId: ObjectId,
  username: String,
  score: Number,
  level: Number,
  gameTime: Number,
  createdAt: Date,
  gameMode: String
}
```

## 🔍 Verificación

Para verificar que la inicialización fue exitosa:

```bash
# Conectar a la base de datos
docker exec -it pacman-mongodb mongosh pacman-devops

# Listar colecciones
show collections

# Verificar datos
db.users.countDocuments()
db.scores.countDocuments()
```

## 🐳 Variables de Entorno

- `MONGO_INITDB_DATABASE=pacman-devops` - Nombre de la base de datos
- `MONGO_INITDB_ROOT_USERNAME` - Usuario admin (opcional)
- `MONGO_INITDB_ROOT_PASSWORD` - Contraseña admin (opcional)

## 🧹 Reset de Base de Datos

Para reinicializar la base de datos:

```bash
# Detener servicios
docker compose down

# Eliminar volumen de datos
docker volume rm pacman-ops_mongodb_data

# Reiniciar servicios
docker compose up -d
```

---

**Parte del 90DaysWithRoxs DevOps Challenge** 🚀
