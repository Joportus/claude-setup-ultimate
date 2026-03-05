# Prompt Sequence Architecture -- The Ultimate Claude Code Setup

> Blueprint for a sequence of copy-paste prompts that configure any Claude Code installation to expert-level.
> This document is the authoritative design reference for all downstream prompt writers and the automation script.

---

## Table of Contents

1. [Design Philosophy](#1-design-philosophy)
2. [Self-Updating Mechanism](#2-self-updating-mechanism)
3. [Prompt Sequence Overview](#3-prompt-sequence-overview)
4. [Prompt 1: Discovery and Analysis](#4-prompt-1-discovery-and-analysis)
5. [Prompt 2: Foundation -- Settings, Permissions, CLAUDE.md](#5-prompt-2-foundation)
6. [Prompt 3: Hooks and Quality Gates](#6-prompt-3-hooks-and-quality-gates)
7. [Prompt 4: Beads Integration](#7-prompt-4-beads-integration)
8. [Prompt 5: Agent Teams Configuration](#8-prompt-5-agent-teams-configuration)
9. [Prompt 6: MCP Servers and External Tools](#9-prompt-6-mcp-servers-and-external-tools)
10. [Prompt 7: System and Performance Optimization](#10-prompt-7-system-and-performance-optimization)
11. [Prompt 8: Verification and Testing](#11-prompt-8-verification-and-testing)
12. [Automation Shell Script Design](#12-automation-shell-script-design)
13. [Cross-Cutting Concerns](#13-cross-cutting-concerns)
14. [Appendix: Key URLs Registry](#14-appendix-key-urls-registry)

---

## 1. Design Philosophy

### Core Principles

1. **Self-updating**: Every prompt checks the internet for the LATEST docs before acting. Our research is a fallback, not the source of truth.
2. **Repository-aware**: Prompts detect the current project's stack, package manager, framework, and existing configuration before making changes.
3. **Idempotent**: Every prompt is safe to run multiple times. It checks what already exists and only adds/modifies what is missing or outdated.
4. **Progressive**: Each prompt builds on the previous. Dependencies flow forward, never backward.
5. **Comprehensive**: The 8-prompt sequence covers everything from zero to a fully optimized expert setup.
6. **Non-destructive**: Prompts never overwrite existing configuration without first showing the user what will change. Existing CLAUDE.md content is preserved and extended, not replaced.
7. **Universal**: Works on any project (Next.js, Python, Rust, Go, Ruby, etc.) by detecting the stack first.

### Architecture: Why 8 Prompts?

We chose 8 prompts based on these constraints:

| Constraint | Impact |
|-----------|--------|
| **Token budget per prompt** | Each prompt targets 3,000-6,000 tokens to stay well within context limits and leave room for Claude's response |
| **Logical grouping** | Each prompt covers one coherent domain (settings, hooks, beads, teams, MCP, etc.) |
| **Dependency chain** | Later prompts depend on earlier ones (e.g., hooks reference settings, teams reference beads) |
| **Failure isolation** | If one prompt fails, the others still work. No single prompt is a hard prerequisite for all others |
| **Cognitive load** | A developer can understand what each prompt does from its name alone |

### Dependency Graph

```
P1: Discovery ──────┐
                     ├──> P2: Foundation ──┬──> P3: Hooks ──┬──> P4: Beads ──> P5: Teams
                     │                     │                │
                     │                     └────────────────┴──> P6: MCP & Tools
                     │
                     └──────────────────────────────────────────> P7: System Optimization

P8: Verification (runs after any/all of the above)
```

**Hard dependencies** (must run in order):
- P2 before P3 (hooks need settings.json to exist)
- P3 before P4 (beads hooks integrate with the hooks system)
- P4 before P5 (agent teams reference beads for task tracking)

**Soft dependencies** (recommended order, but not required):
- P1 before all others (provides detection context, but prompts can self-detect)
- P6 independent of P4/P5 (MCP doesn't require beads or teams)
- P7 independent of everything (system optimization is orthogonal)
- P8 after everything (but can run after any subset)

---

## 2. Self-Updating Mechanism

Every prompt begins with a **Self-Update Block** that forces Claude to check the internet before acting. This is the single most important architectural decision -- it prevents prompts from becoming stale.

### Self-Update Block Template

Every prompt MUST begin with this exact pattern (adapted for its specific domain):

```
IMPORTANT -- SELF-UPDATE PROTOCOL:
Before implementing ANYTHING in this prompt, you MUST:

1. Fetch the latest Claude Code documentation index:
   WebFetch https://code.claude.com/docs/llms.txt

2. Fetch the specific documentation page(s) relevant to this prompt:
   WebFetch https://code.claude.com/docs/en/<specific-page>

3. Check the community auto-updated guide for any recent changes:
   WebFetch https://raw.githubusercontent.com/Cranot/claude-code-guide/main/README.md

4. If ANY information below conflicts with what you find online,
   USE THE ONLINE VERSION. It is more current than this prompt.

5. Note any discrepancies in a "## Updates Found" section of your output
   so the user knows what changed since this prompt was written.
```

### URL Registry by Domain

Each prompt checks different URLs based on its domain:

| Prompt | Primary Doc URL | Secondary URLs |
|--------|----------------|----------------|
| P1: Discovery | `llms.txt` (full index) | `best-practices` |
| P2: Foundation | `settings`, `permissions`, `claude-md` | `security` |
| P3: Hooks | `hooks`, `hooks-guide` | `claude.com/blog/how-to-configure-hooks` |
| P4: Beads | `github.com/steveyegge/beads` README | beads changelog, beads docs |
| P5: Teams | `agent-teams` | `claude-md` (team instructions) |
| P6: MCP | `mcp` | `registry.modelcontextprotocol.io`, MCP GitHub org |
| P7: Optimization | `settings`, `sandboxing` | community guides |
| P8: Verification | All of the above | n/a |

### Why This Works

- **code.claude.com/docs/llms.txt**: Complete documentation index in LLM-readable format. Updated with every release.
- **Cranot/claude-code-guide**: Auto-updated every 2 days from official docs, GitHub releases, and Anthropic changelog.
- **Official docs pages**: Each page is the canonical source for its feature.
- **GitHub READMEs**: For third-party tools (beads, MCP servers), the README is the latest truth.

---

## 3. Prompt Sequence Overview

| # | Name | Purpose | Token Est. | Self-Update URLs | Output Artifacts |
|---|------|---------|-----------|-----------------|-----------------|
| 1 | **Discovery & Analysis** | Analyze repo, detect stack, plan setup | ~4,000 | `llms.txt`, `best-practices` | `/tmp/claude-setup-discovery.json` (detection results) |
| 2 | **Foundation** | settings.json, permissions, CLAUDE.md scaffold | ~5,500 | `settings`, `permissions`, `claude-md`, `security` | `~/.claude/settings.json`, `.claude/settings.json`, `CLAUDE.md` |
| 3 | **Hooks & Quality Gates** | All 18 hook events, quality gate scripts | ~5,000 | `hooks`, `hooks-guide` | `.claude/hooks/`, settings.json hooks block |
| 4 | **Beads Integration** | Install beads, configure hooks, init project | ~4,500 | `github.com/steveyegge/beads` | `bd init`, `.beads/`, beads hooks |
| 5 | **Agent Teams** | Team patterns, coordination, hooks integration | ~4,000 | `agent-teams` | settings.json teams config, team hooks |
| 6 | **MCP & External Tools** | Essential MCP servers, skills, plugins | ~5,500 | `mcp`, MCP registry | `.mcp.json` or `.claude/mcp.json`, installed skills |
| 7 | **System Optimization** | Shell, git, filesystem, network, terminal | ~4,500 | `settings`, `sandboxing` | Shell config, git config, `.claudeignore` |
| 8 | **Verification & Testing** | Run all checks, spawn test team, verify | ~3,500 | All URLs | Verification report |

**Total estimated prompt tokens: ~36,500** (well within limits for copy-paste)

---

## 4. Prompt 1: Discovery and Analysis

### Purpose

Analyze the current repository, detect the technology stack, identify existing Claude Code configuration, and produce a structured detection report that all subsequent prompts can reference.

### Self-Update URLs

```
https://code.claude.com/docs/llms.txt
https://code.claude.com/docs/en/best-practices
```

### Detection Logic

The prompt instructs Claude to detect:

| Category | Detection Method | Examples |
|----------|-----------------|----------|
| **Package manager** | Check for `bun.lockb`, `bun.lock`, `pnpm-lock.yaml`, `yarn.lock`, `package-lock.json`, `Cargo.lock`, `go.sum`, `Pipfile.lock`, `poetry.lock`, `Gemfile.lock` | bun, npm, yarn, pnpm, cargo, go, pip, poetry, bundler |
| **Framework** | Check `package.json` dependencies, `Cargo.toml`, `go.mod`, `requirements.txt`, directory structure | Next.js, React, Vue, Svelte, Rails, Django, FastAPI, Express, etc. |
| **Language** | File extensions, config files | TypeScript, JavaScript, Python, Rust, Go, Ruby, Java, etc. |
| **Existing Claude config** | Check for `CLAUDE.md`, `.claude/`, `~/.claude/`, `.mcp.json` | Presence, contents, version |
| **Git setup** | `.git/`, branch strategy, hooks | Git present, main branch name, existing hooks |
| **Quality tools** | Check for ESLint, Prettier, Biome, Black, Ruff, clippy, golangci-lint | Existing linters, formatters, type checkers |
| **CI/CD** | `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`, etc. | CI platform, existing workflows |
| **Testing** | Test directories, test runners in package.json | Jest, Vitest, Bun test, pytest, cargo test, go test |
| **Docker** | `Dockerfile`, `docker-compose.yml` | Docker present, compose services |
| **Monorepo** | `pnpm-workspace.yaml`, `lerna.json`, `nx.json`, `turbo.json` | Monorepo tool, workspace structure |

### Output Format

```json
{
  "timestamp": "2026-03-05T12:00:00Z",
  "project": {
    "name": "my-project",
    "path": "/Users/me/my-project",
    "language": "typescript",
    "framework": "nextjs-15",
    "packageManager": "bun",
    "monorepo": false
  },
  "existingConfig": {
    "claudeMd": { "exists": true, "path": "CLAUDE.md", "lines": 150 },
    "claudeDir": { "exists": true, "hasSettings": true, "hasHooks": false },
    "userSettings": { "exists": true, "path": "~/.claude/settings.json" },
    "mcp": { "exists": false },
    "beads": { "exists": false },
    "claudeignore": { "exists": false }
  },
  "qualityTools": {
    "linter": "biome",
    "formatter": "biome",
    "typeChecker": "typescript",
    "testRunner": "bun"
  },
  "ci": {
    "platform": "github-actions",
    "workflows": ["ci.yml", "deploy.yml"]
  },
  "recommendations": [
    "CLAUDE.md exists but is missing hooks section -- P3 will add it",
    "No beads detected -- P4 will install and configure",
    "No MCP servers configured -- P6 will add essentials",
    "Shell startup time is 450ms -- P7 will optimize"
  ]
}
```

### Actions

1. Run detection commands (all read-only, no modifications)
2. Produce the JSON detection report
3. Save to `/tmp/claude-setup-discovery.json`
4. Display a human-readable summary with recommendations

### Verification

- Detection report exists and is valid JSON
- All detected tools match reality (spot-check 2-3)
- Recommendations are actionable

### Estimated Tokens: ~4,000

---

## 5. Prompt 2: Foundation -- Settings, Permissions, CLAUDE.md

### Purpose

Set up the three foundational configuration layers: user settings (`~/.claude/settings.json`), project settings (`.claude/settings.json`), and the CLAUDE.md instruction file. This is the bedrock everything else builds on.

### Self-Update URLs

```
https://code.claude.com/docs/en/settings
https://code.claude.com/docs/en/permissions
https://code.claude.com/docs/en/claude-md
https://code.claude.com/docs/en/security
```

### Detection Logic

1. Read existing `~/.claude/settings.json` (if any) -- preserve all existing settings
2. Read existing `.claude/settings.json` (if any) -- preserve team settings
3. Read existing `CLAUDE.md` (if any) -- preserve all existing content
4. Read `/tmp/claude-setup-discovery.json` from P1 (if available) for stack detection
5. If P1 was not run, perform minimal inline detection (package manager, framework, language)

### Actions

#### A. User Settings (`~/.claude/settings.json`)

Create or update with:

```jsonc
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  // Enable agent teams (experimental but essential)
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  // Permission rules -- global defaults
  "permissions": {
    "allow": [
      // Read-only operations (safe everywhere)
      "Read",
      "Glob",
      "Grep",
      // Common safe commands
      "Bash(git status)",
      "Bash(git log *)",
      "Bash(git diff *)",
      "Bash(git branch *)",
      "Bash(which *)",
      "Bash(cat *)",
      "Bash(ls *)",
      "Bash(pwd)",
      "Bash(echo *)",
      "Bash(date)",
      "Bash(uname *)",
      "Bash(wc *)"
    ],
    "deny": [
      // Never read secrets
      "Read(.env)",
      "Read(.env.*)",
      "Read(**/secrets/**)",
      "Read(**/.aws/credentials)",
      // Never execute dangerous commands
      "Bash(rm -rf /)",
      "Bash(sudo rm *)",
      "Bash(curl * | bash)",
      "Bash(wget * | bash)",
      "Bash(curl * | sh)",
      "Bash(wget * | sh)"
    ]
  }
}
```

#### B. Project Settings (`.claude/settings.json`)

Create or update with stack-specific settings. Example for a Next.js/TypeScript/Bun project:

```jsonc
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "allow": [
      // Package manager (detected from P1)
      "Bash(bun install *)",
      "Bash(bun run *)",
      "Bash(bun test *)",
      "Bash(bun add *)",
      "Bash(bunx *)",
      // Type checking
      "Bash(npx tsc *)",
      "Bash(npx tsgo *)",
      // Quality tools (detected)
      "Bash(npx biome *)",
      "Bash(npx eslint *)",
      "Bash(npx knip *)",
      "Bash(npx semgrep *)",
      // Git (safe operations)
      "Bash(git add *)",
      "Bash(git commit *)",
      "Bash(git stash *)",
      "Bash(git checkout *)",
      // Docker (if detected)
      "Bash(docker compose *)",
      "Bash(docker logs *)"
    ],
    "deny": [
      // Project-specific secrets
      "Read(.env.local)",
      "Read(.env.production)"
    ],
    "defaultMode": "acceptEdits"
  }
}
```

The prompt MUST adapt the permission rules based on the detected stack:
- **Python projects**: `Bash(pip install *)`, `Bash(pytest *)`, `Bash(python -m *)`, `Bash(ruff *)`, `Bash(mypy *)`
- **Rust projects**: `Bash(cargo build *)`, `Bash(cargo test *)`, `Bash(cargo clippy *)`, `Bash(cargo fmt *)`
- **Go projects**: `Bash(go build *)`, `Bash(go test *)`, `Bash(golangci-lint *)`
- **Ruby projects**: `Bash(bundle *)`, `Bash(rails *)`, `Bash(rspec *)`, `Bash(rubocop *)`

#### C. CLAUDE.md

If CLAUDE.md does not exist, create a comprehensive scaffold. If it exists, extend it with missing sections (never replace existing content).

**Scaffold structure** (from research -- R4, R10, R15):

```markdown
# CLAUDE.md -- [Project Name]

## Overview
[1-2 sentences about the project]

**Stack:** [detected] | **Language:** [detected] | **Package Manager:** [detected]

## Quick Start
[detected build/run/test commands]

## Architecture
[directory structure overview]

## Core Patterns
[framework-specific patterns]

## Quality Gates
[detected quality tools and how to run them]

## NEVER
[project-specific prohibitions]

## ALWAYS
[project-specific requirements]

## External Services
[detected integrations]

## Testing
[detected test patterns]
```

**Key CLAUDE.md best practices to embed** (from R4, R10):
- Use imperative voice ("Use X", "Never do Y") -- not suggestions
- Keep under 500 lines (larger = diluted attention, higher token cost)
- Use tables for structured data (more token-efficient than prose)
- Include the "Self-Updating Rule" pattern: "When you learn something from debugging, update this file"
- Reference subdirectory CLAUDE.md files for domain-specific context
- Use `@imports` for large reference docs

### Verification

1. `~/.claude/settings.json` exists and is valid JSON with `$schema`
2. `.claude/settings.json` exists and is valid JSON with `$schema`
3. `CLAUDE.md` exists with all core sections
4. No existing configuration was destroyed
5. Permission rules match the detected stack

### Estimated Tokens: ~5,500

---

## 6. Prompt 3: Hooks and Quality Gates

### Purpose

Configure the hooks system -- Claude Code's most powerful automation feature. Install hooks for all relevant lifecycle events with quality gate scripts that enforce project standards.

### Self-Update URLs

```
https://code.claude.com/docs/en/hooks
https://code.claude.com/docs/en/hooks-guide
https://claude.com/blog/how-to-configure-hooks
```

### Detection Logic

1. Read existing hooks in settings.json (preserve them)
2. Detect quality tools from P1/P2 (or re-detect)
3. Check for existing `.claude/hooks/` directory
4. Detect CI/CD platform for mirroring quality gates

### Actions

#### A. Create Hook Scripts Directory

```
.claude/hooks/
  pre-commit-check.sh     # Pre-commit quality gate
  post-tool-lint.sh       # Auto-lint after file edits
  block-dangerous.sh      # Block dangerous commands
  session-start.sh        # Session initialization
  pre-compact.sh          # Save state before compaction
  notification.sh         # Desktop notifications
  stop-summary.sh         # End-of-task summary
```

#### B. Hook Event Configuration

The prompt configures these hook events (all 18 supported events, but only installs what's relevant):

**Tier 1: Essential (always install)**

| Event | Hook Purpose | Script |
|-------|-------------|--------|
| `SessionStart` | Initialize session, show project status, run `bd prime` if beads installed | `session-start.sh` |
| `PreToolUse` (matcher: `Bash`) | Block dangerous commands (`rm -rf /`, `sudo rm`, pipe-to-bash) | `block-dangerous.sh` |
| `PostToolUse` (matcher: `Write\|Edit\|MultiEdit`) | Auto-lint/format modified files | `post-tool-lint.sh` |
| `PreCompact` | Save beads state, commit work-in-progress notes | `pre-compact.sh` |
| `Stop` | Show summary, suggest next steps | `stop-summary.sh` |
| `Notification` | Desktop notification when Claude needs attention | `notification.sh` |

**Tier 2: Quality Gates (install if quality tools detected)**

| Event | Hook Purpose | Condition |
|-------|-------------|-----------|
| `PostToolUse` (matcher: `Bash`) | After `git commit`, run type checker | TypeScript/typed language detected |
| `UserPromptSubmit` | Validate prompt isn't too vague | Optional (power users) |

**Tier 3: Team Coordination (install in P5)**

| Event | Hook Purpose |
|-------|-------------|
| `TeammateIdle` | Verify beads issues closed before agent goes idle |
| `TaskCompleted` | Verify beads issues closed before task marked complete |

**Tier 4: Advanced (optional)**

| Event | Hook Purpose |
|-------|-------------|
| `SubagentStart` | Log subagent spawning for cost tracking |
| `SubagentStop` | Collect subagent results |
| `ConfigChange` | Alert on config changes |
| `WorktreeCreate` | Custom worktree setup |

#### C. Hook Script Templates

**Block dangerous commands** (`block-dangerous.sh`):
```bash
#!/bin/bash
# Reads PreToolUse input from stdin, blocks dangerous patterns
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
# Block patterns: rm -rf /, sudo rm, pipe-to-bash/sh, DROP DATABASE, etc.
# Output JSON: {"decision": "block", "reason": "..."} or {"decision": "approve"}
```

**Auto-lint after edits** (`post-tool-lint.sh`):
```bash
#!/bin/bash
# Reads PostToolUse input, runs formatter on modified file
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
# Detect formatter (biome, prettier, black, rustfmt, gofmt) and run it
```

**Session start** (`session-start.sh`):
```bash
#!/bin/bash
# Show project status, git status, beads ready (if installed)
echo "=== Session Start ==="
git status --short 2>/dev/null
command -v bd >/dev/null && bd prime 2>/dev/null
```

**Desktop notifications** (`notification.sh`):
```bash
#!/bin/bash
# Cross-platform notification
INPUT=$(cat)
MESSAGE=$(echo "$INPUT" | jq -r '.notification.message // "Claude needs attention"')
if [[ "$OSTYPE" == "darwin"* ]]; then
  osascript -e "display notification \"$MESSAGE\" with title \"Claude Code\""
elif command -v notify-send &>/dev/null; then
  notify-send "Claude Code" "$MESSAGE"
fi
```

#### D. Settings.json Hooks Block

Add the hooks configuration to `.claude/settings.json`:

```jsonc
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/session-start.sh",
            "timeout": 10
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/block-dangerous.sh",
            "timeout": 5
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/post-tool-lint.sh",
            "timeout": 30
          }
        ]
      }
    ],
    "PreCompact": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/pre-compact.sh",
            "timeout": 10
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/stop-summary.sh",
            "timeout": 10
          }
        ]
      }
    ],
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/notification.sh",
            "timeout": 5,
            "async": true
          }
        ]
      }
    ]
  }
}
```

### Verification

1. All hook scripts exist and are executable (`chmod +x`)
2. `settings.json` hooks block is valid JSON
3. Each hook script handles stdin JSON correctly
4. Dangerous command blocking works (test with `echo '{"tool_input":{"command":"rm -rf /"}}' | .claude/hooks/block-dangerous.sh`)

### Estimated Tokens: ~5,000

---

## 7. Prompt 4: Beads Integration

### Purpose

Install the Beads issue tracker, initialize it for the project, configure hooks for agent-beads integration, and set up the dual task system (Beads + CC Tasks).

### Self-Update URLs

```
https://raw.githubusercontent.com/steveyegge/beads/main/README.md
https://github.com/steveyegge/beads/releases
```

### Detection Logic

1. Check if `bd` is already installed (`which bd`)
2. Check if `.beads/` directory exists in the project
3. Check if beads hooks are already configured
4. Detect OS for installation method

### Actions

#### A. Install Beads

```bash
# macOS (preferred)
brew install beads

# Or via npm/bun (fallback)
bun install -g --trust @beads/bd
# npm install -g @beads/bd

# Verify
bd version
```

#### B. Initialize for Project

```bash
cd /path/to/project
bd init --quiet  # Non-interactive, auto-installs hooks
```

#### C. Configure Beads Hooks

Add to `~/.claude/settings.json` (global, applies to all projects):

```jsonc
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bd prime 2>/dev/null || true",
            "timeout": 10
          }
        ]
      }
    ],
    "PreCompact": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bd sync 2>/dev/null || true",
            "timeout": 15
          }
        ]
      }
    ]
  }
}
```

#### D. Configure Team Hooks (for agent teams)

Add to `.claude/settings.json` (project-level):

```jsonc
{
  "hooks": {
    "TeammateIdle": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/teammate-idle-check.sh",
            "timeout": 10
          }
        ]
      }
    ],
    "TaskCompleted": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/task-completed-check.sh",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

**teammate-idle-check.sh**: Ensures agents close their beads issues before going idle.
**task-completed-check.sh**: Verifies beads issue is closed before CC task can complete.

#### E. Add Beads Rules to CLAUDE.md

Append to CLAUDE.md:

```markdown
## Task Tracking (Beads)

Beads (`bd`) is this project's persistent, git-backed issue tracker.

**Key commands:**
- `bd ready` -- What can I work on now?
- `bd create "Title" -p 1 --description="..." --json` -- Create a task
- `bd update <id> --status in_progress --json` -- Claim a task
- `bd close <id> --reason "..." --json` -- Complete a task
- `bd dep add <child> <parent>` -- Wire dependency

**Rules:**
- Always claim a bead before starting work (`bd update <id> --status in_progress`)
- Always close a bead when work is done (`bd close <id> --reason="..."`)
- Include detailed descriptions when creating tasks
- Use dependencies for related tasks
```

### Verification

1. `bd version` returns a version
2. `.beads/` directory exists in project root
3. `bd ready` returns without error
4. Beads hooks fire on session start (`bd prime` output visible)
5. CLAUDE.md contains beads section

### Estimated Tokens: ~4,500

---

## 8. Prompt 5: Agent Teams Configuration

### Purpose

Configure Claude Code's agent teams feature for multi-agent workflows. Set up team patterns, coordination hooks, and CLAUDE.md instructions for effective team orchestration.

### Self-Update URLs

```
https://code.claude.com/docs/en/agent-teams
https://code.claude.com/docs/en/claude-md
```

### Detection Logic

1. Check if `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is set in settings
2. Check for existing team hooks (TeammateIdle, TaskCompleted)
3. Check if beads is installed (required for dual task system)
4. Read current CLAUDE.md for existing team instructions

### Actions

#### A. Enable Agent Teams

Ensure `settings.json` has:

```jsonc
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

#### B. Create Team Orchestration Templates

Create `.claude/agents/` directory with team-specific agent definitions:

```markdown
<!-- .claude/agents/researcher.md -->
---
name: researcher
description: Research agent for exploring codebases and documentation
model: sonnet
---

You are a research agent. Your job is to explore, read, and analyze code.
You NEVER modify files. You report findings to the team lead.

## Rules
- Read-only operations only
- Report file paths, line numbers, and code snippets
- Summarize findings concisely
```

```markdown
<!-- .claude/agents/implementer.md -->
---
name: implementer
description: Implementation agent for writing and modifying code
model: opus
---

You are an implementation agent. You write production-quality code.

## Rules
- Always read existing code before modifying
- Run type checker after changes
- Follow project coding standards from CLAUDE.md
- Claim beads issues before starting work
- Close beads issues when done
```

#### C. Add Agent Teams CLAUDE.md Section

Append to CLAUDE.md:

```markdown
## Agent Team Orchestration

### Team Size Guidance
- 3-5 teammates for most workflows
- 5-6 tasks per teammate
- Three focused teammates outperform five scattered ones

### DO
- Use `mode: "bypassPermissions"` for all agents
- Agents work on main repo directly (NO worktree isolation)
- Each agent documents work in beads
- Agent prompts must be exhaustive (exact file paths, what to change, acceptance criteria)
- Coordinator verifies after agents complete

### DO NOT
- Never use `isolation: "worktree"` (changes are lost on agent exit)
- Never spawn agents without a specific bead assignment
- Never assume agents completed successfully -- always verify
- Never exceed 5 teammates without justification

### Dual Task System
- Beads = primary, persistent tracker (survives compaction)
- CC tasks = bridge for real-time team coordination
- CC task subjects MUST include beads ID: "[project-XXXX] Title"
```

#### D. Create Team Lifecycle Hooks

If not already created in P3, add:

- `TeammateIdle` hook: Blocks if in-progress beads remain open
- `TaskCompleted` hook: Blocks if referenced beads issue not closed

### Verification

1. Agent teams are enabled (`settings.json` has the env var)
2. `.claude/agents/` directory exists with at least 2 agent definitions
3. CLAUDE.md contains agent teams section
4. TeammateIdle and TaskCompleted hooks are configured
5. Quick test: `claude --print -p "What agent teams features are available?"` returns relevant info

### Estimated Tokens: ~4,000

---

## 9. Prompt 6: MCP Servers and External Tools

### Purpose

Install essential MCP servers for the detected stack, configure skills and plugins, and set up external tool integrations.

### Self-Update URLs

```
https://code.claude.com/docs/en/mcp
https://registry.modelcontextprotocol.io
https://raw.githubusercontent.com/Cranot/claude-code-guide/main/README.md
```

### Detection Logic

1. Run `claude mcp list` to see existing MCP servers
2. Read `.mcp.json` if it exists
3. Detect which servers are relevant based on the project stack
4. Check for API keys in environment (GitHub token, etc.)

### Actions

#### A. Essential MCP Servers (install for every project)

| Server | Purpose | Install Command |
|--------|---------|----------------|
| **Context7** | Up-to-date library documentation | `claude mcp add context7 -- npx -y @upstash/context7-mcp` |
| **GitHub** | PR/issue management, code search | `claude mcp add github -- npx -y @modelcontextprotocol/server-github` |
| **Playwright** | Browser automation and testing | `claude mcp add playwright -- npx -y @anthropic-ai/mcp-playwright` |

#### B. Stack-Specific MCP Servers

| Stack | Server | Purpose |
|-------|--------|---------|
| **Any with PostgreSQL** | PostgreSQL MCP | Database queries |
| **Any with SQLite** | SQLite MCP | Database management |
| **Web projects** | Brave Search or Firecrawl | Web search/scraping |
| **Supabase projects** | Supabase Agent Skills | Supabase operations |

#### C. Essential Skills

Install via `npx skills add`:

| Skill | Source | Purpose |
|-------|--------|---------|
| **Superpowers** | `obra/superpowers` | Structured lifecycle planning, TDD, debugging |
| **Agent Skills** (Vercel) | `vercel-labs/agent-skills` | React/Next.js best practices, web design guidelines |

#### D. Useful Plugins (optional, prompt asks user)

| Plugin | Source | Purpose |
|--------|--------|---------|
| **frontend-design** | `claude-plugins-official` | Distinctive UI design |
| **react-best-practices** | `vercel-labs/agent-skills` | 40+ React/Next.js rules |

#### E. MCP Configuration File

Create `.mcp.json` at project root (for Playwright and other browser tools):

```jsonc
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/mcp-playwright"],
      "env": {}
    }
  }
}
```

### Verification

1. `claude mcp list` shows all installed servers
2. Each server responds to a test query (e.g., Context7: resolve a library)
3. Skills are installed (check `.claude/skills/` or relevant location)
4. No API key errors in MCP server logs

### Estimated Tokens: ~5,500

---

## 10. Prompt 7: System and Performance Optimization

### Purpose

Optimize the developer's system for maximum Claude Code performance: shell startup time, git operations, filesystem caching, terminal configuration, and .claudeignore.

### Self-Update URLs

```
https://code.claude.com/docs/en/settings
https://code.claude.com/docs/en/sandboxing
```

### Detection Logic

1. Measure current shell startup time (`time zsh -i -c exit`)
2. Check git configuration (`git config --list`)
3. Detect terminal emulator
4. Check for existing `.claudeignore`
5. Measure filesystem performance (optional)

### Actions

#### A. Shell Optimization

**Goal: Shell startup under 100ms** (Claude spawns a shell for every Bash tool call)

1. Measure baseline: `time zsh -i -c exit`
2. If > 100ms, create a minimal ZDOTDIR for Claude:
   ```bash
   mkdir -p ~/.config/zsh-claude
   # Create minimal .zshrc with just PATH and essential aliases
   ```
3. Add to settings.json:
   ```jsonc
   {
     "env": {
       "ZDOTDIR": "~/.config/zsh-claude"
     }
   }
   ```

#### B. Git Optimization

```bash
# Enable filesystem monitor for faster git status
git config --global core.fsmonitor true
git config --global core.untrackedCache true

# Increase buffer for large repos
git config --global http.postBuffer 524288000

# Enable parallel fetch
git config --global fetch.parallel 0

# Commit graph for faster log operations
git config --global feature.manyFiles true
git config --global core.commitGraph true
```

#### C. .claudeignore

Create `.claudeignore` to exclude irrelevant files from Claude's file scanning:

```
# Dependencies
node_modules/
.pnpm/
vendor/
venv/
__pycache__/
target/

# Build output
.next/
dist/
build/
out/
.turbo/

# Large binary files
*.wasm
*.bin
*.dat
*.db
*.sqlite
*.lock

# IDE
.idea/
.vscode/settings.json

# OS
.DS_Store
Thumbs.db

# Test artifacts
coverage/
.nyc_output/
playwright-report/
test-results/
```

Adapt based on detected stack.

#### D. Terminal Setup

Run `/terminal-setup` within Claude Code to configure:
- Shift+Enter multiline input
- Option as Meta key (macOS)
- Proper keybindings

#### E. Environment Variables

Add performance-related env vars to settings:

```jsonc
{
  "env": {
    "CLAUDE_CODE_MAX_OUTPUT_TOKENS": "16000",
    "NODE_OPTIONS": "--max-old-space-size=4096"
  }
}
```

### Verification

1. Shell startup time under 100ms
2. Git operations noticeably faster
3. `.claudeignore` exists with stack-appropriate exclusions
4. Terminal multiline input works (Shift+Enter)

### Estimated Tokens: ~4,500

---

## 11. Prompt 8: Verification and Testing

### Purpose

Run a comprehensive verification suite across all configured components. Optionally spawn a test agent team to validate the full setup end-to-end.

### Self-Update URLs

```
https://code.claude.com/docs/llms.txt
(All URLs -- this prompt verifies everything)
```

### Detection Logic

1. Determine which prompts (P1-P7) were actually run
2. Check which components exist and need verification
3. Detect if agent teams are available for the full E2E test

### Actions

#### A. Configuration Verification

| Check | Command | Expected |
|-------|---------|----------|
| User settings | `cat ~/.claude/settings.json \| jq .` | Valid JSON with $schema |
| Project settings | `cat .claude/settings.json \| jq .` | Valid JSON with hooks block |
| CLAUDE.md exists | `test -f CLAUDE.md` | File exists, > 50 lines |
| CLAUDE.md sections | `grep -c "^##" CLAUDE.md` | >= 5 sections |
| Hooks directory | `ls -la .claude/hooks/` | Scripts exist, are executable |
| Hook scripts valid | Test each with sample JSON input | Correct JSON output |

#### B. Tools Verification

| Check | Command | Expected |
|-------|---------|----------|
| Beads installed | `bd version` | Version number |
| Beads initialized | `bd info` | Project info |
| MCP servers | `claude mcp list` | >= 2 servers |
| Skills installed | Check `.claude/skills/` | At least 1 skill |

#### C. Performance Verification

| Check | Command | Expected |
|-------|---------|----------|
| Shell startup | `time zsh -i -c exit` | < 100ms |
| .claudeignore | `test -f .claudeignore` | File exists |
| Git optimizations | `git config core.fsmonitor` | true |

#### D. End-to-End Test (Optional)

Spawn a minimal agent team to verify everything works together:

1. Create a beads issue: `bd create "Test: Verify setup" -p 3 --description="E2E test"`
2. Create a team with 2 agents (researcher + implementer)
3. Assign the test task
4. Verify agents can:
   - Read files
   - Claim beads issues
   - Communicate via messages
   - Close beads issues
   - Complete tasks
5. Clean up: delete team, close test bead

#### E. Generate Report

Output a verification report:

```
=== Claude Code Setup Verification Report ===

[PASS] User settings: Valid JSON with schema
[PASS] Project settings: Valid JSON with hooks
[PASS] CLAUDE.md: 12 sections, 280 lines
[PASS] Hooks: 6 scripts, all executable
[PASS] Block dangerous: Correctly blocks rm -rf /
[PASS] Beads: v0.58.0 installed, project initialized
[PASS] MCP: 3 servers (context7, github, playwright)
[PASS] Shell startup: 45ms (target: <100ms)
[PASS] .claudeignore: 28 patterns
[PASS] Git optimizations: fsmonitor, untrackedCache
[SKIP] Agent teams E2E: User opted out

Score: 10/11 checks passed
Setup quality: EXCELLENT
```

### Verification

The prompt IS the verification. Success = all checks pass.

### Estimated Tokens: ~3,500

---

## 12. Automation Shell Script Design

### Overview

A single shell script (`setup-claude-code.sh`) that orchestrates all 8 prompts. The user downloads and runs it, and it handles everything.

### Script Architecture

```bash
#!/usr/bin/env bash
set -euo pipefail

# === Configuration ===
VERSION="1.0.0"
SCRIPT_NAME="setup-claude-code"
LOG_DIR="/tmp/${SCRIPT_NAME}-logs"
PROMPTS_DIR="/tmp/${SCRIPT_NAME}-prompts"

# === Functions ===

detect_os()        # macOS or Linux
check_prereqs()    # bun/node, git, claude CLI
show_progress()    # Progress bar/status
log_step()         # Timestamped logging
run_prompt()       # Execute a single prompt via claude CLI
handle_error()     # Graceful error handling
is_idempotent()    # Check if step already completed

# === Main Flow ===

main() {
    welcome_banner
    detect_os
    check_prereqs

    # Parse arguments
    # --all          Run all prompts (default)
    # --prompt N     Run only prompt N
    # --from N       Start from prompt N
    # --skip N       Skip prompt N
    # --verify-only  Only run P8 (verification)
    # --dry-run      Show what would be done
    # --verbose      Show full claude output

    mkdir -p "$LOG_DIR" "$PROMPTS_DIR"

    for i in $(seq $START $END); do
        if should_skip $i; then continue; fi

        show_progress $i 8 "Running Prompt $i: $(prompt_name $i)"

        # Generate the prompt content
        generate_prompt $i > "$PROMPTS_DIR/prompt-$i.md"

        # Run via claude headless mode
        claude --print -p "$(cat $PROMPTS_DIR/prompt-$i.md)" \
            2>&1 | tee "$LOG_DIR/prompt-$i.log"

        # Check exit code
        if [ $? -ne 0 ]; then
            handle_error $i
        fi

        log_step "Prompt $i completed"
    done

    show_summary
}
```

### Key Design Decisions

#### 1. Prompt Delivery Method

```bash
# Option A: Inline prompts (chosen -- self-contained, no network dependency)
claude --print -p "$(cat <<'PROMPT'
[prompt content here]
PROMPT
)"

# Option B: Fetch from URL (alternative -- always latest)
# claude --print -p "$(curl -s https://example.com/prompts/p1.md)"
```

We chose **Option A** (inline) because:
- Works offline
- No external dependency
- User can inspect before running
- But we ALSO support `--fetch-latest` flag to download prompts from a URL

#### 2. Idempotency Checks

Before each prompt, the script checks if it's already been run:

```bash
is_prompt_complete() {
    case $1 in
        1) [ -f /tmp/claude-setup-discovery.json ] ;;
        2) [ -f ~/.claude/settings.json ] && [ -f .claude/settings.json ] && [ -f CLAUDE.md ] ;;
        3) [ -d .claude/hooks ] && [ -f .claude/hooks/block-dangerous.sh ] ;;
        4) command -v bd >/dev/null && [ -d .beads ] ;;
        5) grep -q "AGENT_TEAMS" ~/.claude/settings.json 2>/dev/null ;;
        6) claude mcp list 2>/dev/null | grep -q "context7" ;;
        7) [ -f .claudeignore ] ;;
        8) true ;; # Verification always runs
    esac
}
```

If already complete, the script shows `[SKIP] Prompt N already configured` and moves on.

#### 3. Error Handling

```bash
handle_error() {
    local prompt_num=$1
    echo "ERROR: Prompt $prompt_num failed."
    echo "Log: $LOG_DIR/prompt-$prompt_num.log"
    echo ""
    echo "Options:"
    echo "  1) Retry this prompt"
    echo "  2) Skip and continue"
    echo "  3) Abort"
    read -p "Choice [1-3]: " choice
    case $choice in
        1) run_prompt $prompt_num ;;
        2) log_step "Skipped prompt $prompt_num" ;;
        3) exit 1 ;;
    esac
}
```

#### 4. Prerequisites Check

```bash
check_prereqs() {
    local missing=()

    # Required
    command -v git >/dev/null || missing+=("git")
    command -v claude >/dev/null || missing+=("claude (npm i -g @anthropic-ai/claude-code)")

    # Package manager (at least one)
    if ! command -v bun >/dev/null && ! command -v node >/dev/null; then
        missing+=("bun or node")
    fi

    # Optional (warn but don't fail)
    command -v jq >/dev/null || warn "jq not found -- some features limited"

    if [ ${#missing[@]} -gt 0 ]; then
        error "Missing prerequisites: ${missing[*]}"
        exit 1
    fi
}
```

#### 5. Progress Display

```bash
show_progress() {
    local current=$1 total=$2 label=$3
    local pct=$((current * 100 / total))
    local filled=$((pct / 5))
    local empty=$((20 - filled))

    printf "\r[%s%s] %d%% %s" \
        "$(printf '#%.0s' $(seq 1 $filled))" \
        "$(printf '.%.0s' $(seq 1 $empty))" \
        "$pct" \
        "$label"
}
```

#### 6. Logging

Every step is logged with timestamps:

```
/tmp/setup-claude-code-logs/
  setup.log              # Main log
  prompt-1.log           # Full output of each prompt
  prompt-2.log
  ...
  discovery.json         # P1 output
  verification-report.md # P8 output
```

### Script CLI Interface

```bash
# Full setup
./setup-claude-code.sh

# Just verification
./setup-claude-code.sh --verify-only

# Start from prompt 4 (already ran 1-3)
./setup-claude-code.sh --from 4

# Skip beads (don't want it)
./setup-claude-code.sh --skip 4

# Dry run (show what would happen)
./setup-claude-code.sh --dry-run

# Verbose (show full Claude output)
./setup-claude-code.sh --verbose

# Fetch latest prompts from GitHub
./setup-claude-code.sh --fetch-latest
```

### Distribution

The script can be distributed as:

1. **Single file**: `setup-claude-code.sh` (all prompts embedded)
2. **GitHub repo**: Script + separate prompt files
3. **One-liner install**: `curl -fsSL https://example.com/setup-claude-code.sh | bash`

---

## 13. Cross-Cutting Concerns

### Token Budget Management

Each prompt is designed to stay within 3,000-6,000 tokens. The self-update block adds ~500 tokens of overhead. The prompt body is the remainder.

To keep prompts efficient:
- Use tables instead of prose where possible
- Use code blocks for exact configurations
- Avoid repeating information across prompts
- Reference the P1 discovery output instead of re-detecting

### Security Considerations

1. **Never auto-approve all commands**: Even in the most permissive setup, deny dangerous patterns
2. **Never bypass permissions in production**: `bypassPermissions` mode is for containers/VMs only
3. **API keys**: Never hardcode. Always reference env vars. The script checks for `.env` files and warns about committing them
4. **MCP server trust**: Only install from official sources (Anthropic, modelcontextprotocol org, verified community)
5. **Hook security**: Hook scripts run with the user's privileges. Sanitize all inputs from JSON stdin

### Handling Conflicts with Existing Configuration

Every prompt follows this protocol:

1. **Read existing config** before making changes
2. **Merge, don't replace** -- add new settings alongside existing ones
3. **Warn about conflicts** -- if an existing setting contradicts what we're adding, show both and ask the user
4. **Backup before modify** -- create `.claude/settings.json.backup` before changes
5. **Log all changes** -- so the user can review what was modified

### Supporting Multiple Stacks

The prompts are designed for ANY project, not just JavaScript/TypeScript. Stack-specific adaptations:

| Decision Point | JavaScript/TS | Python | Rust | Go |
|---------------|--------------|--------|------|-----|
| Package manager permission | `Bash(bun *)` | `Bash(pip *)` / `Bash(uv *)` | `Bash(cargo *)` | `Bash(go *)` |
| Linter permission | `Bash(npx biome *)` | `Bash(ruff *)` | `Bash(cargo clippy *)` | `Bash(golangci-lint *)` |
| Test permission | `Bash(bun test *)` | `Bash(pytest *)` | `Bash(cargo test *)` | `Bash(go test *)` |
| Type check permission | `Bash(npx tsc *)` | `Bash(mypy *)` | N/A (compiled) | N/A (compiled) |
| .claudeignore | `node_modules/`, `.next/` | `__pycache__/`, `venv/` | `target/` | `vendor/` |
| Auto-lint hook | biome/prettier | black/ruff | rustfmt | gofmt |

### Versioning Strategy

Prompts include a version comment at the top:

```
# Claude Code Setup -- Prompt 2: Foundation
# Version: 1.0.0 | Date: 2026-03-05
# Self-updating: This prompt checks online docs before acting
```

When the automation script has a `--fetch-latest` flag, it downloads the latest prompt versions from a hosted URL, ensuring users always have the most current prompts even if they downloaded the script months ago.

---

## 14. Appendix: Key URLs Registry

### Official Anthropic Documentation

| URL | Purpose | Used By |
|-----|---------|---------|
| `https://code.claude.com/docs/llms.txt` | Complete docs index (LLM-readable) | P1, P8 |
| `https://code.claude.com/docs/en/settings` | Settings reference | P2, P7 |
| `https://code.claude.com/docs/en/permissions` | Permission system | P2 |
| `https://code.claude.com/docs/en/claude-md` | CLAUDE.md reference | P2, P5 |
| `https://code.claude.com/docs/en/hooks` | Hooks reference | P3 |
| `https://code.claude.com/docs/en/hooks-guide` | Hooks guide | P3 |
| `https://code.claude.com/docs/en/agent-teams` | Agent teams | P5 |
| `https://code.claude.com/docs/en/mcp` | MCP reference | P6 |
| `https://code.claude.com/docs/en/security` | Security guide | P2 |
| `https://code.claude.com/docs/en/sandboxing` | Sandboxing | P7 |
| `https://code.claude.com/docs/en/skills` | Skills system | P6 |
| `https://code.claude.com/docs/en/best-practices` | Best practices | P1 |

### Official Blog Posts

| URL | Purpose |
|-----|---------|
| `https://claude.com/blog/how-to-configure-hooks` | Hooks deep dive |
| `https://www.anthropic.com/engineering/claude-code-best-practices` | Engineering best practices |

### Community (Auto-Updating)

| URL | Purpose | Update Frequency |
|-----|---------|-----------------|
| `https://github.com/Cranot/claude-code-guide` | Auto-synced guide | Every 2 days |
| `https://claudelog.com` | Comprehensive hub | Continuous |
| `https://claudefa.st` | Guides + changelog | Regular |
| `https://github.com/hesreallyhim/awesome-claude-code` | Ecosystem directory | Continuous (26.4K stars) |

### Third-Party Tools

| URL | Purpose | Used By |
|-----|---------|---------|
| `https://github.com/steveyegge/beads` | Beads issue tracker | P4 |
| `https://registry.modelcontextprotocol.io` | MCP server registry | P6 |
| `https://github.com/modelcontextprotocol/servers` | Official MCP servers | P6 |

---

## Summary

This architecture defines 8 progressive, self-updating, repository-aware, idempotent prompts that transform any Claude Code installation into an expert-level setup. The automation shell script orchestrates them with error handling, progress tracking, and logging.

**Key differentiators from other setup guides:**
1. **Self-updating**: Prompts check the internet first, so they never go stale
2. **Universal**: Works on any stack, not just JavaScript
3. **Idempotent**: Safe to run multiple times
4. **Progressive**: Run 1 prompt or all 8 -- your choice
5. **Battle-tested patterns**: Every configuration is sourced from 16K lines of research across 12 files, community best practices (26.4K-star awesome lists), official Anthropic docs, and real-world production setups

The next steps are:
- **S3**: Write the actual prompt content for P1-P5 (core prompts)
- **S4**: Write the actual prompt content for P6-P8 (advanced prompts)
- **S5**: Implement the automation shell script
