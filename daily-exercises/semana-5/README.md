# Semana 5: Kubernetes and Container Orchestration

## Overview

Week 5 transitions from single-host container management (Docker / Docker Compose) to distributed container orchestration with Kubernetes. Kubernetes provides the abstraction layer necessary to automate application scheduling, horizontal scaling, self-healing, rolling deployments, internal service discovery, and declarative configuration across clustered infrastructure.

---

## Technical Curriculum Breakdown

| Day | Topic | Key Concepts and Deliverables |
|---|---|---|
| Dia 29 | Kubernetes Architecture | Control Plane, Worker Nodes, etcd consensus, API server, Kubelet |
| Dia 30 | Local Clusters & kubectl | Kind / Minikube cluster provisioning, context management, namespaces |
| Dia 31 | Pods and Pod Lifecycles | Atomic execution units, pod manifests, multi-container patterns |
| Dia 32 | Deployments & ReplicaSets | Desired state reconciliation, horizontal scaling, zero-downtime rollouts |
| Dia 33 | Services & Networking | ClusterIP, NodePort, LoadBalancer, CoreDNS, Kube-Proxy packet routing |
| Dia 34 | Storage & Configuration | ConfigMaps, Secrets, PersistentVolumes (PV), PersistentVolumeClaims (PVC) |
| Dia 35 | Week 5 Final Challenge | Roxs Voting App fully deployed on Kubernetes with high availability |

---

## Directory Structure

```
daily-exercises/semana-5/
├── README.md           # Semana 5 module overview and navigation
├── dia-29/README.md    # Kubernetes architecture deep-dive
├── dia-30/README.md    # Local cluster setup (Kind/Minikube) and kubectl workflows
├── dia-31/README.md    # Pod primitives, spec structures, and lifecycle states
├── dia-32/README.md    # Deployments, ReplicaSets, rolling updates, and rollback strategies
├── dia-33/README.md    # Kubernetes Services, CoreDNS, and cluster networking
├── dia-34/README.md    # Persistent storage (PV/PVC), ConfigMaps, and Secrets
└── dia-35/README.md    # Capstone challenge: Distributed Roxs Voting App on Kubernetes
```
