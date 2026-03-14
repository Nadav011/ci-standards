# ci-standards

## What This Is

Global CI/CD standards infrastructure for Nadav's 5 web projects (mexicani, cash, shifts, hatumdigital, brain) and Flutter project (sportchat). Provides: (1) machine-wide git hooks replacing per-project Husky, (2) reusable GitHub Actions workflows eliminating duplicated CI config, (3) fixes to critical CI/CD bugs discovered in audit.

## Core Value

One change to fix CI → all projects benefit. No broken deployments of untested code.

## Requirements

### Validated

(None yet — this is v1.0)

### Active

#### Global Git Hooks (replaces Husky everywhere)
- [ ] Global pre-commit: lint-staged + RTL + console.log + secrets + conflict markers + .env + ts-ignore
- [ ] Global pre-push: typecheck only (no lint, no build — those are CI's job)
- [ ] Global commit-msg: conventional commits validation
- [ ] git config --global core.hooksPath ~/.git-hooks applied
- [ ] Remove .husky/ from: mexicani, cash, shifts, hatumdigital, brain

#### Mexicani CI — Critical Fixes
- [ ] deploy.yml depends on ci.yml success (workflow_run trigger)
- [ ] cancel-in-progress: true in ci.yml (fix GitHub concurrency bug)
- [ ] Security scan fails the build (remove || true from npm audit)
- [ ] Lighthouse tests preview build, not production URL

#### Mexicani CI — Performance
- [ ] deploy.yml downloads build artifact from ci.yml (no rebuild)
- [ ] Remove redundant typecheck+lint from deploy.yml
- [ ] Remove build from pre-push hook
- [ ] TypeScript incremental compilation + .tsbuildinfo cache in CI

#### Mexicani CI — Quality & Compliance
- [ ] gitleaks runs in CI (not optional like in pre-commit)
- [ ] SBOM generated on every build (Cyber Resilience Act 2026)
- [ ] Coverage threshold raised to 65% minimum (from current ~53%)

#### Reusable GitHub Actions (ci-standards repo)
- [ ] ci-reusable.yml: install → typecheck+lint+security+tests → build → lighthouse
- [ ] deploy-reusable.yml: workflow_run after CI → download artifact → deploy
- [ ] mexicani converted to call reusable workflows
- [ ] Template documented for cash, shifts, hatumdigital, brain

### Out of Scope

- E2E tests in CI on every push (too slow — keep manual/nightly)
- Mutation testing in CI (Stryker runs nightly max — too slow)
- Flutter/sportchat CI changes (different machine, different scope)
- Coverage to 80%+ in one shot (gradual ratchet: 53% → 65% → 75% → 80%)

## Context

**Audit findings (Mar 14, 2026):**
- deploy.yml fires independently of ci.yml → can deploy broken code to production
- GitHub Actions cancel-in-progress: false causes queued runs to be silently cancelled (looks like "finished immediately")
- Security scan has `|| true` → always green, never blocks
- Lighthouse checks production URL, not the new build
- 3× redundant builds (pre-push + ci + deploy) on every push to main
- Husky hooks differ between projects, drift over time
- npm audit level=high with no enforcement

**Projects using npm:** mexicani (main), cash, shifts, hatumdigital, brain
**Package manager:** npm (mexicani uses npm not pnpm despite global config)

## Constraints

- **Compatibility**: Global hooks must work for npm AND pnpm projects
- **Safety**: Cannot break existing CI while fixing it (fix atomically)
- **Scope**: ci-standards repo is YAML + shell only, no package.json needed

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Replace Husky globally | Single source of truth, no drift | — Pending |
| New repo ci-standards | Reusable workflows need their own repo | — Pending |
| workflow_run over needs: | Cross-workflow dependency needs workflow_run | — Pending |
| pre-push: typecheck only | Build+lint are CI's job, not local pre-push | — Pending |

---
*Last updated: 2026-03-14 — Milestone v1.0 initialized from CI/CD audit*
