#!/usr/bin/env bash
# sync-to-msi.sh — Run on pop-os to push ci-standards to MSI
# MSI must be online via Tailscale (100.87.247.87)
set -euo pipefail

MSI_HOST="${1:-msi}"
MSI_DIR="${2:-~/ci-standards}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Syncing ci-standards to MSI ($MSI_HOST)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. Test connection
if ! ssh -o ConnectTimeout=5 "$MSI_HOST" 'echo ok' >/dev/null 2>&1; then
  echo "❌ MSI not reachable. Make sure Tailscale is running."
  echo "   Then run: bash ~/ci-standards/sync-to-msi.sh"
  exit 1
fi
echo "✅ MSI connected"

# 2. Clone or pull ci-standards on MSI
ssh "$MSI_HOST" "
  if [ -d $MSI_DIR/.git ]; then
    echo 'Pulling ci-standards...'
    cd $MSI_DIR && git pull
  else
    echo 'Cloning ci-standards...'
    git clone https://github.com/Nadav011/ci-standards.git $MSI_DIR
  fi
"

# 3. Run install on MSI
ssh "$MSI_HOST" "cd $MSI_DIR && bash install.sh"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " ✅ MSI setup complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "MSI now has global git hooks for all repos:"
echo "  - pre-commit: RTL, secrets, console.log, etc."
echo "  - pre-push: typecheck only"
echo "  - commit-msg: conventional commits"
echo ""
echo "MSI projects (cash, shifts, hatumdigital, brain, Z, SportChat)"
echo "also need their CI workflows added. Run on MSI:"
echo "  ssh $MSI_HOST"
echo "  # Then for each project: add .github/workflows/ci.yml"
