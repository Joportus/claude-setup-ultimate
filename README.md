# The Ultimate Claude Code Setup

> Transform any Claude Code installation from default to expert-level with 8 progressive, self-updating prompts.

**One script. Any project. Expert-level configuration in minutes.**

This system analyzes your repository, detects your tech stack, and configures Claude Code with production-grade settings, hooks, quality gates, MCP servers, agent teams, and performance optimizations -- all tailored to your project.

---

## Table of Contents

- [How It Works](#how-it-works)
- [Quick Start](#quick-start)
- [Manual Usage](#manual-usage)
- [The 8 Prompts](#the-8-prompts)
- [Prerequisites](#prerequisites)
- [Configuration Options](#configuration-options)
- [What Gets Configured](#what-gets-configured)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [Research and Sources](#research-and-sources)
- [Contributing](#contributing)
- [License](#license)

---

## How It Works

The system uses a sequence of **8 copy-paste prompts** that you run inside Claude Code. Each prompt handles one domain (settings, hooks, beads, teams, MCP, etc.) and builds on the previous ones.

Every prompt follows three principles:

1. **Self-updating** -- Before making changes, it fetches the latest official documentation from `code.claude.com` so it never relies on stale information.
2. **Repository-aware** -- It detects your tech stack (language, framework, package manager, existing tools) and adapts all configuration to match.
3. **Idempotent** -- Safe to run multiple times. It checks what already exists and only adds what is missing.

The prompts can be run individually (copy-paste one at a time) or automated via the included shell script.

### Dependency Graph

```
P1: Discovery --------+
                       +--> P2: Foundation --+--> P3: Hooks --+--> P4: Beads --> P5: Teams
                       |                     |                |
                       |                     +----------------+--> P6: MCP & Tools
                       |
                       +--------------------------------------------> P7: System Optimization

P8: Verification (runs after any/all of the above)
```

**Hard dependencies** (must run in order): P2 before P3, P3 before P4, P4 before P5.
**Soft dependencies** (recommended but not required): P1 before all others, P6 and P7 are independent.

---

## Quick Start

### Option 1: Automated (recommended)

```bash
# 1. Clone or download
git clone https://github.com/Joportus/claude-setup-ultimate.git
cd claude-setup-ultimate

# 2. Make executable
chmod +x prompts/setup-claude-ultimate.sh

# 3. Run from your project directory
cd /path/to/your/project
/path/to/claude-setup-ultimate/prompts/setup-claude-ultimate.sh
```

### Option 2: Manual (copy-paste)

```bash
# Open Claude Code in your project
cd /path/to/your/project
claude

# Copy-paste Prompt 1 from prompts/core-setup-prompts.md
# Then Prompt 2, etc.
```

---

## Manual Usage

If you prefer to run prompts individually:

1. Open `prompts/core-setup-prompts.md` (Prompts 1-5)
2. Open `prompts/advanced-setup-prompts.md` (Prompts 6-8)
3. Start Claude Code in your project directory (`claude`)
4. Copy the entire text of Prompt 1 and paste it into Claude Code
5. Wait for it to complete, then paste Prompt 2, and so on
6. Skip any prompt you do not want (e.g., skip P4 if you do not want Beads)

**Tips for manual usage:**
- Each prompt is self-contained -- it includes the self-update URLs and all instructions
- You can run prompts across separate sessions (they detect existing state)
- If a prompt partially fails, just paste it again -- it will pick up where it left off

---

## The 8 Prompts

### Core Prompts (prompts/core-setup-prompts.md)

| # | Name | What It Does | Time |
|---|------|-------------|------|
| **P1** | Discovery and Analysis | Scans your repo, detects stack (language, framework, package manager, CI, testing, Docker), produces a JSON report with recommendations | ~30s |
| **P2** | Foundation | Creates/updates `~/.claude/settings.json` (global), `.claude/settings.json` (project), and `CLAUDE.md` with stack-appropriate permissions, security rules, and project documentation scaffold | ~60s |
| **P3** | Hooks and Quality Gates | Installs hook scripts (`.claude/hooks/`) for dangerous command blocking, auto-linting after edits, session start, desktop notifications, pre-compaction state save, and stop summaries | ~45s |
| **P4** | Beads Integration | Installs the Beads issue tracker (`bd`), initializes it for the project, configures session/compaction hooks, and adds task tracking instructions to CLAUDE.md | ~45s |
| **P5** | Agent Teams | Enables multi-agent workflows, creates agent definition templates (`.claude/agents/`), configures team coordination hooks (TeammateIdle, TaskCompleted), and adds orchestration rules to CLAUDE.md | ~30s |

### Advanced Prompts (prompts/advanced-setup-prompts.md)

| # | Name | What It Does | Time |
|---|------|-------------|------|
| **P6** | MCP and External Tools | Installs essential MCP servers (Context7 for library docs, GitHub for PR management, Playwright for browser testing), plus stack-specific servers and skills | ~60s |
| **P7** | System Optimization | Optimizes shell startup time (target: under 100ms), git configuration, creates `.claudeignore` for faster file scanning, configures terminal settings | ~30s |
| **P8** | Verification and Testing | Runs a comprehensive check across all configured components, validates hooks work correctly, tests MCP servers, measures performance, and generates a scored report | ~45s |

---

## Prerequisites

### Required

| Tool | Minimum Version | Install |
|------|----------------|---------|
| **Claude Code CLI** | Latest | `npm install -g @anthropic-ai/claude-code` (or `bun install -g @anthropic-ai/claude-code` / `npx @anthropic-ai/claude-code`) |
| **Git** | 2.x | Included with most systems |
| **Node.js or Bun** | Node 18+ / Bun 1.x+ | [nodejs.org](https://nodejs.org) or [bun.sh](https://bun.sh) |

### Recommended

| Tool | Purpose | Install |
|------|---------|---------|
| **jq** | JSON processing in hook scripts | `brew install jq` / `apt install jq` |
| **curl** | Fetching latest docs (self-update) | Usually pre-installed |

### Optional (installed by specific prompts)

| Tool | Installed By | Purpose |
|------|-------------|---------|
| **Beads (`bd`)** | P4 | Git-backed issue tracker for persistent task management |
| **MCP Servers** | P6 | External tool integrations (Context7, GitHub, Playwright) |

---

## Configuration Options

### Script Flags

```bash
# Run all 8 prompts (default)
./setup-claude-ultimate.sh

# Run only a specific prompt
./setup-claude-ultimate.sh --prompt 3

# Start from a specific prompt (already ran 1-2)
./setup-claude-ultimate.sh --from 3

# Skip specific prompts
./setup-claude-ultimate.sh --skip 4 --skip 7

# Only run verification (P8)
./setup-claude-ultimate.sh --verify-only

# Preview what would happen without making changes
./setup-claude-ultimate.sh --dry-run

# Show full Claude output for each step
./setup-claude-ultimate.sh --verbose

# Non-interactive mode (no confirmation prompts)
./setup-claude-ultimate.sh --yes

# Fetch latest prompt versions from GitHub before running
./setup-claude-ultimate.sh --fetch-latest
```

### Skipping Prompts

Not every project needs every feature. Common skip patterns:

| Scenario | Command |
|----------|---------|
| Solo developer, no teams | `--skip 5` |
| No issue tracking needed | `--skip 4 --skip 5` |
| Already have optimized shell | `--skip 7` |
| Just want hooks and settings | `--prompt 2` then `--prompt 3` |
| Quick verification of existing setup | `--verify-only` |

---

## What Gets Configured

After running all 8 prompts, your project will have:

### Files Created/Updated

```
~/.claude/
  settings.json              # Global user settings (permissions, env vars)

your-project/
  CLAUDE.md                  # Project instructions (adapted to your stack)
  .claudeignore              # File exclusions for faster scanning
  .claude/
    settings.json            # Project settings (permissions, hooks)
    hooks/
      session-start.sh       # Session initialization
      block-dangerous.sh     # Dangerous command blocking
      post-tool-lint.sh      # Auto-lint after file edits
      pre-compact.sh         # State preservation before compaction
      stop-summary.sh        # End-of-session summary
      notification.sh        # Desktop notifications
      teammate-idle-check.sh # Agent team coordination (if P5)
      task-completed-check.sh# Agent team coordination (if P5)
    agents/                  # Agent team definitions (if P5)
      researcher.md
      implementer.md
  .beads/                    # Beads database (if P4)
  .mcp.json                  # MCP server config (if P6)
```

### Capabilities Enabled

| Category | What You Get |
|----------|-------------|
| **Security** | Dangerous command blocking, secret file protection, permission rules tailored to your stack |
| **Quality** | Auto-formatting on every edit, pre-commit quality gates, CI-mirrored checks |
| **Productivity** | Desktop notifications, session status on startup, state preservation across compactions |
| **Task Management** | Persistent issue tracking that survives context compaction (Beads) |
| **Multi-Agent** | Team orchestration patterns, coordination hooks, agent definitions |
| **Tools** | Library documentation (Context7), GitHub integration, browser testing (Playwright) |
| **Performance** | Optimized shell startup, faster git operations, reduced file scanning |

---

## Troubleshooting

### Script fails on prerequisite check

**Problem:** `Missing prerequisites: claude`

**Solution:** Install the Claude Code CLI:
```bash
npm install -g @anthropic-ai/claude-code
```

### A prompt fails partway through

**Problem:** Claude encounters an error during one of the 8 prompts.

**Solution:**
- The script will ask whether to retry, skip, or abort
- Most prompts are idempotent -- just retry
- Check the log file at `/tmp/claude-setup-logs/prompt-N.log` for details
- If the issue persists, skip the prompt and continue. Come back to it later.

### Hooks are not firing

**Problem:** Configured hooks do not seem to run.

**Solution:**
1. Check that hook scripts are executable: `chmod +x .claude/hooks/*.sh`
2. Verify the hooks block in `.claude/settings.json` is valid JSON: `cat .claude/settings.json | jq .hooks`
3. Test a hook manually: `echo '{}' | .claude/hooks/session-start.sh`
4. Restart Claude Code to pick up settings changes

### Shell startup is still slow

**Problem:** P7 did not improve shell startup time.

**Solution:**
1. Measure directly: `time zsh -i -c exit`
2. Profile your shell: `zsh -i -c "zprof" 2>/dev/null` (add `zmodload zsh/zprof` to top of `.zshrc`)
3. The most common culprits: nvm, conda init, oh-my-zsh plugins
4. Consider creating a minimal ZDOTDIR just for Claude (P7 attempts this)

### Beads installation fails

**Problem:** `bd` command not found after P4.

**Solution:**
```bash
# Homebrew (macOS/Linux)
brew install steveyegge/tap/beads

# Or npm global install
npm install -g @beads/bd

# Or Bun global install
bun install -g --trust @beads/bd

# Verify
bd version
```

### MCP server not responding

**Problem:** `claude mcp list` shows the server but it is not working.

**Solution:**
1. Check for API keys: some servers (GitHub) need tokens set in environment
2. Test the MCP endpoint: Context7 uses HTTP transport at `https://mcp.context7.com/mcp` (not stdio)
3. Remove and re-add: `claude mcp remove context7 && claude mcp add context7 --transport http https://mcp.context7.com/mcp`

---

## FAQ

### Is this safe to run on my existing project?

Yes. Every prompt follows a strict protocol:

1. **Read** existing configuration before making changes
2. **Merge** new settings with existing ones (never replace)
3. **Backup** configuration files before modifying them
4. **Log** all changes so you can review what was modified

The `--dry-run` flag lets you preview everything before committing.

### Do I need to run all 8 prompts?

No. Each prompt is designed to be useful on its own. Common minimal setups:

- **P1 + P2 + P3** = Settings, permissions, hooks (the essentials)
- **P1 + P2 + P3 + P6** = Essentials plus MCP tools
- **P1 through P5** = Full setup minus external tools and optimization

### Will this overwrite my existing CLAUDE.md?

No. If `CLAUDE.md` exists, the prompts extend it with missing sections. Your existing content is preserved.

### Does this work with projects that are not JavaScript/TypeScript?

Yes. The system supports any tech stack. P1 detects your stack, and all subsequent prompts adapt:

| Stack | Package Manager | Linter | Test Runner |
|-------|----------------|--------|-------------|
| JavaScript/TypeScript | npm/yarn/pnpm/bun | ESLint/Biome | Jest/Vitest/Bun test |
| Python | pip/uv/poetry | Ruff/Flake8 | pytest |
| Rust | Cargo | Clippy | cargo test |
| Go | Go modules | golangci-lint | go test |
| Ruby | Bundler | RuboCop | RSpec |

### Can I run this again if Claude Code updates?

Yes. The prompts are idempotent and self-updating. Running them again after a Claude Code update will:
1. Fetch the latest docs (catching any new features or changes)
2. Check what is already configured
3. Only update what is outdated or missing

### How is this different from just reading the Claude Code docs?

This system synthesizes information from:
- Official Anthropic documentation
- Official blog posts and engineering guides
- Community resources (26,000+ star repositories)
- Real-world production configurations
- 12 deep-dive research files totaling 16,000+ lines

It distills all of this into actionable, automated configuration -- not just documentation to read.

### What does the self-updating mechanism do?

Every prompt begins by fetching the latest docs from `code.claude.com`. If the online documentation says something different from what the prompt contains, the prompt defers to the online version. This means even if you downloaded the prompts months ago, they will still produce up-to-date configuration.

---

## Research and Sources

This system is built on extensive research. The raw research files are available in the `raw/` and `synthesis/` directories for those who want the deep details.

### Research Files

| File | Lines | Topic |
|------|-------|-------|
| `raw/01-beads-deep-dive.md` | 1,553 | Beads issue tracker internals and patterns |
| `raw/02-agent-teams-deep-dive.md` | 1,657 | Multi-agent orchestration patterns |
| `raw/03-hooks-system-deep-dive.md` | 1,951 | All 18 hook events with examples |
| `raw/04-settings-permissions-claudemd.md` | 1,627 | Configuration system deep dive |
| `raw/05-external-tools-repos.md` | 620 | MCP servers, skills, plugins ecosystem |
| `raw/06-community-resources.md` | 797 | Community guides and resources |
| `raw/07-system-optimizations.md` | 1,136 | Shell, git, terminal performance |
| `raw/08-token-optimization.md` | 1,095 | Context window and token efficiency |
| `raw/09-mcp-servers-ecosystem.md` | 937 | MCP server ecosystem analysis |
| `raw/10-context-memory-persistence.md` | 1,146 | Memory and persistence patterns |
| `raw/11-dx-workflows-automation.md` | 1,581 | Developer experience workflows |
| `raw/12-security-permissions.md` | 1,835 | Security model and permissions |

### Synthesis Documents

| File | Purpose |
|------|---------|
| `synthesis/00-MASTER-SYNTHESIS.md` | Consolidated findings from all 12 research files |
| `synthesis/01-PROMPT-ARCHITECTURE.md` | Architecture blueprint for the 8-prompt sequence |

### Key External Sources

| Source | Description |
|--------|-------------|
| [Claude Code Official Docs](https://code.claude.com/docs) | Canonical feature reference |
| [Anthropic Engineering Blog](https://www.anthropic.com/engineering/claude-code-best-practices) | Official best practices |
| [Cranot/claude-code-guide](https://github.com/Cranot/claude-code-guide) | Auto-updated community guide (synced every 2 days) |
| [awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) | Ecosystem directory (26,000+ stars) |
| [Beads](https://github.com/steveyegge/beads) | Git-backed issue tracker for AI agents |
| [MCP Server Registry](https://registry.modelcontextprotocol.io) | Official MCP server directory |

---

## Contributing

Contributions welcome. The most valuable contributions are:

1. **Testing on different stacks** -- Run the prompts on Python, Rust, Go, Ruby, or Java projects and report what works or does not
2. **Prompt improvements** -- Better detection logic, missing edge cases, clearer instructions
3. **New hook scripts** -- Useful hook scripts for common workflows
4. **MCP server recommendations** -- Tested MCP servers worth adding to P6

### How to contribute

1. Fork the repository
2. Test changes against a real project
3. Ensure prompts remain idempotent (safe to run twice)
4. Submit a pull request with a description of what you tested

---

## License

MIT License. See [LICENSE](LICENSE) for details.

---

Built on 16,000+ lines of research from official Anthropic documentation, community best practices, and real-world production configurations.
