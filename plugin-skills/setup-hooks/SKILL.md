---
name: setup-hooks
description: "Install Claude Code lifecycle hooks: dangerous command blocker, auto-linting after edits, session start context, pre-compaction state save, desktop notifications, stop summary, and optional TDD enforcement. Configures all hooks in .claude/settings.json."
user-invocable: true
argument-hint: ""
---

# Hooks & Quality Gates (Prompt 3 of 8)

Install Claude Code's hook system -- the most powerful automation feature. Create hook scripts and configure them in settings.json.

## Self-Update Protocol

Before implementing anything:
1. WebFetch `https://code.claude.com/docs/en/hooks`
2. If any information below conflicts with online docs, USE THE ONLINE VERSION.

## Prerequisites

`.claude/settings.json` must exist (from `/setup-foundation`). If not, tell the user to run that first.

## Step 0: Detect Context

1. Read `.claude/settings.json` for existing hooks (preserve them)
2. Read `/tmp/claude-setup-discovery.json` for quality tools
3. Detect OS: `uname -s`

## Step 1: Create Hook Scripts

Create all scripts in `.claude/hooks/`, make each executable with `chmod +x`.

### A. block-dangerous.sh (ALWAYS install -- security critical)
- Hook: PreToolUse (matcher: Bash)
- Reads JSON stdin, extracts command via jq
- Blocks: `rm -rf /`, `rm -rf ~`, `rm -rf .`, fork bombs, `chmod 777`, `dd if=`, `mkfs`, `> /dev/sd`, `git push --force origin main/master`, `git push -f origin main/master`, `DROP DATABASE`, `DROP TABLE`, `TRUNCATE TABLE`, `sudo rm`
- Regex blocks pipe-to-shell: `curl.*|.*(ba)?sh`, `wget.*|.*(ba)?sh`
- Output: `{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"BLOCKED: ..."}}`
- Allow all else: `echo '{}'`

### B. post-tool-lint.sh (Install if linter/formatter detected)
- Hook: PostToolUse (matcher: Write|Edit|MultiEdit)
- Detects and runs the appropriate formatter based on file extension:
  - `.sh`/`.bash`: shellcheck
  - `.md`: basic heading/whitespace validation
  - `.ts`/`.tsx`/`.js`/`.jsx`/`.json`/`.css`: Biome (if config exists) or Prettier (if config exists)
  - `.py`: ruff format or black
  - `.rs`: rustfmt
  - `.go`: gofmt

### C. session-start.sh (ALWAYS install)
- Hook: SessionStart
- Shows: project name, branch, last commit, file counts, uncommitted changes

### D. pre-compact.sh (ALWAYS install)
- Hook: PreCompact
- Saves session state (working dir, branch, modified files, staged files, recent commits) to `/tmp/claude-setup-compaction-state.md`

### E. notification.sh (ALWAYS install)
- Hook: Notification (async)
- Desktop notifications via `osascript` on macOS or `notify-send` on Linux

### F. stop-summary.sh (ALWAYS install)
- Hook: Stop
- Shows modified files and uncommitted change count

### G. tdd-enforce.sh (OPTIONAL -- install if project has tests)
- Hook: Stop
- Checks if new source files were created without corresponding test files
- Advisory only (exit 0), can be changed to exit 2 to enforce

## Step 2: Configure Hooks in Settings

Read `.claude/settings.json`, MERGE hooks block (do NOT replace existing hooks):

| Event | Script | Timeout | Matcher |
|-------|--------|---------|---------|
| SessionStart | session-start.sh | 10000 | - |
| PreToolUse | block-dangerous.sh | 5000 | Bash |
| PostToolUse | post-tool-lint.sh | 30000 | Write\|Edit\|MultiEdit |
| PreCompact | pre-compact.sh | 10000 | - |
| Stop | stop-summary.sh | 10000 | - |
| Notification | notification.sh | 5000 | - (async: true) |

Use `set -euo pipefail` in all scripts. Use `#!/usr/bin/env bash` shebang.

## Verification

1. All hook scripts exist and are executable: `ls -la .claude/hooks/*.sh`
2. Test block-dangerous.sh: `echo '{"tool_input":{"command":"rm -rf /"}}' | .claude/hooks/block-dangerous.sh` (should deny)
3. Test with safe command: `echo '{"tool_input":{"command":"git status"}}' | .claude/hooks/block-dangerous.sh` (should output `{}`)
4. `.claude/settings.json` hooks block is valid JSON with 6 events configured
5. All scripts are executable

Display PASS/FAIL for each. Next: Run `/setup-beads` for persistent issue tracking.
