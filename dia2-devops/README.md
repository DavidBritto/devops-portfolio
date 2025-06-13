# 🚀 Tarea Opcional del Día 2: #90DaysOfDevOps

> *Este resumen fue escrito puramente en `nano` y subido a este repositorio con `git` desde WSL2.*

---

## 🛠️ 1. Exploración Básica de Comandos

Estos son los primeros comandos ejecutados en la terminal y su función:

* **`whoami`**: Muestra el nombre del usuario con el que estoy actualmente logueado en la terminal.
* **`pwd`**: Imprime la ruta completa del directorio de trabajo actual (Print Working Directory).
* **`ls -lah`**: Genera una lista detallada (`-l`) de **todos** los archivos y directorios (`-a`), incluyendo los ocultos, con los tamaños en un formato legible por humanos (`-h`).
* **`df -hT`**: Reporta el espacio libre y usado de los sistemas de archivos, mostrando el tipo (`-T`) y los tamaños en formato legible (`-h`).
* **`uptime`**: Muestra cuánto tiempo lleva encendido el sistema, cuántos usuarios están conectados y la carga promedio del procesador.

---

## 📂 2. Navegación por Directorios Clave

Secuencia de comandos para navegar por directorios importantes del sistema de archivos de Linux:

```bash
# Ir al directorio raíz del sistema
cd /

# Listar el contenido del directorio raíz
ls

# Ir al directorio /etc (archivos de configuración) y listar su contenido
cd /etc && ls

# Ir al directorio /home (carpetas de usuarios) y listar su contenido
cd /home && ls
```
---

## 📂 🧠 5. Reto de Comprensión: Permisos
Pregunta: ¿Qué hace este comando?


```bash

chmod u=rwx,g=rx,o= hola.txt
```

Mi Explicación:

El comando establece que para el archivo hola.txt:

El propietario **`(u)`** tiene control total (leer, escribir, ejecutar).
El grupo **`(g)`** puede leerlo y ejecutarlo, pero no modificarlo.
Todos los demás **`(o)`** no tienen ningún tipo de acceso.

