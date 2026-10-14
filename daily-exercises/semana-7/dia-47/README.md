# Dia 47: Kubernetes Role-Based Access Control (RBAC) and ServiceAccount Governance

## 1. Technical Overview and Objective

The objective of Day 47 is to implement fine-grained access control across the Kubernetes cluster using Role-Based Access Control (RBAC). Default Kubernetes setups grant overly permissive access or leave workloads using the default ServiceAccount. If an application with access to the Kubernetes API is compromised, an attacker can enumerate secrets, spawn privileged pods, and compromise the entire cluster. RBAC enforces least privilege by strictly scoping what API resources (`pods`, `deployments`, `secrets`) and verbs (`get`, `list`, `create`, `delete`) subjects can perform.

Key goals:
- Understand the core RBAC primitives: `ServiceAccount`, `Role`, `RoleBinding`, `ClusterRole`, and `ClusterRoleBinding`.
- Differentiate between namespace-scoped and cluster-scoped access boundaries.
- Create a dedicated `ServiceAccount` and scoped `Role` for a CI/CD deployment agent.
- Audit and verify permissions using `kubectl auth can-i`.
- Prevent privilege escalation via `bind` and `escalate` verb restrictions.

---

## 2. Architecture and RBAC Authorization Matrix

### 2.1 RBAC Entity Relationship Topology

```
+-------------------------------------------------------------------------+
| SUBJECTS (WHO?)                                                         |
|  - ServiceAccount (cicd-deployer in ns: production)                     |
|  - Human User / Group (OIDC: devops-engineers)                          |
+-------------------+---------------------------------+-------------------+
                    |                                 |
                    v Bound via                       v Bound via
+-------------------+---------------+   +-------------+-------------------+
| RoleBinding                       |   | ClusterRoleBinding              |
| (Namespace Scoped: production)    |   | (Cluster Scoped)                |
+-------------------+---------------+   +-------------+-------------------+
                    | References                      | References
                    v                                 v
+-------------------+---------------+   +-------------+-------------------+
| Role: app-deployer                |   | ClusterRole: cluster-reader     |
| apiGroups: ["apps"]               |   | apiGroups: ["*"]                |
| resources: ["deployments"]        |   | resources: ["nodes", "pvs"]     |
| verbs: ["get", "update", "patch"] |   | verbs: ["get", "list", "watch"] |
+-----------------------------------+   +---------------------------------+
```

---

## 3. Configuration Breakdown

### 3.1 Declarative Scoped RBAC Manifest (`cicd-rbac.yaml`)

```yaml
# 1. Dedicated ServiceAccount
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cicd-deployer
  namespace: production
automountServiceAccountToken: true

---
# 2. Namespace-Scoped Role with strictly limited privileges
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deployer-role
  namespace: production
rules:
  - apiGroups: ["apps"]
    resources: ["deployments", "replicasets"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
  - apiGroups: [""]
    resources: ["services", "configmaps"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
  - apiGroups: [""]
    resources: ["pods", "pods/log"]
    verbs: ["get", "list", "watch"]
  # Explicitly disallow access to Secrets and cluster-level nodes

---
# 3. RoleBinding connecting ServiceAccount to Role
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: bind-cicd-deployer
  namespace: production
subjects:
  - kind: ServiceAccount
    name: cicd-deployer
    namespace: production
roleRef:
  kind: Role
  name: deployer-role
  apiGroup: rbac.authorization.k8s.io
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# 1. Ensure production namespace exists
kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -

# 2. Apply RBAC definitions
kubectl apply -f cicd-rbac.yaml

# 3. Verify created resources
kubectl get sa -n production
kubectl get role -n production
kubectl get rolebinding -n production
```

---

## 5. Real-World Verification Methods

```bash
# 1. Test allowed permissions as cicd-deployer ServiceAccount
kubectl auth can-i create deployments \
  --as=system:serviceaccount:production:cicd-deployer \
  -n production
# Output: yes

kubectl auth can-i get pods \
  --as=system:serviceaccount:production:cicd-deployer \
  -n production
# Output: yes

# 2. Test forbidden permissions: Verify deployer CANNOT read Secrets
kubectl auth can-i get secrets \
  --as=system:serviceaccount:production:cicd-deployer \
  -n production
# Output: no

# 3. Test namespace containment: Verify deployer CANNOT access other namespaces
kubectl auth can-i get pods \
  --as=system:serviceaccount:production:cicd-deployer \
  -n kube-system
# Output: no
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **The `cluster-admin` Anti-Pattern**:
   - Issue: Granting `cluster-admin` to automation tools or third-party Helm charts because creating tailored RBAC manifests takes time.
   - Danger: Compromising a single deployment token grants full administrative control over every node and secret across the entire cluster.
   - Rule: Never bind `cluster-admin` to service accounts used by application pods or external CI runners.

2. **`automountServiceAccountToken: false` for Workloads**:
   - Issue: Application pods that do not communicate with the Kubernetes API still have a valid ServiceAccount JWT mounted at `/var/run/secrets/kubernetes.io/serviceaccount/token`.
   - Solution: Set `automountServiceAccountToken: false` in the Pod spec to prevent token harvesting in case of application remote code execution (RCE).

3. **API Groups Specification**:
   - Issue: Defining `resources: ["deployments"]` under `apiGroups: [""]` results in authorization errors.
   - Reason: Core resources (`pods`, `services`) belong to the empty API group `""`. Workload resources (`deployments`, `statefulsets`) belong to `apps`. Batch jobs belong to `batch`. Ensure the correct `apiGroups` are mapped.
