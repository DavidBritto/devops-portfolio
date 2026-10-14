# Dia 44: Static Application Security Testing (SAST) and Secret Detection with GitLeaks and Semgrep

## 1. Technical Overview and Objective

The objective of Day 44 is to implement automated static security analysis and secret scanning to prevent sensitive credentials and common software flaws from reaching version control. Hardcoded credentials (API tokens, private keys, database connection strings) committed into Git repositories represent one of the most common vectors for cloud infrastructure breaches. Combining GitLeaks for regex and entropy-based secret detection with Semgrep for semantic static application security testing (SAST) eliminates vulnerabilities before code compiles or deploys.

Key goals:
- Understand entropy analysis and pattern matching in secret detection engines.
- Configure GitLeaks to audit entire Git commit histories and PR diffs.
- Deploy Semgrep to detect Common Weakness Enumerations (CWEs) and OWASP Top 10 flaws in Python and Node.js code.
- Implement an automated SAST and Secret Scanning workflow in GitHub Actions.
- Remediate and purge detected leaks from Git commit histories using `git-filter-repo`.

---

## 2. Architecture and Scanning Workflow Breakdown

### 2.1 GitLeaks and Semgrep Integration in Pipeline

```
[Developer Pull Request]
           |
           +---> [GitLeaks Scanning Engine]
           |     - High-entropy string detection (Shannon entropy > 4.5)
           |     - 100+ Pre-compiled regex patterns (AWS, GitHub, Slack tokens)
           |     - Audits: git log origin/main..HEAD
           |     |
           |     +---> Match Found? ---> Block PR & Flag Credential for Immediate Revocation
           |
           +---> [Semgrep SAST Engine]
                 - Parses Abstract Syntax Trees (AST)
                 - Detects: SQL injection, hardcoded cryptographic keys, XSS
                 - Rulesets: p/ci, p/owasp-top-ten
                 |
                 +---> Violation Found? ---> Fail Build with Remediation Guidelines
```

---

## 3. Configuration Breakdown

### 3.1 Custom GitLeaks Configuration (`.gitleaks.toml`)

```toml
[extend]
useDefault = true

[allowlist]
description = "Global allowlist for non-sensitive local development paths"
paths = [
  '''(^|/)tests/''',
  '''(^|/)\.venv/''',
  '''(^|/)node_modules/'''
]
regexes = [
  '''example-secret-key-do-not-use''',
  '''SuperSecurePostgresPassword123'''
]
```

### 3.2 GitHub Actions SAST Workflow (`.github/workflows/security-sast.yml`)

```yaml
name: Security - SAST and Secret Scanning

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  gitleaks:
    name: GitLeaks Secret Scan
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Run GitLeaks
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  semgrep:
    name: Semgrep SAST Scan
    runs-on: ubuntu-latest
    container:
      image: semgrep/semgrep:latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Execute Semgrep Rules
        run: semgrep scan --config auto --error --exclude "tests/"
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# 1. Run GitLeaks locally on the current directory
docker run --rm -v $(pwd):/path zricethezav/gitleaks:latest detect --source="/path" -v

# 2. Run GitLeaks specifically on Git commit history
docker run --rm -v $(pwd):/path zricethezav/gitleaks:latest git --source="/path" --log-opts="--all"

# 3. Run Semgrep locally against microservice source code
docker run --rm -v $(pwd):/src semgrep/semgrep semgrep scan /src/voting-app/roxs-voting-app \
  --config "p/owasp-top-ten"
```

---

## 5. Real-World Verification Methods

```bash
# 1. Verify exit codes: GitLeaks returns exit code 1 upon leak detection
docker run --rm -v $(pwd):/path zricethezav/gitleaks:latest detect --source="/path" --no-git
echo "GitLeaks Exit Code: $?"

# 2. Inspect generated JSON reports
docker run --rm -v $(pwd):/path zricethezav/gitleaks:latest detect --source="/path" --report-path=/path/gitleaks-report.json
cat gitleaks-report.json | grep -i "findings" || echo "No leaks found"
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **Leaked Secrets Committed to History**:
   - Issue: A developer commits an AWS key, realizes the error, deletes the file in a subsequent commit, and pushes to remote.
   - Danger: The secret remains permanently readable in Git historical commit objects (`git log -p`).
   - Solution: Immediately rotate/revoke the credential at the cloud provider. Use `git-filter-repo` or BFG Repo-Cleaner to rewrite history and purge the commit before force-pushing.

2. **AST-Based SAST vs Naive Regex Grep**:
   - Lesson: Simple `grep` scripts flag variable names like `apiKey` in comments and test files, creating alert fatigue. Semantic scanners like Semgrep parse the Abstract Syntax Tree (AST), differentiating between actual unsafe data flows (taint mode) and harmless variable declarations.

3. **Shallow Clones in CI**:
   - Issue: GitLeaks in CI outputs zero findings on historical commits because `actions/checkout` defaults to `fetch-depth: 1` (shallow clone).
   - Solution: Always configure `fetch-depth: 0` in GitHub Actions for secret scanning workflows to inspect complete Git reflogs.
