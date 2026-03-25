#!/usr/bin/env bash
# Graphite Merge Queue — Setup Script
# Configures Graphite for a GitHub repository
#
# Prerequisites:
#   1. Install: pnpm add -g @withgraphite/graphite-cli
#   2. Auth: gt auth --token <graphite-token>
#   3. Install Graphite GitHub App on repo
#
# Usage: ./setup-graphite.sh

set -euo pipefail

echo "🔧 Graphite Merge Queue Setup"
echo ""

# Check gt is installed
if ! command -v gt &>/dev/null; then
  echo "❌ Graphite CLI not found. Install: pnpm add -g @withgraphite/graphite-cli"
  exit 1
fi

# Check auth
if ! gt auth 2>/dev/null; then
  echo "❌ Not authenticated. Run: gt auth --token <your-token>"
  echo "   Get token at: https://app.graphite.dev/settings"
  exit 1
fi

# Init graphite in current repo
gt init 2>/dev/null || true
echo "✅ Graphite initialized"

echo ""
echo "📋 Next steps:"
echo "   1. Install Graphite GitHub App: https://github.com/apps/graphite"
echo "   2. Enable merge queue in Graphite settings for this repo"
echo "   3. Disable GitHub native merge queue (Settings → General → Pull Requests)"
echo ""
echo "📋 Daily workflow:"
echo "   gt create -m 'feat: my change'     # Create stacked PR"
echo "   gt submit --merge-when-ready        # Submit to merge queue"
echo "   gt log                              # View stack"
echo "   gt sync                             # Sync with remote"
echo ""
echo "📋 Merge queue features:"
echo "   • Auto-rebase on conflicts"
echo "   • Parallel CI on stacks"
echo "   • Skip redundant CI runs"
echo "   • Fast-forward merge (clean history)"
echo ""
echo "✅ Graphite setup complete!"
