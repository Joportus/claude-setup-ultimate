#!/usr/bin/env bash
set -euo pipefail

# Auto-lint files after edits
# Hook: PostToolUse (matcher: Write|Edit|MultiEdit)

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

[ -z "$FILE_PATH" ] && exit 0
[ ! -f "$FILE_PATH" ] && exit 0

case "$FILE_PATH" in
  *.sh|*.bash)
    if command -v shellcheck &>/dev/null; then
      shellcheck --severity=warning "$FILE_PATH" 2>&1 || true
    fi
    ;;
  *.md)
    # Basic markdown validation: check for broken headings (no space after #)
    if grep -nE '^#{1,6}[^ #]' "$FILE_PATH" 2>/dev/null; then
      echo "Warning: possible malformed headings in $FILE_PATH (missing space after #)" >&2
    fi
    # Check for trailing whitespace
    if grep -nE ' +$' "$FILE_PATH" 2>/dev/null | head -5; then
      echo "Warning: trailing whitespace found in $FILE_PATH" >&2
    fi
    ;;
  *.ts|*.tsx|*.js|*.jsx|*.json|*.css)
    # Biome (check npx AND config existence with proper operator precedence)
    if command -v npx &>/dev/null && { [ -f "biome.json" ] || [ -f "biome.jsonc" ]; }; then
      npx biome format --write "$FILE_PATH" 2>/dev/null || true
    # Prettier
    elif command -v npx &>/dev/null && { [ -f ".prettierrc" ] || [ -f ".prettierrc.json" ] || [ -f "prettier.config.js" ]; }; then
      npx prettier --write "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  *.py)
    if command -v ruff &>/dev/null; then
      ruff format "$FILE_PATH" 2>/dev/null || true
    elif command -v black &>/dev/null; then
      black --quiet "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  *.rs)
    if command -v rustfmt &>/dev/null; then
      rustfmt "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  *.go)
    if command -v gofmt &>/dev/null; then
      gofmt -w "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
esac

exit 0
