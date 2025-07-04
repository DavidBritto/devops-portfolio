# 🚀 Día 18: Construyendo mi Propio Runner Self-Hosted

Hoy di un paso fundamental para tener control total sobre mi entorno de CI/CD: configuré mi primer **runner auto-alojado (self-hosted)**. En lugar de depender de las máquinas virtuales que provee GitHub, ahora tengo mi propio "trabajador" de automatización.

## 🤔 El Fundamento: ¿Por Qué un Runner Propio?

La decisión de usar un runner propio se basa en un principio clave de DevOps: la **separación entre el código y la infraestructura**.

* **Mi Repositorio de GitHub:** Es el código, el "qué" quiero construir.
* **Mi Runner Self-Hosted:** Es la infraestructura, el "dónde" se construye.

Por esta razón, y por motivos de seguridad (para no exponer tokens), **no instalé el runner en mi repositorio principal**. En su lugar, creé una pieza de infraestructura dedicada y aislada.

## ✅ El Proceso: Creando una VM Dedicada con Vagrant

Para simular un servidor dedicado, usé Vagrant para levantar una máquina virtual específica para esta tarea.

1.  **Creé un `Vagrantfile`** en una nueva carpeta, definiendo una VM con Ubuntu 22.04, 2GB de RAM y una IP privada (`192.168.56.11`).
2.  Levanté la máquina con `vagrant up`.

## 🛠️ Configuración del Runner Dentro de la VM

Una vez que la VM estuvo corriendo, realicé todo el proceso de configuración **dentro de ella** vía `vagrant ssh`:

1.  **Preparé la máquina:** Actualicé los paquetes e instalé `curl`, `git` y `docker`.
2.  **Generé el Token:** Fui a la configuración de mi repositorio en GitHub (`Settings > Actions > Runners`) y generé las credenciales para un nuevo runner.
3.  **Configuré y Ejecuté:** Usando los comandos provistos por GitHub, descargué el software del runner, lo configuré con el token (`./config.sh`) y lo puse en modo de escucha (`./run.sh`).

Al final, la terminal de mi VM se quedó esperando, lista para recibir trabajos desde GitHub.

## 🏁 La Prueba Final: Usando mi Runner

Para verificar que todo funcionaba, modifiqué mi workflow `hola-mundo.yml` en mi repositorio principal. Cambié una sola línea:

```yaml
# De:
runs-on: ubuntu-latest
# A:
runs-on: self-hosted
