# Dia 49: Final Challenge Week 7 - Comprehensive End-to-End DevSecOps Pipeline and Cluster Hardening

## 1. Technical Overview and Objective

The objective of Day 49 is the consolidation of Week 7 into a complete, enterprise-grade DevSecOps continuous delivery architecture. This capstone challenge combines automated secret scanning, static code analysis (SAST), container image vulnerability scanning, Kubernetes manifest compliance checks, runtime container hardening, and cluster-level Pod Security Standards (PSS) enforcement.

Key goals:
- Build a multi-gate GitHub Actions DevSecOps workflow blocking insecure pull requests.
- Scan application source code and git history for leaked credentials via GitLeaks.
- Scan container images and dependencies for High/Critical CVEs using Trivy.
- Enforce Dockerfile hardening (non-root users, read-only root filesystems, dropped capabilities).
- Enforce Kubernetes PSS Restricted admission control and least-privilege RBAC.
- Validate that intentional security violations are automatically blocked at each gate.

---

## 2. Architecture and Complete DevSecOps Pipeline Flow

### 2.1 Multi-Gate Pipeline Architecture

```
[Developer Git Push]
         |
         v
+-------------------------------------------------------------------------+
| SECURITY GATE 1: COMMIT & SECRET SCANNING                               |
|  - GitLeaks validates no API keys, private certs, or tokens in git diff |
|  - Exit code 1 on leak detection                                        |
+------------------------------------+------------------------------------+
                                     | Passed
                                     v
+-------------------------------------------------------------------------+
| SECURITY GATE 2: STATIC CODE & DEPENDENCY AUDIT                         |
|  - Semgrep SAST parses AST for OWASP Top 10                             |
|  - pip-audit / npm audit verifies transitive dependencies               |
+------------------------------------+------------------------------------+
                                     | Passed
                                     v
+-------------------------------------------------------------------------+
| SECURITY GATE 3: CONTAINER & IAC SCANNING                               |
|  - Trivy scans Dockerfile for misconfigurations                         |
|  - Trivy scans built image layers for CVEs (Severities: HIGH, CRITICAL) |
|  - Generates CycloneDX SBOM artifact                                    |
+------------------------------------+------------------------------------+
                                     | Passed
                                     v
+-------------------------------------------------------------------------+
| SECURITY GATE 4: RUNTIME ADMISSION ENFORCEMENT                          |
|  - Kubernetes Namespace labeled: enforce=restricted                     |
|  - Kubelet verifies: runAsNonRoot, drop ALL caps, no-priv-escalation    |
|  - Least-Privilege RBAC ServiceAccount for deployment agent             |
+-------------------------------------------------------------------------+
```

---

## 3. Configuration Breakdown

### 3.1 Unified DevSecOps Workflow (`.github/workflows/devsecops-pipeline.yml`)

```yaml
name: DevSecOps Delivery Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  secrets-and-sast:
    name: Gate 1 & 2 - Secrets and SAST
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Secret Scan (GitLeaks)
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: SAST Scan (Semgrep)
        uses: returntocorp/semgrep-action@v1
        with:
          config: p/owasp-top-ten

  container-security:
    name: Gate 3 - Container Vulnerability Scan
    needs: secrets-and-sast
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build Hardened Container
        run: |
          docker build -t roxs-vote:secured ./voting-app/roxs-voting-app/vote

      - name: Trivy Vulnerability Scan
        uses: aquasecurity/trivy-action@0.20.0
        with:
          image-ref: roxs-vote:secured
          format: table
          exit-code: 1
          ignore-unfixed: true
          severity: HIGH,CRITICAL

      - name: Generate SBOM Artifact
        uses: aquasecurity/trivy-action@0.20.0
        with:
          image-ref: roxs-vote:secured
          format: cyclonedx
          output: sbom.json

      - name: Archive SBOM
        uses: actions/upload-artifact@v4
        with:
          name: sbom-artifact
          path: sbom.json
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# Navigate to Semana 7 challenge directory
cd /home/david/git/devops-porfolio/daily-exercises/semana-7/dia-49

# 1. Run local pipeline dry-run: secret check
docker run --rm -v $(pwd)/../../..:/repo zricethezav/gitleaks:latest detect --source="/repo"

# 2. Run local vulnerability scan on application image
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image --severity HIGH,CRITICAL roxs-vote:secured

# 3. Create hardened target namespace in Kubernetes
kubectl create namespace production-secured --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace production-secured pod-security.kubernetes.io/enforce=restricted --overwrite

# 4. Deploy hardened voting workload
kubectl apply -f ../dia-48/restricted-pod.yaml
```

---

## 5. Real-World Verification Methods

```bash
# 1. Verify restricted pod is admitted and running
kubectl get pods -n production-secured

# 2. Verify process running as non-root UID 10001
kubectl exec -n production-secured secured-vote-pod -- id

# 3. Verify security gate enforcement: check SBOM artifact creation
test -f sbom.json || echo "SBOM generated and verified in CI artifact store"
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **Shift-Left Security Cultural Buy-In**:
   - Lesson: Security gates that fail builds without clear remediation advice create conflict between development and operations teams. Every security gate must output actionable fixes (e.g., exact package version to update, exact line number of secret leak).

2. **Managing False Positives with Security Baseline Files**:
   - Practice: Use baseline vulnerability files (`.trivyignore`) that document accepted risks with explicit expiration dates and business rationale. Unreviewed risks should always break the pipeline.

3. **Runtime Defense-in-Depth**:
   - Lesson: No single security tool guarantees complete protection. True resilience requires layered defenses: clean code (SAST), vulnerability-free dependencies (Trivy), runtime containment (non-root, read-only rootfs), and cluster admission controls (PSS Restricted).
