#!/usr/bin/env bash
set -euo pipefail

# Show project context at session start
# Hook: SessionStart

echo "=== Session Start ==="
echo "Project: $(basename "$(pwd)")"
echo "Branch: $(git branch --show-current 2>/dev/null || echo 'not a git repo')"
echo "Last commit: $(git log --oneline -1 2>/dev/null || echo 'none')"
echo ""

# File counts
SH_COUNT=$(find . -name '*.sh' -not -path './.git/*' 2>/dev/null | wc -l | tr -d ' ')
MD_COUNT=$(find . -name '*.md' -not -path './.git/*' 2>/dev/null | wc -l | tr -d ' ')
echo "Files: ${SH_COUNT} shell, ${MD_COUNT} markdown"

# Git status summary
DIRTY=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
echo "Uncommitted changes: ${DIRTY} file(s)"
git status --short 2>/dev/null | head -10
