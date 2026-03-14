# ci-standards

Shared CI/CD infrastructure for all Nadav011 projects. One change here → all projects benefit.

## What's in here

| File | Purpose |
|------|---------|
| `hooks/pre-commit` | Global pre-commit (RTL, secrets, console.log, type safety, etc.) |
| `hooks/pre-push` | Global pre-push (typecheck only — no tests/build) |
| `hooks/commit-msg` | Conventional Commits validation |
| `install.sh` | Sets up machine-wide git hooks + ~/.gitconfig |
| `.github/workflows/ci-vite-react.yml` | Reusable CI for Vite+React projects |
| `.github/workflows/ci-nextjs.yml` | Reusable CI for Next.js projects |
| `.github/workflows/ci-flutter.yml` | Reusable CI for Flutter projects |

## Install on a machine (pop-os or MSI)

```bash
cd ~/ci-standards && git pull && bash install.sh
```

To install on MSI from pop-os via Tailscale SSH:
```bash
ssh msi 'cd ~/ci-standards && git pull && bash install.sh'
```

This sets:
- `git config core.hooksPath ~/.git-hooks` — applies to ALL repos on the machine
- `pull.rebase true`, `push.autoSetupRemote true`, `init.defaultBranch main`
- Git aliases: `git lg`, `git undo`, `git unstage`, `git branches`

## Add CI to a Vite+React project (mexicani, cash, shifts, hatumdigital...)

Create `.github/workflows/ci.yml` in the project:

```yaml
name: CI
on:
  push:
    branches: [main, feat/*, fix/*]
    paths-ignore: ["**.md"]
  pull_request:
    branches: [main]
    paths-ignore: ["**.md"]

jobs:
  ci:
    uses: Nadav011/ci-standards/.github/workflows/ci-vite-react.yml@main
    secrets: inherit
```

That's it. Handles: install → typecheck + lint + security + 4-shard tests → build → deploy (main only).

## Add CI to a Next.js project (nadavai, mediflow, vibechat...)

```yaml
name: CI
on:
  push: { branches: [main, feat/*, fix/*] }
  pull_request: { branches: [main] }

jobs:
  ci:
    uses: Nadav011/ci-standards/.github/workflows/ci-nextjs.yml@main
    with:
      package-manager: pnpm
    secrets: inherit
```

## Add CI to Flutter (sportchat)

```yaml
name: CI
on:
  push: { branches: [main, feat/*, fix/*] }
  pull_request: { branches: [main] }

jobs:
  ci:
    uses: Nadav011/ci-standards/.github/workflows/ci-flutter.yml@main
```

## Required Secrets (set per project in GitHub → Settings → Secrets)

| Secret | Required for | Where to get |
|--------|-------------|--------------|
| `VERCEL_TOKEN` | Deploy | Vercel → Account Settings → Tokens |
| `VERCEL_ORG_ID` | Deploy | Vercel project → Settings |
| `VERCEL_PROJECT_ID` | Deploy | Vercel project → Settings |

## What the hooks check

### pre-commit (~5-30s, runs on staged files only)
1. Block commits to main/master (use feature branches)
2. lint-staged → Biome/ESLint on staged files
3. RTL violations → ms-/me- not ml-/mr- (Law #5)
4. console.log in source files
5. TypeScript `any` types
6. Secrets (gitleaks or fallback pattern)
7. Merge conflict markers
8. debugger statements
9. Files > 500KB
10. .env file protection
11. @ts-ignore without explanation
12. Flutter RTL (EdgeInsetsDirectional, AlignmentDirectional)
13. Python ruff/flake8

### pre-push (~2 min, runs typecheck only)
- `npm run typecheck` / `flutter analyze` / `mypy`
- **NO tests** (CI does it)
- **NO build** (CI does it)
- **NO lint** (pre-commit already did it)

### commit-msg (<1s)
- `feat(scope): description` format
- 10-100 char header
- No WIP/temp on main
