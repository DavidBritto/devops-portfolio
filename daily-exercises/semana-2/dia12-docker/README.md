🚀 Día 12: Construyendo Mis Propias Imágenes con Dockerfile
Hoy dejamos de usar imágenes pre-hechas de Docker Hub y aprendimos a construir las nuestras. Esta es la habilidad central para "dockerizar" cualquier aplicación personalizada.

🧠 Conceptos Clave
Dockerfile: Un archivo de texto que actúa como un manual de instrucciones paso a paso para que Docker ensamble una imagen. Cada instrucción en el Dockerfile crea una "capa" en la imagen.

Contexto de Build (.): Al ejecutar docker build, le pasamos un "contexto", que usualmente es el directorio actual (.). Esto le permite a Docker acceder a los archivos de ese directorio para copiarlos dentro de la imagen.

Capas y Caché: Docker construye las imágenes en capas. Si no has modificado las primeras instrucciones de tu Dockerfile (como la instalación de dependencias), Docker reutilizará las capas cacheadas de builds anteriores, haciendo el proceso mucho más rápido.

.dockerignore: Similar a un .gitignore. Es un archivo que le dice a Docker qué archivos y carpetas del contexto debe ignorar al construir la imagen (como la carpeta .git o node_modules del host).

🛠️ Instrucciones Esenciales del Dockerfile
Instrucción

Propósito

FROM

Define la imagen base sobre la que se construye.

WORKDIR

Establece el directorio de trabajo dentro del contenedor.

COPY

Copia archivos del host al contenedor.

RUN

Ejecuta comandos para construir la imagen (ej: npm install).

CMD

Define el comando por defecto al iniciar el contenedor.

EXPOSE

Documenta el puerto que la aplicación usa.

ENV

Define variables de entorno.

📝 Tareas Prácticas Realizadas
Imagen Nginx Personalizada:

Se creó un Dockerfile simple que partía de la imagen nginx:alpine.

Usaba la instrucción COPY para reemplazar el index.html por defecto con uno personalizado.

Se construyó la imagen con docker build -t simple-nginx:v1 ..

Se ejecutó un contenedor a partir de esta nueva imagen y se verificó en el navegador que se mostraba la página personalizada.

Imagen de una Aplicación Node.js:

Se creó una aplicación "Hola Mundo" con Node.js y Express.

Se escribió un Dockerfile que:

Partía de una imagen node:18-alpine.

Establecía el WORKDIR.

Copiaba package.json y ejecutaba RUN npm install para instalar dependencias (aprovechando el caché).

Copiaba el resto del código fuente.

Exponía el puerto 3000.

Usaba CMD ["npm", "start"] para iniciar la aplicación.

Se construyó y ejecutó con éxito, demostrando el proceso completo de dockerizar una aplicación desde cero.

Este día fue fundamental para adquirir la autonomía necesaria para empaquetar cualquier proyecto, sin importar su lenguaje o framework, en una imagen de Docker portable y lista para desplegar.