---
name: setup-verify
description: "Run comprehensive verification of all Claude Code setup components: settings files, CLAUDE.md, hooks, Beads, MCP servers, performance, and agent teams. Generates a scored report with fix instructions for any failures."
user-invocable: true
argument-hint: ""
---

# Verification & Testing (Prompt 8 of 8)

Run the final verification suite for this Claude Code setup. Test every component and generate a comprehensive report.

## Self-Update Protocol

Before implementing anything:
1. WebFetch `https://code.claude.com/docs/en/settings`
2. WebFetch `https://code.claude.com/docs/en/hooks`
3. WebFetch `https://code.claude.com/docs/en/mcp`
4. If any information below conflicts, USE THE ONLINE VERSION.

## Step 1: Configuration Files

### A. Settings Files
- `~/.claude/settings.json` -- exists? valid JSON? has permissions? no `$schema` key?
- `.claude/settings.json` -- exists? valid JSON? has hooks? has sandbox?

### B. CLAUDE.md
- Exists? Line count? Section count?
- Has essential sections: Quick Start, Architecture, NEVER, ALWAYS, Testing?
- Warn if < 50 lines (too short) or > 500 lines (too long)

### C. .claudeignore
- Exists? Pattern count?
- Excludes node_modules? Excludes lock files?

## Step 2: Hooks

- Count scripts in `.claude/hooks/`, check all are executable
- Test block-dangerous.sh: pipe `{"tool_input":{"command":"rm -rf /"}}` -- should deny
- Test with safe command: `{"tool_input":{"command":"git status"}}` -- should output `{}`
- Verify hooks registered in settings for: SessionStart, PreToolUse, PostToolUse, PreCompact, Stop, Notification
- Note additional high-value events: UserPromptSubmit, PermissionRequest, PostToolUseFailure
- Note hook types: command, http, prompt, agent

## Step 3: Beads

- `bd version` returns a version
- `.beads/` exists
- `bd ready` works
- If not installed: SKIP

## Step 4: MCP Servers

- `claude mcp list` -- count and list servers
- Check for: Context7 (recommended), GitHub (optional), Playwright (optional)
- `.mcp.json` valid JSON if it exists

## Step 5: Performance

- Shell startup time (check ZDOTDIR)
- Git fsmonitor, untrackedCache, manyFiles settings
- File descriptor limit (target >= 65536)
- Token optimization env vars: CLAUDE_AUTOCOMPACT_PCT_OVERRIDE, ENABLE_TOOL_SEARCH

## Step 6: Agent Teams

- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is "1"
- TeammateIdle and TaskCompleted hooks configured
- Agent definitions in `.claude/agents/`

## Step 7: Optional E2E Test

Ask user: "Run a quick end-to-end test? This creates a temporary beads issue. (y/n)"

If yes: create test bead -> claim -> close -> verify lifecycle.
If agent teams enabled and user agrees: create test team, assign simple task, verify, delete team.

## Step 8: Generate Report

```
================================================================
     CLAUDE CODE SETUP VERIFICATION REPORT
     Generated: [timestamp]
================================================================

CONFIGURATION
  [PASS/FAIL] User settings
  [PASS/FAIL] Project settings
  [PASS/FAIL] CLAUDE.md
  [PASS/FAIL] .claudeignore

HOOKS
  [PASS/FAIL] Hook scripts (count, executable)
  [PASS/FAIL] Dangerous command blocker
  [PASS/FAIL] Events registered

TOOLS
  [PASS/FAIL/SKIP] Beads
  [PASS/FAIL] MCP servers

PERFORMANCE
  [PASS/FAIL] Shell startup
  [PASS/FAIL] Git optimizations
  [PASS/FAIL] File descriptors
  [PASS/FAIL] Token optimization

AGENT TEAMS
  [PASS/FAIL/SKIP] Agent teams

================================================================
  SCORE: X/Y checks passed | Z skipped | W failed
  SETUP QUALITY: [EXCELLENT/GOOD/NEEDS WORK]
================================================================
```

## Step 9: Resources

Provide fix instructions for any WARN/FAIL results. Then list:

| Resource | URL |
|----------|-----|
| ClaudeLog | claudelog.com |
| Claude Fast | claudefa.st |
| Cranot's Guide | github.com/Cranot/claude-code-guide |
| awesome-claude-code | github.com/hesreallyhim/awesome-claude-code |
| Official Docs | code.claude.com/docs/en/best-practices |
| Official Blog | anthropic.com/engineering/claude-code-best-practices |
