🚀 Día 9: Mi Primer Contenedor Docker
Hoy damos el primer paso en el mundo de la contenerización, una de las tecnologías más transformadoras en DevOps. El objetivo es entender qué es un contenedor y ejecutar los primeros ejemplos prácticos.

🧠 Conceptos Clave
Docker: Una plataforma que nos permite empaquetar una aplicación con TODAS sus dependencias (código, librerías, configuraciones) en una unidad aislada y portable llamada contenedor.

Imagen vs. Contenedor: Una imagen es una plantilla inmutable, como un plano de construcción. Un contenedor es una instancia en ejecución de esa imagen, es decir, el edificio construido a partir del plano.

Ventajas: Portabilidad ("funciona en mi máquina" se acabó), aislamiento entre aplicaciones y eficiencia en el uso de recursos.

🛠️ Tareas Prácticas Realizadas
Verificación de Docker:

docker --version

Contenedor hello-world: El rito de iniciación.

Se descargó la imagen con docker pull hello-world.

Se ejecutó el contenedor con docker run hello-world, validando que la instalación funciona correctamente.

Servidor Web con NGINX: Un caso de uso real.

Se ejecutó un contenedor Nginx en segundo plano (-d) y se mapeó el puerto 80 del contenedor al 8080 de la máquina local (-p 8080:80).

docker run -d -p 8080:80 --name web-nginx nginx

Resultado: Se accedió a la página de bienvenida de NGINX desde el navegador en http://localhost:8080.

Gestión del Ciclo de Vida: Se practicaron los comandos esenciales para administrar contenedores:

docker ps y docker ps -a: Para ver contenedores activos y todos los contenedores.

docker stop web-nginx: Para detener un contenedor.

docker rm web-nginx: Para eliminar un contenedor detenido.

Contenedor Interactivo: Se exploró el interior de un contenedor Ubuntu.

docker run -it --name explorador ubuntu bash

Se utilizaron comandos como docker start, docker attach y docker exec para interactuar con él.

Desafío Extra - Sitio Web Personalizado:

Se clonó un repositorio con una web estática.

Se usó docker cp para copiar los archivos del sitio dentro del contenedor Nginx en ejecución, reemplazando la página por defecto.

git clone -b devops-simple-web https://github.com/roxsross/devops-static-web.git
docker cp devops-static-web/bootcamp-web/. bootcamp-web:/usr/share/nginx/html/

Resultado: Se sirvió un sitio web personalizado desde un contenedor Docker.

Este día sentó las bases fundamentales para entender cómo Docker empaqueta y ejecuta aplicaciones de forma aislada.