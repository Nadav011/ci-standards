# devenv-vite-react.nix — תבנית Devenv לפרויקטי Vite + React
#
# שימוש:
#   1. העתק לשורש הפרויקט בשם devenv.nix
#   2. ודא ש-devenv.yaml קיים (ראה devenv.yaml בתיקייה זו)
#   3. הפעל: devenv shell
#
# PLACEHOLDER — התאם לפני שימוש:
#   PROJECT_NAME: my-project       # שם הפרויקט
#   NODE_VERSION: nodejs_24        # גרסת Node — nodejs_22 | nodejs_24
#   MAIN_BRANCH:  main             # main | master
#
# פרויקטים שמשתמשים בתבנית זו:
#   mexicani, shifts, brain, hatumdigital, signature-pro, nadavai

{ pkgs, lib, config, inputs, ... }:

{
  # ─── שפות ───────────────────────────────────────────────────────────────────

  languages.javascript = {
    enable = true;

    # PLACEHOLDER: NODE_VERSION — החלף ל-nodejs_22 אם צריך
    package = pkgs.nodejs_24;

    # pnpm מופעל — חריג יחיד: פרויקט Z/cash משתמש ב-npm
    pnpm = {
      enable = true;

      # מריץ pnpm install אוטומטית בכניסה ל-shell
      install.enable = true;
    };
  };

  # ─── חבילות ─────────────────────────────────────────────────────────────────

  packages = with pkgs; [
    # Biome — linter + formatter (מחליף ESLint + Prettier)
    # גרסה 2.4.4+ נדרשת לתאימות Tailwind 4.2
    biome

    # act — הרצת GitHub Actions CI מקומית (docker נדרש)
    # שימוש: act push | act -j typecheck
    act

    # כלי עזר כלליים
    jq
    curl
  ];

  # ─── Playwright לבדיקות E2E ──────────────────────────────────────────────────
  # הסר את הבלוק הזה אם הפרויקט לא כולל בדיקות E2E

  # playwright-driver מאפשר הרצת chromium מבלי להוריד דפדפן ידנית
  # לאחר `devenv shell` הפעל: pnpm exec playwright install chromium
  env.PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
  env.PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";

  # ─── משתני סביבה ────────────────────────────────────────────────────────────

  env = {
    # מגביל זיכרון ל-Node.js — חיוני עם pnpm + vitest + TypeScript
    NODE_OPTIONS = "--max-old-space-size=4096";

    # משתה הדיגום — ייוצא רק בסביבת dev
    NODE_ENV = "development";

    # PLACEHOLDER: הוסף כאן את ה-env vars של הפרויקט שלך
    # VITE_SUPABASE_URL = "";
    # VITE_SUPABASE_ANON_KEY = "";
  };

  # ─── Pre-commit hooks ────────────────────────────────────────────────────────

  pre-commit.hooks = {
    # Biome — בדיקת format ו-lint לפני כל commit
    # מקביל ל-lint-staged עם biome check
    biome = {
      enable = true;
      name = "biome check";
      entry = "biome check --write --unsafe";
      files = "\\.(ts|tsx|js|jsx|json)$";
      language = "system";
      pass_filenames = true;
    };

    # מניעת commit של console.log ב-production code
    # קבצי test מותרים (ראה APEX check-console-log.sh)
    no-console = {
      enable = true;
      name = "no console.log";
      entry = ''bash -c 'git diff --cached --name-only | grep -E "\.(ts|tsx|js|jsx)$" | grep -v "\.(test|spec)\." | xargs grep -l "console\.log" && echo "❌ נמצאו console.log — הסר לפני commit" && exit 1 || exit 0' '';
      language = "system";
      pass_filenames = false;
    };

    # בדיקת RTL — חסימת שימוש ב-ml-/mr-/pl-/pr- (חוק APEX #5)
    rtl-check = {
      enable = true;
      name = "RTL classes check";
      entry = ''bash -c 'git diff --cached --name-only | grep -E "\.(tsx|jsx)$" | xargs grep -lE "className=.*\b(ml-|mr-|pl-|pr-)" 2>/dev/null && echo "❌ RTL violation — השתמש ב-ms-/me-/ps-/pe- במקום" && exit 1 || exit 0' '';
      language = "system";
      pass_filenames = false;
    };
  };

  # ─── תהליכים (processes) ─────────────────────────────────────────────────────
  # הפעלה: devenv up | devenv up dev | devenv up test-watch

  processes = {
    # שרת פיתוח עם HMR
    # PLACEHOLDER: שנה ל-"npm run dev" אם הפרויקט הוא Z/cash
    dev = {
      exec = "pnpm dev";
      process-compose.readiness_probe = {
        http_get = {
          host = "localhost";
          port = 5173;           # PLACEHOLDER: שנה לפי vite.config.ts
          path = "/";
        };
        initial_delay_seconds = 2;
        period_seconds = 5;
      };
    };

    # Vitest במצב watch — לפיתוח TDD
    # ראה RULE-flutter-test-command: לא very_good כאן אבל --maxWorkers=2 חשוב
    test-watch = {
      exec = "pnpm vitest --watch --reporter=verbose --maxWorkers=2";
    };

    # TypeScript type-checking רציף
    typecheck-watch = {
      exec = "pnpm tsc --noEmit --watch --preserveWatchOutput";
    };
  };

  # ─── Scripts נוחים ──────────────────────────────────────────────────────────

  scripts = {
    # בדיקה מהירה — typecheck + lint + test (MEDIUM tier)
    check.exec = ''
      echo "🔍 Running medium-tier verification..."
      pnpm run typecheck && echo "✅ typecheck" && \
      pnpm run lint      && echo "✅ lint"      && \
      echo "Done ✓"
    '';

    # בדיקה מלאה — FEATURE tier (כולל trivy)
    check-full.exec = ''
      echo "🔍 Running feature-tier verification..."
      pnpm run typecheck && echo "✅ typecheck" && \
      pnpm run lint      && echo "✅ lint"      && \
      pnpm run test      && echo "✅ tests"     && \
      trivy fs . --severity HIGH,CRITICAL && echo "✅ trivy" && \
      echo "Done ✓ — ready for PR"
    '';

    # הרצת CI מקומית עם act
    ci-local.exec = "act push --rm";
  };

  # ─── הגדרות devenv כלליות ────────────────────────────────────────────────────

  devenv = {
    # שמור state בין sessions (node_modules, cache וכו')
    root = ".devenv";
  };
}
