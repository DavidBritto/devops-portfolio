🚀 Desafío Final Semana 1 - Roxs Voting App
Este repositorio documenta la solución al desafío final de la primera semana del programa #90DaysOfDevOps. El objetivo fue levantar y orquestar una aplicación de votación distribuida (Roxs Voting App) utilizando un stack de herramientas de DevOps como Vagrant y Ansible.

Repositorio Base Original: roxsross/roxs-devops-project90

🎯 Arquitectura de la Aplicación
La aplicación se compone de varios microservicios que trabajan en conjunto:

Vote (Python/Flask): Interfaz web para que los usuarios emitan votos.

Redis: Base de datos en memoria que actúa como una cola temporal para los votos.

Worker (Node.js): Proceso de fondo que toma los votos de Redis y los guarda de forma permanente en PostgreSQL.

PostgreSQL: Base de datos relacional que almacena el conteo final de los votos.

Result (Node.js): Interfaz web que lee los datos de PostgreSQL y muestra los resultados en tiempo real.

🧗 Desafíos Afrontados y Lecciones Aprendidas
El camino para levantar esta aplicación fue un ejercicio de depuración intensivo y realista, demostrando que la teoría a menudo choca con la práctica. Los principales obstáculos superados fueron:

Errores de Permisos en Ansible (become_user): Los intentos iniciales de configurar PostgreSQL con los módulos nativos de Ansible fallaron repetidamente con errores de chmod: invalid mode. Esto se debió a una incompatibilidad entre la forma en que Ansible intenta escalar privilegios de forma segura (usando ACLs) y la configuración mínima de la máquina virtual bento/ubuntu-24.04. Se intentaron varias soluciones, como cambiar el become_method a su, lo que a su vez generó errores de timeout al esperar una contraseña.

Configuraciones "Hardcodeadas" vs. Entorno: Se descubrió que las aplicaciones estaban diseñadas para un entorno de contenedores, buscando nombres de host como database y redis. La solución fue modificar el código fuente y usar variables de entorno para apuntar a localhost, adaptando la aplicación a nuestro entorno de máquina virtual única.

Conflicto de Puertos (EADDRINUSE): El servicio Worker y el servicio Result intentaban usar el mismo puerto (3000). La solución fue editar el código del Worker para que utilizara un puerto diferente para su servidor de métricas, resolviendo el conflicto.

Entorno Interactivo vs. No Interactivo: Se demostró que los scripts de inicio fallaban cuando se ejecutaban remotamente a través de vagrant ssh -c "..." (una sesión no interactiva), pero funcionaban perfectamente cuando se ejecutaban manualmente dentro de una sesión vagrant ssh (interactiva). Esto nos llevó a la solución final de crear un script de arranque que se ejecuta directamente dentro de la VM.

🛠️ Paso a Paso de la Solución Final
Este es el proceso consolidado para levantar el entorno desde cero.

Clonar y Preparar el Entorno:

Clonar el repositorio base.

Crear la estructura de carpetas roxs-devops-project90/roxs-voting-app/.

Crear un Vagrantfile en la raíz para definir la VM, la red privada (192.168.56.10) y la redirección de puertos (8080 -> 5000, 3000 -> 3000).

Automatizar Dependencias con Ansible:

Crear un playbook.yml que se encarga de instalar todo el software base: redis, postgresql, python3, pip, nodejs y npm.

El playbook también instala las dependencias de cada aplicación usando los módulos pip y npm.

Importante: La configuración de la base de datos PostgreSQL se omite intencionadamente del playbook debido a los errores de permisos.

Ejecutar la Automatización Parcial:

Levantar la máquina virtual y ejecutar el playbook con vagrant up. Este proceso termina sin errores.

Configuración Manual de PostgreSQL:

Conectarse a la VM con vagrant ssh.

Convertirse en el superusuario de la base de datos con sudo -i -u postgres.

Entrar a la consola de psql.

Ejecutar los comandos SQL necesarios para crear la base de datos y configurar el usuario:

ALTER USER postgres WITH PASSWORD 'postgres';
CREATE DATABASE votes;

Ajustes al Código Fuente:

Servicio Vote (vote/app.py): Se modificó la última línea para que la aplicación corra en el puerto 5000 en lugar del privilegiado 80.

Servicio Worker (worker/main.js): Se modificó la variable port de 3000 a 3001 para resolver el conflicto de puertos.

✨ Automatización Final: Script de Arranque
Para simplificar el inicio de todos los servicios, se creó un script start_all.sh directamente dentro de la máquina virtual (en la carpeta /vagrant/).

start_all.sh
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

Ejecución Final
Conectarse a la VM: vagrant ssh

Navegar a la raíz: cd /vagrant/

Dar permisos al script: chmod +x start_all.sh

Ejecutar el script: ./start_all.sh

✅ Resultado
Una vez ejecutado el script, la aplicación es accesible desde el navegador del anfitrión:

Página de Votación: http://localhost:8080

Página de Resultados: http://localhost:3000