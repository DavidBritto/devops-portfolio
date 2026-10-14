# Dia 45: Comprehensive Vulnerability Scanning and SBOM Generation with Aquasecurity Trivy

## 1. Technical Overview and Objective

The objective of Day 45 is to integrate Aquasecurity Trivy into continuous delivery pipelines to detect vulnerabilities across container images, filesystems, Git repositories, and Kubernetes configurations. Modern container images bundle operating system base libraries and hundreds of transitive application dependencies. Unmonitored dependencies expose applications to known Common Vulnerabilities and Exposures (CVEs). Trivy provides fast, stateless scanning backed by a comprehensive vulnerability database, producing structured Software Bill of Materials (SBOM) artifacts for compliance.

Key goals:
- Understand CVE severity scoring (CVSS v3) and vulnerability databases (NVD, Alpine SecDB, Debian Security Tracker).
- Scan local filesystems and dependency manifest files (`requirements.txt`, `package-lock.json`).
- Scan container images across OS layers and application runtimes.
- Scan Kubernetes manifests for Infrastructure as Code (IaC) misconfigurations.
- Generate standard Software Bill of Materials (SBOM) in CycloneDX and SPDX formats.

---

## 2. Architecture and Scanning Engine Breakdown

### 2.1 Trivy Scanning Multi-Target Architecture

```
+-------------------------------------------------------------------------+
| AQUASECURITY TRIVY SCANNING ENGINE                                      |
|  - Local Cache DB (~/.cache/trivy/db) updated daily via GitHub Releases |
|  - CVSS Vulnerability Scoring & Exploit Status Tracking                 |
+-------------------+---------------------------------+-------------------+
                    |                                 |
     [Target: Container Images]       [Target: IaC Manifests]   [Target: Filesystem]
     - Base OS (glibc, openssl)       - Kubernetes YAMLs         - Node.js (npm)
     - Multi-stage image layers       - Dockerfile lints         - Python (pip)
     - Embedded binaries              - Terraform HCL            - Go modules
                    |                                 |
                    v                                 v
+-------------------------------------------------------------------------+
| OUTPUT FORMATS & GATES                                                  |
|  - Human Table Output                                                   |
|  - CycloneDX / SPDX Software Bill of Materials (SBOM)                   |
|  - SARIF (Static Analysis Results Interchange Format for GitHub UI)     |
|  - Exit Code Policy: Exit 1 if CRITICAL CVEs detected                   |
+-------------------------------------------------------------------------+
```

---

## 3. Configuration Breakdown

### 3.1 Declarative Trivy Configuration (`trivy.yaml`)

```yaml
# Configuration file for enterprise Trivy scans
severity:
  - HIGH
  - CRITICAL
ignore-unfixed: true
format: table
exit-code: 1

scan:
  scanners:
    - vuln
    - misconfig
    - secret

vuln:
  type:
    - os
    - library
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# 1. Scan the local repository filesystem for vulnerabilities and misconfigurations
docker run --rm -v $(pwd):/workspace aquasec/trivy:latest fs /workspace \
  --severity HIGH,CRITICAL \
  --ignore-unfixed

# 2. Scan a specific container image
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image \
  --severity HIGH,CRITICAL \
  postgres:15-alpine

# 3. Scan Kubernetes YAML manifests for security misconfigurations
docker run --rm -v $(pwd):/workspace aquasec/trivy:latest config /workspace/daily-exercises/semana-5/dia-35

# 4. Generate a Software Bill of Materials (SBOM) in CycloneDX JSON format
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image \
  --format cyclonedx \
  --output /tmp/vote-sbom.json \
  redis:7-alpine
```

---

## 5. Real-World Verification Methods

```bash
# 1. Inspect generated SBOM structure
head -n 30 /tmp/vote-sbom.json

# 2. Export scan results to SARIF format for integration into GitHub Security tab
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image \
  --format sarif \
  --output /tmp/trivy-results.sarif \
  postgres:15-alpine

# 3. Verify exit code enforcement: should return 0 if no unpatched criticals
echo "Trivy exit code: $?"
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **Docker In-Docker Socket Permission**:
   - Issue: `Got permission denied while trying to connect to the Docker daemon socket`.
   - Solution: Grant read access to the Docker socket or pass `--user root` to the Trivy container invocation when running locally.

2. **Database Download Rate Limiting (GitHub API 403)**:
   - Issue: Trivy fails during DB download with `rate limit reached`.
   - Cause: Unauthenticated requests downloading Trivy's vulnerability DB hitting GitHub API rate limits.
   - Solution: Provide a `GITHUB_TOKEN` environment variable to Trivy or host an internal mirror of the vulnerability database.

3. **Software Bill of Materials (SBOM) in Executive Compliance**:
   - Lesson: Modern regulatory standards (e.g. Executive Order 14028) mandate software vendors provide an accurate SBOM detailing all transitive libraries included in published images. Generating CycloneDX SBOMs via Trivy fulfills this requirement automatically in CI.
