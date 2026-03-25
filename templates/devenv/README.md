# Devenv — סביבות פיתוח ניידות ורבייתיות

> תבניות devenv לכל סוגי הפרויקטים. devenv מבוסס על Nix — מבטיח שסביבת הפיתוח זהה על כל מכונה (pop-os, MSI, CI).

---

## מה זה devenv?

[devenv](https://devenv.sh) מגדיר סביבת פיתוח שלמה בקובץ Nix אחד:

- Node.js + pnpm/npm בגרסה מדויקת
- CLI tools (biome, act, trivy, very_good_cli)
- pre-commit hooks אוטומטיים
- תהליכי פיתוח (`pnpm dev`, `vitest --watch`)
- משתני סביבה

**תועלות:** קול-סטארט ל-developer חדש = `devenv shell` ב-30 שניות. ללא "עובד אצלי".

---

## התקנת devenv

### דרישות קדם

```bash
# Nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# devenv עצמו
nix-env -iA devenv -f https://github.com/NixOS/nixpkgs/archive/HEAD.tar.gz

# אלטרנטיבה (עם cachix — מהיר יותר):
nix-env -iA cachix -f https://github.com/NixOS/nixpkgs/archive/HEAD.tar.gz
cachix use devenv
nix-env -iA devenv -f https://github.com/NixOS/nixpkgs/archive/HEAD.tar.gz
```

### direnv (אופציונלי — מומלץ מאוד)

direnv מפעיל `devenv shell` אוטומטית בכניסה לתיקיית הפרויקט:

```bash
# התקנה
sudo apt install direnv

# הוסף ל-~/.zshrc:
eval "$(direnv hook zsh)"

# אפשור בפרויקט (פעם אחת):
direnv allow
```

---

## שימוש עם כל סוג פרויקט

### Vite + React (mexicani, shifts, brain, hatumdigital, signature-pro)

```bash
# 1. העתק תבנית לפרויקט
cp ~/ci-standards/templates/devenv/devenv-vite-react.nix ~/Desktop/mexicani/devenv.nix
cp ~/ci-standards/templates/devenv/devenv.yaml ~/Desktop/mexicani/devenv.yaml

# 2. ערוך PLACEHOLDER comments ב-devenv.nix

# 3. כנס לסביבה
cd ~/Desktop/mexicani
devenv shell

# 4. הפעל תהליכי פיתוח
devenv up            # dev + test-watch + typecheck-watch
devenv up dev        # רק שרת פיתוח
devenv up test-watch # רק vitest watch

# 5. בדיקות לפני PR
check-full           # typecheck + lint + test + trivy
```

**הערה:** פרויקט Z/cash משתמש ב-npm ולא pnpm — שנה `pnpm` ל-`npm run` ב-devenv.nix.

---

### Next.js (mediflow, nadavai, vibechat)

```bash
cp ~/ci-standards/templates/devenv/devenv-nextjs.nix ~/Desktop/mediflow/devenv.nix
cp ~/ci-standards/templates/devenv/devenv.yaml ~/Desktop/mediflow/devenv.yaml

cd ~/Desktop/mediflow
devenv shell

# Turbopack פעיל אוטומטית ב-pnpm dev (Next.js 16+)
devenv up dev

# סריקת RLS לפני deploy
rls-check

# ניתוח bundle
build-analyze
```

**הערה על Turbopack:** Next.js 16.1.6 משתמש ב-Turbopack כברירת מחדל. יש floor מובנה של 109 KB polyfill — אל תדווח עליו כ-regression. אם Sentry webpack plugin דרוש, הסר הערה מ-`NEXT_DISABLE_TURBOPACK = "1"`.

---

### Flutter / Dart (SportChat)

```bash
cp ~/ci-standards/templates/devenv/devenv-flutter.nix ~/Desktop/SportChat/sportchat_ultimate/devenv.nix
cp ~/ci-standards/templates/devenv/devenv.yaml ~/Desktop/SportChat/sportchat_ultimate/devenv.yaml

cd ~/Desktop/SportChat/sportchat_ultimate
devenv shell

# התקנת CLI tools (פעם אחת)
setup

# הרצת build_runner לפני כל דבר
build-runner

# בדיקות עם coverage
test-full

# ניתוח סטטי
analyze
```

**כללים קריטיים לפרויקט Flutter:**
- לעולם אל תשתמש ב-`flutter test` — תמיד `very_good test --coverage --fail-fast`
- Flutter SDK נמצא ב-`~/.flutter-sdk/bin/flutter` (שתי המכונות)
- `DART_VM_OPTIONS=--max-old-space-size=16384` נדרש לבניות עם build_runner

---

## אינטגרציה עם GitHub Actions (Cachix)

הוסף לכל workflow שרוצה להשתמש ב-devenv:

```yaml
# .github/workflows/my-workflow.yml
name: CI with devenv

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: [self-hosted, linux, x64, pop-os]   # חובה — ראה RULE-no-ubuntu-latest-ever
    steps:
      - uses: actions/checkout@v4

      # התקנת Nix
      - uses: DeterminateSystems/nix-installer-action@v16

      # הגדרת Cachix — מאיץ downloads ב-10x
      - uses: cachix/cachix-action@v15
        with:
          name: devenv
          authToken: ${{ secrets.CACHIX_AUTH_TOKEN }}

      # הרצת בדיקות דרך devenv
      - name: Run typecheck
        run: devenv shell -- pnpm run typecheck

      - name: Run lint
        run: devenv shell -- pnpm run lint

      - name: Run tests
        run: devenv shell -- pnpm run test

      # בניה
      - name: Build
        run: devenv shell -- pnpm run build
```

> **הערה:** ב-CI הנוכחי (`ci-standards/templates/`) אנו **לא** משתמשים ב-devenv אלא בהתקנה ישירה של Node.js + pnpm. devenv ב-CI שימושי כאשר רוצים **אחידות מוחלטת** בין local לCI, או עם packages שקשה להתקין ידנית.

---

## מדריך פתרון בעיות

### `devenv shell` לוקח יותר מ-5 דקות

```bash
# הוסף את ה-binary cache של devenv (מהיר פי 10)
cachix use devenv
# ואז:
devenv shell
```

### שגיאת permissions על Nix store

```bash
# תיקון הרשאות
sudo chown -R $(whoami) /nix/store
```

### `pnpm install` נכשל ב-devenv shell

```bash
# ודא שה-Node version נכון
node --version  # צריך להיות v24.x.x (RULE-fnm-bashrc-before-interactive-guard)

# נקה cache
pnpm store prune
pnpm install --frozen-lockfile
```

### Flutter SDK לא נמצא

```bash
# בדוק שהנתיב נכון
ls ~/.flutter-sdk/bin/flutter

# אם לא קיים — ראה RULE-msi-flutter-path
# ~/.local/bin/flutter לא קיים — תמיד ~/.flutter-sdk/bin/flutter
```

---

## קבצים בתיקייה זו

| קובץ | תיאור |
|------|-------|
| `devenv-vite-react.nix` | תבנית לפרויקטי Vite + React (mexicani, shifts, brain...) |
| `devenv-nextjs.nix` | תבנית לפרויקטי Next.js (mediflow, nadavai, vibechat) |
| `devenv-flutter.nix` | תבנית לפרויקטי Flutter/Dart (SportChat) |
| `devenv.yaml` | הגדרות nixpkgs + cachix — קובץ זה משתמש בתבניות לעיל |
| `README.md` | המסמך שאתה קורא כרגע |
