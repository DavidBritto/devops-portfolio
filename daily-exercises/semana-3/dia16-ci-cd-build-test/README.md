# Dia 16: Continuous Integration (CI) - Automated Build and Test Suites in GitHub Actions

## 1. Technical Overview and Objective

The objective of Day 16 is to implement a robust Continuous Integration (CI) pipeline using GitHub Actions. CI is the engineering practice of automatically building and testing code on every commit and pull request to detect integration errors as early as possible. This prevents broken code, syntax errors, and regressions from merging into protected release branches.

Key goals:
- Configure GitHub Actions event triggers for branch pushes (`develop`, `main`) and pull requests (`main`).
- Set up automated testing matrix environments (Python runtime for Vote service, Node.js runtime for Result and Worker services).
- Execute static code analysis and linting (`flake8` / `eslint`) to enforce code quality standards.
- Run automated unit test suites (`pytest` for Python, `jest` / `mocha` for Node.js).
- Implement status checks that block non-compliant pull requests from merging.

---

## 2. Architecture and CI Workflow Breakdown

### 2.1 Continuous Integration Workflow Flowchart

```
[Developer Git Push / PR]
           |
           v
[GitHub Actions Trigger] -> Event: push/pull_request
           |
+----------v--------------------------------------------------------------+
| RUNNER: ubuntu-latest                                                   |
|                                                                         |
|  [Step 1: Code Checkout] -> actions/checkout@v4                         |
|                                                                         |
|  +-----------------------------------+-------------------------------+  |
|  | Job: test-python                  | Job: test-nodejs              |  |
|  | - actions/setup-python@v5         | - actions/setup-node@v4       |  |
|  | - Install flake8, pytest, deps    | - Install npm packages        |  |
|  | - Run linter (flake8)             | - Run linter (eslint)         |  |
|  | - Execute test suite (pytest)     | - Execute test suite (npm test) |
|  +-----------------+-----------------+---------------+---------------+  |
|                    |                                 |                  |
|                    +----------------+----------------+                  |
|                                     |                                   |
|                                     v                                   |
|                     [Job: build-verification]                           |
|                     - Docker build dry-run                              |
|                     - Output: Artifacts / Test Reports                  |
+-------------------------------------+-----------------------------------+
                                      |
                                      v
                      [GitHub Status Check: PASSED]
                                      |
                                      v
                       [Merge Permitted into Main]
```

---

## 3. Configuration Breakdown

### 3.1 Declarative CI Workflow (`.github/workflows/ci-build-test.yml`)

```yaml
name: CI Build and Test Suite

on:
  push:
    branches:
      - main
      - develop
  pull_request:
    branches:
      - main

jobs:
  lint-and-test-python:
    name: Python Unit Tests and Linting
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Source Code
        uses: actions/checkout@v4

      - name: Set up Python 3.11
        uses: actions/setup-python@v5
        with:
          python-version: "3.11"
          cache: "pip"

      - name: Install Dependencies
        run: |
          python -m pip install --upgrade pip
          pip install flake8 pytest
          if [ -f voting-app/roxs-voting-app/vote/requirements.txt ]; then
            pip install -r voting-app/roxs-voting-app/vote/requirements.txt
          fi

      - name: Static Code Analysis (Lint)
        run: |
          flake8 voting-app/roxs-voting-app/vote --count --select=E9,F63,F7,F82 --show-source --statistics
          flake8 voting-app/roxs-voting-app/vote --count --exit-zero --max-complexity=10 --max-line-length=127 --statistics

      - name: Execute Pytest Suite
        run: |
          pytest voting-app/roxs-voting-app/vote/tests/ -v

  lint-and-test-node:
    name: Node.js Unit Tests
    runs-on: ubuntu-latest
    strategy:
      matrix:
        service: [result, worker]
    steps:
      - name: Checkout Source Code
        uses: actions/checkout@v4

      - name: Set up Node.js 18.x
        uses: actions/setup-node@v4
        with:
          node-version: 18.x
          cache: "npm"
          cache-dependency-path: voting-app/roxs-voting-app/${{ matrix.service }}/package-lock.json

      - name: Install Node Modules
        working-directory: voting-app/roxs-voting-app/${{ matrix.service }}
        run: npm ci

      - name: Execute Test Suite
        working-directory: voting-app/roxs-voting-app/${{ matrix.service }}
        run: npm test --if-present
```

---

## 4. Step-by-Step Reproducible Execution Commands

### Local Emulation and Testing Before Push

```bash
# Navigate to repository root
cd /home/david/git/devops-porfolio

# 1. Run Python test suite locally
cd voting-app/roxs-voting-app/vote
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt pytest flake8
flake8 .
pytest tests/ -v
deactivate
cd ../../..

# 2. Run Node.js test suite locally
cd voting-app/roxs-voting-app/result
npm install
npm test
cd ../../..

# 3. Simulate GitHub Actions locally using act (optional CLI tool)
act push -j lint-and-test-python
```

---

## 5. Real-World Verification Methods

```bash
# Inspect GitHub Actions run history using GitHub CLI (gh)
gh run list --workflow="CI Build and Test Suite" --limit 5

# View detailed execution logs for the most recent run
gh run view --log

# Validate commit status checks on active branch
git status
git log -1 --format="%h - %an: %s"
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **Dependency Cache Misses and Pipeline Latency**:
   - Issue: Every CI run takes several minutes downloading repeated npm and pip packages.
   - Solution: Leverage `cache: "pip"` in `actions/setup-python` and `cache: "npm"` with `cache-dependency-path` in `actions/setup-node`. This cuts run time by up to 70%.

2. **`npm ci` vs `npm install` in Pipelines**:
   - Issue: Builds produce non-deterministic results between local dev and CI runners when `npm install` modifies `package-lock.json`.
   - Resolution: Always use `npm ci` in automated pipelines. `npm ci` requires an existing `package-lock.json` and deletes any existing `node_modules`, guaranteeing clean, reproducible builds.

3. **Flaky Unit Tests Depending on External Services**:
   - Issue: Unit tests for Vote or Worker fail intermittently when trying to connect to real Redis or Postgres sockets.
   - Resolution: Mock external network sockets using Python `unittest.mock` or Node.js test doubles. True integration tests should run in a dedicated stage utilizing GitHub Actions service containers (`services: redis: ...`).
