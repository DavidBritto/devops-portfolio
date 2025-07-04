# 🚀 Día 19: Despliegue Automatizado con Docker Compose

Hoy el desafío subió de nivel de forma masiva. Pasamos de manejar contenedores individuales a orquestar una **aplicación completa** con **Docker Compose**, y automatizamos su despliegue de extremo a extremo con nuestro runner self-hosted.

## El Proceso: De Código a Contenedores Orquestados

El objetivo era crear un pipeline que, tras un `git push`, desplegara una aplicación web de forma automática.

1.  **Aplicación de Ejemplo 📦:** Creé una aplicación súper simple con Node.js y su respectivo `Dockerfile` para poder empaquetarla en una imagen de Docker.

2.  **La Receta de Orquestación 📜:** Creé un archivo `docker-compose.yml`. Aquí es donde definí los "servicios" que componen mi aplicación (por ahora, solo el servicio `app`). Este archivo es el cerebro que le dice a Docker cómo deben correr y conectarse los contenedores.

3.  **El Workflow de Despliegue 🤖:** Diseñé un workflow de GitHub Actions (`deploy-compose.yml`) con los siguientes pasos:
    * Se dispara con un `push` a la rama `main`.
    * Se asigna a mi runner `self-hosted`.
    * Clona el código más reciente.
    * **Instala `docker-compose`** (solucionando el problema del día anterior).
    * Ejecuta `docker-compose down` para detener cualquier versión antigua.
    * Ejecuta `docker-compose up -d --build` para construir la nueva imagen y levantar el contenedor en segundo plano.
    * Finalmente, hace un `curl` a la aplicación para verificar que respondió correctamente.

## La Ejecución: Observando la Magia

El momento de la verdad fue hacer `git push` y ver la pestaña "Actions" en GitHub. Pude seguir en tiempo real cómo mi runner personal recogía el trabajo, instalaba sus propias dependencias y ejecutaba los comandos de Docker Compose, levantando la aplicación sin que yo tuviera que intervenir en absoluto.

## 🧠 Revisión Rápida del Día

* **¿Qué es Docker Compose?**
    * ✔️ Es una herramienta para definir y correr aplicaciones Docker multi-contenedor. Usa un archivo YAML para configurar los servicios, redes y volúmenes de la aplicación, permitiendo levantarlos y conectarlos todos con un solo comando.

* **¿Qué hace el workflow?**
    * ✔️ Automatiza el proceso de despliegue. Detecta un cambio en el código, se conecta a mi runner, detiene la versión anterior de la aplicación, construye la nueva y la levanta, finalizando con una prueba de que está funcionando.

* **¿Cómo se levanta la app en staging?**
    * ✔️ Se usaría un archivo de compose diferente (ej: `docker-compose.staging.yml`) y se lo llamaría en el workflow con `docker-compose -f docker-compose.staging.yml up -d`. El workflow podría tener una lógica condicional para usar un archivo u otro dependiendo de la rama (`develop` para staging, `main` para producción).

## Conclusión

Hoy se conectaron todos los puntos. Vi en la práctica cómo Git, GitHub Actions, un runner propio y Docker Compose trabajan en perfecta armonía para crear un pipeline de CI/CD real. La capacidad de describir una aplicación completa en un archivo y desplegarla con un `push` es, sin duda, uno de los superpoderes de DevOps.
