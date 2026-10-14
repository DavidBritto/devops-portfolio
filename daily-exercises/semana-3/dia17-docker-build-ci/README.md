# Dia 17: Container Image Build in CI, Semantic Tagging, Registry Push, and Trivy Security Scanning

## 1. Technical Overview and Objective

The objective of Day 17 is to automate container image builds, tagging strategies, and vulnerability scanning within the Continuous Integration lifecycle. Manually building and pushing container images risks publishing untested layers, unpatched base image CVEs, and insecure credentials. Automating this pipeline via GitHub Actions establishes supply chain security and enables rapid, trusted deployments.

Key goals:
- Configure Docker Buildx in CI for multi-platform build caching.
- Implement automated semantic tagging based on Git commit SHA, branch name, and semantic release tags.
- Authenticate securely with container registries (GitHub Packages / Docker Hub) using secrets.
- Integrate automated container vulnerability scanning with Aquasecurity Trivy to detect high and critical CVEs.
- Fail pipeline runs when unpatched critical vulnerabilities are detected.

---

## 2. Architecture and CI Security Workflow Breakdown

### 2.1 Container Build & Security Scan Pipeline

```
[Git Push to develop / main]
            |
            v
[GitHub Actions Runner: ubuntu-latest]
            |
            +---> [Step 1: Checkout Source Code]
            |
            +---> [Step 2: Docker Buildx Initialization]
            |
            +---> [Step 3: Extract Metadata & Tags]
            |     - sha-xxxxxxx
            |     - branch name (staging/latest)
            |
            +---> [Step 4: Build Container Image Locally]
            |     - Dockerfile multi-stage layers
            |
            +---> [Step 5: Trivy Vulnerability Scan]
            |     - Scans OS packages & app dependencies
            |     - Severity: HIGH, CRITICAL
            |     |
            |     +---> CRITICAL CVE Found? ---> [FAIL PIPELINE (Exit 1)]
            |     |
            |     +---> PASS / No Blockers
            |
            +---> [Step 6: Login to Container Registry]
            |     - docker/login-action using GITHUB_TOKEN
            |
            +---> [Step 7: Push Image to Registry]
                  - ghcr.io/username/vote:sha-xxxxxxx
                  - ghcr.io/username/vote:latest
```

---

## 3. Configuration Breakdown

### 3.1 Declarative Workflow (`.github/workflows/docker-build-scan-push.yml`)

```yaml
name: Docker Build, Scan and Publish

on:
  push:
    branches:
      - main
      - develop
    tags:
      - 'v*.*.*'

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}/vote

jobs:
  build-scan-push:
    name: Build, Scan with Trivy, and Push
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
      security-events: write

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Extract Docker Metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=raw,value=latest,enable=${{ github.ref == 'refs/heads/main' }}
            type=ref,event=branch
            type=sha,format=short

      - name: Build Container Image (Local cache)
        uses: docker/build-push-action@v5
        with:
          context: ./voting-app/roxs-voting-app/vote
          file: ./voting-app/roxs-voting-app/vote/Dockerfile
          load: true
          tags: ${{ steps.meta.outputs.tags }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

      - name: Run Trivy Security Vulnerability Scanner
        uses: aquasecurity/trivy-action@0.20.0
        with:
          image-ref: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:sha-${{ github.sha }}
          format: 'table'
          exit-code: '1'
          ignore-unfixed: true
          vuln-type: 'os,library'
          severity: 'CRITICAL'

      - name: Log in to GitHub Container Registry
        if: github.event_name != 'pull_request'
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Push Container Image to Registry
        if: github.event_name != 'pull_request'
        uses: docker/build-push-action@v5
        with:
          context: ./voting-app/roxs-voting-app/vote
          file: ./voting-app/roxs-voting-app/vote/Dockerfile
          push: true
          tags: ${{ steps.meta.outputs.tags }}
```

---

## 4. Step-by-Step Reproducible Execution Commands

### Local Emulation of Image Build and Vulnerability Scanning

```bash
# Navigate to the Vote application directory
cd /home/david/git/devops-porfolio/voting-app/roxs-voting-app/vote

# Build the container image locally with Git commit tag
GIT_SHA=$(git rev-parse --short HEAD)
docker build -t roxs-vote:${GIT_SHA} .

# Install and run Trivy locally (via container)
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image \
  --severity HIGH,CRITICAL \
  roxs-vote:${GIT_SHA}

# Inspect image layers and size optimization
docker history roxs-vote:${GIT_SHA}
```

---

## 5. Real-World Verification Methods

```bash
# Verify image presence in local Docker cache
docker images | grep roxs-vote

# Inspect SBOM (Software Bill of Materials) generated by Trivy
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image \
  --format cyclonedx \
  roxs-vote:${GIT_SHA} > sbom.json

head -n 25 sbom.json
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **Pipeline Fails on Non-Fixable Upstream Vulnerabilities**:
   - Issue: Trivy fails the build with exit code 1 due to critical vulnerabilities in the base OS image (e.g., Debian/Ubuntu) that have no official patch yet.
   - Solution: Configure `ignore-unfixed: true`. This ignores vulnerabilities where no upstream package vendor fix exists, focusing pipeline enforcement solely on actionable patches.

2. **Docker In-Docker Socket Mount in CI**:
   - Issue: When running Trivy inside a container on the runner, it cannot find the newly built image.
   - Solution: Use `load: true` in `docker/build-push-action` to ensure the artifact is exported to the local Docker daemon image store, and mount `/var/run/docker.sock` for the scanner.

3. **Tagging with `latest` Anti-Pattern**:
   - Issue: Using only `:latest` tags makes deployments non-reproducible and prevents clean rollbacks.
   - Solution: Always push immutable tags based on Git SHA (`sha-abc1234`) or SemVer releases (`v1.2.0`), while maintaining `:latest` strictly as a pointer for developer convenience.
