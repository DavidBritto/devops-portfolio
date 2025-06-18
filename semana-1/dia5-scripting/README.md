# Día 5: Automatizando la Configuración de un Servidor Web con un Script de Shell

Hoy di un paso más allá en la automatización. En lugar de usar una herramienta de virtualización como Vagrant, apliqué los conceptos directamente en mi sistema nativo de Ubuntu. El desafío consistió en encapsular toda la lógica para configurar un servidor web en un único y potente **script de shell (`.sh`)**.

El objetivo: crear un script que, al ejecutarse, transforme mi sistema en un servidor web funcional que sirve una página clonada directamente desde GitHub.

## El Desafío: Un Servidor Configurado por Script

Mi script `setup_webserver.sh` fue diseñado para realizar las siguientes tareas de forma desatendida:
1.  Asegurarse de que el sistema esté actualizado.
2.  Instalar los paquetes necesarios: **Nginx** (servidor web) y **Git** (control de versiones).
3.  Limpiar el directorio por defecto de Nginx para asegurar una instalación limpia.
4.  Clonar un sitio web de ejemplo desde un repositorio de GitHub al directorio web de Nginx.

## La Solución: Mi Script `setup_webserver.sh`

Este es el script que creé para lograr la automatización. Cada comando está pensado para ejecutarse secuencialmente y los `echo` sirven para informar el progreso en la terminal.

```bash
#!/bin/bash

# Este script configura un servidor Nginx y despliega un sitio desde Git.
# Debe ejecutarse con privilegios de sudo para instalar paquetes y escribir en /var/www/html.

set -e # Termina el script inmediatamente si un comando falla.

# --- Variables de Configuración ---
WEB_DIR="/var/www/html"
REPO_URL="[https://github.com/StartBootstrap/startbootstrap-resume.git](https://github.com/StartBootstrap/startbootstrap-resume.git)"

# --- Inicio del Provisionamiento ---
echo "--- [Paso 1/4] Actualizando lista de paquetes... ---"
apt-get update -y

echo "--- [Paso 2/4] Instalando Nginx y Git... ---"
apt-get install -y nginx git

echo "--- [Paso 3/4] Limpiando el directorio web por defecto de Nginx... ---"
# Borramos todo lo que haya para hacer una instalación limpia.
rm -rf ${WEB_DIR}/*

echo "--- [Paso 4/4] Clonando el repositorio del sitio web en ${WEB_DIR}... ---"
# Clonamos el proyecto directamente en el directorio web.
git clone ${REPO_URL} ${WEB_DIR}

echo "------------------------------------------------------"
echo "¡Provisionamiento completado!"
echo "Puedes acceder al sitio en http://localhost"
echo "------------------------------------------------------"