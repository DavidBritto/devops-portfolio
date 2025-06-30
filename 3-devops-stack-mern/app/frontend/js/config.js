// Configuración dinámica del frontend
class Config {
    constructor() {
        this.loadConfig();
    }

    loadConfig() {
        // Intentar obtener la configuración del servidor
        this.API_BASE_URL = this.getAPIBaseURL();
        this.HEALTH_CHECK_INTERVAL = 30000; // 30 segundos
        this.RETRY_ATTEMPTS = 3;
        this.RETRY_DELAY = 1000; // 1 segundo
    }

    getAPIBaseURL() {
        // Prioridad:
        // 1. Variable de entorno del contenedor
        // 2. Meta tag en HTML
        // 3. Detección automática basada en el host
        // 4. Fallback a localhost

        // Verificar meta tag
        const metaTag = document.querySelector('meta[name="api-base-url"]');
        if (metaTag && metaTag.content) {
            return metaTag.content;
        }

        // Detección automática basada en el host actual
        const protocol = window.location.protocol;
        const hostname = window.location.hostname;
        
        // Si estamos en producción (no localhost), asumir que la API está en el puerto 3000
        if (hostname !== 'localhost' && hostname !== '127.0.0.1') {
            return `${protocol}//${hostname}:3000`;
        }

        // Fallback para desarrollo local
        return 'http://localhost:3000';
    }

    // Método para actualizar la configuración en tiempo de ejecución
    updateConfig(newConfig) {
        Object.assign(this, newConfig);
    }
}

// Exportar configuración global
window.Config = new Config();