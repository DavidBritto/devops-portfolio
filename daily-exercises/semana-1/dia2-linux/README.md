# Día 2: Comandos, Sistema de Archivos, Usuarios y Permisos en Linux

Hoy arrancamos con uno de los superpoderes más importantes de DevOps: la terminal.

### 💻 Opciones para usar una terminal:
* **Linux/macOS:** Ya tienes una terminal incorporada.
* **Windows:** Puedes usar WSL (Subsistema de Linux para Windows), Git Bash, o PowerShell/CMD para lo más básico.
* **100% online:** Killercoda (escenarios interactivos) o JS Linux (simulador).

> ⚠️ **Recomendación Roxs:** Si vas en serio con DevOps, instalá una terminal real en tu máquina. ¡Te vas a sentir más poderoso y libre! 💪🐧

---

## 🐧 Parte 1: Comandos Básicos de Linux que TODO DevOps debe dominar

### 🔥 Comandos TOP para DevOps

1.  **`alias` – Atajos para comandos**
    Crea `alias` para ahorrar tiempo. Guárdalos en `~/.bashrc` o `~/.zshrc` para que sean permanentes.
    ```bash
    alias ll='ls -lah --color=auto'  # Lista archivos con detalles
    alias ..='cd ..'                 # Sube un directorio
    alias gs='git status'            # Ver estado de Git
    ```

2.  **`whoami` – ¿Quién soy?**
    Muestra el usuario actual. Útil en scripts para verificar permisos.
    ```bash
    whoami
    
    # Ejemplo en un script
    if [ "$(whoami)" != "root" ]; then
        echo "¡Error! Necesitas ser root."
        exit 1
    fi
    ```

3.  **`ssh` – Conexión remota segura**
    ```bash
    ssh usuario@servidor          # Conexión básica
    ssh -p 2222 usuario@servidor  # Puerto personalizado
    ssh -i ~/.ssh/mi_llave usuario@servidor  # Usar clave privada
    ```

4.  **`scp` – Copiar archivos de forma segura**
    ```bash
    scp archivo.txt usuario@servidor:/ruta/  # Copiar un archivo
    scp -r carpeta/ usuario@servidor:/ruta/  # Copiar una carpeta (recursivo)
    ```

5.  **`nc` (Netcat) – El "navaja suiza" de redes**
    ```bash
    nc -zv servidor.com 80-100    # Escanear puertos
    nc -l 1234 > archivo_recibido  # Recibir un archivo
    ```

6.  **`ss` – Estadísticas de sockets (reemplaza a `netstat`)**
    ```bash
    ss -tuln    # Ver puertos abiertos (TCP/UDP)
    ss -tunlp | grep nginx  # Ver si Nginx está escuchando
    ```

7.  **`systemctl` – Gestión de servicios (systemd)**
    ```bash
    systemctl restart nginx    # Reiniciar Nginx
    systemctl status nginx     # Ver estado
    systemctl enable nginx     # Activar en el arranque
    ```

8.  **`service` – Alternativa antigua (sistemas init.d)**
    ```bash
    service apache2 restart   # Reiniciar Apache
    ```

9.  **`uptime` – Tiempo de actividad del sistema**
    ```bash
    uptime  # Muestra: "16:12 up 20 days, load: 0.20, 0.18, 0.08"
    ```

10. **`top` / `htop` – Monitor en tiempo real**
    `top` es el monitoreo básico. `htop` es una versión mejorada.
    En `top`, presiona `1` para ver todos los núcleos de CPU o `m` para ordenar por memoria.

### 🛠️ Comandos Avanzados (pero útiles)

11. **`ps` – Listar procesos**
    ```bash
    ps aux | grep nginx  # Buscar procesos de Nginx
    ```
12. **`journalctl` – Ver logs de systemd**
    ```bash
    journalctl -u nginx  # Logs de Nginx
    journalctl -xe       # Últimos logs críticos
    ```
13. **`ping` – Probar conectividad**
    ```bash
    ping -c 5 google.com  # Hacer 5 pings a Google
    ```
14. **`telnet` – Probar puertos**
    ```bash
    telnet servidor.com 80
    ```
15. **`sed` – Editar texto en stream**
    ```bash
    sed -i 's/old/new/g' archivo.conf  # Reemplazar "old" por "new"
    ```
16. **`awk` – Procesamiento de texto avanzado**
    ```bash
    awk '{print $1, $3}' access.log  # Extraer columnas 1 y 3
    ```
17. **`grep` – Buscar patrones en archivos**
    ```bash
    grep -r "ERROR" /var/log/  # Buscar "ERROR" en logs
    ```

### 📂 Comandos por Categoría

* **Sistema de Archivos**
    ```bash
    df -hT       # Espacio en discos
    du -sh * # Tamaño de archivos/carpetas
    tree -a      # Estructura de directorios
    ```
* **Procesos**
    ```bash
    lsof -i :80       # Ver qué usa el puerto 80
    kill -9 PID       # Matar proceso (¡cuidado!)
    ```
* **Paquetes (Ubuntu/Debian)**
    ```bash
    apt update && apt upgrade  # Actualizar todo
    apt install docker.io      # Instalar Docker
    ```
* **Trucos de Terminal**
    ```bash
    comando1 && comando2   # Ejecuta comando2 SOLO si comando1 funciona
    comando1 || comando2   # Ejecuta comando2 SOLO si comando1 falla
    ```

---

## 🐧 Parte 2: El Sistema de Archivos de Linux

El **Filesystem Hierarchy Standard (FHS)** es el "mapa" que sigue Linux para organizar archivos. En Linux, todo parte del directorio raíz **`/`**.

### 🗂️ Estructura Básica: Directorios Clave

| Directorio | ¿Qué contiene?                  | Ejemplo Importante             |
| :--------- | :------------------------------ | :----------------------------- |
| **`/`** | Raíz del sistema                | ¡El punto de partida de todo!  |
| **/bin** | Comandos básicos                | `ls`, `cp`, `bash`             |
| **/sbin** | Comandos de admin (root)        | `iptables`, `fdisk`            |
| **/etc** | Archivos de configuración       | `/etc/passwd`, `/etc/nginx/`   |
| **/dev** | Dispositivos (discos, USB)      | `/dev/sda1` (tu disco duro)    |
| **/home** | Directorios de usuarios         | `/home/tu_usuario`             |
| **/var** | Datos variables (logs, cachés)  | `/var/log/nginx/`              |
| **/tmp** | Archivos temporales             | (Se borra al reiniciar)        |
| **/boot** | Archivos de arranque            | `vmlinuz` (el kernel)          |
| **/opt** | Software de terceros            | `/opt/google/chrome/`          |
| **/proc** | Info de procesos (virtual)      | `/proc/cpuinfo`                |
| **/usr** | Aplicaciones y librerías        | `/usr/bin/python3`             |

### 🔍 Profundizando en Directorios Clave

1.  **/etc – El "panel de control" de Linux**: Aquí viven todas las configuraciones como `/etc/passwd`, `/etc/fstab` y `/etc/ssh/sshd_config`.
2.  **/var – Donde Linux guarda lo que cambia**: Contiene logs (`/var/log`), bases de datos (`/var/lib`) y a veces sitios web (`/var/www`).
3.  **/proc y /sys – El "cerebro" de Linux**: Son directorios virtuales que no ocupan espacio y contienen información en tiempo real sobre el CPU, RAM y red.
4.  **/home vs /root**: `/home/tu_usuario` es para tus archivos personales. `/root` es el "home" del administrador.

### 🛠️ Herramientas para DevOps

* **Ver uso de disco:**
    ```bash
    du -sh /var/log      # ¿Cuánto ocupan los logs?
    df -hT               # Espacio libre en discos
    ```
* **Buscar archivos grandes:**
    ```bash
    find / -type f -size +100M  # Archivos >100MB
    ```
* **Monitorear logs en tiempo real:**
    ```bash
    tail -f /var/log/syslog
    ```

---

## 🐧 Parte 3: Gestión de Usuarios y Permisos en Linux

La gestión de usuarios y permisos es crucial para la seguridad del sistema.

* **Usuarios**: `root` (superusuario), usuarios normales y usuarios del sistema (servicios).
* **Grupos**: Agrupan usuarios según roles o proyectos.
* **Permisos**: Lectura (`r`), Escritura (`w`) y Ejecución (`x`), asignados al Dueño, Grupo y Otros.

### El poderoso comando `chmod`

Cambia los permisos de un archivo.
**Sintaxis:** `chmod [opciones] modo archivo`
**Ejemplo `chmod 755 mi_script.sh`:**
* **7** (Dueño): `4+2+1` -> `rwx` (Lectura, Escritura, Ejecución)
* **5** (Grupo): `4+1` -> `r-x` (Lectura, Ejecución)
* **5** (Otros): `4+1` -> `r-x` (Lectura, Ejecución)

### Cambiando la propiedad con `chown`

Transfiere la propiedad de un archivo o directorio.
**Sintaxis:** `chown [opciones] nuevo_dueño:nuevo_grupo archivo`
```bash
chown alice:desarrolladores codigo_proyecto.py