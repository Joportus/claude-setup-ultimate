#!/usr/bin/env bash
set -euo pipefail

# Show project context at session start
# Hook: SessionStart

echo "=== Session Start ==="
echo "Project: $(basename "$(pwd)")"
echo "Branch: $(git branch --show-current 2>/dev/null || echo 'not a git repo')"
echo "Last commit: $(git log --oneline -1 2>/dev/null || echo 'none')"
echo ""

# Git status summary
DIRTY=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
echo "Uncommitted changes: ${DIRTY} file(s)"
git status --short 2>/dev/null | head -10

# Beads integration (safe to fail if not installed)
if command -v bd &>/dev/null && [ -d ".beads" ]; then
  bd prime 2>/dev/null || true
fi
