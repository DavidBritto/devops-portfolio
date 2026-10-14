# Dia 68: Documentation as Code - Architectural Decision Records (ADRs), Operational Runbooks, and OpenAPI Specs

## 1. Technical Overview and Objective

The objective of Day 68 is to implement "Documentation as Code" (DaC) across engineering repositories. In high-velocity DevOps teams, stale wiki pages (Confluence/Notion) or oral traditions lead to onboarding friction, operational errors during outages, and undocumented architectural drift. Treating documentation as code -- stored in Git alongside the source code, formatted in plain Markdown, validated by linters, and versioned via pull requests -- ensures that technical documentation stays synchronized with real-world infrastructure.

Key goals:
- Adopt Architectural Decision Records (ADRs) to document technical trade-offs and rationale.
- Author standardized Operational Runbooks for critical on-call alert procedures.
- Document microservice REST endpoints using OpenAPI 3.0 / Swagger specifications.
- Configure Markdown and link linters in CI to catch broken references and syntax issues.
- Maintain ASCII diagrams and architecture manifests versioned directly in Git.

---

## 2. Architecture and Documentation as Code Structure

### 2.1 Documentation Hierarchy in Repository

```
devops-portfolio/
├── docs/
│   ├── adr/                         # Architectural Decision Records
│   │   ├── 0001-use-postgresql-for-votes.md
│   │   └── 0002-adopt-helm-umbrella-chart.md
│   ├── runbooks/                    # Operational Incident Runbooks
│   │   ├── db-connection-exhaustion.md
│   │   └── redis-eviction-spike.md
│   └── api/
│       └── openapi-spec.yaml        # OpenAPI 3.0 Contract Definition
├── daily-exercises/                 # Reproducible hands-on daily engineering logs
└── README.md                        # Master Portfolio Entrypoint
```

---

## 3. Standardized Templates Breakdown

### 3.1 Architectural Decision Record Template (`docs/adr/0002-adopt-helm.md`)

```markdown
# ADR 0002: Adoption of Helm Umbrella Chart for Roxs Voting App

## Status: ACCEPTED

## Date: 2026-10-06

## Context
Deploying 5 distinct microservices using individual raw YAML manifests required managing
15+ separate files across multiple environments, causing configuration drift between staging
and production.

## Decision
We will package all microservices into an Umbrella Helm Chart ('roxs-voting-app') with
decoupled environment values ('values-dev.yaml', 'values-prod.yaml').

## Consequences
- Positive: Single-command atomic deployments and automatic rollbacks.
- Positive: Templated parameters prevent duplicate YAML definitions.
- Negative: Requires team familiarity with Go template syntax.
```

### 3.2 Operational Incident Runbook (`docs/runbooks/db-down.md`)

```markdown
# Incident Runbook: ServiceDown (PostgreSQL Database)

## Alert Summary
Triggered when 'up{job="postgres-exporter"} == 0' for more than 1 minute.

## Impact
All write operations from Worker app fail. Vote app queues up in Redis.

## Triage Steps
1. Verify container status:
   docker ps -f name=database
2. Inspect last 50 error logs:
   docker logs --tail=50 roxs-voting-app-database-1
3. Check host disk space:
   df -h /var/lib/docker

## Remediation
1. If container exited due to OOM:
   docker compose restart database
2. If disk is full:
   Run automated Docker prune and expand volume.
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# 1. Lint repository markdown files using markdownlint CLI
docker run --rm -v $(pwd):/work tmknom/markdownlint:latest \
  --ignore daily-exercises/semana-5 \
  daily-exercises/semana-10/README.md

# 2. Validate OpenAPI 3.0 specification syntax using Redocly CLI
docker run --rm -v $(pwd):/spec redocly/cli lint /spec/voting-app/roxs-voting-app/docs/openapi.yaml 2>/dev/null || true
```

---

## 5. Real-World Verification Methods

```bash
# 1. Verify all relative Markdown links in documentation are intact
# Run markdown-link-check
docker run --rm -v $(pwd):/work -w /work \
  ghcr.io/tcort/markdown-link-check:3.11.2 README.md

# 2. Verify ASCII-only format across generated portfolio READMEs
file daily-exercises/semana-10/dia-68/README.md | grep -E "ASCII|text"
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **The Wiki Grave Syndrome**:
   - Problem: Confluence or Notion pages created during project kickoffs never get updated after production changes, misleading on-call responders during outages.
   - Solution: Keep documentation in the Git repository alongside the code. Pull requests that alter infrastructure or APIs must require corresponding documentation updates to be approved.

2. **ASCII vs Unicode Formatting in Automated Tooling**:
   - Lesson: Rich unicode characters, fancy smart quotes, and unrendered icons frequently break headless CI parsers, PDF export pipelines, and text-based terminals. Strict ASCII formatting guarantees universal rendering across any environment or operating system.

3. **Actionable Runbooks vs Theory**:
   - Rule: An incident runbook must never be a theoretical architecture essay. It must follow a strict triage structure: Alert Summary, Impact, Step-by-Step CLI commands, and Escalation path.
