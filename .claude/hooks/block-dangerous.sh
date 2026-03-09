#!/usr/bin/env bash
set -euo pipefail

# Block dangerous commands before execution
# Hook: PreToolUse (matcher: Bash)
# Exit 0 with deny JSON to block, exit 0 with empty JSON to allow

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

[[ -z "$COMMAND" ]] && echo '{}' && exit 0

BLOCKED_PATTERNS=(
  "rm -rf /"
  "rm -rf ~"
  "rm -rf ."
  "git push --force"
  "git push -f "
  "git reset --hard"
  "git checkout -- ."
  "git restore ."
  "eval "
  "chmod 777"
  ":(){ :|:& };:"
  "dd if="
  "mkfs"
  "> /dev/sd"
  "DROP DATABASE"
  "DROP TABLE"
  "TRUNCATE TABLE"
  "sudo rm"
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if [[ "$COMMAND" == *"$pattern"* ]]; then
    cat <<HOOKEOF
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"BLOCKED: matches dangerous pattern '$pattern'"}}
HOOKEOF
    exit 0
  fi
done

# Regex-based check for pipe-to-shell patterns
if [[ "$COMMAND" =~ curl.*\|.*(ba)?sh ]] || [[ "$COMMAND" =~ wget.*\|.*(ba)?sh ]]; then
  cat <<'HOOKEOF'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"BLOCKED: pipe-to-shell pattern detected"}}
HOOKEOF
  exit 0
fi

echo '{}'
