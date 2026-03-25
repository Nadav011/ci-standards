/**
 * @module CiPipeline
 *
 * פייפליין CI/CD מבוסס Dagger עבור פרויקטי TypeScript/Vite/Next.js.
 *
 * שלבים:
 *   base()      — קונטיינר בסיסי עם Node 24 + pnpm + תלויות מותקנות
 *   typecheck() — בדיקת טיפוסים עם tsc --noEmit
 *   lint()      — בדיקת סגנון קוד עם Biome
 *   test()      — הרצת בדיקות Vitest עם Coverage
 *   security()  — סריקת CVE עם Trivy
 *   ci()        — typecheck + lint + security במקביל, אחר כך test
 *   build()     — ci() ואז בניית dist, מחזיר ספריית dist
 *
 * שימוש:
 *   dagger call ci
 *   dagger call build export --path=./dist-output
 *
 * REQUIRED — הגדרות לפני העתקה לפרויקט:
 *   NODE_VERSION: 24     # גרסת Node (slim image)
 *   LOCKFILE: pnpm-lock.yaml
 *   TYPECHECK_CMD: pnpm typecheck
 *   LINT_CMD: pnpm lint
 *   TEST_CMD: pnpm vitest run --coverage --maxWorkers=2
 *   BUILD_CMD: pnpm build
 */

import {
  dag,
  Container,
  Directory,
  object,
  func,
  argument,
} from "@dagger.io/dagger";

/** גרסת Node.js המשמשת לקונטיינר הבסיסי */
const NODE_IMAGE = "node:24-slim";

/** זמן קצוב מרבי לכל שלב בשניות (10 דקות) */
const STEP_TIMEOUT = 600;

@object()
export class CiPipeline {
  /**
   * בונה קונטיינר בסיסי עם Node 24, corepack ו-pnpm.
   * מותקנות כל התלויות מה-lockfile (frozen — ללא שינויים).
   *
   * @param source — ספריית קוד המקור (ברירת מחדל: ספריית העבודה הנוכחית)
   * @returns קונטיינר מוכן עם node_modules מותקנים
   */
  @func()
  async base(
    @argument({ defaultPath: "." }) source: Directory
  ): Promise<Container> {
    return dag
      .container()
      .from(NODE_IMAGE)
      // התקנת כלי מערכת הנדרשים לסריקות אבטחה ובנייה
      .withExec(["apt-get", "update", "-qq"])
      .withExec([
        "apt-get",
        "install",
        "-y",
        "--no-install-recommends",
        "curl",
        "ca-certificates",
        "git",
      ])
      .withExec(["apt-get", "clean"])
      .withExec(["rm", "-rf", "/var/lib/apt/lists/*"])
      // הפעלת corepack לניהול גרסאות package manager
      .withExec(["corepack", "enable"])
      .withExec(["corepack", "prepare", "pnpm@latest", "--activate"])
      // העתקת קוד המקור וקבצי תלויות לקונטיינר
      .withDirectory("/app", source, {
        exclude: [
          "node_modules",
          "dist",
          ".next",
          "build",
          "coverage",
          ".turbo",
          "*.log",
        ],
      })
      .withWorkdir("/app")
      // התקנת תלויות מה-lockfile (מניעת שינויים בסביבת CI)
      .withExec(["pnpm", "install", "--frozen-lockfile"]);
  }

  /**
   * מריץ בדיקת טיפוסים עם TypeScript.
   * כל שגיאת טיפוס גורמת לכשל.
   *
   * @param source — ספריית קוד המקור
   * @returns קונטיינר לאחר בדיקת הטיפוסים
   */
  @func()
  async typecheck(
    @argument({ defaultPath: "." }) source: Directory
  ): Promise<Container> {
    return (await this.base(source))
      .withExec(["pnpm", "typecheck"]);
  }

  /**
   * מריץ בדיקת סגנון קוד עם Biome (או ESLint — תלוי בפרויקט).
   * מוגדר ב-package.json תחת "scripts.lint".
   *
   * @param source — ספריית קוד המקור
   * @returns קונטיינר לאחר הבדיקה
   */
  @func()
  async lint(
    @argument({ defaultPath: "." }) source: Directory
  ): Promise<Container> {
    return (await this.base(source))
      .withExec(["pnpm", "lint"]);
  }

  /**
   * מריץ את סוויטת הבדיקות עם Vitest + Coverage.
   * Coverage מדווח בפורמט v8 ונשמר כ-artifact.
   *
   * @param source — ספריית קוד המקור
   * @returns קונטיינר לאחר הרצת הבדיקות
   */
  @func()
  async test(
    @argument({ defaultPath: "." }) source: Directory
  ): Promise<Container> {
    return (await this.base(source))
      .withEnvVariable("CI", "true")
      .withEnvVariable("NODE_ENV", "test")
      .withExec(
        [
          "pnpm",
          "vitest",
          "run",
          "--coverage",
          "--maxWorkers=2",
          "--reporter=verbose",
        ]
      );
  }

  /**
   * סורק ספריות תלויות ל-CVE בחומרה HIGH ו-CRITICAL.
   * משתמש ב-Trivy המותקן מראש על ה-runner.
   * כשלון = חסימת מיזוג (ראה: rules/security/security.md).
   *
   * @param source — ספריית קוד המקור
   * @returns קונטיינר עם תוצאות הסריקה
   */
  @func()
  async security(
    @argument({ defaultPath: "." }) source: Directory
  ): Promise<Container> {
    // התקנת Trivy בתוך הקונטיינר
    const withTrivy = (await this.base(source))
      .withExec([
        "sh",
        "-c",
        [
          "curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh",
          "| sh -s -- -b /usr/local/bin v0.69.3",
        ].join(" "),
      ]);

    return withTrivy.withExec(
      [
        "trivy",
        "fs",
        ".",
        "--severity",
        "HIGH,CRITICAL",
        "--exit-code",
        "1",
        "--format",
        "table",
        "--no-progress",
      ],
          );
  }

  /**
   * מריץ את כל שלבי האימות במקביל ואחר כך את הבדיקות.
   *
   * סדר ביצוע:
   *   1. typecheck + lint + security — במקביל (Promise.all)
   *   2. test — לאחר הצלחת שלב 1
   *
   * @param source — ספריית קוד המקור
   * @returns Container — קונטיינר לאחר השלמת כל הבדיקות
   */
  @func()
  async ci(
    @argument({ defaultPath: "." }) source: Directory
  ): Promise<Container> {
    // שלב 1: הרצה מקבילית של כל בדיקות האיכות
    const [typecheckResult, lintResult, securityResult] = await Promise.all([
      this.typecheck(source),
      this.lint(source),
      this.security(source),
    ]);

    // אימות שכל השלבים המקביליים הסתיימו בהצלחה
    // (Dagger מבצע lazy evaluation — הסטדאוט מאלץ ביצוע)
    await Promise.all([
      typecheckResult.stdout(),
      lintResult.stdout(),
      securityResult.stdout(),
    ]);

    // שלב 2: הרצת הבדיקות (רק אחרי הצלחת שלב 1)
    return this.test(source);
  }

  /**
   * מריץ את כל שלבי CI ואז בונה את הפרויקט.
   * מחזיר את ספריית dist לייצוא.
   *
   * @param source — ספריית קוד המקור
   * @returns Directory — ספריית dist מוכנה לפריסה
   */
  @func()
  async build(
    @argument({ defaultPath: "." }) source: Directory
  ): Promise<Directory> {
    // הרצת כל שלבי CI תחילה
    const ciContainer = await this.ci(source);
    await ciContainer.stdout();

    // בניית הפרויקט לאחר הצלחת CI
    const buildContainer = (await this.base(source))
      .withEnvVariable("NODE_ENV", "production")
      .withExec(["pnpm", "build"]);

    // החזרת ספריית dist בלבד (לא את כל הקונטיינר)
    return buildContainer.directory("/app/dist");
  }
}
