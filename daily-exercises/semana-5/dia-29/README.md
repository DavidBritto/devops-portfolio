# Dia 29: Kubernetes Architecture - Control Plane, Worker Nodes, and Distributed Consensus

## 1. Technical Overview and Objective

The objective of Day 29 is to analyze the internal distributed systems architecture of Kubernetes. Running containerized workloads across production clusters requires decoupling operational responsibilities into a centralized Control Plane (brain) and distributed Worker Nodes (execution layer). Understanding how the declarative API, scheduler, controllers, and kubelet coordinate through the etcd distributed datastore is critical for troubleshooting cluster degradation, etcd quorum loss, and scheduling bottlenecks.

Key goals:
- Deconstruct the Kubernetes Control Plane components: `kube-apiserver`, `etcd`, `kube-scheduler`, and `kube-controller-manager`.
- Analyze Worker Node architecture: `kubelet`, `kube-proxy`, and the Container Runtime Interface (CRI).
- Understand the Raft consensus algorithm and quorum requirements in `etcd`.
- Trace an API request lifecycle from `kubectl` issuance to container process execution.
- Inspect cluster component states and health metrics.

---

## 2. Architecture and Workflow Breakdown

### 2.1 Kubernetes Cluster Component Topology

```
+-------------------------------------------------------------------------+
| CONTROL PLANE (MASTER NODE)                                             |
|                                                                         |
|  +-------------------------------------------------------------------+  |
|  | KUBE-APISERVER (Port 6443)                                        |  |
|  | - Authentication, Authorization (RBAC), Admission Webhooks       |  |
|  | - Sole component communicating directly with etcd                |  |
|  +--------^------------------------^----------------------^----------+  |
|           |                        |                      |             |
|           v                        v                      v             |
|  +-----------------+      +-----------------+    +-------------------+  |
|  | ETCD            |      | KUBE-SCHEDULER  |    | KUBE-CONTROLLER-  |  |
|  | - Key-value DB  |      | - Evaluates     |    |   MANAGER         |  |
|  | - Raft consensus|      |   node affinity,|    | - Node, Replica,  |  |
|  | - Port 2379     |      |   taints, memory|    |   Endpoint loops  |  |
|  +-----------------+      +-----------------+    +-------------------+  |
+------------------------------------+------------------------------------+
                                     | Network Fabric (TLS / gRPC)
+------------------------------------v------------------------------------+
| WORKER NODES (DATA PLANE)                                               |
|                                                                         |
|  +-----------------------------------+-------------------------------+  |
|  | WORKER NODE 1                     | WORKER NODE 2                 |  |
|  |                                   |                               |  |
|  |  [Kubelet]                        |  [Kubelet]                    |  |
|  |   - Communicates with CRI         |   - Communicates with CRI     |  |
|  |   - Monitors Pod status           |   - Monitors Pod status       |  |
|  |                                   |                               |  |
|  |  [Kube-Proxy]                     |  [Kube-Proxy]                 |  |
|  |   - IPVS / iptables packet filter |   - IPVS / iptables packet filter |
|  |                                   |                               |  |
|  |  [CRI: containerd / CRI-O]        |  [CRI: containerd / CRI-O]    |  |
|  |   - Spawns pods via runc          |   - Spawns pods via runc      |  |
|  |                                   |                               |  |
|  |  [Pod: Vote]   [Pod: Redis]       |  [Pod: Result] [Pod: Worker]  |  |
|  +-----------------------------------+-------------------------------+  |
+-------------------------------------------------------------------------+
```

### 2.2 Pod Scheduling and Lifecycle Flow

```
1. [User] ----------------> kubectl apply -f pod.yaml
2. [kube-apiserver] -----> Authenticates token, enforces RBAC, writes Spec to etcd
3. [kube-scheduler] -----> Observes unassigned Pod (NodeName: "") via Watch API
4. [kube-scheduler] -----> Evaluates filtering & scoring predicates -> Assigns Node1
5. [kube-apiserver] -----> Updates Pod binding in etcd
6. [kubelet on Node1] ---> Detects scheduled Pod via local Watch stream
7. [kubelet on Node1] ---> Invokes CRI (containerd) via gRPC to pull image and run
8. [kubelet on Node1] ---> Invokes CNI (networking) to allocate IP and attach veth
9. [kubelet on Node1] ---> Reports status: Running back to kube-apiserver
```

---

## 3. Core Architectural Components Reference

| Component | Layer | Primary Responsibility |
|---|---|---|
| `kube-apiserver` | Control Plane | Central gateway; exposes REST API; enforces authentication and validation. |
| `etcd` | Control Plane | Distributed B-tree key-value store holding the complete state of the cluster. |
| `kube-scheduler` | Control Plane | Selects optimal worker node for newly created pods based on resource capacity and constraints. |
| `kube-controller-manager` | Control Plane | Regulates cluster state via reconciliation control loops (ReplicaSet, Node, ServiceAccount). |
| `kubelet` | Worker Node | Node-level agent; communicates with CRI to start/stop containers and monitor health. |
| `kube-proxy` | Worker Node | Maintains network rules on host OS (iptables/IPVS) for Service virtual IP forwarding. |
| `CRI (containerd)` | Worker Node | Implements Container Runtime Interface; manages container lifecycle via `runc`. |
| `CNI (Container Network Interface)` | Cluster Fabric | Manages Pod IP allocation and cross-node pod-to-pod network routing (Calico, Flannel, Cilium). |

---

## 4. Step-by-Step Hands-On Inspection Commands

```bash
# Verify cluster endpoint and control plane connectivity
kubectl cluster-info

# Check health and status of core control plane components
kubectl get componentstatuses 2>/dev/null || kubectl get --raw='/readyz?verbose'

# List nodes and their current operational state
kubectl get nodes -o wide

# Inspect system pods running the control plane (in self-hosted/kubeadm clusters)
kubectl get pods -n kube-system -o wide

# Describe a control plane node to view capacity, allocatable resources, and system taints
kubectl describe node $(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
```

---

## 5. Real-World Verification Methods

```bash
# Verify raw API endpoints via kubectl proxy
kubectl get --raw='/livez'
kubectl get --raw='/readyz'

# Inspect API resources supported by the API server
kubectl api-resources --namespaced=true | head -n 15

# View real-time resource utilization of nodes (requires metrics-server)
kubectl top nodes || echo "metrics-server not yet installed"
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **etcd Quorum and Failure Tolerance**:
   - `etcd` requires a strict majority (`(N/2) + 1`) to maintain cluster consensus.
   - In a 3-node etcd cluster, 1 failure is tolerated. In a 5-node cluster, 2 failures are tolerated. Never use even numbers of etcd nodes, as it increases network partition vulnerability without increasing fault tolerance.

2. **Kubelet Certificate Expiry**:
   - Issue: Worker node status switches to `NotReady`; kubelet logs show `x509: certificate has expired`.
   - Resolution: Check system time synchronization (`chrony`/`ntp`) and rotate kubelet client certificates via `kubeadm certs renew` or CSR approval workflows (`kubectl certificate approve`).

3. **Scheduler Starvation (Pending Pods)**:
   - Issue: Pods stuck indefinitely in `Pending` state.
   - Diagnosis: Run `kubectl describe pod <name>` and check `Events`. Look for `FailedScheduling: 0/X nodes available: insufficient cpu/memory` or unsatisfied NodeAffinity / Taints.
