🚀 Día 13: Orquestando con Docker Compose
Hoy dimos el salto de gestionar contenedores individuales a orquestar aplicaciones completas y complejas con una sola herramienta y un solo comando: Docker Compose.

🧠 Conceptos Clave
Docker Compose: Es la herramienta nativa de Docker para definir y ejecutar aplicaciones multi-contenedor. Reemplaza la necesidad de ejecutar múltiples comandos docker run con configuraciones de red y volúmenes complejas.

docker-compose.yml: Es el archivo de configuración central donde se describe toda la "sinfonía". Se define cada servicio, cómo se construye, qué puertos abre, a qué redes se conecta y de qué otros servicios depende.

Servicios: Cada componente de nuestra aplicación (frontend, backend, base de datos, etc.) se define como un service dentro del archivo docker-compose.yml.

Comando Unificado: El nuevo estándar es docker compose (sin el guion), que viene integrado directamente en el motor de Docker.

🛠️ Anatomía de un docker-compose.yml Profesional
Analizamos un archivo docker-compose.yml completo, entendiendo sus propiedades principales:

services: La sección principal que contiene la definición de cada contenedor.

build: ./ruta: Le dice a Compose que construya una imagen desde un Dockerfile local.

image: 'nombre:tag': Le dice a Compose que use una imagen pre-construida de Docker Hub.

ports: ["8080:80"]: Mapea el puerto del host (izquierda) al puerto del contenedor (derecha).

environment:: Define las variables de entorno para un servicio.

volumes: ["datos:/data"]: Monta un volumen para persistir datos.

networks: ["mi-red"]: Conecta el servicio a una red personalizada.

depends_on:: Controla el orden de inicio de los servicios.

healthcheck:: Una forma avanzada de verificar que un servicio esté no solo iniciado, sino "sano" y listo para recibir conexiones.

📝 Tareas Prácticas Realizadas
Análisis del Stack de WordPress:

Se estudió un docker-compose.yml completo que desplegaba un stack de WordPress con una base de datos MariaDB y una interfaz phpMyAdmin.

Este ejemplo práctico sirvió para ver cómo interactúan todos los conceptos (redes, volúmenes, variables de entorno, healthchecks) en un caso de uso real.

Práctica con Comandos de docker compose:

docker compose up --build -d: El comando principal para construir y levantar todo en segundo plano.

docker compose ps: Para ver el estado de los servicios.

docker compose logs -f <servicio>: Para ver los logs de un servicio específico en tiempo real.

docker compose down --volumes: Para detener y eliminar todos los recursos (contenedores, redes y volúmenes).

docker compose exec <servicio> <comando>: Para ejecutar un comando dentro de un contenedor en ejecución.

Desafío (Node.js + MongoDB):

Se implementó una aplicación simple de Node.js con una base de datos MongoDB usando docker-compose.yml.

Se configuró el servicio backend para que usara depends_on con la condición service_healthy del servicio db.

Se usó un volumen para asegurar la persistencia de los datos en MongoDB.

Resultado: Se demostró la capacidad de levantar una aplicación completa de dos capas, conectada y con datos persistentes, con un solo comando.

Este día fue el puente entre gestionar contenedores individuales y orquestar aplicaciones completas, preparándonos para el desafío final.