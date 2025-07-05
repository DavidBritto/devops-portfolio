# 📈 Día 20: Implementando Monitoreo y Logging

"Lo que no se mide, no se mejora". Con mi aplicación ya desplegada automáticamente, el desafío de hoy se centró en darle "sentidos": la capacidad de saber si está sana y de contarnos qué ha estado haciendo. Esto se conoce como **observabilidad**.

## Implementaciones del Día

Para darle visibilidad a mi aplicación, implementé tres características clave.

### 1. Health Check (`/health`) 🩺

Añadí un nuevo "endpoint" o ruta a mi aplicación Node.js: `/health`.
* **Propósito:** Su única función es devolver un mensaje JSON simple con el estado `OK` y un timestamp. No hace operaciones complejas.
* **Utilidad:** Sirve como una forma rápida y ligera para que sistemas externos (como nuestro monitor) puedan preguntar: "¿Estás vivo?". Es la prueba de vida fundamental.

### 2. Logging Básico y Centralizado (`docker logs`) 📓

Modifiqué mi `docker-compose.yml` para añadir una configuración de `logging`.
* **Propósito:** Le dije a Docker que gestione los logs de mi contenedor, rotándolos para que no ocupen espacio infinito en el disco.
* **Utilidad:** Toda la salida de la consola de mi aplicación (`console.log`) ahora es capturada por Docker. Para diagnosticar cualquier problema, solo necesito conectarme a la VM y ejecutar `docker logs <nombre_del_contenedor>` para ver el historial completo de peticiones y errores.

### 3. Monitoreo Automatizado (Workflow de GitHub Actions) 🛰️

Creé un nuevo workflow (`monitoreo.yml`) para actuar como un sistema de alerta proactivo.
* **Propósito:** Este workflow se ejecuta automáticamente cada 15 minutos (`cron: '*/15 * * * *'`).
* **Lógica:** Su única tarea es hacer un `curl` al endpoint `/health` de mi aplicación. Si la petición falla (porque la app está caída o devuelve un error), el workflow falla y me podría notificar.
* **Implementación Clave:** Tuve que configurarlo para que corriera en mi runner `self-hosted`, ya que es el único que está en la misma red privada (`192.168.56.x`) y puede "ver" la aplicación. Un runner de GitHub no podría acceder a ella.

## 🧠 Revisión Rápida del Día

* **¿Qué es un health check?**
    * ✔️ Es un endpoint específico en una aplicación que sistemas de monitoreo pueden consultar para verificar de forma rápida y simple si la aplicación está corriendo y es funcional a un nivel básico.

* **¿Cómo se revisan los logs en Docker?**
    * ✔️ Se utiliza el comando `docker logs <ID_o_nombre_del_contenedor>`. Este comando muestra la salida estándar (lo que la aplicación imprimiría en la consola) del proceso principal que corre dentro del contenedor.

* **¿Podés hacer monitoreo desde GitHub Actions?**
    * ✔️ Sí. Se puede crear un workflow con un disparador de tiempo (`schedule` con una expresión `cron`) que ejecute periódicamente un script para verificar la salud de un endpoint. Si el endpoint falla, el workflow falla, lo que puede a su vez disparar notificaciones.

## Conclusión

Si el Día 19 fue sobre desplegar, el Día 20 fue sobre **mantener**. Sin logging y monitoreo, una aplicación en producción es una caja negra. Ahora tengo las herramientas para saber si mi aplicación está sana y, si no lo está, tengo el historial clínico (`logs`) para diagnosticar por qué.
