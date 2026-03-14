# Requirements: ci-standards

**Defined:** 2026-03-14
**Core Value:** One change to fix CI → all projects benefit. No broken deployments of untested code.

## v1 Requirements

### HOOKS — Global Git Hooks (replaces Husky)

- [ ] **HOOKS-01**: Machine has `~/.git-hooks/pre-commit` with all 10 checks (lint, RTL, console.log, secrets, conflicts, debugger, large files, .env, ts-ignore, branch protection)
- [ ] **HOOKS-02**: Machine has `~/.git-hooks/pre-push` with typecheck only (no lint, no build)
- [ ] **HOOKS-03**: Machine has `~/.git-hooks/commit-msg` with conventional commits + length validation
- [ ] **HOOKS-04**: `git config --global core.hooksPath ~/.git-hooks` is set
- [ ] **HOOKS-05**: Global hooks detect project type (npm vs pnpm vs no-package) and use correct commands
- [ ] **HOOKS-06**: .husky/ removed from mexicani, cash, shifts, hatumdigital, brain
- [ ] **HOOKS-07**: husky removed from devDependencies in all 5 projects

### SAFETY — Mexicani CI Critical Fixes

- [ ] **SAFETY-01**: deploy.yml only runs after ci.yml succeeds (workflow_run trigger, conclusion == 'success')
- [ ] **SAFETY-02**: ci.yml concurrency cancel-in-progress changed from false to true
- [ ] **SAFETY-03**: Security job fails the CI run (remove `|| true` from npm audit)
- [ ] **SAFETY-04**: Lighthouse CI tests a locally-built preview (not https://mexicani.vercel.app/)

### PERF — Mexicani CI Performance

- [ ] **PERF-01**: deploy.yml downloads dist/ artifact from ci.yml instead of rebuilding
- [ ] **PERF-02**: deploy.yml does not re-run typecheck or lint (trusts CI gate)
- [ ] **PERF-03**: pre-push hook removed from mexicani (replaced by global HOOKS-02)
- [ ] **PERF-04**: TypeScript typecheck uses --incremental flag in CI
- [ ] **PERF-05**: .tsbuildinfo cached between CI runs using actions/cache

### QUALITY — Mexicani CI Quality & Compliance

- [ ] **QUALITY-01**: gitleaks runs as CI job (not optional like in pre-commit)
- [ ] **QUALITY-02**: SBOM generated as CI artifact using @cyclonedx/cyclonedx-npm
- [ ] **QUALITY-03**: Coverage threshold enforced at minimum 65% (lines, functions, branches, statements)
- [ ] **QUALITY-04**: git-commit-guard.sh hook auto-bypasses for repos without package.json

### REUSE — Reusable GitHub Actions Workflows

- [ ] **REUSE-01**: ci-standards repo has `.github/workflows/ci-reusable.yml` (callable)
- [ ] **REUSE-02**: ci-standards repo has `.github/workflows/deploy-reusable.yml` (callable, depends on CI)
- [ ] **REUSE-03**: mexicani's ci.yml calls ci-reusable.yml with `uses:` instead of inline jobs
- [ ] **REUSE-04**: mexicani's deploy.yml calls deploy-reusable.yml with `uses:`
- [ ] **REUSE-05**: README documents how to onboard cash, shifts, hatumdigital, brain

## v2 Requirements

### E2E Automation

- **E2E-01**: Smoke E2E tests run automatically on every PR (tagged subset)
- **E2E-02**: Full E2E suite runs nightly via cron trigger
- **E2E-03**: Visual regression (Percy) runs on PRs touching UI components

### Coverage Ratchet

- **COV-01**: Coverage threshold increases to 75% after 2 months
- **COV-02**: Coverage threshold increases to 80% after 4 months
- **COV-03**: Per-module coverage gates (critical modules: 90%)

### Other Projects

- **OTHER-01**: cash converted to reusable workflows
- **OTHER-02**: shifts converted to reusable workflows
- **OTHER-03**: hatumdigital converted to reusable workflows

## Out of Scope

| Feature | Reason |
|---------|--------|
| Flutter/sportchat CI | Different machine, Dart ecosystem, separate milestone |
| E2E in CI every push | Too slow (40min+), use smoke subset only |
| Mutation testing in CI | Stryker is too slow for per-PR runs |
| 80%+ coverage immediately | Gradual ratchet from 53% is safer |
| DAST (ZAP) in CI | Infrastructure required, v2 |
| Container scanning (Trivy) | No Docker in current stack |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| HOOKS-01 | Phase 1 | Pending |
| HOOKS-02 | Phase 1 | Pending |
| HOOKS-03 | Phase 1 | Pending |
| HOOKS-04 | Phase 1 | Pending |
| HOOKS-05 | Phase 1 | Pending |
| HOOKS-06 | Phase 1 | Pending |
| HOOKS-07 | Phase 1 | Pending |
| SAFETY-01 | Phase 2 | Pending |
| SAFETY-02 | Phase 2 | Pending |
| SAFETY-03 | Phase 2 | Pending |
| SAFETY-04 | Phase 2 | Pending |
| PERF-01 | Phase 3 | Pending |
| PERF-02 | Phase 3 | Pending |
| PERF-03 | Phase 3 | Pending |
| PERF-04 | Phase 3 | Pending |
| PERF-05 | Phase 3 | Pending |
| QUALITY-01 | Phase 4 | Pending |
| QUALITY-02 | Phase 4 | Pending |
| QUALITY-03 | Phase 4 | Pending |
| QUALITY-04 | Phase 4 | Pending |
| REUSE-01 | Phase 5 | Pending |
| REUSE-02 | Phase 5 | Pending |
| REUSE-03 | Phase 5 | Pending |
| REUSE-04 | Phase 5 | Pending |
| REUSE-05 | Phase 5 | Pending |

**Coverage:**
- v1 requirements: 25 total
- Mapped to phases: 25
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-14*
*Last updated: 2026-03-14 after initial CI/CD audit*
