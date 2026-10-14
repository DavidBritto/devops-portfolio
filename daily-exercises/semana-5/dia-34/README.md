# Dia 34: Kubernetes Configuration and Storage - ConfigMaps, Secrets, PVs, and PVCs

## 1. Technical Overview and Objective

The objective of Day 34 is to decouple configuration and stateful data from containerized application runtimes in Kubernetes. Hardcoding configuration parameters or secrets into container images violates 12-factor application methodology and creates critical security vulnerabilities. Similarly, storing state directly in container filesystems causes immediate data loss when pods restart. Kubernetes provides declarative primitives to inject configuration (`ConfigMap`), encrypt and mount credentials (`Secret`), and abstract physical storage lifecycle from application pods (`PersistentVolume` and `PersistentVolumeClaim`).

Key goals:
- Externalize configuration using `ConfigMap` objects (env vars, envFrom, mounted config files).
- Secure sensitive credentials using base64-encoded Kubernetes `Secret` objects.
- Understand storage decoupling: StorageClass -> PersistentVolume (PV) -> PersistentVolumeClaim (PVC).
- Configure stateful storage volumes with `ReadWriteOnce` access mode for PostgreSQL.
- Validate data persistence across pod termination and rescheduling events.

---

## 2. Architecture and Storage Decoupling Breakdown

### 2.1 Storage Lifecycle and Binding Flow

```
+-------------------------------------------------------------------------+
| STORAGE ABSTRACTION LAYER                                               |
|                                                                         |
|  [StorageClass: standard / local-path]                                  |
|         |                                                               |
|         v (Dynamic Provisioning or Pre-provisioned)                     |
|  [PersistentVolume: pv-postgres-data (Capacity: 5Gi, RWO, hostPath)]    |
|         ^                                                               |
|         | (Bound via Capacity & Access Mode matching)                   |
|  [PersistentVolumeClaim: postgres-pvc (Requested: 5Gi, RWO)]            |
+---------+---------------------------------------------------------------+
          |
          v (Mounted via volumeMounts at /var/lib/postgresql/data)
+---------+---------------------------------------------------------------+
| POD: postgres-db-0                                                      |
|                                                                         |
|  [Env From ConfigMap: postgres-config] -> POSTGRES_DB: votes            |
|  [Env From Secret: postgres-secret]   -> POSTGRES_PASSWORD: secret      |
|  [Container: postgres:15-alpine]                                        |
+-------------------------------------------------------------------------+
```

---

## 3. Configuration Breakdown

### 3.1 Declarative Configuration & Secrets Manifest (`config-secrets.yaml`)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-config
  namespace: development
data:
  POSTGRES_DB: "votes"
  POSTGRES_USER: "postgres"
  PGPORT: "5432"

---
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
  namespace: development
type: Opaque
stringData:
  POSTGRES_PASSWORD: "SuperSecurePostgresPassword123"
```

### 3.2 Declarative Storage & Stateful Pod Manifest (`storage-postgres.yaml`)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: development
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-deployment
  namespace: development
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
          envFrom:
            - configMapRef:
                name: postgres-config
            - secretRef:
                name: postgres-secret
          volumeMounts:
            - name: postgres-storage
              mountPath: /var/lib/postgresql/data
              subPath: pgdata
      volumes:
        - name: postgres-storage
          persistentVolumeClaim:
            claimName: postgres-pvc
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# 1. Apply ConfigMaps and Secrets
kubectl apply -f config-secrets.yaml

# 2. Inspect created ConfigMaps and Secrets
kubectl get configmap -n development
kubectl get secret -n development

# 3. Apply Storage Claim and Postgres Deployment
kubectl apply -f storage-postgres.yaml

# 4. Verify PVC status transitioned to 'Bound'
kubectl get pvc -n development

# 5. Verify the Pod has successfully attached the volume
kubectl describe pod -n development -l app=postgres | grep -A 5 Mounts
```

---

## 5. Real-World Verification Methods

```bash
# 1. Connect to PostgreSQL and create a test table with records
kubectl exec -it -n development deployment/postgres-deployment -- psql -U postgres -d votes -c \
  "CREATE TABLE test_persistence (id SERIAL PRIMARY KEY, note VARCHAR(50)); INSERT INTO test_persistence (note) VALUES ('data survived pod restart');"

# 2. Force delete the Postgres pod to test recovery and persistence
kubectl delete pod -n development -l app=postgres

# 3. Wait for Deployment controller to spin up replacement pod
kubectl rollout status deployment/postgres-deployment -n development

# 4. Query the newly spawned pod to confirm data survived intact
kubectl exec -it -n development deployment/postgres-deployment -- psql -U postgres -d votes -c \
  "SELECT * FROM test_persistence;"
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **PVC Stuck in `Pending` Status**:
   - Cause: No available PersistentVolume matches the requested storage size or access mode, or no dynamic provisioner (StorageClass) is marked default.
   - Diagnosis: Run `kubectl describe pvc <claim-name>` and check `Events`. Look for `no persistent volumes available for this claim and no storage class is set`.
   - Resolution: Deploy a default StorageClass (e.g. `rancher/local-path-provisioner` in Kind/bare-metal).

2. **Base64 Encoding vs Plaintext in Secrets**:
   - `Secret.data` requires base64-encoded strings: `echo -n 'password' | base64`.
   - Using `Secret.stringData` allows entering plaintext in YAML; Kubernetes automatically encodes it to base64 upon admission.
   - Note: Standard Kubernetes Secrets are only base64-encoded, not encrypted at rest by default. Production clusters require KMS envelope encryption or HashiCorp Vault integration.

3. **Multi-Pod Access Mode Conflicts (`ReadWriteOnce`)**:
   - Issue: When scaling a Stateful Deployment with RWO PVC to multiple replicas, new pods fail to mount the volume.
   - Reason: `ReadWriteOnce` means the volume can be mounted as read-write by a single node only.
   - Solution: Use `StatefulSet` with `volumeClaimTemplates` to allocate an independent PVC per replica.
