# 🎮 Pacman Backend API

![](https://media.licdn.com/dms/image/v2/D4D16AQF4ND-cC_uxZg/profile-displaybackgroundimage-shrink_350_1400/profile-displaybackgroundimage-shrink_350_1400/0/1731367727725?e=1753920000&v=beta&t=80SZ4IOx4V_VDcCBli7aFjYuMhzMos9SRFq8GnV8zc4)

> **Proyecto educativo de DevOps** creado por **roxsross** para aprender conceptos fundamentales de desarrollo, contenedores, orquestación y monitoreo.

Backend Node.js/Express para el juego Pacman con autenticación JWT y gestión de puntuaciones.

## 🚀 Tecnologías

- **Node.js** - Runtime JavaScript
- **Express.js** - Framework web
- **MongoDB** - Base de datos
- **Redis** - Cache y sesiones
- **JWT** - Autenticación
- **Docker** - Containerización

## 📦 Instalación

```bash
# Instalar dependencias
npm install

# Variables de entorno
cp .env.example .env
```

## 🔧 Variables de Entorno

```env
NODE_ENV=production
PORT=8080
MONGODB_URI=mongodb://localhost:27017/pacman-devops
REDIS_URL=redis://localhost:6379
JWT_SECRET=your-super-secret-jwt-key
```

## 🏃‍♂️ Desarrollo

```bash
# Desarrollo local
npm run dev

# Con Docker
docker build -t pacman-backend .
docker run -p 8080:8080 pacman-backend
```

## 📋 API Endpoints

### Autenticación
- `POST /auth/register` - Registrar usuario
- `POST /auth/login` - Iniciar sesión

### Puntuaciones
- `GET /scores` - Obtener leaderboard
- `POST /scores` - Guardar puntuación
- `GET /scores/user/:userId` - Puntuaciones del usuario

### Salud
- `GET /health` - Estado del servicio

## 🧪 Testing

```bash
npm test
```

## 🐳 Docker

```bash
# Construir imagen
docker build -t pacman-backend .

# Ejecutar contenedor
docker run -p 8080:8080 \
  -e MONGODB_URI=mongodb://host.docker.internal:27017/pacman \
  -e REDIS_URL=redis://host.docker.internal:6379 \
  pacman-backend
```

## 📁 Estructura

```
backend/
├── server.js           # Servidor principal
├── routes/             # Rutas de la API
├── controllers/        # Controladores
├── models/            # Modelos de datos
├── middleware/        # Middlewares
├── utils/             # Utilidades
├── tests/             # Tests
├── Dockerfile         # Container configuration
└── package.json       # Dependencias
```

## 🔍 Logs

Los logs incluyen información sobre:
- Requests HTTP
- Conexiones a base de datos
- Errores de autenticación
- Operaciones de puntuaciones

---

**Parte del 90DaysWithRoxs DevOps Challenge** 🚀
