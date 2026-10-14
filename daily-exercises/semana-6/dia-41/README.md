# Dia 41: Production Kubernetes Engineering - Ingress Controllers, TLS, PDBs, and Network Security

## 1. Technical Overview and Objective

The objective of Day 41 is to transform standard Kubernetes deployments into hardened, production-ready systems. Running workloads in production requires routing external HTTPS traffic through an Ingress Controller, automating TLS certificate issuance via `cert-manager`, guaranteeing service availability during node drains using Pod Disruption Budgets (`PodDisruptionBudget`), and enforcing zero-trust network boundaries via `NetworkPolicy`.

Key goals:
- Deploy and configure an Nginx Ingress Controller for Layer 7 reverse-proxying.
- Implement automated TLS termination using `cert-manager` and ACME / self-signed ClusterIssuers.
- Enforce high availability during maintenance windows using `PodDisruptionBudget` (PDB).
- Configure `HorizontalPodAutoscaler` (HPA v2) based on real-time CPU and memory metrics.
- Implement zero-trust firewall isolation using declarative `NetworkPolicy` rules.

---

## 2. Architecture and Production Traffic Flow

### 2.1 Layer 7 Ingress and Security Architecture

```
+-------------------------------------------------------------------------+
| EXTERNAL CLIENT (HTTPS Request: https://vote.company.com)               |
+------------------------------------+------------------------------------+
                                     | Port 443 / TLS Termination
                                     v
+-------------------------------------------------------------------------+
| INGRESS CONTROLLER (Ingress-Nginx in namespace: ingress-nginx)          |
|  - TLS Secret: vote-tls-cert (Managed by cert-manager)                  |
|  - Layer 7 Host Routing: vote.company.com                               |
|  - Rate Limiting & SSL Offloading                                       |
+------------------------------------+------------------------------------+
                                     | Internal ClusterIP Routing
                                     v
+-------------------------------------------------------------------------+
| APPLICATION NAMESPACE (Namespace: production)                           |
|                                                                         |
|  [NetworkPolicy: default-deny-all] (Blocks all unauthorized traffic)    |
|                                                                         |
|  [NetworkPolicy: allow-ingress-to-vote]                                 |
|         |                                                               |
|         v                                                               |
|  [Service: vote-service:80]                                             |
|         |                                                               |
|         v                                                               |
|  [Pods: vote-app (HPA Scaled: 2 -> 10 replicas)]                        |
|  [PodDisruptionBudget: minAvailable: 1]                                 |
+-------------------------------------------------------------------------+
```

---

## 3. Configuration Breakdown

### 3.1 Production Ingress and TLS Manifest (`ingress-production.yaml`)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: vote-ingress
  namespace: production
  annotations:
    kubernetes.io/ingress.class: "nginx"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"
spec:
  tls:
    - hosts:
        - vote.company.com
      secretName: vote-tls-secret
  rules:
    - host: vote.company.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: vote-service
                port:
                  number: 80
```

### 3.2 High Availability and Scaling Manifests (`ha-and-security.yaml`)

```yaml
# 1. Pod Disruption Budget: Ensures at least 1 replica is alive during cluster drain
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: vote-pdb
  namespace: production
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: vote

---
# 2. Horizontal Pod Autoscaler: Dynamic elastic scaling
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: vote-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: vote-deployment
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80

---
# 3. Network Policy: Restricts ingress traffic to Vote app from Ingress Controller only
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-to-vote
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: vote
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: ingress-nginx
      ports:
        - protocol: TCP
          port: 5000
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# 1. Install Ingress-Nginx Controller on cluster
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# 2. Wait for ingress-nginx controller to be operational
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# 3. Apply production manifests (Ingress, PDB, HPA, NetworkPolicy)
kubectl apply -f ingress-production.yaml
kubectl apply -f ha-and-security.yaml

# 4. Inspect HPA targets and metrics
kubectl get hpa -n production

# 5. Inspect PodDisruptionBudget status
kubectl get pdb -n production
```

---

## 6. Real-World Verification Methods

```bash
# 1. Test Ingress routing locally via Host header injection
curl -k -H "Host: vote.company.com" https://localhost:8443/

# 2. Verify PodDisruptionBudget by attempting a simulated node drain
kubectl drain kind-worker --ignore-daemonsets --delete-emptydir-data --dry-run=client

# 3. Verify NetworkPolicy isolation:
# Launch a rogue pod in default namespace and verify connection to Vote pod is blocked
kubectl run rogue-tester --image=busybox -it --rm --restart=Never -- nc -z -w 3 vote-service.production 80 || echo "Traffic successfully blocked by NetworkPolicy"
```

---

## 7. Troubleshooting Takeaways and Lessons Learned

1. **HPA Unknown Metrics (`<unknown>/70%`)**:
   - Cause: `metrics-server` is either not running or pods lack `resources.requests.cpu`.
   - Solution: Deploy `metrics-server` with `--kubelet-insecure-tls` for local clusters, and ensure every container defines explicit CPU requests.

2. **Drain Deadlocks Due to Overly Strict PDBs**:
   - Issue: `kubectl drain` hangs indefinitely waiting for pods to terminate.
   - Cause: A Deployment with `replicas: 1` and `minAvailable: 1` can never be drained without violating its PDB.
   - Solution: Always run at least 2 replicas in production workloads protected by a PDB with `minAvailable: 1` or use `maxUnavailable: 1`.

3. **Ingress 404 Not Found vs 503 Service Unavailable**:
   - `404`: The Ingress controller did not match the `Host` or `path` rule.
   - `503`: The rule matched, but the backing Service has zero healthy endpoints (pods failed readiness checks).
