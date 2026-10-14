# Dia 32: Kubernetes Deployments and ReplicaSets - Reconciliation, Scaling, and Zero-Downtime Rollouts

## 1. Technical Overview and Objective

The objective of Day 32 is to master declarative workload orchestration using Kubernetes Deployments and ReplicaSets. Directly creating individual Pods in production is an anti-pattern because individual pods do not self-heal, scale horizontally, or support zero-downtime rolling upgrades. A Deployment manages an underlying ReplicaSet to maintain the desired number of Pod replicas, executing rolling updates and instant rollbacks via revision history.

Key goals:
- Understand the reconciliation control loop managed by the Deployment and ReplicaSet controllers.
- Implement declarative horizontal scaling (scaling up and down).
- Configure Zero-Downtime Rolling Updates using `maxSurge` and `maxUnavailable` parameters.
- Track deployment revision history and execute automated rollbacks (`rollout undo`).
- Validate rolling update behavior without application downtime.

---

## 2. Architecture and Rolling Update Workflow Breakdown

### 2.1 Deployment Hierarchy: Deployment -> ReplicaSet -> Pods

```
+-------------------------------------------------------------------------+
| KUBERNETES DEPLOYMENT: vote-deployment (spec.replicas: 3)               |
+------------------------------------+------------------------------------+
                                     |
                                     v
+-------------------------------------------------------------------------+
| REPLICASET v1 (active: 3 pods)     | REPLICASET v2 (new rollout: 0->3)  |
| Pod-Template-Hash: 7b84f98d7       | Pod-Template-Hash: 54b8d9fc6       |
|                                    |                                    |
| [Pod v1]  [Pod v1]  [Pod v1]       | [Pod v2]  [Pod v2]  [Pod v2]       |
+------------------------------------+------------------------------------+
```

### 2.2 Rolling Update Progression (`maxSurge: 1`, `maxUnavailable: 0`)

```
Step 1: Current state: 3 Pods running on ReplicaSet v1.
Step 2: Trigger update: Image changed to v2.
Step 3: RS v2 creates 1 Pod (Total pods = 4, respect maxSurge: 1).
Step 4: Pod v2 becomes Ready via readiness probe.
Step 5: RS v1 terminates 1 Pod (Total pods = 3, respect maxUnavailable: 0).
Step 6: Repeat until RS v2 has 3 active pods and RS v1 has 0 active pods.
Step 7: RS v1 is retained in history for fast rollback.
```

---

## 3. Configuration Breakdown

### 3.1 Declarative Deployment Manifest (`deployment.yaml`)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vote-deployment
  namespace: development
  labels:
    app: vote
    tier: frontend
spec:
  replicas: 3
  revisionHistoryLimit: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
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
          image: roxsross/votingapp-vote:v1
          ports:
            - containerPort: 5000
          env:
            - name: REDIS_HOST
              value: "redis-service"
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "250m"
              memory: "256Mi"
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# 1. Apply initial Deployment manifest
kubectl apply -f deployment.yaml

# 2. Check rollout status
kubectl rollout status deployment/vote-deployment -n development

# 3. View the underlying ReplicaSets created by the Deployment
kubectl get replicasets -n development -l app=vote

# 4. Declarative horizontal scaling
kubectl scale deployment/vote-deployment --replicas=5 -n development
kubectl get pods -n development -l app=vote

# 5. Perform a rolling update by updating the container image
kubectl set image deployment/vote-deployment vote=roxsross/votingapp-vote:v2 -n development

# 6. Monitor rollout progress and inspect revision history
kubectl rollout status deployment/vote-deployment -n development
kubectl rollout history deployment/vote-deployment -n development

# 7. Perform an instant rollback to the previous revision
kubectl rollout undo deployment/vote-deployment -n development
```

---

## 5. Real-World Verification Methods

```bash
# 1. Verify zero downtime during update using a continuous curl loop
while true; do
  curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/ || true
  sleep 0.2
done

# 2. Inspect deployment rollout revision annotations
kubectl rollout history deployment/vote-deployment --revision=2 -n development

# 3. Verify labels and selector matching
kubectl get pods --show-labels -n development
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **Selector Immutability**:
   - Issue: Attempting to update `spec.selector.matchLabels` in an existing Deployment returns an API validation error: `field is immutable`.
   - Solution: Deployment label selectors are immutable once created. If selectors must change, delete the Deployment with `--cascade=orphan` and re-apply, or deploy a new Deployment name.

2. **Rollout Stuck Indefinitely (ProgressDeadlineExceeded)**:
   - Issue: Rollout hangs and does not complete within 600s (`progressDeadlineSeconds`).
   - Root Cause: New pods are failing healthchecks, cannot pull the image (`ErrImagePull`), or lack sufficient cluster resources.
   - Diagnosis: Run `kubectl describe deployment <name>` and check `Progressing: False`.
   - Resolution: Abort and rollback immediately: `kubectl rollout undo deployment/<name>`.

3. **`maxUnavailable: 0` vs Cluster Capacity**:
   - Issue: Rolling update cannot proceed when worker nodes are at 100% CPU capacity.
   - Cause: When `maxSurge: 1`, the scheduler cannot place the new surge pod due to lack of schedulable CPU, and cannot kill old pods because `maxUnavailable: 0`.
   - Resolution: Ensure cluster nodes maintain headroom or adjust `maxUnavailable: 25%`.
