# Dia 66: Enterprise Release Engineering - Conventional Commits, Semantic Versioning, and Environment Protection Gates

## 1. Technical Overview and Objective

The objective of Day 66 is to standardize release management across enterprise CI/CD pipelines. Manual releases (creating Git tags by hand, compiling release notes manually, and deploying directly to production without oversight) introduce human error and bypass compliance audits. By enforcing the **Conventional Commits** standard, software repositories can automatically calculate the next Semantic Version (`MAJOR.MINOR.PATCH`), generate comprehensive changelogs, and enforce multi-stage environment promotion with manual approval gates.

Key goals:
- Understand Semantic Versioning 2.0.0 (`MAJOR.MINOR.PATCH`) specifications.
- Enforce Conventional Commits specification: `feat:`, `fix:`, `perf:`, `refactor:`, `BREAKING CHANGE:`.
- Automate release tagging and changelog updates via GitHub Actions.
- Configure protected GitHub Environments (`production`) requiring designated reviewer sign-off.
- Build an automated release and deployment pipeline.

---

## 2. Architecture and Release Pipeline Flow

### 2.1 Automated Release Lifecycle

```
[Developer Commits]
  - "feat(vote): add real-time websocket updates" -> Minor bump
  - "fix(db): resolve connection pool leak"       -> Patch bump
  - "feat(api)!: drop legacy v1 endpoints"        -> Major bump
           |
           v (Merged into 'main' via PR)
+-------------------------------------------------------------------------+
| GITHUB ACTIONS RELEASE WORKFLOW                                         |
|                                                                         |
|  1. Evaluates commit messages since last tag (git log)                  |
|  2. Determines SemVer increment: v1.3.4 -> v1.4.0                       |
|  3. Updates CHANGELOG.md automatically                                  |
|  4. Publishes GitHub Release with cryptographic tag                     |
|  5. Generates build release artifacts                                   |
+------------------------------------+------------------------------------+
                                     |
                                     v Deploys automatically
+------------------------------------+------------------------------------+
| ENVIRONMENT: STAGING (Auto-deploy, integration smoke tests pass)        |
+------------------------------------+------------------------------------+
                                     | Promotion requested
                                     v
+-------------------------------------------------------------------------+
| ENVIRONMENT: PRODUCTION (Protected Environment)                         |
|  - Manual approval gate triggered                                       |
|  - Designated on-call reviewer receives notification                    |
|  - Reviewer verifies staging metrics & clicks 'Approve'                 |
|  - Production deployment executes                                       |
+-------------------------------------------------------------------------+
```

---

## 3. Configuration Breakdown

### 3.1 Declarative Enterprise Release Workflow (`.github/workflows/release-enterprise.yml`)

```yaml
name: Enterprise Release & Promotion Pipeline

on:
  push:
    branches:
      - main

jobs:
  release:
    name: Compute Version and Publish Release
    runs-on: ubuntu-latest
    permissions:
      contents: write
    outputs:
      new_version: ${{ steps.version.outputs.version }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Compute Next Semantic Version
        id: version
        run: |
          # Fallback automated tag generation
          LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v1.0.0")
          echo "Previous version: $LATEST_TAG"
          # Mock version bump
          NEW_TAG="v1.1.0"
          echo "version=$NEW_TAG" >> $GITHUB_OUTPUT

      - name: Create Git Release
        uses: softprops/action-gh-release@v1
        with:
          tag_name: ${{ steps.version.outputs.version }}
          name: Release ${{ steps.version.outputs.version }}
          generate_release_notes: true

  deploy-production:
    name: Deploy to Production
    needs: release
    runs-on: self-hosted
    environment:
      name: production
      url: https://vote.company.com
    steps:
      - uses: actions/checkout@v4

      - name: Execute Production Deployment
        run: |
          echo "Deploying version ${{ needs.release.outputs.new_version }} to Production..."
          ./voting-app/roxs-voting-app/scripts/deploy.sh production
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# 1. Enforce commit message formatting locally via commitlint
npm install -g @commitlint/cli @commitlint/config-conventional
echo "module.exports = {extends: ['@commitlint/config-conventional']}" > commitlint.config.js

# 2. Test commit message validation
echo "feat(vote): add real-time voting counter" | npx commitlint
# Output: clean (valid)

echo "bad commit message without type" | npx commitlint
# Output: Error: type may not be empty [type-empty]
```

---

## 5. Real-World Verification Methods

```bash
# 1. Inspect existing CHANGELOG.md structure in repository
test -f voting-app/CHANGELOG.md && head -n 30 voting-app/CHANGELOG.md

# 2. List git tags with chronological ordering
git tag -l --sort=-creatordate | head -n 5
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **Squash Merges and Conventional Commit Loss**:
   - Issue: When a PR contains 10 conventional commits, but is squash-merged with a default title like `Merge pull request #12 from dev`, automated release tools fail to detect the feature types.
   - Solution: Configure GitHub repository settings to enforce PR title linting and populate the squash commit message directly from the PR title.

2. **Automated Release Loops in CI**:
   - Issue: The release job commits `CHANGELOG.md` back to `main`, which triggers another CI push event, creating an infinite pipeline loop.
   - Solution: Include `[skip ci]` in the release commit message: `git commit -m "chore(release): 1.1.0 [skip ci]"`.

3. **Protection Rules on Shared Runners**:
   - Lesson: Always isolate production runners from development runners. Protected environments guarantee that unreviewed pull requests cannot execute malicious code on production-privileged runners.
