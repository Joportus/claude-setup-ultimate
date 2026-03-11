#!/usr/bin/env bash
set -euo pipefail

# Save session state summary before context compaction
# Hook: PreCompact

STATE_FILE="/tmp/claude-setup-compaction-state.md"

{
  echo "# Pre-Compaction State"
  echo "Timestamp: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  echo "Working directory: $(pwd)"
  echo "Branch: $(git branch --show-current 2>/dev/null || echo 'unknown')"
  echo ""
  echo "## Modified Files"
  git diff --name-only 2>/dev/null | head -20 || echo "(not a git repo)"
  echo ""
  echo "## Staged Files"
  git diff --cached --name-only 2>/dev/null | head -20 || echo "(none)"
  echo ""
  echo "## Recent Commits"
  git log --oneline -5 2>/dev/null || echo "(none)"
} > "$STATE_FILE"

echo "Session state saved to $STATE_FILE"

# Beads sync (safe to fail)
if command -v bd &>/dev/null && [ -d ".beads" ]; then
  bd sync 2>/dev/null || true
fi
