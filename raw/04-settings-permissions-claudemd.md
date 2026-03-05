# R4: Claude Code Settings, Permissions, and CLAUDE.md -- Complete Reference

> Deep dive into Claude Code configuration: settings.json schema, permission system, CLAUDE.md patterns, skills, plugins, subagents, sandboxing, and hooks.
> Sources: Official docs (code.claude.com), HumanLayer blog, Builder.io blog, Trail of Bits config, feiskyer/claude-code-settings

---

## Table of Contents

1. [Settings Files -- Location, Scope, Precedence](#1-settings-files)
2. [Complete settings.json Schema](#2-complete-settingsjson-schema)
3. [Permission System](#3-permission-system)
4. [CLAUDE.md -- Memory and Instructions](#4-claudemd)
5. [.claude/rules/ -- Path-Scoped Rules](#5-claude-rules)
6. [Auto Memory](#6-auto-memory)
7. [Skills System](#7-skills-system)
8. [Custom Subagents](#8-custom-subagents)
9. [Plugins System](#9-plugins-system)
10. [Hooks System](#10-hooks-system)
11. [Sandboxing](#11-sandboxing)
12. [Environment Variables -- Complete List](#12-environment-variables)
13. [.claude/ Directory Structure](#13-claude-directory-structure)
14. [.claudeignore](#14-claudeignore)
15. [CLAUDE.md Best Practices -- From Real-World Experience](#15-claudemd-best-practices)
16. [Real-World Configuration Examples](#16-real-world-examples)

---

## 1. Settings Files

### Locations and Scope

| Scope | Location | Shared? | Purpose |
|-------|----------|---------|---------|
| **Managed policy** | Server, plist, registry, or `/managed-settings.json` | Yes (IT-deployed) | Organization-wide enforcement |
| **User** | `~/.claude/settings.json` | No | Personal preferences, all projects |
| **Project (shared)** | `.claude/settings.json` | Yes (git-committed) | Team-shared project config |
| **Project (local)** | `.claude/settings.local.json` | No (gitignored) | Personal project overrides |

### Precedence (Highest to Lowest)

1. **Managed settings** -- cannot be overridden by anything, including CLI args
2. **Command line arguments** -- temporary session overrides
3. **Local project settings** (`.claude/settings.local.json`)
4. **Shared project settings** (`.claude/settings.json`)
5. **User settings** (`~/.claude/settings.json`)

**Key rule**: If a tool is denied at any level, no other level can allow it. Deny always wins.

### Array Merge Behavior

Array-valued settings **merge across scopes** (not replaced):
- `permissions.allow`, `permissions.deny`, `permissions.ask`
- `sandbox.filesystem.allowWrite`, `sandbox.filesystem.denyWrite`, `sandbox.filesystem.denyRead`
- `sandbox.network.allowedDomains`, `sandbox.network.allowUnixSockets`
- `allowedMcpServers`, `deniedMcpServers`
- `allowedHttpHookUrls`, `httpHookAllowedEnvVars`
- `claudeMdExcludes`

### Managed Settings File Locations

- **macOS**: `/Library/Application Support/ClaudeCode/managed-settings.json`
- **Linux/WSL**: `/etc/claude-code/managed-settings.json`
- **Windows**: `C:\Program Files\ClaudeCode\managed-settings.json`

---

## 2. Complete settings.json Schema

### JSON Schema Validation

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json"
}
```

Adding this enables autocomplete and inline validation in VS Code, Cursor, and other JSON-schema-aware editors.

### Core Settings

| Key | Type | Description | Example |
|-----|------|-------------|---------|
| `$schema` | string | JSON schema URL for IDE validation | `"https://json.schemastore.org/claude-code-settings.json"` |
| `model` | string | Override default model | `"claude-sonnet-4-6"` |
| `availableModels` | array | Restrict selectable models | `["sonnet", "haiku"]` |
| `language` | string | Preferred response language | `"japanese"` |
| `outputStyle` | string | Adjust system prompt style | `"Explanatory"` |

### Authentication and API

| Key | Type | Description | Example |
|-----|------|-------------|---------|
| `apiKeyHelper` | string | Shell script to generate auth token | `"/bin/generate_temp_api_key.sh"` |
| `otelHeadersHelper` | string | Script for dynamic OpenTelemetry headers | `"/bin/generate_otel_headers.sh"` |
| `forceLoginMethod` | string | `"claudeai"` or `"console"` | `"claudeai"` |
| `forceLoginOrgUUID` | string | Auto-select organization UUID | `"xxxxxxxx-xxxx-xxxx-..."` |

### Permissions Block

```json
{
  "permissions": {
    "allow": [
      "Bash(npm run lint)",
      "Bash(npm run test *)",
      "Read(~/.zshrc)"
    ],
    "deny": [
      "Bash(curl *)",
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)"
    ],
    "ask": [
      "Bash(git push *)"
    ],
    "additionalDirectories": ["../docs/"],
    "defaultMode": "acceptEdits"
  }
}
```

**Permission fields:**
- `allow` (array) -- Rules to allow tool use without prompting
- `deny` (array) -- Rules to deny (evaluated first, always wins)
- `ask` (array) -- Rules requiring user confirmation
- `additionalDirectories` (array) -- Additional working directories
- `defaultMode` (string) -- Default permission mode

### Sandbox Configuration

```json
{
  "sandbox": {
    "enabled": true,
    "autoAllowBashIfSandboxed": true,
    "excludedCommands": ["git", "docker"],
    "allowUnsandboxedCommands": false,
    "filesystem": {
      "allowWrite": ["//tmp/build", "~/.kube"],
      "denyWrite": ["//etc", "//usr/local/bin"],
      "denyRead": ["~/.aws/credentials"]
    },
    "network": {
      "allowedDomains": ["github.com", "*.npmjs.org"],
      "allowManagedDomainsOnly": false,
      "allowUnixSockets": ["~/.ssh/agent-socket"],
      "allowAllUnixSockets": false,
      "allowLocalBinding": false,
      "httpProxyPort": 8080,
      "socksProxyPort": 8081
    },
    "enableWeakerNestedSandbox": false,
    "enableWeakerNetworkIsolation": false
  }
}
```

**Sandbox path prefixes:**
- `//` -- Absolute path from filesystem root (`//tmp/build` = `/tmp/build`)
- `~/` -- Home directory (`~/.kube` = `$HOME/.kube`)
- `/` -- Relative to the settings file's directory
- `./` or none -- Relative path

### Git and Attribution

```json
{
  "attribution": {
    "commit": "Generated with Claude Code\n\nCo-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>",
    "pr": "Generated with Claude Code"
  },
  "includeCoAuthoredBy": false,
  "includeGitInstructions": true
}
```

- `attribution.commit` (string) -- Commit message attribution
- `attribution.pr` (string) -- Pull request attribution
- `includeCoAuthoredBy` (boolean) -- **Deprecated** -- use `attribution` instead
- `includeGitInstructions` (boolean) -- Include built-in git instructions in system prompt

### Hooks Configuration

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/block-rm.sh"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "compact",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Context re-injected after compaction'"
          }
        ]
      }
    ]
  },
  "disableAllHooks": false,
  "allowManagedHooksOnly": false,
  "allowedHttpHookUrls": ["https://hooks.example.com/*"],
  "httpHookAllowedEnvVars": ["MY_TOKEN", "HOOK_SECRET"]
}
```

### MCP Servers

```json
{
  "enableAllProjectMcpServers": true,
  "enabledMcpjsonServers": ["memory", "github"],
  "disabledMcpjsonServers": ["filesystem"],
  "allowedMcpServers": [
    { "serverName": "github" }
  ],
  "deniedMcpServers": [
    { "serverName": "filesystem" }
  ],
  "allowManagedMcpServersOnly": false
}
```

### Plugins

```json
{
  "enabledPlugins": {
    "formatter@acme-tools": true,
    "deployer@acme-tools": true,
    "analyzer@security-plugins": false
  },
  "extraKnownMarketplaces": {
    "acme-tools": {
      "source": {
        "source": "github",
        "repo": "acme-corp/claude-plugins"
      }
    }
  },
  "strictKnownMarketplaces": [
    { "source": "github", "repo": "acme-corp/approved-plugins" }
  ],
  "blockedMarketplaces": [
    { "source": "github", "repo": "untrusted/plugins" }
  ],
  "pluginTrustMessage": "All plugins from our marketplace are approved by IT"
}
```

**Marketplace source types:**
1. **GitHub**: `{ "source": "github", "repo": "owner/repo", "ref": "branch", "path": "subdir" }`
2. **Git**: `{ "source": "git", "url": "https://...", "ref": "branch", "path": "subdir" }`
3. **URL**: `{ "source": "url", "url": "https://...", "headers": {...} }`
4. **NPM**: `{ "source": "npm", "package": "@org/name" }`
5. **File**: `{ "source": "file", "path": "/absolute/path" }`
6. **Directory**: `{ "source": "directory", "path": "/absolute/path" }`
7. **Host Pattern**: `{ "source": "hostPattern", "hostPattern": "^github\\.example\\.com$" }`

### Environment Variables

```json
{
  "env": {
    "CLAUDE_CODE_ENABLE_TELEMETRY": "1",
    "OTEL_METRICS_EXPORTER": "otlp",
    "FOO": "bar"
  }
}
```

### UI and Behavior

| Key | Type | Description | Example |
|-----|------|-------------|---------|
| `showTurnDuration` | boolean | Show turn duration after responses | `true` |
| `spinnerVerbs` | object | Custom spinner action verbs | `{"mode": "append", "verbs": ["Pondering"]}` |
| `spinnerTipsEnabled` | boolean | Show tips in spinner | `true` |
| `spinnerTipsOverride` | object | Custom spinner tips | `{"excludeDefault": true, "tips": [...]}` |
| `terminalProgressBarEnabled` | boolean | Show terminal progress bar | `true` |
| `prefersReducedMotion` | boolean | Reduce UI animations | `false` |

### Extended Thinking and Performance

| Key | Type | Description | Example |
|-----|------|-------------|---------|
| `alwaysThinkingEnabled` | boolean | Enable extended thinking by default | `true` |
| `fastModePerSessionOptIn` | boolean | Require opt-in per session | `true` |

### Team Features

```json
{
  "teammateMode": "in-process"
}
```

**Values:** `"auto"`, `"in-process"`, `"tmux"`

### Session and Storage

| Key | Type | Description | Example |
|-----|------|-------------|---------|
| `cleanupPeriodDays` | number | Delete inactive sessions after N days | `20` |
| `plansDirectory` | string | Custom plan storage directory | `"./plans"` |
| `autoUpdatesChannel` | string | `"stable"` or `"latest"` | `"stable"` |

### File Management

```json
{
  "respectGitignore": false,
  "fileSuggestion": {
    "type": "command",
    "command": "~/.claude/file-suggestion.sh"
  }
}
```

### Organization Announcements

```json
{
  "companyAnnouncements": [
    "Welcome to Acme Corp! Review our code guidelines at docs.acme.com",
    "Reminder: Code reviews required for all PRs"
  ]
}
```

### AWS Bedrock

| Key | Type | Description |
|-----|------|-------------|
| `awsAuthRefresh` | string | Script to refresh AWS credentials |
| `awsCredentialExport` | string | Script outputting JSON AWS credentials |

### Status Line

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

### CLAUDE.md Exclusions

```json
{
  "claudeMdExcludes": [
    "**/monorepo/CLAUDE.md",
    "/home/user/monorepo/other-team/.claude/rules/**"
  ]
}
```

### Auto Memory Toggle

```json
{
  "autoMemoryEnabled": false
}
```

### Managed-Only Settings

These settings are **only effective in managed settings** (cannot be set by users/projects):

| Setting | Description |
|---------|-------------|
| `disableBypassPermissionsMode` | Set to `"disable"` to prevent `bypassPermissions` mode |
| `allowManagedPermissionRulesOnly` | When `true`, prevents user/project permission rules |
| `allowManagedHooksOnly` | When `true`, prevents user/project/plugin hooks |
| `allowManagedMcpServersOnly` | When `true`, only managed MCP server allowlist applies |
| `blockedMarketplaces` | Blocklist of marketplace sources |
| `sandbox.network.allowManagedDomainsOnly` | When `true`, only managed domain allowlist applies |
| `strictKnownMarketplaces` | Controls which plugin marketplaces users can add |
| `allow_remote_sessions` | When `false`, prevents remote/web sessions |

---

## 3. Permission System

### Permission Modes

| Mode | Description |
|------|-------------|
| `default` | Standard: prompts for permission on first use of each tool |
| `acceptEdits` | Automatically accepts file edit permissions for the session |
| `plan` | Plan Mode: Claude can analyze but not modify files or execute commands |
| `dontAsk` | Auto-denies tools unless pre-approved via `/permissions` or `permissions.allow` |
| `bypassPermissions` | Skips all permission prompts (only for isolated environments) |

**Warning**: `bypassPermissions` disables ALL permission checks. Only use in containers or VMs. Admins can prevent it with `disableBypassPermissionsMode: "disable"`.

### Tool Permission Tiers

| Tool type | Example | Approval required | "Yes, don't ask again" behavior |
|-----------|---------|-------------------|-------------------------------|
| Read-only | File reads, Grep | No | N/A |
| Bash commands | Shell execution | Yes | Permanently per project+command |
| File modification | Edit/write files | Yes | Until session end |

### Rule Evaluation Order

**deny -> ask -> allow** -- first matching rule wins.

### Permission Rule Syntax

#### Match All Uses

| Rule | Effect |
|------|--------|
| `Bash` | Matches all Bash commands |
| `WebFetch` | Matches all web fetch requests |
| `Read` | Matches all file reads |

`Bash(*)` is equivalent to `Bash`.

#### Specifiers for Fine-Grained Control

| Rule | Effect |
|------|--------|
| `Bash(npm run build)` | Matches exact command |
| `Read(./.env)` | Matches reading .env in cwd |
| `WebFetch(domain:example.com)` | Matches fetch to example.com |

#### Wildcard Patterns

```json
{
  "permissions": {
    "allow": [
      "Bash(npm run *)",
      "Bash(git commit *)",
      "Bash(git * main)",
      "Bash(* --version)",
      "Bash(* --help *)"
    ],
    "deny": [
      "Bash(git push *)"
    ]
  }
}
```

**Space before `*` matters**: `Bash(ls *)` matches `ls -la` but NOT `lsof`. `Bash(ls*)` matches both.

**Shell operator awareness**: Claude Code knows about `&&`, so `Bash(safe-cmd *)` won't permit `safe-cmd && other-cmd`.

### Tool-Specific Rules

#### Bash

- `Bash(npm run build)` -- exact match
- `Bash(npm run test *)` -- prefix match with word boundary
- `Bash(npm *)` -- any npm command
- `Bash(* install)` -- any command ending with install
- `Bash(git * main)` -- pattern in middle

#### Read and Edit

Follow **gitignore specification** with four path pattern types:

| Pattern | Meaning | Example | Matches |
|---------|---------|---------|---------|
| `//path` | Absolute path from filesystem root | `Read(//Users/alice/secrets/**)` | `/Users/alice/secrets/**` |
| `~/path` | Home directory | `Read(~/Documents/*.pdf)` | `$HOME/Documents/*.pdf` |
| `/path` | Relative to project root | `Edit(/src/**/*.ts)` | `<project>/src/**/*.ts` |
| `path` or `./path` | Relative to current directory | `Read(*.env)` | `<cwd>/*.env` |

**Warning**: `/Users/alice/file` is NOT an absolute path -- it's relative to project root. Use `//Users/alice/file` for absolute.

**Glob behavior**: `*` matches files in a single directory; `**` matches recursively.

#### WebFetch

- `WebFetch(domain:example.com)` -- domain-based filtering

#### MCP Tools

- `mcp__puppeteer` -- all tools from puppeteer server
- `mcp__puppeteer__*` -- wildcard matching all tools
- `mcp__puppeteer__puppeteer_navigate` -- specific tool

#### Agent (Subagents)

- `Agent(Explore)` -- matches Explore subagent
- `Agent(Plan)` -- matches Plan subagent
- `Agent(my-custom-agent)` -- matches custom subagent

#### Skill

- `Skill(commit)` -- exact skill match
- `Skill(review-pr *)` -- prefix match with arguments

### Additional Working Directories

- **CLI**: `--add-dir <path>`
- **Session**: `/add-dir` command
- **Settings**: `additionalDirectories` array

---

## 4. CLAUDE.md

### What is CLAUDE.md?

CLAUDE.md files are markdown files that give Claude persistent instructions. Claude reads them at the start of every session. They are context, not enforced configuration -- how you write instructions affects how reliably Claude follows them.

### Where to Put CLAUDE.md Files

| Scope | Location | Purpose | Shared with |
|-------|----------|---------|-------------|
| **Managed policy** | macOS: `/Library/Application Support/ClaudeCode/CLAUDE.md`, Linux: `/etc/claude-code/CLAUDE.md`, Windows: `C:\Program Files\ClaudeCode\CLAUDE.md` | Organization-wide | All users |
| **Project** | `./CLAUDE.md` or `./.claude/CLAUDE.md` | Team-shared | Team via source control |
| **User** | `~/.claude/CLAUDE.md` | Personal, all projects | Just you |
| **Local** | `./CLAUDE.local.md` | Personal project-specific (not committed) | Just you |

### How CLAUDE.md Files Load

1. Claude walks **up** the directory tree from cwd, checking each directory for `CLAUDE.md` and `CLAUDE.local.md`
2. Files **above** the working directory are loaded **in full** at launch
3. Files in **subdirectories** load **on demand** when Claude reads files in those directories
4. CLAUDE.md from `--add-dir` directories are **NOT loaded** by default (set `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` to enable)

### CLAUDE.md vs Auto Memory

| | CLAUDE.md | Auto Memory |
|---|-----------|-------------|
| **Who writes it** | You | Claude |
| **What it contains** | Instructions and rules | Learnings and patterns |
| **Scope** | Project, user, or org | Per working tree |
| **Loaded into** | Every session | Every session (first 200 lines) |
| **Use for** | Coding standards, workflows, architecture | Build commands, debugging insights, preferences |

### @imports System

Reference external files using `@path/to/import` syntax:

```markdown
See @README for project overview and @package.json for available npm commands.

# Additional Instructions
- git workflow @docs/git-instructions.md
```

- Both relative and absolute paths allowed
- Relative paths resolve relative to the file containing the import
- Recursive imports supported (max depth: 5 hops)
- First time external imports appear, Claude shows an approval dialog

### Key Writing Rules

- **Target under 200 lines** per CLAUDE.md file
- Use **markdown headers and bullets** to group related instructions
- Write instructions that are **concrete enough to verify** ("Use 2-space indentation" not "format code properly")
- Remove **conflicting instructions** across files (Claude picks one arbitrarily)
- CLAUDE.md **fully survives compaction** -- instructions persist across `/compact`

### /init Command

Run `/init` to generate a starting CLAUDE.md automatically. If one exists, `/init` suggests improvements.

### /memory Command

Lists all CLAUDE.md and rules files loaded in current session. Lets you toggle auto memory and open memory files in your editor.

---

## 5. .claude/rules/

### Purpose

For larger projects, organize instructions into multiple files using `.claude/rules/` directory. Rules are modular and easier for teams to maintain.

### Setup

```
your-project/
  .claude/
    CLAUDE.md           # Main project instructions
    rules/
      code-style.md     # Code style guidelines
      testing.md        # Testing conventions
      security.md       # Security requirements
      frontend/         # Subdirectory for frontend rules
        react.md
      backend/
        api-design.md
```

Rules without `paths` frontmatter are loaded at launch (same priority as `.claude/CLAUDE.md`).

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

Path-scoped rules **trigger when Claude reads** files matching the pattern, not on every tool use.

**Glob pattern examples:**

| Pattern | Matches |
|---------|---------|
| `**/*.ts` | All TypeScript files in any directory |
| `src/**/*` | All files under `src/` |
| `*.md` | Markdown files in project root only |
| `src/components/*.tsx` | React components in specific directory |
| `src/**/*.{ts,tsx}` | Brace expansion for multiple extensions |

### User-Level Rules

`~/.claude/rules/` applies to every project. Loaded before project rules (project rules have higher priority).

### Symlinks

`.claude/rules/` supports symlinks for sharing rules across projects:

```bash
ln -s ~/shared-claude-rules .claude/rules/shared
ln -s ~/company-standards/security.md .claude/rules/security.md
```

---

## 6. Auto Memory

### What It Is

Auto memory lets Claude accumulate knowledge across sessions without manual effort. Claude saves notes about build commands, debugging insights, architecture, code style, and workflow preferences.

### Storage Location

`~/.claude/projects/<project>/memory/` -- derived from the git repository, so all worktrees share one directory.

```
~/.claude/projects/<project>/memory/
  MEMORY.md          # Concise index, loaded into every session (first 200 lines)
  debugging.md       # Detailed notes on debugging patterns
  api-conventions.md # API design decisions
  ...
```

### How It Works

- First 200 lines of `MEMORY.md` loaded at every session start
- Content beyond line 200 is NOT loaded
- Topic files (debugging.md, etc.) are NOT loaded at startup -- read on demand
- Machine-local; not shared across machines
- All worktrees within the same git repo share one auto memory directory

### Toggle

- In session: `/memory` command
- Settings: `"autoMemoryEnabled": false`
- Environment: `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`

---

## 7. Skills System

### What Are Skills?

Skills extend what Claude can do. Create a `SKILL.md` file with instructions, and Claude adds it to its toolkit. Skills can be invoked directly with `/skill-name` or loaded automatically when relevant.

**Skills follow the [Agent Skills](https://agentskills.io) open standard.**

### Where Skills Live

| Location | Path | Applies to |
|----------|------|------------|
| Enterprise | See managed settings | All users |
| Personal | `~/.claude/skills/<skill-name>/SKILL.md` | All your projects |
| Project | `.claude/skills/<skill-name>/SKILL.md` | This project only |
| Plugin | `<plugin>/skills/<skill-name>/SKILL.md` | Where plugin is enabled |

**Priority**: enterprise > personal > project. Plugin skills use `plugin-name:skill-name` namespace.

### Skill Directory Structure

```
my-skill/
  SKILL.md           # Main instructions (required)
  template.md        # Template for Claude to fill in
  examples/
    sample.md        # Example output
  scripts/
    validate.sh      # Script Claude can execute
```

### Frontmatter Reference

```yaml
---
name: my-skill
description: What this skill does
argument-hint: [issue-number]
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
          command: "./validate.sh"
---
```

| Field | Required | Description |
|-------|----------|-------------|
| `name` | No | Display name (defaults to directory name). Lowercase, hyphens, max 64 chars. |
| `description` | Recommended | What the skill does. Claude uses this to decide when to apply. |
| `argument-hint` | No | Hint shown during autocomplete (e.g., `[issue-number]`) |
| `disable-model-invocation` | No | `true` prevents Claude from auto-loading (manual `/name` only). Default: `false` |
| `user-invocable` | No | `false` hides from `/` menu (background knowledge only). Default: `true` |
| `allowed-tools` | No | Tools Claude can use without asking when skill is active |
| `model` | No | Model to use when skill is active |
| `context` | No | `fork` to run in a forked subagent context |
| `agent` | No | Which subagent type for `context: fork` |
| `hooks` | No | Hooks scoped to this skill's lifecycle |

### Invocation Control

| Frontmatter | You can invoke | Claude can invoke | Context loading |
|-------------|---------------|-------------------|-----------------|
| (default) | Yes | Yes | Description always in context, full loads on invoke |
| `disable-model-invocation: true` | Yes | No | Description NOT in context |
| `user-invocable: false` | No | Yes | Description always in context |

### String Substitutions

| Variable | Description |
|----------|-------------|
| `$ARGUMENTS` | All arguments passed when invoking |
| `$ARGUMENTS[N]` | Specific argument by 0-based index |
| `$N` | Shorthand for `$ARGUMENTS[N]` |
| `${CLAUDE_SESSION_ID}` | Current session ID |
| `${CLAUDE_SKILL_DIR}` | Directory containing the skill's SKILL.md |

### Dynamic Context Injection

The `` !`command` `` syntax runs shell commands before skill content is sent to Claude:

```yaml
---
name: pr-summary
context: fork
agent: Explore
---

## PR context
- PR diff: !`gh pr diff`
- Changed files: !`gh pr diff --name-only`
```

### Bundled Skills

- **`/simplify`** -- Reviews recently changed files for code reuse, quality, and efficiency
- **`/batch <instruction>`** -- Orchestrates large-scale changes across codebase in parallel (5-30 units, each in isolated git worktree)
- **`/debug [description]`** -- Troubleshoots current Claude Code session by reading debug log
- **`/claude-api`** -- Loads Claude API reference material for your language

### Character Budget

Skill descriptions are loaded into context. Budget scales at 2% of context window (fallback: 16,000 chars). Override with `SLASH_COMMAND_TOOL_CHAR_BUDGET` env var.

---

## 8. Custom Subagents

### What Are Subagents?

Specialized AI assistants that handle specific tasks. Each runs in its own context window with custom system prompt, tool access, and independent permissions.

### Built-in Subagents

| Agent | Model | Tools | Purpose |
|-------|-------|-------|---------|
| **Explore** | Haiku (fast) | Read-only | File discovery, codebase exploration |
| **Plan** | Inherits | Read-only | Codebase research for planning |
| **general-purpose** | Inherits | All | Complex multi-step tasks |
| **Bash** | Inherits | Terminal | Running terminal commands |
| **statusline-setup** | Sonnet | - | `/statusline` configuration |
| **Claude Code Guide** | Haiku | - | Questions about Claude Code features |

### Subagent Scopes and Priority

| Location | Scope | Priority |
|----------|-------|----------|
| `--agents` CLI flag | Current session | 1 (highest) |
| `.claude/agents/` | Current project | 2 |
| `~/.claude/agents/` | All projects | 3 |
| Plugin `agents/` | Where plugin enabled | 4 (lowest) |

### Subagent File Format

```markdown
---
name: code-reviewer
description: Reviews code for quality and best practices
tools: Read, Glob, Grep, Bash
disallowedTools: Write, Edit
model: sonnet
permissionMode: default
maxTurns: 50
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
          command: "./scripts/validate.sh"
---

You are a code reviewer. Analyze code and provide specific feedback.
```

### Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Unique identifier (lowercase, hyphens) |
| `description` | Yes | When Claude should delegate to this subagent |
| `tools` | No | Tools the subagent can use (inherits all if omitted) |
| `disallowedTools` | No | Tools to deny |
| `model` | No | `sonnet`, `opus`, `haiku`, or `inherit` (default) |
| `permissionMode` | No | `default`, `acceptEdits`, `dontAsk`, `bypassPermissions`, `plan` |
| `maxTurns` | No | Maximum agentic turns |
| `skills` | No | Skills preloaded at startup (full content injected) |
| `mcpServers` | No | MCP servers available |
| `hooks` | No | Lifecycle hooks scoped to subagent |
| `memory` | No | Persistent memory scope: `user`, `project`, `local` |
| `background` | No | `true` to always run as background task |
| `isolation` | No | `worktree` for isolated git worktree copy |

### Memory Scopes

| Scope | Location | Use when |
|-------|----------|----------|
| `user` | `~/.claude/agent-memory/<name>/` | Knowledge across all projects |
| `project` | `.claude/agent-memory/<name>/` | Project-specific, shareable |
| `local` | `.claude/agent-memory-local/<name>/` | Project-specific, not committed |

### CLI-Defined Subagents

```bash
claude --agents '{
  "code-reviewer": {
    "description": "Expert code reviewer. Use proactively after code changes.",
    "prompt": "You are a senior code reviewer...",
    "tools": ["Read", "Grep", "Glob", "Bash"],
    "model": "sonnet"
  }
}'
```

### Foreground vs Background

- **Foreground**: Blocks main conversation. Permission prompts pass through to user.
- **Background**: Runs concurrently. Pre-approves permissions before launch. Auto-denies anything not pre-approved.
- Press **Ctrl+B** to background a running task
- Disable with `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1`

---

## 9. Plugins System

### Plugin Structure

```
my-plugin/
  .claude-plugin/
    plugin.json        # Manifest (required)
  commands/            # Skills as Markdown files
  agents/              # Custom agent definitions
  skills/              # Agent Skills with SKILL.md files
  hooks/
    hooks.json         # Event handlers
  .mcp.json            # MCP server configurations
  .lsp.json            # LSP server configurations
  settings.json        # Default settings when plugin enabled
```

**Warning**: Don't put `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/`. Only `plugin.json` goes inside `.claude-plugin/`.

### Plugin Manifest (plugin.json)

```json
{
  "name": "my-plugin",
  "description": "A helpful plugin",
  "version": "1.0.0",
  "author": {
    "name": "Your Name"
  },
  "homepage": "https://...",
  "repository": "https://...",
  "license": "MIT"
}
```

### Plugin Commands

- `/plugin marketplace add <owner/repo>` -- Add marketplace
- `/plugin install <name>` -- Install from marketplace
- `--plugin-dir ./my-plugin` -- Load plugin during development

### Plugin vs Standalone

| Approach | Skill names | Best for |
|----------|-------------|----------|
| Standalone (`.claude/`) | `/hello` | Personal, project-specific |
| Plugin | `/plugin-name:hello` | Sharing, distribution, versioning |

### Plugin Settings

Currently only `agent` key is supported in plugin `settings.json`:

```json
{
  "agent": "security-reviewer"
}
```

---

## 10. Hooks System

### Hook Events (Complete List)

| Event | When it fires | Matcher filters | Can block? |
|-------|---------------|-----------------|------------|
| `SessionStart` | Session begins/resumes | `startup`, `resume`, `clear`, `compact` | No |
| `UserPromptSubmit` | Prompt submitted, before processing | No matcher | No (injects context) |
| `PreToolUse` | Before tool call executes | Tool name (`Bash`, `Edit\|Write`, `mcp__.*`) | Yes |
| `PermissionRequest` | Permission dialog appears | Tool name | Yes |
| `PostToolUse` | After tool call succeeds | Tool name | Yes (block response) |
| `PostToolUseFailure` | After tool call fails | Tool name | No |
| `Notification` | Notification sent | `permission_prompt`, `idle_prompt`, `auth_success`, `elicitation_dialog` | No |
| `SubagentStart` | Subagent spawned | Agent type name | No |
| `SubagentStop` | Subagent finishes | Agent type name | No |
| `Stop` | Claude finishes responding | No matcher | Yes (continue working) |
| `TeammateIdle` | Team teammate going idle | No matcher | Yes |
| `TaskCompleted` | Task marked complete | No matcher | Yes |
| `InstructionsLoaded` | CLAUDE.md/rules loaded | No matcher | No |
| `ConfigChange` | Config file changes | `user_settings`, `project_settings`, `local_settings`, `policy_settings`, `skills` | Yes |
| `WorktreeCreate` | Worktree being created | No matcher | Yes (replaces default) |
| `WorktreeRemove` | Worktree being removed | No matcher | No |
| `PreCompact` | Before compaction | `manual`, `auto` | No |
| `SessionEnd` | Session terminates | `clear`, `logout`, `prompt_input_exit`, `bypass_permissions_disabled`, `other` | No |

### Hook Types

| Type | Description |
|------|-------------|
| `command` | Run a shell command |
| `http` | POST event data to a URL |
| `prompt` | Single-turn LLM evaluation (Haiku by default) |
| `agent` | Multi-turn verification with tool access |

### Exit Code Behavior

- **Exit 0**: Action proceeds. Stdout added to context for `UserPromptSubmit` and `SessionStart`.
- **Exit 2**: Action blocked. Stderr fed back to Claude as feedback.
- **Any other**: Action proceeds. Stderr logged but not shown to Claude (visible in verbose mode via Ctrl+O).

### JSON Output Format

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Use rg instead of grep for better performance"
  }
}
```

`permissionDecision` values for PreToolUse: `"allow"`, `"deny"`, `"ask"`

### Prompt-Based Hooks

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Check if all tasks are complete. If not, respond with {\"ok\": false, \"reason\": \"what remains\"}.",
            "model": "haiku"
          }
        ]
      }
    ]
  }
}
```

Returns `{"ok": true}` or `{"ok": false, "reason": "..."}`.

### Agent-Based Hooks

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "agent",
            "prompt": "Verify that all unit tests pass. Run the test suite. $ARGUMENTS",
            "timeout": 120
          }
        ]
      }
    ]
  }
}
```

Spawns a subagent with tool access. Default timeout 60s, max 50 turns.

### HTTP Hooks

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "hooks": [
          {
            "type": "http",
            "url": "http://localhost:8080/hooks/tool-use",
            "headers": {
              "Authorization": "Bearer $MY_TOKEN"
            },
            "allowedEnvVars": ["MY_TOKEN"]
          }
        ]
      }
    ]
  }
}
```

### Environment Variables in Hooks

- `$CLAUDE_PROJECT_DIR` -- project root directory
- `$TOOL_INPUT` -- tool input JSON (for some hooks)
- Custom env vars via `allowedEnvVars` in HTTP hooks

### Important Stop Hook Pattern

To prevent infinite loops, check `stop_hook_active`:

```bash
#!/bin/bash
INPUT=$(cat)
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then
  exit 0  # Allow Claude to stop
fi
# ... rest of hook logic
```

---

## 11. Sandboxing

### What It Is

OS-level filesystem and network isolation for Bash commands. Uses Seatbelt (macOS) or bubblewrap (Linux/WSL2).

### Enable

Run `/sandbox` in Claude Code session.

### Sandbox Modes

| Mode | Description |
|------|-------------|
| **Auto-allow** | Sandboxed commands auto-approved. Unsandboxed fall back to normal permission flow. |
| **Regular permissions** | All commands go through standard permission flow, even when sandboxed. |

### Filesystem Isolation

- **Default writes**: Only current working directory and subdirectories
- **Default reads**: Entire computer, except denied directories
- **Configurable**: `sandbox.filesystem.allowWrite`, `denyWrite`, `denyRead`
- **OS-level**: Enforced for all subprocesses too (kubectl, terraform, npm, etc.)

### Network Isolation

- **Domain restrictions**: Only approved domains accessible
- **User confirmation**: New domains trigger permission prompts
- **Proxy-based**: Runs through a proxy server outside the sandbox

### Security Benefits

Protects against:
- Prompt injection (can't modify `~/.bashrc`, system files)
- Data exfiltration (can't contact unapproved servers)
- Malicious dependencies
- Supply chain attacks

### Limitations

- `watchman` incompatible (use `jest --no-watchman`)
- `docker` incompatible (add to `excludedCommands`)
- `enableWeakerNestedSandbox` for Docker environments (weakens security)
- Escape hatch: `dangerouslyDisableSandbox` parameter (disable with `allowUnsandboxedCommands: false`)

---

## 12. Environment Variables (Complete List)

### Authentication

| Variable | Description |
|----------|-------------|
| `ANTHROPIC_API_KEY` | API key |
| `ANTHROPIC_AUTH_TOKEN` | Custom Authorization header |
| `ANTHROPIC_CUSTOM_HEADERS` | Custom headers (Name: Value) |
| `ANTHROPIC_FOUNDRY_API_KEY` | Microsoft Foundry API key |
| `ANTHROPIC_FOUNDRY_BASE_URL` | Foundry base URL |
| `ANTHROPIC_FOUNDRY_RESOURCE` | Foundry resource name |
| `AWS_BEARER_TOKEN_BEDROCK` | Bedrock API key |

### Model Configuration

| Variable | Description |
|----------|-------------|
| `ANTHROPIC_MODEL` | Model name to use |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | Haiku model override |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | Sonnet model override |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | Opus model override |
| `ANTHROPIC_SMALL_FAST_MODEL` | **Deprecated** |
| `ANTHROPIC_SMALL_FAST_MODEL_AWS_REGION` | AWS region for Haiku |

### Behavior and Features

| Variable | Description |
|----------|-------------|
| `CLAUDE_CODE_EFFORT_LEVEL` | `"low"`, `"medium"`, `"high"` |
| `CLAUDE_CODE_DISABLE_FAST_MODE` | Disable fast mode |
| `CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING` | Disable adaptive reasoning |
| `CLAUDE_CODE_DISABLE_AUTO_MEMORY` | Disable auto memory |
| `CLAUDE_CODE_DISABLE_GIT_INSTRUCTIONS` | Disable git instructions |
| `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS` | Disable background tasks |
| `CLAUDE_CODE_DISABLE_1M_CONTEXT` | Disable 1M context window |
| `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS` | Disable beta features |
| `CLAUDE_CODE_DISABLE_TERMINAL_TITLE` | Disable terminal title updates |
| `CLAUDE_CODE_ENABLE_PROMPT_SUGGESTION` | Enable prompt suggestions |
| `CLAUDE_CODE_ENABLE_TASKS` | Enable task tracking system |
| `CLAUDE_CODE_SIMPLE` | Minimal mode (Bash, file tools only) |

### Telemetry and Monitoring

| Variable | Description |
|----------|-------------|
| `CLAUDE_CODE_ENABLE_TELEMETRY` | Enable OpenTelemetry |
| `CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY` | Disable session quality surveys |
| `DISABLE_ERROR_REPORTING` | Opt out of Sentry |
| `DISABLE_TELEMETRY` | Disable telemetry |
| `DISABLE_COST_WARNINGS` | Disable cost warnings |

### Updates and Maintenance

| Variable | Description |
|----------|-------------|
| `DISABLE_AUTOUPDATER` | Disable automatic updates |
| `DISABLE_INSTALLATION_CHECKS` | Disable installation warnings |

### Tools and Commands

| Variable | Description |
|----------|-------------|
| `DISABLE_BUG_COMMAND` | Disable `/bug` command |
| `DISABLE_NON_ESSENTIAL_MODEL_CALLS` | Disable flavor text model calls |
| `DISABLE_PROMPT_CACHING` | Disable prompt caching globally |
| `DISABLE_PROMPT_CACHING_HAIKU` | Disable prompt caching for Haiku |

### Shell and Execution

| Variable | Description |
|----------|-------------|
| `CLAUDE_CODE_SHELL` | Override shell detection |
| `CLAUDE_CODE_SHELL_PREFIX` | Command prefix for all bash commands |
| `CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR` | Return to original directory after bash |
| `BASH_DEFAULT_TIMEOUT_MS` | Default bash timeout |
| `BASH_MAX_TIMEOUT_MS` | Maximum allowed bash timeout |
| `BASH_MAX_OUTPUT_LENGTH` | Max characters in bash output |

### Files and I/O

| Variable | Description |
|----------|-------------|
| `CLAUDE_CODE_FILE_READ_MAX_OUTPUT_TOKENS` | Override file read token limit |
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS` | Max output tokens (default: 32000, max: 64000) |
| `CLAUDE_CODE_TMPDIR` | Override temp directory |

### Sandbox and Network

| Variable | Description |
|----------|-------------|
| `CLAUDE_CODE_SKIP_BEDROCK_AUTH` | Skip AWS auth for Bedrock |
| `CLAUDE_CODE_SKIP_FOUNDRY_AUTH` | Skip Azure auth for Foundry |
| `CLAUDE_CODE_SKIP_VERTEX_AUTH` | Skip Google auth for Vertex |
| `CLAUDE_CODE_USE_BEDROCK` | Use AWS Bedrock |
| `CLAUDE_CODE_USE_FOUNDRY` | Use Microsoft Foundry |
| `CLAUDE_CODE_USE_VERTEX` | Use Google Vertex |
| `CLAUDE_CODE_PROXY_RESOLVES_HOSTS` | Allow proxy DNS resolution |

### Plugins and Extensions

| Variable | Description |
|----------|-------------|
| `CLAUDE_CODE_PLUGIN_GIT_TIMEOUT_MS` | Git timeout for plugins (default: 120000) |

### Agent Teams

| Variable | Description |
|----------|-------------|
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | Enable agent teams |
| `CLAUDE_CODE_TEAM_NAME` | Name of agent team (auto-set) |
| `CLAUDE_CODE_PLAN_MODE_REQUIRED` | Require plan approval (auto-set) |
| `CLAUDE_CODE_SUBAGENT_MODEL` | Subagent model override |

### Session and State

| Variable | Description |
|----------|-------------|
| `CLAUDE_CODE_TASK_LIST_ID` | Share task list across sessions |
| `CLAUDE_CODE_AUTOCOMPACT_PCT_OVERRIDE` | Auto-compaction threshold (1-100) |
| `CLAUDE_CODE_EXIT_AFTER_STOP_DELAY` | Auto-exit delay (ms) |

### User and Organization

| Variable | Description |
|----------|-------------|
| `CLAUDE_CODE_ACCOUNT_UUID` | Account UUID (for SDK) |
| `CLAUDE_CODE_USER_EMAIL` | User email (for SDK) |
| `CLAUDE_CODE_ORGANIZATION_UUID` | Organization UUID (for SDK) |
| `CLAUDE_CODE_HIDE_ACCOUNT_INFO` | Hide email/org in UI |

### Configuration and Storage

| Variable | Description |
|----------|-------------|
| `CLAUDE_CONFIG_DIR` | Custom config directory |
| `CLAUDE_CODE_API_KEY_HELPER_TTL_MS` | Credential refresh interval |
| `CLAUDE_CODE_OTEL_HEADERS_HELPER_DEBOUNCE_MS` | OTel header refresh interval |

### IDE and Client

| Variable | Description |
|----------|-------------|
| `CLAUDE_CODE_IDE_SKIP_AUTO_INSTALL` | Skip IDE extension auto-install |
| `CLAUDE_CODE_CLIENT_CERT` | Client certificate for mTLS |
| `CLAUDE_CODE_CLIENT_KEY` | Client private key for mTLS |
| `CLAUDE_CODE_CLIENT_KEY_PASSPHRASE` | Passphrase for client key |

### Additional Context

| Variable | Description |
|----------|-------------|
| `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD` | Load CLAUDE.md from additional directories |
| `SLASH_COMMAND_TOOL_CHAR_BUDGET` | Override skill description character budget |

---

## 13. .claude/ Directory Structure

```
.claude/
  CLAUDE.md              # Main project instructions (loaded at launch)
  settings.json          # Shared project settings (committed to git)
  settings.local.json    # Local project settings (gitignored)
  rules/                 # Path-scoped and general rules
    code-style.md
    testing.md
    security.md
    frontend/
      react.md
  skills/                # Custom skills
    my-skill/
      SKILL.md
      scripts/
        helper.sh
  agents/                # Custom subagent definitions
    code-reviewer.md
    debugger.md
  agent-memory/          # Subagent persistent memory (project scope)
    code-reviewer/
      MEMORY.md
  agent-memory-local/    # Subagent memory (local, not committed)
    debugger/
      MEMORY.md
  hooks/                 # Hook scripts
    block-rm.sh
    protect-files.sh
  commands/              # Legacy custom commands (superseded by skills/)
    review.md
```

### User-Level Directory

```
~/.claude/
  CLAUDE.md              # Personal instructions (all projects)
  settings.json          # User settings
  settings.local.json    # User local settings
  rules/                 # Personal rules (all projects)
    preferences.md
    workflows.md
  skills/                # Personal skills
    explain-code/
      SKILL.md
  agents/                # Personal subagents
    code-reviewer.md
  agent-memory/          # Subagent memory (user scope)
    code-reviewer/
      MEMORY.md
  projects/              # Auto memory per project
    <project>/
      memory/
        MEMORY.md
        debugging.md
```

---

## 14. .claudeignore

`.claudeignore` works like `.gitignore` -- files matching patterns are excluded from Claude's context. Place it at your project root.

```
# .claudeignore example
node_modules/
dist/
*.min.js
*.map
.env*
coverage/
```

Note: `respectGitignore` setting (default `true`) also controls whether `.gitignore` patterns are respected.

---

## 15. CLAUDE.md Best Practices -- From Real-World Experience

### From HumanLayer Blog

1. **LLMs are stateless** -- CLAUDE.md is the ONLY persistent context across sessions
2. **Structure around WHY, WHAT, HOW**:
   - WHAT: tech stack, project structure, codebase map
   - WHY: project purpose, component functions
   - HOW: workflows, tools, testing, compilation
3. **Keep under 300 lines** (ideally under 60 for root file)
4. **Research shows**: Frontier thinking LLMs can follow ~150-200 instructions consistently. Claude Code's system prompt already uses ~50, leaving limited capacity.
5. **"As instruction count increases, instruction-following quality decreases uniformly"** -- models ignore ALL instructions more, not just new ones
6. **Claude Code injects this reminder**: "this context may or may not be relevant to your tasks" -- so irrelevant content gets ignored
7. **Use progressive disclosure**: Separate docs in `agent_docs/` or `docs/`, reference from CLAUDE.md
8. **Prefer pointers to copies**: Don't include code snippets (they become outdated)
9. **Never use CLAUDE.md for code style** -- LLMs are in-context learners; they infer patterns from existing code
10. **Never use CLAUDE.md as a linter** -- Use deterministic tools (Biome, Prettier) + hooks instead
11. **Don't auto-generate with `/init`** -- CLAUDE.md is the highest leverage point; craft it manually

### From Builder.io Blog

1. **Filename is case-sensitive**: Must be exactly `CLAUDE.md`
2. **Essential sections**: Project context (one-line), code style, commands, architecture, gotchas
3. **Be explicit about preferences**: "Use 2-space indentation" not "format code properly"
4. **List exact commands**: Claude uses these exact commands when you request execution
5. **Document gotchas**: Files that should never be modified, auth flows with special handling, API endpoints with specific headers
6. **Use @imports sparingly** to avoid confusing reference chains
7. **Treat as living documentation**: Update when architecture changes, remove sections Claude never needs

### From Trail of Bits

1. **Philosophy sections**: "No speculative features", "No premature abstraction", "Replace don't deprecate"
2. **Hard limits**: Function length, complexity thresholds, line width
3. **Language-specific toolchains**: List exact linters, formatters, test runners per language
4. **Run with `--dangerously-skip-permissions`** + sandbox for speed, using deny rules as enforcement

### Universal Anti-Patterns

- **Bloated CLAUDE.md**: >300 lines causes Claude to ignore instructions uniformly
- **Duplicate content**: Same instruction in CLAUDE.md, rules/, and skills/ creates confusion
- **Code snippets**: Become outdated; prefer file:line references
- **Vague instructions**: "Keep code clean" is useless; "Run `bun run lint:fix` before committing" is actionable
- **Auto-generated without review**: `/init` output needs heavy editing
- **Conflicting instructions**: Claude picks one arbitrarily when instructions conflict

---

## 16. Real-World Configuration Examples

### Example: Security-Focused Configuration (Trail of Bits)

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "env": {
    "DISABLE_TELEMETRY": "1",
    "DISABLE_ERROR_REPORTING": "1",
    "CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY": "1"
  },
  "permissions": {
    "deny": [
      "Read(~/.ssh/**)",
      "Read(~/.gnupg/**)",
      "Read(~/.aws/**)",
      "Read(~/.azure/**)",
      "Read(~/.kube/**)",
      "Read(~/.docker/config.json)",
      "Read(~/.npmrc)",
      "Read(~/.pypirc)",
      "Read(~/.gem/credentials)",
      "Read(~/.git-credentials)",
      "Read(~/.config/gh/**)",
      "Edit(~/.bashrc)",
      "Edit(~/.zshrc)",
      "Edit(~/.profile)"
    ]
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "echo \"$(cat)\" | jq -r '.tool_input.command' | grep -q 'rm -rf' && echo 'Use trash instead of rm -rf' >&2 && exit 2 || exit 0"
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "echo \"$(cat)\" | jq -r '.tool_input.command' | grep -qE 'git push.*(main|master)' && echo 'Use feature branches, not direct push to main' >&2 && exit 2 || exit 0"
          }
        ]
      }
    ]
  },
  "enableAllProjectMcpServers": false,
  "alwaysThinkingEnabled": true,
  "cleanupPeriodDays": 365
}
```

### Example: Development Team Configuration

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "allow": [
      "Bash(bun run *)",
      "Bash(bun test *)",
      "Bash(git status)",
      "Bash(git diff *)",
      "Bash(git log *)",
      "Bash(git add *)",
      "Bash(git commit *)",
      "Read"
    ],
    "deny": [
      "Bash(git push --force *)",
      "Bash(rm -rf *)",
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)"
    ],
    "ask": [
      "Bash(git push *)",
      "Bash(bun run deploy *)"
    ],
    "defaultMode": "acceptEdits"
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.tool_input.file_path' | xargs npx biome check --write 2>/dev/null || true"
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "osascript -e 'display notification \"Claude Code needs attention\" with title \"Claude Code\"'"
          }
        ]
      }
    ]
  },
  "alwaysThinkingEnabled": true,
  "showTurnDuration": true
}
```

### Example: Minimal CLAUDE.md (50 lines)

```markdown
# MyProject

Next.js 15 App Router + TypeScript + Tailwind v4 + Bun

## Commands

- `bun install` -- install deps (NEVER npm/yarn/pnpm)
- `bun run dev` -- dev server
- `bun run build` -- production build
- `bun run typecheck` -- TypeScript check
- `bun run lint:fix` -- auto-fix lint issues
- `bun test <path>` -- run specific tests

## Architecture

```
app/           -- Next.js routes and layouts
components/    -- React components (shadcn/ui primitives)
lib/           -- Business logic, services, utilities
lib/services/  -- Core services (auth, db, search, etc.)
```

## Rules

- Server Components by default. Only add `'use client'` when needed.
- `await params` and `await searchParams` in Next.js 15 (async).
- Use `createServiceRoleClient()` for Supabase, never construct manually.
- Use sonner toast for notifications, never `alert()`/`confirm()`.
- Use `next/image`, never raw `<img>`.
- Use `lucide-react` icons, never emoji in system UI.
- Run `bun run quality-check` before committing.

## Gotchas

- Clerk auth: `const { userId } = await auth()` in all protected API routes.
- PostgREST: End schema-changing migrations with `NOTIFY pgrst, 'reload schema'`.
- Docker dev (`bun run dev:docker`) uses different Clerk keys than `.env.local`.
```

### Example: Multi-Provider Settings (feiskyer)

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://localhost:4000",
    "ANTHROPIC_AUTH_TOKEN": "sk-...",
    "ANTHROPIC_MODEL": "litellm/claude-sonnet-4-6",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "litellm/claude-sonnet-4-6",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "litellm/claude-opus-4-6",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "litellm/claude-haiku-4-5-20251001",
    "DISABLE_TELEMETRY": "1",
    "DISABLE_NON_ESSENTIAL_MODEL_CALLS": "1"
  }
}
```

---

## Sources

- [Claude Code Settings Reference](https://code.claude.com/docs/en/settings)
- [Claude Code Permissions](https://code.claude.com/docs/en/permissions)
- [Claude Code Memory (CLAUDE.md)](https://code.claude.com/docs/en/memory)
- [Claude Code Skills](https://code.claude.com/docs/en/skills)
- [Claude Code Subagents](https://code.claude.com/docs/en/sub-agents)
- [Claude Code Plugins](https://code.claude.com/docs/en/plugins)
- [Claude Code Hooks Guide](https://code.claude.com/docs/en/hooks-guide)
- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks)
- [Claude Code Sandboxing](https://code.claude.com/docs/en/sandboxing)
- [Writing a Good CLAUDE.md -- HumanLayer Blog](https://www.humanlayer.dev/blog/writing-a-good-claude-md)
- [How to Write a Good CLAUDE.md -- Builder.io](https://www.builder.io/blog/claude-md-guide)
- [Trail of Bits Claude Code Config](https://github.com/trailofbits/claude-code-config)
- [feiskyer/claude-code-settings](https://github.com/feiskyer/claude-code-settings)
- [Claude Code Best Practices](https://code.claude.com/docs/en/best-practices)
