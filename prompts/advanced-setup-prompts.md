# Advanced Setup Prompts (6-8) -- The Ultimate Claude Code Configuration

> Prompts 6-8 of 8. For Prompts 1-5, see `core-setup-prompts.md`.
> Version: 1.0.0 | Date: 2026-03-05 | Self-updating: Each prompt checks online docs before acting.

---

## PROMPT 6: MCP Servers & External Tools

---

```
# Claude Code Setup -- Prompt 6: MCP Servers & External Tools
# Version: 1.0.0 | Date: 2026-03-05
# Self-updating: Fetches latest MCP docs before configuring

You are configuring MCP (Model Context Protocol) servers and external developer tools for this Claude Code project. MCP servers extend Claude Code with external capabilities -- database access, documentation lookup, browser automation, and more.

## Step 0: Self-Update

Before doing ANYTHING, fetch the latest MCP documentation to ensure your knowledge is current:

1. Fetch https://code.claude.com/docs/en/mcp and read the current MCP configuration reference
2. Fetch https://registry.modelcontextprotocol.io to check for new recommended servers
3. If Context7 is already configured, use it: "How to configure MCP servers in Claude Code? use context7"

If any fetch fails, proceed with your built-in knowledge -- it is comprehensive as of March 2026.

## Step 1: Detect Current State

Run these commands and analyze the results:

1. `claude mcp list` -- existing MCP servers
2. `cat .mcp.json 2>/dev/null` -- project-level MCP config
3. `cat ~/.claude.json 2>/dev/null | jq '.mcpServers // empty'` -- user-level config
4. Detect the project stack by reading package.json, Cargo.toml, pyproject.toml, go.mod, etc.
5. Check for API keys: `env | grep -iE '(GITHUB|SUPABASE|BRAVE|SENTRY|OPENAI).*TOKEN\|KEY' | sed 's/=.*/=***/'`

Report what you find before proceeding.

## Step 2: Install Essential MCP Servers

These servers benefit EVERY project. Install any that are missing:

### A. Context7 (Documentation Lookup -- HIGHEST VALUE)

Provides up-to-date, version-specific documentation for any library. Eliminates hallucinated APIs.

```bash
# HTTP transport (recommended -- no API key needed)
claude mcp add --scope user --transport http context7 https://mcp.context7.com/mcp
```

Usage: Add "use context7" to any prompt, e.g., "How do I use React Server Components? use context7"

### B. GitHub (Issues, PRs, Code Search)

```bash
# HTTP transport with OAuth
claude mcp add --transport http github https://api.githubcopilot.com/mcp/
# Then run /mcp inside Claude Code to authenticate via browser
```

### C. Playwright (Browser Automation & Testing)

```bash
claude mcp add playwright --transport stdio -- npx -y @playwright/mcp@latest
```

## Step 3: Install Stack-Specific Servers

Based on the detected stack, install ONLY the relevant servers:

| Detected | Server | Command |
|----------|--------|---------|
| Supabase (SUPABASE_* env vars or @supabase/) | Supabase | `claude mcp add --transport http supabase https://mcp.supabase.com/mcp` |
| PostgreSQL connection string in env | PostgreSQL | `claude mcp add postgres --transport stdio -- npx -y @modelcontextprotocol/server-postgres "$DATABASE_URL"` |
| Sentry DSN in env or @sentry/ in deps | Sentry | `claude mcp add --transport http sentry https://mcp.sentry.dev/mcp` |
| Vercel project (vercel.json or .vercel/) | Vercel | `claude mcp add --transport http vercel https://mcp.vercel.com/` |
| Stripe keys in env or stripe in deps | Stripe | `claude mcp add --transport http stripe https://mcp.stripe.com` |
| Linear / Jira / Asana in workflow | PM tool | Use the appropriate HTTP MCP server |
| Slack integration needed | Slack | `claude mcp add --transport http slack https://mcp.slack.com/mcp` |

Do NOT install servers the project does not use. Each server adds token overhead (~600-800 tokens per tool definition). Keep active servers to 5-6 maximum.

## Step 4: Create Project .mcp.json

If team members should share MCP config, create `.mcp.json` at the project root. Only include servers that the WHOLE team needs (no personal API keys):

```json
{
  "mcpServers": {
    "context7": {
      "type": "http",
      "url": "https://mcp.context7.com/mcp"
    },
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest"]
    }
  }
}
```

For servers requiring credentials, use environment variable expansion:

```json
{
  "mcpServers": {
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres", "${DATABASE_URL}"]
    }
  }
}
```

## Step 5: Install External Developer Tools

Check if these high-value tools are installed. Offer to install any that are missing:

### A. ccusage -- Token Cost Tracking (11K+ GitHub stars)

```bash
# Run without installing
bunx ccusage@latest daily
# Or install globally
bun install -g ccusage
# Commands: daily, monthly, session, blocks, statusline
```

### B. Claude Squad -- Multi-Session Manager

```bash
# Install
go install github.com/smtg-ai/claude-squad@latest
# Or via Homebrew
brew install claude-squad
```

Enables running multiple Claude Code sessions in parallel with a tmux-based TUI.

### C. MCP Server Selector -- TUI for Managing Servers

```bash
# Clone and use
git clone https://github.com/henkisdabro/Claude-Code-MCP-Server-Selector.git
cd Claude-Code-MCP-Server-Selector && chmod +x mcp-selector.sh
./mcp-selector.sh
```

Interactive terminal UI for enabling/disabling MCP servers per session.

### D. Graphite -- PR Stacking (Eliminates Review Bottlenecks)

```bash
# Install via Homebrew (macOS/Linux)
brew install withgraphite/tap/graphite
# Or via npm
npm install -g @withgraphite/graphite-cli

# Authenticate
gt auth --token <your-graphite-token>

# Initialize in repo
gt init
```

Graphite enables PR stacking: submit dependent PRs in sequence without waiting for reviews. AI agent teams can create stacked PRs for multi-part features. Dramatically reduces time-to-merge when combined with automated review.

### E. Adversarial Code Review Pattern

Create a custom review agent in `.claude/agents/` that reviews other agents' work:

```yaml
# .claude/agents/code-reviewer.md
---
name: code-reviewer
description: Adversarial code review agent that catches issues other agents miss
tools: [Read, Glob, Grep, Bash, WebFetch]
---

You are an adversarial code reviewer. Your job is to find problems that the implementing agent missed.

Review the changes for:
1. Security vulnerabilities (injection, XSS, auth bypass)
2. Performance regressions (N+1 queries, missing indexes, unbounded loops)
3. Missing error handling and edge cases
4. Test coverage gaps
5. Architecture violations (wrong layer, circular deps)
6. False positives from other AI reviewers

Be skeptical. Challenge assumptions. If you find nothing wrong, say so -- but look hard first.
```

Use via: `claude --agent code-reviewer -p "Review changes in the last commit"`

## Step 6: Configure MCP Performance

Add to the project's `.claude/settings.json` or `~/.claude/settings.json`:

```json
{
  "env": {
    "ENABLE_TOOL_SEARCH": "auto:5",
    "MCP_TIMEOUT": "10000",
    "MAX_MCP_OUTPUT_TOKENS": "25000"
  }
}
```

- `ENABLE_TOOL_SEARCH=auto:5`: Defers MCP tool loading when definitions exceed 5% of context (saves ~85% context)
- `MCP_TIMEOUT=10000`: 10-second timeout for slow server startups
- `MAX_MCP_OUTPUT_TOKENS=25000`: Cap individual server output to prevent context flooding

## Step 7: Configure Permissions for MCP Tools

Add MCP tool permissions to `.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "mcp__context7__*",
      "mcp__playwright__*",
      "mcp__github__*"
    ]
  }
}
```

Only allow tools you trust. Use deny rules for dangerous operations:

```json
{
  "permissions": {
    "deny": [
      "mcp__*__delete_*",
      "mcp__*__drop_*"
    ]
  }
}
```

## Step 8: Verify

Run these checks and report results:

1. `claude mcp list` -- all servers appear and show status
2. Test Context7: In Claude Code, ask "What is the latest Next.js App Router API? use context7"
3. Test Playwright: `claude mcp get playwright` shows available tools
4. No API key errors in any server
5. `/context` shows MCP tools consuming < 10% of context window
6. Token tracking works: `bunx ccusage@latest daily` (if installed)

Report the full list of installed servers and their status.

## Key Resources for Ongoing Discovery

- Official MCP Registry: https://registry.modelcontextprotocol.io
- MCP.so: https://mcp.so (18,000+ community servers)
- Smithery: https://smithery.ai (automated installation guides)
- Anthropic Registry API: https://api.anthropic.com/mcp-registry/v0/servers?version=latest
- awesome-mcp-servers: https://github.com/punkpeye/awesome-mcp-servers
```

---

## PROMPT 7: System & Performance Optimization

---

```
# Claude Code Setup -- Prompt 7: System & Performance Optimization
# Version: 1.0.0 | Date: 2026-03-05
# Self-updating: Checks latest optimization guides before acting

You are a systems performance engineer optimizing this machine for maximum Claude Code throughput. Every millisecond saved on shell startup, git operations, or filesystem access compounds across hundreds of tool invocations per session. A typical session runs 200-500 Bash tool calls -- saving 100ms per call saves 20-50 seconds per session.

## Step 0: Self-Update

Fetch the latest optimization guidance:

1. Fetch https://code.claude.com/docs/en/best-practices for current performance recommendations
2. Fetch https://code.claude.com/docs/en/costs for token optimization strategies
3. If Context7 is configured: "Claude Code performance optimization best practices? use context7"

If fetches fail, proceed with built-in knowledge.

## Step 1: Baseline Measurements

Run ALL of these and record the results. We will compare after optimization:

```bash
# Shell startup time (target: < 100ms)
echo "Shell startup:" && time zsh -i -c exit 2>&1

# Git status speed (target: < 100ms)
echo "Git status:" && time git status --short 2>&1

# Current file descriptor limit
echo "File descriptors:" && ulimit -n

# OS detection
echo "OS:" && uname -s && sw_vers 2>/dev/null || cat /etc/os-release 2>/dev/null

# Terminal emulator
echo "Terminal:" && echo "${TERM_PROGRAM:-unknown}"

# Current shell config size
echo "Shell config:" && wc -l ~/.zshrc 2>/dev/null || wc -l ~/.bashrc 2>/dev/null

# Memory pressure (macOS)
memory_pressure 2>/dev/null | head -5 || free -h 2>/dev/null | head -3
```

Report all baselines before proceeding.

## Step 2: Shell Optimization (HIGHEST IMPACT)

Claude Code spawns a new shell for EVERY Bash tool call. Reducing shell startup from ~770ms to ~40ms is a 97% improvement that compounds across hundreds of invocations.

### A. Create Minimal ZDOTDIR for Claude Code

This gives Claude Code a fast, stripped-down shell while preserving your normal shell experience:

```bash
# Create directory
mkdir -p ~/.config/zsh-claude

# Create minimal .zshrc (target: < 50ms startup)
cat > ~/.config/zsh-claude/.zshrc << 'SHELLEOF'
# Minimal shell for Claude Code -- fast startup
[[ $- != *i* ]] && return

# Essential PATH only (detect and include package manager paths)
export PATH="$HOME/.bun/bin:$HOME/.local/bin:$HOME/.cargo/bin:$HOME/go/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# Minimal prompt
PS1='%~ %# '

# History
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt SHARE_HISTORY HIST_IGNORE_DUPS

# Fast completions (cached, no security check)
autoload -Uz compinit && compinit -C

# File descriptor limit
ulimit -n 65536 2>/dev/null
SHELLEOF
```

Add to Claude Code settings (`~/.claude/settings.json`):

```json
{
  "env": {
    "ZDOTDIR": "~/.config/zsh-claude"
  }
}
```

**Verification**: `ZDOTDIR=~/.config/zsh-claude time zsh -i -c exit` -- should be < 50ms.

### B. If You Prefer Not to Use ZDOTDIR

Optimize your existing `.zshrc` instead:

1. Audit what is slow: `zsh -xv 2>&1 | ts -i '%.s' | head -200` (needs `moreutils`)
2. Replace Oh-My-Zsh (300-700ms) with Zinit turbo mode (30-80ms) or no framework (10-40ms)
3. Defer plugins with `zsh-defer`: `git clone https://github.com/romkatv/zsh-defer.git ~/.zsh/plugins/zsh-defer`
4. Cache completions: only regenerate `.zcompdump` once per day
5. Lazy-load version managers (nvm, rbenv, pyenv)

## Step 3: Git Optimization (96% FASTER git status)

```bash
# Enable filesystem monitor daemon (biggest single improvement)
git config --global core.fsmonitor true

# Cache untracked file results
git config --global core.untrackedCache true

# Enable commit graph for faster log/merge-base
git config --global fetch.writeCommitGraph true
git config --global core.commitGraph true

# Enable many-files optimization bundle (fsmonitor + untrackedCache + index v4)
git config --global feature.manyFiles true

# Parallel index operations
git config --global index.threads true

# Start background maintenance on this repo (hourly prefetch, daily repack)
git maintenance start

# Skip expensive ahead/behind calculation in status
git config --global status.aheadBehind false
```

**Impact**: `git status` drops from ~970ms to ~40ms. `git log` operations become near-instant with commit graph.

## Step 4: Filesystem Optimization

### A. macOS: Spotlight Exclusions

Spotlight indexing dev directories causes I/O contention:

```bash
# Exclude build artifacts from Spotlight indexing
for dir in node_modules .next .turbo dist build .venv target vendor __pycache__; do
  [ -d "$dir" ] && touch "$dir/.metadata_never_index" 2>/dev/null
done
```

### B. macOS: Time Machine Exclusions

```bash
# Exclude build directories from Time Machine backups
for dir in node_modules .next .turbo dist build; do
  [ -d "$dir" ] && tmutil addexclusion "$dir" 2>/dev/null
done
```

### C. File Descriptor Limits

macOS default is only 256 -- far too low for dev tools:

```bash
# Increase for current session
ulimit -n 65536

# Make permanent: add to your shell config
grep -q 'ulimit -n 65536' ~/.zshrc 2>/dev/null || echo 'ulimit -n 65536 2>/dev/null' >> ~/.zshrc
```

For a system-wide permanent fix (survives reboot), create `/Library/LaunchDaemons/limit.maxfiles.plist`:

```bash
sudo tee /Library/LaunchDaemons/limit.maxfiles.plist << 'PLISTEOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key><string>limit.maxfiles</string>
    <key>ProgramArguments</key>
    <array>
      <string>launchctl</string><string>limit</string>
      <string>maxfiles</string><string>65536</string><string>524288</string>
    </array>
    <key>RunAtLoad</key><true/>
  </dict>
</plist>
PLISTEOF
sudo launchctl load -w /Library/LaunchDaemons/limit.maxfiles.plist
```

### D. Linux: inotify Watch Limits

```bash
# Increase file watcher limits (Linux only)
if [ -f /proc/sys/fs/inotify/max_user_watches ]; then
  echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf
  echo "fs.inotify.max_user_instances=1024" | sudo tee -a /etc/sysctl.conf
  sudo sysctl -p
fi
```

## Step 5: macOS Performance Tweaks

Apply only on macOS (`uname -s` == "Darwin"):

```bash
# Disable App Nap for terminal (prevents throttling background Claude)
defaults write "${TERM_PROGRAM_BUNDLE_ID:-com.apple.Terminal}" NSAppSleepDisabled -bool YES 2>/dev/null

# Speed up animations (snappier window management)
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
defaults write com.apple.dock expose-animation-duration -float 0.1
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.2

# Disable crash reporter dialog (prevents modal blocking)
defaults write com.apple.CrashReporter DialogType -string "none"

# Prevent .DS_Store on network/USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Prevent sleep on AC power (long agent sessions)
sudo pmset -c sleep 0 disksleep 0 powernap 0 2>/dev/null

# Caffeinate: prevent sleep during active agent sessions
# Usage: caffeinate -dims -t 14400 & (keeps awake for 4 hours)
# Or wrap long agent runs: caffeinate -dims claude -p "your prompt"
echo '# Caffeinate alias for long Claude sessions (prevents sleep/screen dim)
alias claude-long="caffeinate -dims claude"
alias claude-team="caffeinate -dims claude --teammate-mode in-process"' >> ~/.zshrc.claude-optimized 2>/dev/null

# Apply Dock changes
killall Dock 2>/dev/null
```

## Step 6: .claudeignore (Token Savings: 50-90%)

Create or update `.claudeignore` to prevent Claude from reading irrelevant files. A single `package-lock.json` can consume 80,000 tokens:

```bash
cat > .claudeignore << 'IGNOREEOF'
# Dependencies (massive token waste)
node_modules/
.pnpm/
vendor/
venv/
.venv/
__pycache__/
target/

# Build output
.next/
dist/
build/
out/
.turbo/
.nuxt/

# Lock files (30,000-80,000 tokens each!)
package-lock.json
yarn.lock
pnpm-lock.yaml
composer.lock
Gemfile.lock
poetry.lock

# Generated/compiled
*.min.js
*.min.css
*.bundle.js
*.chunk.js
*.map
*.d.ts

# Binary and data files
*.wasm
*.bin
*.dat
*.db
*.sqlite
*.csv
*.parquet

# Coverage and test artifacts
coverage/
.nyc_output/
playwright-report/
test-results/
__snapshots__/

# IDE and OS
.idea/
.vscode/settings.json
.DS_Store
Thumbs.db

# Docker volumes
docker-data/

# Large generated docs
docs/api-reference/generated/
IGNOREEOF
```

Adapt based on detected stack: add `target/` for Rust, `.venv/` for Python, etc.

## Step 7: Token & Context Optimization

Add to `~/.claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "60",
    "DISABLE_NON_ESSENTIAL_MODEL_CALLS": "1",
    "ENABLE_TOOL_SEARCH": "auto:5"
  }
}
```

- `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=60`: Compact at 60% context (default ~95%) -- prevents quality degradation
- `DISABLE_NON_ESSENTIAL_MODEL_CALLS=1`: Skip flavor text generation, saves ~$0.04/session
- `ENABLE_TOOL_SEARCH=auto:5`: Defer MCP tools at 5% threshold (saves ~85% tool definition tokens)

### Habits That Save Tokens

Add these to CLAUDE.md as reminders:

- `/clear` between unrelated tasks (eliminates stale context)
- `/compact <focus>` at logical breakpoints ("Focus on the auth module changes")
- Use Plan mode before multi-file refactors (saves ~40% tokens)
- Use subagents for verbose operations (tests, log analysis, doc fetching)
- Scope investigations narrowly: "Check src/auth/" not "investigate the codebase"
- After 2 failed corrections, `/clear` and write a better initial prompt

## Step 8: Terminal Recommendation

If the detected terminal has high input latency (iTerm2: 12ms, Terminal.app: 15ms+), recommend switching:

| Terminal | Latency | Install |
|----------|---------|---------|
| Ghostty (recommended) | 2ms | `brew install --cask ghostty` |
| Alacritty | 3ms | `brew install --cask alacritty` |
| Kitty | 3ms | `brew install --cask kitty` |
| WezTerm | 4ms | `brew install --cask wezterm` |

Key settings for any terminal: scrollback 10,000 lines (not 100K+), disable ligatures, disable transparency/blur.

## Step 9: Docker Optimization (if Docker detected)

```
Docker Desktop > Settings > General:
  - File sharing: VirtioFS (fastest, 90% improvement over osxfs)

Docker Desktop > Settings > Resources:
  - CPUs: Leave 2-4 for host
  - Memory: 8-12 GB (depending on total RAM)

Docker Desktop > Settings > Resources > File Sharing > Synchronized file shares:
  - Add project directory (59% faster than standard)
```

## Step 10: Post-Optimization Measurements

Re-run ALL baseline measurements from Step 1 and compare:

```bash
echo "=== POST-OPTIMIZATION RESULTS ==="
echo "Shell startup:" && ZDOTDIR=~/.config/zsh-claude time zsh -i -c exit 2>&1
echo "Git status:" && time git status --short 2>&1
echo "File descriptors:" && ulimit -n
echo ".claudeignore patterns:" && wc -l .claudeignore 2>/dev/null
```

Report a before/after comparison table showing improvements:

```
| Metric              | Before  | After   | Improvement |
|---------------------|---------|---------|-------------|
| Shell startup       | XXXms   | XXms    | XX% faster  |
| Git status          | XXXms   | XXms    | XX% faster  |
| File descriptors    | 256     | 65536   | 256x more   |
| .claudeignore       | 0 rules | XX rules| XX files excluded |
```

## Manual Steps (Cannot Be Automated)

List these for the user to do manually:
1. Terminal switch (if recommended): Install and configure Ghostty/Alacritty
2. Docker VirtioFS: Must be changed in Docker Desktop GUI
3. DNS caching (optional): `brew install dnsmasq` for 10-100ms savings per API call
4. RAM disk for build cache (optional): `brew install --cask tmpdisk` for zero-latency cache I/O
```

---

## PROMPT 8: Verification & Testing

---

```
# Claude Code Setup -- Prompt 8: Verification & Testing
# Version: 1.0.0 | Date: 2026-03-05
# Self-updating: Checks latest docs to verify against current features

You are running the final verification suite for this Claude Code setup. Your job is to test every component configured by Prompts 1-7, generate a comprehensive report, and provide fix instructions for any failures.

## Step 0: Self-Update

Fetch the latest documentation to verify against current features:

1. Fetch https://code.claude.com/docs/en/settings for current settings schema
2. Fetch https://code.claude.com/docs/en/hooks for current hook events
3. Fetch https://code.claude.com/docs/en/mcp for current MCP configuration

If fetches fail, proceed with built-in knowledge.

## Step 1: Configuration File Verification

Run each check. Record PASS, FAIL, or SKIP (if component was not installed):

### A. Settings Files

```bash
# User settings exist and are valid JSON
echo "--- User Settings ---"
if [ -f ~/.claude/settings.json ]; then
  jq . ~/.claude/settings.json >/dev/null 2>&1 && echo "PASS: Valid JSON" || echo "FAIL: Invalid JSON"
  jq -r 'has("$schema")' ~/.claude/settings.json | grep -q true && echo "PASS: Has schema" || echo "WARN: No schema (optional)"
  jq -r '.permissions.allow // [] | length' ~/.claude/settings.json | xargs -I{} echo "INFO: {} permission rules"
else
  echo "FAIL: ~/.claude/settings.json does not exist"
fi

# Project settings exist and are valid JSON
echo "--- Project Settings ---"
if [ -f .claude/settings.json ]; then
  jq . .claude/settings.json >/dev/null 2>&1 && echo "PASS: Valid JSON" || echo "FAIL: Invalid JSON"
  jq -r 'has("hooks")' .claude/settings.json | grep -q true && echo "PASS: Has hooks" || echo "WARN: No hooks configured"
else
  echo "WARN: .claude/settings.json does not exist (optional if using user-level only)"
fi
```

### B. CLAUDE.md

```bash
echo "--- CLAUDE.md ---"
if [ -f CLAUDE.md ]; then
  LINES=$(wc -l < CLAUDE.md)
  SECTIONS=$(grep -c "^##" CLAUDE.md)
  echo "PASS: Exists ($LINES lines, $SECTIONS sections)"
  [ "$LINES" -lt 50 ] && echo "WARN: Very short ($LINES lines) -- consider adding more project context"
  [ "$LINES" -gt 500 ] && echo "WARN: Very long ($LINES lines) -- consider moving content to skills or subdirectory CLAUDE.md files"

  # Check for essential sections
  for section in "Quick Start" "Architecture" "NEVER" "ALWAYS" "Testing"; do
    grep -qi "$section" CLAUDE.md && echo "  PASS: Has '$section' section" || echo "  WARN: Missing '$section' section"
  done
else
  echo "FAIL: CLAUDE.md does not exist"
fi
```

### C. .claudeignore

```bash
echo "--- .claudeignore ---"
if [ -f .claudeignore ]; then
  PATTERNS=$(grep -v '^#' .claudeignore | grep -v '^$' | wc -l)
  echo "PASS: Exists ($PATTERNS active patterns)"
  grep -q "node_modules" .claudeignore 2>/dev/null && echo "  PASS: Excludes node_modules" || echo "  WARN: Missing node_modules exclusion"
  grep -q "lock" .claudeignore 2>/dev/null && echo "  PASS: Excludes lock files" || echo "  WARN: Missing lock file exclusion (saves 30-80K tokens each)"
else
  echo "WARN: .claudeignore does not exist -- Claude may waste tokens on build artifacts"
fi
```

## Step 2: Hooks Verification

```bash
echo "--- Hooks ---"
if [ -d .claude/hooks ]; then
  SCRIPTS=$(find .claude/hooks -name "*.sh" | wc -l)
  EXECUTABLE=$(find .claude/hooks -name "*.sh" -perm +111 | wc -l)
  echo "INFO: $SCRIPTS hook scripts found, $EXECUTABLE are executable"

  # Check each script is executable
  for script in .claude/hooks/*.sh; do
    [ -f "$script" ] || continue
    if [ -x "$script" ]; then
      echo "  PASS: $(basename $script) is executable"
    else
      echo "  FAIL: $(basename $script) is NOT executable -- run: chmod +x $script"
    fi
  done

  # Test dangerous command blocker
  if [ -f .claude/hooks/block-dangerous.sh ] && [ -x .claude/hooks/block-dangerous.sh ]; then
    RESULT=$(echo '{"tool_input":{"command":"rm -rf /"}}' | .claude/hooks/block-dangerous.sh 2>/dev/null)
    if echo "$RESULT" | jq -r '.decision // .hookSpecificOutput.permissionDecision // empty' 2>/dev/null | grep -qi "block\|deny"; then
      echo "  PASS: block-dangerous.sh correctly blocks 'rm -rf /'"
    else
      echo "  WARN: block-dangerous.sh may not be blocking dangerous commands (output: $RESULT)"
    fi
  fi
else
  echo "WARN: No .claude/hooks/ directory"
fi

# Verify hooks are registered in settings
echo "--- Hook Registration ---"
for event in SessionStart PreToolUse PostToolUse PreCompact Stop Notification; do
  if jq -e ".hooks.\"$event\"" .claude/settings.json >/dev/null 2>&1 || \
     jq -e ".hooks.\"$event\"" ~/.claude/settings.json >/dev/null 2>&1; then
    echo "  PASS: $event hook registered"
  else
    echo "  SKIP: $event hook not configured"
  fi
done
```

## Step 3: Beads Verification

```bash
echo "--- Beads Issue Tracker ---"
if command -v bd >/dev/null 2>&1; then
  VERSION=$(bd version 2>/dev/null || echo "unknown")
  echo "PASS: bd installed (version: $VERSION)"

  if [ -d .beads ]; then
    echo "PASS: .beads/ directory exists (project initialized)"
    bd ready 2>/dev/null && echo "PASS: bd ready works" || echo "WARN: bd ready returned error"
  else
    echo "WARN: .beads/ not found -- run 'bd init' to initialize for this project"
  fi
else
  echo "SKIP: Beads not installed (Prompt 4 was not run or bd not in PATH)"
fi
```

## Step 4: MCP Server Verification

```bash
echo "--- MCP Servers ---"
SERVERS=$(claude mcp list 2>/dev/null)
if [ -n "$SERVERS" ]; then
  COUNT=$(echo "$SERVERS" | grep -c "." || echo "0")
  echo "PASS: $COUNT MCP server(s) configured"
  echo "$SERVERS" | while read -r line; do
    echo "  - $line"
  done

  # Check for recommended servers
  echo "$SERVERS" | grep -qi "context7" && echo "  PASS: Context7 (documentation)" || echo "  WARN: Context7 not installed (recommended for all projects)"
  echo "$SERVERS" | grep -qi "github" && echo "  PASS: GitHub" || echo "  INFO: GitHub MCP not installed"
  echo "$SERVERS" | grep -qi "playwright" && echo "  PASS: Playwright (browser)" || echo "  INFO: Playwright MCP not installed"
else
  echo "WARN: No MCP servers configured (run Prompt 6)"
fi

# Check .mcp.json
if [ -f .mcp.json ]; then
  jq . .mcp.json >/dev/null 2>&1 && echo "PASS: .mcp.json is valid JSON" || echo "FAIL: .mcp.json is invalid JSON"
else
  echo "INFO: No .mcp.json (team-shared MCP config)"
fi
```

## Step 5: Performance Verification

```bash
echo "--- Performance ---"

# Shell startup
if [ -d ~/.config/zsh-claude ]; then
  SHELL_MS=$(ZDOTDIR=~/.config/zsh-claude zsh -i -c 'exit' 2>&1 | grep real | awk '{print $2}' || echo "unknown")
  echo "PASS: ZDOTDIR configured (startup: $SHELL_MS)"
else
  SHELL_MS=$(zsh -i -c 'exit' 2>&1 | grep real | awk '{print $2}' || echo "unknown")
  echo "INFO: Shell startup: $SHELL_MS (target: < 0.100s)"
fi

# Git optimizations
FSMONITOR=$(git config --global core.fsmonitor 2>/dev/null || echo "not set")
UNTRACKED=$(git config --global core.untrackedCache 2>/dev/null || echo "not set")
MANYFILES=$(git config --global feature.manyFiles 2>/dev/null || echo "not set")
echo "Git fsmonitor: $FSMONITOR $([ "$FSMONITOR" = "true" ] && echo "(PASS)" || echo "(WARN: not enabled)")"
echo "Git untrackedCache: $UNTRACKED $([ "$UNTRACKED" = "true" ] && echo "(PASS)" || echo "(WARN: not enabled)")"
echo "Git manyFiles: $MANYFILES $([ "$MANYFILES" = "true" ] && echo "(PASS)" || echo "(WARN: not enabled)")"

# File descriptors
FD_LIMIT=$(ulimit -n)
echo "File descriptors: $FD_LIMIT $([ "$FD_LIMIT" -ge 10000 ] && echo "(PASS)" || echo "(WARN: low limit, target >= 65536)")"

# Token optimization env vars
for var in CLAUDE_AUTOCOMPACT_PCT_OVERRIDE DISABLE_NON_ESSENTIAL_MODEL_CALLS ENABLE_TOOL_SEARCH; do
  VAL=$(jq -r ".env.\"$var\" // empty" ~/.claude/settings.json 2>/dev/null)
  if [ -n "$VAL" ]; then
    echo "  PASS: $var = $VAL"
  else
    echo "  INFO: $var not set (optional)"
  fi
done
```

## Step 6: Agent Teams Verification

```bash
echo "--- Agent Teams ---"
TEAMS_ENABLED=$(jq -r '.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS // empty' ~/.claude/settings.json 2>/dev/null)
if [ "$TEAMS_ENABLED" = "1" ]; then
  echo "PASS: Agent teams enabled"

  # Check for team hooks
  for hook in TeammateIdle TaskCompleted; do
    if jq -e ".hooks.\"$hook\"" .claude/settings.json >/dev/null 2>&1; then
      echo "  PASS: $hook hook configured"
    else
      echo "  WARN: $hook hook not configured (needed for multi-agent coordination)"
    fi
  done

  # Check for agent definitions
  if [ -d .claude/agents ]; then
    AGENTS=$(ls .claude/agents/*.md 2>/dev/null | wc -l)
    echo "  INFO: $AGENTS agent definition(s) in .claude/agents/"
  fi
else
  echo "SKIP: Agent teams not enabled (Prompt 5 was not run)"
fi
```

## Step 7: End-to-End Test (Optional)

Ask the user: "Would you like to run a quick end-to-end test? This will create a temporary beads issue and verify the full workflow. (y/n)"

If yes:

1. Create a test bead: `bd create "Setup verification test" -p 3 --description="Automated test -- will be closed immediately" --json`
2. Claim it: `bd update <id> --status in_progress --json`
3. Close it: `bd close <id> --reason="Setup verification passed" --json`
4. Verify the lifecycle worked without errors
5. Report: "E2E beads lifecycle: PASS"

If agent teams are enabled and the user agrees to a deeper test:

1. Create a test team with 2 agents
2. Assign a simple task: "Read CLAUDE.md and report the number of sections"
3. Verify agents can communicate and complete
4. Delete the test team
5. Report: "E2E agent teams: PASS"

If the user declines: Report "E2E test: SKIPPED (user opted out)"

## Step 8: Generate Final Report

Compile all results into a clear verification report:

```
================================================================
     CLAUDE CODE SETUP VERIFICATION REPORT
     Generated: [timestamp]
================================================================

CONFIGURATION
  [PASS] User settings (~/.claude/settings.json)
  [PASS] Project settings (.claude/settings.json)
  [PASS] CLAUDE.md (285 lines, 12 sections)
  [PASS] .claudeignore (28 patterns)

HOOKS
  [PASS] 6 hook scripts, all executable
  [PASS] Dangerous command blocker works
  [PASS] SessionStart, PreToolUse, PostToolUse, PreCompact, Stop, Notification

TOOLS
  [PASS] Beads v0.58.0 (project initialized)
  [PASS] MCP: 4 servers (context7, github, playwright, supabase)
  [PASS] ccusage installed

PERFORMANCE
  [PASS] Shell startup: 38ms (target: < 100ms)
  [PASS] Git fsmonitor + untrackedCache enabled
  [PASS] File descriptors: 65536
  [PASS] Token optimization: auto-compact at 60%, tool search at 5%

AGENT TEAMS
  [PASS] Enabled with TeammateIdle + TaskCompleted hooks

E2E TEST
  [PASS] Beads lifecycle (create -> claim -> close)
  [SKIP] Agent teams (user opted out)

================================================================
  SCORE: 16/17 checks passed | 1 skipped | 0 failed
  SETUP QUALITY: EXCELLENT
================================================================
```

## Step 9: Recommendations & Resources

Based on any WARN or FAIL results, provide specific fix instructions.

Then list these resources for ongoing optimization:

### Constantly Updated Resources (Bookmark These)

| Resource | URL | What It Covers |
|----------|-----|----------------|
| ClaudeLog | claudelog.com | Comprehensive guides, tutorials, newsletter |
| Claude Fast | claudefa.st | Agent teams, changelog, deep guides |
| Cranot's Guide | github.com/Cranot/claude-code-guide | Auto-updates every 2 days from official docs |
| awesome-claude-code | github.com/hesreallyhim/awesome-claude-code | 26K+ stars, 100+ tools/resources |
| alexop.dev | alexop.dev/posts/ | Deep technical dives, creative use cases |
| Official Docs | code.claude.com/docs/en/best-practices | Canonical source |
| Anthropic Blog | anthropic.com/engineering/claude-code-best-practices | Official best practices |

### Communities

| Community | URL | Size |
|-----------|-----|------|
| r/ClaudeAI | reddit.com/r/ClaudeAI | 535K+ members |
| Claude Discord | discord.com/invite/6PPFFzqPDZ | 66K+ members |
| Hacker News | Search "Claude Code" on news.ycombinator.com | Active threads |

### Key People to Follow

- @bcherny (Boris Cherny) -- Creator of Claude Code
- Simon Willison (simonwillison.net) -- Agentic engineering patterns
- YK Dojo (ykdojo/claude-code-tips) -- Practical tips

### Newsletters

- Agentic Coding (agenticcoding.substack.com) -- YK Dojo, regular tips
- AI Coding Daily (aicodingdaily.substack.com) -- Weekly community pulse

Report complete. The user's Claude Code installation is now configured to expert level.
```

---

## Summary

| Prompt | Focus | Key Outcomes |
|--------|-------|-------------|
| **P6** | MCP Servers & External Tools | Context7, GitHub, Playwright MCP + ccusage, claude-squad + .mcp.json + permissions |
| **P7** | System & Performance | ZDOTDIR (97% shell speedup), git optimizations (96% faster), .claudeignore (50-90% token savings), macOS tweaks, token optimization |
| **P8** | Verification & Testing | 17-point verification suite, E2E beads test, agent teams test, performance comparison, fix instructions, community resources |

Each prompt is self-contained, idempotent, self-updating, and under 6,000 tokens.
