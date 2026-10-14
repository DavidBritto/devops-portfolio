# Semana 7: DevSecOps, Container Hardening, Vulnerability Scanning, and Kubernetes RBAC

## Overview

Week 7 shifts security practices left into every phase of the software delivery lifecycle (DevSecOps). Relying solely on perimeter network firewalls or post-deployment penetration tests leaves modern containerized applications vulnerable to software supply chain attacks, privilege escalation, and credential leakage. This week implements automated secret scanning, static vulnerability analysis with Trivy, Dockerfile runtime hardening (dropping Linux capabilities, non-root execution), and fine-grained Kubernetes Role-Based Access Control (RBAC) and Pod Security Standards (PSS).

---

## Technical Curriculum Breakdown

| Day | Topic | Key Concepts and Deliverables |
|---|---|---|
| Dia 43 | DevSecOps & Threat Modeling | Shift-Left principles, STRIDE threat model, security gates in CI/CD |
| Dia 44 | Secret Scanning & SAST | GitLeaks, TruffleHog, pre-commit hooks, static code analysis |
| Dia 45 | Vulnerability Scanning (Trivy) | CVE detection in OS layers and application binaries, SBOM generation |
| Dia 46 | Docker Runtime Hardening | Non-root users, read-only root filesystems, dropping capabilities |
| Dia 47 | Kubernetes RBAC Architecture | ServiceAccounts, Roles, RoleBindings, ClusterRoles, least privilege |
| Dia 48 | Pod Security Standards (PSS) | Privileged vs Baseline vs Restricted modes, admission control |
| Dia 49 | Week 7 Final Challenge | Comprehensive automated DevSecOps security pipeline & hardened cluster |

---

## Directory Structure

```
daily-exercises/semana-7/
├── README.md           # Semana 7 module overview and security roadmap
├── dia-43/README.md    # DevSecOps fundamentals, Shift-Left, and threat modeling
├── dia-44/README.md    # Secret scanning and static security analysis
├── dia-45/README.md    # Deep dive into Trivy container & filesystem scanning
├── dia-46/README.md    # Docker container and runtime security hardening
├── dia-47/README.md    # Kubernetes RBAC and ServiceAccount governance
├── dia-48/README.md    # Kubernetes Pod Security Standards (PSS) enforcement
└── dia-49/README.md    # Week 7 Capstone: Full DevSecOps security pipeline
```
