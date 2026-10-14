# Dia 48: Kubernetes Pod Security Standards (PSS) and SecurityContext Enforcement

## 1. Technical Overview and Objective

The objective of Day 48 is to enforce cluster-wide container workload security policies using Kubernetes native Pod Security Standards (PSS) and Admission Control. With the deprecation of legacy PodSecurityPolicies (PSP), Kubernetes introduced built-in Pod Security Admission (PSA) that enforces three standardized security profiles: **Privileged**, **Baseline**, and **Restricted**. Enforcing PSS prevents developers or rogue processes from deploying containers with host namespace access, root permissions, or unsafe capabilities.

Key goals:
- Understand the three Pod Security Standards levels: Privileged, Baseline, and Restricted.
- Configure Namespace admission labels (`enforce`, `audit`, and `warn`) targeting PSS profiles.
- Craft Kubernetes workloads compliant with the **Restricted** security standard via `securityContext`.
- Test admission controller interception against non-compliant pod definitions.
- Inspect cluster audit logs for PSS violation warnings.

---

## 2. Architecture and Admission Control Flow

### 2.1 Pod Security Standards Hierarchy

```
+-------------------------------------------------------------------------+
| POD SECURITY STANDARDS (PSS) HIERARCHY                                  |
+-------------------------------------------------------------------------+
| PRIVILEGED                                                              |
| - Unrestricted. Used for system daemons (CNI, storage plugins).         |
+------------------------------------+------------------------------------+
                                     v
| BASELINE                                                                |
| - Prevents known privilege escalations. Default out-of-the-box profile. |
| - Blocks hostNetwork, hostPID, hostIPC, privileged containers.          |
+------------------------------------+------------------------------------+
                                     v
| RESTRICTED (HARDENED PRODUCTION)                                        |
| - Follows best-practice container hardening.                            |
| - Requires: runAsNonRoot: true, readOnlyRootFilesystem: true,           |
|   drop ALL capabilities (only allow NET_BIND_SERVICE), no host mounts.  |
+-------------------------------------------------------------------------+
```

### 2.2 Namespace Admission Label Evaluation

```
[kubectl apply pod.yaml in namespace: production]
                     |
                     v
       [kube-apiserver Admission Chain]
                     |
                     v
       [Pod Security Admission Controller]
                     |
                     +---> Check label: pod-security.kubernetes.io/enforce=restricted
                     |
                     +---> Spec violates restricted policy?
                           |
                           +---> YES: REJECT ADMISSION (HTTP 403 Forbidden)
                           |
                           +---> NO:  ADMIT WORKLOAD TO CLUSTER
```

---

## 3. Configuration Breakdown

### 3.1 Hardened Namespace with PSS Labels (`hardened-namespace.yaml`)

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production-secured
  labels:
    pod-security.kubernetes.io/enforce: "restricted"
    pod-security.kubernetes.io/enforce-version: "latest"
    pod-security.kubernetes.io/warn: "restricted"
    pod-security.kubernetes.io/warn-version: "latest"
    pod-security.kubernetes.io/audit: "restricted"
    pod-security.kubernetes.io/audit-version: "latest"
```

### 3.2 Fully Compliant Restricted Workload (`restricted-pod.yaml`)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secured-vote-pod
  namespace: production-secured
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 10001
    runAsGroup: 10001
    fsGroup: 10001
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: vote
      image: roxsross/votingapp-vote:v1
      ports:
        - containerPort: 5000
      securityContext:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        capabilities:
          drop:
            - ALL
      volumeMounts:
        - name: tmp-dir
          mountPath: /tmp
  volumes:
    - name: tmp-dir
      emptyDir: {}
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# 1. Apply secured namespace manifest
kubectl apply -f hardened-namespace.yaml

# 2. Verify namespace labels
kubectl get namespace production-secured --show-labels

# 3. Apply compliant restricted pod
kubectl apply -f restricted-pod.yaml

# 4. Verify pod successfully started
kubectl get pod secured-vote-pod -n production-secured
```

---

## 5. Real-World Verification Methods

```bash
# 1. Test Admission Denial: Attempt to deploy an unhardened root pod into the namespace
kubectl run rogue-pod --image=nginx -n production-secured --dry-run=server 2>&1 | grep -i "violates PodSecurity"
# Expected response: Error from server (Forbidden): ... violates PodSecurity "restricted:latest"

# 2. Inspect seccomp profile enforcement inside running pod
kubectl get pod secured-vote-pod -n production-secured -o jsonpath='{.spec.securityContext.seccompProfile}'
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **Missing `allowPrivilegeEscalation: false`**:
   - Issue: Specifying `runAsNonRoot: true` is not enough to satisfy the `restricted` standard; the pod is still rejected.
   - Requirement: The restricted standard mandates explicit declaration of `securityContext.allowPrivilegeEscalation: false` at the container level.

2. **Seccomp Profile Requirements in Kubernetes 1.25+**:
   - Issue: Pod fails admission under restricted mode with `seccompProfile must be set`.
   - Solution: Include `securityContext.seccompProfile.type: RuntimeDefault` at the Pod or container spec level.

3. **Gradual Migration with `warn` Mode**:
   - Migration Best Practice: When securing existing production clusters, do not set `enforce: restricted` immediately. Set `warn: restricted` and `audit: restricted` first. This displays warnings to developers during deployments and logs violations without disrupting existing running workloads.
