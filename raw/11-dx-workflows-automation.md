# R11: Developer Experience -- Keyboard Shortcuts, Workflows, and Automation

> Exhaustive reference for Claude Code DX features: every shortcut, slash command, CLI flag, workflow pattern, automation technique, IDE integration, and productivity tool.

---

## Table of Contents

1. [Keyboard Shortcuts (Complete Reference)](#1-keyboard-shortcuts)
2. [Keybindings Customization](#2-keybindings-customization)
3. [Vim Mode](#3-vim-mode)
4. [Slash Commands (Built-in)](#4-slash-commands)
5. [Bundled Skills](#5-bundled-skills)
6. [CLI Flags (Complete Reference)](#6-cli-flags)
7. [Headless Mode / Non-Interactive (-p)](#7-headless-mode)
8. [Output Formats and Structured Output](#8-output-formats)
9. [Session Management](#9-session-management)
10. [Shell Aliases and Functions](#10-shell-aliases)
11. [CI/CD Integration](#11-cicd-integration)
12. [GitHub Actions](#12-github-actions)
13. [Automation Patterns](#13-automation-patterns)
14. [Status Line Customization](#14-status-line)
15. [Output Styles](#15-output-styles)
16. [Fast Mode](#16-fast-mode)
17. [Extended Thinking](#17-extended-thinking)
18. [IDE Integration: VS Code](#18-vs-code)
19. [IDE Integration: JetBrains](#19-jetbrains)
20. [Desktop App and Cross-Surface Workflows](#20-desktop-and-cross-surface)
21. [Skills System (Custom Commands)](#21-skills-system)
22. [Prompt Suggestions and Autocomplete](#22-prompt-suggestions)
23. [Git Worktrees and Parallel Sessions](#23-git-worktrees)
24. [Background Tasks](#24-background-tasks)
25. [Terminal Configuration](#25-terminal-configuration)
26. [Quick-Reference Cheat Sheet](#26-cheat-sheet)

---

## 1. Keyboard Shortcuts

**Source**: [code.claude.com/docs/en/interactive-mode](https://code.claude.com/docs/en/interactive-mode)

> macOS note: Option/Alt shortcuts (`Alt+B`, `Alt+F`, `Alt+Y`, `Alt+M`, `Alt+P`) require configuring Option as Meta in your terminal. iTerm2: Profiles > Keys > set Option to "Esc+". Terminal.app: Profiles > Keyboard > "Use Option as Meta Key". VS Code: set "terminal.integrated.macOptionIsMeta": true.

### General Controls

| Shortcut | Description | Notes |
|----------|-------------|-------|
| `Ctrl+C` | Cancel current input/generation | Standard interrupt, cannot be rebound |
| `Ctrl+D` | Exit Claude Code session | EOF signal, cannot be rebound |
| `Ctrl+F` | Kill all background agents | Press twice within 3s to confirm |
| `Ctrl+G` | Open in external text editor | Edit prompt in $EDITOR (vim, nano, etc.) |
| `Ctrl+L` | Clear terminal screen | Keeps conversation history |
| `Ctrl+O` | Toggle verbose output | Shows detailed tool usage, thinking |
| `Ctrl+R` | Reverse search command history | Interactive search through previous inputs |
| `Ctrl+V` / `Cmd+V` / `Alt+V` | Paste image from clipboard | Platform-dependent |
| `Ctrl+B` | Background running tasks | Tmux users: press twice (conflicts with prefix) |
| `Ctrl+T` | Toggle task list | Show/hide tasks in terminal status area |
| `Left/Right arrows` | Cycle through dialog tabs | In permission dialogs and menus |
| `Up/Down arrows` | Navigate command history | Recall previous inputs |
| `Esc + Esc` | Rewind or summarize | Restore code/conversation to earlier point |
| `Shift+Tab` | Toggle permission modes | Cycle: Normal -> Auto-Accept -> Plan Mode |
| `Alt+P` / `Option+P` | Switch model | Without clearing prompt |
| `Alt+T` / `Option+T` | Toggle extended thinking | Run `/terminal-setup` first to enable |
| `?` | Show help/shortcuts | Context-dependent |

### Text Editing

| Shortcut | Description |
|----------|-------------|
| `Ctrl+K` | Delete to end of line (stores for paste) |
| `Ctrl+U` | Delete entire line (stores for paste) |
| `Ctrl+Y` | Paste deleted text |
| `Alt+Y` (after Ctrl+Y) | Cycle paste history |
| `Alt+B` | Move cursor back one word |
| `Alt+F` | Move cursor forward one word |
| `Ctrl+A` | Move to start of line |
| `Ctrl+E` | Move to end of line |
| `Ctrl+W` | Delete previous word |

### Multiline Input

| Method | Shortcut | Notes |
|--------|----------|-------|
| Quick escape | `\` + `Enter` | Works in all terminals |
| macOS default | `Option+Enter` | Default on macOS |
| Shift+Enter | `Shift+Enter` | iTerm2, WezTerm, Ghostty, Kitty natively |
| Line feed | `Ctrl+J` | Control sequence for multiline |
| Paste mode | Paste directly | For code blocks, logs |

> For other terminals (VS Code, Alacritty, Zed, Warp), run `/terminal-setup` to install Shift+Enter binding.

### Quick Commands (Prefix Shortcuts)

| Prefix | Action | Notes |
|--------|--------|-------|
| `/` at start | Invoke slash command or skill | See Section 4 |
| `!` at start | Bash mode (direct shell) | Output added to context |
| `@` | File path autocomplete | Fuzzy matching, supports directories |

### Agent Team Shortcuts

| Shortcut | Description |
|----------|-------------|
| `Shift+Down` | Cycle through teammates |
| `Enter` | View teammate session |
| `Escape` | Interrupt teammate |
| `Ctrl+T` | Toggle task list |

---

## 2. Keybindings Customization

**Source**: [code.claude.com/docs/en/keybindings](https://code.claude.com/docs/en/keybindings)

### Configuration File

Run `/keybindings` to create or open `~/.claude/keybindings.json`. Changes are **auto-detected and applied without restart**.

### File Structure

```json
{
  "$schema": "https://www.schemastore.org/claude-code-keybindings.json",
  "$docs": "https://code.claude.com/docs/en/keybindings",
  "bindings": [
    {
      "context": "Chat",
      "bindings": {
        "ctrl+e": "chat:externalEditor",
        "ctrl+u": null
      }
    }
  ]
}
```

### 17 Available Contexts

| Context | Description |
|---------|-------------|
| `Global` | Everywhere in the app |
| `Chat` | Main chat input area |
| `Autocomplete` | Autocomplete menu open |
| `Settings` | Settings menu |
| `Confirmation` | Permission/confirmation dialogs |
| `Tabs` | Tab navigation |
| `Help` | Help menu visible |
| `Transcript` | Transcript viewer |
| `HistorySearch` | History search (Ctrl+R) |
| `Task` | Background task running |
| `ThemePicker` | Theme picker dialog |
| `Attachments` | Image/attachment bar |
| `Footer` | Footer indicator navigation |
| `MessageSelector` | Rewind/summarize dialog |
| `DiffDialog` | Diff viewer navigation |
| `ModelPicker` | Model picker effort level |
| `Select` | Generic select/list components |
| `Plugin` | Plugin dialog |

### Key Syntax

```
ctrl+k              # Single modifier + key
shift+tab            # Shift + Tab
meta+p               # Command/Meta + P
ctrl+shift+c         # Multiple modifiers
ctrl+k ctrl+s        # Chord (multi-key sequence)
K                    # Uppercase implies Shift (K = shift+k)
```

**Modifiers**: `ctrl`/`control`, `alt`/`opt`/`option`, `shift`, `meta`/`cmd`/`command`

**Special keys**: `escape`/`esc`, `enter`/`return`, `tab`, `space`, `up`/`down`/`left`/`right`, `backspace`, `delete`

### Unbinding Defaults

Set any action to `null`:

```json
{
  "context": "Chat",
  "bindings": {
    "ctrl+s": null
  }
}
```

### Reserved (Cannot Be Rebound)

| Shortcut | Reason |
|----------|--------|
| `Ctrl+C` | Hardcoded interrupt |
| `Ctrl+D` | Hardcoded exit |

### Terminal Conflicts

| Shortcut | Conflict |
|----------|----------|
| `Ctrl+B` | tmux prefix (press twice) |
| `Ctrl+A` | GNU screen prefix |
| `Ctrl+Z` | Unix process suspend (SIGTSTP) |

### All Available Actions (Organized by Context)

**Global/App**:
- `app:interrupt` (Ctrl+C), `app:exit` (Ctrl+D), `app:toggleTodos` (Ctrl+T), `app:toggleTranscript` (Ctrl+O)

**Chat**:
- `chat:cancel` (Escape), `chat:cycleMode` (Shift+Tab), `chat:modelPicker` (Cmd+P/Meta+P), `chat:thinkingToggle` (Cmd+T/Meta+T), `chat:submit` (Enter), `chat:undo` (Ctrl+_), `chat:externalEditor` (Ctrl+G), `chat:stash` (Ctrl+S), `chat:imagePaste` (Ctrl+V)

**History**: `history:search` (Ctrl+R), `history:previous` (Up), `history:next` (Down)

**Autocomplete**: `autocomplete:accept` (Tab), `autocomplete:dismiss` (Escape), `autocomplete:previous` (Up), `autocomplete:next` (Down)

**Confirmation**: `confirm:yes` (Y/Enter), `confirm:no` (N/Escape), `confirm:cycleMode` (Shift+Tab), `confirm:toggleExplanation` (Ctrl+E), `permission:toggleDebug` (Ctrl+D)

**Transcript**: `transcript:toggleShowAll` (Ctrl+E), `transcript:exit` (Ctrl+C/Escape)

**History Search**: `historySearch:next` (Ctrl+R), `historySearch:accept` (Escape/Tab), `historySearch:cancel` (Ctrl+C), `historySearch:execute` (Enter)

**Task**: `task:background` (Ctrl+B)

**Theme**: `theme:toggleSyntaxHighlighting` (Ctrl+T)

**Diff**: `diff:dismiss` (Escape), `diff:previousSource/nextSource` (Left/Right), `diff:previousFile/nextFile` (Up/Down), `diff:viewDetails` (Enter)

**Model Picker**: `modelPicker:decreaseEffort` (Left), `modelPicker:increaseEffort` (Right)

**Select**: `select:next` (Down/J/Ctrl+N), `select:previous` (Up/K/Ctrl+P), `select:accept` (Enter), `select:cancel` (Escape)

**Plugin**: `plugin:toggle` (Space), `plugin:install` (I)

**Settings**: `settings:search` (/), `settings:retry` (R)

**Message Selector**: `messageSelector:up` (Up/K), `messageSelector:down` (Down/J), `messageSelector:top` (Ctrl+Up/Shift+K), `messageSelector:bottom` (Ctrl+Down/Shift+J), `messageSelector:select` (Enter)

**Footer**: `footer:next` (Right), `footer:previous` (Left), `footer:openSelected` (Enter), `footer:clearSelection` (Escape)

**Attachments**: `attachments:next` (Right), `attachments:previous` (Left), `attachments:remove` (Backspace/Delete), `attachments:exit` (Down/Escape)

**Tabs**: `tabs:next` (Tab/Right), `tabs:previous` (Shift+Tab/Left)

### Example Configurations

**tmux-Friendly** (avoid prefix conflicts):
```json
{
  "bindings": [{
    "context": "Task",
    "bindings": {
      "ctrl+b": null,
      "ctrl+shift+b": "task:background"
    }
  }]
}
```

**Chord-Based Power User**:
```json
{
  "bindings": [{
    "context": "Chat",
    "bindings": {
      "ctrl+k ctrl+t": "chat:thinkingToggle",
      "ctrl+k ctrl+m": "chat:modelPicker",
      "ctrl+k ctrl+e": "chat:externalEditor"
    }
  }]
}
```

### Validation

Run `/doctor` to check for keybinding warnings: parse errors, invalid contexts, reserved conflicts, terminal conflicts, duplicate bindings.

---

## 3. Vim Mode

**Source**: [code.claude.com/docs/en/interactive-mode](https://code.claude.com/docs/en/interactive-mode)

Enable with `/vim` command or configure permanently via `/config`.

### Mode Switching

| Command | Action | From |
|---------|--------|------|
| `Esc` | Enter NORMAL | INSERT |
| `i` | Insert before cursor | NORMAL |
| `I` | Insert at line start | NORMAL |
| `a` | Insert after cursor | NORMAL |
| `A` | Insert at line end | NORMAL |
| `o` | Open line below | NORMAL |
| `O` | Open line above | NORMAL |

### Navigation (NORMAL)

`h/j/k/l` (move), `w` (next word), `e` (end word), `b` (prev word), `0` (line start), `$` (line end), `^` (first non-blank), `gg` (input start), `G` (input end), `f{char}` (jump to char), `F{char}` (jump back), `t{char}` (just before), `T{char}` (just after), `;` (repeat), `,` (reverse)

### Editing (NORMAL)

`x` (delete char), `dd` (delete line), `D` (delete to EOL), `dw/de/db`, `cc` (change line), `C` (change to EOL), `cw/ce/cb`, `yy/Y` (yank line), `yw/ye/yb`, `p/P` (paste after/before), `>>/<<` (indent/dedent), `J` (join), `.` (repeat)

### Text Objects

`iw/aw` (word), `iW/aW` (WORD), `i"/a"` (quotes), `i'/a'` (single quotes), `i(/a(`, `i[/a[`, `i{/a{`

### Integration

- Vim mode handles input at text level; keybindings handle app-level actions
- Escape switches vim modes; does NOT trigger `chat:cancel`
- Most `Ctrl+key` shortcuts pass through vim to keybinding system
- In NORMAL mode, `?` shows vim help

---

## 4. Slash Commands (Built-in)

**Source**: [code.claude.com/docs/en/interactive-mode#built-in-commands](https://code.claude.com/docs/en/interactive-mode#built-in-commands)

Type `/` to see all commands, or `/` + letters to filter.

| Command | Purpose |
|---------|---------|
| `/add-dir <path>` | Add working directory to session |
| `/agents` | Manage subagent configurations |
| `/chrome` | Configure Chrome integration |
| `/clear` | Clear conversation history (aliases: `/reset`, `/new`) |
| `/compact [instructions]` | Compact conversation with optional focus |
| `/config` | Open Settings interface (alias: `/settings`) |
| `/context` | Visualize context usage as colored grid |
| `/copy` | Copy last response to clipboard (with code block picker) |
| `/cost` | Show token usage statistics |
| `/desktop` | Continue session in Desktop app (alias: `/app`) |
| `/diff` | Interactive diff viewer (uncommitted + per-turn diffs) |
| `/doctor` | Diagnose installation and settings |
| `/exit` | Exit (alias: `/quit`) |
| `/export [filename]` | Export conversation as plain text |
| `/extra-usage` | Configure extra usage for rate limits |
| `/fast [on\|off]` | Toggle fast mode (2.5x speed, higher cost) |
| `/feedback [report]` | Submit feedback (alias: `/bug`) |
| `/fork [name]` | Fork conversation at this point |
| `/help` | Show help and commands |
| `/hooks` | Manage hook configurations |
| `/ide` | Manage IDE integrations |
| `/init` | Initialize CLAUDE.md |
| `/insights` | Analyze sessions (areas, patterns, friction) |
| `/install-github-app` | Set up GitHub Actions app |
| `/install-slack-app` | Install Claude Slack app |
| `/keybindings` | Open keybindings.json |
| `/login` | Sign in |
| `/logout` | Sign out |
| `/mcp` | Manage MCP servers and OAuth |
| `/memory` | Edit CLAUDE.md, auto-memory |
| `/mobile` | QR code for mobile app (aliases: `/ios`, `/android`) |
| `/model [model]` | Select/change model (left/right for effort) |
| `/output-style [style]` | Switch output styles |
| `/passes` | Share free week (if eligible) |
| `/permissions` | View/update permissions (alias: `/allowed-tools`) |
| `/plan` | Enter plan mode |
| `/plugin` | Manage plugins |
| `/pr-comments [PR]` | Fetch PR comments (auto-detects current branch) |
| `/privacy-settings` | Privacy settings (Pro/Max only) |
| `/release-notes` | View changelog |
| `/reload-plugins` | Reload active plugins |
| `/remote-control` | Remote control from claude.ai (alias: `/rc`) |
| `/remote-env` | Configure remote environment for teleport |
| `/rename [name]` | Rename session (auto-generates if empty) |
| `/resume [session]` | Resume conversation (alias: `/continue`) |
| `/review` | Review PR for quality, security, tests |
| `/rewind` | Rewind conversation/code (alias: `/checkpoint`) |
| `/sandbox` | Toggle sandbox mode |
| `/security-review` | Analyze changes for security vulnerabilities |
| `/skills` | List available skills |
| `/stats` | Visualize daily usage, streaks, model preferences |
| `/status` | Status tab (version, model, account) |
| `/statusline` | Configure status line |
| `/stickers` | Order Claude Code stickers |
| `/tasks` | List/manage background tasks |
| `/terminal-setup` | Configure terminal keybindings |
| `/theme` | Change color theme (light/dark/daltonized/ANSI) |
| `/upgrade` | Open upgrade page |
| `/usage` | Show plan limits and rate status |
| `/vim` | Toggle vim/normal editing |

### MCP Prompts as Commands

MCP servers expose prompts as `/mcp__<server>__<prompt>` commands, dynamically discovered from connected servers.

---

## 5. Bundled Skills

**Source**: [code.claude.com/docs/en/skills](https://code.claude.com/docs/en/skills)

Bundled skills ship with Claude Code and are prompt-based (not fixed logic):

| Skill | Purpose |
|-------|---------|
| `/simplify` | Reviews recently changed files for code reuse, quality, efficiency. Spawns 3 parallel review agents. Optional focus text. |
| `/batch <instruction>` | Orchestrates large-scale changes in parallel. Decomposes into 5-30 units, each in isolated worktree. Opens individual PRs. |
| `/debug [description]` | Troubleshoots current session by reading debug log. |
| `/claude-api` | Loads Claude API reference for your project language (Python, TS, Java, Go, Ruby, C#, PHP, cURL). Auto-activates on `anthropic` imports. |

---

## 6. CLI Flags (Complete Reference)

**Source**: [code.claude.com/docs/en/cli-reference](https://code.claude.com/docs/en/cli-reference)

### CLI Commands

| Command | Description |
|---------|-------------|
| `claude` | Start interactive session |
| `claude "query"` | Start with initial prompt |
| `claude -p "query"` | Non-interactive (headless), print and exit |
| `cat file \| claude -p "query"` | Process piped content |
| `claude -c` | Continue most recent conversation |
| `claude -c -p "query"` | Continue via SDK (non-interactive) |
| `claude -r "session" "query"` | Resume by ID or name |
| `claude update` | Update to latest version |
| `claude auth login` | Sign in (supports `--email`, `--sso`) |
| `claude auth logout` | Sign out |
| `claude auth status` | Auth status as JSON (`--text` for human-readable) |
| `claude agents` | List all configured subagents |
| `claude mcp` | Configure MCP servers |
| `claude remote-control` | Start remote control session |

### All CLI Flags

| Flag | Description |
|------|-------------|
| `--add-dir` | Add additional working directories |
| `--agent` | Specify agent for session |
| `--agents` | Define custom subagents via JSON |
| `--allow-dangerously-skip-permissions` | Enable permission bypass as option |
| `--allowedTools` | Tools that execute without prompting |
| `--append-system-prompt` | Append to default system prompt |
| `--append-system-prompt-file` | Append system prompt from file |
| `--betas` | Beta headers for API requests |
| `--chrome` | Enable Chrome integration |
| `--continue` / `-c` | Load most recent conversation |
| `--dangerously-skip-permissions` | Skip all permission prompts |
| `--debug` | Enable debug mode with category filtering |
| `--disable-slash-commands` | Disable all skills/commands |
| `--disallowedTools` | Tools removed from model context |
| `--fallback-model` | Fallback model when default overloaded (print mode) |
| `--fork-session` | Create new session ID when resuming |
| `--from-pr` | Resume sessions linked to GitHub PR |
| `--ide` | Auto-connect to IDE on startup |
| `--init` | Run initialization hooks + interactive |
| `--init-only` | Run initialization hooks + exit |
| `--include-partial-messages` | Include streaming events (stream-json) |
| `--input-format` | Input format: `text`, `stream-json` |
| `--json-schema` | Get validated JSON matching schema (print mode) |
| `--maintenance` | Run maintenance hooks + exit |
| `--max-budget-usd` | Max dollar spend (print mode) |
| `--max-turns` | Limit agentic turns (print mode) |
| `--mcp-config` | Load MCP servers from JSON files |
| `--model` | Set model (aliases: `sonnet`, `opus`) |
| `--no-chrome` | Disable Chrome for session |
| `--no-session-persistence` | Don't save session to disk (print mode) |
| `--output-format` | Output: `text`, `json`, `stream-json` |
| `--permission-mode` | Start in permission mode: `plan`, `bypassPermissions` |
| `--permission-prompt-tool` | MCP tool for permission prompts (non-interactive) |
| `--plugin-dir` | Load plugins from directory |
| `--print` / `-p` | Non-interactive mode |
| `--remote` | Create web session on claude.ai |
| `--resume` / `-r` | Resume session by ID or name |
| `--session-id` | Use specific session UUID |
| `--setting-sources` | Setting sources: `user`, `project`, `local` |
| `--settings` | Path to settings JSON |
| `--strict-mcp-config` | Only use MCP from --mcp-config |
| `--system-prompt` | Replace entire system prompt |
| `--system-prompt-file` | Replace system prompt from file |
| `--teleport` | Resume web session in terminal |
| `--teammate-mode` | Team display: `auto`, `in-process`, `tmux` |
| `--tools` | Restrict built-in tools: `""`, `"default"`, `"Bash,Edit,Read"` |
| `--verbose` | Verbose logging |
| `--version` / `-v` | Show version |
| `--worktree` / `-w` | Start in isolated git worktree |

### System Prompt Flags

| Flag | Behavior | Use Case |
|------|----------|----------|
| `--system-prompt` | **Replace** entire prompt | Complete control |
| `--system-prompt-file` | **Replace** from file | Reproducibility |
| `--append-system-prompt` | **Append** to default | Add instructions, keep defaults |
| `--append-system-prompt-file` | **Append** file to default | Version-controlled additions |

`--system-prompt` and `--system-prompt-file` are mutually exclusive. Append flags can combine with either.

### --agents Flag Format

```bash
claude --agents '{
  "code-reviewer": {
    "description": "Expert code reviewer",
    "prompt": "You are a senior code reviewer.",
    "tools": ["Read", "Grep", "Glob", "Bash"],
    "model": "sonnet"
  }
}'
```

Fields: `description` (required), `prompt` (required), `tools`, `disallowedTools`, `model`, `skills`, `mcpServers`, `maxTurns`

---

## 7. Headless Mode

**Source**: [code.claude.com/docs/en/headless](https://code.claude.com/docs/en/headless)

The `-p` (or `--print`) flag runs Claude non-interactively. All CLI options work with `-p`.

### Basic Usage

```bash
# Simple query
claude -p "What does the auth module do?"

# With tool permissions
claude -p "Run tests and fix failures" --allowedTools "Bash,Read,Edit"

# With budget limit
claude -p "Refactor auth" --max-budget-usd 5.00

# With turn limit
claude -p "Fix the bug" --max-turns 3

# With custom system prompt
gh pr diff "$1" | claude -p --append-system-prompt "You are a security engineer." --output-format json
```

### Structured Output with JSON Schema

```bash
claude -p "Extract function names from auth.py" \
  --output-format json \
  --json-schema '{"type":"object","properties":{"functions":{"type":"array","items":{"type":"string"}}},"required":["functions"]}'
```

### Streaming

```bash
claude -p "Write a poem" --output-format stream-json --verbose --include-partial-messages | \
  jq -rj 'select(.type == "stream_event" and .event.delta.type? == "text_delta") | .event.delta.text'
```

### Continue Conversations

```bash
# First request
claude -p "Review this codebase for performance issues"

# Continue most recent
claude -p "Focus on database queries" --continue

# Capture session ID for specific resumption
session_id=$(claude -p "Start a review" --output-format json | jq -r '.session_id')
claude -p "Continue that review" --resume "$session_id"
```

### Create Commits (Headless)

```bash
claude -p "Look at staged changes and create a commit" \
  --allowedTools "Bash(git diff *),Bash(git log *),Bash(git status *),Bash(git commit *)"
```

---

## 8. Output Formats

### Three Formats

| Format | Output | Use Case |
|--------|--------|----------|
| `text` (default) | Plain text response | Human reading, simple scripts |
| `json` | JSON with result, session_id, metadata, cost | Programmatic parsing |
| `stream-json` | NDJSON (one object per line) | Real-time processing |

### JSON Output Structure

```json
{
  "type": "result",
  "result": "...",
  "session_id": "...",
  "cost_usd": 0.042,
  "duration_ms": 3200,
  "num_turns": 1,
  "structured_output": { ... }
}
```

### Parsing with jq

```bash
# Extract text result
claude -p "Summarize" --output-format json | jq -r '.result'

# Extract structured output
claude -p "Extract names" --output-format json --json-schema '{...}' | jq '.structured_output'

# Extract session ID
claude -p "Start" --output-format json | jq -r '.session_id'
```

---

## 9. Session Management

### Resume Sessions

```bash
claude --continue          # Most recent in current directory
claude --resume            # Interactive picker
claude --resume auth-refactor  # By name
claude --resume abc123     # By ID
claude --from-pr 123       # Sessions linked to PR
claude --fork-session --resume abc123  # Fork instead of reuse
```

### Name Sessions

```bash
/rename auth-refactor      # During session
claude --resume auth-refactor  # Later
```

### Session Picker Shortcuts

| Shortcut | Action |
|----------|--------|
| `Up/Down` | Navigate sessions |
| `Left/Right` | Expand/collapse groups |
| `Enter` | Resume selected |
| `P` | Preview session |
| `R` | Rename session |
| `/` | Search/filter |
| `A` | Toggle current dir / all projects |
| `B` | Filter to current git branch |
| `Esc` | Exit picker |

### PR Link in Footer

When on a branch with open PR, footer shows clickable "PR #NNN" with colored underline:
- Green: approved
- Yellow: pending
- Red: changes requested
- Gray: draft
- Purple: merged

`Cmd+click` (Mac) / `Ctrl+click` to open in browser. Updates every 60s. Requires `gh` CLI.

---

## 10. Shell Aliases and Functions

### Essential Aliases

```bash
# ~/.zshrc or ~/.bashrc

# Quick launch
alias cc="claude"
alias ccc="claude --continue"
alias ccr="claude --resume"

# Headless queries
alias cq="claude -p"
alias cqj="claude -p --output-format json"

# Model shortcuts
alias cco="claude --model opus"
alias ccs="claude --model sonnet"

# Fast mode
alias ccf="claude --model opus" # use /fast inside

# Worktree sessions
alias ccw="claude --worktree"

# Plan mode
alias ccp="claude --permission-mode plan"

# Skip permissions (dangerous)
alias ccy="claude --dangerously-skip-permissions"
```

### Productivity Functions

```bash
# Quick code review
cr() {
  git diff "${1:-main}" | claude -p "Review this diff for bugs, security issues, and improvements" --output-format text
}

# Fix and commit
fix() {
  claude -p "$1" --allowedTools "Bash,Read,Edit,Write"
}

# Explain a file
explain() {
  claude -p "Explain what this file does and its key patterns" < "$1"
}

# Summarize git log
gitsum() {
  git log --oneline -"${1:-20}" | claude -p "Summarize these commits by theme"
}

# Claude as linter
clint() {
  claude -p "You are a linter. Check the changes vs main. Report filename:line and description." --output-format text
}

# Generate tests for a file
ctest() {
  claude -p "Generate comprehensive tests for this file: $1" --allowedTools "Read,Write,Bash"
}

# Security review
csec() {
  git diff "${1:-main}" | claude -p "Security review: identify vulnerabilities, injection risks, auth issues" --output-format text
}

# claudify / fire-and-forget (from edspencer.net)
claudify() {
  claude -p "$*" --allowedTools "Bash,Read,Edit,Write" --max-turns 10 &
}
alias fix="claudify"
```

### Piping Patterns

```bash
# Pipe error logs
cat build-error.txt | claude -p "Explain the root cause" > diagnosis.txt

# Pipe git diff
git diff main | claude -p "Review for security issues"

# Pipe file listing
ls -la | claude -p "Explain this directory structure"

# Monitor logs
tail -f app.log | claude -p "Alert me about anomalies"

# Chain with other tools
git diff main --name-only | claude -p "Review changed files for security"
```

### Zsh Plugin: zsh-claude-code-shell

From [ArielTM/zsh-claude-code-shell](https://github.com/ArielTM/zsh-claude-code-shell): Integrates Claude CLI into your shell. Chat with Claude and execute AI-generated commands from your prompt.

### Loading ZSH Functions into Claude Code

From [John Lindquist's gist](https://gist.github.com/johnlindquist/a22d4171e56107b55d60db4a0e929fb3): Source your zsh functions to make them available to Claude Code's Bash tool.

---

## 11. CI/CD Integration

### General Pattern

```bash
# In any CI pipeline
claude -p "your task" \
  --output-format json \
  --allowedTools "Read,Write" \
  --max-turns 10 \
  --max-budget-usd 2.00
```

### package.json Integration

```json
{
  "scripts": {
    "lint:claude": "claude -p 'you are a linter. look at changes vs. main and report typos. report filename:line on one line, description on second.'",
    "review:claude": "git diff main | claude -p 'review for security issues' --output-format json > review.json",
    "docs:generate": "claude -p 'generate JSDoc for all exported functions' --allowedTools Read,Write --max-turns 10",
    "test:generate": "claude -p 'generate missing unit tests' --allowedTools Read,Write,Bash --max-turns 10"
  }
}
```

### Environment Variables for CI

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
export CLAUDE_CODE_MAX_TURNS=5
export CLAUDE_CODE_OUTPUT_FORMAT=json
export CLAUDE_CODE_MODEL=claude-sonnet-4-6
```

### Performance in CI

- Startup time: ~800ms
- Memory: <256MB typical
- Cost per run: $0.03-$0.20
- Code review: 15-45 seconds
- Default timeout: 120 seconds

---

## 12. GitHub Actions

**Source**: [code.claude.com/docs/en/github-actions](https://code.claude.com/docs/en/github-actions)

### Quick Setup

Run `/install-github-app` inside Claude Code to set up automatically.

### Basic Workflow

```yaml
name: Claude Code
on:
  issue_comment:
    types: [created]
  pull_request_review_comment:
    types: [created]
jobs:
  claude:
    runs-on: ubuntu-latest
    steps:
      - uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
```

### With Skills

```yaml
- uses: anthropics/claude-code-action@v1
  with:
    anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
    prompt: "/review"
    claude_args: "--max-turns 5"
```

### Scheduled Automation

```yaml
name: Daily Report
on:
  schedule:
    - cron: "0 9 * * *"
jobs:
  report:
    runs-on: ubuntu-latest
    steps:
      - uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          prompt: "Generate a summary of yesterday's commits and open issues"
          claude_args: "--model opus"
```

### Action Parameters (v1)

| Parameter | Required | Description |
|-----------|----------|-------------|
| `prompt` | No | Instructions (text or skill) |
| `claude_args` | No | CLI arguments |
| `anthropic_api_key` | Yes* | API key |
| `github_token` | No | GitHub token |
| `trigger_phrase` | No | Custom trigger (default: "@claude") |
| `use_bedrock` | No | Use AWS Bedrock |
| `use_vertex` | No | Use Google Vertex AI |

### Usage Triggers

In issue/PR comments:
```
@claude implement this feature based on the issue description
@claude fix the TypeError in the user dashboard component
@claude review this PR for security issues
```

### Cloud Provider Support

- **AWS Bedrock**: OIDC-based auth, model format `us.anthropic.claude-sonnet-4-6`
- **Google Vertex AI**: Workload Identity Federation, model format `claude-sonnet-4@20250514`

### GitLab CI/CD

Also supported. See [code.claude.com/docs/en/gitlab-ci-cd](https://code.claude.com/docs/en/gitlab-ci-cd).

---

## 13. Automation Patterns

### Pre-Commit Hook with Claude

```bash
# .git/hooks/pre-commit or via husky
#!/bin/bash
git diff --cached | claude -p "Check for security issues, exposed secrets, or obvious bugs. Output 'PASS' if clean, or describe issues." --output-format text | grep -q "PASS"
```

### Automated Test Generation

```bash
# After each commit
claude -p "Generate unit tests for changed files" \
  --allowedTools Read,Write,Bash \
  --max-turns 5 \
  --output-format json > test-results.json
```

### Batch File Processing

```bash
# Process multiple files
find src/ -name "*.ts" -newer last-review | while read f; do
  claude -p "Review $f for quality issues" --output-format json >> reviews.json
done
```

### Watch Mode Pattern

```bash
# File watcher + Claude
fswatch -o src/ | while read; do
  claude -p "Check recent changes for issues" --continue --max-turns 1
done
```

### Cron Job Pattern

```bash
# Daily code health check
0 8 * * * cd /project && claude -p "Generate a code health report" --output-format json > /reports/$(date +%Y%m%d).json
```

### Multi-Step Pipeline

```bash
# Step 1: Analyze
analysis=$(claude -p "Analyze auth module architecture" --output-format json)
session_id=$(echo "$analysis" | jq -r '.session_id')

# Step 2: Plan (continuing same session)
claude -p "Create a refactoring plan" --resume "$session_id" --output-format json > plan.json

# Step 3: Execute
claude -p "Execute the plan" --resume "$session_id" --allowedTools "Bash,Read,Edit,Write"
```

### Structured Output for Automation

```bash
# Extract specific data
claude -p "List all API endpoints in this project" \
  --output-format json \
  --json-schema '{
    "type": "object",
    "properties": {
      "endpoints": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "method": {"type": "string"},
            "path": {"type": "string"},
            "description": {"type": "string"}
          }
        }
      }
    }
  }' | jq '.structured_output.endpoints'
```

---

## 14. Status Line Customization

**Source**: [code.claude.com/docs/en/statusline](https://code.claude.com/docs/en/statusline)

The status line is a customizable bar at the bottom of Claude Code that runs any shell script you configure. It receives JSON session data on stdin.

### Quick Setup

```bash
/statusline    # Auto-configure from your shell prompt
/statusline "show git branch, context usage, and cost"  # Describe what you want
```

### Configuration (settings.json)

```json
{
  "statusLine": {
    "command": "~/.claude/status.sh",
    "interval": 5
  }
}
```

### Session Data (JSON on stdin)

| Field | Type | Description |
|-------|------|-------------|
| `context_window_tokens` | number | Total context window size |
| `context_window_used_tokens` | number | Tokens currently used |
| `context_window_used_percent` | number | Percentage used |
| `model` | string | Current model name |
| `session_id` | string | Current session ID |
| `session_name` | string | Session name |
| `total_cost_usd` | number | Session cost |
| `total_turns` | number | Number of turns |
| `cwd` | string | Working directory |
| `git_branch` | string | Current branch |
| `fast_mode` | boolean | Fast mode status |
| `thinking_enabled` | boolean | Thinking mode status |
| `permission_mode` | string | Current permission mode |

### Example Scripts

**Context bar with color coding**:
```bash
#!/bin/bash
read -r DATA
PCT=$(echo "$DATA" | jq '.context_window_used_percent')
MODEL=$(echo "$DATA" | jq -r '.model')
COST=$(echo "$DATA" | jq '.total_cost_usd')

if (( $(echo "$PCT > 80" | bc -l) )); then
  COLOR="\033[31m"  # Red
elif (( $(echo "$PCT > 50" | bc -l) )); then
  COLOR="\033[33m"  # Yellow
else
  COLOR="\033[32m"  # Green
fi

printf "${COLOR}%.0f%%\033[0m | %s | \$%.3f" "$PCT" "$MODEL" "$COST"
```

**Multi-line status** (first line git, second line context):
```bash
#!/bin/bash
read -r DATA
BRANCH=$(echo "$DATA" | jq -r '.git_branch // "no branch"')
PCT=$(echo "$DATA" | jq '.context_window_used_percent')
printf "git:%s\n%.0f%% context" "$BRANCH" "$PCT"
```

### Key Details

- `interval` controls refresh rate in seconds (default: 5)
- Script must read one line from stdin (JSON) and print to stdout
- Multi-line output supported
- ANSI color codes supported
- Non-zero exit code = status line hidden
- Scripts should be fast (<1s) to avoid lag

---

## 15. Output Styles

**Source**: [code.claude.com/docs/en/output-styles](https://code.claude.com/docs/en/output-styles)

### Built-in Styles

| Style | Description |
|-------|-------------|
| **Default** | Standard software engineering assistant |
| **Explanatory** | Adds educational "Insights" about implementation choices and codebase patterns |
| **Learning** | Collaborative learn-by-doing mode; adds `TODO(human)` markers for you to implement |

### Switch Styles

```
/output-style                  # Menu selection
/output-style explanatory      # Direct switch
```

Saved to `.claude/settings.local.json` (local project level).

### Custom Output Styles

Create files at `~/.claude/output-styles/` (user) or `.claude/output-styles/` (project):

```markdown
---
name: My Custom Style
description: Brief description for UI
keep-coding-instructions: false
---

# Custom Instructions

You are an interactive CLI tool that [your instructions]...
```

**Frontmatter**:

| Field | Default | Purpose |
|-------|---------|---------|
| `name` | file name | Display name |
| `description` | none | UI description |
| `keep-coding-instructions` | false | Keep default coding prompt parts |

### How They Work

- All output styles exclude concise output instructions
- Custom styles exclude coding instructions (unless `keep-coding-instructions: true`)
- Custom instructions added to end of system prompt
- Reminders injected during conversation to maintain style

---

## 16. Fast Mode

**Source**: [code.claude.com/docs/en/fast-mode](https://code.claude.com/docs/en/fast-mode)

Fast mode = same Opus 4.6, 2.5x faster, higher cost per token. Research preview.

### Toggle

```
/fast          # Toggle on/off
/fast on       # Explicit on
/fast off      # Explicit off
```

Or in settings: `"fastMode": true`

### Pricing

| Mode | Input (MTok) | Output (MTok) |
|------|-------------|---------------|
| Fast (<200K) | $30 | $150 |
| Fast (>200K) | $60 | $225 |

### Behavior

- Switching on auto-selects Opus 4.6
- `lightning` icon appears next to prompt
- Falls back to standard on rate limit (icon turns gray)
- Re-enables automatically after cooldown

### When to Use

- **Fast mode**: rapid iteration, live debugging, time-sensitive work
- **Standard**: long autonomous tasks, batch processing, cost-sensitive

### Combine with Effort Level

Fast mode + low effort = maximum speed for straightforward tasks.

---

## 17. Extended Thinking

### Configuration

| Scope | Method |
|-------|--------|
| Effort level | `/model` or `CLAUDE_CODE_EFFORT_LEVEL` env var |
| ultrathink | Include "ultrathink" in prompt for one-off deep reasoning |
| Toggle shortcut | `Option+T` / `Alt+T` |
| Global default | `/config` (saved as `alwaysThinkingEnabled`) |
| Token budget | `MAX_THINKING_TOKENS` env var |

### Effort Levels (Opus 4.6 / Sonnet 4.6)

- **Low**: Minimal thinking, fastest responses
- **Medium**: Balanced (default)
- **High**: Deep reasoning, slowest

Adjust in `/model` with left/right arrows.

### View Thinking

`Ctrl+O` toggles verbose mode -- thinking shown as gray italic text.

---

## 18. IDE Integration: VS Code

**Source**: [code.claude.com/docs/en/vs-code](https://code.claude.com/docs/en/vs-code)

### Installation

- [Install for VS Code](vscode:extension/anthropic.claude-code)
- [Install for Cursor](cursor:extension/anthropic.claude-code)
- Requires VS Code 1.98.0+

### Key Features

- **Inline diffs**: Side-by-side comparison of proposed changes
- **@-mentions**: `@filename` for file context, fuzzy matching
- **Plan review**: Claude shows plan before execution
- **Auto-accept mode**: Edits applied without asking
- **Conversation history**: Browse past sessions
- **Multiple conversations**: Open in new tab or window
- **Checkpoint/rewind**: Hover over messages to rewind
- **Terminal output reference**: `@terminal:name`
- **Chrome integration**: `@browser` for web automation
- **Plugin management**: `/plugins` in prompt box
- **Remote session resume**: Resume claude.ai sessions locally

### VS Code Shortcuts

| Command | Shortcut | Description |
|---------|----------|-------------|
| Focus Input | `Cmd+Esc` / `Ctrl+Esc` | Toggle focus between editor and Claude |
| Open in New Tab | `Cmd+Shift+Esc` / `Ctrl+Shift+Esc` | New conversation tab |
| New Conversation | `Cmd+N` / `Ctrl+N` | Start new (Claude focused) |
| Insert @-Mention | `Option+K` / `Alt+K` | Insert file + line reference |
| Show Logs | - | View debug logs |

### Extension Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `selectedModel` | `default` | Model for new conversations |
| `useTerminal` | `false` | Terminal mode instead of GUI |
| `initialPermissionMode` | `default` | `default`, `plan`, `acceptEdits`, `bypassPermissions` |
| `preferredLocation` | `panel` | `sidebar` or `panel` |
| `autosave` | `true` | Auto-save before read/write |
| `useCtrlEnterToSend` | `false` | Ctrl/Cmd+Enter to send |
| `respectGitIgnore` | `true` | Exclude .gitignore patterns |
| `allowDangerouslySkipPermissions` | `false` | Bypass all permissions |

### CLI vs Extension Differences

| Feature | CLI | Extension |
|---------|-----|-----------|
| All commands/skills | Yes | Subset |
| MCP config | Yes | No (via CLI) |
| `!` bash shortcut | Yes | No |
| Tab completion | Yes | No |
| Checkpoints | Yes | Yes |

---

## 19. IDE Integration: JetBrains

**Source**: [code.claude.com/docs/en/jetbrains](https://code.claude.com/docs/en/jetbrains)

### Supported IDEs

IntelliJ IDEA, PyCharm, Android Studio, WebStorm, PhpStorm, GoLand

### Features

- **Quick launch**: `Cmd+Esc` / `Ctrl+Esc`
- **Diff viewing**: Changes in IDE diff viewer
- **Selection context**: Current selection auto-shared
- **File references**: `Cmd+Option+K` / `Alt+Ctrl+K` for `@File#L1-99`
- **Diagnostic sharing**: Lint/syntax errors auto-shared

### Configuration

- **Claude command**: Settings > Tools > Claude Code [Beta]
- **ESC key**: Settings > Tools > Terminal > uncheck "Move focus to editor with Escape"
- **Multi-line**: Enable Option+Enter in plugin settings

---

## 20. Desktop App and Cross-Surface Workflows

### Desktop App

- macOS (Intel + Apple Silicon) and Windows (x64 + ARM64)
- Visual diff review, multiple sessions side-by-side, cloud sessions
- Open from CLI: `/desktop` or `/app`

### Cross-Surface Workflows

| From | To | How |
|------|-----|-----|
| Terminal | Desktop | `/desktop` |
| Terminal | Mobile/Browser | `/remote-control` or `/rc` |
| Web/iOS | Terminal | `/teleport` or `claude --teleport` |
| Terminal | Web | `claude --remote "task"` |
| Slack | PR | Mention `@Claude` with bug report |

### Remote Control

Start with `/remote-control` or `claude remote-control`. Control from claude.ai or Claude app.

---

## 21. Skills System (Custom Commands)

**Source**: [code.claude.com/docs/en/skills](https://code.claude.com/docs/en/skills)

### Skill Locations

| Location | Path | Scope |
|----------|------|-------|
| Enterprise | Managed settings | All org users |
| Personal | `~/.claude/skills/<name>/SKILL.md` | All your projects |
| Project | `.claude/skills/<name>/SKILL.md` | This project |
| Plugin | `<plugin>/skills/<name>/SKILL.md` | Where enabled |

Priority: Enterprise > Personal > Project.

### SKILL.md Structure

```yaml
---
name: my-skill
description: When to use this skill
argument-hint: [arg1] [format]
disable-model-invocation: false
user-invocable: true
allowed-tools: Read, Grep
model: sonnet
context: fork
agent: Explore
---

Your instructions here. Use $ARGUMENTS for all args.
Use $ARGUMENTS[0] or $0 for first arg.
Use ${CLAUDE_SESSION_ID} and ${CLAUDE_SKILL_DIR} for session/path info.
```

### Frontmatter Fields

| Field | Default | Purpose |
|-------|---------|---------|
| `name` | directory name | Slash command name |
| `description` | first paragraph | When to use (Claude reads this) |
| `argument-hint` | - | Autocomplete hint |
| `disable-model-invocation` | false | Only user can invoke |
| `user-invocable` | true | Hidden from `/` menu if false |
| `allowed-tools` | all | Restrict tool access |
| `model` | inherit | Model override |
| `context` | inline | `fork` for subagent execution |
| `agent` | general-purpose | Subagent type when forked |
| `hooks` | - | Skill-scoped hooks |

### Dynamic Context Injection

```yaml
---
name: pr-summary
context: fork
agent: Explore
---

PR diff: !`gh pr diff`
PR comments: !`gh pr view --comments`
```

`!`command`` runs before Claude sees the prompt. Output replaces the placeholder.

### Invocation Control

| Setting | You invoke | Claude invokes |
|---------|-----------|---------------|
| Default | Yes | Yes |
| `disable-model-invocation: true` | Yes | No |
| `user-invocable: false` | No | Yes |

### Supporting Files

```
my-skill/
  SKILL.md           # Main (required)
  template.md        # Template for Claude
  examples/sample.md # Expected format
  scripts/validate.sh # Executable
```

### Legacy Compatibility

`.claude/commands/` files still work. Skills (`.claude/skills/`) take precedence on name conflicts.

---

## 22. Prompt Suggestions and Autocomplete

### Prompt Suggestions

- Grayed-out suggestion appears based on git history or conversation
- `Tab` to accept, `Enter` to accept and submit
- Start typing to dismiss
- Uses background request with prompt cache (minimal cost)
- Skipped: after first turn, non-interactive, plan mode, cold cache

### Disable

```bash
export CLAUDE_CODE_ENABLE_PROMPT_SUGGESTION=false
```

Or toggle in `/config`.

### Bash Mode Autocomplete

In `!` bash mode, type partial command + `Tab` to complete from previous `!` commands in current project.

### File Autocomplete

Type `@` to trigger file path autocomplete with fuzzy matching.

---

## 23. Git Worktrees and Parallel Sessions

### Built-in Worktree Support

```bash
claude --worktree feature-auth   # Named worktree + branch
claude --worktree                # Auto-generated name
claude -w bugfix-123             # Short flag
```

Creates at `<repo>/.claude/worktrees/<name>/`, branches from default remote branch as `worktree-<name>`.

### Cleanup

- **No changes**: Auto-removed on exit
- **With changes**: Prompted to keep or remove

### Subagent Worktrees

Ask Claude to "use worktrees for your agents" or set `isolation: worktree` in custom agent frontmatter.

### Manual Worktrees

```bash
git worktree add ../project-auth -b feature-auth main
cd ../project-auth && claude
git worktree remove ../project-auth
```

### Best Practices

- Add `.claude/worktrees/` to `.gitignore`
- Run dependency install in each worktree
- Non-git VCS: configure WorktreeCreate/WorktreeRemove hooks

---

## 24. Background Tasks

### How It Works

Claude runs commands asynchronously, returns a task ID immediately, continues responding to prompts.

### Trigger Backgrounding

1. Prompt Claude to run in background
2. Press `Ctrl+B` during any Bash command (tmux: press twice)

### Task Management

- Output buffered, retrieved via TaskOutput tool
- Unique IDs for tracking
- Auto-cleaned on exit
- `/tasks` to list and manage

### Disable

```bash
export CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1
```

### Common Use Cases

Build tools, package managers, test runners, dev servers, Docker, Terraform

---

## 25. Terminal Configuration

### Run `/terminal-setup`

Installs Shift+Enter binding for terminals that need it (VS Code, Alacritty, Zed, Warp). Only visible when needed.

### Option as Meta (macOS)

Required for Alt/Option shortcuts:
- **iTerm2**: Profiles > Keys > set Option to "Esc+"
- **Terminal.app**: Profiles > Keyboard > "Use Option as Meta Key"
- **VS Code**: `"terminal.integrated.macOptionIsMeta": true`

### Syntax Highlighting

Only available in native build of Claude Code. Toggle with `Ctrl+T` inside `/theme` picker.

---

## 26. Quick-Reference Cheat Sheet

### Most-Used Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+C` | Cancel/interrupt |
| `Ctrl+D` | Exit |
| `Esc+Esc` | Rewind (undo changes) |
| `Shift+Tab` | Cycle permission modes |
| `Ctrl+O` | Toggle verbose |
| `Ctrl+G` | Open in editor |
| `Ctrl+R` | Search history |
| `Ctrl+T` | Toggle task list |
| `Ctrl+B` | Background task |
| `Alt+P` | Switch model |
| `Alt+T` | Toggle thinking |
| `@` | File mention |
| `!` | Bash mode |
| `/` | Commands/skills |
| `\+Enter` | New line |
| `Tab` | Accept suggestion |

### Most-Used CLI Flags

```bash
claude -p "query"              # Headless
claude -c                      # Continue
claude -r name                 # Resume
claude -w name                 # Worktree
claude --model opus            # Model
claude --output-format json    # JSON output
claude --max-turns 5           # Limit turns
claude --allowedTools "R,E,B"  # Auto-approve tools
claude --permission-mode plan  # Plan mode
```

### Most-Used Slash Commands

```
/compact        # Compress context
/clear          # New session
/model          # Switch model
/diff           # View changes
/rewind         # Undo
/cost           # Token usage
/fast           # Toggle fast mode
/resume         # Switch session
/review         # Review PR
/init           # Create CLAUDE.md
```

### Most-Used Skills

```
/simplify       # Clean up code
/batch          # Parallel changes
/debug          # Debug session
/claude-api     # API reference
```

---

## Sources

- [Interactive Mode](https://code.claude.com/docs/en/interactive-mode) -- Official keyboard shortcuts, slash commands
- [CLI Reference](https://code.claude.com/docs/en/cli-reference) -- Complete CLI flags
- [Keybindings](https://code.claude.com/docs/en/keybindings) -- Customization guide
- [Common Workflows](https://code.claude.com/docs/en/common-workflows) -- Workflow patterns
- [Headless Mode](https://code.claude.com/docs/en/headless) -- Non-interactive/scripting
- [GitHub Actions](https://code.claude.com/docs/en/github-actions) -- CI/CD integration
- [Skills](https://code.claude.com/docs/en/skills) -- Custom commands
- [Status Line](https://code.claude.com/docs/en/statusline) -- Status bar customization
- [Output Styles](https://code.claude.com/docs/en/output-styles) -- Response formatting
- [Fast Mode](https://code.claude.com/docs/en/fast-mode) -- Speed optimization
- [VS Code](https://code.claude.com/docs/en/vs-code) -- VS Code extension
- [JetBrains](https://code.claude.com/docs/en/jetbrains) -- JetBrains plugin
- [Overview](https://code.claude.com/docs/en/overview) -- Feature overview
- [Awesome Claude Cheatsheet](https://awesomeclaude.ai/code-cheatsheet) -- Community reference
- [Njengah/claude-code-cheat-sheet](https://github.com/Njengah/claude-code-cheat-sheet) -- Community cheat sheet
- [SFEIR Institute](https://institute.sfeir.com/en/claude-code/claude-code-headless-mode-and-ci-cd/cheatsheet/) -- CI/CD patterns
- [claudifa.st Keybindings Guide](https://claudefa.st/blog/tools/keybindings-guide) -- Deep keybindings reference
- [zsh-claude-code-shell](https://github.com/ArielTM/zsh-claude-code-shell) -- Zsh plugin
- [claudify](https://edspencer.net/2025/5/14/claudify-fire-forget-claude-code) -- Fire-and-forget pattern
