# Dia 31: Kubernetes Pods - Atomic Workload Units, Lifecycle States, and Multi-Container Patterns

## 1. Technical Overview and Objective

The objective of Day 31 is to master the fundamental deployable execution unit in Kubernetes: the Pod. A Pod represents a group of one or more co-located containers that share storage volumes, an IP address, and an IPC namespace. Understanding the Pod lifecycle, container initialization sequences, resource allocation contracts (requests vs limits), and multi-container design patterns (sidecar, adapter, init container) is crucial for building resilient, observable applications.

Key goals:
- Understand the Pod anatomy and IPC/network namespace sharing mechanisms.
- Master Pod lifecycle phases: `Pending`, `Running`, `Succeeded`, `Failed`, and `Unknown`.
- Implement `initContainers` to enforce database pre-flight checks and configuration priming.
- Deploy the Sidecar pattern for log forwarding and metrics collection.
- Define container resource contracts: `requests` (for scheduling guarantees) and `limits` (for cgroup enforcement).

---

## 2. Architecture and Pod Patterns Breakdown

### 2.1 Pod Shared Namespace Topology

```
+-------------------------------------------------------------------------+
| POD (IP: 10.244.1.25)                                                   |
| Shared Network Namespace (veth) + Shared IPC + Shared IPC/UTS           |
|                                                                         |
|  +----------------------------------+  +-----------------------------+  |
|  | Main Application Container       |  | Sidecar Log Shipper         |  |
|  | Image: python:3.11-alpine        |  | Image: busybox:latest       |  |
|  | Process: flask run               |  | Process: tail -f /logs/app  |  |
|  | Port: 5000 (localhost:5000)      |  | Reads shared volume         |  |
|  +-----------------+----------------+  +--------------+--------------+  |
|                    |                                  |                 |
|                    +----------------+-----------------+                 |
|                                     |                                   |
|                                     v Mount Point: /var/log/app         |
|  +-------------------------------------------------------------------+  |
|  | SHARED VOLUME (emptyDir)                                          |  |
|  +-------------------------------------------------------------------+  |
+-------------------------------------------------------------------------+
```

### 2.2 Pod Phase Transition State Machine

```
[kubectl apply]
       |
       v
   [Pending] --------> Waiting for scheduling or image download
       |
       v
 [InitContainers] ---> Execute sequentially to completion (0 errors)
       |
       v
   [Running] --------> All containers spawned and at least one active
       |
       +---> [Succeeded] --------> Containers completed task with exit code 0
       |
       +---> [Failed] -----------> Container exited with error (CrashLoopBackOff)
```

---

## 3. Configuration Breakdown

### 3.1 Declarative Pod Specification with Init Container (`pod-advanced.yaml`)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: vote-service-pod
  namespace: development
  labels:
    app: vote
    tier: frontend
spec:
  # Init container waits for Redis cache readiness before starting app
  initContainers:
    - name: wait-for-cache
      image: busybox:1.36
      command: ['sh', '-c', 'until nc -z -w 2 redis-service 6379; do echo waiting for redis...; sleep 2; done;']

  containers:
    - name: vote-app
      image: roxsross/votingapp-vote:v1
      ports:
        - containerPort: 5000
          name: http
      resources:
        requests:
          cpu: "100m"
          memory: "128Mi"
        limits:
          cpu: "250m"
          memory: "256Mi"
      volumeMounts:
        - name: app-logs
          mountPath: /var/log/vote

    # Sidecar container processing application logs
    - name: log-collector
      image: busybox:1.36
      command: ['sh', '-c', 'tail -F /var/log/vote/app.log 2>/dev/null || sleep infinity']
      volumeMounts:
        - name: app-logs
          mountPath: /var/log/vote

  volumes:
    - name: app-logs
      emptyDir: {}
  restartPolicy: OnFailure
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# 1. Apply the Pod specification
kubectl apply -f pod-advanced.yaml

# 2. Monitor Pod status and initialization phases in real-time
kubectl get pod vote-service-pod -w

# 3. View logs of specific container inside multi-container Pod
kubectl logs vote-service-pod -c wait-for-cache
kubectl logs vote-service-pod -c vote-app

# 4. Execute an interactive shell inside a specific container
kubectl exec -it vote-service-pod -c vote-app -- /bin/sh

# 5. Delete the Pod
kubectl delete pod vote-service-pod
```

---

## 5. Real-World Verification Methods

```bash
# 1. Inspect low-level Pod conditions and lifecycle events
kubectl describe pod vote-service-pod

# 2. Verify resource consumption against defined limits
kubectl top pod vote-service-pod --containers 2>/dev/null || echo "metrics-server required"

# 3. Check container termination reasons
kubectl get pod vote-service-pod -o jsonpath='{.status.containerStatuses[*].state}'
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **CrashLoopBackOff Diagnosis**:
   - Cause: The container process terminates with non-zero exit code immediately after starting. Kubelet restarts it with exponential backoff (10s, 20s, 40s... up to 5m).
   - Diagnosis: Run `kubectl logs <pod-name> --previous` to inspect logs emitted by the terminated container prior to restart.

2. **OOMKilled (Exit Code 137)**:
   - Cause: Container memory consumption exceeded the hard boundary configured in `resources.limits.memory`. The Linux kernel OOM Killer immediately kills the process.
   - Diagnosis: `kubectl describe pod <name>` displays `Last State: Terminated, Reason: OOMKilled`.
   - Solution: Profile heap memory and elevate the `limits.memory` threshold.

3. **InitContainer Deadlocks**:
   - Cause: The init container waits indefinitely for a dependent service (e.g. database) that has not been deployed yet.
   - Solution: Set active deadlines or timeout mechanisms on init scripts (`timeout 30 sh -c ...`) to prevent blocking entire rollouts.
