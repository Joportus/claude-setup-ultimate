#!/usr/bin/env bash
set -euo pipefail

# Desktop notification when Claude needs attention
# Hook: Notification (async)

INPUT=$(cat)
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Claude Code needs your attention"')

if [[ "$(uname -s)" == "Darwin" ]]; then
  osascript -e "display notification \"${MESSAGE}\" with title \"Claude Code\"" 2>/dev/null || true
elif command -v notify-send &>/dev/null; then
  notify-send "Claude Code" "$MESSAGE" 2>/dev/null || true
fi
