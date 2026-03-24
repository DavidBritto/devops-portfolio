# Despliegue de Aplicación de Votación con Vagrant y Ansible

Este proyecto documenta el despliegue de una aplicación de votación distribuida ("Roxs Voting App") como solución al desafío final de la Semana 1 del programa **#90DaysOfDevOpsWithRoxs**.

El objetivo principal fue orquestar una arquitectura de microservicios (Python, Node.js, Redis, PostgreSQL) en un entorno virtualizado, utilizando **Vagrant** para la creación de la infraestructura y **Ansible** para la gestión de la configuración.



---
## 🛠️ Stack Tecnológico
* **Orquestación de Entorno:** Vagrant
* **Gestión de Configuración:** Ansible
* **Aplicaciones:** Python (Flask), Node.js
* **Bases de Datos:** PostgreSQL, Redis
* **Scripting:** Bash

---
## 🚀 Cómo Ejecutar el Proyecto

#### **Prerrequisitos:**
* Vagrant
* VirtualBox
* Ansible

#### **Pasos:**
1.  **Clonar el repositorio:**
    ```bash
    git clone [https://github.com/DavidBritto/devops-portfolio.git](https://github.com/DavidBritto/devops-portfolio.git)
    ```
2.  **Levantar la Máquina Virtual y Provisionar:**
    Navega a la carpeta de este proyecto y ejecuta:
    ```bash
    vagrant up
    ```
    Este comando creará la VM (Ubuntu 22.04) con una IP `192.168.56.10`, redireccionará los puertos necesarios y ejecutará el playbook de Ansible para instalar todas las dependencias de software.

3.  **Configurar la Base de Datos (Paso Manual):**
    Debido a las particularidades de los permisos en la VM, la configuración inicial de PostgreSQL se realiza manualmente.
    ```bash
    vagrant ssh
    sudo -i -u postgres psql
    ```
    Dentro de la consola de `psql`, ejecuta:
    ```sql
    ALTER USER postgres WITH PASSWORD 'postgres';
    CREATE DATABASE votes;
    \q
    ```
    Sal de la sesión de `postgres` y de la VM.

4.  **Iniciar los Servicios de la Aplicación:**
    Se ha creado un script de arranque para gestionar todos los servicios. Conéctate a la VM y ejecútalo:
    ```bash
    vagrant ssh
    cd /vagrant/roxs-voting-app/  # O la ruta correcta a la app
    chmod +x start_all.sh
    ./start_all.sh
    ```
5.  **Acceder a la Aplicación:**
    ¡Listo! Abre tu navegador y visita:
    * **Página de Votación:** `http://localhost:8080`
    * **Página de Resultados:** `http://localhost:3000`

---
## 🧠 Desafíos Técnicos y Aprendizajes Clave

Este proyecto presentó varios desafíos del mundo real, cuya resolución fue clave para el aprendizaje:

* **Gestión de Privilegios en Ansible:** Se diagnosticó un problema de escalada de privilegios (`become_user`) con el módulo de PostgreSQL en una VM mínima. Como solución pragmática, se optó por automatizar la instalación de la base de datos con Ansible y documentar la configuración inicial como un paso manual controlado.

* **Adaptación de Aplicaciones a Entornos:** Se refactorizó el código fuente de los servicios para que las direcciones de la base de datos y Redis no estuvieran "hardcodeadas", adaptándolas para funcionar en un entorno de VM en lugar de un entorno de contenedores.

* **Diagnóstico de Conflictos de Red:** Se identificó y resolvió un conflicto de puertos (`EADDRINUSE`) entre dos de los servicios Node.js, modificando la configuración de uno de ellos para asegurar que cada servicio escuchara en un puerto único.

* **Automatización del Arranque de Servicios:** Se desarrolló un script de arranque en Bash (`start_all.sh`) para orquestar el inicio de los 5 microservicios en el orden correcto y en segundo plano, asegurando que el stack completo se inicie con un solo comando.

---
#### Contenido del Script `start_all.sh`
<details>
  <summary>Haz clic para ver el código</summary>
  
  ```bash
  #!/bin/bash

  # --- Limpieza y Arranque de Servicios ---

  echo "--- Limpiando procesos anteriores ---"
  pkill -f 'python3 app.py' || true
  pkill -f 'node main.js' || true

  echo "--- Iniciando servicios de la Voting App ---"

  # VOTE APP
  echo "▶️  Iniciando Vote App..."
  cd /vagrant/roxs-voting-app/vote
  DATABASE_HOST=localhost DATABASE_USER=postgres DATABASE_PASSWORD=postgres python3 app.py &

  # WORKER APP
  echo "▶️  Iniciando Worker App..."
  cd /vagrant/roxs-voting-app/worker
  REDIS_HOST=localhost DATABASE_HOST=localhost node main.js &

  # RESULT APP
  echo "▶️  Iniciando Result App..."
  cd /vagrant/roxs-voting-app/result
  REDIS_HOST=localhost DATABASE_HOST=localhost node main.js &

  echo "✅ ¡Servicios lanzados!"