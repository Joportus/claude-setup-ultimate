# R10: Advanced Context Management, Memory, and Persistence Patterns

> Comprehensive research on how to optimally manage context, memory, and persistence in Claude Code. Covers CLAUDE.md hierarchy, auto memory, skills, plugins, custom agents, context compaction, session management, .claudeignore, and git worktree patterns.

**Source**: Official Claude Code documentation (code.claude.com), community resources, and web research.
**Date**: 2026-03-05

---

## Table of Contents

1. [CLAUDE.md Hierarchy](#1-claudemd-hierarchy)
2. [Auto Memory System](#2-auto-memory-system)
3. [.claude/rules/ System](#3-clauderules-system)
4. [Skills System](#4-skills-system)
5. [Plugins System](#5-plugins-system)
6. [Custom Agents (.claude/agents/)](#6-custom-agents)
7. [Context Compaction](#7-context-compaction)
8. [Session Management](#8-session-management)
9. [.claudeignore and File Exclusion](#9-claudeignore-and-file-exclusion)
10. [Git Worktree Patterns](#10-git-worktree-patterns)
11. [Context Cost Management](#11-context-cost-management)
12. [Community Tools and Resources](#12-community-tools-and-resources)
13. [Best Practices Summary](#13-best-practices-summary)

---

## 1. CLAUDE.md Hierarchy

### What It Is

CLAUDE.md files are markdown files that give Claude persistent instructions for a project, your personal workflow, or your entire organization. They are loaded into the context window at the start of every session, consuming tokens alongside your conversation. They are context, not enforced configuration -- the more specific and concise your instructions, the more consistently Claude follows them.

### Complete Hierarchy (Priority Order)

| Scope | Location | Purpose | Shared With |
|-------|----------|---------|-------------|
| **Managed policy** (highest) | macOS: `/Library/Application Support/ClaudeCode/CLAUDE.md`; Linux/WSL: `/etc/claude-code/CLAUDE.md`; Windows: `C:\Program Files\ClaudeCode\CLAUDE.md` | Organization-wide instructions managed by IT/DevOps | All users in organization |
| **Project instructions** | `./CLAUDE.md` or `./.claude/CLAUDE.md` | Team-shared instructions for the project | Team members via source control |
| **User instructions** | `~/.claude/CLAUDE.md` | Personal preferences for all projects | Just you (all projects) |
| **Local instructions** | `./CLAUDE.local.md` | Personal project-specific preferences, not checked into git | Just you (current project) |

**Key rule**: More specific locations take precedence over broader ones. Managed policy CLAUDE.md files **cannot be excluded** by individual settings.

### Loading Behavior

Claude Code reads CLAUDE.md files by **walking up the directory tree** from your current working directory, checking each directory along the way for `CLAUDE.md` and `CLAUDE.local.md` files. If you run Claude Code in `foo/bar/`, it loads instructions from both `foo/bar/CLAUDE.md` and `foo/CLAUDE.md`.

**Subdirectory CLAUDE.md files** are NOT loaded at launch. They are loaded **on demand** when Claude reads files in those subdirectories. This is lazy loading to save context space.

**Loading order** (as confirmed by SFEIR Institute research):
1. Global user CLAUDE.md
2. Project root CLAUDE.md
3. `.claude/rules/*.md` (alphabetical)
4. Auto-memory MEMORY.md (first 200 lines)

### Import Syntax

CLAUDE.md files can import additional files using `@path/to/import` syntax:

```markdown
See @README for project overview and @package.json for available npm commands.

# Additional Instructions
- git workflow @docs/git-instructions.md
```

- Both relative and absolute paths are allowed
- Relative paths resolve relative to the file containing the import, not the working directory
- Imported files can recursively import other files, with a **maximum depth of five hops**
- First-time imports require user approval dialog

### CLAUDE.local.md

For private per-project preferences not checked into git. Auto-added to `.gitignore`. For worktree sharing:

```markdown
# Individual Preferences
- @~/.claude/my-project-instructions.md
```

### Loading from Additional Directories

The `--add-dir` flag gives Claude access to additional directories. By default, CLAUDE.md files from these directories are NOT loaded. To load them:

```bash
CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1 claude --add-dir ../shared-config
```

### Excluding CLAUDE.md Files in Monorepos

Use `claudeMdExcludes` setting for large monorepos where ancestor CLAUDE.md files aren't relevant:

```json
{
  "claudeMdExcludes": [
    "**/monorepo/CLAUDE.md",
    "/home/user/monorepo/other-team/.claude/rules/**"
  ]
}
```

Patterns matched against absolute file paths using glob syntax. Can be configured at any settings layer. **Managed policy CLAUDE.md files cannot be excluded.**

### Size Guidelines and Performance Data

| Metric | Value |
|--------|-------|
| **Optimal size** | Under 200 lines per CLAUDE.md file |
| **Rule adherence (<200 lines)** | >92% |
| **Rule adherence (>400 lines)** | ~71% |
| **Modular approach (5x 30-line files)** | 96% adherence |
| **500-line file token cost** | ~3,800 tokens (3% of 200K context) |
| **100-line file token cost** | ~4,000 tokens (2% of context) |
| **Imperative rules** | 94% compliance |
| **Same content as descriptions** | 73% compliance |

### Writing Effective Instructions

- **Size**: Target under 200 lines per file. Split using imports or `.claude/rules/` if growing large
- **Structure**: Use markdown headers and bullets to group related instructions
- **Specificity**: Write concrete, verifiable instructions ("Use 2-space indentation" not "Format code properly")
- **Consistency**: Remove conflicting instructions across files
- **Style**: Imperative rules ("Always do X", "Never do Y") produce 94% compliance vs 73% for descriptive
- Use `/init` to generate a starting CLAUDE.md automatically

### Anti-Patterns

- Secrets/API keys in CLAUDE.md (use environment variables)
- File-type-specific rules in root CLAUDE.md (use `.claude/rules/` with path scoping)
- One-time instructions (pass directly in prompt instead)
- Complex conditional logic ("if main branch, then...")
- Emojis in headings (disrupts parsing in pre-v1.0.12)
- Monolithic files over 400 lines

### Debugging

- Run `/memory` to verify your CLAUDE.md files are being loaded
- Use the `InstructionsLoaded` hook to log exactly which instruction files are loaded, when, and why
- Check for conflicting instructions across files

### Surviving Compaction

**CLAUDE.md fully survives compaction.** After `/compact`, Claude re-reads your CLAUDE.md from disk and re-injects it fresh into the session. If an instruction disappeared after compaction, it was given only in conversation, not written to CLAUDE.md.

---

## 2. Auto Memory System

### What It Is

Auto memory lets Claude accumulate knowledge across sessions without you writing anything. Claude saves notes for itself as it works: build commands, debugging insights, architecture notes, code style preferences, and workflow habits. Claude doesn't save something every session -- it decides what's worth remembering based on whether the information would be useful in a future conversation.

### How It Differs from CLAUDE.md

| | CLAUDE.md files | Auto memory |
|---|---|---|
| **Who writes it** | You | Claude |
| **What it contains** | Instructions and rules | Learnings and patterns |
| **Scope** | Project, user, or org | Per working tree |
| **Loaded into** | Every session | Every session (first 200 lines) |
| **Use for** | Coding standards, workflows, architecture | Build commands, debugging insights, preferences |

### Storage Location

Each project gets its own memory directory at `~/.claude/projects/<project>/memory/`. The `<project>` path is derived from the git repository, so **all worktrees and subdirectories within the same repo share one auto memory directory**. Outside a git repo, the project root is used instead.

```
~/.claude/projects/<project>/memory/
  MEMORY.md          # Concise index, loaded into every session
  debugging.md       # Detailed notes on debugging patterns
  api-conventions.md # API design decisions
  ...                # Any other topic files Claude creates
```

### How It Works

- The **first 200 lines** of `MEMORY.md` are loaded at the start of every conversation
- Content **beyond line 200 is NOT loaded** at session start (silent truncation, no warnings)
- Claude keeps `MEMORY.md` concise by moving detailed notes into separate topic files
- Topic files (like `debugging.md`) are NOT loaded at startup; Claude reads them on demand
- Auto memory is **machine-local** -- not shared across machines or cloud environments

### Enable/Disable

Auto memory is **on by default**. To toggle:

- Open `/memory` in a session and use the auto memory toggle
- Set `autoMemoryEnabled` in project settings:
  ```json
  { "autoMemoryEnabled": false }
  ```
- Environment variable: `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`

### Best Practices for Auto Memory

1. **Keep MEMORY.md as an index** -- move detailed notes to topic files
2. **Organize semantically by topic**, not chronologically
3. **Update or remove memories that turn out to be wrong or outdated**
4. **Do not write duplicate memories** -- check existing memories first
5. **The 200-line limit applies only to MEMORY.md** -- CLAUDE.md files are loaded in full
6. When user asks to remember something, save it immediately
7. When user corrects something from memory, update the entry immediately

### Subagent Auto Memory

Subagents can also maintain their own auto memory. The `memory` field in subagent frontmatter enables this:

| Scope | Location | Use when |
|-------|----------|----------|
| `user` | `~/.claude/agent-memory/<name>/` | Learnings across all projects |
| `project` | `.claude/agent-memory/<name>/` | Project-specific, shareable via version control |
| `local` | `.claude/agent-memory-local/<name>/` | Project-specific, not checked in |

### Audit and Edit

Auto memory files are **plain markdown you can edit or delete at any time**. Run `/memory` to browse and open memory files from within a session. Ask Claude to "remember X" to save to auto memory, or "add this to CLAUDE.md" for instructions.

---

## 3. .claude/rules/ System

### What It Is

For larger projects, you can organize instructions into multiple files using the `.claude/rules/` directory. This keeps instructions modular and easier for teams to maintain. Rules can be scoped to specific file paths.

### Directory Structure

```
your-project/
  .claude/
    CLAUDE.md           # Main project instructions
    rules/
      code-style.md     # Code style guidelines
      testing.md         # Testing conventions
      security.md        # Security requirements
      frontend/          # Subdirectories supported
        react-patterns.md
```

All `.md` files are discovered recursively. Rules **without** `paths` frontmatter are loaded at launch with the same priority as `.claude/CLAUDE.md`.

### Path-Specific Rules

Rules can be scoped to specific files using YAML frontmatter:

```markdown
---
paths:
  - "src/api/**/*.ts"
---

# API Development Rules

- All API endpoints must include input validation
- Use the standard error response format
```

Rules **without** a `paths` field are loaded unconditionally. Path-scoped rules trigger when Claude **reads files** matching the pattern.

Glob patterns supported:

| Pattern | Matches |
|---------|---------|
| `**/*.ts` | All TypeScript files in any directory |
| `src/**/*` | All files under `src/` directory |
| `*.md` | Markdown files in the project root |
| `src/components/*.tsx` | React components in a specific directory |

Multiple patterns and brace expansion:
```markdown
---
paths:
  - "src/**/*.{ts,tsx}"
  - "lib/**/*.ts"
  - "tests/**/*.test.ts"
---
```

### User-Level Rules

Personal rules in `~/.claude/rules/` apply to every project. Loaded **before** project rules (project rules have higher priority).

### Symlinks for Cross-Project Sharing

The `.claude/rules/` directory supports symlinks:

```bash
ln -s ~/shared-claude-rules .claude/rules/shared
ln -s ~/company-standards/security.md .claude/rules/security.md
```

### When to Use Rules vs CLAUDE.md vs Skills

| Aspect | CLAUDE.md | `.claude/rules/` | Skill |
|--------|-----------|-------------------|-------|
| **Loads** | Every session | Every session, or when matching files opened | On demand |
| **Scope** | Whole project | Can be scoped to file paths | Task-specific |
| **Best for** | Core conventions and build commands | Language-specific or directory-specific guidelines | Reference material, repeatable workflows |

---

## 4. Skills System

### What It Is

Skills extend what Claude can do. A `SKILL.md` file with instructions becomes part of Claude's toolkit. Claude uses skills when relevant, or you can invoke one directly with `/skill-name`. Skills follow the [Agent Skills](https://agentskills.io) open standard.

### Directory Structure

```
my-skill/
  SKILL.md           # Main instructions (required)
  template.md        # Template for Claude to fill in
  examples/
    sample.md        # Example output
  scripts/
    validate.sh      # Script Claude can execute
```

### Where Skills Live

| Location | Path | Applies to | Priority |
|----------|------|-----------|----------|
| Enterprise | Managed settings | All users in org | Highest |
| Personal | `~/.claude/skills/<skill-name>/SKILL.md` | All your projects | High |
| Project | `.claude/skills/<skill-name>/SKILL.md` | This project only | Medium |
| Plugin | `<plugin>/skills/<skill-name>/SKILL.md` | Where plugin enabled | Lowest |

When skills share the same name, higher-priority locations win.

### SKILL.md Frontmatter Reference

```yaml
---
name: my-skill
description: What this skill does
argument-hint: "[issue-number]"
disable-model-invocation: true
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
context: fork
agent: Explore
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate.sh"
---

Your skill instructions here...
```

| Field | Required | Description |
|-------|----------|-------------|
| `name` | No | Display name (defaults to directory name). Lowercase, numbers, hyphens, max 64 chars |
| `description` | Recommended | What it does. Claude uses this for auto-loading decisions |
| `argument-hint` | No | Hint shown during autocomplete (e.g., `[issue-number]`) |
| `disable-model-invocation` | No | `true` = only user can invoke. Default: `false` |
| `user-invocable` | No | `false` = hidden from `/` menu. Default: `true` |
| `allowed-tools` | No | Tools Claude can use without asking permission when skill is active |
| `model` | No | Model to use when skill is active |
| `context` | No | `fork` to run in a forked subagent context |
| `agent` | No | Which subagent type to use when `context: fork` is set |
| `hooks` | No | Hooks scoped to this skill's lifecycle |

### Invocation Control Matrix

| Frontmatter | You can invoke | Claude can invoke | When loaded into context |
|-------------|---------------|-------------------|-------------------------|
| (default) | Yes | Yes | Description always in context, full skill loads when invoked |
| `disable-model-invocation: true` | Yes | No | Description not in context, full skill loads when you invoke |
| `user-invocable: false` | No | Yes | Description always in context, full skill loads when invoked |

### String Substitutions

| Variable | Description |
|----------|-------------|
| `$ARGUMENTS` | All arguments passed when invoking |
| `$ARGUMENTS[N]` / `$N` | Specific argument by 0-based index |
| `${CLAUDE_SESSION_ID}` | Current session ID |
| `${CLAUDE_SKILL_DIR}` | Directory containing the skill's SKILL.md file |

### Dynamic Context Injection

The `` !`command` `` syntax runs shell commands before skill content is sent to Claude:

```yaml
---
name: pr-summary
context: fork
agent: Explore
---

## Pull request context
- PR diff: !`gh pr diff`
- PR comments: !`gh pr view --comments`
```

### Running Skills in Subagents

Add `context: fork` to frontmatter to run in isolation. The skill content becomes the subagent's prompt. The `agent` field specifies which subagent: `Explore`, `Plan`, `general-purpose`, or any custom agent from `.claude/agents/`.

### Bundled Skills

Ships with Claude Code:
- **`/simplify`**: Reviews recently changed files for code reuse, quality, efficiency. Spawns 3 parallel review agents
- **`/batch <instruction>`**: Large-scale changes across codebase in parallel. Decomposes into 5-30 units, each in isolated git worktree
- **`/debug [description]`**: Troubleshoots session by reading debug log
- **`/claude-api`**: Loads Claude API reference for your project's language

### Skill Description Budget

Descriptions are loaded into context. Budget scales dynamically at 2% of context window, fallback 16,000 characters. Override with `SLASH_COMMAND_TOOL_CHAR_BUDGET` environment variable. Run `/context` to check for warnings about excluded skills.

### Best Practices

- Keep SKILL.md under 500 lines; move reference material to separate files
- Use `disable-model-invocation: true` for skills with side effects
- Include "ultrathink" in skill content to enable extended thinking
- Reference supporting files from SKILL.md so Claude knows when to load them
- Test with both auto-invocation and direct `/skill-name` invocation

---

## 5. Plugins System

### What It Is

Plugins package skills, agents, hooks, MCP servers, and settings into a single installable unit. Plugin skills are namespaced (like `/my-plugin:review`) to prevent conflicts.

### Plugin Directory Structure

```
plugin-name/
  .claude-plugin/
    plugin.json          # Required: Plugin manifest
  commands/              # Slash commands (.md files)
  agents/                # Subagent definitions (.md files)
  skills/                # Agent skills (subdirectories with SKILL.md)
  hooks/
    hooks.json           # Event handler configuration
  .mcp.json              # MCP server definitions
  .lsp.json              # LSP server configurations
  settings.json          # Default settings when plugin is enabled
  scripts/               # Helper scripts and utilities
```

**CRITICAL**: Don't put `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`. Only `plugin.json` goes there.

### Plugin Manifest (plugin.json)

```json
{
  "name": "my-plugin",
  "description": "A greeting plugin to learn the basics",
  "version": "1.0.0",
  "author": {
    "name": "Your Name"
  }
}
```

Additional fields: `homepage`, `repository`, `license`.

### Installation Methods

```bash
# From marketplace
claude plugin install <plugin-name>

# Local development/testing
claude --plugin-dir ./my-plugin

# Multiple plugins
claude --plugin-dir ./plugin-one --plugin-dir ./plugin-two
```

Install scopes: user (default), project (shared with team), or local (gitignored).

### Plugin Hooks (hooks/hooks.json)

Use `${CLAUDE_PLUGIN_ROOT}` in hook commands for portability:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          { "type": "command", "command": "jq -r '.tool_input.file_path' | xargs npm run lint:fix" }
        ]
      }
    ]
  }
}
```

### Plugin Settings (settings.json)

Currently only the `agent` key is supported -- activates a plugin's custom agent as the main thread:

```json
{
  "agent": "security-reviewer"
}
```

### Plugin vs Standalone

| Approach | Skill names | Best for |
|----------|-------------|----------|
| Standalone (`.claude/`) | `/hello` | Personal workflows, quick experiments |
| Plugins | `/plugin-name:hello` | Sharing with team, distribution, versioned releases |

### Marketplace Submission

Submit at [claude.ai/settings/plugins/submit](https://claude.ai/settings/plugins/submit) or [platform.claude.com/plugins/submit](https://platform.claude.com/plugins/submit).

---

## 6. Custom Agents (.claude/agents/)

### What It Is

Subagents are specialized AI assistants that handle specific types of tasks. Each runs in its own context window with a custom system prompt, specific tool access, and independent permissions.

### Built-in Subagents

| Agent | Model | Tools | Purpose |
|-------|-------|-------|---------|
| **Explore** | Haiku (fast) | Read-only | File discovery, code search, codebase exploration |
| **Plan** | Inherits | Read-only | Research for planning in plan mode |
| **general-purpose** | Inherits | All | Complex research, multi-step operations, code modifications |
| **Bash** | Inherits | - | Running terminal commands in separate context |
| **Claude Code Guide** | Haiku | - | Answering questions about Claude Code features |

### Agent File Location & Priority

| Location | Scope | Priority |
|----------|-------|----------|
| `--agents` CLI flag | Current session | 1 (highest) |
| `.claude/agents/` | Current project | 2 |
| `~/.claude/agents/` | All your projects | 3 |
| Plugin's `agents/` | Where plugin enabled | 4 (lowest) |

### Agent File Format

```markdown
---
name: code-reviewer
description: Reviews code for quality and best practices. Use proactively after code changes.
tools: Read, Glob, Grep, Bash
disallowedTools: Write, Edit
model: sonnet
permissionMode: default
maxTurns: 20
skills:
  - api-conventions
  - error-handling-patterns
memory: user
background: false
isolation: worktree
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-command.sh"
---

You are a code reviewer. When invoked, analyze the code and provide
specific, actionable feedback on quality, security, and best practices.
```

### Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Unique identifier using lowercase letters and hyphens |
| `description` | Yes | When Claude should delegate to this subagent |
| `tools` | No | Tools the subagent can use. Inherits all if omitted |
| `disallowedTools` | No | Tools to deny |
| `model` | No | `sonnet`, `opus`, `haiku`, or `inherit` (default) |
| `permissionMode` | No | `default`, `acceptEdits`, `dontAsk`, `bypassPermissions`, `plan` |
| `maxTurns` | No | Maximum agentic turns |
| `skills` | No | Skills to preload at startup (full content injected) |
| `mcpServers` | No | MCP servers available to this subagent |
| `hooks` | No | Lifecycle hooks scoped to this subagent |
| `memory` | No | Persistent memory scope: `user`, `project`, `local` |
| `background` | No | `true` to always run as background task |
| `isolation` | No | `worktree` to run in temporary git worktree |

### Permission Modes

| Mode | Behavior |
|------|----------|
| `default` | Standard permission checking with prompts |
| `acceptEdits` | Auto-accept file edits |
| `dontAsk` | Auto-deny permission prompts |
| `bypassPermissions` | Skip all permission checks |
| `plan` | Read-only exploration |

### CLI-Defined Agents

For quick testing or automation:

```bash
claude --agents '{
  "code-reviewer": {
    "description": "Expert code reviewer",
    "prompt": "You are a senior code reviewer...",
    "tools": ["Read", "Grep", "Glob", "Bash"],
    "model": "sonnet"
  }
}'
```

### Persistent Memory for Subagents

When `memory` is enabled:
- System prompt includes instructions for reading/writing to the memory directory
- First 200 lines of agent's `MEMORY.md` are included
- Read, Write, and Edit tools are automatically enabled
- Memory persists across conversations

### Foreground vs Background Subagents

- **Foreground**: Blocks main conversation until complete. Permission prompts pass through
- **Background**: Runs concurrently. Pre-approves permissions before launch. Ctrl+B to background a running task
- Disable background tasks: `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1`

### Subagent Transcripts

Stored at `~/.claude/projects/{project}/{sessionId}/subagents/` as `agent-{agentId}.jsonl`. Persist independently of main conversation compaction. Cleaned up based on `cleanupPeriodDays` setting (default: 30 days).

### Auto-Compaction for Subagents

Triggers at ~95% capacity. Override with `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` (e.g., `50`).

---

## 7. Context Compaction

### How It Works

Claude Code uses a 200,000-token context window (~150,000 words). When the conversation approaches the limit (~95% capacity), Claude Code automatically:

1. Analyzes the conversation to identify key information worth preserving
2. Clears older tool outputs first
3. Summarizes previous interactions if needed
4. Replaces old messages with the summary
5. Re-reads CLAUDE.md from disk and re-injects it fresh

### What Is Preserved

- Your requests and key code snippets
- CLAUDE.md files (re-injected fresh from disk after compaction)
- Auto memory files (always available on disk)
- The summary of what happened before compaction

### What Can Be Lost

- Detailed instructions from early in the conversation
- Verbose tool outputs
- Intermediate reasoning steps
- Nuanced context that the summarizer doesn't deem critical

### Manual Compaction

```
/compact                          # Basic compaction
/compact focus on the API changes  # Directed compaction with preservation focus
/compact retain the error handling patterns  # Specify what to keep
```

**Tip**: Manual compaction at logical breakpoints (after finishing a feature or fixing a bug) produces better summaries because the context is cleaner.

### Compact Instructions in CLAUDE.md

Add a "Compact Instructions" section to CLAUDE.md:

```markdown
# Compact instructions

When you are using compact, please focus on test output and code changes
```

### PreCompact Hook

The `PreCompact` hook fires before compaction to preserve state:

**Common implementations**:
1. **Transcript backup**: Copy session JSONL to a backups directory
2. **Context recovery**: Send last 50 exchanges to a fresh Claude instance to generate a recovery brief
3. **State persistence**: Write critical in-progress information to files

**Community tools**:
- [precompact-hook](https://github.com/mvara-ai/precompact-hook) - LLM-interpreted recovery summaries
- [everything-claude-code/hooks/memory-persistence/pre-compact.sh](https://github.com/affaan-m/everything-claude-code/blob/main/hooks/memory-persistence/pre-compact.sh) - Memory persistence hooks

### Structuring Work to Survive Compaction

1. **Put persistent rules in CLAUDE.md** -- they are re-injected from disk after compaction
2. **Use beads or external tools** (task trackers) to persist state beyond the conversation
3. **Use auto memory** -- Claude can write important findings to MEMORY.md during the session
4. **Use PreCompact hooks** to save critical state before compaction
5. **Run `/compact` manually** at logical breakpoints for better summaries
6. **Name your sessions** -- easier to resume after compaction loses context
7. **Keep separate topic files** in auto memory so Claude can re-read them on demand

---

## 8. Session Management

### Session Basics

- Sessions are independent -- each new session starts with a fresh context window
- Sessions are saved locally with full message history
- Sessions are tied to directories (per project directory)
- Switching git branches changes file visibility but preserves conversation history

### Commands

| Command | Purpose |
|---------|---------|
| `claude --continue` | Continue most recent conversation in current directory |
| `claude --resume` | Open conversation picker or resume by name |
| `claude --resume auth-refactor` | Resume specific session by name |
| `claude --from-pr 123` | Resume sessions linked to a specific PR |
| `claude --fork-session` | Branch off and try different approach (with `--continue`) |
| `/resume` | Switch to different conversation from inside a session |
| `/rename auth-refactor` | Name the current session |
| `/clear` | Reset conversation context (start fresh) |
| `/compact` | Manual compaction with optional focus |
| `/rewind` | Open checkpoint menu to undo changes |
| `/context` | See what's using context space |
| `/memory` | Browse all loaded CLAUDE.md and memory files |

### Rewind (Checkpoints)

Before Claude edits any file, it snapshots the current contents. Options:
- Press **Esc twice** to open rewind menu
- Choose "conversation only", "code only", or both
- Checkpoints are local to your session, separate from git
- Only covers file changes -- not remote system actions

### Resume vs Fork

- **Resume** (`--continue`/`--resume`): Same session ID, messages appended, full history restored
- **Fork** (`--fork-session`): New session ID, preserves history up to that point, original untouched
- Neither inherits session-scoped permissions (must re-approve)

### Session Picker Shortcuts

| Shortcut | Action |
|----------|--------|
| Up/Down | Navigate between sessions |
| Right/Left | Expand/collapse grouped sessions |
| Enter | Select and resume |
| P | Preview session content |
| R | Rename session |
| / | Search/filter |
| A | Toggle current directory / all projects |
| B | Filter to current git branch |
| Esc | Exit picker |

### How Session Storage Works

1. **Conversation Storage**: All conversations automatically saved locally with full message history
2. **Message Deserialization**: Full history restored on resume
3. **Tool State**: Tool usage and results preserved
4. **Context Restoration**: Conversation resumes with all previous context intact

### Session Best Practices

- **Name sessions early** with `/rename` for distinct tasks
- **Use `/clear` between unrelated tasks** to avoid stale context waste
- Use `/rename` before clearing so you can resume later
- Use `--continue` for quick access to most recent conversation
- Use `--resume` without arguments to browse and select
- For scripts: `claude --continue --print "prompt"` for non-interactive mode

---

## 9. .claudeignore and File Exclusion

### Current Status

Claude Code does **not have an official built-in `.claudeignore` file**. The feature has been requested in multiple GitHub issues (#79, #579, #4160, #29455) but is not officially supported.

### Community Solutions

[claude-ignore](https://github.com/li-zhixin/claude-ignore) -- A Claude Code PreToolUse hook that prevents Claude from reading files matching patterns in `.claudeignore` files:
- Discovers `.claudeignore` files starting from current directory upward through parent directories
- Loads ignore patterns hierarchically (files closer to root processed first)
- Checks file paths against patterns
- Exits with code 2 to block read operations

### Official Alternative: Permission Deny Rules

The recommended approach is using `permissions.deny` in `.claude/settings.json`:

```json
{
  "permissions": {
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)",
      "Read(./build)"
    ]
  }
}
```

This is more reliable than `.claudeignore` for preventing access to sensitive files.

### Security Note

There have been reports (The Register, Jan 2026) that Claude can sometimes bypass `.claudeignore` rules and read file contents despite matching patterns. For truly sensitive files, permission deny rules in settings are more reliable.

### What Claude Already Ignores

- Files matching `.gitignore` patterns are excluded from file discovery and search results by default
- The `.git/` directory is not directly accessible
- Binary files are typically skipped during search operations

---

## 10. Git Worktree Patterns

### What Git Worktrees Solve

When working on multiple tasks at once, each Claude session needs its own copy of the codebase so changes don't collide. Git worktrees create separate working directories that share the same repository history and remote connections.

### Built-in Worktree Support

```bash
# Named worktree
claude --worktree feature-auth
# Creates .claude/worktrees/feature-auth/ with branch worktree-feature-auth

# Auto-named worktree
claude --worktree
# Generates random name like "bright-running-fox"

# Another parallel session
claude --worktree bugfix-123
```

Worktrees are created at `<repo>/.claude/worktrees/<name>` and branch from the default remote branch.

### During a Session

Ask Claude to "work in a worktree" or "start a worktree" during a session.

### Subagent Worktrees

```yaml
---
name: parallel-worker
isolation: worktree
---
```

Each subagent gets its own worktree, automatically cleaned up when the subagent finishes without changes.

### Cleanup

| Scenario | What happens |
|----------|-------------|
| No changes | Worktree and branch removed automatically |
| Changes exist | Claude prompts to keep or remove. Keeping preserves directory and branch. Removing deletes everything |

### Manual Worktree Management

```bash
# Create worktree with new branch
git worktree add ../project-feature-a -b feature-a

# Create worktree with existing branch
git worktree add ../project-bugfix bugfix-123

# Start Claude in worktree
cd ../project-feature-a && claude

# Clean up
git worktree list
git worktree remove ../project-feature-a
```

### Gitignore

Add `.claude/worktrees/` to your `.gitignore`.

### Best Practices

1. **Initialize each worktree**: Run `/init` in each new worktree session
2. **Run dependency installation** in each worktree (e.g., `npm install`, `bun install`)
3. **Name worktrees descriptively** for easier identification
4. **Use subagent worktrees** (`isolation: worktree`) for parallel work within a session
5. **For non-git VCS**: Configure `WorktreeCreate` and `WorktreeRemove` hooks

### Non-Git Version Control

Configure hooks in settings to provide custom worktree creation/cleanup for SVN, Perforce, or Mercurial:

```json
{
  "hooks": {
    "WorktreeCreate": [...],
    "WorktreeRemove": [...]
  }
}
```

---

## 11. Context Cost Management

### Context Window Overview

Claude Code uses a **200,000-token context window** (~150,000 words). Understanding what consumes this space is critical for long sessions.

### Context Cost by Feature

| Feature | When it loads | What loads | Context cost |
|---------|--------------|------------|-------------|
| **CLAUDE.md** | Session start | Full content | Every request |
| **Skills** | Session start + when used | Descriptions at start, full content when used | Low (descriptions every request) |
| **MCP servers** | Session start | All tool definitions and schemas | Every request |
| **Subagents** | When spawned | Fresh context with specified skills | Isolated from main session |
| **Hooks** | On trigger | Nothing (runs externally) | Zero (unless hook returns context) |

### Token Budget Guidelines

- 100-line CLAUDE.md: ~4,000 tokens (2% of context)
- 500-line CLAUDE.md: ~3,800 tokens (3% of context)
- Total memory files should not exceed 10,000 tokens
- Skill descriptions: 2% of context window budget (fallback 16,000 characters)
- MCP tool search threshold: 10% of context (configurable with `ENABLE_TOOL_SEARCH=auto:<N>`)

### Strategies to Reduce Token Usage

1. **Clear between tasks**: `/clear` when switching to unrelated work
2. **Custom compaction instructions**: `/compact Focus on code samples and API usage`
3. **Use the right model**: Sonnet for most tasks, Opus for complex reasoning, Haiku for simple subagents
4. **Reduce MCP overhead**: Prefer CLI tools (`gh`, `aws`), disable unused servers, lower tool search threshold
5. **Install code intelligence plugins**: Precise symbol navigation reduces file reads
6. **Offload to hooks**: Preprocess data before Claude sees it (filter test output to failures only)
7. **Move instructions to skills**: Move specialized content from CLAUDE.md to on-demand skills
8. **Delegate to subagents**: Verbose operations stay in subagent context, only summary returns
9. **Use plan mode**: Reduces total token consumption by 40-60% on complex tasks
10. **Write specific prompts**: "Add validation to auth.ts login function" > "improve this codebase"
11. **Adjust extended thinking**: Lower effort level or `MAX_THINKING_TOKENS=8000` for simpler tasks

### Monitoring Tools

- `/cost` -- Current session token usage (API users)
- `/stats` -- Usage patterns (subscribers)
- `/context` -- What's consuming context space
- `/mcp` -- Per-server MCP costs
- Status line configuration for continuous monitoring

### Average Costs

- ~$6/developer/day average
- <$12/day for 90% of users
- ~$100-200/developer/month with Sonnet 4.6
- Agent teams use ~7x more tokens than standard sessions

---

## 12. Community Tools and Resources

### Memory Management

- **[claude-mem](https://github.com/thedotmack/claude-mem)** - Plugin that captures everything Claude does during sessions, compresses with AI, and injects relevant context into future sessions
- **[precompact-hook](https://github.com/mvara-ai/precompact-hook)** - LLM-interpreted recovery summaries before context compaction
- **[everything-claude-code](https://github.com/affaan-m/everything-claude-code)** - Collection of hooks including memory-persistence pre-compact scripts

### Skills Collections

- **[alirezarezvani/claude-skills](https://github.com/alirezarezvani/claude-skills)** - Collection of skills for real-world usage including subagents and commands
- **[karanb192/awesome-claude-skills](https://github.com/karanb192/awesome-claude-skills)** - 50+ verified awesome Claude Skills
- **[glebis/claude-skills](https://github.com/glebis/claude-skills)** - Collection of Claude Code skills for enhanced workflows
- **[Agent Skills Marketplace (skillsmp.com)](https://skillsmp.com)** - Marketplace for Claude, Codex, and ChatGPT skills

### Custom Agents

- **[iannuttall/claude-agents](https://github.com/iannuttall/claude-agents)** - Custom subagents collection for Claude Code

### File Exclusion

- **[li-zhixin/claude-ignore](https://github.com/li-zhixin/claude-ignore)** - PreToolUse hook implementing .claudeignore functionality

### Learning Resources

- **[SFEIR Institute - CLAUDE.md Memory System](https://institute.sfeir.com/en/claude-code/claude-code-memory-system-claude-md/)** - Deep dive, tutorials, and FAQ
- **[SFEIR Institute - Context Management](https://institute.sfeir.com/en/claude-code/claude-code-context-management/faq/)** - FAQ on context management
- **[Steve Kinney - Session Management](https://stevekinney.com/courses/ai-development/claude-code-session-management)** - Course on session management
- **[ClaudeLog](https://claudelog.com/)** - Docs, guides, tutorials, and best practices
- **[claudefa.st](https://claudefa.st)** - Claude Code optimization guides
- **[Claude Code Plugin Directory (claudecodeplugin.com)](https://www.claudecodeplugin.com/)** - Plugin marketplace, commands, agents, hooks

### Blog Posts and Articles

- "[You (probably) don't understand Claude Code memory](https://joseparreogarcia.substack.com/p/claude-code-memory-explained)" - Deep explanation of memory system
- "[Anthropic Just Added Auto-Memory to Claude Code](https://medium.com/@joe.njenga/anthropic-just-added-auto-memory-to-claude-code-memory-md-i-tested-it-0ab8422754d2)" - MEMORY.md testing
- "[The Complete Guide to AI Agent Memory Files](https://medium.com/data-science-collective/the-complete-guide-to-ai-agent-memory-files-claude-md-agents-md-and-beyond-49ea0df5c5a9)" - Cross-platform memory file guide
- "[Claude Code Compaction](https://stevekinney.com/courses/ai-development/claude-code-compaction)" - Steve Kinney's compaction guide
- "[How Claude Code Got Better by Protecting More Context](https://hyperdev.matsuoka.com/p/how-claude-code-got-better-by-protecting)" - Context protection improvements

---

## 13. Best Practices Summary

### CLAUDE.md Best Practices

1. Keep under 200 lines per file (92%+ adherence)
2. Use imperative rules ("Always do X", "Never do Y")
3. Split into `.claude/rules/` files for modularity (96% adherence with 5x 30-line files)
4. Use path-scoping for language/directory-specific rules
5. Use `@path/to/import` for reference material
6. Don't put volatile info in CLAUDE.md -- it belongs in conversation prompts
7. Review periodically for conflicting or outdated instructions
8. Use `CLAUDE.local.md` for personal project preferences
9. Run `/init` to bootstrap, then refine

### Auto Memory Best Practices

1. Treat MEMORY.md as an index -- move details to topic files
2. Stay under 200 lines in MEMORY.md (silent truncation beyond)
3. Organize by topic, not chronologically
4. Update incorrect entries immediately when corrections happen
5. Don't duplicate what's in CLAUDE.md
6. Verify against project docs before writing speculative conclusions
7. Use `user` scope for subagent memory as default

### Context Management Best Practices

1. Use `/clear` between unrelated tasks
2. Use `/compact` with focus instructions at logical breakpoints
3. Delegate verbose operations to subagents
4. Move specialized CLAUDE.md content to on-demand skills
5. Use `disable-model-invocation: true` for user-only skills (zero context cost)
6. Prefer CLI tools over MCP servers when available
7. Install code intelligence plugins for typed languages
8. Write specific prompts to minimize unnecessary exploration
9. Use plan mode for complex tasks (40-60% token savings)
10. Monitor with `/context`, `/cost`, `/mcp`

### Session Management Best Practices

1. Name sessions with `/rename` early for easy resumption
2. Use `--continue` for quick access to most recent session
3. Use `--fork-session` to try alternative approaches
4. Use `/rewind` (Esc twice) to undo changes safely
5. Choose "code only" rewind to preserve conversation but undo file changes
6. Use git worktrees for parallel sessions
7. Add `.claude/worktrees/` to `.gitignore`
8. Use PreCompact hooks to preserve critical state before compaction

### Skills Best Practices

1. Keep SKILL.md under 500 lines; use supporting files for detail
2. Write clear descriptions for accurate auto-invocation
3. Use `context: fork` for isolation-requiring skills
4. Use `allowed-tools` to restrict access appropriately
5. Use `$ARGUMENTS` for dynamic skill content
6. Use `` !`command` `` for dynamic context injection
7. Test both auto-invocation and manual `/skill-name` invocation

### Subagent Best Practices

1. Design focused subagents -- one specific task each
2. Write detailed descriptions for accurate delegation
3. Limit tool access to only what's necessary
4. Check project subagents into version control
5. Use `memory: user` for cross-project learning
6. Use `isolation: worktree` for parallel work
7. Resume subagents when continuing previous work (preserves full history)
8. Use `model: haiku` for simple tasks to save costs

---

## Quick Reference Card

### Memory Hierarchy (What Loads When)

```
Session Start:
  1. Managed policy CLAUDE.md (cannot be excluded)
  2. User CLAUDE.md (~/.claude/CLAUDE.md)
  3. Project CLAUDE.md (./CLAUDE.md or ./.claude/CLAUDE.md)
  4. CLAUDE.local.md (./CLAUDE.local.md)
  5. .claude/rules/*.md (without paths: frontmatter)
  6. Auto memory MEMORY.md (first 200 lines)
  7. Skill descriptions (2% context budget)
  8. MCP tool definitions

On Demand:
  - Subdirectory CLAUDE.md files (when accessing those files)
  - Path-scoped .claude/rules/ files (when matching files opened)
  - Full skill content (when invoked or auto-triggered)
  - Auto memory topic files (when Claude needs them)

After Compaction:
  - CLAUDE.md re-injected fresh from disk
  - Auto memory still available on disk
  - Conversation history summarized
```

### Key Commands

```
/memory     - Browse all loaded instruction files
/context    - See what's using context space
/cost       - Current session token usage
/compact    - Manual compaction (with optional focus)
/clear      - Reset conversation context
/resume     - Session picker
/rename     - Name current session
/rewind     - Checkpoint menu (or Esc twice)
/init       - Generate starter CLAUDE.md
/agents     - Manage subagents
/mcp        - Check MCP server costs
```

### Key Environment Variables

```
CLAUDE_CODE_DISABLE_AUTO_MEMORY=1
CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=50
SLASH_COMMAND_TOOL_CHAR_BUDGET=32000
ENABLE_TOOL_SEARCH=auto:5
MAX_THINKING_TOKENS=8000
CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1
CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1
CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING=1
CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```
