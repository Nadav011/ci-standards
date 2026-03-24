# devenv-nextjs.nix — תבנית Devenv לפרויקטי Next.js
#
# שימוש:
#   1. העתק לשורש הפרויקט בשם devenv.nix
#   2. ודא ש-devenv.yaml קיים (ראה devenv.yaml בתיקייה זו)
#   3. הפעל: devenv shell
#
# PLACEHOLDER — התאם לפני שימוש:
#   PROJECT_NAME:     my-project    # שם הפרויקט
#   NODE_VERSION:     nodejs_24     # גרסת Node
#   MAIN_BRANCH:      main          # main | master
#   NEXT_PORT:        3000          # פורט שרת הפיתוח
#   SUPABASE_PROJECT: proj-ref      # ref של פרויקט Supabase (אם רלוונטי)
#
# פרויקטים שמשתמשים בתבנית זו:
#   mediflow, nadavai, vibechat, hatumdigital-next

{ pkgs, lib, config, inputs, ... }:

{
  # ─── שפות ───────────────────────────────────────────────────────────────────

  languages.javascript = {
    enable = true;

    # Next.js 16.1.6 דורש Node.js 24+ לתמיכה ב-Turbopack
    # PLACEHOLDER: NODE_VERSION
    package = pkgs.nodejs_24;

    pnpm = {
      enable = true;

      # מריץ pnpm install אוטומטית בכניסה ל-shell
      # מכיל את כל ה-dependencies כולל @sentry/nextjs + supabase-js
      install.enable = true;
    };
  };

  # ─── חבילות ─────────────────────────────────────────────────────────────────

  packages = with pkgs; [
    # Biome — linter + formatter
    biome

    # act — הרצת GitHub Actions מקומית
    act

    # כלי עזר כלליים
    jq
    curl

    # trivy — סריקת CVE מקומית לפני push
    trivy
  ];

  # ─── משתני סביבה ────────────────────────────────────────────────────────────

  env = {
    # ────── Next.js ──────
    # מכבה שליחת telemetry ל-Vercel — חובה בפרויקטים עסקיים
    NEXT_TELEMETRY_DISABLED = "1";

    # זיכרון ל-Node.js — Next.js + TypeScript + Turbopack צורכים זיכרון רב
    NODE_OPTIONS = "--max-old-space-size=4096";

    NODE_ENV = "development";

    # ────── Turbopack ────
    # Next.js 16.1.6: Turbopack פעיל כברירת מחדל ב-dev
    # אין צורך ב-NEXT_DISABLE_TURBOPACK אלא אם Sentry webpack plugin פעיל
    # (ראה RULE-turbopack-polyfill-hardcoded: 109 KB floor מובנה ב-Turbopack)
    #
    # אם Sentry webpack דרוש — הסר הערה מהשורה הבאה:
    # NEXT_DISABLE_TURBOPACK = "1";

    # ────── Supabase ─────
    # PLACEHOLDER: מלא את הערכים הנכונים מ-Supabase Dashboard
    # NEXT_PUBLIC_SUPABASE_URL = "";
    # NEXT_PUBLIC_SUPABASE_ANON_KEY = "";

    # ────── Auth ─────────
    # NEXTAUTH_SECRET = "";           # צור עם: openssl rand -base64 32
    # NEXTAUTH_URL = "http://localhost:3000";
  };

  # ─── Pre-commit hooks ────────────────────────────────────────────────────────

  pre-commit.hooks = {
    # Biome — בדיקת format ו-lint
    biome = {
      enable = true;
      name = "biome check";
      entry = "biome check --write --unsafe";
      files = "\\.(ts|tsx|js|jsx|json)$";
      language = "system";
      pass_filenames = true;
    };

    # מניעת console.log — מיוחד ל-Next.js: גם Server Components
    no-console = {
      enable = true;
      name = "no console.log";
      entry = ''bash -c 'git diff --cached --name-only | grep -E "\.(ts|tsx|js|jsx)$" | grep -v "\.(test|spec)\." | grep -v "\.stories\." | xargs grep -l "console\.log" 2>/dev/null && echo "❌ נמצאו console.log — השתמש ב-pino logger" && exit 1 || exit 0' '';
      language = "system";
      pass_filenames = false;
    };

    # בדיקת RTL — חוק APEX #5
    rtl-check = {
      enable = true;
      name = "RTL classes check";
      entry = ''bash -c 'git diff --cached --name-only | grep -E "\.(tsx|jsx)$" | xargs grep -lE "className=.*\b(ml-|mr-|pl-|pr-)" 2>/dev/null && echo "❌ RTL violation — השתמש ב-ms-/me-/ps-/pe- במקום" && exit 1 || exit 0' '';
      language = "system";
      pass_filenames = false;
    };

    # בדיקת 'server-only' — מניעת import בשגגה ב-Client Components
    # (ראה past-mistakes.md: 'server-only' ב-error.tsx גורם ל-500)
    server-only-check = {
      enable = true;
      name = "server-only boundary check";
      entry = ''bash -c 'git diff --cached --name-only | grep "error\.tsx$\|global-error\.tsx$" | xargs grep -l "server-only\|pino" 2>/dev/null && echo "❌ error.tsx לא יכול להכיל server-only imports" && exit 1 || exit 0' '';
      language = "system";
      pass_filenames = false;
    };

    # בדיקת await params — Next.js 16 דורש await params ב-Server Components
    await-params-check = {
      enable = true;
      name = "await params check (Next.js 16)";
      entry = ''bash -c 'git diff --cached --name-only | grep "app/.*page\.tsx$\|app/.*layout\.tsx$" | xargs grep -lP "params\.(slug|id|locale)\b(?!\s*\))" 2>/dev/null && echo "⚠️  ייתכן params ללא await ב-Next.js 16 — בדוק" && exit 0 || exit 0' '';
      language = "system";
      pass_filenames = false;
    };
  };

  # ─── תהליכים ────────────────────────────────────────────────────────────────

  processes = {
    # שרת פיתוח Next.js עם Turbopack
    # Turbopack פעיל אוטומטית ב-next dev (Next.js 16+)
    # PLACEHOLDER: שנה NEXT_PORT אם נדרש
    dev = {
      exec = "pnpm dev";
      process-compose.readiness_probe = {
        http_get = {
          host = "localhost";
          port = 3000;           # PLACEHOLDER: NEXT_PORT
          path = "/";
        };
        initial_delay_seconds = 3;
        period_seconds = 5;
        failure_threshold = 10; # Turbopack לוקח יותר זמן ב-cold start
      };
    };

    # Type-checking רציף — Next.js TypeScript מורכב יחסית
    typecheck-watch = {
      exec = "pnpm tsc --noEmit --watch --preserveWatchOutput";
    };

    # Vitest לבדיקות unit/integration
    # Next.js: vitest.config.ts צריך setupFiles עם "@testing-library/react"
    test-watch = {
      exec = "pnpm vitest --watch --reporter=verbose --maxWorkers=2";
    };
  };

  # ─── Scripts ────────────────────────────────────────────────────────────────

  scripts = {
    # בנייה מקומית עם ניתוח bundle
    build-analyze.exec = ''
      ANALYZE=true pnpm run build 2>&1 | tee /tmp/next-build.log
      echo ""
      echo "📦 Bundle size (.next/static/chunks/):"
      find .next/static/chunks -name "*.js" -exec du -k {} + 2>/dev/null | sort -rn | head -20
    '';

    # בדיקה מהירה — MEDIUM tier
    check.exec = ''
      echo "🔍 Running medium-tier verification..."
      pnpm run typecheck && echo "✅ typecheck" && \
      pnpm run lint      && echo "✅ lint"      && \
      echo "Done ✓"
    '';

    # בדיקה מלאה — FEATURE tier
    check-full.exec = ''
      echo "🔍 Running feature-tier verification..."
      pnpm run typecheck && echo "✅ typecheck" && \
      pnpm run lint      && echo "✅ lint"      && \
      pnpm run test      && echo "✅ tests"     && \
      trivy fs . --severity HIGH,CRITICAL && echo "✅ trivy" && \
      echo "Done ✓ — ready for PR"
    '';

    # בדיקת Supabase RLS — חשוב לפני deploy
    rls-check.exec = ''
      echo "🔐 Checking RLS patterns..."
      grep -rn "USING(true)\|auth\.uid() IS NULL" supabase/ migrations/ 2>/dev/null && \
        echo "❌ RLS vulnerability found!" && exit 1 || \
        echo "✅ No obvious RLS vulnerabilities"
    '';

    ci-local.exec = "act push --rm";
  };
}
