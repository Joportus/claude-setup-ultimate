---
name: setup-agents
description: "Configure Claude Code agent teams for multi-agent workflows. Creates reusable agent definitions (researcher, implementer, reviewer), adds orchestration instructions to CLAUDE.md, and integrates with Beads for persistent task coordination."
user-invocable: true
argument-hint: ""
---

# Agent Teams Configuration (Prompt 5 of 8)

Configure agent teams for multi-agent workflows. Set up team patterns, create agent definitions, and add orchestration instructions to CLAUDE.md.

## Self-Update Protocol

Before implementing anything:
1. WebFetch `https://code.claude.com/docs/en/agent-teams`
2. If any information below conflicts with online docs, USE THE ONLINE VERSION.
3. Pay special attention to: TeamCreate parameters, spawn options, available modes.

## Prerequisites

1. Agent teams enabled? Check `~/.claude/settings.json` for `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS: "1"`. Add if missing.
2. Beads installed? If not, warn: agents work without beads but lose persistent tracking.
3. Team hooks configured? If not, warn: consider running `/setup-beads` first.

## Step 1: Create Agent Definitions

Create `.claude/agents/` directory if needed. Create these files:

### A. .claude/agents/researcher.md
- model: sonnet
- tools: Read, Grep, Glob, WebFetch, WebSearch
- Read-only research agent. Reports findings with file:line references.
- Output: Summary, Key Findings, Recommendations

### B. .claude/agents/implementer.md
- model: opus
- tools: Read, Write, Edit, Bash, Grep, Glob
- Writes production-quality code. Follows CLAUDE.md standards.
- Workflow: read task -> claim bead -> implement -> run quality checks -> close bead

### C. .claude/agents/reviewer.md
- model: sonnet
- tools: Read, Grep, Glob
- Code review agent. Checks security, error handling, type safety, performance, testing.
- Output: severity (CRITICAL/WARNING/INFO), file:line, issue, suggested fix

## Step 2: Add Agent Teams Section to CLAUDE.md

If no "Agent Team" section exists, append orchestration instructions:

**Team Size**: 3-5 teammates, 5-6 tasks each. Three focused > five scattered. Never exceed 5 without justification.

**DO**:
- `mode: "bypassPermissions"` for all agents
- Agents work on main repo directly
- Each agent documents work in beads (claim -> close)
- Agent prompts must be exhaustive: exact file paths, what to change, acceptance criteria
- Coordinator verifies after agents complete
- Use `subagent_type: "general-purpose"` for editing agents

**DO NOT**:
- Don't use `isolation: 'worktree'` on the orchestrator
- Never spawn agents without specific task assignments
- Never assume agents completed -- always verify
- Never exceed 5 teammates without justification
- Never mark CC tasks complete without closing beads

**Dual Task System** (Beads + CC Tasks):
- Beads = persistent tracker (survives compaction)
- CC tasks = real-time bridge for team coordination
- CC task subjects MUST include beads ID: `[project-XXXX] Title`

**Team Lifecycle**: Create beads -> TeamCreate -> TaskCreate per bead -> agents work -> coordinator verifies -> SendMessage shutdown -> TeamDelete -> git commit + push

## Verification

1. `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is "1" in settings
2. `.claude/agents/researcher.md` exists with frontmatter
3. `.claude/agents/implementer.md` exists with frontmatter
4. `.claude/agents/reviewer.md` exists with frontmatter
5. CLAUDE.md contains agent teams section with DO/DO NOT
6. TeammateIdle and TaskCompleted hooks configured

Display PASS/FAIL. Core setup (P1-P5) is now complete. Optional: `/setup-mcp`, `/setup-optimize`, `/setup-verify`.
