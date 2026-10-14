# Semana 6: Advanced Kubernetes, Actions Runner Controller (ARC), Helm, and GitOps CI/CD

## Overview

Week 6 advances from basic Kubernetes workload primitives to production-grade deployment patterns, packaging, and enterprise CI/CD automation. The week focuses on running GitHub Actions runners natively inside Kubernetes clusters via the Actions Runner Controller (ARC), configuring multi-environment promotion patterns, implementing robust application health checks and probes, standardizing package management via Helm charts, and building automated continuous delivery pipelines.

---

## Technical Curriculum Breakdown

| Day | Topic | Key Concepts and Deliverables |
|---|---|---|
| Dia 36 | Actions Runner Controller (ARC) | Kubernetes-native autoscaling GitHub Actions runners on Kind |
| Dia 37 | Multi-Environment Workloads | Environment isolation, Kustomize overlays, resource quotas |
| Dia 38 | Health Checks and Lifecycle Probes | Liveness, Readiness, and Startup probes, graceful shutdown hooks |
| Dia 39 | Helm Package Manager | Chart architecture, templates, values.yaml overrides, dependencies |
| Dia 40 | CI/CD Pipelines with Helm | Automated chart linting, packaging, and cluster deployment |
| Dia 41 | Production Kubernetes Engineering | Ingress controllers, TLS cert-manager, network policies, PDBs |
| Dia 42 | Week 6 Final Challenge | Full GitOps-ready Voting App packaging with Helm and automated release |

---

## Directory Structure

```
daily-exercises/semana-6/
├── README.md           # Semana 6 module overview and roadmap
├── dia-36/README.md    # Actions Runner Controller (ARC) on Kind
├── dia-37/README.md    # Multi-environment architecture (dev, staging, prod)
├── dia-38/README.md    # Pod health checks (liveness, readiness, startup probes)
├── dia-39/README.md    # Helm fundamentals and custom chart development
├── dia-40/README.md    # Continuous deployment pipelines driven by Helm
├── dia-41/README.md    # Production Kubernetes hardening, Ingress, and policies
└── dia-42/README.md    # Week 6 Capstone: Enterprise Helm chart & GitOps release
```
