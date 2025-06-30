class ItemsManager {
    constructor() {
        this.config = window.Config;
        this.baseURL = this.config.API_BASE_URL;
        this.editingId = null;
        this.healthCheckInterval = null;
        this.retryAttempts = this.config.RETRY_ATTEMPTS;
        this.retryDelay = this.config.RETRY_DELAY;
        this.init();
    }

    async init() {
        this.bindEvents();
        await this.checkAPIStatus();
        await this.loadItems();
        this.startHealthMonitoring();
    }

    bindEvents() {
        document.getElementById('itemForm').addEventListener('submit', (e) => this.handleSubmit(e));
        document.getElementById('cancelBtn').addEventListener('click', () => this.cancelEdit());
        document.getElementById('refreshBtn').addEventListener('click', () => this.loadItems());
        
        // Agregar listener para reconexión automática
        window.addEventListener('online', () => this.handleReconnection());
        window.addEventListener('offline', () => this.handleDisconnection());
    }

    async makeRequest(url, options = {}, attempt = 1) {
        try {
            const response = await fetch(url, {
                ...options,
                headers: {
                    'Content-Type': 'application/json',
                    ...options.headers
                }
            });

            if (!response.ok) {
                const errorData = await response.json().catch(() => ({}));
                throw new Error(errorData.detail || `Error ${response.status}: ${response.statusText}`);
            }

            return response;
        } catch (error) {
            if (attempt < this.retryAttempts && this.shouldRetry(error)) {
                console.warn(`Request failed, retrying... (${attempt}/${this.retryAttempts})`);
                await this.delay(this.retryDelay * attempt);
                return this.makeRequest(url, options, attempt + 1);
            }
            throw error;
        }
    }

    shouldRetry(error) {
        // Retry en errores de red o errores del servidor (5xx)
        return error.name === 'TypeError' || 
               (error.message.includes('Error 5')) ||
               error.message.includes('Failed to fetch');
    }

    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    async checkAPIStatus() {
        try {
            const response = await this.makeRequest(`${this.baseURL}/health`);
            const data = await response.json();
            
            const statusElement = document.getElementById('apiStatus');
            statusElement.textContent = `Conectado (v${data.version})`;
            statusElement.className = 'api-status online';
            
            // Mostrar información adicional si está disponible
            if (data.database === 'disconnected') {
                this.showAlert('API conectada pero base de datos desconectada', 'error');
            }
        } catch (error) {
            this.handleAPIError();
        }
    }

    handleAPIError() {
        const statusElement = document.getElementById('apiStatus');
        statusElement.textContent = 'Desconectado';
        statusElement.className = 'api-status offline';
    }

    startHealthMonitoring() {
        // Health check cada 30 segundos
        this.healthCheckInterval = setInterval(() => {
            this.checkAPIStatus();
        }, this.config.HEALTH_CHECK_INTERVAL);
    }

    stopHealthMonitoring() {
        if (this.healthCheckInterval) {
            clearInterval(this.healthCheckInterval);
        }
    }

    handleReconnection() {
        console.log('Connection restored, checking API status...');
        this.checkAPIStatus();
        this.loadItems();
    }

    handleDisconnection() {
        console.log('Connection lost');
        this.handleAPIError();
        this.showAlert('Conexión perdida. Reintentando automáticamente...', 'error');
    }

    async handleSubmit(e) {
        e.preventDefault();
        
        const submitBtn = document.getElementById('submitBtn');
        const originalText = submitBtn.textContent;
        
        try {
            submitBtn.disabled = true;
            submitBtn.textContent = 'Procesando...';
            
            const formData = new FormData(e.target);
            const data = {
                name: formData.get('name').trim(),
                description: formData.get('description').trim()
            };

            // Validación del lado del cliente
            if (!data.name || !data.description) {
                throw new Error('Todos los campos son obligatorios');
            }

            if (this.editingId) {
                await this.updateItem(this.editingId, data);
            } else {
                await this.createItem(data);
            }
            
            this.resetForm();
            await this.loadItems();
        } catch (error) {
            this.showAlert('Error: ' + error.message, 'error');
        } finally {
            submitBtn.disabled = false;
            submitBtn.textContent = originalText;
        }
    }

    async createItem(data) {
        const response = await this.makeRequest(`${this.baseURL}/items`, {
            method: 'POST',
            body: JSON.stringify(data)
        });

        this.showAlert('Item creado exitosamente', 'success');
        return await response.json();
    }

    async updateItem(id, data) {
        const response = await this.makeRequest(`${this.baseURL}/items/${id}`, {
            method: 'PUT',
            body: JSON.stringify(data)
        });

        this.showAlert('Item actualizado exitosamente', 'success');
        return await response.json();
    }

    async deleteItem(id) {
        if (!confirm('¿Estás seguro de que quieres eliminar este item?')) {
            return;
        }

        try {
            await this.makeRequest(`${this.baseURL}/items/${id}`, {
                method: 'DELETE'
            });

            this.showAlert('Item eliminado exitosamente', 'success');
            await this.loadItems();
        } catch (error) {
            this.showAlert('Error al eliminar: ' + error.message, 'error');
        }
    }

    async loadItems() {
        const container = document.getElementById('itemsContainer');
        container.innerHTML = `
            <div class="loading">
                <div class="spinner"></div>
                <p>Cargando items...</p>
            </div>
        `;

        try {
            const response = await this.makeRequest(`${this.baseURL}/items`);
            const items = await response.json();
            this.renderItems(items);
        } catch (error) {
            container.innerHTML = `
                <div class="alert alert-error">
                    <strong>Error al cargar los items:</strong><br>
                    ${error.message}
                    <br><br>
                    <button class="btn btn-secondary" onclick="app.loadItems()">
                        Reintentar
                    </button>
                </div>
            `;
        }
    }

    renderItems(items) {
        const container = document.getElementById('itemsContainer');
        
        if (items.length === 0) {
            container.innerHTML = `
                <div style="text-align: center; padding: 40px; color: #6c757d;">
                    <h3>No hay items disponibles</h3>
                    <p>¡Crea el primer item usando el formulario de arriba!</p>
                </div>
            `;
            return;
        }

        const itemsHTML = items.map(item => `
            <div class="item-card" data-item-id="${item.id}">
                <div class="item-header">
                    <div class="item-id">ID: ${item.id}</div>
                </div>
                <div class="item-name">${this.escapeHtml(item.name)}</div>
                <div class="item-description">${this.escapeHtml(item.description)}</div>
                <div class="item-actions">
                    <button class="btn btn-edit" onclick="app.editItem(${item.id}, '${this.escapeHtml(item.name)}', '${this.escapeHtml(item.description)}')">
                        ✏️ Editar
                    </button>
                    <button class="btn btn-danger" onclick="app.deleteItem(${item.id})">
                        🗑️ Eliminar
                    </button>
                </div>
            </div>
        `).join('');

        container.innerHTML = `
            <div class="items-header">
                <p>Total de items: <strong>${items.length}</strong></p>
            </div>
            <div class="items-grid">${itemsHTML}</div>
        `;
    }

    editItem(id, name, description) {
        this.editingId = id;
        document.getElementById('formTitle').textContent = 'Editar Item';
        document.getElementById('itemId').value = id;
        document.getElementById('itemName').value = name;
        document.getElementById('itemDescription').value = description;
        document.getElementById('submitBtn').textContent = 'Actualizar Item';
        document.getElementById('cancelBtn').style.display = 'inline-block';
        
        // Highlight del item que se está editando
        document.querySelectorAll('.item-card').forEach(card => {
            card.classList.remove('editing');
        });
        document.querySelector(`[data-item-id="${id}"]`)?.classList.add('editing');
        
        // Scroll to form
        document.querySelector('.form-section').scrollIntoView({ behavior: 'smooth' });
    }

    cancelEdit() {
        this.resetForm();
        // Remover highlight
        document.querySelectorAll('.item-card').forEach(card => {
            card.classList.remove('editing');
        });
    }

    resetForm() {
        this.editingId = null;
        document.getElementById('formTitle').textContent = 'Crear Nuevo Item';
        document.getElementById('itemForm').reset();
        document.getElementById('itemId').value = '';
        document.getElementById('submitBtn').textContent = 'Crear Item';
        document.getElementById('cancelBtn').style.display = 'none';
    }

    showAlert(message, type) {
        const container = document.getElementById('alertContainer');
        const alert = document.createElement('div');
        alert.className = `alert alert-${type}`;
        
        const icon = type === 'success' ? '✅' : '❌';
        alert.innerHTML = `
            <span style="margin-right: 10px;">${icon}</span>
            ${message}
        `;
        
        container.innerHTML = '';
        container.appendChild(alert);
        
        // Auto-hide success messages
        if (type === 'success') {
            setTimeout(() => {
                alert.remove();
            }, 3000);
        }
    }

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    // Cleanup al cerrar la página
    destroy() {
        this.stopHealthMonitoring();
    }
}

// Inicializar la aplicación cuando se carga la página
document.addEventListener('DOMContentLoaded', () => {
    window.app = new ItemsManager();
});

// Cleanup al cerrar la página
window.addEventListener('beforeunload', () => {
    if (window.app) {
        window.app.destroy();
    }
});