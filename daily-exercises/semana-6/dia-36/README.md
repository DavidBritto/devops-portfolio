# Dia 36: Kubernetes-Native CI/CD - Actions Runner Controller (ARC) on Kind

## 1. Technical Overview and Objective

The objective of Day 36 is to implement a scalable, Kubernetes-native CI/CD runner infrastructure using GitHub's Actions Runner Controller (ARC). Traditional self-hosted runners hosted on static virtual machines suffer from configuration drift, lack of horizontal scalability, and credential exposure across consecutive builds. ARC operates as a Kubernetes operator that dynamically provisions ephemeral, isolated runner pods in response to GitHub Actions workflow webhooks and queue metrics.

Key goals:
- Understand the Actions Runner Controller (ARC) operator pattern and Custom Resource Definitions (CRDs).
- Deploy `cert-manager` for internal webhook TLS certificate provisioning.
- Deploy the ARC controller manager and configure GitHub Personal Access Token (PAT) authentication.
- Provision ephemeral autoscaling RunnerDeployments and RunnerSets on a local Kind cluster.
- Execute automated CI workflows that target the newly registered Kubernetes runner pods.

---

## 2. Architecture and Workflow Breakdown

### 2.1 Actions Runner Controller Architecture

```
+-------------------------------------------------------------------------+
| GITHUB PLATFORM                                                         |
|  - Repository: DavidBritto/devops-portfolio                             |
|  - Workflow runs with: runs-on: arc-runner-k8s                          |
|  - Webhook Events / Long Poll API (GitHub Actions Queue)                |
+-------------------+-----------------------------------------------------+
                    | TLS (gRPC / HTTPS)
                    v
+-------------------------------------------------------------------------+
| KUBERNETES CLUSTER (Kind devops-cluster)                                |
|                                                                         |
|  [Namespace: cert-manager]                                              |
|   - cert-manager operator generates admission webhook certificates      |
|                                                                         |
|  [Namespace: actions-runner-system]                                     |
|   - actions-runner-controller-manager (Pod)                             |
|   - Reconciles RunnerDeployment & Runner Custom Resources               |
|         |                                                               |
|         | watches GitHub queue & spawns                                 |
|         v                                                               |
|  [Namespace: arc-runners]                                               |
|   +------------------------------------+-----------------------------+  |
|   | Runner Pod: arc-runner-7b49f-x     | Runner Pod: arc-runner-7b49f-y|  |
|   | - Container: runner                | - Container: runner         |  |
|   |   (github-actions-runner agent)    |   (github-actions-runner)   |  |
|   | - Ephemeral (Terminated upon job   | - Scales 1 -> N dynamically |  |
|   |   completion, guaranteeing clean   |                             |  |
|   |   workspaces)                      |                             |  |
|   +------------------------------------+-----------------------------+  |
+-------------------------------------------------------------------------+
```

### 2.2 Dynamic Ephemeral Runner Lifecycle

```
1. Workflow triggered on GitHub with 'runs-on: arc-runner-k8s'
2. GitHub signals queued job via check-run events
3. ARC Controller reconciles desired vs active runners
4. ARC spawns ephemeral Runner Pod with dedicated credentials
5. Runner registers with GitHub API, receives job payload
6. Job completes -> Runner pod automatically terminates (Self-destruction)
7. Pristine new runner pod spawned for subsequent queue items
```

---

## 3. Configuration Breakdown

### 3.1 GitHub Authentication Secret (`github-pat-secret.yaml`)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: controller-manager
  namespace: actions-runner-system
type: Opaque
stringData:
  github_token: "ghp_MockGitHubPersonalAccessTokenForClusterDeployment"
```

### 3.2 Declarative RunnerDeployment Manifest (`runner-deployment.yaml`)

```yaml
apiVersion: actions.summerwind.dev/v1alpha1
kind: RunnerDeployment
metadata:
  name: devops-runner-pool
  namespace: arc-runners
spec:
  template:
    spec:
      repository: DavidBritto/devops-portfolio
      labels:
        - arc-runner-k8s
        - linux
        - x64
      ephemeral: true
      resources:
        limits:
          cpu: "1000m"
          memory: "2Gi"
        requests:
          cpu: "500m"
          memory: "1Gi"
      dockerdWithinRunner: true

---
apiVersion: actions.summerwind.dev/v1alpha1
kind: HorizontalRunnerAutoscaler
metadata:
  name: devops-runner-scaler
  namespace: arc-runners
spec:
  scaleTargetRef:
    name: devops-runner-pool
  minReplicas: 1
  maxReplicas: 5
  metrics:
    - type: TotalNumberOfQueuedAndInProgressWorkflowRuns
      repositoryNames:
        - DavidBritto/devops-portfolio
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# 1. Install cert-manager prerequisites
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.1/cert-manager.yaml

# 2. Wait for cert-manager webhooks to be ready
kubectl wait --for=condition=Available deployment --all -n cert-manager --timeout=120s

# 3. Add ARC Helm repository and install controller
helm repo add actions-runner-controller https://actions-runner-controller.github.io/actions-runner-controller
helm repo update

# 4. Create system namespaces
kubectl create namespace actions-runner-system
kubectl create namespace arc-runners

# 5. Deploy ARC with Helm
helm install arc actions-runner-controller/actions-runner-controller \
  --namespace actions-runner-system \
  --set syncPeriod=1m

# 6. Apply Runner authentication secret and RunnerDeployment CRD
kubectl apply -f github-pat-secret.yaml
kubectl apply -f runner-deployment.yaml
```

---

## 5. Real-World Verification Methods

```bash
# 1. Verify ARC operator pods are healthy
kubectl get pods -n actions-runner-system

# 2. Verify spawned ephemeral runner pods
kubectl get runners -n arc-runners
kubectl get pods -n arc-runners -o wide

# 3. Check Runner registration status in GitHub UI
# Navigate to: Repo Settings -> Actions -> Runners
# Verify 'devops-runner-pool-xxxx' displays with status: Idle

# 4. Trigger test workflow targeted at 'runs-on: arc-runner-k8s'
gh workflow run ci.yml -r develop
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **Cert-Manager Webhook Race Condition**:
   - Issue: ARC CRDs fail to apply with `Internal error occurred: failed calling webhook`.
   - Cause: The `cert-manager-webhook` pod is not yet serving TLS endpoints when the CRD validator runs.
   - Solution: Use `kubectl wait --for=condition=Available` on `cert-manager-webhook` before applying ARC manifests.

2. **Docker-in-Docker (DinD) Security and Mount Permissions**:
   - Issue: Building container images inside runner pods fails with `Cannot connect to the Docker daemon`.
   - Root Cause: Runner container lacks elevated Linux capabilities.
   - Solution: Set `dockerdWithinRunner: true` in the runner spec, which automatically injects the Docker sidecar with requisite `securityContext.privileged: true`.

3. **Ephemeral Runner Secret Retention**:
   - Lesson: Setting `ephemeral: true` guarantees that leftover files, credentials, or malicious artifacts from compromised dependency pipelines are wiped entirely upon build completion, enforcing zero-trust build environments.
