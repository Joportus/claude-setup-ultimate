# R7: System/OS-Level Optimizations for Claude Code Performance

> Every millisecond saved on shell startup, git operations, or filesystem access compounds across hundreds of tool invocations per session.

---

## Table of Contents

1. [Shell Optimization](#1-shell-optimization)
2. [Git Performance](#2-git-performance)
3. [Filesystem Optimization](#3-filesystem-optimization)
4. [Terminal Emulator Selection](#4-terminal-emulator-selection)
5. [Network Optimization](#5-network-optimization)
6. [Process Management](#6-process-management)
7. [macOS-Specific Optimizations](#7-macos-specific-optimizations)
8. [Development Environment](#8-development-environment)
9. [Docker Performance](#9-docker-performance)
10. [Claude Code Context Management](#10-claude-code-context-management)
11. [Implementation Priority Matrix](#11-implementation-priority-matrix)

---

## 1. Shell Optimization

Claude Code spawns shell processes constantly -- every `Bash` tool invocation creates a new shell. Reducing shell startup time from ~770ms to ~40ms has a massive compounding effect.

### 1.1 Measure Current Shell Startup Time

```bash
# Time your current zsh startup
time zsh -i -c exit

# Profile what's slow
zsh -xv 2>&1 | head -100

# Use zsh's built-in profiler
# Add to top of ~/.zshrc:
#   zmodload zsh/zprof
# Add to bottom of ~/.zshrc:
#   zprof
```

### 1.2 Minimal .zshrc for Fast Startup

Claude Code reads your shell config on every invocation. A minimal config dramatically reduces latency:

```bash
# ~/.zshrc - optimized for speed
# Target: < 50ms startup time

# Skip everything in non-interactive shells (scripts, Claude Code spawns)
[[ $- != *i* ]] && return

# Essential PATH only
export PATH="$HOME/.bun/bin:$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# Minimal prompt (no git status, no fancy themes)
PS1='%~ %# '

# History
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE

# Completions (deferred)
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C  # Use cache, skip security check
fi

# Defer expensive plugins
if (( $+commands[zsh-defer] )); then
  zsh-defer source ~/.zsh/plugins/zsh-autosuggestions.zsh
  zsh-defer source ~/.zsh/plugins/zsh-syntax-highlighting.zsh
else
  # Load synchronously if zsh-defer not available
  [ -f ~/.zsh/plugins/zsh-autosuggestions.zsh ] && source ~/.zsh/plugins/zsh-autosuggestions.zsh
  [ -f ~/.zsh/plugins/zsh-syntax-highlighting.zsh ] && source ~/.zsh/plugins/zsh-syntax-highlighting.zsh
fi
```

### 1.3 ZDOTDIR Trick for Claude Code

Set a separate, minimal ZDOTDIR for Claude Code to bypass your full shell config:

```bash
# Create minimal zsh config directory
mkdir -p ~/.config/zsh-claude

# ~/.config/zsh-claude/.zshrc - bare minimum
export PATH="$HOME/.bun/bin:$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
PS1='$ '
```

Then in Claude Code settings (`~/.claude/settings.json`):

```json
{
  "env": {
    "ZDOTDIR": "~/.config/zsh-claude"
  }
}
```

**Impact:** Can reduce shell startup from ~770ms to ~20ms -- a 97% improvement. With hundreds of shell invocations per session, this saves minutes.

### 1.4 Disable Oh-My-Zsh / Heavy Frameworks

Oh-My-Zsh, Prezto, and similar frameworks add 200-500ms to startup. Alternatives:

| Framework | Startup Time | Notes |
|-----------|-------------|-------|
| Oh-My-Zsh (default) | 300-700ms | Loads dozens of plugins |
| Oh-My-Zsh (minimal) | 100-200ms | Disable unused plugins |
| Antidote | 50-100ms | Lazy-loading plugin manager |
| Zinit (turbo) | 30-80ms | Turbo mode defers loading |
| No framework | 10-40ms | Manual config, fastest |

### 1.5 Plugin Deferral with zsh-defer

```bash
# Install zsh-defer
git clone https://github.com/romkatv/zsh-defer.git ~/.zsh/plugins/zsh-defer
source ~/.zsh/plugins/zsh-defer/zsh-defer.plugin.zsh

# Defer everything non-essential
zsh-defer source ~/.zsh/plugins/zsh-autosuggestions.zsh
zsh-defer source ~/.zsh/plugins/zsh-syntax-highlighting.zsh
zsh-defer eval "$(fnm env --use-on-cd)"      # Node version manager
zsh-defer eval "$(starship init zsh)"         # Prompt
```

**Impact:** Reduces startup to ~20ms (0.02 seconds) even with plugins loaded.

### 1.6 Powerlevel10k Instant Prompt

If you use Powerlevel10k, enable instant prompt:

```bash
# Add to TOP of ~/.zshrc (before anything else)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
```

This shows the prompt immediately while loading plugins in the background.

### 1.7 Completion Cache Optimization

```bash
# Only regenerate completion dump once per day
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# Disable unused completion systems
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache
```

---

## 2. Git Performance

Claude Code runs `git status`, `git diff`, `git log`, and other commands frequently. Optimizing git can save 100-800ms per operation.

### 2.1 Essential Git Config for Performance

```bash
# Enable filesystem monitor daemon (watches for file changes)
git config --global core.fsmonitor true

# Cache untracked file results
git config --global core.untrackedCache true

# Enable commit graph for faster log/merge-base operations
git config --global fetch.writeCommitGraph true
git config --global core.commitGraph true

# Enable many-files optimization bundle
git config --global feature.manyFiles true

# Parallel index operations
git config --global index.threads true

# Use faster SHA-1 implementation
git config --global core.checkRoundtripEncoding false
```

**Impact:** `git status` drops from ~970ms to ~40ms (96% faster) with fsmonitor + untrackedCache enabled.

### 2.2 Git Maintenance (Background Optimization)

```bash
# Start background maintenance (runs hourly)
git maintenance start

# What it does:
# - Hourly: prefetch, commit-graph
# - Daily: loose-objects, incremental-repack
# - Weekly: pack-refs
```

Individual tasks:

```bash
# Manually run maintenance tasks
git maintenance run --task=commit-graph    # Speed up log/merge operations
git maintenance run --task=pack-refs       # Consolidate loose refs
git maintenance run --task=loose-objects   # Clean up loose objects
git maintenance run --task=incremental-repack  # Optimize pack files
```

### 2.3 Git Config for Large Repos

```bash
# .gitconfig additions for large repos
[core]
    fsmonitor = true
    untrackedCache = true
    commitGraph = true
    preloadIndex = true
    fscache = true          # Windows: cache filesystem calls

[pack]
    threads = 0             # Use all CPU cores for packing
    windowMemory = 256m     # Memory per packing thread

[gc]
    auto = 256              # Auto GC after 256 loose objects (default: 6700)
    autoPackLimit = 50      # Auto repack after 50 packs

[fetch]
    writeCommitGraph = true
    parallel = 0            # Fetch from multiple remotes in parallel

[feature]
    manyFiles = true        # Enables fsmonitor, untrackedCache, index.version=4

[index]
    version = 4             # Smaller index, faster reads
    threads = true          # Parallel index operations

[status]
    aheadBehind = false     # Skip expensive ahead/behind calculation
```

### 2.4 Partial Clone and Sparse Checkout

For very large repos where you only work on a subset:

```bash
# Partial clone (download objects on demand)
git clone --filter=blob:none <repo-url>

# Sparse checkout (only checkout needed directories)
git sparse-checkout init --cone
git sparse-checkout set app/ lib/ components/

# Check current sparse patterns
git sparse-checkout list
```

### 2.5 Shallow Clone for CI/Fresh Checkouts

```bash
# Only fetch last N commits
git clone --depth=1 <repo-url>

# Deepen later if needed
git fetch --deepen=100
```

### 2.6 .gitignore Optimization

A well-structured `.gitignore` reduces the work git does scanning untracked files:

```gitignore
# Build outputs (match early, skip entire directories)
/node_modules/
/.next/
/dist/
/build/
/.turbo/

# OS files
.DS_Store
Thumbs.db

# IDE
.idea/
.vscode/
*.swp

# Large binary directories
/public/uploads/
```

**Tip:** Place the most commonly matched patterns at the top of `.gitignore` for marginal speed improvement.

---

## 3. Filesystem Optimization

### 3.1 macOS: Exclude Dev Directories from Spotlight

Spotlight indexing dev directories causes I/O contention and wastes CPU:

```bash
# Exclude node_modules, .next, etc. from Spotlight
sudo mdutil -i off /Users/joaquin/Documents/hypebase-ai/node_modules
sudo mdutil -i off /Users/joaquin/Documents/hypebase-ai/.next

# Or add to Spotlight privacy list via System Settings:
# System Settings > Siri & Spotlight > Spotlight Privacy > Add folders

# Exclude all node_modules recursively (add to .metadata_never_index)
find /Users/joaquin/Documents -name "node_modules" -type d -exec touch {}/.metadata_never_index \;
```

**Alternative:** Add directories to System Settings > Spotlight > Privacy.

### 3.2 macOS: Exclude from Time Machine

```bash
# Exclude build artifacts from Time Machine
sudo tmutil addexclusion /Users/joaquin/Documents/hypebase-ai/node_modules
sudo tmutil addexclusion /Users/joaquin/Documents/hypebase-ai/.next
sudo tmutil addexclusion /Users/joaquin/Documents/hypebase-ai/.turbo

# Verify exclusions
tmutil isexcluded /Users/joaquin/Documents/hypebase-ai/node_modules
```

### 3.3 File Descriptor Limits (macOS)

macOS default limit is only 256 file descriptors per process, which is extremely low for dev tools:

```bash
# Check current limits
ulimit -n        # Per-process soft limit
launchctl limit maxfiles  # System limits

# Increase temporarily (current session)
ulimit -n 65536

# Increase permanently (survives reboot)
# Create /Library/LaunchDaemons/limit.maxfiles.plist:
sudo tee /Library/LaunchDaemons/limit.maxfiles.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>limit.maxfiles</string>
    <key>ProgramArguments</key>
    <array>
      <string>launchctl</string>
      <string>limit</string>
      <string>maxfiles</string>
      <string>65536</string>
      <string>524288</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>ServiceIPC</key>
    <false/>
  </dict>
</plist>
EOF

# Load the plist
sudo launchctl load -w /Library/LaunchDaemons/limit.maxfiles.plist
```

Also add to shell profile:

```bash
# ~/.zshrc
ulimit -n 65536 2>/dev/null
```

### 3.4 Linux: inotify Watch Limits

```bash
# Check current limit
cat /proc/sys/fs/inotify/max_user_watches

# Increase (temporary)
sudo sysctl fs.inotify.max_user_watches=524288

# Increase (permanent)
echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf
echo "fs.inotify.max_user_instances=1024" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### 3.5 RAM Disk for Build Caches

Use a RAM disk for temporary/cache files to eliminate disk I/O:

```bash
# macOS: Create a 2GB RAM disk
RAMDISK_SIZE=$((2 * 1024 * 2048))  # 2GB in 512-byte sectors
DEVICE=$(hdiutil attach -nomount ram://$RAMDISK_SIZE)
diskutil erasevolume HFS+ "RAMDisk" $DEVICE

# Mount point: /Volumes/RAMDisk
# Symlink build caches to RAM disk
ln -sf /Volumes/RAMDisk/turbo-cache /Users/joaquin/Documents/hypebase-ai/.turbo

# Auto-create on boot (add to login items or launchd)
```

**TmpDisk app** (open source, menu bar): Provides a GUI for managing RAM disks on macOS with auto-creation on startup.

```bash
# Install TmpDisk
brew install --cask tmpdisk
```

**Caution:** RAM disk contents are lost on reboot/power loss. Only use for caches and temporary files, never for source code.

### 3.6 SSD TRIM (macOS)

Modern macOS enables TRIM automatically for Apple SSDs. For third-party SSDs:

```bash
# Check TRIM status
system_profiler SPSerialATADataType | grep TRIM
# or for NVMe
system_profiler SPNVMeDataType | grep TRIM

# Enable TRIM for third-party SSDs (if not already enabled)
sudo trimforce enable
```

---

## 4. Terminal Emulator Selection

Terminal performance directly affects Claude Code's responsiveness, especially for output-heavy operations.

### 4.1 Benchmark Comparison (2026)

| Terminal | Input Latency | GPU Accel | Tabs/Splits | Platform | Best For |
|----------|--------------|-----------|-------------|----------|----------|
| **Ghostty** | 2ms | Yes (native) | Yes | macOS, Linux | Best all-rounder on Mac |
| **Alacritty** | 3ms | Yes (OpenGL) | No (use tmux) | Cross-platform | Raw speed minimalists |
| **Kitty** | 3ms | Yes (OpenGL) | Yes | macOS, Linux | Linux power users |
| **WezTerm** | 4ms | Yes | Yes | Cross-platform | Cross-platform flexibility |
| **Warp** | 8ms | Yes | Yes | macOS, Linux | AI-integrated workflows |
| **iTerm2** | 12ms | Partial | Yes | macOS only | Feature-rich Mac users |
| **Terminal.app** | 15ms+ | No | Yes | macOS only | (avoid for dev work) |

### 4.2 Recommended: Ghostty

Ghostty (written in Zig) has the lowest input latency and uses platform-native GPU APIs:

```bash
# Install Ghostty
brew install --cask ghostty
```

Key performance settings (`~/.config/ghostty/config`):

```ini
# Performance
font-size = 14
font-family = JetBrains Mono
font-thicken = true

# Disable ligatures (marginal rendering speed improvement)
font-feature = -calt
font-feature = -liga
font-feature = -dlig

# Scrollback (lower = less memory, faster scroll)
scrollback-limit = 10000

# Window
window-decoration = false
macos-titlebar-style = hidden

# GPU rendering (default, but explicit)
# Ghostty uses platform-native Metal on macOS
```

### 4.3 Alternative: Alacritty (Fastest Raw Latency)

```bash
brew install --cask alacritty
```

`~/.config/alacritty/alacritty.toml`:

```toml
[font]
size = 14.0

[font.normal]
family = "JetBrains Mono"

[scrolling]
history = 10000

# No ligatures
[font.normal]
style = "Regular"
```

### 4.4 Terminal Settings That Affect Performance

Regardless of terminal choice:

- **Reduce scrollback buffer**: 10,000 lines is plenty. Default 100,000+ wastes memory.
- **Disable ligatures**: Font ligatures require extra rendering passes. Turn them off if you don't need them.
- **Use a simple font**: Monospace fonts without complex glyph substitution render faster.
- **Minimize transparency/blur**: GPU compositing effects add latency.
- **Disable mouse reporting** if not needed: Reduces terminal escape sequence processing.

---

## 5. Network Optimization

### 5.1 DNS Caching with dnsmasq

Every API call (Claude API, npm registry, GitHub) starts with DNS resolution. Local caching eliminates repeated lookups:

```bash
# Install dnsmasq
brew install dnsmasq

# Configure
echo "cache-size=10000" >> /opt/homebrew/etc/dnsmasq.conf
echo "no-resolv" >> /opt/homebrew/etc/dnsmasq.conf
echo "server=1.1.1.1" >> /opt/homebrew/etc/dnsmasq.conf
echo "server=8.8.8.8" >> /opt/homebrew/etc/dnsmasq.conf

# Start service
sudo brew services start dnsmasq

# Configure macOS to use local DNS
# System Settings > Network > Wi-Fi > Details > DNS > Add 127.0.0.1
```

**Impact:** Eliminates 10-100ms DNS latency on repeated lookups.

### 5.2 macOS Built-in DNS Cache

macOS has a built-in mDNSResponder cache. Flush it when having issues:

```bash
# Flush DNS cache
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

### 5.3 HTTP Keep-Alive and Connection Pooling

Most modern tools (curl, fetch) handle this automatically, but verify:

```bash
# Check if your Node/Bun processes use keep-alive
# Bun enables HTTP keep-alive by default
# Node.js: set in your HTTP agent configuration
```

### 5.4 Local NPM/Bun Registry Mirror

For teams or CI, Verdaccio provides a local caching proxy:

```bash
# Install and start Verdaccio
npm install -g verdaccio
verdaccio

# Configure Bun to use local mirror
# bunfig.toml
# [install]
# registry = "http://localhost:4873"
```

**Impact:** Reduces `bun install` latency by caching packages locally. First install is slower; subsequent installs are near-instant.

### 5.5 Bun's Built-in Caching

Bun already has aggressive package caching:

```bash
# Bun global cache location
ls ~/.bun/install/cache/

# Clear cache if corrupted
bun pm cache rm
```

Bun installs are already 3-10x faster than npm. The local registry mirror mainly helps in CI or when multiple machines share the same packages.

---

## 6. Process Management

### 6.1 CPU Priority (nice/renice)

Give Claude Code and its child processes higher CPU priority:

```bash
# Run Claude Code with higher priority (lower nice = higher priority)
# nice values: -20 (highest) to +19 (lowest), default = 0
nice -n -5 claude

# Renice a running Claude Code process
# Find the PID first
pgrep -f "claude" | xargs renice -n -5

# Or create an alias
alias claude='nice -n -5 claude'
```

**Note:** Negative nice values require `sudo` or appropriate permissions on macOS.

### 6.2 Lower Priority for Background Tasks

Conversely, reduce priority for background processes that compete with Claude Code:

```bash
# Lower priority for Docker
pgrep -f "Docker" | xargs renice -n 10

# Lower priority for Spotlight indexing
# (Better: exclude dev dirs from Spotlight entirely -- see section 3.1)

# Lower priority for Time Machine
sudo sysctl debug.lowpri_throttle_enabled=0  # Disable Time Machine throttle
```

### 6.3 Background Process Cleanup

Kill unnecessary processes that consume CPU/memory:

```bash
# Find top CPU consumers
top -l 1 -o cpu -n 10

# Common culprits to close during dev:
# - Slack desktop (use web version)
# - Chrome (close unnecessary tabs)
# - Zoom (quit when not in a meeting)
# - Dropbox/Google Drive sync
# - Adobe Creative Cloud background services

# macOS: List all launch agents/daemons
launchctl list | grep -v "com.apple"
```

### 6.4 Memory Management

```bash
# Check memory pressure
memory_pressure  # macOS built-in

# Monitor swap usage
sysctl vm.swapusage

# Clear inactive memory (macOS)
sudo purge  # Forces disk cache purge, use sparingly
```

**Recommendation:** For Claude Code sessions, aim for green memory pressure. If yellow/red, close memory-hungry apps (Docker containers, browsers with many tabs).

---

## 7. macOS-Specific Optimizations

### 7.1 Disable App Nap for Terminal

App Nap throttles background apps. Disable it for your terminal:

```bash
# Disable App Nap globally (not recommended)
defaults write NSGlobalDomain NSAppSleepDisabled -bool YES

# Disable App Nap for specific app (recommended)
# Right-click app in Finder > Get Info > check "Prevent App Nap"

# Disable App Nap for Terminal.app
defaults write com.apple.Terminal NSAppSleepDisabled -bool YES

# For iTerm2
defaults write com.googlecode.iterm2 NSAppSleepDisabled -bool YES
```

### 7.2 Reduce Visual Animations

```bash
# Reduce motion (System Settings > Accessibility > Display)
defaults write com.apple.universalaccess reduceMotion -bool true

# Speed up Mission Control animations
defaults write com.apple.dock expose-animation-duration -float 0.1

# Speed up Dock animations
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.2

# Disable window animations
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false

# Speed up sheet (dialog) animations
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

# Apply changes
killall Dock
killall Finder
```

### 7.3 Disable Unnecessary System Services

```bash
# Disable Gatekeeper (optional, security trade-off)
# sudo spctl --master-disable

# Disable automatic software updates during work
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool false

# Disable crash reporter dialog
defaults write com.apple.CrashReporter DialogType -string "none"
```

### 7.4 Energy Settings for Performance

```bash
# Prevent sleep when on power adapter
sudo pmset -c sleep 0         # Never sleep on AC power
sudo pmset -c disksleep 0     # Never spin down disk on AC
sudo pmset -c displaysleep 30 # Display sleep after 30 min

# Disable Power Nap
sudo pmset -c powernap 0

# Check current settings
pmset -g
```

### 7.5 Disable .DS_Store on Network Volumes

```bash
# Prevent .DS_Store creation on network drives
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
```

---

## 8. Development Environment

### 8.1 Bun vs Node.js Performance

| Metric | Bun 1.3+ | Node.js 24 | Winner |
|--------|----------|-------------|--------|
| Startup time | 8-15ms | 40-120ms | Bun (5-10x) |
| Package install | 1-3s | 10-30s | Bun (3-10x) |
| TypeScript execution | Native, 0ms transpile | Requires ts-node/tsx | Bun |
| HTTP server | ~150k req/s | ~80k req/s | Bun |
| Complex CPU work | Varies | Often faster (V8) | Node.js |
| File I/O | Faster (Zig) | Good | Bun |

**Recommendation:** Use Bun for everything except CPU-bound computation where V8 excels.

### 8.2 TypeScript Compilation: tsgo vs tsc

| Tool | Speed | Compatibility | Notes |
|------|-------|---------------|-------|
| **tsgo** | 10x faster than tsc | Most features | Doesn't support `baseUrl` in tsconfig |
| **tsc** | Baseline | Full compatibility | Fallback when tsgo fails |
| **SWC** | Very fast | Transpile only | No type checking |
| **esbuild** | Very fast | Transpile only | No type checking |

```bash
# Use tsgo for type checking (10x faster)
bun run typecheck     # Uses tsgo by default in this project

# Fallback to tsc if needed
bun run typecheck:tsc
```

### 8.3 Turbopack (Next.js)

Turbopack is the default bundler in Next.js 16+ (2026):

```bash
# Dev with Turbopack (already configured in this project)
bun run dev:turbo

# Performance gains:
# - 76.7% faster local server startup
# - 96.3% faster Fast Refresh (HMR)
# - Function-level caching
# - Parallel compilation across all CPU cores
```

Key Turbopack optimizations:

```js
// next.config.js
module.exports = {
  // Turbopack is default in Next.js 16+
  // Explicit configuration if needed:
  turbopack: {
    // Resolve aliases (replaces webpack resolve.alias)
    resolveAlias: {
      // Custom aliases
    },
  },
};
```

### 8.4 Build Cache Persistence

```bash
# Turbopack cache location
ls .next/cache/

# Remote caching with Vercel
npx turbo login
npx turbo link

# Local persistent cache (survives bun install)
# .turbo/ directory is gitignored but persists locally
```

---

## 9. Docker Performance

### 9.1 VirtioFS (macOS Docker Desktop)

VirtioFS is the fastest file sharing option for Docker on macOS:

```
Docker Desktop > Settings > General > "Choose file sharing implementation for your containers"
Select: VirtioFS
```

**Impact:** Bind mounts go from 5-6x slower to ~3x slower vs native (90% improvement in some benchmarks).

### 9.2 Synchronized File Shares (Docker Desktop 4.27+)

For bind-mount-heavy projects:

```
Docker Desktop > Settings > Resources > File Sharing > Synchronized file shares
Add: /Users/joaquin/Documents/hypebase-ai
```

**Impact:** 59% faster than standard Docker-VZ. Requires Docker Desktop paid plan.

### 9.3 Docker Resource Allocation

```
Docker Desktop > Settings > Resources:
- CPUs: 4-6 (leave 2-4 for host)
- Memory: 8-12 GB (depending on total RAM)
- Swap: 2 GB
- Disk image size: 64+ GB
```

### 9.4 Docker Compose Optimization

```yaml
# docker-compose.yml optimizations
services:
  app:
    # Use named volumes for node_modules (faster than bind mount)
    volumes:
      - .:/app:cached           # :cached flag for better read performance
      - node_modules:/app/node_modules  # Named volume, NOT bind mount

volumes:
  node_modules:
```

### 9.5 Docker BuildKit

```bash
# Enable BuildKit (faster builds, better caching)
export DOCKER_BUILDKIT=1

# Or in docker-compose
# docker-compose.yml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
      # BuildKit features
      cache_from:
        - type=local,src=/tmp/docker-cache
      cache_to:
        - type=local,dest=/tmp/docker-cache
```

---

## 10. Claude Code Context Management

While not strictly "OS-level," context management directly affects Claude Code's responsiveness and output quality.

### 10.1 Context Window Basics

- Claude Code uses a **200,000-token window** (~150,000 words)
- Performance degrades as context fills up
- Sessions that stay under **75% utilization** produce higher-quality output
- Every file read, command output, and message accumulates in the budget

### 10.2 Key Commands

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/clear` | Reset context entirely | Between unrelated tasks |
| `/compact` | Summarize and compress context | Long sessions, preserving some history |
| `/compact <instructions>` | Compact with specific preservation rules | "Preserve the list of modified files" |
| `/context` | Show token usage breakdown | When responses feel slow |
| `/model haiku` | Switch to faster model | Simple tasks (syntax, quick explanations) |

### 10.3 CLAUDE.md Optimization

- Keep CLAUDE.md under **200 lines / 2,000 tokens**
- Only include universally applicable instructions
- Move domain-specific context to sub-directory CLAUDE.md files
- Delete instructions Claude already follows correctly without being told
- Convert repeating instructions into hooks instead

### 10.4 Context-Saving Strategies

- **Use Plan mode** before multi-file refactors (saves ~40% tokens)
- **Use subagents** for research/exploration (isolates from main context)
- **Limit file reads**: Use `--lines` or specify ranges instead of reading entire files
- **Use `/clear` aggressively** between distinct tasks
- Monitor the status bar fill indicator; compact at 60%

### 10.5 PreCompact Hook

Configure a hook to preserve critical context during automatic compaction:

```json
// ~/.claude/settings.json
{
  "hooks": {
    "PreCompact": [
      {
        "type": "command",
        "command": "echo 'Preserve: list of modified files, current task ID, test commands'"
      }
    ]
  }
}
```

---

## 11. Implementation Priority Matrix

### Tier 1: High Impact, Easy to Implement (Do First)

| Optimization | Expected Impact | Time to Implement |
|-------------|----------------|-------------------|
| Git fsmonitor + untrackedCache | 96% faster git status | 2 minutes |
| Shell ZDOTDIR for Claude Code | 97% faster shell spawn | 5 minutes |
| Spotlight exclusion for dev dirs | Reduced I/O contention | 2 minutes |
| File descriptor limit increase | Prevents EMFILE errors | 5 minutes |
| Time Machine exclusion for node_modules | Reduced backup I/O | 1 minute |
| `/compact` and `/clear` usage | Better response quality | 0 minutes (habit) |

### Tier 2: Moderate Impact, Low Effort

| Optimization | Expected Impact | Time to Implement |
|-------------|----------------|-------------------|
| Disable App Nap for terminal | Consistent performance | 1 minute |
| Reduce macOS animations | Snappier UI | 2 minutes |
| Git maintenance start | Background optimization | 1 minute |
| Terminal switch (Ghostty/Alacritty) | 5-10ms lower latency | 10 minutes |
| Energy settings (no sleep on AC) | No interruptions | 2 minutes |
| .DS_Store prevention on network | Fewer filesystem ops | 1 minute |

### Tier 3: Moderate Impact, More Effort

| Optimization | Expected Impact | Time to Implement |
|-------------|----------------|-------------------|
| DNS caching (dnsmasq) | 10-100ms per lookup saved | 15 minutes |
| Docker VirtioFS + resource tuning | 59-90% faster mounts | 10 minutes |
| RAM disk for build cache | Eliminated disk I/O for cache | 15 minutes |
| zsh-defer plugin loading | ~20ms shell startup | 20 minutes |
| Process priority (nice) | More CPU for Claude | 5 minutes |
| Linux inotify limits | More file watchers | 5 minutes |

### Tier 4: Niche / Situational

| Optimization | Expected Impact | When Useful |
|-------------|----------------|-------------|
| Partial/sparse git clone | Smaller repo checkout | Very large repos |
| Local npm registry (Verdaccio) | Cached package installs | Teams/CI |
| Turbopack remote caching | Shared build cache | Teams/CI |
| Background process cleanup | More available resources | Resource-constrained machines |

---

## Quick Setup Script (macOS)

A combined script to apply the most impactful optimizations:

```bash
#!/bin/bash
# claude-code-optimize.sh - Apply high-impact system optimizations

echo "=== Claude Code System Optimization ==="

# 1. Git performance
echo "Configuring git performance..."
git config --global core.fsmonitor true
git config --global core.untrackedCache true
git config --global fetch.writeCommitGraph true
git config --global core.commitGraph true
git config --global feature.manyFiles true
git config --global index.threads true

# 2. Start git maintenance on current repo
echo "Starting git maintenance..."
git maintenance start 2>/dev/null || true

# 3. File descriptor limits
echo "Increasing file descriptor limits..."
ulimit -n 65536 2>/dev/null || echo "  Note: Add 'ulimit -n 65536' to ~/.zshrc"

# 4. Spotlight exclusions
echo "Excluding dev directories from Spotlight..."
if [ -d "node_modules" ]; then
  touch node_modules/.metadata_never_index 2>/dev/null
fi
if [ -d ".next" ]; then
  touch .next/.metadata_never_index 2>/dev/null
fi

# 5. Time Machine exclusions
echo "Excluding build dirs from Time Machine..."
tmutil addexclusion node_modules 2>/dev/null || true
tmutil addexclusion .next 2>/dev/null || true
tmutil addexclusion .turbo 2>/dev/null || true

# 6. macOS performance
echo "Applying macOS performance tweaks..."
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false 2>/dev/null
defaults write com.apple.dock expose-animation-duration -float 0.1 2>/dev/null
defaults write com.apple.dock autohide-delay -float 0 2>/dev/null
defaults write com.apple.CrashReporter DialogType -string "none" 2>/dev/null
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true 2>/dev/null

# 7. Disable .DS_Store on network volumes
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true 2>/dev/null

echo ""
echo "=== Done! ==="
echo ""
echo "Manual steps remaining:"
echo "  1. Set ZDOTDIR in Claude Code settings for fast shell startup"
echo "  2. Switch terminal to Ghostty or Alacritty for lower latency"
echo "  3. Docker Desktop: Enable VirtioFS in Settings > General"
echo "  4. Consider 'brew install dnsmasq' for DNS caching"
echo "  5. Add 'ulimit -n 65536' to ~/.zshrc"
```

---

## Sources

### Shell Optimization
- [ZDOTDIR Setup (2025)](https://data-wise.github.io/zsh-claude-workflow/optimization/zdotdir-setup/)
- [Speeding Up Zsh](https://www.joshyin.cc/blog/speeding-up-zsh)
- [Speeding up zsh Startup with zprof and zsh-defer](https://mzunino.com.uy/til/2025/03/speeding-up-zsh-startup-with-zprof-and-zsh-defer/)
- [My ZSH config built for speed](https://towardsthecloud.com/notes/zsh-config)
- [Improving Zsh Performance](https://www.dribin.org/dave/blog/archives/2024/01/01/zsh-performance/)
- [How I Used Claude Code to Speed Up My Shell Startup by 95%](https://www.nickyt.co/blog/how-i-used-claude-code-to-speed-up-my-shell-startup-by-95-m0f/)

### Git Performance
- [Improve Git monorepo performance with a file system monitor](https://github.blog/engineering/infrastructure/improve-git-monorepo-performance-with-a-file-system-monitor/)
- [How to Improve Performance in Git: The Complete Guide](https://www.git-tower.com/blog/git-performance)
- [The Ultimate Tips for Working With Large Git Monorepos](https://www.kenmuse.com/blog/tips-for-large-monorepos-on-github/)
- [Git Maintenance](https://alchemists.io/articles/git_maintenance)
- [Git Performance Issues](https://www.compilenrun.com/docs/devops/git/git-troubleshooting/git-performance-issues/)

### Terminal Emulators
- [Best Terminal Emulators 2026: Benchmarked](https://scopir.com/posts/best-terminal-emulators-developers-2026/)
- [Best Terminal Emulators 2026: Warp vs Ghostty vs Kitty vs Alacritty vs iTerm2](https://www.devtoolreviews.com/reviews/best-terminal-emulators-2026)
- [The Modern Terminals Showdown: Alacritty, Kitty, and Ghostty](https://blog.codeminer42.com/modern-terminals-alacritty-kitty-and-ghostty/)
- [Ghostty Performance Discussion](https://github.com/ghostty-org/ghostty/discussions/4837)
- [Choosing a Terminal on macOS (2025)](https://medium.com/@dynamicy/choosing-a-terminal-on-macos-2025-iterm2-vs-ghostty-vs-wezterm-vs-kitty-vs-alacritty-d6a5e42fd8b3)

### macOS Optimization
- [Best Mac Settings for Developers in 2026](https://imidef.com/en/2026-02-26-dev-mac-setup)
- [OSX Optimizer](https://github.com/sickcodes/osx-optimizer)
- [Optimizing Spotlight for Better Performance](https://macperformanceguide.com/Optimizing-Spotlight.html)
- [Increasing File Descriptor Ulimit on MacOS](https://hiltmon.com/blog/2023/01/01/increasing-file-descriptor-ulimit-on-macos/)
- [Creating RAM disk in macOS](https://gist.github.com/htr3n/344f06ba2bb20b1056d7d5570fe7f596)
- [TmpDisk - RAM Disk Management](https://github.com/imothee/tmpdisk)

### Docker Performance
- [Docker on Apple Silicon: Performance Optimization in M4 Clusters](https://macdate.com/en/blog/2026-docker-m4-performance-optimization.html)
- [Docker on MacOS is still slow?](https://www.paolomainardi.com/posts/docker-performance-macos-2025/)
- [Ultimate Docker Desktop Performance Guide for Mac](https://m.academy/articles/docker-desktop-performance-guide-mac/)
- [Synchronized File Shares in Docker Desktop](https://www.docker.com/blog/announcing-synchronized-file-shares/)

### Claude Code Performance
- [Claude Code Speed: Rev the Engine](https://claudefa.st/blog/guide/performance/speed-optimization)
- [Best Practices for Claude Code](https://code.claude.com/docs/en/best-practices)
- [Context Management - Optimization Guide](https://institute.sfeir.com/en/claude-code/claude-code-context-management/optimization/)
- [50 Claude Code Tips & Tricks](https://www.geeky-gadgets.com/claude-code-tips-2/)
- [CLAUDE MD High Performance](https://github.com/ruvnet/ruflo/wiki/CLAUDE-MD-High-Performance)
- [Claude Code Performance Issues and Optimization](https://claudelog.com/faqs/claude-code-performance/)

### Build Tools
- [Turbopack in Next.js 16](https://medium.com/@mernstackdevbykevin/turbopack-builds-in-next-js-16-performance-gains-real-world-impact-ffa6dc447821)
- [Inside Turbopack: Building Faster by Building Less](https://nextjs.org/blog/turbopack-incremental-computation)
- [Bun vs Node.js 2025: Performance](https://strapi.io/blog/bun-vs-nodejs-performance-comparison-guide)
- [Bun vs Native Node.js TypeScript](https://betterstack.com/community/guides/scaling-nodejs/bun-vs-nodejs-typescript/)

### Network
- [Local DNS Caching on macOS](https://zameermanji.com/blog/2021/6/5/local-dns-caching-on-macos/)
- [DNS Performance Optimization](https://1337skills.com/blog/2025-06-25-dns-performance-optimization/)
- [Verdaccio - Local NPM Registry](https://www.verdaccio.org/)
