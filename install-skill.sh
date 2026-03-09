#!/usr/bin/env bash
set -euo pipefail

# install-skill.sh -- Install the setup-ultimate skill globally for Claude Code
# Usage: bash install-skill.sh [--uninstall]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_SOURCE="$SCRIPT_DIR/skills/setup-ultimate.md"
SKILL_DIR="$HOME/.claude/skills"
SKILL_LINK="$SKILL_DIR/setup-ultimate.md"

# --- Uninstall mode ---
if [[ "${1:-}" == "--uninstall" ]]; then
  if [ -L "$SKILL_LINK" ]; then
    rm "$SKILL_LINK"
    echo "Removed symlink: $SKILL_LINK"
    # Remove skills dir if empty
    rmdir "$SKILL_DIR" 2>/dev/null || true
    echo "Uninstalled setup-ultimate skill."
  elif [ -f "$SKILL_LINK" ]; then
    echo "Warning: $SKILL_LINK exists but is not a symlink (was it copied manually?)."
    echo "Remove it manually if you want to uninstall: rm $SKILL_LINK"
    exit 1
  else
    echo "Nothing to uninstall: $SKILL_LINK does not exist."
  fi
  exit 0
fi

# --- Install mode ---

# Verify source exists
if [ ! -f "$SKILL_SOURCE" ]; then
  echo "Error: Skill file not found at $SKILL_SOURCE"
  echo "Are you running this script from the claude-setup-ultimate repository?"
  exit 1
fi

# Create skills directory
mkdir -p "$SKILL_DIR"

# Create or update symlink
if [ -L "$SKILL_LINK" ]; then
  EXISTING_TARGET="$(readlink "$SKILL_LINK")"
  if [ "$EXISTING_TARGET" = "$SKILL_SOURCE" ]; then
    echo "Already installed: $SKILL_LINK -> $SKILL_SOURCE"
    echo "Nothing to do."
    exit 0
  else
    echo "Updating symlink (was pointing to: $EXISTING_TARGET)"
    rm "$SKILL_LINK"
  fi
elif [ -f "$SKILL_LINK" ]; then
  echo "Warning: $SKILL_LINK exists as a regular file (not a symlink)."
  echo "Remove it first if you want to install via symlink: rm $SKILL_LINK"
  exit 1
fi

ln -s "$SKILL_SOURCE" "$SKILL_LINK"

echo "Installed setup-ultimate skill."
echo ""
echo "  Symlink: $SKILL_LINK"
echo "       -> $SKILL_SOURCE"
echo ""
echo "Usage (in any project, inside Claude Code):"
echo "  /setup-ultimate          Run lite setup (P1-P3: discovery, settings, hooks)"
echo "  /setup-ultimate lite     Same as above"
echo "  /setup-ultimate full     Run full setup (P1-P8: everything)"
echo "  /setup-ultimate verify   Run verification only (P8)"
echo ""
echo "The skill auto-updates when you 'git pull' this repo."
echo "To uninstall: bash $0 --uninstall"
