🚀 Día 10: Gestión y Administración de Contenedores
Hoy profundizamos en el control del ciclo de vida de los contenedores y en cómo interactuar con ellos de formas más avanzadas. El objetivo es pasar de solo "ejecutar" a "administrar" contenedores de forma efectiva.

🧠 Conceptos Clave
Ciclo de Vida del Contenedor: Un contenedor no solo está "encendido" o "apagado". Puede ser creado, iniciado, pausado, reiniciado, detenido y eliminado (created, running, paused, exited).

Variables de Entorno (-e): Es la forma estándar de pasar configuraciones a una aplicación dentro de un contenedor sin modificar su código. Permite que la misma imagen se comporte de manera diferente según el entorno (desarrollo, producción).

Inspección y Monitoreo: Herramientas como docker logs, docker top y docker inspect nos dan visibilidad completa sobre lo que ocurre dentro de un contenedor.

🛠️ Tareas Prácticas Realizadas
Logs de Contenedores: Se aprendió a ver la salida de un contenedor en segundo plano.

# Ver logs pasados
docker logs <nombre_contenedor>
# Ver logs en tiempo real
docker logs -f <nombre_contenedor>

Control del Ciclo de Vida: Se practicó el control total sobre un contenedor en ejecución.

docker start/stop: Para iniciar y detener.

docker restart: Para reiniciar.

docker pause/unpause: Para suspender y reanudar todos los procesos dentro del contenedor.

Ejecución de Comandos (exec): Se exploró cómo ejecutar comandos dentro de un contenedor que ya está en marcha.

# Ejecutar un comando y salir
docker exec <nombre_contenedor> ls -l /tmp
# Obtener una shell interactiva dentro del contenedor
docker exec -it <nombre_contenedor> bash

Copia de Archivos (cp): Se practicó la transferencia de archivos entre el host y el contenedor en ambas direcciones.

# De host a contenedor
docker cp archivo_local.txt mi_contenedor:/ruta/en/contenedor
# De contenedor a host
docker cp mi_contenedor:/ruta/en/contenedor/archivo.txt .

Variables de Entorno:

Se ejecutó un contenedor alpine pasándole variables de entorno y se verificó que estas existían dentro del mismo.

docker run --rm -e APP_ENV=development -e APP_VERSION=1.0.0 alpine sh -c 'echo Entorno: $APP_ENV, Versión: $APP_VERSION'

Se levantó un contenedor de MariaDB, cuya inicialización depende críticamente de variables de entorno para establecer la contraseña de root.

docker run -d --name some-mariadb -p 3306:3306 -e MARIADB_ROOT_PASSWORD=my-secret-pw mariadb

Este día fue crucial para obtener las habilidades necesarias para administrar y depurar aplicaciones en contenedores, una tarea diaria en cualquier rol de DevOps.