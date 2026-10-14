# 📘 Guía de Supuestos de Arquitectura y Laboratorio Práctico (Seguridad & Observabilidad)

> **De un arquitecto senior para vos:**  
> Si llevás más de un año postergando este reto y te quedaste en la Semana 5, no te castigues. Es lo más normal del mundo: la curva de aprendizaje en DevOps es empinada porque la mayoría de los cursos te enseñan a tirar comandos (`docker run`, `kubectl apply`) pero **nunca te explican los supuestos de fondo**.  
> Esta guía fue diseñada específicamente para vos: para que entiendas la lógica detrás de cada decisión, domines la teoría clave para entrevistas y puedas **practicar Seguridad y Observabilidad desde cero** en tu propia máquina, paso a paso y sin gastar un solo centavo en la nube.

---

## 🧭 PARTE I: Los 5 Supuestos Fundamentales que Nadie Te Explica

Para entender qué hace cada archivo de este repositorio, tenés que internalizar estos cinco modelos mentales:

### 1. El principio de Ganado vs. Mascotas (*Pets vs. Cattle*)
- **En la informática tradicional (Mascotas):** Los servidores tienen nombres (`servidor-db-principal`), se configuran a mano, se actualizan con cuidado y si fallan, todo el mundo llora y se queda despierto toda la noche intentando repararlos.
- **En DevOps moderno (Ganado):** Los servidores y contenedores no tienen nombre ni alma; tienen un número de serie generado al azar (`vote-7b89f8dc9b-4k2ls`). Si un nodo o un pod empieza a fallar, **no lo arreglás: lo destruís** y dejás que Kubernetes o el Auto Scaling Group levante uno nuevo en 3 segundos idéntico al anterior.
- **El supuesto clave:** Ningún contenedor debe guardar estado en su sistema de archivos local. Todo contenedor debe poder morir en cualquier milisegundo sin que se pierda un solo dato.

### 2. Desacoplamiento de Cargas Stateless vs. Stateful
- **Stateless (Sin estado):** El frontend de `vote` y `result`. No guardan información en disco ni recuerdan la petición anterior. Por eso podés tener 10 réplicas corriendo en paralelo balanceadas sin problema.
- **Stateful (Con estado):** `PostgreSQL` y `Redis`. Guardan información persistente. No podés simplemente multiplicarlos sin una estrategia de replicación, volúmenes de red desacoplados (`EBS gp3` o `PVC`) y mecanismos de sincronización transaccional.
- **El supuesto clave:** Separar la lógica de negocio (stateless) de los datos (stateful) es lo que permite que el sistema escale elásticamente y se auto-repare.

### 3. Declarativo vs. Imperativo (El corazón de IaC y Kubernetes)
- **Imperativo:** *"Creame una máquina virtual, instalale Docker, descargá esta imagen y corré este contenedor en el puerto 80"*. Si el script falla en el paso 3 y lo volvés a correr, rompe todo.
- **Declarativo (Terraform, K8s, ArgoCD):** *"El estado deseado es tener 3 réplicas de esta imagen corriendo en el puerto 80"*. Vos no le decís **cómo** hacerlo; el motor compara continuamente el estado actual con el deseado y aplica únicamente las diferencias necesarias (*Reconciliación continua*).
- **El supuesto clave:** Tu repositorio de Git no contiene comandos; contiene la **definición del estado final**.

### 4. La Red en Kubernetes es Plana pero Aislada Lógicamente
- En Kubernetes, cada Pod recibe su propia IP interna real y todos los Pods pueden verse entre sí por defecto sin NAT.
- Un `Service` (`ClusterIP`) no es un servidor ni un proceso; es una regla virtual en el kernel de Linux (`iptables` o `IPVS`) gestionada por `kube-proxy` que balancea tráfico hacia las IPs dinámicas de los Pods.
- **El supuesto clave:** Nunca te conectás a la IP de un Pod; te conectás al nombre del Service en el DNS interno (`db:5432`, `redis:6379`), y Kubernetes se encarga de dirigir el paquete al Pod que esté vivo y saludable.

### 5. GitOps (Pull) destruye el modelo de CI/CD tradicional (Push)
- En un pipeline clásico, GitHub Actions tiene que tener acceso SSH o la clave de tu clúster de producción para empujar cambios. Si hackean GitHub o se filtra un secreto, perdiste tu infraestructura.
- Con **GitOps (ArgoCD)**, el clúster es un agente cerrado que mira hacia afuera: nadie entra al clúster; es el clúster el que lee Git y se actualiza solo.
- **El supuesto clave:** Nadie toca `kubectl` en producción. Si querés hacer un cambio, abrís un Pull Request.

---

## 🛡️ PARTE II: Laboratorio Práctico de DevSecOps (Paso a Paso)

Mencionaste que no tocaste ni viste nada de seguridad. La seguridad moderna en DevOps no se hace al final antes de salir a producción; se implementa a la izquierda en el ciclo de desarrollo (**Shift-Left Security**).

Acá tenés **4 prácticas reales y ejecutables** en tu máquina para dominarla:

```
[Código del desarrollador]
       |
       +---> [1. Detección de Secretos: GitLeaks] (Evitar filtrar contraseñas en Git)
       |
       +---> [2. SAST: Semgrep] (Detectar código inseguro antes de compilar)
       |
       +---> [3. Vulnerabilidades en Imágenes: Trivy] (Detectar CVEs en el contenedor)
       |
       +---> [4. Runtime Hardening: Non-Root & Capabilities] (Blindar el Pod en K8s)
```

---

### Práctica de Seguridad 1: Detección de Secretos con GitLeaks

**El problema real:** Un desarrollador commitea un archivo con `aws_secret_key = "AKIA..."` o la contraseña de la base de datos a un repo público de GitHub. A los 5 minutos, bots automáticos ya te vaciaron la cuenta o secuestraron tus servidores.

#### Comandos para practicar:

```bash
# 1. Instalar GitLeaks (en Linux/Ubuntu)
curl -sS https://raw.githubusercontent.com/gitleaks/gitleaks/master/scripts/install.sh | sudo bash

# 2. Escanear todo el historial de este repositorio en busca de secretos expuestos
gitleaks detect --source . --verbose --report-path gitleaks-report.json

# 3. Simulación de prueba: Crear un archivo con una clave falsa y ver cómo GitLeaks la atrapa
echo 'AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"' > test-secret.env
gitleaks detect --source test-secret.env --verbose

# 4. Limpiar el archivo de prueba
rm -f test-secret.env gitleaks-report.json
```

**Concepto que tenés que entender:** GitLeaks se ejecuta como un **Pre-commit hook** (en tu máquina local antes de hacer `git commit`) y en el pipeline de GitHub Actions para rechazar cualquier Pull Request que contenga tokens, certificados o claves privadas.

---

### Práctica de Seguridad 2: Escaneo de Vulnerabilidades en Imágenes con Trivy

**El problema real:** Descargás una imagen base como `python:3.9` o `node:16` de internet sin saber que contiene librerías del sistema operativo con vulnerabilidades críticas (CVEs) conocidas que permiten ejecución remota de código (RCE).

#### Comandos para practicar:

```bash
# 1. Instalar Trivy (Aquasecurity)
sudo apt-get install wget apt-transport-https gnupg lsb-release -y
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update && sudo apt-get install trivy -y

# 2. Escanear la imagen del frontend de Vote en busca de vulnerabilidades
trivy image dockersamples/examplevotingapp_vote:before

# 3. Filtrar solo las vulnerabilidades CRÍTICAS y ALTAS que tienen parche disponible
trivy image --severity HIGH,CRITICAL --ignore-unfixed dockersamples/examplevotingapp_vote:before

# 4. Generar el Software Bill of Materials (SBOM) en formato estándar CycloneDX
trivy image --format cyclonedx --output vote-sbom.json dockersamples/examplevotingapp_vote:before
head -n 30 vote-sbom.json
```

**Concepto que tenés que entender:** En un pipeline de CI/CD profesional, si Trivy detecta una vulnerabilidad `CRITICAL` con parche disponible, el build falla automáticamente y bloquea el despliegue con `--exit-code 1`.

---

### Práctica de Seguridad 3: Hardening de Contenedores (Correr como No-Root)

**El problema real:** Por defecto, los contenedores corren como el usuario `root` (UID 0). Si un atacante encuentra una falla en tu aplicación Flask o Node.js y logra escapar del contenedor (*Container Breakout*), **se convierte en el root del servidor host físico**.

#### Cómo se ve en código:

En el `Dockerfile`:
```dockerfile
# MAL (Por defecto):
CMD ["python", "app.py"] # Corre como root (UID 0)

# BIEN (Hardened):
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER 10001
CMD ["python", "app.py"]
```

En el manifiesto de Kubernetes (`securityContext`):
```yaml
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 10001
    fsGroup: 10001
  containers:
    - name: vote
      image: roxs-vote:v1
      securityContext:
        allowPrivilegeEscalation: false # Prohíbe sudo o elevación de privilegios
        readOnlyRootFilesystem: true    # El atacante no puede escribir scripts en disco
        capabilities:
          drop: ["ALL"]                 # Remueve todas las llamadas de bajo nivel del kernel
```

#### Comandos para practicar en tu clúster local (Kind):

```bash
# 1. Probar un pod que intenta correr como root cuando la política lo prohíbe
kubectl run test-root --image=nginx --restart=Never --overrides='
{
  "spec": {
    "securityContext": { "runAsNonRoot": true }
  }
}'

# 2. Observar el error en Kubernetes:
kubectl get pod test-root
kubectl describe pod test-root | grep -i "container has runAsNonRoot and image will run as root"
# Kubernetes se niega a iniciar el contenedor: ContainerCannotRun

# 3. Limpiar
kubectl delete pod test-root
```

---

### Práctica de Seguridad 4: Aislamiento de Red con NetworkPolicies

**El problema real:** En Kubernetes, por defecto, el frontend de Vote puede conectarse directamente al puerto 5432 de PostgreSQL, aunque **no debería** (Vote solo habla con Redis; es el Worker el único que debe hablar con Postgres). Si hackean Vote, pueden acceder directamente a los datos.

#### Manifiesto de NetworkPolicy (`isolate-db.yaml`):

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-db-only-from-worker
  namespace: voting-app
spec:
  podSelector:
    matchLabels:
      app: db # Aplica a PostgreSQL
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: worker # SOLO el Worker tiene permiso de entrada
      ports:
        - protocol: TCP
          port: 5432
```

**Concepto que tenés que entender:** `NetworkPolicy` es el cortafuegos interno de Kubernetes. Aisla el tráfico intra-clúster para que una vulnerabilidad en la capa web no se convierta en una filtración de base de datos.

---

## 📊 PARTE III: Laboratorio Práctico de Observabilidad (Paso a Paso)

Dijiste que no viste observabilidad. Vamos a derribar el mito: **Observabilidad no es mirar logs cuando el sistema se cae**. Es la capacidad de entender el estado interno de un sistema complejo a partir de sus salidas externas.

### La diferencia entre Métricas, Logs y Trazas (Los 3 Pilares)

| Pilar | ¿Qué es? | Ejemplo | ¿Para qué sirve? | Costo de disco |
|---|---|---|---|---|
| **Métricas** | Números agregados en series de tiempo | `cpu_usage: 78%`, `http_requests_per_sec: 450` | Detectar problemas y disparar alertas inmediatas | Muy bajo |
| **Logs** | Mensajes de texto con timestamp y contexto | `{"timestamp": "...", "level": "ERROR", "msg": "DB Timeout"}` | Entender la causa raíz una vez que sonó la alarma | Alto |
| **Trazas** | El viaje completo de una petición HTTP | Petición #456 demoró: 40ms en Vote -> 10ms en Redis -> 180ms en Worker | Descubrir cuellos de botella de latencia entre servicios | Medio |

---

### Los 2 Métodos de Monitoreo que DEBES saber para entrevistas

1. **El Método USE (Para Infraestructura y Hardware: Nodos, CPU, RAM, Discos):**
   - **U**tilization: ¿Qué porcentaje de tiempo estuvo ocupado el recurso? (e.g. 85% CPU).
   - **S**aturation: ¿Cuánto trabajo extra está encolado esperando turno? (e.g. Linux run-queue, Swap).
   - **E**rrors: ¿Ocurrieron fallos en el dispositivo? (e.g. paquetes de red descartados).

2. **El Método RED (Para Microservicios y APIs HTTP):**
   - **R**ate: Cantidad de peticiones procesadas por segundo (RPS).
   - **E**rrors: Cantidad de peticiones que fallan por segundo (errores HTTP 5xx).
   - **D**uration: Tiempo que tardan las peticiones en responder (Distribución de latencia: percentiles p50, p95, p99).

---

### Práctica de Observabilidad 1: Levantar el Stack Completo en 2 Minutos

Ya tenés todo configurado en este repositorio. Vamos a levantarlo localmente con Docker Compose para que lo toques con tus propias manos:

```bash
# 1. Posicionarte en la carpeta de la voting app
cd /home/david/git/devops-porfolio/voting-app/roxs-voting-app

# 2. Levantar los microservicios + Prometheus + Grafana
docker compose up -d

# 3. Comprobar que todos los contenedores estén corriendo
docker compose ps
```

Accedé desde tu navegador a:
- **Vote App (Frontend):** [http://localhost:8080](http://localhost:8080) -> Emití algunos votos.
- **Result App (Dashboard):** [http://localhost:3000](http://localhost:3000) -> Mirá cómo se actualiza.
- **Prometheus UI:** [http://localhost:9091](http://localhost:9091) -> Donde viven las métricas.
- **Grafana UI:** [http://localhost:3003](http://localhost:3003) -> (Usuario: `admin` / Password: `admin`).

---

### Práctica de Observabilidad 2: Consultas PromQL Esenciales en Prometheus

Entrá a [http://localhost:9091/graph](http://localhost:9091/graph) y probá estas 4 consultas en la pestaña **Expression**:

1. **¿Qué servicios están vivos en este momento?**
   ```promql
   up
   ```
   *Devuelve `1` si el servicio está respondiendo al raspado de métricas y `0` si está caído.*

2. **Calcular la tasa de peticiones por segundo en los últimos 5 minutos:**
   ```promql
   rate(http_requests_total[5m])
   ```

3. **Calcular el porcentaje de uso de CPU de un contenedor:**
   ```promql
   sum(rate(container_cpu_usage_seconds_total[1m])) by (name) * 100
   ```

4. **Calcular la tasa de errores HTTP 5xx (La métrica crítica de alertas):**
   ```promql
   sum(rate(http_requests_total{status=~"5.."}[2m])) / sum(rate(http_requests_total[2m])) * 100
   ```

---

### Práctica de Observabilidad 3: Simular una Caída y Ver la Alerta Dispararse

Este es el ejercicio que une todo. Vamos a provocar una falla a propósito para ver cómo reacciona el sistema:

```bash
# 1. Ver que en Prometheus (en http://localhost:9091/targets) todos los targets están en 'UP' (verde)

# 2. Simular la caída de la base de datos PostgreSQL deteniendo su contenedor
docker compose stop db

# 3. Ir de inmediato al navegador a Prometheus en la pestaña 'Alerts':
# En menos de 30 segundos verás la alerta cambiar de estado:
# - Estado 'Pending': Prometheus detectó que db está caído y está esperando el tiempo de gracia (for: 30s)
# - Estado 'Firing': Pasaron los 30 segundos; la alerta se dispara en rojo y notifica a Alertmanager

# 4. Ver los logs de error en el Worker en tiempo real
docker compose logs worker --tail=20 -f
# Observarás los errores: connect ECONNREFUSED a PostgreSQL

# 5. Recuperar el servicio levantando la base de datos de nuevo
docker compose start db

# 6. Observar cómo en 15 segundos la alerta vuelve a estado verde ('Resolved') de forma automática
```

---

## 🎯 PARTE IV: Preguntas Típicas de Entrevista Técnica (Cheat Sheet)

Cuando presentes este repositorio en entrevistas para puestos de DevOps o SRE, te van a hacer estas preguntas. Así es como respondés con autoridad técnica:

#### P1: "¿Cómo gestionás los secretos de AWS en tus Pods de Kubernetes?"
> **Respuesta senior:** *"Nunca usamos credenciales estáticas como `AWS_ACCESS_KEY_ID` ni Secrets planos. Implementamos IAM Roles for Service Accounts (IRSA) mediante el proveedor OIDC del clúster EKS. Cada Pod se asocia a una ServiceAccount anotada con el ARN del rol IAM y asume credenciales temporales que rotan cada hora vía STS mediante el SDK."*

#### P2: "¿Cuál es la diferencia entre un RollingUpdate estándar y un Canary Release con Argo Rollouts?"
> **Respuesta senior:** *"Un RollingUpdate solo reemplaza réplicas de forma continua; si la versión nueva tiene un bug que falla en tiempo de ejecución, reemplaza todos los pods y rompe producción. Con Argo Rollouts y Canary Releases, enrutamos solo un porcentaje pequeño (e.g. 10%) a la nueva versión, pausamos para evaluar métricas en Prometheus (latencia p99 y tasa de 5xx) y si las métricas degradan, ejecutamos un rollback automático en milisegundos sin intervención humana."*

#### P3: "¿Por qué usar Prometheus con pull-based scraping en lugar de que las apps envíen métricas con push?"
> **Respuesta senior:** *"El modelo pull protege a la infraestructura de monitoreo: si una aplicación sufre un pico masivo de tráfico o un bucle infinito, un modelo push bombardearía al servidor de métricas y lo tumbaría (DDoS interno). Con pull, Prometheus decide su propio ritmo de scraping (e.g. cada 15s) y además detecta caídas de inmediato: si el endpoint `/metrics` no responde en el timeout configurado, Prometheus sabe instantáneamente que la instancia cayó (`up == 0`)."*

#### P4: "¿Qué hacés si un Pod en Kubernetes se queda en estado `CrashLoopBackOff`?"
> **Respuesta senior:** *"Sigo un diagnóstico sistemático: primero `kubectl describe pod` para revisar eventos de OOMKilled, fallos de liveness probes o errores de montaje de volúmenes. Luego `kubectl logs <pod> --previous` para leer el stack trace del contenedor antes de que muriera. Si no hay logs, valido conectividad y secretos inyectados con variables de entorno."*

---

## 🚀 PARTE V: Tu Plan de 2 Semanas para Desbloquearte (Sin Presión)

Tenés este repositorio 100% terminado y documentado con las 10 semanas (70 días de hands-on) del reto de Roxs. Para que el conocimiento sea tuyo y pierdas el miedo a las entrevistas, dedicate **45 minutos al día** durante dos semanas siguiendo este orden:

- **Semana 1: Fundamentos, Contenedores y Observabilidad**
  - Día 1: Leé la Semana 1 y 2 en el repo. Levantá la app con `docker compose up -d`.
  - Día 2: Mirá el archivo `docker-compose.yml` y entendé cómo se comunican Vote, Redis, Worker y Postgres.
  - Día 3: Hacé la **Práctica de Seguridad 1 y 2** de esta guía (GitLeaks y Trivy).
  - Día 4: Hacé la **Práctica de Observabilidad 1 y 2** (Prometheus y PromQL en la Semana 8).
  - Día 5: Hacé la **Práctica de Observabilidad 3** (Simular la caída de PostgreSQL y ver la alerta en Grafana).

- **Semana 2: Kubernetes, Cloud Emulation y Capstone**
  - Día 6: Leé la Semana 5 (manifiestos de Kubernetes en `voting-app/roxs-voting-app/*.yaml`).
  - Día 7: Levantá un clúster local con Kind (`kind create cluster`) y desplegá los manifiestos con `deploy-k8s.sh`.
  - Día 8: Leé la Semana 6 y 7 (Kustomize, Helm, RBAC y NetworkPolicies).
  - Día 9: Leé la Semana 9 (LocalStack con S3, DynamoDB y Terraform) para dominar Cloud sin costos.
  - Día 10: Leé la Semana 10 (pruebas de estrés con k6 y Capstone del Día 70). ¡Felicitaciones! Tenés un portfolio de nivel Senior para mostrar en tu LinkedIn y GitHub con total seguridad.

