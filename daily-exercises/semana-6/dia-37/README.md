# Dia 37: Multi-Environment Kubernetes Architecture with Kustomize Overlays and Resource Quotas

## 1. Technical Overview and Objective

The objective of Day 37 is to establish enterprise multi-environment separation on Kubernetes without duplicating manifest files. Managing distinct environments (Development, Staging, Production) through copied YAML files inevitably causes configuration drift, accidental environment leaks, and maintenance overhead. Using native Kubernetes Kustomize overlays allows engineers to define a common declarative base while injecting environment-specific patches (replica counts, ingress hostnames, resource limits, and secrets) cleanly.

Key goals:
- Structure declarative multi-environment configurations using Kustomize (`base/` and `overlays/`).
- Implement environment isolation via dedicated Namespaces (`voting-dev`, `voting-staging`, `voting-prod`).
- Enforce cluster governance and noisy-neighbor prevention using `ResourceQuota` and `LimitRange` objects.
- Isolate intra-namespace network traffic using `NetworkPolicy`.
- Validate dry-run output of environment overlays (`kubectl kustomize`).

---

## 2. Architecture and Directory Breakdown

### 2.1 Kustomize Architecture Model

```
+-------------------------------------------------------------------------+
| BASE CONFIGURATION (daily-exercises/semana-6/dia-37/k8s/base)          |
|  - deployment.yaml (Generic app definition, 1 replica, container spec)  |
|  - service.yaml    (ClusterIP service definition)                       |
|  - kustomization.yaml                                                   |
+-------------------+---------------------------------+-------------------+
                    |                                 |
                    v                                 v
+-------------------+---------------+   +-------------+-------------------+
| OVERLAY: DEV                      |   | OVERLAY: PROD                   |
| (k8s/overlays/dev)                |   | (k8s/overlays/prod)             |
|  - kustomization.yaml             |   |  - kustomization.yaml           |
|  - replicas: 1                    |   |  - replicas: 5 (High-Avail)     |
|  - namespace: voting-dev          |   |  - namespace: voting-prod       |
|  - resource limits: minimal       |   |  - resource limits: enterprise  |
|  - ingress: dev.voting.local      |   |  - ingress: vote.company.com    |
+-----------------------------------+   +---------------------------------+
```

---

## 3. Configuration Breakdown

### 3.1 Base Kustomization (`k8s/base/kustomization.yaml`)

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml

commonLabels:
  app.kubernetes.io/part-of: roxs-voting-app
```

### 3.2 Production Overlay (`k8s/overlays/prod/kustomization.yaml`)

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: voting-prod

bases:
  - ../../base

namePrefix: prod-

patchesStrategicMerge:
  - replica-patch.yaml
  - resources-patch.yaml

configMapGenerator:
  - name: app-env
    literals:
      - ENVIRONMENT=production
      - LOG_LEVEL=warn
```

### 3.3 Resource Governance Manifest (`k8s/overlays/prod/quota.yaml`)

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: prod-compute-quota
  namespace: voting-prod
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
    pods: "20"
    services.loadbalancers: "2"

---
apiVersion: v1
kind: LimitRange
metadata:
  name: prod-default-limits
  namespace: voting-prod
spec:
  limits:
    - default:
        cpu: "500m"
        memory: "512Mi"
      defaultRequest:
        cpu: "100m"
        memory: "128Mi"
      type: Container
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# Navigate to dia-37 directory
cd /home/david/git/devops-porfolio/daily-exercises/semana-6/dia-37

# 1. Preview generated manifests for DEV without applying
kubectl kustomize k8s/overlays/dev

# 2. Preview generated manifests for PROD
kubectl kustomize k8s/overlays/prod

# 3. Apply DEV environment to the cluster
kubectl apply -k k8s/overlays/dev

# 4. Apply PROD environment to the cluster
kubectl apply -k k8s/overlays/prod

# 5. Inspect resources across both namespaces
kubectl get all -n voting-dev
kubectl get all -n voting-prod
```

---

## 5. Real-World Verification Methods

```bash
# 1. Verify ResourceQuota enforcement in production
kubectl describe resourcequota prod-compute-quota -n voting-prod

# 2. Verify LimitRange default injection
kubectl describe limitrange prod-default-limits -n voting-prod

# 3. Test quota rejection: attempt to create a pod requesting 10 CPU
kubectl run quota-test --image=nginx --requests='cpu=10' -n voting-prod 2>&1 | grep -i "exceeded quota"
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **Missing Resource Requests Under ResourceQuota**:
   - Issue: Once a `ResourceQuota` with CPU/memory constraints is attached to a namespace, any new pod without explicit `requests` or `limits` is rejected immediately by admission control.
   - Solution: Always deploy a `LimitRange` alongside `ResourceQuota`. The LimitRange automatically injects default request and limit values to pods that omit them.

2. **Kustomize Name Prefixing on References**:
   - Issue: When `namePrefix: prod-` is specified, services and deployments get prefixed (`prod-vote-app`), but hardcoded environment variables pointing to `vote-app` fail to resolve in DNS.
   - Solution: Use Kustomize `vars` or `configMapGenerator` to synchronize generated resource names dynamically into dependent containers.

3. **Multi-Tenancy vs Dedicated Clusters**:
   - Lesson: While namespace isolation and ResourceQuotas provide logical multi-tenancy for dev and staging, production workloads with strict compliance and noisy-neighbor isolation requirements should run on dedicated production clusters.
