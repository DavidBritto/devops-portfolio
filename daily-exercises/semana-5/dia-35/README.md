# Dia 35: Final Challenge Week 5 - Full Roxs Voting App Orchestrated on Kubernetes

## 1. Technical Overview and Objective

The objective of Day 35 is the complete end-to-end orchestration of the Roxs Voting App microservices architecture on a Kubernetes cluster. This capstone challenge for Week 5 brings together all fundamental Kubernetes objects: Deployments for stateless application layers (Vote, Result, Worker), PersistentVolumeClaims and Deployments for stateful data layers (PostgreSQL, Redis), ConfigMaps and Secrets for environment injection, and ClusterIP/NodePort Services for internal and external network communication.

Key goals:
- Orchestrate 5 distributed microservices in a dedicated Kubernetes namespace (`voting-app`).
- Provide data persistence for PostgreSQL via PersistentVolumeClaims.
- Implement decoupled internal DNS discovery using ClusterIP services (`redis-service`, `db-service`).
- Expose external entrypoints via NodePort services (`vote-service` on port 31080, `result-service` on port 31000).
- Validate end-to-end transactional vote flows from client frontend to relational database.

---

## 2. Architecture and Complete Cluster Topology Breakdown

### 2.1 Complete Kubernetes Workload Graph

```
+-------------------------------------------------------------------------+
| EXTERNAL CLIENT BROWSERS & CONSUMERS                                   |
|  - Vote UI:   http://localhost:31080                                    |
|  - Result UI: http://localhost:31000                                    |
+-------------------+---------------------------------+-------------------+
                    | NodePort: 31080                 | NodePort: 31000
                    v                                 v
+-------------------------------------------------------------------------+
| KUBERNETES CLUSTER (Namespace: voting-app)                             |
|                                                                         |
|  [Service: vote-service]                       [Service: result-service]|
|  Type: NodePort (Port 80 -> 5000)              Type: NodePort (3000)    |
|         |                                               |               |
|         v                                               v               |
|  [Deployment: vote-app]                        [Deployment: result-app] |
|  Replicas: 2 | Python 3 Flask                  Replicas: 2 | Node.js    |
|         |                                               |               |
|         | writes to redis-service:6379                  | queries       |
|         v                                               | db-service    |
|  [Service: redis-service (ClusterIP: 6379)]             |               |
|         |                                               |               |
|         v                                               |               |
|  [Deployment: redis-app]                                |               |
|  Replicas: 1 | Redis 7                                  |               |
|         ^                                               |               |
|         | polls queue                                   |               |
|  [Deployment: worker-app]                               |               |
|  Replicas: 1 | Node.js Worker                           |               |
|         |                                               |               |
|         | commits to db-service:5432                    |               |
|         v                                               v               |
|  [Service: db-service (ClusterIP: 5432)] <---------------+              |
|         |                                                               |
|         v                                                               |
|  [Deployment: postgres-app]                                             |
|  Replicas: 1 | PostgreSQL 15                                            |
|         |                                                               |
|         v Mounts                                                        |
|  [PersistentVolumeClaim: postgres-pvc (5Gi RWO)]                        |
+-------------------------------------------------------------------------+
```

---

## 3. Configuration Breakdown

### 3.1 Namespace, Config, and Secret Manifest (`00-init.yaml`)

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: voting-app

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: voting-config
  namespace: voting-app
data:
  REDIS_HOST: "redis-service"
  DATABASE_HOST: "db-service"
  DATABASE_NAME: "votes"
  DATABASE_USER: "postgres"
  PORT: "3000"

---
apiVersion: v1
kind: Secret
metadata:
  name: voting-secret
  namespace: voting-app
type: Opaque
stringData:
  DATABASE_PASSWORD: "SuperSecurePostgresPassword123"
```

### 3.2 Data Tier Manifests (`01-data-tier.yaml`)

```yaml
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

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-deployment
  namespace: voting-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
        - name: postgres
          image: postgres:15-alpine
          ports:
            - containerPort: 5432
          env:
            - name: POSTGRES_DB
              valueFrom:
                configMapKeyRef:
                  name: voting-config
                  key: DATABASE_NAME
            - name: POSTGRES_USER
              valueFrom:
                configMapKeyRef:
                  name: voting-config
                  key: DATABASE_USER
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: voting-secret
                  key: DATABASE_PASSWORD
          volumeMounts:
            - name: postgres-data
              mountPath: /var/lib/postgresql/data
      volumes:
        - name: postgres-data
          persistentVolumeClaim:
            claimName: postgres-pvc

---
apiVersion: v1
kind: Service
metadata:
  name: db-service
  namespace: voting-app
spec:
  type: ClusterIP
  ports:
    - port: 5432
      targetPort: 5432
  selector:
    app: postgres

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-deployment
  namespace: voting-app
spec:
  replicas: 1
  selector:
    app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
        - name: redis
          image: redis:7-alpine
          ports:
            - containerPort: 6379

---
apiVersion: v1
kind: Service
metadata:
  name: redis-service
  namespace: voting-app
spec:
  type: ClusterIP
  ports:
    - port: 6379
      targetPort: 6379
  selector:
    app: redis
```

### 3.3 Application Tier Manifests (`02-app-tier.yaml`)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vote-deployment
  namespace: voting-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: vote
  template:
    metadata:
      labels:
        app: vote
    spec:
      containers:
        - name: vote
          image: roxsross/votingapp-vote:v1
          ports:
            - containerPort: 5000
          env:
            - name: REDIS_HOST
              valueFrom:
                configMapKeyRef:
                  name: voting-config
                  key: REDIS_HOST

---
apiVersion: v1
kind: Service
metadata:
  name: vote-service
  namespace: voting-app
spec:
  type: NodePort
  ports:
    - port: 80
      targetPort: 5000
      nodePort: 31080
  selector:
    app: vote

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: worker-deployment
  namespace: voting-app
spec:
  replicas: 1
  selector:
    app: worker
  template:
    metadata:
      labels:
        app: worker
    spec:
      containers:
        - name: worker
          image: roxsross/votingapp-worker:v1
          env:
            - name: REDIS_HOST
              valueFrom:
                configMapKeyRef:
                  name: voting-config
                  key: REDIS_HOST
            - name: DATABASE_HOST
              valueFrom:
                configMapKeyRef:
                  name: voting-config
                  key: DATABASE_HOST
            - name: DATABASE_NAME
              valueFrom:
                configMapKeyRef:
                  name: voting-config
                  key: DATABASE_NAME
            - name: DATABASE_USER
              valueFrom:
                configMapKeyRef:
                  name: voting-config
                  key: DATABASE_USER
            - name: DATABASE_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: voting-secret
                  key: DATABASE_PASSWORD

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: result-deployment
  namespace: voting-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: result
  template:
    metadata:
      labels:
        app: result
    spec:
      containers:
        - name: result
          image: roxsross/votingapp-result:v1
          ports:
            - containerPort: 3000
          env:
            - name: DATABASE_HOST
              valueFrom:
                configMapKeyRef:
                  name: voting-config
                  key: DATABASE_HOST
            - name: DATABASE_NAME
              valueFrom:
                configMapKeyRef:
                  name: voting-config
                  key: DATABASE_NAME
            - name: DATABASE_USER
              valueFrom:
                configMapKeyRef:
                  name: voting-config
                  key: DATABASE_USER
            - name: DATABASE_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: voting-secret
                  key: DATABASE_PASSWORD

---
apiVersion: v1
kind: Service
metadata:
  name: result-service
  namespace: voting-app
spec:
  type: NodePort
  ports:
    - port: 3000
      targetPort: 3000
      nodePort: 31000
  selector:
    app: result
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# Navigate to Semana 5 workspace
cd /home/david/git/devops-porfolio/daily-exercises/semana-5

# 1. Deploy the complete Kubernetes stack in order
kubectl apply -f dia-35/00-init.yaml 2>/dev/null || kubectl apply -f - <<EOF
# (Apply manifests declared above)
EOF

# 2. Monitor pod rollout across the voting-app namespace
kubectl get pods -n voting-app -w

# 3. Verify all services and endpoints are active
kubectl get svc -n voting-app
kubectl get endpoints -n voting-app
```

---

## 5. Real-World Verification Methods

```bash
# 1. Test HTTP connectivity to Vote frontend
curl -sI http://localhost:31080 | head -n 5

# 2. Test HTTP connectivity to Result frontend
curl -sI http://localhost:31000 | head -n 5

# 3. Post a simulated vote via curl
curl -s -X POST -d "vote=a" http://localhost:31080/

# 4. Inspect worker processing logs
kubectl logs -n voting-app -l app=worker --tail=20

# 5. Query PostgreSQL database directly to confirm persisted vote
kubectl exec -it -n voting-app deployment/postgres-deployment -- \
  psql -U postgres -d votes -c "SELECT vote, count(vote) FROM votes GROUP BY vote;"
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **Service Discovery Across Namespaces**:
   - Issue: When services are in different namespaces, short names (`redis-service`) fail to resolve.
   - Solution: Use the FQDN: `redis-service.<namespace>.svc.cluster.local`. Keeping all interconnected microservices within a dedicated unified namespace (`voting-app`) simplifies DNS discovery.

2. **Database Startup Sequencing**:
   - Issue: The `worker` pod enters `CrashLoopBackOff` if it attempts database connection before PostgreSQL is accepting connections.
   - Solution: Configure restart policies (`restartPolicy: Always`), utilize readiness probes, or add initContainers that run `pg_isready` before launching the main worker process.

3. **Horizontal Pod Autoscaling Prerequisites**:
   - Lesson: Deployments cannot be autoscaled based on CPU/memory unless container specs declare explicit `resources.requests`. Always define requests to enable the scheduler and HPA to make accurate allocation decisions.
