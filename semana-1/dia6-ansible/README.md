# Día 6: Explorando las Capas de la Red y Herramientas de Diagnóstico

Hoy el desafío me sumergió en el mundo de las redes, un pilar fundamental para cualquier rol en DevOps. La jornada consistió en dejar de solo *usar* la red para empezar a *entender* cómo funciona por debajo, desde los modelos teóricos que la rigen hasta las herramientas prácticas que usamos para diagnosticarla en el día a día.

## Fundamentos Teóricos: Modelo OSI y TCP/IP

Antes de ejecutar comandos, dediqué tiempo a entender los principios.
* **Modelo OSI:** Comprendí que es un mapa conceptual de 7 capas que estandariza la forma en que pensamos sobre la comunicación de redes. Es la teoría universal.
* **Modelo TCP/IP:** Aprendí que este es el modelo práctico de 4 capas que realmente utiliza internet. Es una implementación más simple y directa del modelo OSI.

La clave fue entender que cada herramienta que usamos opera en una o más de estas capas, desde los cables hasta la aplicación.

## Pruebas Prácticas con Herramientas de Red

Puse en práctica los conceptos teóricos con las siguientes herramientas de línea de comandos en mi terminal de Ubuntu.

### 1. Verificando Conectividad y Latencia con `ping`
Usé `ping -c 4 google.com` para enviar 4 paquetes ICMP y confirmar que tengo conectividad con el exterior. Analicé el tiempo de respuesta (latencia) de cada paquete, una métrica fundamental para el rendimiento.

### 2. Interactuando con Servicios Web con `curl` y `wget`
* Con `curl -I https://www.google.com`, pude inspeccionar las cabeceras de respuesta HTTP del servidor sin necesidad de descargar la página completa, ideal para diagnósticos rápidos de APIs o sitios web.
* Con `wget`, practiqué la descarga de archivos directamente desde la terminal, una tarea común al automatizar la obtención de instaladores o artefactos.

### 3. Inspeccionando Puertos Locales con `ss`
Ejecuté `sudo ss -tuln` para obtener un mapa de todos los puertos TCP y UDP que están "escuchando" en mi sistema. Este comando es crucial para verificar qué servicios (como servidores web, bases de datos, etc.) están corriendo y esperando conexiones. Identifiqué el puerto `:22` de mi servicio SSH.

### 4. Consultando el DNS con `dig`
Para entender la resolución de nombres, usé `dig 90daysdevops.295devops.com`. En la sección de respuesta, pude ver claramente cómo el nombre de dominio se traduce a su correspondiente dirección IP, el primer paso para que cualquier comunicación en internet pueda empezar.

## Conclusión del Día

Este día fue clave para desmitificar la "magia" de internet. Ahora cuento con un set de herramientas de diagnóstico fundamentales. Saber usar `ping`, `curl`, `ss` y `dig` me da la confianza para empezar a diagnosticar por qué un servicio no responde o por qué un contenedor no puede conectarse a una base de datos, habilidades indispensables en DevOps.