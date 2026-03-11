---
name: setup-optimize
description: "Optimize system performance for Claude Code: minimal ZDOTDIR shell (97% faster startup), git fsmonitor/untrackedCache (96% faster git status), .claudeignore token savings, file descriptor limits, macOS tweaks, and token/context optimization settings."
user-invocable: true
argument-hint: ""
---

# System & Performance Optimization (Prompt 7 of 8)

Optimize this machine for maximum Claude Code throughput. Every millisecond saved compounds across hundreds of tool invocations per session.

## Self-Update Protocol

Before implementing anything:
1. WebFetch `https://code.claude.com/docs/en/best-practices`
2. WebFetch `https://code.claude.com/docs/en/costs`
3. If any information below conflicts, USE THE ONLINE VERSION.

## Step 1: Baseline Measurements

Record ALL of these before optimizing:
- Shell startup: `time zsh -i -c exit 2>&1`
- Git status speed: `time git status --short 2>&1`
- File descriptor limit: `ulimit -n`
- OS: `uname -s`
- Terminal: `echo "${TERM_PROGRAM:-unknown}"`
- Shell config size: `wc -l ~/.zshrc 2>/dev/null`

## Step 2: Shell Optimization (HIGHEST IMPACT)

Create a minimal ZDOTDIR for Claude Code (fast shell while preserving your normal shell):

```bash
mkdir -p ~/.config/zsh-claude
```

Create `~/.config/zsh-claude/.zshrc` with:
- Essential PATH only (detect bun, cargo, go, homebrew paths)
- Minimal prompt: `PS1='%~ %# '`
- History settings
- Fast completions: `autoload -Uz compinit && compinit -C`
- File descriptor limit: `ulimit -n 65536 2>/dev/null`

Add to `~/.claude/settings.json`:
```json
{ "env": { "ZDOTDIR": "$HOME/.config/zsh-claude" } }
```

Note: Use `$HOME` not `~` in JSON (tilde does not expand).

Verify: `{ time ZDOTDIR=$HOME/.config/zsh-claude zsh -i -c exit; } 2>&1` -- target < 50ms.

## Step 3: Git Optimization

```bash
git config --global core.fsmonitor true
git config --global core.untrackedCache true
git config --global fetch.writeCommitGraph true
git config --global core.commitGraph true
git config --global feature.manyFiles true
git config --global index.threads true
git maintenance start
git config --global status.aheadBehind false
```

## Step 4: Filesystem Optimization

### macOS: Spotlight & Time Machine Exclusions
```bash
for dir in node_modules .next .turbo dist build .venv target vendor __pycache__; do
  [ -d "$dir" ] && touch "$dir/.metadata_never_index" 2>/dev/null
  [ -d "$dir" ] && tmutil addexclusion "$dir" 2>/dev/null
done
```

### File Descriptor Limits
Increase to 65536 in current session and shell configs. For permanent system-wide fix, create `/Library/LaunchDaemons/limit.maxfiles.plist` (requires sudo).

### Linux: inotify Watch Limits
If Linux, increase `fs.inotify.max_user_watches` to 524288.

## Step 5: macOS Tweaks

Apply only on macOS:
- Disable App Nap for terminal
- Prevent .DS_Store on network/USB volumes
- Create caffeinate aliases for long sessions: `alias claude-long="caffeinate -dims claude"`

System animation changes are OPTIONAL and commented out by default.

## Step 6: .claudeignore Enhancement

Merge comprehensive ignore patterns (if not already done by `/setup-foundation`): dependencies, build output, lock files, generated/compiled files, binary/data files, coverage/test artifacts, IDE/OS files.

## Step 7: Token & Context Optimization

Add to `~/.claude/settings.json`:
```json
{
  "env": {
    "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "60",
    "ENABLE_TOOL_SEARCH": "auto:5"
  }
}
```

Add to CLAUDE.md as reminders:
- `/clear` between unrelated tasks
- `/compact <focus>` at logical breakpoints
- Use Plan mode before multi-file refactors
- Use subagents for verbose operations
- Scope investigations narrowly

## Step 8: Terminal Recommendation

If high-latency terminal detected, recommend:
| Terminal | Latency |
|----------|---------|
| Ghostty | 2ms |
| Alacritty | 3ms |
| Kitty | 3ms |
| WezTerm | 4ms |

## Step 9: Post-Optimization Measurements

Re-run all baselines and display before/after comparison table.

## Manual Steps

List for user:
1. Terminal switch (if recommended)
2. Docker VirtioFS (must be changed in Docker Desktop GUI)
3. DNS caching (optional): `brew install dnsmasq`
4. RAM disk for build cache (optional): `brew install --cask tmpdisk`

Next: `/setup-verify` for comprehensive validation.
