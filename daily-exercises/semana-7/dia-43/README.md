# Dia 43: DevSecOps Fundamentals - Shift-Left Security, Threat Modeling, and CI/CD Security Gates

## 1. Technical Overview and Objective

The objective of Day 43 is to establish the architectural foundations of DevSecOps. Traditional security practices operated as an isolated gate at the end of the development cycle, frequently causing deployment delays or skipped security checks under tight deadlines. DevSecOps embeds security practices, automated compliance policies, and automated risk scoring throughout every phase of the CI/CD pipeline -- from local developer commits to production operations (Shift-Left).

Key goals:
- Understand the Shift-Left security paradigm and its impact on Mean Time to Remediation (MTTR).
- Apply the STRIDE threat modeling framework to containerized microservice architectures.
- Define automated Security Gates in CI/CD pipelines with configurable severity thresholds.
- Understand Software Supply Chain Security and the SLSA (Supply-chain Levels for Software Artifacts) framework.
- Configure pre-commit security verification tooling.

---

## 2. Architecture and Security Gate Flow Breakdown

### 2.1 DevSecOps Continuous Lifecycle Pipeline

```
[Developer IDE]
       |  Pre-commit Hook: Secret detection (GitLeaks), Linting
       v
[Git Commit & Push]
       |
       +---> [Gate 1: Source Analysis]
       |     - SAST (Static Application Security Testing)
       |     - Secret Leak Detection
       |
       +---> [Gate 2: Dependency Analysis]
       |     - SCA (Software Composition Analysis: pip-audit, npm audit)
       |     - License Compliance
       |
       +---> [Gate 3: Build & Image Security]
       |     - Container Vulnerability Scanning (Trivy CVE scans)
       |     - Dockerfile Linter (Hadolint)
       |     - Image Signing & Attestation (Cosign)
       |
       +---> [Gate 4: Kubernetes Admission Security]
       |     - Admission Webhooks (Kyverno / OPA Gatekeeper)
       |     - Pod Security Standards (PSS Restricted)
       |
       v
[Production Cluster Deployment]
       - Runtime Security Monitoring & Audit Logging
```

### 2.2 STRIDE Threat Model Applied to Microservices

| Threat | Description | Mitigation Strategy |
|---|---|---|
| **Spoofing** | Impersonating a user or service | Mutual TLS (mTLS), strict JWT token validation, OIDC authentication. |
| **Tampering** | Modifying in-flight data or container layers | Read-only container rootfs, cryptographic image signing (Cosign). |
| **Repudiation** | Denying performed actions | Tamper-proof Kubernetes audit logging, centralized SIEM. |
| **Information Disclosure** | Exposing API keys, passwords, database records | HashiCorp Vault, Kubernetes Secrets with encryption at rest, GitLeaks. |
| **Denial of Service** | Resource exhaustion crashing cluster nodes | Kubernetes ResourceQuotas, CPU/memory limits, ingress rate limiting. |
| **Elevation of Privilege** | Container breakout to host root | Drop Linux capabilities, enforce non-root UID, PSS Restricted mode. |

---

## 3. Configuration Breakdown

### 3.1 Declarative Pre-Commit Hook Configuration (`.pre-commit-config.yaml`)

```yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.1
    hooks:
      - id: gitleaks
  - repo: https://github.com/hadolint/hadolint
    rev: v2.12.0
    hooks:
      - id: hadolint-docker
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# 1. Install pre-commit framework
pip install pre-commit

# 2. Install pre-commit hooks in the git repository
cd /home/david/git/devops-porfolio
pre-commit install

# 3. Execute pre-commit checks manually against all files
pre-commit run --all-files

# 4. Run Dockerfile static security analysis using Hadolint
docker run --rm -i hadolint/hadolint < voting-app/roxs-voting-app/vote/Dockerfile
```

---

## 5. Real-World Verification Methods

```bash
# 1. Test pre-commit interception: attempt to stage a mock API key
echo "AWS_SECRET_ACCESS_KEY=AKIAIOSFODNN7EXAMPLE12345" > test_secret.env
git add test_secret.env
# Commit will fail immediately with Gitleaks violation
git commit -m "test: commit secret" || echo "Pre-commit security gate blocked commit"
rm -f test_secret.env
git reset HEAD test_secret.env 2>/dev/null || true

# 2. Audit dependencies for known vulnerabilities in Python
cd voting-app/roxs-voting-app/vote
pip-audit || pip list
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **False Positives in Security Scanners**:
   - Issue: Developers bypass security gates using `--no-verify` because scanners flag test fixtures or non-sensitive mock tokens.
   - Solution: Configure a `.gitleaksignore` file or explicit baseline rule definitions. Maintain documented, auditable ignore files rather than allowing developers to disable gates entirely.

2. **Supply Chain Compromise via Unpinned Dependencies**:
   - Risk: Floating tags like `image: node:latest` or `pip install flask` can silently pull malicious updates if upstream repositories are compromised.
   - Solution: Pin exact cryptographic digests (`image: node@sha256:xxxx`) or strict lockfiles (`package-lock.json`, `poetry.lock`).

3. **Security Gate SLA and Developer Velocity**:
   - Lesson: Running exhaustive 30-minute security scans on every local commit kills developer velocity. Run lightweight scanners (secret checks, linting) in pre-commit (< 5s), and execute deep vulnerability and dynamic analysis in CI asynchronous pipelines.
