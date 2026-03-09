---
name: setup-beads
description: "Install and configure the Beads issue tracker for persistent, git-backed task tracking that survives context compaction. Sets up hooks for agent coordination (TeammateIdle, TaskCompleted) and adds usage instructions to CLAUDE.md."
user-invocable: true
argument-hint: ""
---

# Beads Integration (Prompt 4 of 8)

Install the Beads issue tracker, initialize it, configure hooks, and add usage instructions to CLAUDE.md. Beads gives agents persistent memory that survives context compaction.

## Self-Update Protocol

Before implementing anything:
1. WebFetch `https://raw.githubusercontent.com/steveyegge/beads/main/README.md`
2. Check latest version at `https://github.com/steveyegge/beads/releases`
3. If installation commands or CLI syntax have changed, USE THE ONLINE VERSION.

## Prerequisites

Check if hooks system is installed (`.claude/hooks/` and hooks in `.claude/settings.json`). If missing, warn but continue.

## Step 1: Install Beads

If `bd` is NOT found (`which bd`):
- macOS: `brew install steveyegge/tap/beads`
- Fallback: `bun install -g @beads/bd` or `npm install -g @beads/bd`
- Verify: `bd version`

## Step 2: Initialize in Project

If `.beads/` does NOT exist: `bd init`
If already exists, skip. Verify: `bd info`

## Step 3: Configure Hooks

### A. Global Hooks (SessionStart + PreCompact)
Add to `~/.claude/settings.json` (MERGE):
- SessionStart: `bd prime 2>/dev/null || true` (timeout: 10000)
- PreCompact: `bd sync 2>/dev/null || true` (timeout: 15000)

### B. Team Hooks
Create `.claude/hooks/teammate-idle-check.sh`:
- Hook: TeammateIdle
- Checks for in-progress beads, denies idle if open issues exist
- Output: deny with "Agent has N in-progress beads issue(s). Close them before going idle."

Create `.claude/hooks/task-completed-check.sh`:
- Hook: TaskCompleted
- Extracts beads ID from task subject `[project-XXXX]`
- Denies completion if referenced bead is not closed

Make both executable. Add to `.claude/settings.json`:
- TeammateIdle -> teammate-idle-check.sh (timeout: 10000)
- TaskCompleted -> task-completed-check.sh (timeout: 10000)

## Step 4: Add Beads Section to CLAUDE.md

If no "Beads" or "Task Tracking" section exists, append:

```
## Task Tracking (Beads)

Key commands:
- `bd ready` -- what can I work on now?
- `bd create "Title" -p 1 --description="..." --json` -- create a task
- `bd update <id> --status in_progress --json` -- claim a task
- `bd close <id> --reason "..." --json` -- complete a task
- `bd dep add <child> <parent>` -- wire dependency
- `bd sync` / `bd prime` -- save/inject state

Rules:
- Always claim before starting, close when done
- Include detailed descriptions (enough for cold pickup)
- Use dependencies for related tasks
```

## Step 5: Create Test Issue

Create and immediately close a test issue to verify the pipeline:
```bash
bd create "Setup: Verify beads integration" -p 3 --description="Test issue. Safe to close." --json
bd close <id> --reason "Setup verification complete" --json
```

## Verification

1. `bd version` returns a version
2. `.beads/` directory exists
3. `bd ready` runs without error
4. `bd prime` produces output
5. Team hooks exist and are executable
6. TeammateIdle and TaskCompleted hooks in settings
7. CLAUDE.md contains beads section
8. Test issue created and closed

Display PASS/FAIL. Next: Run `/setup-agents` for multi-agent workflows.
