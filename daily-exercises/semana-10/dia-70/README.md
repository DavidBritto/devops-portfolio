# Dia 70: Capstone Project - Comprehensive Production DevOps Portfolio Final Showcase

## 1. Technical Overview and Objective

The objective of Day 70 is the final consolidation and showcase of the entire 10-week DevOps engineering journey. Over the course of 70 intensive days, this portfolio evolved from low-level Linux systems administration to multi-cloud infrastructure orchestration, containerization, distributed Kubernetes clusters, DevSecOps pipelines, automated observability, and cloud emulation.

This capstone document serves as the technical master overview demonstrating how each discipline integrates into an end-to-end, enterprise-ready delivery pipeline centered around the distributed **Roxs Voting App**.

Key competencies demonstrated:
- **Week 1 (Systems & Automation)**: Linux kernel internals, FHS, Bash scripting, Vagrant, and Ansible configuration management.
- **Week 2 (Containerization)**: Docker daemon, cgroups, namespaces, multi-stage Dockerfiles, and Docker Compose orchestration.
- **Week 3 (CI/CD Pipelines)**: GitHub Actions, automated test suites, self-hosted runners on Vagrant, and staging/production deployments.
- **Week 4 (Infrastructure as Code)**: Declarative Terraform, modular architecture, multi-environment tfvars, and state locking.
- **Week 5 (Kubernetes Workloads)**: Distributed clusters (Kind), Pods, Deployments, Services, ConfigMaps, Secrets, and persistent storage.
- **Week 6 (Advanced Kubernetes & Helm)**: Actions Runner Controller (ARC), Kustomize overlays, health probes, and Umbrella Helm Charts.
- **Week 7 (DevSecOps & Hardening)**: Shift-Left security, GitLeaks secret scanning, Trivy vulnerability audits, Docker hardening, and RBAC.
- **Week 8 (Observability & Alerting)**: Prometheus scraping, custom exporters, PromQL analytics, Grafana dashboards as code, and Alertmanager.
- **Week 9 (Cloud Emulation & IaC)**: AWS S3, DynamoDB, SQS, and Lambda serverless architectures emulated on LocalStack via Terraform.
- **Week 10 (Reliability & Performance)**: Grafana k6 load/stress testing, automated disaster recovery restore drills, and chaos resilience.

---

## 2. Complete End-to-End Enterprise Architecture

```
+-------------------------------------------------------------------------+
| DEVELOPER WORKFLOW (Shift-Left DevSecOps)                               |
|  - Git Commit -> Pre-commit Hooks (GitLeaks secret check + Linting)     |
|  - Git Push   -> Conventional Commits (feat:, fix:, chore:)             |
+------------------------------------+------------------------------------+
                                     |
                                     v
+-------------------------------------------------------------------------+
| CONTINUOUS INTEGRATION (GitHub Actions / ARC Kubernetes Runners)        |
|  - Stage 1: Static Code Analysis (Semgrep SAST)                         |
|  - Stage 2: Unit Testing (pytest for Python, npm test for Node.js)      |
|  - Stage 3: Container Build (Docker Buildx multi-stage caching)          |
|  - Stage 4: Vulnerability Gate (Trivy CVE scans + CycloneDX SBOM)       |
|  - Stage 5: Chart Verification (ct lint & helm template)                |
+------------------------------------+------------------------------------+
                                     |
                                     v
+-------------------------------------------------------------------------+
| CONTINUOUS DELIVERY & PROMOTION                                         |
|  - Staging: Automated promotion via Helm on merge to develop            |
|  - Production: Protected Environment requiring designated sign-off      |
+------------------------------------+------------------------------------+
                                     |
                                     v
+-------------------------------------------------------------------------+
| PRODUCTION RUNTIME INFRASTRUCTURE (Kubernetes / Cloud Fabric)           |
|                                                                         |
|  [Ingress Controller (TLS Termination via cert-manager)]                |
|         |                                                               |
|         +---> [Vote Frontend: Python Flask (HPA: 2-10 replicas)]        |
|         |     (Hardened: non-root, read-only rootfs, dropped caps)      |
|         |           |                                                   |
|         |           v writes                                            |
|         |     [Redis In-Memory Cache (ClusterIP Service)]               |
|         |           ^                                                   |
|         |           | polls                                             |
|         |     [Worker Processor: Node.js (Background loop)]             |
|         |           |                                                   |
|         |           v commits                                           |
|         |     [PostgreSQL Database (PVC Bound Storage)]                 |
|         |           ^                                                   |
|         |           | queries                                           |
|         +---> [Result Dashboard: Node.js (Real-time charts)]            |
+------------------------------------+------------------------------------+
                                     |
                                     +---> Monitored by
                                     v
+-------------------------------------------------------------------------+
| ENTERPRISE OBSERVABILITY & RELIABILITY                                  |
|  - Prometheus scrapes exporters every 15s (Node, Postgres, Redis, App)  |
|  - Alertmanager groups and routes critical alerts to on-call webhooks   |
|  - Grafana renders executive dashboards provisioned as code             |
|  - k6 validates performance SLOs (p95 latency < 200ms)                  |
|  - Automated weekly restore drills verify RTO/RPO disaster recovery     |
+-------------------------------------------------------------------------+
```

---

## 3. Technology Stack Reference

| Discipline | Technologies & Tools |
|---|---|
| Operating Systems | Ubuntu 24.04 LTS, Debian, Alpine Linux, POSIX standards |
| Virtualization & IaC | Oracle VirtualBox, Vagrant, HashiCorp Terraform |
| Configuration Management | Ansible (Playbooks, Roles, Inventory, Handlers) |
| Container Runtimes | Docker Engine, containerd, runc, Docker Compose |
| Orchestration | Kubernetes (Kind), kubectl, Kustomize, Helm 3 |
| CI/CD & Runners | GitHub Actions, Actions Runner Controller (ARC), Self-Hosted Runners |
| DevSecOps & Security | GitLeaks, Semgrep, Aquasecurity Trivy, Hadolint, RBAC, PSS Restricted |
| Observability | Prometheus, PromQL, Grafana, Alertmanager, Node/DB Exporters |
| Cloud Services (Emulated) | LocalStack (AWS S3, DynamoDB, SQS, SNS, Lambda, IAM) |
| Performance & Reliability | Grafana k6, Linux Traffic Control (tc), Automated PostgreSQL Backups |

---

## 4. Step-by-Step Portfolio Reproduction Guide

To reproduce the complete stack from zero:

```bash
# 1. Clone repository
git clone https://github.com/DavidBritto/devops-portfolio.git
cd devops-portfolio

# 2. Spin up complete containerized microservice stack with monitoring
cd voting-app/roxs-voting-app
docker compose up -d

# 3. Verify running services
docker compose ps

# 4. Access interfaces in browser:
# - Voting Interface:       http://localhost:8080
# - Results Dashboard:      http://localhost:3000
# - Prometheus Metrics:     http://localhost:9091
# - Grafana Visualizations: http://localhost:3003 (admin / admin)

# 5. Run automated load testing validation
docker run --rm -i --network=host \
  -e TARGET_URL="http://localhost:8080" \
  grafana/k6:latest run - < load-testing/k6.js

# 6. Run automated database backup
./scripts/backup.sh development
```

---

## 5. Key Engineering Lessons Learned

1. **Automation Over Manual Interventions**:
   - Any operational task executed more than twice must be codified as an automated script, Terraform module, or CI/CD workflow. Manual interventions inevitably introduce configuration drift.

2. **Defense-in-Depth Security (Shift-Left)**:
   - Security cannot be treated as a final audit gate before release. Integrating secret scanning into pre-commit hooks, dependency analysis into CI, and runtime policies (PSS Restricted) into Kubernetes ensures continuous protection.

3. **Observability Precedes Reliability**:
   - A distributed system cannot be stabilized without granular telemetry. Instrumenting RED metrics (Rate, Errors, Duration) and USE metrics (Utilization, Saturation, Errors) provides the visibility needed to diagnose production incidents quickly.

4. **Resilience Through Decoupling**:
   - Decoupling synchronous operations via queues (Redis, SQS) ensures that failures in backend databases or downstream services do not bring down user-facing frontend applications.
