# Dia 35 - Desafio final Semana 5 (Roxs Voting App en Kubernetes)

## 1) Objetivo del dia

Desplegar la aplicacion completa **Roxs Voting App** en un cluster local (Minikube), integrando todos los conceptos de la semana 5: Deployments, Services, ConfigMaps, Secrets, volumenes persistentes y Namespaces.

App de referencia en el repo:

`/home/david/git/devops-porfolio/voting-app/roxs-voting-app`

## 2) Arquitectura de la aplicacion

Flujo de datos:

```
Usuario -> vote (NodePort) -> Redis (ClusterIP) -> worker -> PostgreSQL (ClusterIP)
Usuario -> result (NodePort) --------------------------------^
```

| Componente | Imagen (referencia) | Rol | Exposicion |
|------------|---------------------|-----|------------|
| vote   | build local `./vote` o `roxsross12/vote` | Frontend de votacion | NodePort |
| result | build local `./result` o `roxsross12/result` | Resultados en tiempo real |NodePort |
| worker | build local `./worker` o `roxsross12/worker` | Procesa votos Redis -> PostgreSQL |Interno (sin Service) |
| redis | `redis:7-alpine` (app local) / `redis:alpine` (material Roxs) | Cola de mensajes | ClusterIP |
| database | `postgres:15-alpine` | Persistencia de votos | ClusterIP + PVC |

**Nota del repo:** el codigo fuente usa variables `DATABASE_*` y `REDIS_HOST`, no `POSTGRES_*` como en algunos ejemplos genericos. Los nombres de Service en K8s deben coincidir con esas variables (p. ej. `DATABASE_HOST=database` si el Service se llama `database`).

Puertos internos reales (segun Dockerfiles y codigo):

| Servicio                      | Puerto contenedor |
|------------------------------ |-------------------|
| vote (Flask)                  | 5000              |
| result (Express + Socket.IO)  | 3000              |
| worker (solo metricas HTTP)   | 3001              |
| redis                         | 6379              |
| postgres                      | 5432              |

## 3) Mapa de conceptos Semana 5 -> este desafio

| Dia | Concepto | Donde se aplica hoy |
|-----|----------|---------------------|
| 29-30 | Pods, Deployments | 5 Deployments (vote x2-3, result x2, worker x1, redis x1, postgres x1) |
| 31 | Services (ClusterIP, NodePort) | redis/database internos; vote/result externos |
| 32 | ConfigMaps y Secrets | credenciales BD, hosts de redis/database, opciones de votacion |
| 33 | PV, PVC, persistencia | datos de PostgreSQL sobreviven al borrar Pods |
| 34 | Namespaces | namespace dedicado `voting-app` |

## 4) Estrategia de despliegue por capas

Orden recomendado (dependencias de abajo hacia arriba):

1. Namespace + almacenamiento (PV/PVC)
2. ConfigMap + Secret
3. PostgreSQL (esperar ready)
4. Redis
5. vote, worker, result (worker necesita redis + postgres; vote necesita redis; result necesita postgres)

**Entrevista:** desplegar apps antes que la BD produce CrashLoopBackOff hasta que el worker/vote implementen reintentos; en esta app el worker ya reintenta conexion a DB y Redis.

## 5) Variables de entorno (verificadas en codigo)

Segun `vote/app.py`, `worker/main.js` y `result/main.js`:

```bash
# Conexion Redis (vote, worker)
REDIS_HOST=redis          # nombre del Service K8s

# Conexion PostgreSQL (vote healthcheck, worker, result)
DATABASE_HOST=database      # nombre del Service K8s
DATABASE_PORT=5432          # opcional; pg usa 5432 por defecto
DATABASE_NAME=votes
DATABASE_USER=postgres
DATABASE_PASSWORD=postgres

# Result
APP_PORT=3000

# Vote (opcional, ConfigMap)
OPTION_A=Cats
OPTION_B=Dogs
```

Contenedor PostgreSQL (Secret, no ConfigMap):

```bash
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=votes
```

## 6) Services: tipos y cuando usar cada uno

| Tipo      | Uso en voting-app |                Acceso |
|----------------------------- -|-----------------------|
| ClusterIP | redis, database   | Solo dentro del cluster |
| NodePort  | vote, result      | Navegador -> `<minikube-ip>:<nodePort>` |
| (ninguno) | worker            | Solo consume colas; no expone UI |

**Entrevista:** un Pod resuelve `database` como `database.voting-app.svc.cluster.local` dentro del namespace `voting-app`.

## 7) Almacenamiento persistente (PostgreSQL)

- **PV:** disco provisionado (hostPath valido en Minikube single-node).
- **PVC:** solicitud de capacidad (1-2Gi suficiente para el lab).
- **accessModes ReadWriteOnce:** una replica de postgres escribiendo en el volumen.
- **mountPath:** `/var/lib/postgresql/data` en el contenedor postgres.

**Entrevista:** emptyDir perderia todos los votos al reiniciar el Pod; por eso postgres usa PVC.

## 8) ConfigMaps vs Secrets

| Recurso   | Que guardar en voting-app |
|---------  |---------------------------|
| ConfigMap | `REDIS_HOST`, `DATABASE_HOST`, `OPTION_A`, `OPTION_B` |
| Secret    | `DATABASE_PASSWORD`, `POSTGRES_PASSWORD`, credenciales BD |

**Entrevista:** Secrets van en base64 en etcd (cifrado en reposo depende del cluster); no son cifrado de aplicacion. Para produccion usar Sealed Secrets, External Secrets Operator o vault.

## 9) Namespace dedicado

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: voting-app
  labels:
    proyecto: roxs-voting-app
    semana: "5"
```

Beneficios: aislamiento logico, `kubectl get all -n voting-app`, RBAC/Quota por proyecto, borrado limpio con `kubectl delete namespace voting-app`.

## 10) Probes y recursos (desafio extra)

Endpoints `/healthz` en vote, result y worker:

- **readinessProbe:** no recibe trafico hasta que redis/postgres respondan.
- **livenessProbe:** reinicia contenedor si queda colgado.

PostgreSQL: `pg_isready -U postgres -d votes`

Redis: `redis-cli ping`

**Entrevista:** readiness vs liveness -- readiness saca el Pod del Service; liveness mata y recrea el contenedor.

## 11) Imagenes Docker: build local vs publicas

El material Roxs sugiere `roxsross12/*`. En este portfolio la fuente de verdad es:

```bash
voting-app/roxs-voting-app/vote/
voting-app/roxs-voting-app/worker/
voting-app/roxs-voting-app/result/
```

Build en el daemon de Minikube (`eval $(minikube docker-env)`) + `imagePullPolicy: IfNotPresent` evita push a un registry externo.

## 12) Comparativa Docker Compose vs Kubernetes

| Aspecto          | docker-compose.yml                        | Kubernetes      |
|------------------|-------------------------------------------|-----------------|
| Red              | red `votenet`, hostname = nombre servicio | DNS de Services |
| Persistencia     | volumen `pgdata`                          | PV + PVC        |
| Config           | `.env` + env_file                         | ConfigMap + Secret |
| Escalado         | `docker compose scale`                    | `replicas` en Deployment |
| Exposicion       | `ports: 8080:5000`                        | NodePort / Ingress |

Compose expone vote en **8080** externo pero el contenedor escucha **5000**; en K8s el Service debe usar `targetPort: 5000`.

## 13) Plan de verificacion

1. `kubectl get pods -n voting-app` -- todos Running/Ready
2. Votar en la UI (gato vs perro)
3. Ver resultados actualizarse en result
4. `kubectl logs deployment/worker -n voting-app` -- votos procesados
5. Borrar Pod de postgres y comprobar que los votos persisten

## 14) Errores comunes

- Usar `POSTGRES_HOST` en lugar de `DATABASE_HOST` (esta app no lo lee).
- `targetPort` incorrecto en vote (5000, no 8080).
- Service y Deployment en namespaces distintos (Endpoints vacios).
- Olvidar montar PVC en postgres (datos efimeros).
- Imagen local no visible en Minikube (falta `minikube docker-env`).
- Mismo `nodePort` que ejercicios anteriores (30100, 30300...) -- usar puertos libres (p. ej. 30080, 30030).

## 15) Preguntas tipicas de entrevista

1. **Por que worker no tiene Service?** No recibe trafico entrante; solo lee de Redis y escribe en PostgreSQL.
2. **ClusterIP vs NodePort vs LoadBalancer:** interno vs puerto en nodo vs LB cloud.
3. **Como descubre vote la IP de redis?** DNS del Service `redis` dentro del namespace.
4. **Que pasa si borras el Pod de postgres con PVC?** El nuevo Pod remonta el mismo disco; los votos persisten.
5. **ConfigMap actualizado, la app ve el cambio?** Variables de entorno se inyectan al crear el Pod; hace falta `kubectl rollout restart`.
6. **Por que 2 replicas de vote y no de postgres?** vote es stateless; postgres con RWO suele ser 1 replica (salvo operadores HA).
7. **Diferencia Deployment vs Pod suelto:** Deployment gestiona replicas, rolling updates y self-healing.
8. **Que revisar si vote funciona pero result no?** Logs de result, `DATABASE_HOST`, Endpoints del Service database, readiness de postgres.

## 16) Metricas de exito

- 5 Deployments Running en `voting-app`
- 4 Services (redis, database, vote, result)
- 1 namespace, 1 PVC Bound
- Flujo completo voto -> worker -> result
- Datos persisten tras delete pod postgres
- Config externalizada (ConfigMap/Secret)

## 17) Diagrama mental del namespace

```
Namespace: voting-app
├── PV/PVC (postgres-data)
├── ConfigMap (app-config) + Secret (db-credentials)
├── Deployment/Service: database (ClusterIP:5432)
├── Deployment/Service: redis (ClusterIP:6379)
├── Deployment/Service: vote (NodePort -> 5000)
├── Deployment: worker
└── Deployment/Service: result (NodePort -> 3000)
```
