# Dia 40: CI/CD Pipelines with Helm - Automated Linting, Testing, and OCI Registry Distribution

## 1. Technical Overview and Objective

The objective of Day 40 is to integrate Helm into automated Continuous Integration and Continuous Deployment (CI/CD) pipelines. In enterprise production environments, Helm charts must not be manually applied from developer laptops. Instead, changes to charts are validated using chart-testing (`ct`), checked against Kubernetes schema validators, packaged as Open Container Initiative (OCI) artifacts, published to secure container registries (GitHub Container Registry - GHCR), and deployed via automated deployment workflows.

Key goals:
- Configure automated chart linting and unit testing in GitHub Actions using `chart-testing` (`ct`).
- Stand up ephemeral KinD clusters in CI runners to execute live chart installation dry-runs.
- Package Helm charts as OCI artifacts and push to GHCR (`helm push`).
- Build an automated Continuous Delivery workflow deploying Helm charts to target Kubernetes clusters.
- Enforce semantic versioning policies on chart updates.

---

## 2. Architecture and CI/CD Helm Workflow Breakdown

### 2.1 Helm OCI Packaging and CD Delivery Pipeline

```
[Pull Request: Chart changes]
             |
             v
[CI Runner: ubuntu-latest]
             |
             +---> Step 1: ct lint (Validates chart syntax, version bumps, maintainers)
             +---> Step 2: kind-action (Creates ephemeral cluster inside runner)
             +---> Step 3: ct install (Installs chart on ephemeral KinD cluster)
             |
             v (PR Approved & Merged to main)
[CD Release Pipeline]
             |
             +---> Step 1: helm package (Generates vote-chart-1.0.0.tgz)
             +---> Step 2: helm registry login ghcr.io
             +---> Step 3: helm push (Publishes OCI artifact to GHCR)
             +---> Step 4: helm upgrade --install --atomic (Deploys to Staging/Prod)
```

---

## 3. Configuration Breakdown

### 3.1 GitHub Actions Helm CI/CD Workflow (`.github/workflows/helm-pipeline.yml`)

```yaml
name: Helm Chart CI/CD Pipeline

on:
  push:
    branches:
      - main
    paths:
      - 'charts/**'
  pull_request:
    branches:
      - main
    paths:
      - 'charts/**'

jobs:
  lint-and-test:
    name: Lint & Test Chart
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Set up Helm
        uses: azure/setup-helm@v4
        with:
          version: v3.14.0

      - name: Set up Python for Chart-Testing
        uses: actions/setup-python@v5
        with:
          python-version: '3.10'

      - name: Set up Chart-Testing CLI
        uses: helm/chart-testing-action@v2.6.1

      - name: Run Chart Linting
        run: ct lint --target-branch main --charts charts/vote-chart

      - name: Create Ephemeral KinD Cluster
        uses: helm/kind-action@v1.9.0
        if: github.event_name == 'pull_request'

      - name: Execute Chart Installation Test
        if: github.event_name == 'pull_request'
        run: ct install --target-branch main --charts charts/vote-chart

  publish-and-deploy:
    name: Package, Publish OCI, and Deploy
    needs: lint-and-test
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: self-hosted-staging
    permissions:
      contents: read
      packages: write
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Package Helm Chart
        run: |
          mkdir -p .cr-release-packages
          helm package charts/vote-chart -d .cr-release-packages

      - name: Login to GitHub Container Registry (OCI)
        run: |
          echo "${{ secrets.GITHUB_TOKEN }}" | helm registry login ghcr.io -u ${{ github.actor }} --password-stdin

      - name: Push Chart to OCI Registry
        run: |
          PACKAGE_FILE=$(ls .cr-release-packages/*.tgz | head -n 1)
          helm push $PACKAGE_FILE oci://ghcr.io/${{ github.repository }}/charts

      - name: Deploy to Target Kubernetes Cluster
        run: |
          helm upgrade --install vote-staging \
            oci://ghcr.io/${{ github.repository }}/charts/vote-chart \
            --namespace staging \
            --create-namespace \
            --values charts/vote-chart/values-staging.yaml \
            --atomic \
            --timeout 5m
```

---

## 4. Step-by-Step Reproducible Execution Commands

### Local Emulation of Chart Testing and OCI Publishing

```bash
# 1. Run chart-testing locally using Docker
docker run --rm -v $(pwd):/workdir -w /workdir \
  quay.io/helmpack/chart-testing:v3.10.0 ct lint --all

# 2. Package chart locally
helm package daily-exercises/semana-6/dia-39/vote-chart

# 3. Log in to local OCI registry (or GHCR)
echo $CR_PAT | helm registry login ghcr.io -u $USERNAME --password-stdin

# 4. Push OCI artifact
helm push vote-chart-1.0.0.tgz oci://ghcr.io/$USERNAME/charts

# 5. Pull and install directly from OCI repository
helm install my-remote-vote oci://ghcr.io/$USERNAME/charts/vote-chart --version 1.0.0
```

---

## 5. Real-World Verification Methods

```bash
# 1. Inspect OCI chart metadata and layers without downloading
helm show chart oci://ghcr.io/$USERNAME/charts/vote-chart --version 1.0.0

# 2. Verify Helm release deployment status on cluster
helm status vote-staging -n staging

# 3. Verify history of automated revisions deployed by CI/CD
helm history vote-staging -n staging
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **OCI Registry URL Prefixing**:
   - Issue: `helm push` fails with `protocol scheme not supported`.
   - Cause: OCI registries in Helm 3 require the explicit `oci://` scheme protocol prefix.
   - Solution: Use `helm push <package.tgz> oci://ghcr.io/<repo>/charts`.

2. **Chart Version Bump Enforcement (`ct lint`)**:
   - Issue: CI pipeline fails with `chart version not increased`.
   - Reason: Standard chart-testing rules require incrementing `version:` in `Chart.yaml` whenever any file in the chart directory is modified.
   - Solution: Adhere to Semantic Versioning (`PATCH` for bug fixes, `MINOR` for template features, `MAJOR` for breaking value changes).

3. **Cluster RBAC Permissions for CI Runners**:
   - Issue: The runner gets `forbidden: User system:serviceaccount cannot list resource deployments`.
   - Solution: Configure an isolated Kubernetes `ServiceAccount` and `RoleBinding` granting the CI runner only the specific permissions required within its target deployment namespace.
