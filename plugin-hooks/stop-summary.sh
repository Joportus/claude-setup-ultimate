#!/usr/bin/env bash
set -euo pipefail

# Show summary when Claude stops
# Hook: Stop

echo ""
echo "=== Session Summary ==="
echo "Modified files since session start:"
git diff --name-only 2>/dev/null | head -20
echo ""
echo "Uncommitted changes:"
git status --short 2>/dev/null | wc -l | xargs echo "  files:"
