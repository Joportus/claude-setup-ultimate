# Beads Issue Tracker - Exhaustive Deep Dive

> **Research date:** 2026-03-05
> **Repository:** https://github.com/steveyegge/beads
> **Stars:** 18,103 | **Forks:** 1,140 | **Open Issues:** 89
> **License:** MIT | **Language:** Go | **Created:** 2025-10-12
> **Current version:** v0.58.0 (2026-03-02)
> **Author:** Steve Yegge

---

## Table of Contents

1. [Overview](#1-overview)
2. [Installation](#2-installation)
3. [Initialization & Project Setup](#3-initialization--project-setup)
4. [Core Concepts](#4-core-concepts)
5. [CLI Command Reference](#5-cli-command-reference)
6. [Configuration System](#6-configuration-system)
7. [Dolt Backend](#7-dolt-backend)
8. [Editor & Agent Integration](#8-editor--agent-integration)
9. [Memory System](#9-memory-system)
10. [Molecule & Workflow System](#10-molecule--workflow-system)
11. [Hooks Integration](#11-hooks-integration)
12. [Protected Branch Workflow](#12-protected-branch-workflow)
13. [Multi-Agent Workflows](#13-multi-agent-workflows)
14. [MCP Server](#14-mcp-server)
15. [Community Tools & Ecosystem](#15-community-tools--ecosystem)
16. [Version History](#16-version-history)
17. [Troubleshooting](#17-troubleshooting)
18. [Articles & Tutorials](#18-articles--tutorials)
19. [Best Practices & Anti-Patterns](#19-best-practices--anti-patterns)
20. [Our Project Setup (Hypebase)](#20-our-project-setup-hypebase)

---

## 1. Overview

Beads (CLI: `bd`) is a **distributed, git-backed graph issue tracker designed for AI agents**. It provides persistent, structured memory for coding agents, replacing markdown plans with a dependency-aware graph that allows agents to handle long-horizon tasks without losing context.

### Key Differentiators

| Feature | Beads | GitHub Issues |
|---------|-------|---------------|
| Typed dependencies | 4 types (blocks, related, parent-child, discovered-from) | Only blocks/blocked by |
| Ready-work detection | `bd ready` computes transitive blocking in ~10ms offline | No built-in concept |
| Offline-first | Full functionality without network | Cloud-first, requires network |
| AI-resolvable conflicts | Auto collision resolution, duplicate merge | Manual close-as-duplicate |
| Version-controlled SQL | Full SQL queries against local Dolt DB | No local database |
| Agent-native APIs | Consistent `--json` on all commands, MCP server | Mixed output, no agent focus |

### Core Features

- **Dolt-Powered:** Version-controlled SQL database with cell-level merge, native branching, and built-in sync via Dolt remotes
- **Agent-Optimized:** JSON output, dependency tracking, auto-ready task detection
- **Zero Conflict:** Hash-based IDs (`bd-a1b2`) prevent merge collisions in multi-agent/multi-branch workflows
- **Compaction:** Semantic "memory decay" summarizes old closed tasks to save context window
- **Messaging:** Message issue type with threading (`--thread`), ephemeral lifecycle, and mail delegation
- **Graph Links:** `relates_to`, `duplicates`, `supersedes`, and `replies_to` for knowledge graphs
- **Hierarchical IDs:** `bd-a3f8` (Epic) > `bd-a3f8.1` (Task) > `bd-a3f8.1.1` (Sub-task)

---

## 2. Installation

### Installation Methods

| Method | Command | Best For | Updates |
|--------|---------|----------|---------|
| **Homebrew** | `brew install beads` | macOS/Linux | `brew upgrade beads` |
| **npm** | `npm install -g @beads/bd` | JS/Node.js projects | `npm update -g @beads/bd` |
| **bun** | `bun install -g --trust @beads/bd` | Bun projects | `bun install -g --trust @beads/bd` |
| **Install script** | `curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh \| bash` | Quick setup, CI/CD | Re-run script |
| **PowerShell** | `irm https://raw.githubusercontent.com/steveyegge/beads/main/install.ps1 \| iex` | Windows | Re-run script |
| **go install** | `go install github.com/steveyegge/beads/cmd/bd@latest` | Go developers | Re-run command |
| **From source** | `git clone && go build` | Contributors | `git pull && go build` |
| **Mise** | `mise install github:steveyegge/beads` | Mise users | `mise up` |
| **AUR** | `yay -S beads-git` | Arch Linux | `yay -Syu` |

### Build Dependencies (go install / from source)

**macOS:**
```bash
brew install icu4c zstd
```

**Linux (Debian/Ubuntu):**
```bash
sudo apt-get install -y libicu-dev libzstd-dev
```

**Linux (Fedora/RHEL):**
```bash
sudo dnf install -y libicu-devel libzstd-devel
```

### Components Overview

| Component | What It Is | When You Need It |
|-----------|------------|------------------|
| **bd CLI** | Core command-line tool | Always -- this is the foundation |
| **Claude Code Plugin** | Slash commands + enhanced UX | Optional -- `/beads:ready`, `/beads:create` commands |
| **MCP Server (beads-mcp)** | Model Context Protocol interface | Only for MCP-only environments (Claude Desktop, Amp) |

**Important:** Beads is installed system-wide, not cloned into your project. The `.beads/` directory in your project only contains the issue database.

### Typical Setups

| Environment | What to Install |
|-------------|-----------------|
| Claude Code, Cursor, Windsurf | bd CLI (+ optional Plugin for Claude Code) |
| GitHub Copilot (VS Code) | bd CLI + MCP server |
| Claude Desktop (no shell) | MCP server only |
| Terminal / scripts | bd CLI only |
| CI/CD pipelines | bd CLI only |

### Post-Install Verification

```bash
bd version
bd help
bd info --whats-new
```

### After Upgrading

```bash
bd info --whats-new
bd hooks install
bd version
```

---

## 3. Initialization & Project Setup

### Basic Init

```bash
cd your-project
bd init          # Interactive setup
bd init --quiet  # Non-interactive (for agents, auto-installs hooks)
```

### Init Modes

```bash
bd init                           # Basic interactive setup
bd init --quiet                   # Non-interactive (for agents)
bd init --stealth                 # Local-only, no repo pollution (sets no-git-ops: true)
bd init --contributor             # OSS fork workflow (routes to separate planning repo)
bd init --team                    # Team member with commit access
bd init --branch beads-sync       # Protected branch workflow
bd init --backend dolt            # Explicit backend selection (Dolt is default/only)
bd init --prefix myproj           # Custom issue prefix
bd init --database <name>         # Configure existing Dolt server database
```

### Role Configuration

During `bd init`, you're asked about your role:

| Role | Use Case | Issue Storage |
|------|----------|---------------|
| `maintainer` | Repo owner, team with push access | In-repo `.beads/` |
| `contributor` | Fork contributor, OSS contributor | Separate planning repo |

```bash
git config beads.role contributor  # Set as contributor
git config beads.role maintainer   # Set as maintainer
git config --get beads.role        # Check current role
```

### Editor Integration Setup

```bash
bd setup claude   # Claude Code -- installs SessionStart/PreCompact hooks
bd setup cursor   # Cursor IDE -- creates .cursor/rules/beads.mdc
bd setup aider    # Aider -- creates .aider.conf.yml
bd setup codex    # Codex CLI -- creates/updates AGENTS.md
bd setup mux      # Mux -- creates/updates AGENTS.md

# Verify
bd setup claude --check
```

### What `bd init` Creates

```
your-project/
  .beads/
    dolt/           # Dolt database directory (gitignored)
    config.yaml     # Project-specific tool settings
    metadata.json   # Repository metadata
    .gitignore      # Tells git what to ignore in .beads/
  .gitattributes    # Merge driver config (in main branch)
```

---

## 4. Core Concepts

### Issue Lifecycle

```
open -> in_progress -> closed
  |                     ^
  +-----> blocked ------+
  |                     |
  +-----> deferred -----+
```

### Issue Types

- `task` - General work item
- `bug` - Bug fix
- `feature` - New feature
- `epic` - Parent container for hierarchical tasks
- `message` - Threaded communication (ephemeral lifecycle)
- `molecule` - Workflow execution unit

### Priority Levels

| Priority | Meaning |
|----------|---------|
| P0 | Critical |
| P1 | High |
| P2 | Medium |
| P3 | Low |
| P4 | Backlog |

### Dependency Types

| Type | Semantics | Blocks Ready Work? | Use Case |
|------|-----------|-------------------|----------|
| `blocks` | B cannot start until A completes | **Yes** | Sequencing work |
| `parent-child` | If parent blocked, children blocked | **Yes** | Hierarchy (children parallel by default) |
| `conditional-blocks` | B runs only if A fails | **Yes** | Error handling paths |
| `waits-for` | B waits for all of A's children | **Yes** | Fanout gates |
| `related` | Connected but non-blocking | No | Soft relationships |
| `discovered-from` | Found while working on another issue | No | Work discovery context |
| `replies-to` | Message threading | No | Communication |

### Hash-Based IDs

IDs are content-based hashes that prevent collisions when multiple agents/branches create issues concurrently:

- 4 chars (0-500 issues): `bd-a1b2`
- 5 chars (500-1,500 issues): `bd-f14c3`
- 6 chars (1,500+ issues): `bd-3e7a5b`

Progressive length scaling is automatic. Configurable via:
```bash
bd config set max_collision_prob "0.25"
bd config set min_hash_length "4"
bd config set max_hash_length "8"
```

Alternative: Sequential counter IDs (`bd-1`, `bd-2`, ...):
```bash
bd config set issue_id_mode counter
```

### Hierarchical IDs (Epics)

```bash
bd create "Auth System" -t epic -p 1           # bd-a3f8e9
bd create "Login UI" --parent bd-a3f8e9        # bd-a3f8e9.1
bd create "Validation" --parent bd-a3f8e9      # bd-a3f8e9.2
bd create "Tests" --parent bd-a3f8e9           # bd-a3f8e9.3
```

Up to 3 levels of nesting supported.

---

## 5. CLI Command Reference

### Essential Commands

| Command | Action |
|---------|--------|
| `bd ready` | List tasks with no open blockers |
| `bd create "Title" -p 0` | Create a P0 task |
| `bd update <id> --claim` | Atomically claim a task (sets assignee + in_progress) |
| `bd dep add <child> <parent>` | Link tasks (blocks, related, parent-child) |
| `bd show <id>` | View task details and audit trail |
| `bd close <id> --reason "Done"` | Complete a task |
| `bd list` | List all issues |
| `bd blocked` | Show blocked issues |
| `bd stats` | Project statistics |

### Issue Creation

```bash
# Basic
bd create "Issue title" -t bug -p 1 --json

# With description
bd create "Title" -t task -p 2 -d "Description" --json

# With labels
bd create "Title" -t bug -p 1 -l bug,critical --json

# With explicit ID
bd create "Title" --id worker1-100 -p 1 --json

# With dependencies
bd create "Found bug" -t bug -p 1 --deps discovered-from:<parent-id> --json

# With external reference
bd create "Fix login" -t bug -p 1 --external-ref "gh-123" --json

# Hierarchical child
bd create "Login UI" -p 1 --parent bd-a3f8e9 --json

# From file (description)
bd create "Title" --body-file=description.md --json

# From stdin
echo 'Description with `backticks`' | bd create "Title" --stdin --json

# From markdown file (multiple issues)
bd create -f feature-plan.md --json

# With metadata
bd create "Title" -p 1 --metadata key=value --json
```

### Issue Updates

```bash
# Claim (atomic: sets assignee + in_progress, fails if already claimed)
bd update <id> --claim --json

# Status change
bd update <id> --status in_progress --json

# Priority change
bd update <id> --priority 1 --json

# Description/title/design/notes/acceptance
bd update <id> --description "new description"
bd update <id> --title "new title"
bd update <id> --design "design notes"
bd update <id> --notes "additional notes"
bd update <id> --acceptance "acceptance criteria"

# Metadata
bd update <id> --set-metadata key=value --json
bd update <id> --unset-metadata key --json

# Multiple issues at once
bd update <id1> <id2> --priority 1 --json
```

**WARNING:** Never use `bd edit` with AI agents -- it opens an interactive editor.

### Closing/Reopening

```bash
bd close <id> --reason "Done" --json
bd close <id1> <id2> --reason "Completed" --json
bd reopen <id> --reason "Reopening" --json
```

### Dependencies

```bash
bd dep add <dependent> <blocking>               # dependent needs blocking
bd dep add <id> <id> --type discovered-from     # Discovery link
bd dep add <id> <id> --type related             # Soft relationship
bd dep remove <from-id> <to-id>                 # Remove dependency
bd dep tree <id>                                # Dependency tree
bd dep tree <id> --max-depth 10                 # Limit depth
bd dep cycles                                   # Detect circular deps
```

### Labels

```bash
bd label add <id> <label> --json
bd label remove <id> <label> --json
bd label list <id> --json
bd label list-all --json
```

### Filtering & Search

```bash
# By status, priority, type
bd list --status open --priority 1 --json
bd list --type bug --json
bd list --assignee alice --json

# Label filters (AND: must have ALL)
bd list --label bug,critical --json

# Label filters (OR: has ANY)
bd list --label-any frontend,backend --json

# Text search
bd list --title "auth" --json
bd list --title-contains "auth" --json
bd list --desc-contains "implement" --json

# Date ranges
bd list --created-after 2024-01-01 --json
bd list --updated-before 2024-12-31 --json

# Empty/null checks
bd list --empty-description --json
bd list --no-assignee --json
bd list --no-labels --json

# Priority ranges
bd list --priority-min 0 --priority-max 1 --json

# Stale issues
bd stale --days 30 --json
bd stale --days 90 --status in_progress --json

# Metadata filters
bd list --metadata-field key=value --json
```

### Viewing

```bash
bd show <id> --json                # Issue details
bd show <id1> <id2> --json         # Multiple issues
bd show --current                  # Currently active issue
bd info --json                     # Database info
bd stats                           # Project statistics
bd where                           # Database location
```

### Advanced Operations

```bash
# Compaction (memory decay)
bd admin compact --analyze --json
bd admin compact --apply --id bd-42 --summary summary.txt
bd admin compact --stats --json

# Cleanup
bd admin cleanup --older-than 30 --force --json
bd admin cleanup --dry-run --json

# Duplicate detection & merging
bd duplicates --json
bd duplicates --auto-merge
bd merge <source> --into <target> --json

# Search
bd search "keyword" --json

# Query (SQL-like DSL)
bd query "status=open AND priority<=1" --json

# Orphan detection
bd orphans --json

# Rename prefix
bd rename-prefix kw- --dry-run
bd rename-prefix kw-

# Health check
bd doctor
bd doctor --fix
bd doctor --agent
bd doctor validate
```

### Dolt-Specific Commands

```bash
bd dolt start              # Start Dolt server
bd dolt stop               # Stop Dolt server
bd dolt status             # Server status
bd dolt commit             # Commit Dolt data
bd dolt push               # Push to Dolt remote
bd dolt pull               # Pull from Dolt remote
bd dolt remote add <name> <url>  # Add Dolt remote
bd dolt remote list
bd dolt remote remove <name>
bd dolt set mode server    # Set Dolt mode
bd dolt set mode embedded  # Embedded mode (no server)
bd dolt clean-databases    # Clean stale databases
```

### Version Control Commands

```bash
bd vc log                  # Dolt history
bd vc diff                 # Show changes
bd vc conflicts            # View merge conflicts
bd vc resolve              # Resolve conflicts
```

### Global Flags

```bash
bd --json <command>            # JSON output
bd --sandbox <command>         # Sandbox mode (embedded, no auto-sync)
bd --allow-stale <command>     # Skip staleness check (emergency)
bd --db /path <command>        # Custom database path
bd --actor alice <command>     # Custom actor for audit trail
bd --dolt-auto-commit off <command>  # Disable auto Dolt commit
```

---

## 6. Configuration System

Beads has two complementary configuration systems:

### Tool-Level Configuration (Viper)

User preferences for tool behavior. Stored in config files or environment variables.

**Configuration precedence** (highest to lowest):
1. Command-line flags (`--json`, `--dolt-auto-commit`, etc.)
2. Environment variables (`BD_JSON`, `BD_DOLT_AUTO_COMMIT`, etc.)
3. Config file (`.beads/config.yaml` or `~/.config/bd/config.yaml`)
4. Defaults

**Config file locations** (searched in order):
1. `.beads/config.yaml` - Project-specific
2. `~/.config/bd/config.yaml` - User-specific
3. `~/.beads/config.yaml` - Legacy user settings

### Complete Tool-Level Settings

| Setting | Flag | Env Var | Default | Description |
|---------|------|---------|---------|-------------|
| `json` | `--json` | `BD_JSON` | `false` | Output in JSON format |
| `no-push` | `--no-push` | `BD_NO_PUSH` | `false` | Skip pushing to remote |
| `sync.mode` | - | `BD_SYNC_MODE` | `dolt-native` | Sync mode |
| `sync.export_on` | - | `BD_SYNC_EXPORT_ON` | `push` | When to export |
| `sync.import_on` | - | `BD_SYNC_IMPORT_ON` | `pull` | When to import |
| `conflict.strategy` | - | `BD_CONFLICT_STRATEGY` | `newest` | Conflict resolution |
| `federation.remote` | - | `BD_FEDERATION_REMOTE` | (none) | Dolt remote URL |
| `federation.sovereignty` | - | `BD_FEDERATION_SOVEREIGNTY` | (none) | Data sovereignty tier |
| `dolt.auto-commit` | `--dolt-auto-commit` | `BD_DOLT_AUTO_COMMIT` | `on` | Auto Dolt commit after writes |
| `dolt.auto-push` | - | `BD_DOLT_AUTO_PUSH` | (auto) | Auto-push to Dolt remote |
| `dolt.auto-push-interval` | - | `BD_DOLT_AUTO_PUSH_INTERVAL` | `5m` | Min time between auto-pushes |
| `create.require-description` | - | `BD_CREATE_REQUIRE_DESCRIPTION` | `false` | Require description on create |
| `validation.on-create` | - | `BD_VALIDATION_ON_CREATE` | `none` | Template validation on create |
| `validation.on-sync` | - | `BD_VALIDATION_ON_SYNC` | `none` | Template validation on sync |
| `git.author` | - | `BD_GIT_AUTHOR` | (none) | Override commit author |
| `git.no-gpg-sign` | - | `BD_GIT_NO_GPG_SIGN` | `false` | Disable GPG signing |
| `directory.labels` | - | - | (none) | Map dirs to labels |
| `external_projects` | - | - | (none) | Cross-project deps |
| `backup.enabled` | - | `BD_BACKUP_ENABLED` | `false` | Periodic JSONL backup |
| `backup.interval` | - | `BD_BACKUP_INTERVAL` | `15m` | Min time between backups |
| `backup.git-push` | - | `BD_BACKUP_GIT_PUSH` | `false` | Auto git push after export |
| `db` | `--db` | `BD_DB` | (auto) | Database path |
| `actor` | `--actor` | `BD_ACTOR` | `git config user.name` | Actor name for audit trail |

### Actor Identity Resolution Order

1. `--actor` flag
2. `BD_ACTOR` env var
3. `BEADS_ACTOR` env var (MCP compatibility)
4. `git config user.name`
5. `$USER` env var
6. `"unknown"` (final fallback)

### Project-Level Configuration (`bd config`)

Per-project settings stored in the Dolt database. Queryable and scriptable.

```bash
bd config set <key> <value>
bd config get <key>
bd config list
bd config unset <key>
```

### Core Config Namespaces

| Namespace | Purpose |
|-----------|---------|
| `issue_prefix` | Issue ID prefix |
| `issue_id_mode` | `hash` (default) or `counter` |
| `max_collision_prob` | Max collision probability (default: 0.25) |
| `min_hash_length` / `max_hash_length` | Hash ID length bounds (4-8) |
| `import.orphan_handling` | Missing parent handling (default: `allow`) |
| `export.error_policy` | Export error handling (default: `strict`) |
| `sync.branch` | Dedicated sync branch name |
| `compact_*` | Compaction settings |
| `jira.*` | Jira integration |
| `linear.*` | Linear integration |
| `github.*` | GitHub integration |
| `custom.*` | Custom integrations |
| `types.infra` | Infrastructure type routing |
| `types.custom` | Custom issue types |
| `metadata_schema` | Metadata field enforcement |

### Example config.yaml

```yaml
# .beads/config.yaml
create:
  require-description: true

validation:
  on-create: warn
  on-sync: none

git:
  author: "beads-bot <beads@example.com>"
  no-gpg-sign: true

dolt:
  auto-commit: on
  auto-push: true
  auto-push-interval: 5m

backup:
  enabled: true
  interval: 15m
  git-push: false

directory:
  labels:
    packages/frontend: frontend
    packages/backend: backend

output:
  title-length: 255
```

### Sync Modes

| Mode | Description |
|------|-------------|
| `dolt-native` | (default) Use Dolt remotes directly |
| `git-portable` | Legacy: JSONL committed to git |
| `belt-and-suspenders` | Both Dolt sync AND JSONL backup |

### Conflict Resolution Strategies

| Strategy | Description |
|----------|-------------|
| `newest` | (default) Keep newer `updated_at` timestamp |
| `ours` | Always keep local version |
| `theirs` | Always keep remote version |
| `manual` | Require interactive resolution |

### Federation Configuration

```yaml
federation:
  remote: dolthub://myorg/beads
  sovereignty: T2  # T1=full, T2=regional, T3=provider, T4=none
```

---

## 7. Dolt Backend

### What is Dolt?

Dolt is a version-controlled SQL database (like Git for MySQL). It provides:
- Full SQL queries with native version control
- Cell-level merge for concurrent changes
- Multi-writer support via server mode
- Native branching independent of git
- `bd export` produces JSONL for migration

### Architecture

```
bd CLI -> Dolt SQL Server (localhost, per-project port)
            |
            v
         .beads/dolt/ (Dolt database directory)
```

### Server Management

```bash
bd dolt start              # Start server
bd dolt stop               # Stop server
bd dolt status             # Check status
bd dolt set mode server    # Server mode (concurrent writes)
bd dolt set mode embedded  # Embedded mode (no server needed)
```

### Dolt Remotes

```bash
bd dolt remote add origin <url>
bd dolt push               # Push to remote
bd dolt pull               # Pull from remote
```

Remote URLs can be:
- `dolthub://org/beads` - DoltHub
- `gs://bucket/beads` - Google Cloud Storage
- `s3://bucket/beads` - AWS S3
- SSH URLs - Git-protocol remotes

### Auto-Commit and Auto-Push

- **Auto-commit:** Every write command automatically creates a Dolt version-control commit (configurable)
- **Auto-push:** When an `origin` remote exists, pushes happen automatically with 5-minute debounce

### Port Assignment

Beads uses hash-derived ports per project (not hardcoded 3307). Each project gets its own Dolt server.

### Key Changes in v0.56+

- Embedded Dolt mode removed -- running Dolt server required
- SQLite ephemeral store replaced with Dolt-backed `wisps` table
- JSONL sync pipeline removed -- Dolt-native push/pull only
- Binary size: 168MB -> ~41MB

### Key Changes in v0.58

- SQLite backend completely removed -- Dolt is the only backend
- No CGO requirement
- All migration infrastructure removed

---

## 8. Editor & Agent Integration

### Claude Code (Recommended: CLI + Hooks)

```bash
# Install bd CLI
brew install beads

# Initialize project
cd your-project
bd init --quiet

# Setup Claude Code integration
bd setup claude
```

**What `bd setup claude` does:**
- Installs SessionStart hook -> `bd prime` runs automatically on session start
- Installs PreCompact hook -> commits Dolt changes before context compaction
- `bd prime` provides ~1-2k tokens of workflow context

**Why CLI over MCP for Claude Code:**
- Context efficient: ~1-2k tokens vs 10-50k for MCP tool schemas
- Lower latency: Direct CLI calls, no MCP protocol overhead
- Universal: Works with any editor that has shell access

### Claude Code Plugin (Optional)

```bash
# In Claude Code
/plugin marketplace add steveyegge/beads
/plugin install beads
# Restart Claude Code
```

Adds slash commands: `/beads:ready`, `/beads:create`, `/beads:show`, `/beads:update`, `/beads:close`, etc.

### Cursor IDE

```bash
bd setup cursor  # Creates .cursor/rules/beads.mdc
```

### Aider

```bash
bd setup aider  # Creates .aider.conf.yml
```

### GitHub Copilot (VS Code)

Requires MCP server:

```bash
uv tool install beads-mcp
```

Create `.vscode/mcp.json`:
```json
{
  "servers": {
    "beads": {
      "command": "beads-mcp"
    }
  }
}
```

### Agent Session Workflow

```bash
# SESSION START (automatic via hooks)
bd prime                    # Injects ~1-2k tokens of context

# FIND WORK
bd ready --json             # What's available?
bd show <id> --json         # Review task details

# CLAIM WORK
bd update <id> --claim --json  # Atomic claim (sets assignee + in_progress)

# DO WORK
# ... code changes ...

# DISCOVER MORE WORK
bd create "Found bug" -t bug -p 1 --deps discovered-from:<current-id> --json

# COMPLETE WORK
bd close <id> --reason "Done" --json

# SESSION END
bd dolt push               # Push to remote if configured
```

### "Land the Plane" Protocol

When ending a session:

1. File beads issues for remaining work
2. Run quality gates (typecheck, lint, tests)
3. Close finished beads issues
4. `git push` (MANDATORY -- never stop before push completes)
5. Clean up git state
6. Verify clean state
7. Provide follow-up prompt for next session

---

## 9. Memory System

Added in v0.58.0. Persistent agent memory that survives sessions and account rotations.

### Commands

```bash
bd remember <key> <value>    # Store a memory
bd memories                  # List all memories
bd recall <key>              # Retrieve a memory (exact key match)
bd forget <key>              # Remove a memory
```

### How It Works

- Backed by the Dolt k/v store
- Auto-injected at `bd prime` time (SessionStart hook)
- Survives context compaction, session restarts, and account rotations
- Use exact key from `bd memories` output for `bd recall` (not fuzzy search)

### Use Cases

- Storing project conventions discovered during work
- Remembering debugging insights
- Tracking architectural decisions
- Preserving workflow preferences

---

## 10. Molecule & Workflow System

### Core Concept

A molecule is an epic (parent + children) with workflow execution semantics. Work flows through dependency graphs.

### Execution Model

```
epic-root (assigned to agent)
  child.1 (no deps -> ready)      <- execute in parallel
  child.2 (no deps -> ready)      <- execute in parallel
  child.3 (needs child.1) -> blocked until child.1 closes
  child.4 (needs child.2, child.3) -> blocked until both close
```

**Children are parallel by default.** Only explicit dependencies create sequence.

### Phase System (Chemistry Metaphor)

| Phase | Name | Storage | Synced | Purpose |
|-------|------|---------|--------|---------|
| **Solid** | Proto | `.beads/` | Yes | Frozen template (reusable) |
| **Liquid** | Mol | `.beads/` | Yes | Active persistent work |
| **Vapor** | Wisp | `.beads/` (Wisp=true) | No | Ephemeral operations |

### Molecule Commands

```bash
# Template instantiation
bd mol pour <proto> --var k=v    # Proto -> persistent Mol
bd mol wisp <proto>              # Proto -> ephemeral Wisp

# Connecting work graphs
bd mol bond A B                  # B depends on A (sequential)
bd mol bond A B --type parallel  # Organizational, no blocking
bd mol bond A B --type conditional  # B runs only if A fails

# Lifecycle
bd mol squash <id>               # Compress to digest (permanent record)
bd mol burn <id>                 # Discard without record

# Wisp management
bd mol wisp list                 # List wisps
bd mol wisp gc                   # Garbage collect old wisps
bd mol wisp gc --closed --force  # Purge all closed wisps

# Other
bd mol last-activity             # Recent activity timestamp
bd mol current                   # Current step readiness
```

### Common Patterns

**Sequential Pipeline:**
```bash
bd create "Pipeline" -t epic
bd create "Step 1" -t task --parent <pipeline>
bd create "Step 2" -t task --parent <pipeline>
bd dep add <step2> <step1>
bd dep add <step3> <step2>
```

**Parallel Fanout with Gate:**
```bash
bd create "Process files" -t epic
bd create "File A" -t task --parent <epic>
bd create "File B" -t task --parent <epic>
bd create "Aggregate" -t task --parent <epic>
bd dep add <aggregate> <fileA> --type waits-for
```

---

## 11. Hooks Integration

### Git Hooks

```bash
bd hooks install   # Install git hooks
```

Installs:
- **pre-commit** - Commits pending Dolt changes
- **post-merge** - Pulls remote Dolt changes after git merge

### Claude Code Hooks (via `bd setup claude`)

| Hook | Trigger | Action |
|------|---------|--------|
| SessionStart | Agent session begins | Runs `bd prime` (~1-2k tokens of context) |
| PreCompact | Before context compaction | Commits Dolt changes, runs `bd prime` |

### Hook Management

```bash
bd hooks install            # Install/update hooks
bd hooks run <hook-name>    # Run a specific hook manually
bd doctor                   # Check hook health
```

### Section Markers (v0.57+)

Hooks use section markers for safer updates. Beads manages its own section without overwriting existing hooks.

### Supported Hook Managers

- Native git hooks
- Lefthook
- Husky
- hk (hk.jdx.dev)

---

## 12. Protected Branch Workflow

For repos where `main` is protected and requires pull requests.

### Setup

```bash
bd init --branch beads-sync
```

### How It Works

Beads creates a git worktree for the sync branch. Issue changes are committed to `beads-sync` instead of `main`. Periodically merge to `main` via PR.

```
your-project/
  .git/
    beads-worktrees/
      beads-sync/          # Worktree (only .beads/ checked out)
  .beads/                  # Your main copy
  src/                     # Your code (untouched)
```

### Merging to Main

**Via PR (recommended):**
```bash
git push origin beads-sync
gh pr create --base main --head beads-sync --title "Update beads metadata"
```

**Direct merge (if allowed):**
```bash
git checkout main
git merge beads-sync --no-ff
git push
```

### Configuration

```bash
bd config set sync.branch beads-sync
bd config set sync.branch ""  # Disable sync branch
```

---

## 13. Multi-Agent Workflows

### Atomic Claiming

```bash
bd update <id> --claim --json  # Fails if already claimed
bd ready --assignee agent-name --json  # Query by assignee
```

### Database Redirects (Multi-Clone Sharing)

Multiple git clones can share a single beads database:

```bash
# In secondary clone
mkdir -p .beads
echo "../main-clone/.beads" > .beads/redirect
```

### Dolt Server Mode (Concurrent Access)

```bash
bd dolt set mode server
bd dolt start
```

Supports multiple agents writing simultaneously. No lock contention.

### Stealth Mode

```bash
bd init --stealth  # Local-only, no git operations
```

Perfect for personal agent use on shared projects without polluting the repo.

### Contributor Mode

```bash
bd init --contributor  # Routes planning issues to separate repo
```

For fork workflows where experimental work shouldn't be in PRs.

### Federation

```bash
bd config set federation.remote dolthub://org/beads
bd federation sync
```

Peer-to-peer sync across Dolt remotes.

---

## 14. MCP Server

### Installation

```bash
# Using uv (recommended)
uv tool install beads-mcp

# Using pip
pip install beads-mcp
```

### Claude Desktop Configuration

Add to `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "beads": {
      "command": "beads-mcp"
    }
  }
}
```

### Available MCP Tools

| Tool | Description |
|------|-------------|
| `beads_ready` | List unblocked issues |
| `beads_list` | List issues with filters |
| `beads_create` | Create new issue |
| `beads_show` | Show issue details |
| `beads_update` | Update issue fields |
| `beads_close` | Close an issue |
| `beads_claim` | Atomic claim (v0.57+) |
| `beads_sync` | Sync to git |
| `beads_dep_add` | Add dependency |
| `beads_dep_tree` | Show dependency tree |

### Trade-offs: CLI vs MCP

| Approach | Best For | Trade-offs |
|----------|----------|------------|
| CLI (hooks) | Claude Code, Cursor, editors with shell | Context efficient (~1-2k tokens) |
| MCP | Claude Desktop, Amp, no-shell environments | Higher token overhead (10-50k) |

---

## 15. Community Tools & Ecosystem

### Terminal UIs

| Tool | Author | Language | Description |
|------|--------|----------|-------------|
| **Mardi Gras** | matt-wright86 | Go | Parade-themed TUI with Gas Town orchestration |
| **bdui** | assimelha | Node.js | Real-time TUI with tree view, vim navigation |
| **perles** | zjrosen | Go | TUI with custom BQL query language |
| **beads.el** | ctietze | Elisp | Emacs UI |
| **lazybeads** | codegangsta | Go | Bubble Tea TUI |
| **bsv** | bglenden | Rust | Two-panel TUI with markdown rendering |
| **abacus** | ChrisEdwards | - | Terminal UI for visualization |

### Web UIs

| Tool | Author | Description |
|------|--------|-------------|
| **beads-ui** | mantoni | Local web with live updates, kanban (`npx beads-ui start`) |
| **BeadBoard** | zenchantlive | Windows-native control center (Next.js) |
| **beads-dashboard** | rhydlewis | Metrics dashboard with continuous improvement charts |
| **beads-kanban-ui** | AvivK5498 | Kanban board with git branch tracking |
| **beads-pm-ui** | qosha1 | Gantt chart with quarterly goals |
| **Beadspace** | cameronsjo | GitHub Pages dashboard, single HTML file |
| **beadsmap** | dariye | Interactive roadmap with Gantt, list, table views |

### Editor Extensions

| Tool | Editor | Author |
|------|--------|--------|
| **vscode-beads** | VS Code | jdillon |
| **ANAL Beads** | VS Code (Kanban) | sebcook-ctrl |
| **Beads-Kanban** | VS Code (Kanban) | davidcforbes |
| **opencode-beads** | OpenCode | joshuadavidthomas |
| **nvim-beads** | Neovim | joeblubaugh |
| **beads-manager** | JetBrains | developmeh |

### Native Apps

| Tool | Platforms | Description |
|------|-----------|-------------|
| **Beads Task-Issue Tracker** | macOS/Win/Linux | Cross-platform desktop (Tauri/Vue) |
| **Beadster** | macOS | Swift app |
| **Parade** | All (Electron) | Workflow orchestration with Kanban |
| **Beadbox** | macOS | Native dashboard with real-time sync (Tauri) |

### Orchestration

| Tool | Description |
|------|-------------|
| **Foolery** | Visual control surface for AI agent work with dependency-aware wave planning |
| **beads-compound** | Claude Code plugin with 28 agents, 26 commands, 15 skills |
| **beads-orchestration** | Multi-agent orchestration with supervisors on isolated branches |

### Coordination Servers

| Tool | Description |
|------|-------------|
| **BeadHub** | Open-source coordination server with work claiming, file reservation, inter-agent messaging |

### SDKs & Libraries

| Tool | Language | Description |
|------|----------|-------------|
| **beads-sdk** | TypeScript | Typed SDK with zero runtime deps |

### Data Integration

| Tool | Description |
|------|-------------|
| **jira-beads-sync** | Bidirectional Jira sync |
| **stringer** | Codebase archaeology -> JSONL for `bd import` |

---

## 16. Version History

### v0.58.0 (2026-03-02) -- Current

**Major:** SQLite backend completely removed. Dolt is the only backend. No CGO required.

- Persistent agent memory (`bd remember`, `bd memories`, `bd recall`, `bd forget`)
- `bd purge` -- delete closed ephemeral beads
- `bd show --current` -- active issue without ID
- `bd doctor validate` -- Dolt-native conflict detection
- `bd init --backend` -- explicit backend selection
- `--stdin` flag for `bd create`/`bd update`
- `bd preflight --check` -- CI alignment
- JSONL-to-Dolt migration script
- Fixed: Dolt CPU spikes, joinIter hangs, stale DB connection crashes, OSC escape leaks
- Removed: SQLite backend, go-sqlite3 dependency, all migration infrastructure

### v0.57.0 (2026-03-01)

**Major:** Hook migration system, SSH push/pull, circuit breaker, metadata system.

- `bd doctor --agent` mode
- SSH push/pull fallback with dual-surface remote management
- Section markers for git hooks (safer updates)
- Auto-close molecule root when all steps complete
- `bd backup` commands (init, sync, restore)
- `bd gc`, `bd compact`, `bd flatten` -- standalone lifecycle management
- Circuit breaker for Dolt server connections
- Config-driven metadata schema enforcement
- Metadata flags on `bd create` and `bd update`
- PreToolUse hook -- blocks interactive prompts in agent workflows
- `bd dolt remote` -- add, list, remove
- Auto-push to Dolt remote with 5-minute debounce
- Counter mode for sequential issue IDs
- `bd init --stealth`
- Linear Project sync, Jira V2 API
- Fixed: Shadow database prevention, auto-start suppression, phantom catalog entries

### v0.56.0 (2026-02-23)

**Breaking:** Embedded Dolt mode removed. Running Dolt SQL server required.

- Metadata query support in `bd list`, `bd search`, `bd query`
- Wisps table (Dolt-backed ephemeral issues)
- Batch auto-commit mode
- Standalone formula execution
- OpenTelemetry instrumentation
- Transaction infrastructure (RunInTransaction)
- Binary size: 168MB -> ~41MB
- Removed: JSONL sync pipeline, JSONL bootstrap, embedded Dolt driver

### v0.53.0 (2026-02-18)

- Dolt-in-Git sync (native push/pull via git remotes)
- `bd dolt start/stop` -- server lifecycle management
- `bd dolt commit` -- ergonomic Dolt commit
- Hosted Dolt support (TLS, authentication)
- `bd ready` pretty format
- Dolt compaction methods
- Removed: JSONL sync-branch pipeline, daemon infrastructure, 3-way merge engine

### v0.51.0 (2026-02-16)

**Massive 8-phase Dolt cleanup:** Removed daemon, 3-way merge, tombstones, JSONL sync, SQLite backend, storage factory, memory backend, provider abstraction.

### v0.50.0 (2026-02-14)

**Dolt becomes default backend.** Graph visualization overhaul. Plugin-based issue tracker framework with Linear and GitLab adapters.

### Pre-v0.50 (SQLite Era)

- v0.49.x: SQLite + JSONL sync pipeline
- v0.20+: Hash-based IDs (collision-free)
- v0.1: Initial release

---

## 17. Troubleshooting

### Common Issues

**`bd: command not found`**
```bash
export PATH="$PATH:$(go env GOPATH)/bin"
# Or reinstall via Homebrew: brew install beads
```

**Multiple bd binaries in PATH:**
```bash
which -a bd   # Find all copies
rm ~/go/bin/bd  # Remove old go install version
```

**`database is locked`**
```bash
ps aux | grep bd
kill <pid>
rm .beads/dolt/.dolt/lock
# Or use server mode: bd dolt set mode server
```

**`bd ready` shows nothing:**
```bash
bd blocked        # See what's blocked
bd dep tree <id>  # Check dependency tree
bd dep cycles     # Check for circular deps
```

**0 issues but data exists:**
```bash
bd doctor --server  # Check Dolt server
bd dolt status
cat .beads/metadata.json  # Verify database config
```

**Sandbox environments (Codex, containers):**
```bash
bd --sandbox ready                 # Sandbox mode (auto-detected)
bd import --force                  # Force metadata update
bd --allow-stale ready             # Emergency escape hatch
```

### Debug Environment Variables

| Variable | Purpose |
|----------|---------|
| `BD_DEBUG` | General debug logging |
| `BD_DEBUG_RPC` | RPC communication |
| `BD_DEBUG_SYNC` | Sync timestamp protection |
| `BD_DEBUG_ROUTING` | Issue routing |
| `BD_DEBUG_FRESHNESS` | Database file replacement |

```bash
BD_DEBUG=1 bd ready 2> debug.log
```

### Health Check

```bash
bd doctor              # Full health check
bd doctor --fix        # Auto-fix issues
bd doctor --agent      # AI agent diagnostics
bd doctor validate     # Dolt conflict detection
```

---

## 18. Articles & Tutorials

### By Steve Yegge (Author)

1. **[Introducing Beads](https://steve-yegge.medium.com/introducing-beads-a-coding-agent-memory-system-637d7d92514a)** -- Original introduction, "50 First Dates" problem
2. **[The Beads Revolution](https://steve-yegge.medium.com/the-beads-revolution-how-i-built-the-todo-system-that-ai-agents-actually-want-to-use-228a5f9be2a9)** -- Built in 6 days with Claude, epics, child issues
3. **[Beads Blows Up](https://steve-yegge.medium.com/beads-blows-up-a0a61bb889b4)** -- "Land the plane" protocol, session cleanup
4. **[Beads Best Practices](https://steve-yegge.medium.com/beads-best-practices-2db636b9760c)** -- Multi-agent coordination, when to file issues
5. **[Beads for Blobfish](https://steve-yegge.medium.com/beads-for-blobfish-80c7a2977ffa)** -- 3-minute introduction
6. **[The Future of Coding Agents](https://steve-yegge.medium.com/the-future-of-coding-agents-e9451a84207c)** -- Maturity reflections
7. **[Welcome to Gas Town](https://steve-yegge.medium.com/welcome-to-gas-town-4f25ee16dd04)** -- Multi-agent system on Beads

### Community Articles

- **[An Introduction to Beads](https://ianbull.com/posts/beads)** by Ian Bull -- Practical setup and workflow guide
- **[Beads: Memory for Your Coding Agents](https://paddo.dev/blog/beads-memory-for-coding-agents/)** by Paddo -- Deep dive on git storage
- **[From Beads to Tasks: Anthropic Productizes Agent Memory](https://paddo.dev/blog/from-beads-to-tasks/)** by Paddo -- Industry impact
- **[GasTown and the Two Kinds of Multi-Agent](https://paddo.dev/blog/gastown-two-kinds-of-multi-agent/)** by Paddo -- Multi-agent patterns
- **[Beads: A Git-Friendly Issue Tracker for AI Agents](https://betterstack.com/community/guides/ai/beads-issue-tracker-ai-agents/)** by Better Stack -- Getting started
- **[Introducing nvim-beads](https://joeblu.com/blog/2026_01_introducing-nvim-beads-manage-beads-in-neovim/)** by Joe Blubaugh -- Neovim plugin
- **[Solving Agent Context Loss: A Beads + Claude Code Workflow](https://jx0.ca/solving-agent-context-loss/)** -- Three custom skills (brainstorming, plan-to-epic, epic-executor) for structured agent workflows
- **[Three Tools to 10X Your Claude Code Development](https://medium.com/@leopold.odonnell/three-tools-to-10x-your-claude-code-development-today-a00755d05e77)** by Leo O'Donnell

### Official Documentation Hub

- **[DeepWiki](https://deepwiki.com/steveyegge/beads)** -- AI-powered documentation explorer
- **[Beads Documentation Site](https://steveyegge.github.io/beads/)** -- Official docs site

---

## 19. Best Practices & Anti-Patterns

### Best Practices

1. **Always use `--json` flag** for agent-consumed output
2. **Use `bd update --claim`** for atomic task claiming (prevents race conditions)
3. **Use `discovered-from` deps** when finding work mid-session
4. **Keep `bd ready` crisp** -- if it returns 47+ items, you've lost the value
5. **Kill sessions earlier** -- complete one task, land the plane, start fresh
6. **Task granularity** -- anything over ~2 minutes warrants its own issue
7. **Include detailed descriptions** when creating tasks -- enough context for any agent to pick up cold
8. **Always close completed work** -- blocked issues stay blocked forever otherwise
9. **Use `bd doctor`** periodically for health checks
10. **Commit beads before session end** -- `bd dolt push` or let auto-commit handle it

### Agent-Specific Rules

- **Never use `bd edit`** -- it opens an interactive editor ($EDITOR) that agents cannot use
- **Use stdin for special characters:** `echo 'Description with \`backticks\`' | bd create "Title" --stdin`
- **Always quote titles and descriptions** with double quotes
- **Use requirement language for deps** -- "Phase 2 needs Phase 1" not "Phase 1 comes before Phase 2"
- **Numbered steps don't create sequence** -- only explicit `bd dep add` does

### Anti-Patterns

- Using Beads for distant backlog items (use existing systems, import when moving to "now")
- Using it for simple single-session tasks (just do them)
- Using it as a central collaboration hub when team uses Jira/Linear
- Creating issues without descriptions (loses context after compaction)
- Letting `bd ready` grow too large
- Long sessions without checkpoints (context drift)
- Forgetting to sync at session end
- Orphaned wisps (accumulate if not squashed/burned)

### Known Friction Points

1. Claude doesn't proactively use Beads -- explicit prompting required
2. CLAUDE.md instructions fade by session end
3. Session handoff is manual (requires "check bd ready" prompt)
4. Long sessions cause context drift regardless of infrastructure
5. Collaboration requires explicit sync branch setup

---

## 20. Our Project Setup (Hypebase)

### Current Configuration

From the project CLAUDE.md and MEMORY.md:

- **bd v0.58.0** (Dolt backend) -- upgraded from v0.49.6 (SQLite) on 2026-03-04
- `.beads/` directory with Dolt database
- Old `issues.jsonl` (377 issues, legacy format) preserved but not imported

### Global Hooks (in `~/.claude/settings.json`)

| Hook | Trigger | Action |
|------|---------|--------|
| SessionStart | Agent session begins | `bd prime` |
| PreCompact | Before context compaction | `bd sync` |

### Project Hooks (in `.claude/settings.json`)

| Hook | Trigger | Action |
|------|---------|--------|
| TeammateIdle | Agent about to go idle | Checks in-progress beads remain open |
| TaskCompleted | CC task marked complete | Verifies beads issue closed |

### Dual Task System

- **Beads** = primary, persistent tracker (survives compaction, git-backed)
- **CC Tasks** (TaskCreate/TaskUpdate) = bridge for real-time team coordination
- CC task subjects must include beads ID: `"[hypebase-ai-XXXX] Title"`

### Issue ID Format

`hypebase-ai-XXXX` (project-prefixed hash)

### Key Commands Used

```bash
bd ready                                   # What can I work on now?
bd create "Title" -p 1 --description="..." --json  # Create a task
bd update <id> --status in_progress --json # Claim a task
bd close <id> --reason "..." --json        # Complete a task
bd dep add <child> <parent>                # Wire dependency
bd dolt commit -m "message"                # Commit beads state to Dolt
bd backup                                  # Export JSONL backup
bd remember <key> <value>                  # Store persistent memory
bd recall <key>                            # Retrieve memory (exact key)
bd memories                                # List all memories
bd forget <key>                            # Remove memory
bd show --current                          # Active issue
bd purge                                   # Delete closed wisps
bd gc                                      # Garbage collect
bd compact                                 # Lifecycle management
bd search <query>                          # Search issues
bd query <dsl>                             # Query with DSL
bd diff                                    # Show changes
bd history                                 # Version history
```

### Agent Team Rules

- Each CC task subject must include beads ID: `"[hypebase-ai-a1b2] Fix auth redirect loop"`
- TaskCompleted hook enforces beads closure before CC task can complete
- TeammateIdle hook ensures agents close their beads before going idle
- Beads = source of truth for what was done. CC tasks = coordination layer.

---

## Appendix A: Environment Variables

| Variable | Purpose |
|----------|---------|
| `BD_JSON` | Default JSON output |
| `BD_ACTOR` | Override actor identity |
| `BD_DEBUG` | Enable debug logging |
| `BD_DEBUG_RPC` | Debug RPC communication |
| `BD_DEBUG_SYNC` | Debug sync operations |
| `BD_DEBUG_ROUTING` | Debug issue routing |
| `BD_DEBUG_FRESHNESS` | Debug database detection |
| `BD_NO_PUSH` | Skip remote push |
| `BD_SYNC_MODE` | Sync mode |
| `BD_CONFLICT_STRATEGY` | Conflict resolution |
| `BD_DOLT_AUTO_COMMIT` | Auto Dolt commit |
| `BD_DOLT_AUTO_PUSH` | Auto Dolt push |
| `BD_CREATE_REQUIRE_DESCRIPTION` | Require description |
| `BD_BACKUP_ENABLED` | Enable periodic backup |
| `BEADS_DIR` | Override .beads directory |
| `BEADS_DB` | Override database path (deprecated) |
| `BEADS_ACTOR` | Actor identity (MCP compat) |
| `BEADS_SYNC_BRANCH` | Override sync branch |

## Appendix B: File Structure

```
.beads/
  dolt/                  # Dolt database (gitignored)
    sql-server.pid       # Server PID (gitignored)
    sql-server.log       # Server logs (gitignored)
  config.yaml            # Project config
  metadata.json          # Database metadata
  backup/                # JSONL backups (if enabled)
  redirect               # Points to shared database (multi-clone)
  .gitignore             # Auto-generated
```

## Appendix C: Sources

- [GitHub Repository](https://github.com/steveyegge/beads)
- [README.md](https://github.com/steveyegge/beads/blob/main/README.md)
- [AGENT_INSTRUCTIONS.md](https://github.com/steveyegge/beads/blob/main/AGENT_INSTRUCTIONS.md)
- [CHANGELOG.md](https://github.com/steveyegge/beads/blob/main/CHANGELOG.md)
- [docs/INSTALLING.md](https://github.com/steveyegge/beads/blob/main/docs/INSTALLING.md)
- [docs/ADVANCED.md](https://github.com/steveyegge/beads/blob/main/docs/ADVANCED.md)
- [docs/CONFIG.md](https://github.com/steveyegge/beads/blob/main/docs/CONFIG.md)
- [docs/FAQ.md](https://github.com/steveyegge/beads/blob/main/docs/FAQ.md)
- [docs/TROUBLESHOOTING.md](https://github.com/steveyegge/beads/blob/main/docs/TROUBLESHOOTING.md)
- [docs/PROTECTED_BRANCHES.md](https://github.com/steveyegge/beads/blob/main/docs/PROTECTED_BRANCHES.md)
- [docs/QUICKSTART.md](https://github.com/steveyegge/beads/blob/main/docs/QUICKSTART.md)
- [docs/CLI_REFERENCE.md](https://github.com/steveyegge/beads/blob/main/docs/CLI_REFERENCE.md)
- [docs/MOLECULES.md](https://github.com/steveyegge/beads/blob/main/docs/MOLECULES.md)
- [docs/COMMUNITY_TOOLS.md](https://github.com/steveyegge/beads/blob/main/docs/COMMUNITY_TOOLS.md)
- [docs/COPILOT_INTEGRATION.md](https://github.com/steveyegge/beads/blob/main/docs/COPILOT_INTEGRATION.md)
- [ARTICLES.md](https://github.com/steveyegge/beads/blob/main/ARTICLES.md)
- [Ian Bull - An Introduction to Beads](https://ianbull.com/posts/beads/)
- [JX0 - Solving Agent Context Loss](https://jx0.ca/solving-agent-context-loss/)
- [Beads Documentation Site](https://steveyegge.github.io/beads/integrations/claude-code)
