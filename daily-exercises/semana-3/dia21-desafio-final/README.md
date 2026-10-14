# Dia 21: Final Challenge Week 3 - Automated End-to-End CI/CD Pipeline on Self-Hosted Vagrant Runner

## 1. Technical Overview and Objective

The objective of Day 21 is the end-to-end integration of Continuous Integration and Continuous Deployment (CI/CD). This capstone challenge for Week 3 unifies a dedicated self-hosted runner operating inside a Vagrant virtual machine, automated GitHub Actions pipelines triggered by Git events, environment-specific staging and production deployments via Docker Compose, and automated post-deployment health verification.

Key goals:
- Deploy and register a dedicated self-hosted runner on an isolated Vagrant VM (`192.168.56.11`).
- Configure branch-based continuous deployment pipelines:
  - Push to `develop` -> Trigger CI -> Auto-deploy to `staging` environment via `deploy-staging.yml`.
  - Push to `main` -> Trigger CI -> Require passing tests -> Deploy to `production` via `deploy-production.yml`.
- Execute automated Docker Compose deployments using environment configuration overrides (`docker-compose.staging.yml` and `docker-compose.prod.yml`).
- Implement automated verification routines (`health-check.sh`) and scheduled synthetic monitoring (`health-check.yml`).

---

## 2. Architecture and Complete End-to-End Workflow Breakdown

### 2.1 Complete CI/CD Architecture Flowchart

```
[Developer Workstation]
       |
       |  git push origin develop / main
       v
+-------------------------------------------------------------------------+
| GITHUB PLATFORM                                                         |
|                                                                         |
|  [Workflow: CI Pipeline (ci.yml)]                                       |
|  - Runs on: ubuntu-latest                                               |
|  - Buildx verification & image build dry-runs                           |
|       |                                                                 |
|       | (workflow_run completed == 'success')                           |
|       v                                                                 |
|  [Workflow: CD Deployment]                                              |
|  - develop branch  -> triggers deploy-staging.yml (runs-on: self-hosted) |
|  - main branch     -> triggers deploy-production.yml (runs-on: self-hosted)
+-----------------------+-------------------------------------------------+
                        | Long-polling via GitHub Runner Agent
                        v
+-------------------------------------------------------------------------+
| PRIVATE RUNNER INFRASTRUCTURE (Vagrant VM - 192.168.56.11)              |
| Hostname: runner-node1                                                  |
| OS: Ubuntu 22.04 LTS | Engine: Docker Engine & Compose                  |
|                                                                         |
|  1. actions-runner process picks up deployment job                      |
|  2. Injects secrets into local .env (${{ secrets.DATABASE_USER }}, etc)  |
|  3. Executes: ./scripts/deploy.sh [staging | production]                |
|  4. Runs: ./scripts/health-check.sh [staging | production]              |
|                                                                         |
|  [Staging Stack]                |  [Production Stack]                   |
|  - vote on port 5001            |  - vote on port 8082                  |
|  - result on port 5002          |  - result on port 3002                |
|  - isolated database & redis    |  - isolated database & redis          |
+-------------------------------------------------------------------------+
                        ^
                        | Scheduled every 15 mins (cron)
+-----------------------+-------------------------------------------------+
| SYNTHETIC MONITORING (health-check.yml)                                 |
| - Polls HTTP endpoints: /health                                         |
| - Raises alerts upon HTTP non-200 responses                             |
+-------------------------------------------------------------------------+
```

---

## 3. Configuration Breakdown

### 3.1 Self-Hosted Staging Deployment Workflow (`deploy-staging.yml`)

```yaml
name: CD - Despliegue a Staging

on:
  workflow_run:
    workflows: ["CI Pipeline"]
    types:
      - completed
    branches:
      - develop

jobs:
  deploy:
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    runs-on: self-hosted-staging

    steps:
      - name: Checkout Source Code
        uses: actions/checkout@v4

      - name: Configure Staging Environment (.env)
        run: |
          cd ./voting-app/roxs-voting-app
          echo "REDIS_HOST=redis" > .env
          echo "DATABASE_HOST=database" >> .env
          echo "DATABASE_USER=${{ secrets.DATABASE_USER }}" >> .env
          echo "DATABASE_PASSWORD=${{ secrets.DATABASE_PASSWORD }}" >> .env
          echo "DATABASE_NAME=${{ secrets.DATABASE_NAME }}" >> .env

      - name: Execute Deployment Script
        run: |
          cd ./voting-app/roxs-voting-app
          ./scripts/deploy.sh staging

      - name: Run Verification Health Checks
        run: |
          cd ./voting-app/roxs-voting-app
          ./scripts/health-check.sh staging
```

### 3.2 Automated Deployment Script Logic (`deploy.sh`)

```bash
#!/bin/bash
set -e
ENVIRONMENT=${1:-development}
PROJECT_DIR=$(dirname $(dirname $(realpath $0)))

echo "Starting deployment for environment: $ENVIRONMENT"

case $ENVIRONMENT in
    development)
        docker compose -f $PROJECT_DIR/docker-compose.yml up -d --remove-orphans
        ;;
    staging)
        docker compose -f $PROJECT_DIR/docker-compose.staging.yml up -d --remove-orphans
        ;;
    production)
        docker compose -f $PROJECT_DIR/docker-compose.prod.yml up -d --remove-orphans
        ;;
    *)
        echo "Invalid target environment. Options: development, staging, production"
        exit 1
        ;;
esac

echo "Deployment completed successfully for $ENVIRONMENT"
```

---

## 4. Step-by-Step Reproducible Execution Commands

### 4.1 Provision Runner VM and Register Agent

```bash
# Provision dedicated runner VM
cd /home/david/git/devops-porfolio/daily-exercises/semana-3/dia18-self-hosted
vagrant up
vagrant ssh

# Inside the VM: download and configure runner
mkdir -p ~/actions-runner && cd ~/actions-runner
curl -o actions-runner-linux-x64-2.311.0.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz
tar xzf ./actions-runner-linux-x64-2.311.0.tar.gz

# Configure runner with repository registration token
./config.sh --url https://github.com/DavidBritto/devops-portfolio \
  --token <REGISTRATION_TOKEN> \
  --name "vagrant-runner-node1" \
  --labels "self-hosted,self-hosted-staging,linux,x64"

# Install as systemd background service
sudo ./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh status
```

### 4.2 Trigger Pipeline via Git Branch Push

```bash
# On host machine: commit feature change to develop
git checkout develop
git add .
git commit -m "feat(api): optimize database connection pooling"
git push origin develop
```

---

## 5. Real-World Verification Methods

```bash
# 1. Check status of self-hosted runner service
vagrant ssh -c "sudo ~/actions-runner/svc.sh status"

# 2. Verify running containers in staging environment
docker ps --filter "name=staging" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# 3. Test HTTP responsiveness of staging endpoints
curl -sI http://localhost:5001 | head -n 3
curl -sI http://localhost:5002 | head -n 3

# 4. Execute automated health-check suite directly
cd /home/david/git/devops-porfolio/voting-app/roxs-voting-app
./scripts/health-check.sh staging
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **GitHub Runner Disconnections and Orphaned Tasks**:
   - Issue: Running `./run.sh` in an interactive SSH session terminates as soon as the terminal closes.
   - Solution: Always install the runner as a systemd daemon (`sudo ./svc.sh install && sudo ./svc.sh start`). This ensures automatic restarts upon system reboots or crash failures.

2. **Secrets Leaks in `.env` Files During CI Steps**:
   - Issue: Secrets committed or logged directly during `echo` commands.
   - Solution: Use GitHub Actions repository secrets (`${{ secrets.VAR }}`), ensure `.env` is listed in `.gitignore`, and configure `::add-mask::` if secrets need to be manipulated in shell steps.

3. **Port Collisions Between Staging and Production**:
   - Issue: Staging and production instances failing to bind to port 8080 or 3000 on the same runner host.
   - Solution: Externalize host ports per environment: Development uses 8080/3000, Staging uses 5001/5002, and Production uses 8082/3002.
