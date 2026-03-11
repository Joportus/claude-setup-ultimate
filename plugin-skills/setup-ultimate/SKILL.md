---
name: setup-ultimate
description: "Orchestrate the full Claude Code setup sequence. Runs discovery, foundation, hooks, and optionally beads, agents, MCP, optimization, and verification. Detects your stack and configures everything automatically."
user-invocable: true
argument-hint: "[lite|full|verify] (default: lite)"
---

# Setup Ultimate -- Orchestrator

You are the orchestrator for the claude-setup-ultimate prompt sequence. Run the setup skills in order against the current repository.

## Determine Mode

Check `$ARGUMENTS`:

| Mode | Skills Run | Description |
|------|-----------|-------------|
| **lite** (default) | discover, foundation, hooks | Core setup -- highest ROI. Settings, permissions, hooks. |
| **full** | discover, foundation, hooks, beads, agents, mcp, optimize, verify | Everything -- complete expert-level configuration. |
| **verify** | verify only | Validate existing setup, generate health report. |

If `$ARGUMENTS` is empty or unrecognized, default to `lite`.

## Execution

For each skill in the selected range, execute its instructions in sequence:

### Lite Mode (P1-P3)
1. **Discovery** (`/setup-discover`): Analyze repo, detect stack, produce JSON report
2. **Foundation** (`/setup-foundation`): Settings, permissions, CLAUDE.md, .claudeignore
3. **Hooks** (`/setup-hooks`): Install lifecycle hooks and quality gates

### Full Mode (P1-P8)
1-3. Same as lite
4. **Beads** (`/setup-beads`): Install persistent issue tracker
5. **Agents** (`/setup-agents`): Configure multi-agent workflows
6. **MCP** (`/setup-mcp`): Install MCP servers and external tools
7. **Optimize** (`/setup-optimize`): System and performance tuning
8. **Verify** (`/setup-verify`): Comprehensive validation and report

### Verify Mode (P8 only)
8. **Verify** (`/setup-verify`): Run verification suite

## For Each Step

1. **Announce** which step you're running (e.g., "Running Step 1: Discovery & Analysis")
2. **Execute** all instructions from the corresponding skill
3. **Report** brief summary of what was done and any issues
4. **Continue** to next step

## Self-Update Protocol

Before starting, fetch the latest Claude Code docs:
1. WebFetch `https://code.claude.com/docs/llms.txt`
2. If any information in the skills conflicts with online docs, USE THE ONLINE VERSION.

## After Completion

Provide a summary report:
1. List which steps were executed
2. For each step: what was created/modified, any warnings
3. If lite: suggest "Run `/setup-ultimate full` for beads, agents, MCP, and optimization"
4. If full: suggest "Run `/setup-ultimate verify` anytime to re-validate"
5. List any manual steps the user still needs to take
