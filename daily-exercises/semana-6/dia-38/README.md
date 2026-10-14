# Dia 38: Kubernetes Health Checks - Liveness, Readiness, Startup Probes, and Graceful Termination

## 1. Technical Overview and Objective

The objective of Day 38 is to implement production-grade pod health monitoring and lifecycle management in Kubernetes. Without properly configured probes, Kubernetes assumes a container is functional as long as its main process is running. However, applications frequently encounter deadlocks, memory leaks, slow cold starts, or loss of database connections while the process continues running. Configuring Liveness, Readiness, and Startup probes ensures automated self-healing and prevents broken pods from receiving production traffic.

Key goals:
- Understand probe mechanisms: `httpGet`, `tcpSocket`, and `exec`.
- Contrast probe responsibilities:
  - **StartupProbe**: Protects slow-starting applications from premature termination.
  - **ReadinessProbe**: Controls inclusion in Service Endpoints (traffic routing).
  - **LivenessProbe**: Detects deadlocks and triggers container restarts via kubelet.
- Configure graceful termination with `preStop` hooks and `terminationGracePeriodSeconds`.
- Validate zero-downtime routing during simulated application failure states.

---

## 2. Architecture and Probe Lifecycle Flow

### 2.1 Pod Probe Execution Sequence

```
[Container Process Spawned]
             |
             v
   [Startup Probe Active]
   - Checks every 'periodSeconds'
   - All other probes disabled during startup
             |
             +---> Fails after failureThreshold? ---> [Kubelet Kills & Restarts Container]
             |
             v (Success)
+-------------------------------------------------------------------------+
| NORMAL OPERATION                                                        |
|                                                                         |
|  [Readiness Probe Loop]                   [Liveness Probe Loop]         |
|  - Queries /health/readiness              - Queries /health/liveness    |
|  - Success -> Endpoint ADDED              - Success -> Do nothing       |
|  - Failure -> Endpoint REMOVED            - Failure -> Kubelet REBOOTS  |
|               (Traffic stopped)                        container        |
+-------------------------------------------------------------------------+
```

### 2.2 Graceful Shutdown Flow (`preStop` Hook)

```
[kubectl delete pod / Rolling Update]
       |
       +---> 1. Endpoint controller removes Pod from Service endpoints (No new requests)
       |
       +---> 2. Kubelet executes 'preStop' lifecycle hook (Drain in-flight requests)
       |
       +---> 3. Kubelet sends SIGTERM to container process (PID 1)
       |
       +---> 4. Wait for application exit or 'terminationGracePeriodSeconds' (default 30s)
       |
       +---> 5. If still alive after timeout -> Kubelet issues SIGKILL (Force exit)
```

---

## 3. Configuration Breakdown

### 3.1 Hardened Pod Manifest with All Three Probes (`hardened-probes.yaml`)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: resilient-vote-service
  namespace: development
spec:
  replicas: 2
  selector:
    matchLabels:
      app: resilient-vote
  template:
    metadata:
      labels:
        app: resilient-vote
    spec:
      terminationGracePeriodSeconds: 45
      containers:
        - name: vote
          image: roxsross/votingapp-vote:v1
          ports:
            - containerPort: 5000

          # 1. Startup Probe: Accommodates database migration and cold starts
          startupProbe:
            httpGet:
              path: /health
              port: 5000
            initialDelaySeconds: 5
            periodSeconds: 5
            failureThreshold: 12   # Up to 60 seconds allowed to boot

          # 2. Readiness Probe: Prevents premature traffic delivery
          readinessProbe:
            httpGet:
              path: /health
              port: 5000
            initialDelaySeconds: 2
            periodSeconds: 5
            timeoutSeconds: 2
            successThreshold: 1
            failureThreshold: 3

          # 3. Liveness Probe: Detects catastrophic process lockups
          livenessProbe:
            httpGet:
              path: /health
              port: 5000
            initialDelaySeconds: 10
            periodSeconds: 10
            timeoutSeconds: 3
            failureThreshold: 3

          # Lifecycle hook for zero-drop connection draining
          lifecycle:
            preStop:
              exec:
                command: ["/bin/sh", "-c", "sleep 10"]
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# Apply deployment with probes
kubectl apply -f hardened-probes.yaml

# Monitor pod initialization and readiness status
kubectl get pods -l app=resilient-vote -w

# Check endpoint attachment: pods only appear when readiness passes
kubectl get endpoints -l app=resilient-vote

# Inspect events and probe executions
kubectl describe deployment resilient-vote-service
```

---

## 5. Real-World Verification Methods

```bash
# 1. Simulate Readiness Failure:
# Exec into container and simulate backend disconnection (or break health check)
POD_NAME=$(kubectl get pods -l app=resilient-vote -o jsonpath='{.items[0].metadata.name}')

# 2. Observe that Kubelet marks Pod as Not Ready (0/1) but DOES NOT restart it
kubectl get pod $POD_NAME

# 3. Verify that traffic stops routing to this specific pod
kubectl get endpoints -l app=resilient-vote

# 4. Check probe failure events logged in kubelet journal
kubectl describe pod $POD_NAME | grep -A 5 -i "Warning  Unhealthy"
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **Liveness vs Readiness Probe Mistake**:
   - Critical Anti-Pattern: Checking an external dependency (such as downstream PostgreSQL) inside the *Liveness* probe.
   - Outcome: If PostgreSQL suffers an outage, the liveness probes across *all* frontend pods fail simultaneously, causing Kubelet to restart every pod in a cascading crash loop.
   - Rule: Liveness should *only* verify internal process health (deadlock detection). Readiness should verify external dependency readiness.

2. **The Missing Startup Probe Trap**:
   - Issue: Applications taking 45 seconds to boot get repeatedly restarted by an aggressive Liveness probe with a 15-second `initialDelaySeconds`.
   - Solution: Use a `startupProbe` with high `failureThreshold` instead of inflating the liveness probe timeout.

3. **Connection Dropping During Rolling Updates**:
   - Issue: Clients receive HTTP 502/504 errors during deployments even with readiness probes configured.
   - Root Cause: Kube-proxy takes 1-3 seconds to update iptables rules after pod termination starts, during which in-flight packets still route to the terminated pod.
   - Solution: Add a `preStop: exec: command: ["/bin/sh", "-c", "sleep 5"]` hook. This pauses pod shutdown, allowing kube-proxy iptables rules to propagate before SIGTERM is sent.
