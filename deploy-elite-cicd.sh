#!/usr/bin/env bash
# Deploy Elite CI/CD Stack to ALL GitHub repos
# Deploys: AI Self-Heal workflow + Turbo Remote Cache config
#
# Usage: ./deploy-elite-cicd.sh [--dry-run]

set -euo pipefail

DRY_RUN="${1:-}"
OWNER="Nadav011"
TEMPLATE_DIR="$(dirname "$0")/templates"

# All GitHub repos
REPOS=(
  "Mexicani"
  "chance-pro"
  "nadavai"
  "design-system"
  "my-video"
  "signature-pro"
  "Z"
  "cash"
  "mexicani-shifts"
  "hatumdigital"
  "brain"
  "sportchat-ultimate"
  "vibechat"
  "israeli-finance-app"
)

# Default branches per repo
declare -A DEFAULT_BRANCHES=(
  ["Mexicani"]="main"
  ["chance-pro"]="main"
  ["nadavai"]="main"
  ["design-system"]="main"
  ["my-video"]="main"
  ["signature-pro"]="main"
  ["Z"]="main"
  ["cash"]="main"
  ["mexicani-shifts"]="main"
  ["hatumdigital"]="main"
  ["brain"]="master"
  ["sportchat-ultimate"]="main"
  ["vibechat"]="main"
  ["israeli-finance-app"]="main"
)

echo "🚀 Elite CI/CD Deployment — ${#REPOS[@]} repos"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

SUCCESS=0
FAILED=0
SKIPPED=0

for REPO in "${REPOS[@]}"; do
  BRANCH="${DEFAULT_BRANCHES[$REPO]:-main}"
  echo ""
  echo "📦 $OWNER/$REPO (branch: $BRANCH)"

  if [ "$DRY_RUN" = "--dry-run" ]; then
    echo "   [DRY RUN] Would deploy ai-self-heal.yml"
    ((SKIPPED++))
    continue
  fi

  # 1. Deploy AI Self-Heal workflow
  WORKFLOW_FILE="$TEMPLATE_DIR/ai-self-heal.yml"
  if [ -f "$WORKFLOW_FILE" ]; then
    # Check if already exists
    EXISTING=$(gh api "repos/$OWNER/$REPO/contents/.github/workflows/ai-self-heal.yml" \
      --jq '.sha' 2>/dev/null || echo "")

    CONTENT=$(base64 -w0 "$WORKFLOW_FILE")

    if [ -n "$EXISTING" ]; then
      # Update existing
      gh api --method PUT "repos/$OWNER/$REPO/contents/.github/workflows/ai-self-heal.yml" \
        -f message="ci: update AI self-heal workflow" \
        -f content="$CONTENT" \
        -f branch="$BRANCH" \
        -f sha="$EXISTING" \
        --silent 2>/dev/null && echo "   ✅ ai-self-heal.yml updated" || echo "   ⚠️  Failed to update"
    else
      # Create new
      gh api --method PUT "repos/$OWNER/$REPO/contents/.github/workflows/ai-self-heal.yml" \
        -f message="ci: add AI self-heal workflow" \
        -f content="$CONTENT" \
        -f branch="$BRANCH" \
        --silent 2>/dev/null && echo "   ✅ ai-self-heal.yml created" || echo "   ⚠️  Failed to create"
    fi
  else
    echo "   ⏳ ai-self-heal.yml not ready yet (agent still creating)"
  fi

  # 2. Add TURBO secrets (if not already set)
  for SECRET_NAME in TURBO_API TURBO_TOKEN TURBO_TEAM; do
    case "$SECRET_NAME" in
      TURBO_API)   SECRET_VALUE="http://100.82.33.122:3030" ;;
      TURBO_TOKEN) SECRET_VALUE="nadav-turbo-elite-2026" ;;
      TURBO_TEAM)  SECRET_VALUE="nadav" ;;
    esac

    gh secret set "$SECRET_NAME" \
      --repo "$OWNER/$REPO" \
      --body "$SECRET_VALUE" 2>/dev/null \
      && echo "   ✅ Secret $SECRET_NAME set" \
      || echo "   ⚠️  Secret $SECRET_NAME already exists or failed"
  done

  ((SUCCESS++))
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Success: $SUCCESS | ❌ Failed: $FAILED | ⏭️  Skipped: $SKIPPED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
