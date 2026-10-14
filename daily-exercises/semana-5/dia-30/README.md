# Dia 30: Local Cluster Provisioning with Kind and Advanced kubectl CLI Management

## 1. Technical Overview and Objective

The objective of Day 30 is to stand up a lightweight multi-node Kubernetes development cluster locally using Kind (Kubernetes in Docker) and master cluster management via `kubectl`. Running multi-node topologies locally allows engineers to experiment with control plane failover, pod affinity, node port mapping, and namespace isolation without provisioning expensive cloud infrastructure.

Key goals:
- Provision a multi-node Kubernetes cluster (1 control-plane, 2 worker nodes) using Kind and declarative YAML configurations.
- Map host ports to cluster nodes to enable external ingress traffic routing.
- Understand kubeconfig files, contexts, and cluster switching mechanisms.
- Master `kubectl` operations: resource querying, JSONPath filtering, dry-run manifest generation, and namespace management.
- Configure Namespace resource isolation and default quotas.

---

## 2. Architecture and Cluster Topology Breakdown

### 2.1 Kind Multi-Node Architecture

Kind deploys Kubernetes cluster nodes as Docker containers running systemd, containerd, and kubelet:

```
+-------------------------------------------------------------------------+
| HOST LINUX WORKSTATION                                                  |
|                                                                         |
|  Docker Bridge Network: kind (Subnet: 172.18.0.0/16)                   |
|                                                                         |
|  +------------------------+  +-------------------+  +----------------+  |
|  | Container:             |  | Container:        |  | Container:     |  |
|  | kind-control-plane     |  | kind-worker       |  | kind-worker2   |  |
|  | - kube-apiserver:6443  |  | - kubelet         |  | - kubelet      |  |
|  | - etcd, scheduler      |  | - containerd      |  | - containerd   |  |
|  | Host Port: 6443/TCP    |  | - pods scheduled  |  | - pods         |  |
|  +------------------------+  +-------------------+  +----------------+  |
|                                                                         |
|  Kubeconfig (~/.kube/config) -----------------------------------> [API] |
+-------------------------------------------------------------------------+
```

---

## 3. Configuration Breakdown

### 3.1 Declarative Kind Cluster Configuration (`kind-config.yaml`)

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: devops-cluster
nodes:
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
    extraPortMappings:
      - containerPort: 80
        hostPort: 8080
        protocol: TCP
      - containerPort: 443
        hostPort: 8443
        protocol: TCP
  - role: worker
  - role: worker
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# 1. Create Kind cluster using declarative configuration
kind create cluster --config kind-config.yaml

# 2. Inspect active kubectl cluster contexts
kubectl config get-contexts
kubectl config current-context

# 3. Rename or switch context if necessary
kubectl config use-context kind-devops-cluster

# 4. Verify all nodes transitioned to Ready state
kubectl get nodes -L kubernetes.io/role -o wide

# 5. Create dedicated environment namespaces
kubectl create namespace development
kubectl create namespace staging
kubectl create namespace production

# 6. Set default active namespace for current context
kubectl config set-context --current --namespace=development
```

---

## 5. Real-World Verification Methods

```bash
# 1. Advanced querying using JSONPath expressions
# Print internal IP of all nodes
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.addresses[?(@.type=="InternalIP")].address}{"\n"}{end}'

# 2. Generate resource manifests without committing to the cluster (dry-run)
kubectl create deployment web-test --image=nginx:alpine --dry-run=client -o yaml > web-test-deployment.yaml

# 3. Verify namespace resource isolation
kubectl get namespaces --show-labels
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **Docker Inotify Max User Watches Exhaustion on Linux Hosts**:
   - Issue: Kind nodes fail to start or report `too many open files` during containerd initialization.
   - Solution: Increase host kernel limits:
     `sudo sysctl fs.inotify.max_user_watches=524288`
     `sudo sysctl fs.inotify.max_user_instances=512`

2. **Accidental Work on the Wrong Cluster Context**:
   - Issue: Applying destructive manifests to a staging or production cluster instead of local dev.
   - Solution: Configure prompt indicators (e.g., `kube-ps1` or `starship`) that display the active cluster context and namespace directly in the terminal prompt.

3. **Kind Port Forwarding Conflicts**:
   - Issue: `kind create cluster` errors out with `bind: address already in use` for host port 8080 or 8443.
   - Solution: Run `ss -tulnp | grep -E "8080|8443"` to identify and terminate conflicting local processes before provisioning the cluster.
