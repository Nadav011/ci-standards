# devenv-flutter.nix — תבנית Devenv לפרויקטי Flutter / Dart
#
# שימוש:
#   1. העתק לשורש הפרויקט בשם devenv.nix
#   2. ודא ש-devenv.yaml קיים (ראה devenv.yaml בתיקייה זו)
#   3. הפעל: devenv shell
#
# PLACEHOLDER — התאם לפני שימוש:
#   PROJECT_NAME:   my-project        # שם הפרויקט
#   FLUTTER_PATH:   ~/.flutter-sdk    # נתיב Flutter SDK (שתי המכונות זהות)
#   FLUTTER_PORT:   12345             # פורט devtools
#
# פרויקטים שמשתמשים בתבנית זו:
#   SportChat (~/Desktop/SportChat/sportchat_ultimate)
#
# הערה חשובה (RULE-msi-flutter-path):
#   Flutter נמצא ב-~/.flutter-sdk/bin/flutter על שתי המכונות.
#   לעולם אל תשתמש ב-~/.local/bin/flutter (לא קיים).
#
# הערה נוספת (RULE-flutter-test-command):
#   לעולם אל תשתמש ב-"flutter test" ישירות.
#   תמיד: very_good test --coverage --fail-fast

{ pkgs, lib, config, inputs, ... }:

{
  # ─── שפות ───────────────────────────────────────────────────────────────────

  languages.dart = {
    enable = true;

    # flutter מופעל — מוריד Flutter SDK דרך Nix
    # PLACEHOLDER: ודא שגרסת Flutter תואמת ל-pubspec.yaml
    # Flutter 3.41.2 / Dart 3.11 (stack הנוכחי)
    flutter.enable = true;
  };

  # ─── חבילות ─────────────────────────────────────────────────────────────────

  packages = with pkgs; [
    # very_good_cli — wrapper לפקודות flutter עם fail-fast + coverage
    # שימוש: very_good test --coverage --fail-fast
    # (ראה RULE-flutter-test-command — NEVER plain flutter test)
    # very_good_cli  # אם זמין ב-nixpkgs, אחרת ראה scripts.setup למטה

    # melos — מנהל monorepo ל-Dart/Flutter
    # שימוש: melos run test | melos bootstrap
    # melos  # אם זמין ב-nixpkgs, אחרת ראה scripts.setup

    # כלי ניתוח
    lcov    # להצגת דוחות coverage

    # כלי עזר
    jq
    curl

    # Android build tools (הסר אם iOS-only)
    # openjdk17  # JDK לבניית Android
  ];

  # ─── משתני סביבה ────────────────────────────────────────────────────────────

  env = {
    # ────── Dart VM ──────
    # זיכרון מוגדל ל-Dart VM — חיוני עם build_runner + freezed
    # 16384 MB = 16 GB (ראה MEMORY.md: DART_VM_OPTIONS=16384)
    DART_VM_OPTIONS = "--max-old-space-size=16384";

    # ────── Flutter ──────
    # כבה analytics של Flutter — חסכון ב-bandwidth + privacy
    FLUTTER_CLI_TELEMETRY = "false";

    # נתיב Flutter SDK — חובה להיות עקבי עם RULE-msi-flutter-path
    # PLACEHOLDER: ודא שהנתיב נכון על המכונה שלך
    # הנתיב ~/.flutter-sdk/bin מתווסף ל-PATH אוטומטית
    FLUTTER_ROOT = "$HOME/.flutter-sdk";

    # ────── Android ──────
    # PLACEHOLDER: הגדר אם בונה ל-Android
    # ANDROID_HOME = "$HOME/Android/Sdk";
    # ANDROID_SDK_ROOT = "$HOME/Android/Sdk";

    # ────── Supabase ─────
    # PLACEHOLDER: אם הפרויקט מתחבר ל-Supabase
    # SUPABASE_URL = "";
    # SUPABASE_ANON_KEY = "";

    # ────── Sentry ───────
    # PLACEHOLDER: אם Sentry מופעל
    # SENTRY_DSN = "";
  };

  # ─── Pre-commit hooks ────────────────────────────────────────────────────────

  pre-commit.hooks = {
    # dart format — פורמט קוד Dart לפני כל commit
    # מקביל ל-biome בעולם JavaScript
    dart-format = {
      enable = true;
      name = "dart format";
      # PLACEHOLDER: שנה ל-~/.flutter-sdk/bin/dart אם dart לא ב-PATH
      entry = "dart format";
      files = "\\.dart$";
      language = "system";
      pass_filenames = true;
    };

    # dart analyze — בדיקה סטטית לפני commit
    # מגביל ל-60 שניות כדי לא לחסום עבודה
    dart-analyze = {
      enable = true;
      name = "dart analyze";
      entry = "dart analyze --fatal-infos";
      files = "\\.dart$";
      language = "system";
      pass_filenames = false;
    };

    # בדיקת RTL ב-Flutter — חוק APEX Flutter RTL
    # (ראה past-mistakes.md: Flutter/Dart RTL section)
    flutter-rtl-check = {
      enable = true;
      name = "Flutter RTL check";
      entry = ''bash -c '
        VIOLATIONS=$(git diff --cached --name-only | grep "\.dart$" | \
          xargs grep -lnE "EdgeInsets\.only\(left|EdgeInsets\.only\(right|Padding\(EdgeInsets\.only\(left|Alignment\.topLeft|Alignment\.topRight|Positioned\(left|Positioned\(right" 2>/dev/null)
        if [ -n "$VIOLATIONS" ]; then
          echo "❌ Flutter RTL violation נמצא ב:"
          echo "$VIOLATIONS"
          echo "השתמש ב-EdgeInsetsDirectional, AlignmentDirectional, PositionedDirectional"
          exit 1
        fi
      ' '';
      language = "system";
      pass_filenames = false;
    };

    # בדיקת IconButton ללא tooltip — WCAG 4.1.2
    # (ראה past-mistakes.md: Flutter/Dart audit)
    flutter-a11y-check = {
      enable = true;
      name = "Flutter a11y — IconButton tooltip";
      entry = ''bash -c '
        MISSING=$(git diff --cached --name-only | grep "\.dart$" | \
          xargs grep -lnP "IconButton\((?!.*tooltip)" 2>/dev/null)
        if [ -n "$MISSING" ]; then
          echo "⚠️  IconButton ללא tooltip נמצא (WCAG 4.1.2) ב:"
          echo "$MISSING"
          echo "הוסף: tooltip: 'תיאור הפעולה'"
          exit 1
        fi
      ' '';
      language = "system";
      pass_filenames = false;
    };

    # מניעת commit של קבצים שנוצרו אוטומטית
    no-generated-files = {
      enable = true;
      name = "no generated files";
      entry = ''bash -c 'git diff --cached --name-only | grep -E "\.(g\.dart|freezed\.dart)$" && echo "⚠️  קבצים שנוצרו אוטומטית — ודא שכוונת ל-commit אותם" && exit 0 || exit 0' '';
      language = "system";
      pass_filenames = false;
    };
  };

  # ─── תהליכים ────────────────────────────────────────────────────────────────

  processes = {
    # הרצת אפליקציה במכשיר/אמולטור
    # PLACEHOLDER: הוסף device ID אם יש מכשיר ספציפי
    # שימוש: devenv up run
    run = {
      exec = "$HOME/.flutter-sdk/bin/flutter run --debug";
    };

    # הרצת בדיקות ב-watch mode — מפעיל very_good_cli
    # (ראה RULE-flutter-test-command — NEVER plain flutter test)
    test-watch = {
      exec = "very_good test --coverage --fail-fast";
    };

    # DevTools — ניתוח performance + memory
    devtools = {
      exec = "$HOME/.flutter-sdk/bin/flutter pub global run devtools --port 12345";
    };
  };

  # ─── Scripts ────────────────────────────────────────────────────────────────

  scripts = {
    # התקנת CLI tools שלא זמינים ב-nixpkgs
    setup.exec = ''
      echo "📦 מתקין Flutter CLI tools..."
      $HOME/.flutter-sdk/bin/flutter pub global activate very_good_cli
      $HOME/.flutter-sdk/bin/flutter pub global activate melos
      $HOME/.flutter-sdk/bin/flutter pub global activate flutter_gen
      echo "✅ התקנה הושלמה"
      echo ""
      echo "הוסף לנתיב (אם לא קיים):"
      echo "  export PATH=\"\$PATH:\$HOME/.pub-cache/bin\""
    '';

    # הרצת build_runner — לפני run/test
    build-runner.exec = ''
      echo "⚙️  מריץ build_runner..."
      $HOME/.flutter-sdk/bin/flutter pub run build_runner build --delete-conflicting-outputs
      echo "✅ build_runner הושלם"
    '';

    # ניתוח סטטי מלא
    analyze.exec = ''
      echo "🔍 מריץ flutter analyze..."
      $HOME/.flutter-sdk/bin/flutter analyze 2>&1 | tee /tmp/flutter-analyze.log
      ERRORS=$(grep -c "error •" /tmp/flutter-analyze.log || echo 0)
      echo ""
      echo "סה\"כ שגיאות: $ERRORS"
    '';

    # בדיקות עם coverage — FEATURE tier
    test-full.exec = ''
      echo "🧪 מריץ very_good test --coverage..."
      very_good test --coverage --fail-fast
      echo ""
      echo "📊 Coverage report:"
      genhtml coverage/lcov.info -o coverage/html --quiet
      echo "Coverage HTML נוצר ב: coverage/html/index.html"
    '';

    # בנייה ל-Android (APK חתום)
    # RULE: Flutter Play Store = appbundle (לא APK לבדיקה בלבד)
    build-android.exec = ''
      echo "🤖 בונה Android App Bundle..."
      $HOME/.flutter-sdk/bin/flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
      echo "✅ AAB נוצר ב: build/app/outputs/bundle/release/"
    '';

    # בנייה ל-iOS (archive לשחרור)
    build-ios.exec = ''
      echo "🍎 בונה iOS archive..."
      $HOME/.flutter-sdk/bin/flutter build ipa --release --obfuscate --split-debug-info=build/debug-info
      echo "✅ IPA נוצר ב: build/ios/ipa/"
    '';

    # bדיקה מלאה — FEATURE tier לפני PR
    check-full.exec = ''
      echo "🔍 בדיקה מלאה לפני PR..."
      dart analyze --fatal-infos && echo "✅ analyze" && \
      very_good test --coverage --fail-fast && echo "✅ tests" && \
      echo "Done ✓ — ready for PR"
    '';
  };

  # ─── הגדרות devenv כלליות ────────────────────────────────────────────────────

  devenv = {
    root = ".devenv";
  };
}
