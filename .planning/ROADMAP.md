# Roadmap: ci-standards v1.0

**Milestone:** v1.0
**Depth:** Standard
**Coverage:** 25/25 requirements mapped

---

## Phases

- [ ] **Phase 1: Global Git Hooks** - Replace per-project Husky with a single machine-wide git hooks directory
- [ ] **Phase 2: Mexicani CI — Safety Fixes** - Eliminate the "deploy broken code to production" risk and fix GitHub Actions concurrency
- [ ] **Phase 3: Mexicani CI — Performance** - Eliminate triple builds and cut per-push CI time by 15+ minutes
- [ ] **Phase 4: Mexicani CI — Quality & Compliance** - Make security and compliance gates real (not decorative)
- [ ] **Phase 5: Reusable Workflows** - Extract mexicani's CI config into reusable workflows so all projects benefit

---

## Phase Details

### Phase 1: Global Git Hooks
**Goal**: Every git operation on any project runs the same, up-to-date hooks — no more per-project drift
**Depends on**: Nothing (first phase)
**Requirements**: HOOKS-01, HOOKS-02, HOOKS-03, HOOKS-04, HOOKS-05, HOOKS-06, HOOKS-07
**Success Criteria** (what must be TRUE):
  1. `git config --global core.hooksPath` points to `~/.git-hooks`
  2. pre-commit, pre-push, and commit-msg all exist in `~/.git-hooks` and pass shellcheck with no errors
  3. .husky/ directory is removed from all 5 projects (mexicani, cash, shifts, hatumdigital, brain) and husky is removed from their devDependencies
  4. `git commit` in any of the 5 projects runs the global pre-commit hook (observable via hook output in terminal)
  5. Hook auto-detects project type: runs `npm run lint-staged` in npm projects, `pnpm run lint-staged` in pnpm projects, and skips lint-staged in repos without package.json
**Plans**: TBD

### Phase 2: Mexicani CI — Safety Fixes
**Goal**: Pushing broken code to main can never silently succeed — CI gates production
**Depends on**: Phase 1
**Requirements**: SAFETY-01, SAFETY-02, SAFETY-03, SAFETY-04
**Success Criteria** (what must be TRUE):
  1. Pushing to main triggers deploy ONLY after the ci.yml workflow completes successfully (deploy.yml uses workflow_run trigger with conclusion == 'success')
  2. Two rapid pushes to main result in the first CI run being cancelled, not silently queued — ci.yml shows `cancel-in-progress: true`
  3. `npm audit --audit-level=high` with high severity vulnerabilities FAILS the CI build (no `|| true` escape hatch)
  4. Lighthouse CI runs against a locally-built preview served in the CI runner, not the live production URL at mexicani.vercel.app
**Plans**: TBD

### Phase 3: Mexicani CI — Performance
**Goal**: One build per push to main — not three
**Depends on**: Phase 2
**Requirements**: PERF-01, PERF-02, PERF-03, PERF-04, PERF-05
**Success Criteria** (what must be TRUE):
  1. deploy.yml shows a "download artifact" step and contains no `npm run build` step — the build produced by ci.yml is reused
  2. deploy.yml contains no typecheck or lint steps — it trusts the CI gate that already ran
  3. Subsequent CI runs with no TypeScript changes show incremental tsc output (`.tsbuildinfo` cache hit visible in Actions logs)
  4. Total wall time from push to successful deploy on main is reduced by at least 10 minutes compared to baseline
**Plans**: TBD

### Phase 4: Mexicani CI — Quality & Compliance
**Goal**: Security and compliance checks are enforced, not reported-and-ignored
**Depends on**: Phase 3
**Requirements**: QUALITY-01, QUALITY-02, QUALITY-03, QUALITY-04
**Success Criteria** (what must be TRUE):
  1. CI run includes a gitleaks job that exits non-zero on secret detection — a planted test secret causes CI to fail
  2. CI run produces a downloadable `sbom.json` artifact in the Actions run summary
  3. CI fails if coverage drops below 65% on any metric (lines, functions, branches, statements) — visible as a failing vitest step
  4. Running `git commit` in a repo without package.json (e.g., ci-standards itself) succeeds without errors — the global hook auto-bypasses package-specific checks
**Plans**: TBD

### Phase 5: Reusable Workflows
**Goal**: Any of the 5 projects can get the full CI/CD pipeline by referencing two workflow files
**Depends on**: Phase 4
**Requirements**: REUSE-01, REUSE-02, REUSE-03, REUSE-04, REUSE-05
**Success Criteria** (what must be TRUE):
  1. ci-standards repo has `.github/workflows/ci-reusable.yml` and `.github/workflows/deploy-reusable.yml` callable via `workflow_call`
  2. mexicani's ci.yml is under 30 lines — its entire body delegates to `ci-reusable.yml` via `uses:`
  3. mexicani's deploy.yml is under 20 lines — its entire body delegates to `deploy-reusable.yml` via `uses:`
  4. README contains copy-paste instructions that onboard a new project (create ci.yml + deploy.yml, set secrets) in under 5 minutes
**Plans**: TBD

---

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Global Git Hooks | 0/? | Not started | - |
| 2. Mexicani CI — Safety Fixes | 0/? | Not started | - |
| 3. Mexicani CI — Performance | 0/? | Not started | - |
| 4. Mexicani CI — Quality & Compliance | 0/? | Not started | - |
| 5. Reusable Workflows | 0/? | Not started | - |

---

*Roadmap created: 2026-03-14*
*Milestone: v1.0*
