# Claude Code Master Setup Synthesis

> Synthesized from 12 research files (~16,000 lines) into actionable reference.
> Date: 2026-03-05 | Claude Code v2.1.45+ | Opus 4.6

---

## Table of Contents

- [Part 1: Foundation (Settings, Permissions, CLAUDE.md, .claudeignore)](#part-1-foundation)
- [Part 2: Hooks System](#part-2-hooks-system)
- [Part 3: Agent Teams](#part-3-agent-teams)
- [Part 4: Beads Issue Tracker](#part-4-beads)
- [Part 5: MCP Servers](#part-5-mcp-servers)
- [Part 6: External Tools](#part-6-external-tools)
- [Part 7: System Optimization](#part-7-system-optimization)
- [Part 8: Token Optimization](#part-8-token-optimization)
- [Part 9: Developer Experience](#part-9-developer-experience)
- [Part 10: Security & Permissions](#part-10-security)
- [Part 11: Community Resources](#part-11-community-resources)
- [Part 12: Key URLs for Self-Updating Prompts](#part-12-key-urls)

---

# Part 1: Foundation

## 1.1 Settings Files -- Location, Scope, Precedence

| Scope | Location | Shared? | Purpose |
|-------|----------|---------|---------|
| **Managed policy** | `/managed-settings.json`, plist, registry | IT-deployed | Organization-wide enforcement |
| **User** | `~/.claude/settings.json` | No | Personal preferences, all projects |
| **Project (shared)** | `.claude/settings.json` | Yes (git) | Team-shared project config |
| **Project (local)** | `.claude/settings.local.json` | No (.gitignored) | Personal project overrides |

**Precedence**: Managed > Project Local > Project Shared > User (deny wins over allow at same level).

### User Settings (~/.claude/settings.json)

```json
{
  "permissions": {
    "allow": [
      "Bash(git *)",
      "Bash(bun *)",
      "Bash(ls *)",
      "Bash(cat *)",
      "Read",
      "Write",
      "Edit",
      "Glob",
      "Grep",
      "mcp__context7__*"
    ],
    "deny": [
      "Bash(rm -rf *)",
      "Bash(curl * | sh)",
      "Bash(curl * | bash)",
      "Bash(wget * | sh)",
      "Bash(eval *)",
      "Bash(chmod 777 *)"
    ]
  },
  "env": {
    "ZDOTDIR": "~/.config/zsh-claude",
    "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "60",
    "DISABLE_NON_ESSENTIAL_MODEL_CALLS": "1"
  },
  "hooks": {}
}
```

### Project Settings (.claude/settings.json)

```json
{
  "permissions": {
    "allow": [
      "Bash(bun run *)",
      "Bash(bun test *)",
      "Bash(bun install *)",
      "Bash(git status*)",
      "Bash(git diff*)",
      "Bash(git log*)",
      "Bash(git add*)",
      "Bash(git commit*)",
      "Bash(docker compose*)",
      "mcp__github__*",
      "mcp__supabase__*",
      "mcp__playwright__*",
      "mcp__context7__*"
    ],
    "deny": [
      "Bash(bun run deploy*)",
      "Bash(git push --force*)",
      "Bash(git reset --hard*)",
      "Bash(rm -rf *)"
    ]
  },
  "hooks": {}
}
```

### Managed Settings (Enterprise)

Managed settings override everything. Locations:
- macOS: `/Library/Application Support/ClaudeCode/managed-settings.json`
- Linux/WSL: `/etc/claude-code/managed-settings.json`
- Windows: `C:\Program Files\ClaudeCode\managed-settings.json`

Unique managed-only keys: `disableClaudeMd`, `disableAutoMemory`, `disableHooks`, `lockModel`, `allowedMcpServers`, `deniedMcpServers`, `disableSendingConsentToAnthropicForManagedUser`, `lockdown` (disables all MCP, custom agents, hooks).

## 1.2 Permission System

### Permission Modes

| Mode | Description | Flag |
|------|-------------|------|
| **Default** | Prompt for sensitive actions | (none) |
| **Plan** | Read-only; cannot edit/execute | `--plan` |
| **YesMode** | Auto-approve all tools | `--yes` / `-y` |
| **BypassPermissions** | Skip all prompts (teams) | `mode: "bypassPermissions"` |

### Permission Pattern Syntax

```
ToolName                    # Allow/deny entire tool
ToolName(glob_pattern)      # Pattern-matched arguments
Bash(git *)                 # All git commands
Bash(bun run lint*)         # Commands starting with "bun run lint"
mcp__server__tool           # Specific MCP tool
mcp__server__*              # All tools from an MCP server
```

### Built-in Tool Names

| Tool | Purpose | Default |
|------|---------|---------|
| `Read` | Read files | Always allowed |
| `Write` | Write files | Needs approval |
| `Edit` | Edit files | Needs approval |
| `Bash` | Run commands | Needs approval |
| `Glob` | Find files | Always allowed |
| `Grep` | Search content | Always allowed |
| `WebFetch` | HTTP requests | Needs approval |
| `WebSearch` | Web search | Needs approval |
| `Agent` | Spawn subagent | Always allowed |
| `AskUserQuestion` | Ask user | Always allowed |
| `TaskCreate/Update/Get/List` | Team tasks | Always allowed |
| `SendMessage` | Team messaging | Always allowed |
| `TeamCreate/Delete` | Team management | Always allowed |
| `EnterWorktree` | Git worktree | Needs approval |
| `ToolSearch` | Deferred tool load | Always allowed |
| `NotebookEdit` | Jupyter notebooks | Needs approval |
| `MCPSearch` | Search MCP tools | Always allowed |
| `Skill` | Invoke skill | Always allowed |

## 1.3 CLAUDE.md Best Practices

### Hierarchy (All Loaded into Context)

| Level | File | When Loaded |
|-------|------|-------------|
| User global | `~/.claude/CLAUDE.md` | Every session |
| User project | `~/.claude/projects/<hash>/CLAUDE.md` | Matching project |
| Project root | `./CLAUDE.md` | Every session in project |
| Subdirectory | `./lib/CLAUDE.md` | When working in lib/ |
| @-import | `@docs/rules.md` | Referenced from CLAUDE.md |

### Optimization Rules

1. **Keep under 500 lines** (official) -- every line costs tokens on every message
2. **Bullet points over paragraphs** -- more concise, same information
3. **One example per concept** -- not three
4. **Reference paths** instead of embedding full file contents
5. **Use @-imports** for modular loading: `@docs/git-rules.md`
6. **Hierarchical files**: Child CLAUDE.md only loads when Claude works in that directory
7. **Regular pruning**: If Claude already does it correctly without the instruction, delete it
8. **Emphasis for adherence**: "IMPORTANT", "NEVER", "ALWAYS", "YOU MUST" -- improves rule following
9. **Move specialized content to skills** -- skills load on-demand, not at session start

### What to Include vs Exclude

| Include | Exclude |
|---------|---------|
| Bash commands Claude can't guess | Standard conventions Claude knows |
| Code style differing from defaults | Long tutorials or API docs |
| Testing instructions, preferred runners | File-by-file codebase descriptions |
| Branch naming, PR conventions | Self-evident practices |
| Architecture decisions | Frequently changing information |
| Common gotchas, dev environment quirks | Anything Claude does correctly already |

## 1.4 .claude/ Directory Structure

```
.claude/
  settings.json             # Project settings (shared, git-committed)
  settings.local.json       # Personal project overrides (.gitignored)
  rules/                    # Path-scoped rules (.gitignored by default)
    *.md                    # Auto-loaded based on file path matching
  skills/                   # Custom slash commands
    my-skill/SKILL.md       # Skill definition
  agents/                   # Custom subagent definitions
    reviewer.md             # Agent with frontmatter config
  hooks/                    # Hook scripts
    pre-commit.sh
  memory/                   # Auto memory directory
    MEMORY.md               # Auto-loaded (first 200 lines)
    topic.md                # Linked from MEMORY.md
```

## 1.5 .claudeignore

Works like `.gitignore`. Prevents Claude from reading specified files, reducing token waste.

```gitignore
# Build outputs
dist/
build/
.next/
out/
.nuxt/

# Dependencies
node_modules/
vendor/
.venv/

# Lock files (30,000-80,000 tokens each!)
package-lock.json
yarn.lock
pnpm-lock.yaml
bun.lockb
composer.lock

# Generated/compiled
*.min.js
*.min.css
*.bundle.js
*.map
*.d.ts

# Coverage and test output
coverage/
.nyc_output/
__snapshots__/

# Data and binary files
*.sqlite
*.db
*.csv

# IDE
.idea/
.vscode/

# Docker volumes
docker-data/

# Large generated docs
docs/api-reference/generated/
```

**Impact**: A well-configured `.claudeignore` saves **50-90% of tokens** on generated files.

## 1.6 .claude/rules/ (Path-Scoped Rules)

Rules are markdown files that auto-load based on the file path being worked on:

```markdown
<!-- .claude/rules/api-routes.md -->
---
globs: app/api/**/*.ts
---
All API routes must:
1. Validate auth with `await auth()`
2. Return proper HTTP status codes
3. Never expose internal errors to clients
```

Rules are `.gitignored` by default. To share with team, add them to `.claude/settings.json` or CLAUDE.md.

## 1.7 Auto Memory

Auto memory persists across conversations. Stored in `~/.claude/projects/<hash>/memory/`.

- `MEMORY.md` is always loaded (first 200 lines)
- Create topic files (e.g., `debugging.md`) for detailed notes
- Link topic files from MEMORY.md
- Update when you discover something new; remove when wrong

## 1.8 Skills System

Skills are on-demand instructions that load only when invoked (vs CLAUDE.md which loads always).

### Skill File Format

```markdown
<!-- .claude/skills/deploy/SKILL.md -->
---
name: deploy
description: Deploy to production
invocation:
  user: /deploy          # Slash command
  auto: When user mentions deploying
allowed_tools: Bash, Read
hooks:
  PreToolUse:
    - type: command
      matcher: Bash
      command: echo "Deployment safety check"
---

## Deployment Steps
1. Run tests: `bun test`
2. Build: `bun run build`
3. Deploy: `bun run deploy`
```

### Bundled Skills

| Skill | Invocation | Purpose |
|-------|-----------|---------|
| `create-skill` | `/create-skill` | Create a new skill file |
| `create-agent` | `/create-agent` | Create a new custom agent |
| `create-rule` | `/create-rule` | Create a path-scoped rule |
| `bug-report` | `/bug-report` | File a Claude Code bug report |

### Installing Community Skills

```bash
# From vercel-labs/agent-skills
npx skills add vercel-labs/agent-skills --skill react-best-practices -a claude-code

# From claude-plugins-official
/plugin install frontend-design@claude-plugins-official
```

## 1.9 Custom Agents (.claude/agents/)

Custom subagents with specific model, tool, and prompt configurations:

```markdown
<!-- .claude/agents/reviewer.md -->
---
name: code-reviewer
model: sonnet
tools: Read, Grep, Glob
description: Reviews code for quality issues
---

## Review Checklist
- Check for security vulnerabilities
- Verify error handling
- Assess test coverage
- Look for performance issues
```

Invoke with: `Use the code-reviewer agent to review src/auth/`

## 1.10 Plugins System

Plugins extend Claude Code with new skills, hooks, and agents:

```bash
# Install from registry
/plugin install <name>@<registry>

# List installed plugins
/plugin list

# Remove a plugin
/plugin remove <name>
```

## 1.11 Environment Variables

Set in `settings.json` under `"env"` key, or export in shell:

### Critical Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` | ~95% | Trigger compaction earlier |
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS` | 32,000 | Max output tokens per response |
| `CLAUDE_CODE_EFFORT_LEVEL` | - | `low`/`medium`/`high` reasoning depth |
| `DISABLE_NON_ESSENTIAL_MODEL_CALLS` | - | Skip flavor text generation |
| `ENABLE_TOOL_SEARCH` | `auto:5` | Tool deferral threshold (% of context) |
| `MAX_THINKING_TOKENS` | 31,999 | Extended thinking budget |
| `MAX_MCP_OUTPUT_TOKENS` | 25,000 | MCP tool output limit |
| `MCP_TIMEOUT` | - | MCP server startup timeout (ms) |

### Full Reference

| Variable | Purpose |
|----------|---------|
| `ANTHROPIC_API_KEY` | API key (API mode) |
| `ANTHROPIC_BASE_URL` | Custom API endpoint |
| `CLAUDE_CODE_USE_BEDROCK` | Use AWS Bedrock |
| `CLAUDE_CODE_USE_VERTEX` | Use Google Vertex AI |
| `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS` | Disable background tasks |
| `CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING` | Fixed thinking budget |
| `DISABLE_PROMPT_CACHING` | Disable caching (NOT recommended) |
| `CLAUDE_CODE_FILE_READ_MAX_OUTPUT_TOKENS` | Override file read token limit |

---

# Part 2: Hooks System

## 2.1 Overview

Hooks are deterministic shell scripts or prompts that run at specific lifecycle events. They execute before/after tool calls, on session events, and on team events. Unlike CLAUDE.md instructions (probabilistic), hooks are guaranteed to run.

### Configuration Locations

| Location | Scope | Shared? |
|----------|-------|---------|
| `~/.claude/settings.json` | All projects | Personal |
| `.claude/settings.json` | This project | Team (git) |
| `.claude/settings.local.json` | This project | Personal |
| Skill frontmatter | Per-skill | Skill scope |

## 2.2 All 18 Hook Events

### Session Events

| Event | Fires When | Common Uses |
|-------|-----------|-------------|
| `SessionStart` | New session begins | Load context, inject state, check environment |
| `Stop` | Claude stops responding | Trigger notifications, log completions |
| `PreCompact` | Before context compaction | Save state, commit beads, sync progress |

### Tool Events (Most Common)

| Event | Fires When | Can Block? | Can Modify? |
|-------|-----------|-----------|-------------|
| `PreToolUse` | Before any tool call | Yes (deny) | Yes (modify input) |
| `PostToolUse` | After any tool call | No | No (observe only) |
| `PostToolUseFailure` | After a tool call fails | No | No (observe only) |
| `PermissionRequest` | User prompted for permission | Yes (allow/deny) | Yes (modify input) |

### Communication Events

| Event | Fires When | Can Block? |
|-------|-----------|-----------|
| `Notification` | Notification would be sent | No (observe only) |
| `UserPromptSubmit` | User presses Enter | Yes (modify prompt) |

### Team Events

| Event | Fires When | Can Block? |
|-------|-----------|-----------|
| `TeammateIdle` | Teammate about to go idle | Yes |
| `TaskCompleted` | CC task marked complete | Yes |
| `SubagentStart` | Subagent spawned | No (observe only) |
| `SubagentStop` | Subagent finished | Yes |

### Lifecycle Events

| Event | Fires When | Can Block? |
|-------|-----------|-----------|
| `SessionEnd` | Session ends | No |
| `InstructionsLoaded` | CLAUDE.md/rules loaded | No |
| `ConfigChange` | Settings file changed | Yes |
| `WorktreeCreate` | Git worktree created | Yes |
| `WorktreeRemove` | Git worktree removed | No |

## 2.3 Handler Types

### 1. Command Handler (Shell Scripts)

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/pre-bash.sh",
            "timeout": 10000
          }
        ]
      }
    ]
  }
}
```

**Input**: JSON on stdin with `session_id`, `tool_name`, `tool_input`, `project_directory`
**Output**: JSON on stdout (or empty for no-op)
**Exit codes**: 0 = success, 2 = blocking error (stops tool), other = non-blocking error

### 2. Prompt Handler (Inject Instructions)

```json
{
  "type": "prompt",
  "prompt": "Always run linting after editing TypeScript files"
}
```

### 3. Agent Handler (Spawn Agent)

```json
{
  "type": "agent",
  "prompt": "Review the changes for security issues"
}
```

### 4. HTTP Handler (Webhook)

```json
{
  "type": "http",
  "url": "https://hooks.example.com/claude-code",
  "method": "POST",
  "headers": { "Authorization": "Bearer ${TOKEN}" },
  "timeout": 5000
}
```

## 2.4 Matcher Patterns

Matchers filter which tool invocations trigger a hook:

```json
"matcher": "Bash"                    // Exact tool name
"matcher": "Bash(git *)"           // Glob pattern on args
"matcher": "mcp__github__*"        // MCP tool wildcard
"matcher": "Write(*.tsx)"          // File pattern
```

Without a matcher, the hook fires for ALL invocations of that event.

## 2.5 JSON Output Schema (Decision Control)

Pre-hooks can control execution by returning JSON:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "updatedInput": { "command": "modified command" },
    "reason": "Auto-approved: safe command"
  }
}
```

| Decision | Effect |
|----------|--------|
| `"allow"` | Approve without user prompt |
| `"deny"` | Block execution |
| `"ask"` | Show approval prompt (default) |
| (empty) | No decision, continue normally |

## 2.6 Async Hooks (Background)

```json
{
  "type": "command",
  "command": "~/.claude/hooks/notify.sh",
  "async": true,
  "timeout": 30000
}
```

Async hooks run in background, don't block execution. Good for notifications, logging, analytics.

## 2.7 Essential Hook Recipes

### Auto-Approve Safe Commands

```bash
#!/bin/bash
# ~/.claude/hooks/auto-approve-safe.sh
input=$(cat)
tool=$(echo "$input" | jq -r '.tool_name')
cmd=$(echo "$input" | jq -r '.tool_input.command // empty')

if [[ "$tool" == "Bash" ]]; then
  case "$cmd" in
    "git status"*|"git diff"*|"git log"*|"ls "*|"cat "*|"pwd"|"echo "*|"bun run lint"*|"bun test"*)
      echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","reason":"Safe read-only command"}}'
      exit 0
      ;;
  esac
fi
echo '{}'
```

### Block Dangerous Commands

```bash
#!/bin/bash
# ~/.claude/hooks/block-dangerous.sh
input=$(cat)
cmd=$(echo "$input" | jq -r '.tool_input.command // empty')

BLOCKED_PATTERNS=(
  "rm -rf /"
  "rm -rf ~"
  "rm -rf ."
  ":(){ :|:& };:"
  "curl * | sh"
  "curl * | bash"
  "wget * | sh"
  "chmod 777"
  "dd if="
  "mkfs"
  "> /dev/sd"
  "git push --force origin main"
  "git push -f origin main"
  "DROP DATABASE"
  "DROP TABLE"
  "TRUNCATE"
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if [[ "$cmd" == *"$pattern"* ]]; then
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"reason\":\"BLOCKED: matches dangerous pattern '$pattern'\"}}"
    exit 0
  fi
done
echo '{}'
```

### Notification on Task Completion

```bash
#!/bin/bash
# ~/.claude/hooks/notify-done.sh (async hook on Stop event)
osascript -e 'display notification "Claude Code task completed" with title "Claude Code"'
# Or: terminal-notifier -title "Claude Code" -message "Task completed"
# Or: afplay /System/Library/Sounds/Glass.aiff
```

### Lint After Edit

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "cd $PROJECT_DIR && bun run lint:fix -- --files $(echo $HOOK_INPUT | jq -r '.tool_input.file_path')"
          }
        ]
      }
    ]
  }
}
```

### PreCompact: Save State

```json
{
  "hooks": {
    "PreCompact": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "cd /path/to/project && bd sync"
          }
        ]
      }
    ]
  }
}
```

### SessionStart: Inject Context

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "cd /path/to/project && bd prime"
          }
        ]
      }
    ]
  }
}
```

### UserPromptSubmit: Modify Prompts

```bash
#!/bin/bash
# Append context to every user prompt
input=$(cat)
prompt=$(echo "$input" | jq -r '.prompt')
enhanced="$prompt\n\n[Auto-context: Remember to check beads before starting new work]"
echo "{\"hookSpecificOutput\":{\"hookEventName\":\"UserPromptSubmit\",\"updatedPrompt\":\"$enhanced\"}}"
```

### Team Hooks: TeammateIdle and TaskCompleted

```bash
#!/bin/bash
# teammate-idle-check.sh - Block idle if beads still open
input=$(cat)
agent_name=$(echo "$input" | jq -r '.agent_name')
# Check if agent has in-progress beads
open_beads=$(cd /path/to/project && bd query --status in_progress --assignee "$agent_name" --count)
if [[ "$open_beads" -gt 0 ]]; then
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"TeammateIdle\",\"permissionDecision\":\"deny\",\"reason\":\"Agent has $open_beads in-progress beads. Close them before going idle.\"}}"
  exit 0
fi
echo '{}'
```

## 2.8 Hook Community Resources

| Resource | URL |
|----------|-----|
| disler/claude-code-hooks-mastery | github.com/disler/claude-code-hooks-mastery |
| johnlindquist/claude-hooks | github.com/johnlindquist/claude-hooks |
| ChrisWiles/claude-code-showcase | github.com/ChrisWiles/claude-code-showcase |
| decider/claude-hooks | github.com/decider/claude-hooks |
| karanb192/claude-code-hooks | github.com/karanb192/claude-code-hooks |
| pascalporedda/awesome-claude-code | github.com/pascalporedda/awesome-claude-code (hooks-focused) |

---

# Part 3: Agent Teams

## 3.1 Overview

Agent Teams spawn multiple Claude Code instances as teammates, each with their own context window. Teammates work in parallel on separate tasks, coordinated by a team lead.

### Enabling

Teams require either:
- Claude Max subscription, OR
- API key with sufficient quota

## 3.2 TeamCreate

```json
{
  "tool": "TeamCreate",
  "input": {
    "teammates": [
      {
        "name": "auth-agent",
        "subagent_type": "general-purpose",
        "prompt": "Detailed instructions with exact file paths...",
        "mode": "bypassPermissions"
      }
    ]
  }
}
```

### Spawn Options

| Parameter | Values | Notes |
|-----------|--------|-------|
| `subagent_type` | `general-purpose`, `Explore`, `Plan` | general-purpose can edit files |
| `mode` | `"bypassPermissions"` | ALWAYS use -- agents block on prompts otherwise |
| `isolation` | `"none"` (default), `"worktree"` | NEVER use worktree -- changes lost on exit |
| `prompt` | string | Must be exhaustive -- agents have NO conversation history |

### Critical Rules

1. **Always use `mode: "bypassPermissions"`** -- agents go idle on permission prompts
2. **NEVER use `isolation: "worktree"`** -- worktrees are temp git copies, cleaned on exit, all work lost
3. **Always use `subagent_type: "general-purpose"`** for implementation -- Explore/Plan can't edit
4. **Agent prompts must be exhaustive** -- include exact file paths, what to change, acceptance criteria
5. **Verify after agents complete** -- check files exist, typecheck passes

## 3.3 Task System (CC Tasks)

```bash
TaskCreate  # Create task for a teammate
TaskList    # List all tasks
TaskGet     # Get task details
TaskUpdate  # Update task status/details
```

Tasks have:
- `id`, `subject`, `description`, `status` (pending/in_progress/completed)
- `owner` (agent name)
- `blockedBy` (dependency list -- auto-unblock when deps complete)

### Task Dependencies

```json
{
  "tool": "TaskCreate",
  "input": {
    "subject": "Implement login API",
    "description": "...",
    "blockedBy": ["1"]
  }
}
```

When task #1 completes, dependent tasks auto-unblock and waiting agents get notified.

## 3.4 Communication

| Method | Purpose |
|--------|---------|
| `SendMessage type: "message"` | DM to specific teammate |
| `SendMessage type: "broadcast"` | Message ALL teammates (expensive!) |
| `SendMessage type: "shutdown_request"` | Ask teammate to shut down |
| `SendMessage type: "plan_approval_response"` | Approve/reject a teammate's plan |

**Broadcast warning**: N teammates = N separate messages. Use DMs by default.

## 3.5 Plan Approval Workflow

Spawn with `mode: "plan"` for risky work. Agent must get plan approved before editing:

```json
{
  "name": "db-migrator",
  "subagent_type": "general-purpose",
  "mode": "plan",
  "prompt": "..."
}
```

Agent calls `ExitPlanMode` -> leader gets `plan_approval_request` -> approve/reject.

## 3.6 Display Modes

| Mode | Description |
|------|-------------|
| In-process (default) | Teammates share terminal |
| `teammateMode: "tmux"` | Split panes per teammate |

**Navigation**: Shift+Down to cycle, Enter to view, Escape to interrupt, Ctrl+T for task list.

## 3.7 Team Size Guidance

- **3-5 teammates** for most workflows
- **5-6 tasks per teammate** keeps everyone productive
- Three focused teammates outperform five scattered ones
- Never exceed 5 without explicit justification
- Coordination overhead scales quadratically

## 3.8 Token Costs

Agent teams use ~**7x more tokens** than standard sessions:
- Each teammate has its own context window
- Each runs as a separate Claude instance
- Use Sonnet for teammates (not Opus) to control costs

## 3.9 Team Lifecycle Pattern

```
1. Create issues (beads or task tracker)
2. TeamCreate with all teammates
3. TaskCreate for each issue (subject includes tracker ID)
4. Agents claim tasks -> work -> close issues
5. TeammateIdle hook verifies cleanup
6. TaskCompleted hook verifies tracker closure
7. Coordinator verifies (typecheck, file check)
8. SendMessage shutdown_request to all
9. TeamDelete
10. git commit + push
```

## 3.10 Self-Claiming Pattern

Agents can claim tasks autonomously:

```markdown
In your prompt:
"After completing your current task, call TaskList to find the next available
task with status 'pending' and no owner. Claim it with TaskUpdate."
```

## 3.11 File Locking for Concurrent Claims

When multiple agents might edit the same file:
- Use task dependencies to serialize conflicting work
- Or use file-level locking via hooks
- Or partition work by directory

---

# Part 4: Beads

## 4.1 Overview

Beads (`bd`) is a distributed, git-backed graph issue tracker designed for AI agents. Provides persistent, structured memory that survives context compaction.

- **Repository**: github.com/steveyegge/beads (18K+ stars)
- **Current version**: v0.58.0 (March 2026)
- **Backend**: Dolt (Git for data)
- **License**: MIT

## 4.2 Installation

```bash
# macOS
brew install steveyegge/tap/beads

# Initialize in project
cd /path/to/project
bd init
```

## 4.3 Core Commands

```bash
# Issue Management
bd create "Title" -p 1 --description="..." --json   # Create issue
bd update <id> --status in_progress --json           # Claim issue
bd close <id> --reason "..." --json                  # Complete issue
bd show <id>                                          # View issue
bd ready                                              # What can I work on?
bd list                                               # All issues
bd search "query"                                     # Search issues

# Dependencies
bd dep add <child> <parent>                           # Wire dependency
bd dep list <id>                                      # View dependencies

# Memory
bd remember <key> <value>                             # Store a memory
bd recall <key>                                       # Recall by exact key
bd memories                                           # List all memories
bd forget <key>                                       # Delete a memory

# State Management
bd dolt commit -m "message"                           # Commit beads state
bd backup                                             # Export JSONL backup
bd sync                                               # Sync state
bd prime                                              # Inject state into context (~1-2k tokens)
bd purge                                              # Clean up
bd gc                                                 # Garbage collect
bd compact                                            # Compact database
bd diff                                               # Show changes
bd history                                            # Show history
bd query                                              # Advanced queries
bd show --current                                     # Current work
```

## 4.4 Configuration

```bash
# .beads/config.toml
[project]
name = "hypebase-ai"
prefix = "hypebase-ai"

[dolt]
auto_commit = true
```

Issue IDs use format: `hypebase-ai-XXXX` (project-prefixed hash)

## 4.5 Hooks Integration

```json
// ~/.claude/settings.json
{
  "hooks": {
    "SessionStart": [
      { "hooks": [{ "type": "command", "command": "cd /path/to/project && bd prime" }] }
    ],
    "PreCompact": [
      { "hooks": [{ "type": "command", "command": "cd /path/to/project && bd sync" }] }
    ]
  }
}
```

## 4.6 Multi-Agent Workflow with Beads

1. Leader creates beads issues with detailed descriptions
2. CC task subjects include beads ID: `"[hypebase-ai-a1b2] Fix auth redirect"`
3. Agent claims bead: `bd update <id> --status in_progress`
4. Agent works on implementation
5. Agent closes bead: `bd close <id> --reason="Implemented in auth.ts"`
6. TeammateIdle hook verifies beads closed before agent idles
7. TaskCompleted hook verifies beads closed before CC task completes

## 4.7 Molecule & Workflow System

Molecules are reusable workflow templates:

```bash
bd molecule list                     # Available templates
bd molecule run <name>               # Execute a workflow
bd molecule create <name>            # Create custom template
```

## 4.8 MCP Server

Beads can run as an MCP server:

```bash
bd mcp serve                        # Start beads MCP server
```

## 4.9 Protected Branch Workflow

```bash
bd branch create feature-x           # Create feature branch
bd branch switch feature-x           # Switch to branch
bd merge feature-x                   # Merge back
```

---

# Part 5: MCP Servers

## 5.1 Overview

MCP (Model Context Protocol) is an open standard ("USB-C for AI") connecting Claude Code to external tools. 164+ servers in Anthropic's registry, 18,000+ community servers.

## 5.2 Adding Servers

```bash
# HTTP transport (preferred for remote)
claude mcp add --transport http <name> <url>

# Stdio transport (local processes)
claude mcp add --transport stdio <name> -- <command> [args...]

# With environment variables
claude mcp add --transport stdio --env API_KEY=xxx <name> -- npx -y some-package

# With auth headers
claude mcp add --transport http --header "Authorization: Bearer token" <name> <url>

# Import from Claude Desktop
claude mcp add-from-claude-desktop

# Scope options
claude mcp add --scope local ...    # Default: you only, this project
claude mcp add --scope project ...  # .mcp.json (team-shared, git)
claude mcp add --scope user ...     # Global for you
```

**Important**: All options (`--transport`, `--env`, `--scope`) must come **before** the server name.

## 5.3 Managing Servers

```bash
claude mcp list              # List all configured
claude mcp get <name>        # Get details
claude mcp remove <name>     # Remove
/mcp                         # Within Claude Code: status, authenticate
```

## 5.4 .mcp.json (Project Config)

```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/"
    },
    "supabase": {
      "type": "http",
      "url": "https://mcp.supabase.com/mcp"
    },
    "context7": {
      "type": "http",
      "url": "https://mcp.context7.com/mcp"
    },
    "playwright": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest"]
    }
  }
}
```

Env var expansion: `${VAR}` or `${VAR:-default}` in command, args, env, url, headers.

## 5.5 Performance & Context

**Problem**: Each MCP tool definition = ~600-800 tokens. 10 servers = 200K+ tokens before work starts.

**Solution**: MCP Tool Search (auto-enabled at 10% threshold):
- Defers tool loading until needed
- ~85% context reduction (72K -> 8.7K tokens)
- Config: `ENABLE_TOOL_SEARCH=auto:5` (lower threshold to save more)

**Best practices**:
- Keep 5-6 servers active per project
- Use `/mcp` to enable/disable per session
- Use `/context` to monitor per-server consumption
- `disabledMcpServers` in project settings to disable unused globals

## 5.6 Essential Server Catalog

### Development & Git

| Server | Install Command |
|--------|----------------|
| **GitHub** | `claude mcp add --transport http github https://api.githubcopilot.com/mcp/` |
| **Vercel** | `claude mcp add --transport http vercel https://mcp.vercel.com/` |
| **Netlify** | `claude mcp add --transport http netlify https://netlify-mcp.netlify.app/mcp` |
| **Clerk** | `claude mcp add --transport http clerk https://mcp.clerk.com/mcp` |

### Databases

| Server | Install Command |
|--------|----------------|
| **Supabase** (HTTP) | `claude mcp add --transport http supabase https://mcp.supabase.com/mcp` |
| **Supabase** (Stdio) | `claude mcp add --transport stdio -e SUPABASE_ACCESS_TOKEN=xxx supabase -- npx -y @supabase/mcp-server-supabase@latest` |
| **PostgreSQL** | `npx -y @modelcontextprotocol/server-postgres "postgresql://..."` |
| **MongoDB** | `npx -y mongodb-mcp-server` |

### Documentation & Knowledge

| Server | Install Command |
|--------|----------------|
| **Context7** | `claude mcp add --scope user --transport http context7 https://mcp.context7.com/mcp` |
| **Microsoft Learn** | HTTP: `https://learn.microsoft.com/api/mcp` |
| **Memory** | `npx -y @modelcontextprotocol/server-memory` |
| **Sequential Thinking** | `npx -y @modelcontextprotocol/server-sequentialthinking` |

### Browser & Web

| Server | Install Command |
|--------|----------------|
| **Playwright** | `claude mcp add playwright --transport stdio -- npx -y @playwright/mcp@latest` |
| **Firecrawl** | `npx -y firecrawl-mcp` |
| **Fetch** | `npx -y @modelcontextprotocol/server-fetch` |

### Search

| Server | Install Command |
|--------|----------------|
| **Brave Search** | `npx -y @modelcontextprotocol/server-brave-search` (needs `BRAVE_API_KEY`) |
| **Tavily** | `npx -y tavily-mcp@latest` (1,000 free credits/month) |
| **Perplexity** | HTTP remote available |
| **Exa** | `npx -y exa-mcp-server` |

### Observability

| Server | Install Command |
|--------|----------------|
| **Sentry** | `claude mcp add --transport http sentry https://mcp.sentry.dev/mcp` |
| **PostHog** | HTTP: `https://mcp.posthog.com/mcp` |

### Project Management

| Server | Install Command |
|--------|----------------|
| **Linear** | `claude mcp add --transport http linear https://mcp.linear.app/mcp` |
| **Atlassian** | `claude mcp add --transport http atlassian https://mcp.atlassian.com/v1/mcp` |
| **Notion** | `claude mcp add --transport http notion https://mcp.notion.com/mcp` |

### Communication

| Server | Install Command |
|--------|----------------|
| **Slack** | `claude mcp add --transport http slack https://mcp.slack.com/mcp` |

### Design

| Server | Install Command |
|--------|----------------|
| **Figma** | `claude mcp add --transport http figma https://mcp.figma.com/mcp` |

### Payments

| Server | Install Command |
|--------|----------------|
| **Stripe** | `claude mcp add --transport http stripe https://mcp.stripe.com` |

### Cloud & Infrastructure

| Server | Install Command |
|--------|----------------|
| **Cloudflare** | HTTP: `https://bindings.mcp.cloudflare.com/mcp` |
| **Terraform** | `npx -y @hashicorp/terraform-mcp-server` |
| **Kubernetes** | `npx -y @flux159/mcp-server-kubernetes` |

## 5.7 Recommended Starter Setup (Web Developers)

```bash
claude mcp add --scope user --transport http context7 https://mcp.context7.com/mcp
claude mcp add --transport http github https://api.githubcopilot.com/mcp/
claude mcp add --transport http supabase https://mcp.supabase.com/mcp
claude mcp add --transport http sentry https://mcp.sentry.dev/mcp
claude mcp add playwright --transport stdio -- npx -y @playwright/mcp@latest
claude mcp add --transport http vercel https://mcp.vercel.com/
```

## 5.8 MCP Discovery Platforms

| Platform | URL | Servers |
|----------|-----|---------|
| Official Registry | registry.modelcontextprotocol.io | Official |
| Anthropic Registry | api.anthropic.com/mcp-registry/v0/servers | 164+ commercial |
| MCP.so | mcp.so | 18,000+ |
| Smithery | smithery.ai | + install guides |
| PulseMCP | pulsemcp.com/servers | 8,600+ |
| awesome-mcp-servers | github.com/punkpeye/awesome-mcp-servers | Curated |

---

# Part 6: External Tools

## 6.1 Must-Have Tools

### Beads (Issue Tracker)

```bash
brew install steveyegge/tap/beads
bd init
```

### ccusage (Token Tracking)

```bash
npx ccusage@latest daily       # Daily token usage
npx ccusage@latest monthly     # Monthly aggregated
npx ccusage@latest session     # Session-grouped
npx ccusage@latest blocks      # 5-hour billing windows
npx ccusage@latest statusline  # Status line output
# Options: --json, --breakdown, --since, --until, --timezone, --instances
```

Repository: github.com/ryoppippi/ccusage (11.2K stars)

### ccstatusline (Status Line)

```bash
# Customizable status line with Powerline support
# Repo: github.com/sirmalloc/ccstatusline
```

### Claude-Code-Usage-Monitor

```bash
# Real-time terminal monitoring with ML predictions
# Repo: github.com/Maciek-roboblog/Claude-Code-Usage-Monitor
```

### Claude Squad (Session Management)

```bash
# Terminal multiplexer + session orchestrator
# Repo: github.com/smtg-ai/claude-squad
```

### Claude Historian MCP (Memory)

```bash
# Conversation history + memory persistence as MCP server
# Repo: github.com/anthropics/claude-historian-mcp
```

## 6.2 Agent Orchestrators

| Tool | Description | URL |
|------|-------------|-----|
| **Claude Code SDK** | Official programmatic SDK | @anthropic-ai/claude-code-sdk |
| **Claude Orchestra** | Visual workflow builder | Community |
| **MCPHub** | Multi-MCP server manager | github.com/mcp-hub |
| **MetaMCP** | MCP middleware/aggregator | Community |

## 6.3 Skills Libraries

| Library | Install | Description |
|---------|---------|-------------|
| **vercel-labs/agent-skills** | `npx skills add vercel-labs/agent-skills --skill <name> -a claude-code` | react-best-practices, web-design-guidelines, composition-patterns |
| **claude-plugins-official** | `/plugin install <name>@claude-plugins-official` | frontend-design, etc. |
| **travisvn/awesome-claude-skills** | github.com/travisvn/awesome-claude-skills | Skills catalog |
| **ComposioHQ/awesome-claude-skills** | github.com/ComposioHQ/awesome-claude-skills | Integration-tested skills |

## 6.4 Awesome Lists

| List | Stars | URL |
|------|-------|-----|
| **hesreallyhim/awesome-claude-code** | 26,400+ | github.com/hesreallyhim/awesome-claude-code |
| **punkpeye/awesome-mcp-servers** | High | github.com/punkpeye/awesome-mcp-servers |
| **pascalporedda/awesome-claude-code** | - | Hooks-focused |

## 6.5 Configuration Tools

| Tool | Purpose | URL |
|------|---------|-----|
| **claude-token-optimizer** | Reduce session-start tokens by 90% | github.com/nadimtuhin/claude-token-optimizer |
| **MCP Server Selector** | TUI for enabling/disabling MCP servers | github.com/henkisdabro/Claude-Code-MCP-Server-Selector |
| **feiskyer/claude-code-settings** | Curated settings collection | github.com/feiskyer/claude-code-settings |

## 6.6 Hooks Repositories

| Repo | Description |
|------|-------------|
| disler/claude-code-hooks-mastery | Comprehensive hook examples |
| johnlindquist/claude-hooks | Hook collection |
| ChrisWiles/claude-code-showcase | Full project with hooks, skills, agents |
| decider/claude-hooks | Hook recipes |
| karanb192/claude-code-hooks | More recipes |

---

# Part 7: System Optimization

## 7.1 Shell Optimization

Claude Code spawns shell processes on every `Bash` tool call. Reducing startup from ~770ms to ~40ms compounds across hundreds of invocations.

### ZDOTDIR Trick (Most Impactful -- 97% improvement)

```bash
# Create minimal zsh config
mkdir -p ~/.config/zsh-claude
cat > ~/.config/zsh-claude/.zshrc << 'EOF'
export PATH="$HOME/.bun/bin:$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
PS1='$ '
EOF

# Tell Claude Code to use it
# ~/.claude/settings.json:
# { "env": { "ZDOTDIR": "~/.config/zsh-claude" } }
```

### Minimal .zshrc Template

```bash
[[ $- != *i* ]] && return
export PATH="$HOME/.bun/bin:$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
PS1='%~ %# '
HISTSIZE=50000; SAVEHIST=50000; HISTFILE=~/.zsh_history
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then compinit; else compinit -C; fi
```

### Framework Benchmarks

| Framework | Startup Time |
|-----------|-------------|
| Oh-My-Zsh (default) | 300-700ms |
| Oh-My-Zsh (minimal) | 100-200ms |
| Antidote | 50-100ms |
| Zinit (turbo) | 30-80ms |
| No framework | 10-40ms |

### Plugin Deferral (zsh-defer)

```bash
git clone https://github.com/romkatv/zsh-defer.git ~/.zsh/plugins/zsh-defer
source ~/.zsh/plugins/zsh-defer/zsh-defer.plugin.zsh
zsh-defer source ~/.zsh/plugins/zsh-autosuggestions.zsh
zsh-defer source ~/.zsh/plugins/zsh-syntax-highlighting.zsh
```

## 7.2 Git Performance

### Essential Config (96% faster git status)

```bash
git config --global core.fsmonitor true
git config --global core.untrackedCache true
git config --global fetch.writeCommitGraph true
git config --global core.commitGraph true
git config --global feature.manyFiles true
git config --global index.threads true
```

### Background Maintenance

```bash
git maintenance start    # Hourly: prefetch, commit-graph. Daily: loose-objects. Weekly: pack-refs.
```

### Large Repo Config

```gitconfig
[core]
    fsmonitor = true
    untrackedCache = true
    commitGraph = true
    preloadIndex = true

[pack]
    threads = 0

[gc]
    auto = 256

[fetch]
    writeCommitGraph = true
    parallel = 0

[feature]
    manyFiles = true

[index]
    version = 4
    threads = true

[status]
    aheadBehind = false
```

## 7.3 Filesystem Optimization (macOS)

### Spotlight Exclusion

```bash
# Exclude dev dirs from Spotlight indexing
find ~/Documents -name "node_modules" -type d -exec touch {}/.metadata_never_index \;
sudo mdutil -i off ~/Documents/project/node_modules
```

### Time Machine Exclusion

```bash
sudo tmutil addexclusion ~/Documents/project/node_modules
sudo tmutil addexclusion ~/Documents/project/.next
sudo tmutil addexclusion ~/Documents/project/.turbo
```

### File Descriptor Limits (CRITICAL)

macOS default = 256 (extremely low for dev tools):

```bash
# Temporary
ulimit -n 65536

# Permanent: create /Library/LaunchDaemons/limit.maxfiles.plist
# with limits 65536/524288
# Also add to ~/.zshrc: ulimit -n 65536 2>/dev/null
```

### RAM Disk for Build Caches

```bash
RAMDISK_SIZE=$((2 * 1024 * 2048))
DEVICE=$(hdiutil attach -nomount ram://$RAMDISK_SIZE)
diskutil erasevolume HFS+ "RAMDisk" $DEVICE
ln -sf /Volumes/RAMDisk/turbo-cache ~/Documents/project/.turbo
```

Or install TmpDisk: `brew install --cask tmpdisk`

## 7.4 Terminal Emulator

| Terminal | Latency | GPU | Best For |
|----------|---------|-----|----------|
| **Ghostty** | 2ms | Native Metal | Best Mac all-rounder |
| **Alacritty** | 3ms | OpenGL | Raw speed minimalists |
| **Kitty** | 3ms | OpenGL | Linux power users |
| **WezTerm** | 4ms | Yes | Cross-platform |
| **iTerm2** | 12ms | Partial | Feature-rich Mac |
| Terminal.app | 15ms+ | No | Avoid for dev |

```bash
brew install --cask ghostty
```

Performance settings (any terminal):
- Reduce scrollback to 10,000 lines
- Disable ligatures
- Use simple monospace font
- Minimize transparency/blur

## 7.5 Network Optimization

### DNS Caching

```bash
brew install dnsmasq
echo "cache-size=10000" >> /opt/homebrew/etc/dnsmasq.conf
echo "server=1.1.1.1" >> /opt/homebrew/etc/dnsmasq.conf
echo "server=8.8.8.8" >> /opt/homebrew/etc/dnsmasq.conf
sudo brew services start dnsmasq
# System Settings > Network > DNS > Add 127.0.0.1
```

## 7.6 macOS-Specific

### Disable App Nap for Terminal

```bash
defaults write com.apple.Terminal NSAppSleepDisabled -bool YES
defaults write com.googlecode.iterm2 NSAppSleepDisabled -bool YES
```

### Reduce Animations

```bash
defaults write com.apple.dock expose-animation-duration -float 0.1
defaults write com.apple.dock autohide-delay -float 0
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
defaults write com.apple.CrashReporter DialogType -string "none"
killall Dock
```

### Energy Settings

```bash
sudo pmset -c sleep 0 disksleep 0 displaysleep 30 powernap 0
```

## 7.7 Process Management

```bash
# Higher priority for Claude Code
nice -n -5 claude
# Or alias: alias claude='nice -n -5 claude'

# Lower priority for Docker
pgrep -f "Docker" | xargs renice -n 10
```

## 7.8 Quick Setup Script (macOS)

```bash
#!/bin/bash
echo "=== Claude Code System Optimization ==="

# Git performance
git config --global core.fsmonitor true
git config --global core.untrackedCache true
git config --global fetch.writeCommitGraph true
git config --global core.commitGraph true
git config --global feature.manyFiles true
git config --global index.threads true
git maintenance start 2>/dev/null || true

# File descriptor limits
ulimit -n 65536 2>/dev/null

# Spotlight exclusions
[ -d "node_modules" ] && touch node_modules/.metadata_never_index
[ -d ".next" ] && touch .next/.metadata_never_index

# Time Machine exclusions
tmutil addexclusion node_modules 2>/dev/null
tmutil addexclusion .next 2>/dev/null
tmutil addexclusion .turbo 2>/dev/null

# macOS performance
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
defaults write com.apple.dock expose-animation-duration -float 0.1
defaults write com.apple.CrashReporter DialogType -string "none"
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

echo "Done! Manual: ZDOTDIR, terminal switch, Docker VirtioFS, dnsmasq"
```

## 7.9 Implementation Priority

### Tier 1 (Do First -- High Impact, Easy)

| Optimization | Impact | Time |
|-------------|--------|------|
| Git fsmonitor + untrackedCache | 96% faster git status | 2 min |
| Shell ZDOTDIR for Claude Code | 97% faster shell spawn | 5 min |
| Spotlight exclusion | Reduced I/O contention | 2 min |
| File descriptor limit increase | Prevents EMFILE errors | 5 min |
| Time Machine exclusion | Reduced backup I/O | 1 min |

### Tier 2 (Low Effort, Moderate Impact)

| Optimization | Time |
|-------------|------|
| Disable App Nap | 1 min |
| Reduce macOS animations | 2 min |
| Git maintenance start | 1 min |
| Terminal switch (Ghostty) | 10 min |
| Energy settings | 2 min |

### Tier 3 (More Effort)

| Optimization | Time |
|-------------|------|
| DNS caching (dnsmasq) | 15 min |
| Docker VirtioFS + resources | 10 min |
| RAM disk for build cache | 15 min |
| zsh-defer plugin loading | 20 min |

---

# Part 8: Token Optimization

## 8.1 Model Pricing (March 2026)

| Model | Input ($/MTok) | Output ($/MTok) | Cache Read | Cache Write (5min) |
|-------|----------------|-----------------|------------|-------------------|
| Opus 4.6 | $5 | $25 | $0.50 | $6.25 |
| Sonnet 4.6 | $3 | $15 | $0.30 | $3.75 |
| Haiku 4.5 | $1 | $5 | $0.10 | $1.25 |

**Key ratios**: Cache read = 10x cheaper (90% savings). Sonnet = 40% cheaper than Opus. Haiku = 80% cheaper than Opus.

**Average**: ~$6/dev/day, 90th percentile under $12/day.

## 8.2 Top 10 Cost Reduction Strategies

1. **Use Sonnet for 80% of work** -- 40% savings vs Opus
2. **Configure `.claudeignore`** -- 50-90% savings on generated files
3. **`/clear` between tasks** -- eliminate stale context waste
4. **Keep CLAUDE.md under 500 lines** -- move specialized content to skills
5. **Use subagents for verbose operations** -- isolate test output, logs, docs
6. **Prompt caching** (auto-enabled) -- 90% savings on cached input reads
7. **Specific prompts** -- "fix auth.ts line 42" not "fix the login bug"
8. **Lower thinking for simple tasks** -- `CLAUDE_CODE_EFFORT_LEVEL=low`
9. **Disable unused MCP servers** -- each adds tool definitions to every request
10. **Use hooks to preprocess** -- filter test output, logs before context

## 8.3 Context Window Management

- 200,000-token window (~150K words)
- Performance degrades as context fills
- Stay under **75% utilization** for best quality

### Commands

| Command | Purpose |
|---------|---------|
| `/clear` | Reset context (between unrelated tasks) |
| `/compact` | Summarize and compress history |
| `/compact <instructions>` | Directed compaction |
| `/context` | Show token usage breakdown |
| `/model haiku` | Switch to cheaper model |
| `/cost` | API token usage (API users) |
| `/stats` | Usage patterns (subscribers) |

### Auto-Compaction

Triggers at ~95% by default. Override: `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=60`

### Partial Compaction

`Esc + Esc` or `/rewind` -> select checkpoint -> "Summarize from here"

## 8.4 Prompt Caching (Automatic)

Claude Code auto-enables prompt caching on system prompt, tool definitions, CLAUDE.md, and conversation history.

- 5-min cache: 1.25x write cost, pays off after 1 read
- 1-hour cache: 2x write cost, pays off after 2 reads
- Without caching: 100-turn Opus session = $50-100 input tokens
- With caching: $10-19 (5-10x reduction)

**Don't** change CLAUDE.md mid-session (invalidates cache).

## 8.5 Model Selection

| Model | Best For |
|-------|---------|
| Opus 4.6 | Complex architecture, multi-step reasoning, hard debugging |
| Sonnet 4.6 | 80% of work: implementation, refactoring, routine coding |
| Haiku 4.5 | Quick validation, formatting, simple queries, subagent exploration |

```bash
/model          # Switch mid-session
/config         # Set default model
```

### Effort Level

```bash
CLAUDE_CODE_EFFORT_LEVEL=low     # Faster, cheaper, less deep
CLAUDE_CODE_EFFORT_LEVEL=medium  # Balanced
CLAUDE_CODE_EFFORT_LEVEL=high    # Maximum depth
```

## 8.6 Command Output Optimization

```bash
# Git (reduce token output)
git status --short
git log --oneline -10
git diff --stat
git diff --name-only

# Package managers
bun install --silent
npm test --silent

# Search
grep --files-with-matches    # Filenames only
grep -c                       # Count only

# Docker
docker ps --format "{{.Names}}: {{.Status}}"
docker logs --tail 50

# General
# Use --quiet, --format, | head -N, | wc -l
```

## 8.7 Efficient Tool Use

| Task | Use This | Not This |
|------|----------|----------|
| Read files | `Read` tool | `cat`, `head` |
| Search files | `Glob` | `find`, `ls` |
| Search content | `Grep` | `grep`, `rg` |
| Write files | `Write` | heredoc, echo |
| Edit files | `Edit` | `sed`, `awk` |

**Parallel calls**: Make independent tool calls in parallel (1 round trip vs N).

## 8.8 Skills vs CLAUDE.md (Token Savings)

CLAUDE.md loads at EVERY session. Skills load on-demand only.

**Move to skills**: PR review workflows, migration procedures, deployment checklists, framework patterns, testing methodologies.

**Keep in CLAUDE.md**: Build commands, code style rules, project structure, universal gotchas.

If 60% of 1,000-line CLAUDE.md moves to skills: ~24K tokens saved per session start.

## 8.9 Subscription vs API

| Plan | Monthly | Best For |
|------|---------|----------|
| Claude Pro | $20 | Light users |
| Claude Max 5x | $100 | Moderate daily users |
| Claude Max 20x | $200 | Heavy daily users |
| API (pay-per-use) | Variable | Automation, CI/CD, teams |

## 8.10 Anti-Patterns

1. **Kitchen Sink**: Mixed unrelated tasks in one session -> `/clear` between tasks
2. **Correction Loop**: 3+ failed corrections -> `/clear` + better initial prompt
3. **Infinite Exploration**: Unscoped "investigate" -> scope to specific directory or use subagents

---

# Part 9: Developer Experience

## 9.1 Keyboard Shortcuts (Complete)

### Input & Editing

| Shortcut | Action |
|----------|--------|
| `Enter` | Submit prompt (or newline in multi-line) |
| `Shift+Enter` | Force newline |
| `Ctrl+C` | Cancel current generation |
| `Ctrl+D` | Exit Claude Code |
| `Escape` | Interrupt (1x: cancel tool, 2x: open rewind) |
| `Tab` | Autocomplete file paths in prompt |
| `Ctrl+R` | Open fuzzy file search |
| `Ctrl+A` / `Ctrl+E` | Jump to start/end of line |
| `Ctrl+W` | Delete word backward |
| `Ctrl+U` | Delete to start of line |
| `Ctrl+K` | Delete to end of line |

### During Generation

| Shortcut | Action |
|----------|--------|
| `Escape` | Stop generating |
| `Escape Escape` | Open rewind/checkpoint menu |

### Permission Prompts

| Shortcut | Action |
|----------|--------|
| `y` | Accept once |
| `n` | Deny |
| `a` | Always allow (adds to settings) |
| `d` | Always deny (adds to settings) |

### Team Navigation

| Shortcut | Action |
|----------|--------|
| `Shift+Down` | Cycle through teammates |
| `Enter` | View teammate session |
| `Escape` | Back to own session |
| `Ctrl+T` | Toggle task list |

### Special

| Shortcut | Action |
|----------|--------|
| `Ctrl+B` | Send current operation to background |
| `Ctrl+L` | Clear screen |
| `Ctrl+Space` | Toggle model (e.g., Opus <-> Sonnet) |

## 9.2 Keybinding Customization

```json
// ~/.claude/settings.json
{
  "keybindings": {
    "ctrl+shift+p": "togglePlan",
    "ctrl+shift+c": "compact"
  }
}
```

## 9.3 Vim Mode

```json
{
  "vim_mode": true
}
```

Or toggle with `/vim`. Supports: `i`, `a`, `o`, `Esc`, `dd`, `yy`, `p`, `w`, `b`, `0`, `$`, `/search`.

## 9.4 Slash Commands (Built-in)

| Command | Purpose |
|---------|---------|
| `/clear` | Reset context |
| `/compact` | Compress context |
| `/compact <focus>` | Directed compression |
| `/context` | Show token usage |
| `/cost` | API cost stats |
| `/stats` | Usage patterns |
| `/model` | Switch model |
| `/config` | Open settings |
| `/mcp` | MCP server management |
| `/help` | Help documentation |
| `/vim` | Toggle vim mode |
| `/fast` | Toggle fast mode (same model, faster output) |
| `/rewind` | Rewind to checkpoint |
| `/rename <name>` | Name current session |
| `/resume` | Resume named session |
| `/review` | Code review mode |
| `/plan` | Toggle plan mode |
| `/statusline` | Configure status line |
| `/login` | Authenticate |
| `/logout` | Sign out |

## 9.5 CLI Flags (Key Flags)

```bash
claude                          # Interactive mode
claude -p "prompt"              # Headless (non-interactive, pipe-friendly)
claude -p "prompt" --json       # JSON output
claude -p "prompt" --output-format stream-json  # Streaming JSON
claude --model sonnet           # Specify model
claude --plan                   # Start in plan mode
claude --yes                    # Auto-approve all tools
claude --resume                 # Resume last session
claude --resume <session-id>    # Resume specific session
claude --continue               # Continue last conversation
claude --add-dir /other/project # Add directory to context
claude --system-prompt "..."    # Custom system prompt
claude --append-system-prompt   # Append to default system prompt
claude --max-turns 5            # Limit conversation turns (headless)
claude --verbose                # Debug output
claude --debug                  # Maximum debug output
claude --allowedTools "Read,Bash(git *)"  # Restrict tools
claude --disallowedTools "Write,Edit"     # Block specific tools
```

### Piping

```bash
# Pipe input
cat file.ts | claude -p "Review this code"

# Pipe output
claude -p "List all TODOs" --json | jq '.result'

# Fan-out processing
for f in src/*.ts; do claude -p "Add types to $f" --allowedTools "Edit"; done
```

## 9.6 Session Management

```bash
claude --resume                 # Resume last session
claude --resume <id>            # Resume specific session
claude --continue               # Continue last conversation
/rename my-feature              # Name current session
/resume                         # Pick session to resume
```

## 9.7 Status Line

Persistent display at bottom of terminal:

```bash
/statusline show model name and context usage percentage
```

Or configure in settings:

```json
{
  "statusLine": {
    "command": "~/.claude/statusline.sh"
  }
}
```

Status line receives JSON via stdin with `context_window.used_percentage`, model info, costs, git status.

## 9.8 Fast Mode

```bash
/fast                           # Toggle fast mode
```

Same model (Opus 4.6), faster output generation. No model change.

## 9.9 Extended Thinking

Opus and Sonnet 4.6 support extended thinking with configurable budget:

```bash
MAX_THINKING_TOKENS=31999 claude
```

## 9.10 Shell Aliases

```bash
# ~/.zshrc
alias cc='claude'
alias ccp='claude -p'
alias ccr='claude --resume'
alias ccf='claude -p --json'
alias ccplan='claude --plan'
alias ccyes='claude --yes'
```

## 9.11 CI/CD Integration

### GitHub Actions

```yaml
name: Claude Code Review
on: [pull_request]
jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Claude Code
        run: npm install -g @anthropic-ai/claude-code
      - name: Review PR
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          claude -p "Review the changes in this PR for security issues, \
            performance problems, and code quality. Output as markdown." \
            --json --max-turns 3
```

### Headless Mode for Automation

```bash
# Automated tasks
claude -p "Run all tests and report failures" --json --max-turns 10
claude -p "Generate TypeScript types from schema.sql" --allowedTools "Read,Write"
claude -p "Fix all ESLint errors in src/" --allowedTools "Read,Edit,Bash(bun run lint*)"
```

## 9.12 Git Worktrees (Parallel Sessions)

```bash
# Create worktree for parallel work
git worktree add ../project-feature-x feature-x
cd ../project-feature-x
claude  # Separate session, separate branch

# Clean up
git worktree remove ../project-feature-x
```

Each worktree is a separate working directory with its own branch. Multiple Claude Code sessions can work in parallel without conflicts.

## 9.13 Background Tasks

```bash
Ctrl+B  # Send current operation to background
```

Background tasks continue running. You'll be notified on completion.

## 9.14 IDE Integration

### VS Code

Claude Code is built into VS Code via the Claude extension. Terminal-based Claude Code also works in VS Code's integrated terminal.

### JetBrains

JetBrains has MCP integration. Claude Code works in JetBrains terminal.

## 9.15 Quick Reference Cheat Sheet

```
ESSENTIALS                    CONTEXT MANAGEMENT
  claude                        /clear          Reset
  claude -p "..."               /compact        Compress
  Ctrl+C to cancel              /context        Usage
  Escape to stop                /model haiku    Switch model
  Esc+Esc to rewind             /cost           API costs

PERMISSIONS                   SEARCH & EDIT
  y = once                      Tab = file autocomplete
  n = deny                      Ctrl+R = fuzzy search
  a = always allow              /plan = toggle plan mode
  d = always deny               /fast = toggle fast mode

TEAMS                         SESSION
  Shift+Down = cycle            /rename name    Name session
  Enter = view teammate         /resume         Resume session
  Ctrl+T = task list            --continue      Continue last
  Escape = back                 --resume        Resume last
```

---

# Part 10: Security

## 10.1 Permission Architecture

### Three Layers

1. **Tool-level**: Allow/deny specific tools and patterns
2. **Hook-level**: Pre-hooks can block/modify tool calls deterministically
3. **Managed settings**: Enterprise-level enforcement (overrides everything)

### Comprehensive Allow List (Production-Ready)

```json
{
  "permissions": {
    "allow": [
      "Read",
      "Glob",
      "Grep",
      "Bash(git status*)",
      "Bash(git diff*)",
      "Bash(git log*)",
      "Bash(git branch*)",
      "Bash(git stash*)",
      "Bash(git add *)",
      "Bash(git commit *)",
      "Bash(git checkout *)",
      "Bash(git merge *)",
      "Bash(git rebase *)",
      "Bash(git fetch*)",
      "Bash(git pull*)",
      "Bash(bun *)",
      "Bash(npm run *)",
      "Bash(npm test*)",
      "Bash(npx *)",
      "Bash(node *)",
      "Bash(tsc *)",
      "Bash(ls *)",
      "Bash(cat *)",
      "Bash(head *)",
      "Bash(tail *)",
      "Bash(wc *)",
      "Bash(find *)",
      "Bash(grep *)",
      "Bash(rg *)",
      "Bash(echo *)",
      "Bash(pwd)",
      "Bash(which *)",
      "Bash(env)",
      "Bash(printenv *)",
      "Bash(mkdir *)",
      "Bash(cp *)",
      "Bash(mv *)",
      "Bash(touch *)",
      "Bash(sort *)",
      "Bash(uniq *)",
      "Bash(diff *)",
      "Bash(jq *)",
      "Bash(curl *)",
      "Bash(docker compose *)",
      "Bash(docker ps*)",
      "Bash(docker logs*)",
      "Write",
      "Edit",
      "NotebookEdit",
      "mcp__context7__*",
      "mcp__github__*",
      "mcp__supabase__*",
      "mcp__playwright__*"
    ],
    "deny": [
      "Bash(rm -rf /)",
      "Bash(rm -rf ~)",
      "Bash(rm -rf .)",
      "Bash(sudo rm -rf *)",
      "Bash(curl * | sh)",
      "Bash(curl * | bash)",
      "Bash(wget * | sh)",
      "Bash(wget * | bash)",
      "Bash(eval *)",
      "Bash(chmod 777 *)",
      "Bash(chmod -R 777 *)",
      "Bash(git push --force*)",
      "Bash(git push -f *)",
      "Bash(git reset --hard*)",
      "Bash(git clean -fd*)",
      "Bash(dd if=*)",
      "Bash(mkfs*)",
      "Bash(:(){ :|:& };:*)",
      "Bash(> /dev/sd*)",
      "Bash(shutdown *)",
      "Bash(reboot*)",
      "Bash(killall *)",
      "Bash(pkill -9 *)",
      "Bash(*DROP DATABASE*)",
      "Bash(*DROP TABLE*)",
      "Bash(*TRUNCATE *)"
    ]
  }
}
```

## 10.2 Sandboxing

### macOS Sandbox (Default)

Claude Code runs with macOS Seatbelt sandbox by default, restricting:
- Network access to approved domains
- Filesystem access to project directory + temp
- No access to other user directories

### Docker Sandbox

```bash
# Run Claude Code in Docker
docker run -it --rm \
  -v $(pwd):/workspace \
  -e ANTHROPIC_API_KEY \
  anthropic/claude-code
```

### Firecracker/MicroVM

For maximum isolation, run in a microVM.

## 10.3 Security Best Practices

1. **Never use `--yes` in production** -- always review tool calls
2. **Use deny lists for destructive commands** (rm -rf, force push, eval, curl|sh)
3. **Hook-based guardrails** are more reliable than CLAUDE.md instructions
4. **Audit MCP servers before installing** -- they execute code on your machine
5. **Use project-scoped API keys** for MCP servers (narrow blast radius)
6. **Start with read-only MCP servers** before adding write capabilities
7. **Review file changes before committing** -- Claude can write to any file
8. **Use `.claudeignore`** to prevent reading sensitive files (.env, credentials)
9. **Set workspace spend limits** for API usage control
10. **Use managed settings** for enterprise enforcement
11. **Understand `--dangerously-skip-permissions`** -- This flag (enabled by `--allow-dangerously-skip-permissions` in settings) bypasses ALL permission checks including tool approvals. Only use for fully trusted, automated pipelines (CI/CD). Never expose to untrusted input.

## 10.4 Common Security Patterns

### Hook: Prevent Secrets in Code

```bash
#!/bin/bash
# Pre-write hook: check for potential secrets
input=$(cat)
content=$(echo "$input" | jq -r '.tool_input.content // empty')

if echo "$content" | grep -qiE '(password|secret|api_key|token)\s*[:=]\s*["\x27][^"\x27]{8,}'; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","reason":"Potential secret detected in file content"}}'
  exit 0
fi
echo '{}'
```

### Hook: Restrict File Writes to Project

```bash
#!/bin/bash
input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
project_dir=$(echo "$input" | jq -r '.project_directory')

if [[ ! "$file_path" == "$project_dir"* ]]; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","reason":"Write blocked: outside project directory"}}'
  exit 0
fi
echo '{}'
```

### Managed Settings: Enterprise Lockdown

```json
{
  "lockdown": true,
  "lockModel": "sonnet",
  "disableAutoMemory": true,
  "disableHooks": false,
  "allowedMcpServers": [
    { "serverName": "github" },
    { "serverUrl": "https://mcp.company.com/*" }
  ],
  "deniedMcpServers": [
    { "serverName": "*" }
  ]
}
```

---

# Part 11: Community Resources

## 11.1 Top 5 Constantly Updated Resources

| Rank | Resource | URL | Update Frequency |
|------|----------|-----|-----------------|
| 1 | **ClaudeLog** | claudelog.com | Continuous. Run by Claude Developer Ambassador, r/ClaudeAI mod |
| 2 | **Claude Fast** | claudefa.st | Regular. Most in-depth agent teams guide. Changelog tracking |
| 3 | **Cranot/claude-code-guide** | github.com/Cranot/claude-code-guide | Auto-updated every 2 days from official docs |
| 4 | **awesome-claude-code** | github.com/hesreallyhim/awesome-claude-code | 26.4K stars, 819 commits. Definitive ecosystem directory |
| 5 | **alexop.dev** | alexop.dev/posts/ | Regular. Deep technical dives, decision frameworks |

## 11.2 Official Anthropic Resources

| Resource | URL |
|----------|-----|
| Official Docs | code.claude.com/docs/en/best-practices |
| Engineering Blog | anthropic.com/engineering/claude-code-best-practices |
| How Anthropic Teams Use CC | claude.com/blog/how-anthropic-teams-use-claude-code |
| Skills Docs | code.claude.com/docs/en/skills |
| Hooks Reference | code.claude.com/docs/en/hooks |
| Hooks Guide | claude.com/blog/how-to-configure-hooks |
| MCP Docs | code.claude.com/docs/en/mcp |
| Permissions Docs | code.claude.com/docs/en/permissions |
| Security Docs | code.claude.com/docs/en/security |
| Settings Docs | code.claude.com/docs/en/settings |
| Cost Management | code.claude.com/docs/en/costs |
| Agent Teams | code.claude.com/docs/en/agent-teams |
| Sandboxing | code.claude.com/docs/en/sandboxing |

## 11.3 GitHub Repositories (Living Documents)

| Repo | Stars | Focus |
|------|-------|-------|
| hesreallyhim/awesome-claude-code | 26.4K | THE ecosystem directory |
| Cranot/claude-code-guide | 2.4K | Auto-updating guide (every 2 days) |
| ykdojo/claude-code-tips | High | 45 practical tips |
| FlorianBruniaux/claude-code-ultimate-guide | - | Templates, quizzes, cheatsheet |
| wesammustafa/Claude-Code-Everything-You-Need-to-Know | - | All-in-one, BMAD method |
| ChrisWiles/claude-code-showcase | - | Full working config example |
| affaan-m/everything-claude-code | - | Performance optimization system |
| rosmur/claudecode-best-practices | - | HN-featured aggregation |

## 11.4 Practitioner Blogs (Real-World Configs)

| Author | URL | Notable Content |
|--------|-----|----------------|
| Daniil Okhlopkov | okhlopkov.com | TON Foundation, MCP/hooks real usage, $100/mo cost |
| alexop.dev | alexop.dev/posts/ | TDD loops, plugins, hooks, decision frameworks |
| Simon Willison | simonwillison.net | "Agentic Engineering Patterns" living guide |
| Steve Sewell | builder.io/blog/claude-code | CEO workflow, /clear habit, model selection |
| Boris Cherny | @bcherny on X | Creator of Claude Code, viral workflow thread |

## 11.5 Newsletters

| Newsletter | URL | Focus |
|------------|-----|-------|
| Agentic Coding (YK Dojo) | agenticcoding.substack.com | Tips, status line scripts |
| AI Coding Daily | aicodingdaily.substack.com | Weekly AI coding news |
| Push to Prod | getpushtoprod.substack.com | 50 tips, context engineering |
| AI Maker | aimaker.substack.com | Claude Code as personal AI OS |
| The Neuron | theneuron.ai | Tutorial rankings, monthly tips |

## 11.6 Video Courses

| Course | Author | Duration | Level |
|--------|--------|----------|-------|
| Claude Code Masterclass | Nick Saraev | 4 hours | Int-Adv |
| Full Course for Beginners | Sabrina Ramonov | 90 min | Beginner |
| Official Tutorials | Anthropic | Various | All |

## 11.7 Communities

| Community | Size | URL |
|-----------|------|-----|
| r/ClaudeAI | 535K+ | reddit.com/r/ClaudeAI |
| Official Discord | 66K+ | discord.com/invite/6PPFFzqPDZ |
| Hacker News | - | Various threads (see Part 12) |

## 11.8 Optimal Learning Strategy

- **Daily/weekly**: r/ClaudeAI + awesome-claude-code + AI Coding Daily
- **Deep dives**: ClaudeLog + claudefa.st + alexop.dev + okhlopkov.com
- **Reference**: Official docs + Cranot's auto-updating guide
- **Learning**: Sabrina (beginner) -> Nick Saraev (advanced) video courses
- **Creator insights**: Boris Cherny @bcherny on X

---

# Part 12: Key URLs for Self-Updating Prompts

## 12.1 Official Documentation (Canonical)

These URLs should be referenced in setup prompts for the latest information:

```
https://code.claude.com/docs/en/best-practices
https://code.claude.com/docs/en/settings
https://code.claude.com/docs/en/permissions
https://code.claude.com/docs/en/hooks
https://code.claude.com/docs/en/hooks-guide
https://code.claude.com/docs/en/skills
https://code.claude.com/docs/en/sub-agents
https://code.claude.com/docs/en/agent-teams
https://code.claude.com/docs/en/mcp
https://code.claude.com/docs/en/costs
https://code.claude.com/docs/en/security
https://code.claude.com/docs/en/sandboxing
https://code.claude.com/docs/en/statusline
https://code.claude.com/docs/en/model-config
```

## 12.2 Auto-Updating Community Resources

```
https://claudelog.com/
https://claudefa.st/
https://github.com/Cranot/claude-code-guide          # Auto-updated every 2 days
https://github.com/hesreallyhim/awesome-claude-code   # 26.4K stars, 819 commits
https://registry.modelcontextprotocol.io              # Official MCP registry
https://mcp.so                                         # 18,000+ MCP servers
https://pulsemcp.com/servers                           # 8,600+ MCP servers
```

## 12.3 API & Registry Endpoints

```
https://api.anthropic.com/mcp-registry/v0/servers?version=latest    # Commercial MCP servers
https://registry.modelcontextprotocol.io                             # Official MCP registry
https://platform.claude.com/docs/en/about-claude/pricing            # Current pricing
```

## 12.4 Key GitHub Repos (Install Commands)

```bash
# Issue tracking
brew install steveyegge/tap/beads

# Token tracking
npx ccusage@latest daily

# MCP servers
claude mcp add --scope user --transport http context7 https://mcp.context7.com/mcp
claude mcp add --transport http github https://api.githubcopilot.com/mcp/
claude mcp add --transport http supabase https://mcp.supabase.com/mcp
claude mcp add --transport http sentry https://mcp.sentry.dev/mcp
claude mcp add playwright --transport stdio -- npx -y @playwright/mcp@latest

# Skills
npx skills add vercel-labs/agent-skills --skill react-best-practices -a claude-code

# Terminal
brew install --cask ghostty
```

## 12.5 Hacker News Threads (High-Quality Discussion)

```
https://news.ycombinator.com/item?id=44362244   # How to use CC effectively?
https://news.ycombinator.com/item?id=44836879   # Getting good results from CC
https://news.ycombinator.com/item?id=45786738   # How I use every CC feature
https://news.ycombinator.com/item?id=45107962   # Staff engineer's journey
https://news.ycombinator.com/item?id=45830267   # Best practices v2
https://news.ycombinator.com/item?id=47243272   # Agentic Engineering Patterns
```

## 12.6 Podcasts (Creator Insights)

```
https://www.ycombinator.com/library/NJ-inside-claude-code-with-its-creator-boris-cherny
https://podcasts.apple.com/us/podcast/inside-claude-code-from-the-engineers-who-built-it/id1719789201?i=1000734060623
```

---

# Appendix A: Complete settings.json Reference

```json
{
  "permissions": {
    "allow": ["..."],
    "deny": ["..."]
  },
  "env": {
    "ZDOTDIR": "~/.config/zsh-claude",
    "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "60",
    "DISABLE_NON_ESSENTIAL_MODEL_CALLS": "1",
    "ENABLE_TOOL_SEARCH": "auto:5"
  },
  "hooks": {
    "SessionStart": [{ "hooks": [{ "type": "command", "command": "..." }] }],
    "PreToolUse": [{ "matcher": "Bash", "hooks": [{ "type": "command", "command": "..." }] }],
    "PostToolUse": [{ "hooks": [{ "type": "command", "command": "...", "async": true }] }],
    "PreCompact": [{ "hooks": [{ "type": "command", "command": "..." }] }],
    "Stop": [{ "hooks": [{ "type": "command", "command": "...", "async": true }] }],
    "TeammateIdle": [{ "hooks": [{ "type": "command", "command": "..." }] }],
    "TaskCompleted": [{ "hooks": [{ "type": "command", "command": "..." }] }]
  },
  "statusLine": {
    "command": "~/.claude/statusline.sh"
  },
  "vim_mode": false,
  "keybindings": {}
}
```

# Appendix B: .mcp.json Reference

```json
{
  "mcpServers": {
    "server-name": {
      "type": "http",
      "url": "https://...",
      "headers": { "Authorization": "Bearer ${TOKEN}" }
    },
    "local-server": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@package/name"],
      "env": { "API_KEY": "${API_KEY}" }
    }
  }
}
```

# Appendix C: Hook Event Quick Reference

| Event | When | Input | Can Block | Can Modify |
|-------|------|-------|-----------|-----------|
| SessionStart | Session begins | session_id, source | No | No |
| SessionEnd | Session ends | session_id | No | No |
| Stop | Generation stops | session_id | Yes | No |
| PreCompact | Before compaction | session_id | No | No |
| PreToolUse | Before any tool | tool_name, tool_input | Yes | Yes |
| PostToolUse | After any tool | tool_name, tool_input, tool_output | No | No |
| PostToolUseFailure | After tool fails | tool_name, tool_input, error | No | No |
| PermissionRequest | Permission prompt | tool_name, tool_input | Yes | Yes |
| Notification | Alert would send | message | No | No |
| UserPromptSubmit | User presses Enter | prompt | Yes | Yes (modify prompt) |
| TeammateIdle | Agent going idle | agent_name | Yes | No |
| TaskCompleted | Task marked done | task_id | Yes | No |
| SubagentStart | Subagent spawned | agent_type | No | No |
| SubagentStop | Subagent finished | agent_type | Yes | No |
| ConfigChange | Settings changed | config_source | Yes | No |
| InstructionsLoaded | CLAUDE.md loaded | instructions | No | No |
| WorktreeCreate | Worktree created | path | Yes | Yes |
| WorktreeRemove | Worktree removed | path | No | No |

---

*Synthesized from 12 research files totaling ~16,000 lines. For the original source material, see `/claude-setup-research/raw/`.*
