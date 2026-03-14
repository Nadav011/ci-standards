# STATE: ci-standards

*Project memory — updated at each session boundary*

---

## Project Reference

**Core value**: One change to fix CI → all projects benefit. No broken deployments of untested code.
**Milestone**: v1.0
**Current focus**: Phase 1 — Global Git Hooks

---

## Current Position

**Phase**: 1 — Global Git Hooks
**Plan**: None started
**Status**: Not started
**Last action**: Roadmap created

```
Progress: [----------] 0% — Phase 1 of 5 not started
```

---

## Phase Overview

| Phase | Name | Requirements | Status |
|-------|------|--------------|--------|
| 1 | Global Git Hooks | HOOKS-01 through HOOKS-07 | Not started |
| 2 | Mexicani CI — Safety Fixes | SAFETY-01 through SAFETY-04 | Not started |
| 3 | Mexicani CI — Performance | PERF-01 through PERF-05 | Not started |
| 4 | Mexicani CI — Quality & Compliance | QUALITY-01 through QUALITY-04 | Not started |
| 5 | Reusable Workflows | REUSE-01 through REUSE-05 | Not started |

---

## Accumulated Context

### Key Decisions Made

| Decision | Rationale |
|----------|-----------|
| Replace Husky globally | Single source of truth, no per-project drift |
| New repo ci-standards | Reusable workflows need their own repo |
| workflow_run over needs | Cross-workflow dependency requires workflow_run |
| pre-push: typecheck only | Build+lint are CI's job, not local pre-push |

### Audit Findings (Context)

- deploy.yml fires independently of ci.yml → can deploy broken code to production
- GitHub Actions cancel-in-progress: false causes silently cancelled runs
- Security scan has `|| true` → always green, never blocks
- Lighthouse checks production URL, not the new build
- 3x redundant builds (pre-push + ci + deploy) on every push to main
- Husky hooks differ between projects, drift over time

### Technical Context

- Projects using npm: mexicani, cash, shifts, hatumdigital, brain
- mexicani uses npm (not pnpm despite global config)
- Global hooks must handle: npm projects, pnpm projects, repos without package.json
- ci-standards repo: YAML + shell only, no package.json

### Blockers

None.

### TODOs

- Run `/gsd:plan-phase 1` to begin Phase 1 planning

---

## Session Continuity

**To resume**: Read this file, then read `/home/nadavcohen/ci-standards/.planning/ROADMAP.md`.
**Next command**: `/gsd:plan-phase 1`

---

*State initialized: 2026-03-14*
*Last updated: 2026-03-14*
