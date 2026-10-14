# Dia 42: Final Challenge Week 6 - Umbrella Helm Chart Packaging and Multi-Tier Orchestration for Roxs Voting App

## 1. Technical Overview and Objective

The objective of Day 42 is the complete packaging and deployment of the Roxs Voting App microservices architecture using an enterprise Umbrella Helm Chart. Moving beyond fragmented YAML files, this capstone challenge structures the entire 5-tier application (Vote frontend, Result dashboard, Worker processor, Redis cache, and PostgreSQL database) into a unified, version-controlled Helm chart. The deployment features dynamic parameterization for multi-environment promotion (Dev, Staging, Production), automated dependency management, health probes, and Ingress routing.

Key goals:
- Architect an Umbrella Helm Chart (`roxs-voting-app`) orchestrating all 5 microservices and dependent data stores.
- Externalize environment configurations into dedicated value files (`values-dev.yaml`, `values-prod.yaml`).
- Implement zero-downtime rolling updates and liveness/readiness probes across all application components.
- Configure Ingress resource routing for Vote and Result services with TLS readiness.
- Deploy, upgrade, and validate end-to-end voting transactions with a single Helm command.

---

## 2. Architecture and Umbrella Chart Topology Breakdown

### 2.1 Umbrella Chart Architecture

```
roxs-voting-app-chart/
├── Chart.yaml              # Chart metadata (version: 1.0.0, type: application)
├── values.yaml             # Base / default values
├── values-dev.yaml         # Lightweight development overrides
├── values-prod.yaml        # Production overrides (HA replicas, limits, Ingress)
└── templates/
    ├── _helpers.tpl        # Common naming and label templates
    ├── vote-deployment.yaml
    ├── vote-service.yaml
    ├── result-deployment.yaml
    ├── result-service.yaml
    ├── worker-deployment.yaml
    ├── redis-deployment.yaml
    ├── redis-service.yaml
    ├── postgres-deployment.yaml
    ├── postgres-service.yaml
    ├── postgres-pvc.yaml
    ├── configmap.yaml
    ├── secret.yaml
    └── ingress.yaml
```

### 2.2 Workload Dependency and Routing Architecture

```
+-------------------------------------------------------------------------+
| INGRESS CONTROLLER (Routing via Host / Paths)                           |
|  - vote.local   -> vote-service:80   -> vote pods (Python Flask)        |
|  - result.local -> result-service:80 -> result pods (Node.js)           |
+--------------------+--------------------------------+-------------------+
                     |                                |
                     v (Writes votes)                 v (Reads counts)
         +-----------------------+        +-----------------------+
         | redis-service:6379    |        | db-service:5432       |
         | (Redis 7 In-Memory)   |        | (PostgreSQL 15 PVC)   |
         +-----------^-----------+        +-----------^-----------+
                     |                                |
                     | (Polls queue)                  | (Commits votes)
                     +----------+          +----------+
                                |          |
                         +------+----------+------+
                         | worker pod (Node.js)   |
                         +------------------------+
```

---

## 3. Configuration Breakdown

### 3.1 Umbrella Chart Metadata (`Chart.yaml`)

```yaml
apiVersion: v2
name: roxs-voting-app
description: Umbrella Helm chart orchestrating the distributed Roxs Voting App microservices
type: application
version: 1.0.0
appVersion: "1.0.0"
maintainers:
  - name: DevOps Engineering Team
```

### 3.2 Production Values Configuration (`values-prod.yaml`)

```yaml
global:
  environment: production

vote:
  replicaCount: 3
  image:
    repository: roxsross/votingapp-vote
    tag: "v1"
  resources:
    limits: { cpu: "300m", memory: "256Mi" }
    requests: { cpu: "100m", memory: "128Mi" }

result:
  replicaCount: 2
  image:
    repository: roxsross/votingapp-result
    tag: "v1"
  resources:
    limits: { cpu: "300m", memory: "256Mi" }
    requests: { cpu: "100m", memory: "128Mi" }

worker:
  replicaCount: 2
  image:
    repository: roxsross/votingapp-worker
    tag: "v1"

redis:
  image: "redis:7-alpine"

postgres:
  image: "postgres:15-alpine"
  storage:
    size: 10Gi
    accessMode: ReadWriteOnce
  credentials:
    user: "postgres"
    database: "votes"

ingress:
  enabled: true
  className: "nginx"
  hosts:
    vote: "vote.production.local"
    result: "result.production.local"
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# Navigate to Semana 6 challenge directory
cd /home/david/git/devops-porfolio/daily-exercises/semana-6/dia-42

# 1. Lint chart templates and schema
helm lint ./roxs-voting-app-chart

# 2. Render templates locally to verify manifest output
helm template voting-stack ./roxs-voting-app-chart -f ./roxs-voting-app-chart/values-prod.yaml > rendered-manifests.yaml

# 3. Deploy the full production stack atomically
helm upgrade --install voting-stack ./roxs-voting-app-chart \
  --namespace production \
  --create-namespace \
  -f ./roxs-voting-app-chart/values-prod.yaml \
  --atomic \
  --timeout 5m

# 4. Verify release status and tracked revisions
helm status voting-stack -n production
helm history voting-stack -n production
```

---

## 5. Real-World Verification Methods

```bash
# 1. Verify all pods are running and ready across the production namespace
kubectl get pods -n production -o wide

# 2. Verify PersistentVolumeClaim is bound to persistent disk
kubectl get pvc -n production

# 3. Submit a vote through the Vote service
curl -s -X POST -d "vote=a" -H "Host: vote.production.local" http://localhost:8080/

# 4. Query PostgreSQL database directly to verify worker processing
kubectl exec -it -n production deployment/voting-stack-postgres -- \
  psql -U postgres -d votes -c "SELECT vote, count(vote) FROM votes GROUP BY vote;"

# 5. Test automated zero-downtime Helm rollback
helm rollback voting-stack 1 -n production
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **Subchart and Umbrella Value Scoping**:
   - Issue: Parameter values specified in `values.yaml` do not reach nested components.
   - Solution: In Helm umbrella charts, child values must be nested under the subchart or component key (e.g. `vote: ...`, `postgres: ...`). Global variables shared across all templates must be declared under `global:`.

2. **Helm `--atomic` Flag Benefits**:
   - Issue: A broken container tag or configuration error leaves the cluster in an inconsistent state where some services upgraded and others failed.
   - Solution: Always run `helm upgrade --install --atomic`. If any pod fails readiness probes before `--timeout` expires, Helm automatically triggers a complete rollback to the previous operational release.

3. **Database Schema Initialization in Helm Releases**:
   - Lesson: Running relational database schema migrations inside application pods causes race conditions when multiple replicas start concurrently. Implement database schema migrations using a Helm `post-install` / `pre-upgrade` Kubernetes Job hook (`helm.sh/hook: post-install`).
