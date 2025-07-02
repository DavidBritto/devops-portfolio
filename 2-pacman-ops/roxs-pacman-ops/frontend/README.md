# 🎮 Pacman DevOps Challenge - Frontend

![](https://media.licdn.com/dms/image/v2/D4D16AQF4ND-cC_uxZg/profile-displaybackgroundimage-shrink_350_1400/profile-displaybackgroundimage-shrink_350_1400/0/1731367727725?e=1753920000&v=beta&t=80SZ4IOx4V_VDcCBli7aFjYuMhzMos9SRFq8GnV8zc4)

> **Proyecto educativo de DevOps** creado por **roxsross** para aprender conceptos fundamentales de desarrollo, contenedores, orquestación y monitoreo.

Frontend React del juego Pac-Man para el desafío DevOps.

## 🏗️ Estructura

```
frontend/
├── src/                 # Código fuente React
│   ├── components/      # Componentes de React
│   ├── App.js          # Componente principal
│   └── index.js        # Punto de entrada
├── public/             # Archivos estáticos
│   ├── index.html      # Template HTML
│   ├── audio/          # Efectos de sonido
│   └── images/         # Sprites del juego
├── images/             # Imágenes para documentación
├── package.json        # Dependencias y scripts
├── Dockerfile          # Imagen Docker para producción
└── .dockerignore       # Archivos excluidos del build Docker
```

## 🚀 Desarrollo Local

```bash
# Instalar dependencias
npm install

# Ejecutar en modo desarrollo
npm start

# Construir para producción
npm run build

# Ejecutar tests
npm test
```

## 🐳 Docker

```bash
# Construir imagen
docker build -t pacman-frontend .

# Ejecutar contenedor
docker run -p 8000:80 pacman-frontend
```

## 🔧 Variables de Entorno

- `REACT_APP_BACKEND_URL`: URL del backend API
- `REACT_APP_URL`: URL base del frontend
- `NODE_ENV`: Entorno de ejecución

## 🎨 Características

- ⚡ React 18 con Hooks
- 🎮 Canvas-based game engine
- 🔊 Web Audio API para sonidos
- 📱 Diseño responsivo
- 🏆 Sistema de puntuaciones
- ⏱️ Captura de tiempo de juego
- 🎯 Análisis de resultados detallado

## 📊 Componentes Principales

- `Game`: Motor del juego y lógica principal
- `GameResults`: Pantalla de resultados y estadísticas
- `Auth`: Autenticación de usuarios
- `Main`: Pantalla principal y menú
- `Footer`: Información del desafío DevOps
