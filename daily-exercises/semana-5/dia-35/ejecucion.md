# Dia 35 - Ejecucion hands-on (Desafio final: Roxs Voting App en Kubernetes)

## Objetivo

Desplegar la stack completa de **Roxs Voting App** en Minikube aplicando conceptos de toda la Semana 5: Namespace, PV/PVC, ConfigMaps, Secrets, Deployments, Services (ClusterIP + NodePort) y verificacion end-to-end de votacion.

App fuente (verificada en el repo):

```text
/home/david/git/devops-porfolio/voting-app/roxs-voting-app/
├── vote/          # Flask, puerto 5000, REDIS_HOST, DATABASE_*
├── worker/        # Node.js, REDIS_HOST, DATABASE_*
├── result/        # Node.js, puerto 3000, DATABASE_*
├── docker-compose.yml
└── ...
```

Los manifiestos YAML **los creas tu** en `daily-exercises/semana-5/dia-35/` siguiendo cada paso.

Material teorico: `teoria.md` (mismo directorio) y `daily-exercises/teoria diaria/dia-35.md`.

## Requisitos

- Minikube y `kubectl` operativos.
- Codigo de la app clonado en la ruta anterior.
- Puertos NodePort libres: **30080** (vote) y **30030** (result).

```bash
cd /home/david/git/devops-porfolio/daily-exercises/semana-5/dia-35
minikube status
kubectl get nodes
```

**Captura #1:** salida de `minikube status` y `kubectl get nodes` (cluster listo).

---

## Paso 0 - Construir imagenes en el daemon de Minikube

Las apps vote/worker/result se construyen desde el codigo local (no dependas de `POSTGRES_*`; la app usa `DATABASE_*` y `REDIS_HOST`).

```bash
eval $(minikube docker-env)
cd /voting-app/roxs-voting-app

docker build -t vote:local ./vote
docker build -t worker:local ./worker
docker build -t result:local ./result

docker images | grep -E 'vote|worker|result'
```

Alternativa rapida (sin build): sustituir en los YAML `vote:local` por `roxsross12/vote` (y lo mismo para worker/result). Se pierde control sobre el codigo del portfolio.

**Captura #2:** salida de `docker images` mostrando `vote:local`, `worker:local`, `result:local`.

---

## Paso 1 - Namespace

Crea `01-namespace.yaml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: voting-app
  labels:
    proyecto: roxs-voting-app
    ambiente: lab
    semana: "5"
```

```bash
kubectl apply -f 01-namespace.yaml
kubectl get ns voting-app --show-labels
```

**Captura #3:** namespace `voting-app` con labels visibles.

---

## Paso 2 - Almacenamiento PostgreSQL (PV + PVC)

Crea `02-storage.yaml` (hostPath valido en Minikube; patron del dia 33):

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: postgres-pv
spec:
  capacity:
    storage: 2Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: postgres-storage
  hostPath:
    path: /tmp/postgres-voting-data
    type: DirectoryOrCreate
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: voting-app
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
  storageClassName: postgres-storage
```

```bash
kubectl apply -f 02-storage.yaml
kubectl get pv postgres-pv
kubectl get pvc -n voting-app
```

Espera estado **Bound** en el PVC.

**Captura #4:** PV `postgres-pv` y PVC `postgres-pvc` en estado `Bound`.

---

## Paso 3 - ConfigMap y Secret

Crea `03-configs-secrets.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: voting-app
data:
  REDIS_HOST: "redis"
  DATABASE_HOST: "database"
  DATABASE_NAME: "votes"
  DATABASE_USER: "postgres"
  OPTION_A: "Cats"
  OPTION_B: "Dogs"
  APP_PORT: "3000"
---
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
  namespace: voting-app
type: Opaque
stringData:
  DATABASE_PASSWORD: "postgres"
  POSTGRES_USER: "postgres"
  POSTGRES_PASSWORD: "postgres"
  POSTGRES_DB: "votes"
```

```bash
kubectl apply -f 03-configs-secrets.yaml
kubectl get configmap,secret -n voting-app
kubectl describe configmap app-config -n voting-app | head -20
```

**Captura #5:** ConfigMap `app-config` y Secret `db-credentials` listados en `voting-app`.

---

## Paso 4 - PostgreSQL

Crea `04-postgres.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: database
  namespace: voting-app
  labels:
    app: database
    tier: data
spec:
  replicas: 1
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
        tier: data
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        ports:
        - containerPort: 5432
        envFrom:
        - secretRef:
            name: db-credentials
        volumeMounts:
        - name: postgres-data
          mountPath: /var/lib/postgresql/data
        readinessProbe:
          exec:
            command: ["pg_isready", "-U", "postgres", "-d", "votes"]
          initialDelaySeconds: 10
          periodSeconds: 5
        livenessProbe:
          exec:
            command: ["pg_isready", "-U", "postgres", "-d", "votes"]
          initialDelaySeconds: 30
          periodSeconds: 10
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
      volumes:
      - name: postgres-data
        persistentVolumeClaim:
          claimName: postgres-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: database
  namespace: voting-app
spec:
  selector:
    app: database
  ports:
  - port: 5432
    targetPort: 5432
  type: ClusterIP
```

```bash
kubectl apply -f 04-postgres.yaml
kubectl rollout status deployment/database -n voting-app --timeout=180s
kubectl get pods,svc -n voting-app -l app=database
kubectl logs deployment/database -n voting-app --tail=10
```

**Captura #6:** Pod `database-*` en `Running` y Service `database` ClusterIP activo.

---

## Paso 5 - Redis

Crea `05-redis.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: voting-app
  labels:
    app: redis
    tier: cache
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
        tier: cache
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
        readinessProbe:
          exec:
            command: ["redis-cli", "ping"]
          initialDelaySeconds: 5
          periodSeconds: 5
        livenessProbe:
          exec:
            command: ["redis-cli", "ping"]
          initialDelaySeconds: 15
          periodSeconds: 10
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: redis
  namespace: voting-app
spec:
  selector:
    app: redis
  ports:
  - port: 6379
    targetPort: 6379
  type: ClusterIP
```

```bash
kubectl apply -f 05-redis.yaml
kubectl rollout status deployment/redis -n voting-app --timeout=120s
kubectl get pods,svc -n voting-app -l app=redis
```

**Captura #7:** redis Running + Service `redis` ClusterIP.

---

## Paso 6 - Vote (frontend)

Crea `06-vote.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vote
  namespace: voting-app
  labels:
    app: vote
    tier: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: vote
  template:
    metadata:
      labels:
        app: vote
        tier: frontend
    spec:
      containers:
      - name: vote
        image: vote:local
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 5000
        envFrom:
        - configMapRef:
            name: app-config
        - secretRef:
            name: db-credentials
        readinessProbe:
          httpGet:
            path: /healthz
            port: 5000
          initialDelaySeconds: 10
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /healthz
            port: 5000
          initialDelaySeconds: 20
          periodSeconds: 10
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "300m"
---
apiVersion: v1
kind: Service
metadata:
  name: vote
  namespace: voting-app
spec:
  selector:
    app: vote
  ports:
  - port: 5000
    targetPort: 5000
    nodePort: 30080
  type: NodePort
```

```bash
kubectl apply -f 06-vote.yaml
kubectl rollout status deployment/vote -n voting-app --timeout=120s
kubectl get pods -n voting-app -l app=vote
kubectl get svc vote -n voting-app
```

Acceso:

```bash
echo "Vote UI: http://$(minikube ip):30080"
minikube service vote -n voting-app --url
curl -s "$(minikube service vote -n voting-app --url)/healthz"
```

**Captura #8:** interfaz de votacion (Cats vs Dogs) en el navegador en el NodePort **30080**.

---

## Paso 7 - Worker

Crea `07-worker.yaml` (sin Service; solo procesamiento):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: worker
  namespace: voting-app
  labels:
    app: worker
    tier: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: worker
  template:
    metadata:
      labels:
        app: worker
        tier: backend
    spec:
      containers:
      - name: worker
        image: worker:local
        imagePullPolicy: IfNotPresent
        envFrom:
        - configMapRef:
            name: app-config
        - secretRef:
            name: db-credentials
        livenessProbe:
          httpGet:
            path: /healthz
            port: 3001
          initialDelaySeconds: 20
          periodSeconds: 10
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "300m"
```

```bash
kubectl apply -f 07-worker.yaml
kubectl rollout status deployment/worker -n voting-app --timeout=120s
kubectl logs deployment/worker -n voting-app --tail=15
```

Emite varios votos en la UI y revisa logs:

```bash
kubectl logs deployment/worker -n voting-app -f
```

**Captura #9:** logs del worker mostrando procesamiento de votos (Ctrl+C para salir del follow).

---

## Paso 8 - Result (resultados en tiempo real)

Crea `08-result.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: result
  namespace: voting-app
  labels:
    app: result
    tier: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: result
  template:
    metadata:
      labels:
        app: result
        tier: frontend
    spec:
      containers:
      - name: result
        image: result:local
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 3000
        envFrom:
        - configMapRef:
            name: app-config
        - secretRef:
            name: db-credentials
        readinessProbe:
          httpGet:
            path: /healthz
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /healthz
            port: 3000
          initialDelaySeconds: 20
          periodSeconds: 10
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "300m"
---
apiVersion: v1
kind: Service
metadata:
  name: result
  namespace: voting-app
spec:
  selector:
    app: result
  ports:
  - port: 3000
    targetPort: 3000
    nodePort: 30030
  type: NodePort
```

```bash
kubectl apply -f 08-result.yaml
kubectl rollout status deployment/result -n voting-app --timeout=120s
kubectl get pods,svc -n voting-app
```

Acceso:

```bash
echo "Result UI: http://$(minikube ip):30030"
minikube service result -n voting-app --url
```

Vota varias veces en vote y observa barras actualizandose en result.

**Captura #10:** pantalla de resultados reflejando votos en tiempo real (NodePort **30030**).

---

## Paso 9 - Vista global del namespace

```bash
kubectl get all -n voting-app
kubectl get pv,pvc -n voting-app
kubectl get configmap,secret -n voting-app
```

Resumen esperado:

- 5 Deployments: database, redis, vote, worker, result
- 4 Services: database, redis, vote, result
- 2+2+1+1+1 pods segun replicas

**Captura #11:** salida de `kubectl get all -n voting-app` con todos los componentes Running.

---

## Paso 10 - Prueba de persistencia

```bash
# Anota conteo actual en la UI de result, luego:
kubectl delete pod -l app=database -n voting-app
kubectl rollout status deployment/database -n voting-app --timeout=180s
```

Recarga result: los votos deben seguir presentes (PVC montado de nuevo).

**Captura #12:** misma cantidad de votos tras recrear el Pod de postgres (comparar antes/despues o screenshot de result estable).

Prueba extra (auto-recovery):

```bash
kubectl delete pod -l app=vote -n voting-app
kubectl get pods -n voting-app -l app=vote -w
```

El Deployment recrea replicas automaticamente.

---

## Paso 11 - Script de despliegue (opcional)

Crea `deploy.sh`:

```bash
#!/bin/bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
for f in 01-namespace.yaml 02-storage.yaml 03-configs-secrets.yaml \
         04-postgres.yaml 05-redis.yaml 06-vote.yaml 07-worker.yaml 08-result.yaml; do
  echo "Applying $f..."
  kubectl apply -f "$DIR/$f"
done
kubectl rollout status deployment/database -n voting-app --timeout=180s
kubectl rollout status deployment/redis -n voting-app --timeout=120s
kubectl rollout status deployment/vote -n voting-app --timeout=120s
kubectl rollout status deployment/worker -n voting-app --timeout=120s
kubectl rollout status deployment/result -n voting-app --timeout=120s
kubectl get all -n voting-app
```

```bash
chmod +x deploy.sh
./deploy.sh
```

---

## Debug rapido

```bash
kubectl describe pod -l app=vote -n voting-app | tail -30
kubectl get endpoints -n voting-app
kubectl get events -n voting-app --sort-by='.lastTimestamp' | tail -15
kubectl logs deployment/vote -n voting-app --tail=30
kubectl exec -it deployment/redis -n voting-app -- redis-cli ping
```

Errores frecuentes:

| Sintoma | Causa probable |
|---------|----------------|
| vote CrashLoop | `REDIS_HOST` incorrecto o redis no Ready |
| result sin datos | `DATABASE_HOST` distinto al nombre del Service |
| ImagePullBackOff | build sin `minikube docker-env` o tag incorrecto |
| PVC Pending | PV no compatible (storageClassName / capacidad) |
| NodePort no responde | puerto ocupado o firewall; prueba `minikube service` |

---

## Limpieza (opcional)

```bash
kubectl delete namespace voting-app
kubectl delete pv postgres-pv --ignore-not-found
# hostPath en Minikube: rm -rf /tmp/postgres-voting-data (dentro del nodo si quieres borrar datos)
eval $(minikube docker-env) 2>/dev/null || true
```

---

## Resenas importantes (reforzar al cerrar el dia)

1. **Desafio integrador:** un mismo namespace con capas infra (PV, Config/Secret) + datos (postgres, redis) + apps (vote, worker, result).
2. **Nombres de Service = hostnames:** alinear `DATABASE_HOST`/`REDIS_HOST` con los Services (`database`, `redis`), igual que en `docker-compose.yml`.
3. **Variables reales del repo:** usar `DATABASE_*`, no `POSTGRES_*`, en vote/worker/result; `POSTGRES_*` solo en el contenedor postgres.
4. **Puertos:** vote escucha **5000**; result **3000**; NodePort mapea hacia esos targetPorts.
5. **Worker sin Service** es normal: patron cola/consumidor, no API publica.
6. **Persistencia:** postgres + PVC; redis sin PVC (cache efimera aceptable en este lab).
7. **Orden de despliegue** reduce tiempo en CrashLoop; las apps reintentan pero postgres/redis primero acelera el Ready.
8. **Semana 5 completa:** Pods/Deployments (29-30), Services (31), ConfigMaps/Secrets (32), volumenes (33), Namespaces (34) -- todo en una sola app real del portfolio.
9. **Entrevista:** explicar flujo voto -> redis -> worker -> postgres -> result demuestra microservicios, colas y stateful vs stateless.
10. **Compose vs K8s:** mismo diseno logico; cambian mecanismos de red, secretos y disco -- util comparar side-by-side con `docker-compose.yml`.

## Documentacion para compartir (#DevOpsConRoxs)

Screenshots minimos del dia: capturas **#8** (vote), **#10** (result), **#11** (kubectl get all). Anota que fue lo mas dificil (suele ser env vars, targetPort o imagenes locales en Minikube).
