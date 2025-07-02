# 🎮 Pacman DevOps Challenge by Roxs

![](https://media.licdn.com/dms/image/v2/D4D16AQF4ND-cC_uxZg/profile-displaybackgroundimage-shrink_350_1400/profile-displaybackgroundimage-shrink_350_1400/0/1731367727725?e=1753920000&v=beta&t=80SZ4IOx4V_VDcCBli7aFjYuMhzMos9SRFq8GnV8zc4)

[![Docker](https://img.shields.io/badge/Docker-Ready-blue?logo=docker)](https://docker.com)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/roxsross/roxs-pacman-ops)

# 🚀 90 Días de DevOps con Roxs

> **Proyecto educativo de DevOps** creado por **roxsross** para aprender conceptos fundamentales de desarrollo, contenedores, orquestación y monitoreo.

### Una implementación completa del clásico juego Pacman con arquitectura de microservicios, containerización Docker y prácticas DevOps modernas.

![DevOps Banner](./docs/13.png)

## 90DaysWithRoxs DevOps Challenge 🚀

<div align="center">
<img src="docs/1.png" alt="Pacman Game" width="600"/>
</div>

<div align="center">

## ✨ Características Destacadas

🎮 **Juego Completo** • 🐳 **Docker Ready** • 🔐 **Autenticación JWT** • 📊 **Leaderboard** • 🚀 **DevOps Scripts** • ⚡ **Redis Cache** • 🗃️ **MongoDB** • 📱 **Responsive**

[🚀 Inicio Rápido](#inicio-rapido) • [📸 Screenshots](#screenshots) • [🏗️ Arquitectura](#arquitectura) • [🐳 Docker](#docker) • [📱 Galería](#galeria-de-screenshots)

**💡 ¿Prefieres algo más directo?** → [QUICK-START.md](QUICK-START.md)  
**� ¿Necesitas ayuda con BD?** → [DATABASE-QUICK-REFERENCE.md](docs/DATABASE-QUICK-REFERENCE.md) ⭐  
**🗃️ ¿Queries de MongoDB/Redis?** → [DATABASE-QUERIES.md](docs/DATABASE-QUERIES.md)  
**🔧 ¿Problemas con las bases de datos?** → [DATABASE-TROUBLESHOOTING.md](docs/DATABASE-TROUBLESHOOTING.md)  
**⚡ ¿Redis avanzado?** → [REDIS-ADVANCED.md](docs/REDIS-ADVANCED.md)

</div>

## 📸 Screenshots

<div align="center">
<table>
<tr>
<td align="center" width="33%">
<img src="docs/5.png" alt="Gameplay" width="250"/><br>
<b>🎮 Gameplay</b>
</td>
<td align="center" width="33%">
<img src="docs/6.png" alt="Leaderboard" width="250"/><br>
<b>🏆 Leaderboard</b>
</td>
<td align="center" width="33%">
<img src="docs/1.png" alt="Login" width="250"/><br>
<b>🔐 Autenticación</b>
</td>
</tr>
</table>
</div>

## 🏗️ Arquitectura

```mermaid
graph TB
    subgraph "🌐 Cliente"
        U[👤 Usuario]
        B[🌍 Navegador Web]
    end

    subgraph "🐳 Docker Compose - Pacman DevOps"
        subgraph "🎨 Frontend Layer"
            FE[📱 React App<br/>Nginx:80<br/>Puerto: 8000]
        end
        
        subgraph "⚙️ Backend Layer"
            BE[🔧 Node.js API<br/>Express Server<br/>Puerto: 8080]
        end
        
        subgraph "🗃️ Data Layer"
            DB[(📊 MongoDB<br/>Puerto: 27017<br/>DB: pacman-devops)]
            CACHE[(⚡ Redis<br/>Puerto: 6379<br/>Cache & Sessions)]
        end
        
        subgraph "🛠️ Management Layer"
            ME[📋 Mongo Express<br/>Puerto: 8081<br/>DB Admin UI]
            INIT[🔧 Mongo Init<br/>Setup Scripts]
        end
        
        subgraph "📜 DevOps Layer"
            NET[🌐 pacman-network<br/>Docker Network]
            VOL1[💾 mongodb_data<br/>Volume]
            VOL2[💾 redis_data<br/>Volume]
        end
    end

    %% Conexiones Principales
    U --> B
    B -.->|HTTP:8000| FE
    FE -->|API Calls<br/>HTTP:8080| BE
    BE -->|JWT Auth<br/>Game Data| DB
    BE -->|Sessions<br/>Cache| CACHE
    
    %% Conexiones de Management
    ME -.->|Admin Access| DB
    INIT -.->|Initialize| DB
    
    %% Dependencias
    FE -.->|depends_on| BE
    FE -.->|depends_on| DB
    FE -.->|depends_on| CACHE
    BE -.->|depends_on| DB
    BE -.->|depends_on| CACHE
    ME -.->|depends_on| DB
    
    %% Volúmenes
    DB -.->|persist| VOL1
    CACHE -.->|persist| VOL2
    
    %% Red
    FE -.->|network| NET
    BE -.->|network| NET
    DB -.->|network| NET
    CACHE -.->|network| NET
    ME -.->|network| NET

    %% Estilos
    classDef frontend fill:#61dafb,stroke:#333,stroke-width:2px,color:#000
    classDef backend fill:#339933,stroke:#333,stroke-width:2px,color:#fff
    classDef database fill:#47A248,stroke:#333,stroke-width:2px,color:#fff
    classDef cache fill:#DC382D,stroke:#333,stroke-width:2px,color:#fff
    classDef management fill:#FF6C37,stroke:#333,stroke-width:2px,color:#fff
    classDef network fill:#0db7ed,stroke:#333,stroke-width:2px,color:#fff
    classDef client fill:#f9f9f9,stroke:#333,stroke-width:2px,color:#000

    class FE frontend
    class BE backend
    class DB database
    class CACHE cache
    class ME,INIT management
    class NET,VOL1,VOL2 network
    class U,B client
```

### 🔄 Flujo de Datos

1. **👤 Usuario** navega a http://localhost:8000
2. **📱 Frontend (React)** servido por Nginx
3. **🔧 Backend API** procesa requests en puerto 8080
4. **📊 MongoDB** almacena usuarios, puntuaciones y datos del juego
5. **⚡ Redis** maneja sesiones y cache de datos
6. **📋 Mongo Express** permite administración de la BD en puerto 8081

### 🏗️ Componentes Técnicos

| Componente | Tecnología | Puerto | Función |
|------------|------------|--------|---------|
| **Frontend** | React + Nginx | 8000 | Interfaz de usuario |
| **Backend** | Node.js + Express | 8080 | API REST y lógica de negocio |
| **Database** | MongoDB 7.0 | 27017 | Persistencia de datos |
| **Cache** | Redis Alpine | 6379 | Sesiones y cache |
| **Admin UI** | Mongo Express | 8081 | Administración de BD |
| **Network** | Docker Bridge | - | Comunicación interna |
| **Volumes** | Docker Volumes | - | Persistencia de datos |

## 📁 Estructura del Proyecto

```mermaid
graph TD
    ROOT[📦 pacman-ops/]
    
    ROOT --> FE[🎨 frontend/]
    ROOT --> BE[⚙️ backend/]
    ROOT --> MI[🗃️ mongo-init/]
    ROOT --> SC[📜 scripts/]
    ROOT --> DC[📄 docs/]
    ROOT --> CONFIG[⚙️ Config Files]
    
    FE --> FE_SRC[📂 src/]
    FE --> FE_PUB[📂 public/]
    FE --> FE_PKG[📄 package.json]
    FE --> FE_DOC[🐳 Dockerfile]
    
    BE --> BE_SRV[📄 server.js]
    BE --> BE_PKG[📄 package.json]
    BE --> BE_DOC[🐳 Dockerfile]
    
    FE_SRC --> COMP[📂 components/]
    FE_SRC --> GAME[📂 game/]
    COMP --> LOGIN[👤 login/]
    COMP --> LEADER[🏆 leaderboard/]
    GAME --> MODELS[📂 models/]
    GAME --> MECH[📂 mechanics/]
    
    MI --> INIT[📄 init-db.js]
    SC --> DEV[📄 dev.sh]
    DC --> IMGS[🖼️ 1-7.png]
    
    CONFIG --> COMPOSE[🐳 docker compose.yml]
    CONFIG --> README[📚 README.md]
    CONFIG --> QUICK[⚡ QUICK-START.md]

    classDef folder fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef file fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef docker fill:#0db7ed,stroke:#0179a8,stroke-width:2px
    classDef script fill:#fff3e0,stroke:#e65100,stroke-width:2px

    class ROOT,FE,BE,MI,SC,DC,FE_SRC,FE_PUB,COMP,GAME,MODELS,MECH,LOGIN,LEADER folder
    class FE_PKG,BE_PKG,BE_SRV,INIT,IMGS,README,QUICK file
    class FE_DOC,BE_DOC,COMPOSE docker
    class DEV script
```

## 🏃‍♂️ Inicio Rápido {#inicio-rapido}

### 1. Prerrequisitos

```bash
# Docker y Docker Compose
docker --version
docker compose --version

# Git
git --version
```

### 2. Clonar y Ejecutar

```bash
# Clonar el repositorio
git clone https://github.com/roxsross/roxs-pacman-ops.git
cd roxs-pacman-ops

# Iniciar todos los servicios
./scripts/dev.sh start

# O usando Docker Compose directamente
docker compose up -d
```

### 3. Acceder a la Aplicación

- 🎮 **Juego**: http://localhost:8000
- 🔧 **API**: http://localhost:8080
- 📊 **MongoDB Admin**: http://localhost:8081

## 🛠️ Scripts DevOps

El script `./scripts/dev.sh` facilita las operaciones comunes:

```bash
# Comandos disponibles
./scripts/dev.sh help

# Iniciar servicios
./scripts/dev.sh start

# Ver logs
./scripts/dev.sh logs

# Estado de servicios
./scripts/dev.sh health

# Limpiar todo
./scripts/dev.sh clean
```

### 🗃️ Scripts de Base de Datos

El script `./scripts/db-helper.sh` facilita las operaciones con MongoDB y Redis:

```bash
# Comandos disponibles
./scripts/db-helper.sh help

# Estadísticas MongoDB
./scripts/db-helper.sh mongo-stats
./scripts/db-helper.sh mongo-leaderboard

# Estadísticas Redis
./scripts/db-helper.sh redis-stats
./scripts/db-helper.sh redis-leaderboard

# Monitoreo en tiempo real
./scripts/db-helper.sh monitor-all

# Health check de bases de datos
./scripts/db-helper.sh health-check
```

El script `./scripts/db-troubleshooting.sh` proporciona herramientas avanzadas de diagnóstico:

```bash
# Health check completo
./scripts/db-troubleshooting.sh health

# Monitoreo en vivo
./scripts/db-troubleshooting.sh live-monitor

# Reparar problemas comunes
./scripts/db-troubleshooting.sh fix-connections
./scripts/db-troubleshooting.sh clean-cache

# Optimización
./scripts/db-troubleshooting.sh optimize-indexes
./scripts/db-troubleshooting.sh analyze-performance

# Mantenimiento
./scripts/db-troubleshooting.sh cleanup-old-data
./scripts/db-troubleshooting.sh backup-db
```

## 🎯 Características

### 🎮 Gameplay
- Juego Pacman completo con físicas precisas
- Sistema de puntuaciones en tiempo real
- Efectos de sonido y animaciones
- Controles responsivos (teclado/táctil)

### 🔐 Autenticación
- Registro e inicio de sesión
- Tokens JWT para seguridad
- Gestión de sesiones con Redis

### 📊 Leaderboard
- Puntuaciones globales
- Historial personal
- Tiempo de juego registrado
- Estadísticas avanzadas

### 🏗️ DevOps
- Containerización completa
- Volúmenes persistentes
- Redes Docker aisladas
- Health checks automáticos
- Logs centralizados

## 🔄 Flujo de Desarrollo

```mermaid
graph TD
    START([🚀 Iniciar Desarrollo]) --> CLONE[📥 git clone]
    CLONE --> SETUP[🔧 ./scripts/dev.sh setup]
    SETUP --> START_SERVICES[▶️ ./scripts/dev.sh start]

    START_SERVICES --> DEV_CHOICE{Desarrollar en...}

    DEV_CHOICE -->|Frontend| DEV_FE[💻 ./scripts/dev.sh dev-frontend]
    DEV_CHOICE -->|Backend| DEV_BE[⚙️ ./scripts/dev.sh dev-backend]
    DEV_CHOICE -->|Full Stack| CONTAINERS[🐳 Docker Compose]

    DEV_FE --> CODE_FE[📝 Editar React/JS]
    DEV_BE --> CODE_BE[📝 Editar Node.js]
    CONTAINERS --> CODE_FULL[📝 Editar Ambos]

    CODE_FE --> TEST_FE[🧪 npm test]
    CODE_BE --> TEST_BE[🧪 npm test]
    CODE_FULL --> HEALTH[💓 ./scripts/dev.sh health]

    TEST_FE --> BUILD[🏗️ ./scripts/dev.sh build]
    TEST_BE --> BUILD
    HEALTH --> BUILD

    BUILD --> DEPLOY[🚀 docker compose up -d]
    DEPLOY --> VERIFY[✅ Verificar en localhost:8000]

    VERIFY --> SATISFIED{😊 ¿Satisfecho?}
    SATISFIED -->|No| DEV_CHOICE
    SATISFIED -->|Sí| COMMIT[📤 git commit & push]

    COMMIT --> CLEAN[🧹 ./scripts/dev.sh clean]
    CLEAN --> END([🎉 ¡Completado!])

    classDef start fill:#4caf50,stroke:#333,stroke-width:2px,color:#fff
    classDef dev fill:#2196f3,stroke:#333,stroke-width:2px,color:#fff
    classDef test fill:#ff9800,stroke:#333,stroke-width:2px,color:#fff
    classDef deploy fill:#9c27b0,stroke:#333,stroke-width:2px,color:#fff
    classDef endStyle fill:#4caf50,stroke:#333,stroke-width:2px,color:#fff

    class START,SETUP start
    class DEV_FE,DEV_BE,CONTAINERS,CODE_FE,CODE_BE,CODE_FULL dev
    class TEST_FE,TEST_BE,HEALTH test
    class BUILD,DEPLOY,VERIFY deploy
    class END,COMMIT endStyle
```

## 🧪 Desarrollo

### Frontend (React)

```bash
cd frontend

# Desarrollo local
npm install
npm start

# Build de producción
npm run build

# Testing
npm test
```

### Backend (Node.js)

```bash
cd backend

# Desarrollo local
npm install
npm run dev

# Testing
npm test

# Producción
npm start
```

## 🐳 Docker {#docker}

### Builds Individuales

```bash
# Frontend
docker build -t pacman-frontend ./frontend

# Backend
docker build -t pacman-backend ./backend
```

### Docker Compose

```bash
# Construir y ejecutar
docker compose up --build

# Solo ejecutar
docker compose up -d

# Ver logs
docker compose logs -f

# Detener
docker compose down
```

## 📦 Volúmenes Persistentes

Los datos se persisten automáticamente:

- `mongodb_data` - Datos de MongoDB
- `redis_data` - Cache de Redis

## 🔧 Variables de Entorno

### Frontend
- `REACT_APP_BACKEND_URL` - URL del backend
- `NODE_ENV` - Entorno de ejecución

### Backend
- `MONGODB_URI` - Conexión a MongoDB
- `REDIS_URL` - Conexión a Redis
- `JWT_SECRET` - Clave para tokens
- `PORT` - Puerto del servidor


## 📈 Monitoring (Próximamente)

> 🚧 **Próximamente:** Se integrará monitoreo avanzado con Prometheus, Grafana y alertas automáticas para todos los servicios.

### Health Checks

```bash
# Estado general
./scripts/dev.sh health

# Servicios individuales
curl http://localhost:8000/health  # Frontend
curl http://localhost:8080/health  # Backend
```

### Logs

```bash
# Todos los servicios
docker compose logs -f

# Servicio específico
docker compose logs -f pacman-frontend
docker compose logs -f pacman-backend
```

## 🧹 Limpieza

```bash
# Limpiar contenedores y redes
./scripts/dev.sh clean

# Limpiar volúmenes también
docker compose down -v
docker system prune -a
```

## 🚀 Despliegue

### Producción

> 🚧 **Próximamente:** Se incluirán instrucciones detalladas para ajustar la configuración y los scripts a un entorno de producción real, incluyendo variables seguras, optimización de imágenes Docker, y despliegue en servidores cloud.

#### Producción Local

```bash
# Build optimizado
docker compose -f docker compose.yml up --build -d

# Verificar servicios
./scripts/dev.sh health
```

### Variables de Producción

Asegúrate de configurar:
- JWT_SECRET único y seguro
- URLs de base de datos production
- Configuración de CORS apropiada

## 📱 Galería de Screenshots {#galeria-de-screenshots}

<div align="center">
<details>
<summary><b>🖼️ Ver todas las capturas (7 imágenes)</b></summary>
<br>

<table>
<tr>
<td align="center" width="33%">
<img src="docs/1.png" alt="Main Screen" width="200"/><br>
<b>🎮 Pantalla Principal</b>
</td>
<td align="center" width="33%">
<img src="docs/5.png" alt="Gameplay" width="200"/><br>
<b>🕹️ Gameplay</b>
</td>
<td align="center" width="33%">
<img src="docs/6.png" alt="Leaderboard" width="200"/><br>
<b>🏆 Leaderboard</b>
</td>
</tr>
<tr>
<td align="center" width="33%">
<img src="docs/3.png" alt="Login" width="200"/><br>
<b>👤 Login Join</b>
</td>
<td align="center" width="33%">
<img src="docs/8.png" alt="Docker" width="200"/><br>
<b>🐳 Docker</b>
</td>
</tr>
<tr>
</tr>
</table>

</details>
</div>

## 📚 Documentación Adicional

### 🗃️ Bases de Datos
- **[DATABASE-QUICK-REFERENCE.md](docs/DATABASE-QUICK-REFERENCE.md)** ⭐ - **EMPEZAR AQUÍ** - Índice completo y referencia rápida
- **[DATABASE-QUERIES.md](docs/DATABASE-QUERIES.md)** - Guía completa de queries MongoDB y Redis
- **[DATABASE-TROUBLESHOOTING.md](docs/DATABASE-TROUBLESHOOTING.md)** - Troubleshooting avanzado y optimización
- **[REDIS-ADVANCED.md](docs/REDIS-ADVANCED.md)** - Uso avanzado de Redis para el juego
- **[GAME-QUERIES-EXAMPLES.md](docs/GAME-QUERIES-EXAMPLES.md)** - Ejemplos prácticos específicos

### 🚀 Guías de Inicio
- **[QUICK-START.md](QUICK-START.md)** - Inicio rápido en 5 minutos
- **[docs/README.md](docs/README.md)** - Índice visual de documentación

### 🛠️ Scripts DevOps
- **[scripts/dev.sh](scripts/dev.sh)** - Script principal de desarrollo
- **[scripts/db-helper.sh](scripts/db-helper.sh)** - Operaciones básicas de BD
- **[scripts/db-troubleshooting.sh](scripts/db-troubleshooting.sh)** - Diagnóstico avanzado

## 🤝 Contribución

1. Fork el proyecto
2. Crea una rama feature (`git checkout -b feature/AmazingFeature`)
3. Commit cambios (`git commit -m "Add AmazingFeature"`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📋 TODO

- [ ] Tests de integración
- [ ] Seguridad
- [ ] Configuraciones Producción
- [ ] CI/CD Pipeline
- [ ] Kubernetes manifests
- [ ] Monitoring con Prometheus
- [ ] SSL/TLS certificates


## 👥 Equipo

- **Roxs** - DevOps Challenge Creator
- **Comunidad** - Contributors

---

## 📄 Licencia

Este proyecto está licenciado bajo MIT License - ver el archivo [LICENSE](LICENSE) para detalles.

## 👨‍💻 Autor

**roxsross** - Instructor DevOps y Cloud

- 🐦 Twitter: [@roxsross](https://twitter.com/roxsross)
- 🔗 LinkedIn: [roxsross](https://linkedin.com/in/roxsross)
- ☕ Ko-fi [roxsross](https://ko-fi.com/roxsross)
- ▶️ Youtube [295devops](https://www.youtube.com/@295devops)
- 📧 Email: roxs@295devops.com

---

⭐ **¡Dale una estrella si este proyecto te ayudó!** ⭐

