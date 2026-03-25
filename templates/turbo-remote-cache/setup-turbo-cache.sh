#!/usr/bin/env bash
# Turborepo Remote Cache — Setup Script
# Configures a project to use the self-hosted cache on pop-os (100.82.33.122)
#
# Usage: ./setup-turbo-cache.sh [project-dir]

set -euo pipefail

PROJECT_DIR="${1:-.}"
TURBO_API="http://100.82.33.122:3030"
TURBO_TOKEN="nadav-turbo-elite-2026"
TURBO_TEAM="nadav"

echo "🔧 Setting up Turborepo Remote Cache for: $PROJECT_DIR"

# 1. Add turbo.json if not exists
if [ ! -f "$PROJECT_DIR/turbo.json" ]; then
  cp "$(dirname "$0")/turbo.json" "$PROJECT_DIR/turbo.json"
  echo "✅ Created turbo.json"
else
  echo "⚠️  turbo.json already exists — skipping"
fi

# 2. Add environment variables to .env.local (not committed)
ENV_FILE="$PROJECT_DIR/.env.local"
if ! grep -q "TURBO_API" "$ENV_FILE" 2>/dev/null; then
  cat >> "$ENV_FILE" <<EOF

# Turborepo Remote Cache (self-hosted on pop-os)
TURBO_API=$TURBO_API
TURBO_TOKEN=$TURBO_TOKEN
TURBO_TEAM=$TURBO_TEAM
EOF
  echo "✅ Added TURBO_* vars to .env.local"
fi

# 3. Add turbo to package.json scripts if pnpm project
if [ -f "$PROJECT_DIR/package.json" ]; then
  if ! grep -q '"turbo"' "$PROJECT_DIR/package.json" 2>/dev/null; then
    # Check if turbo is installed
    if ! command -v turbo &>/dev/null; then
      echo "📦 Installing turbo..."
      cd "$PROJECT_DIR" && pnpm add -D turbo 2>/dev/null || npm install -D turbo 2>/dev/null
    fi
  fi
fi

# 4. Add CI environment setup
echo ""
echo "📋 Add these secrets to GitHub repo settings:"
echo "   TURBO_API=$TURBO_API"
echo "   TURBO_TOKEN=$TURBO_TOKEN"
echo "   TURBO_TEAM=$TURBO_TEAM"
echo ""
echo "📋 In CI workflow, add before build step:"
echo '   env:'
echo '     TURBO_API: ${{ secrets.TURBO_API }}'
echo '     TURBO_TOKEN: ${{ secrets.TURBO_TOKEN }}'
echo '     TURBO_TEAM: ${{ secrets.TURBO_TEAM }}'
echo ""
echo "✅ Turborepo Remote Cache setup complete!"
echo "   Cache server: $TURBO_API"
echo "   Run 'pnpm turbo build' to test caching"
