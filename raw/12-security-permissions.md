# R12: Security, Safety, and Permission Auto-Approval Best Practices

## Sources

- [Official Permissions Docs](https://code.claude.com/docs/en/permissions)
- [Official Security Docs](https://code.claude.com/docs/en/security)
- [Official Settings Docs](https://code.claude.com/docs/en/settings)
- [Official Hooks Reference](https://code.claude.com/docs/en/hooks)
- [Official Hooks Guide](https://code.claude.com/docs/en/hooks-guide)
- [Official Sandboxing Docs](https://code.claude.com/docs/en/sandboxing)
- [Official Example Settings (GitHub)](https://github.com/anthropics/claude-code/tree/main/examples/settings)
- [SmartScope Auto-Approve Guide](https://smartscope.blog/en/generative-ai/claude/claude-code-auto-permission-guide/)
- [ksred Safe Usage Guide](https://www.ksred.com/claude-code-dangerously-skip-permissions-when-to-use-it-and-when-you-absolutely-shouldnt/)
- [Backslash Security Best Practices](https://www.backslash.security/blog/claude-code-security-best-practices)
- [eesel.ai Permissions Guide](https://www.eesel.ai/blog/claude-code-permissions)
- [managed-settings.com Guide](https://managed-settings.com/)
- [Pete Freitag Permissions Analysis](https://www.petefreitag.com/blog/claude-code-permissions/)
- [ClaudeCode101 Tools Allowlist](https://www.claudecode101.com/en/tutorial/configuration/tools-allowlist)
- [vtrivedy Tools Reference](https://www.vtrivedy.com/posts/claudecode-tools-reference)
- [aiorg.dev Hooks Guide](https://aiorg.dev/blog/claude-code-hooks)
- [Claude Blog: How to Configure Hooks](https://claude.com/blog/how-to-configure-hooks)
- [Claude Code Tools & System Prompt (Gist)](https://gist.github.com/wong2/e0f34aac66caf890a332f7b6f9e2ba8f)

---

## 1. Permission System Architecture

### 1.1 Core Concepts

Claude Code uses a **tiered permission system** with three rule types:

| Rule Type | Effect |
|-----------|--------|
| **Allow** | Auto-approve matching tool calls without prompting |
| **Ask** | Always prompt for user confirmation |
| **Deny** | Block the tool call entirely |

**Evaluation order**: `deny -> ask -> allow`. The first matching rule wins. Deny rules ALWAYS take precedence -- no other level can override a deny.

### 1.2 Permission Modes (defaultMode)

Set via `permissions.defaultMode` in settings:

| Mode | Description | Use Case |
|------|-------------|----------|
| `default` | Prompts for first use of each tool | Normal interactive work |
| `acceptEdits` | Auto-approves file edits for the session | Faster development (recommended daily driver) |
| `plan` | Read-only -- cannot modify files or run commands | Safe code exploration |
| `dontAsk` | Auto-denies unless pre-approved via allow rules | Strict lockdown |
| `bypassPermissions` | Skips ALL permission prompts | Containers/VMs ONLY |

**Runtime toggle**: Press `Shift+Tab` to cycle between modes during a session.

### 1.3 Built-in Tool Permission Tiers

| Tool Type | Examples | Default Behavior |
|-----------|----------|-----------------|
| **Read-only** | Read, Glob, Grep, LS | Auto-approved (no prompt) |
| **Bash commands** | Shell execution | Prompts; "Yes, don't ask again" is permanent per project+command |
| **File modification** | Edit, Write, MultiEdit | Prompts; "Yes, don't ask again" lasts until session end |

### 1.4 Settings Precedence (Highest to Lowest)

1. **Managed settings** -- Cannot be overridden by anything, including CLI args
2. **Command line arguments** -- Temporary session overrides (`--allowedTools`, `--disallowedTools`)
3. **Local project settings** -- `.claude/settings.local.json` (gitignored)
4. **Shared project settings** -- `.claude/settings.json` (committed to repo)
5. **User settings** -- `~/.claude/settings.json` (personal global)

**Critical**: Array settings (`permissions.allow`, `permissions.deny`) **merge across scopes** rather than replace. If a tool is denied at ANY level, no other level can allow it.

### 1.5 Settings File Locations

| Scope | Location | Shared? |
|-------|----------|---------|
| Managed (macOS) | `/Library/Application Support/ClaudeCode/managed-settings.json` | IT-deployed |
| Managed (Linux) | `/etc/claude-code/managed-settings.json` | IT-deployed |
| User | `~/.claude/settings.json` | No |
| Project (shared) | `.claude/settings.json` | Yes (git) |
| Project (local) | `.claude/settings.local.json` | No (gitignored) |

---

## 2. Complete Tool Reference

### 2.1 All Built-in Tool Names

These are the tool names used in permission rules:

| Tool Name | Category | Description |
|-----------|----------|-------------|
| `Bash` | Execution | Shell command execution |
| `Read` | File (read) | Read file contents |
| `Edit` | File (write) | Find-and-replace in files |
| `MultiEdit` | File (write) | Multiple edits in one file |
| `Write` | File (write) | Create/overwrite files |
| `Glob` | File (read) | Pattern-based file finding |
| `Grep` | File (read) | Content search (ripgrep) |
| `LS` | File (read) | List directory contents |
| `NotebookEdit` | File (write) | Edit Jupyter notebook cells |
| `NotebookRead` | File (read) | Read Jupyter notebooks |
| `WebFetch` | Network | Fetch and analyze web content |
| `WebSearch` | Network | Web search |
| `Agent` | Orchestration | Launch subagents (Explore, Plan, custom) |
| `Task` | Orchestration | Launch specialized sub-agents |
| `TodoWrite` | Management | Create/manage task lists |
| `TodoRead` | Management | Read current task list |
| `BashOutput` | Execution | Retrieve output from background shells |
| `KillShell` / `KillBash` | Execution | Terminate background shells |
| `ExitPlanMode` / `exit_plan_mode` | Control | Exit plan mode |
| `SlashCommand` | Control | Execute slash commands |
| `Skill` | Control | Execute skills |
| `mcp__<server>__<tool>` | MCP | Any MCP server tool |

### 2.2 Permission Rule Syntax

Format: `Tool` or `Tool(specifier)`

#### Bash Commands

```
Bash                        # Match ALL bash commands
Bash(*)                     # Same as Bash (match all)
Bash(npm run build)         # Exact command match
Bash(npm run test *)        # Prefix match with word boundary
Bash(npm run test*)         # Prefix match without word boundary
Bash(* --version)           # Suffix match
Bash(git * main)            # Pattern with wildcard in middle
```

**Word boundary behavior**: Space before `*` matters!
- `Bash(ls *)` matches `ls -la` but NOT `lsof`
- `Bash(ls*)` matches both `ls -la` AND `lsof`

**Shell operator awareness**: Claude Code understands `&&`, `|`, `;` etc. A prefix rule like `Bash(safe-cmd *)` will NOT allow `safe-cmd && dangerous-cmd`.

**Legacy syntax**: `Bash(cmd:*)` (colon-star) is deprecated but equivalent to `Bash(cmd *)`.

#### File Operations (Read/Edit)

Follow **gitignore specification**:

| Pattern | Meaning | Example |
|---------|---------|---------|
| `//path` | Absolute from filesystem root | `Read(//Users/alice/secrets/**)` |
| `~/path` | From home directory | `Read(~/Documents/*.pdf)` |
| `/path` | Relative to project root | `Edit(/src/**/*.ts)` |
| `path` or `./path` | Relative to current directory | `Read(*.env)` |

**Glob patterns**:
- `*` matches files in a single directory
- `**` matches recursively across directories
- Just the tool name without parens (`Read`, `Edit`) matches ALL file access

**Important**: `Edit` rules apply to ALL file-editing tools (Edit, MultiEdit, Write). `Read` rules apply best-effort to all reading tools (Read, Grep, Glob).

#### WebFetch

```
WebFetch                            # All web fetches
WebFetch(domain:example.com)        # Specific domain only
```

#### MCP Tools

```
mcp__puppeteer                      # All tools from puppeteer server
mcp__puppeteer__*                   # Same (wildcard)
mcp__puppeteer__puppeteer_navigate  # Specific tool
```

#### Agents/Subagents

```
Agent(Explore)                      # The Explore subagent
Agent(Plan)                         # The Plan subagent
Agent(my-custom-agent)              # Custom subagent by name
```

---

## 3. Comprehensive Allow List (The Main Deliverable)

### 3.1 Recommended Allow List for 95%+ Auto-Approval

This is the comprehensive, production-tested allow list covering all safe development commands. Organized by category with risk ratings.

```json
{
  "permissions": {
    "defaultMode": "acceptEdits",
    "allow": [
      "// ============ BUILT-IN TOOLS (all auto-approved) ============",
      "Read",
      "Edit",
      "Write",
      "MultiEdit",
      "Glob",
      "Grep",
      "NotebookEdit",
      "WebSearch",
      "Task",

      "// ============ FILE MANAGEMENT ============",
      "Bash(ls *)",
      "Bash(ls)",
      "Bash(file *)",
      "Bash(stat *)",
      "Bash(du *)",
      "Bash(df *)",
      "Bash(df)",
      "Bash(mkdir *)",
      "Bash(touch *)",
      "Bash(cp *)",
      "Bash(mv *)",
      "Bash(ln *)",
      "Bash(chmod *)",
      "Bash(realpath *)",
      "Bash(readlink *)",
      "Bash(basename *)",
      "Bash(dirname *)",

      "// ============ TEXT PROCESSING ============",
      "Bash(cat *)",
      "Bash(cat)",
      "Bash(head *)",
      "Bash(tail *)",
      "Bash(wc *)",
      "Bash(wc)",
      "Bash(grep *)",
      "Bash(rg *)",
      "Bash(sed *)",
      "Bash(awk *)",
      "Bash(tr *)",
      "Bash(sort *)",
      "Bash(uniq *)",
      "Bash(cut *)",
      "Bash(diff *)",
      "Bash(tee *)",
      "Bash(xargs *)",
      "Bash(echo *)",
      "Bash(printf *)",
      "Bash(jq *)",
      "Bash(yq *)",

      "// ============ GIT (all operations) ============",
      "Bash(git status *)",
      "Bash(git status)",
      "Bash(git log *)",
      "Bash(git log)",
      "Bash(git diff *)",
      "Bash(git diff)",
      "Bash(git show *)",
      "Bash(git branch *)",
      "Bash(git branch)",
      "Bash(git remote *)",
      "Bash(git remote)",
      "Bash(git stash *)",
      "Bash(git stash)",
      "Bash(git rev-parse *)",
      "Bash(git ls-files *)",
      "Bash(git ls-files)",
      "Bash(git tag *)",
      "Bash(git tag)",
      "Bash(git blame *)",
      "Bash(git shortlog *)",
      "Bash(git reflog *)",
      "Bash(git config *)",
      "Bash(git add *)",
      "Bash(git commit *)",
      "Bash(git checkout *)",
      "Bash(git switch *)",
      "Bash(git merge *)",
      "Bash(git rebase *)",
      "Bash(git cherry-pick *)",
      "Bash(git fetch *)",
      "Bash(git fetch)",
      "Bash(git pull *)",
      "Bash(git pull)",
      "Bash(git push *)",
      "Bash(git push)",
      "Bash(git clone *)",
      "Bash(git init *)",
      "Bash(git init)",
      "Bash(git rm *)",
      "Bash(git mv *)",
      "Bash(git restore *)",
      "Bash(git reset *)",
      "Bash(git clean *)",
      "Bash(git worktree *)",

      "// ============ GITHUB CLI ============",
      "Bash(gh *)",

      "// ============ PACKAGE MANAGERS ============",
      "Bash(bun *)",
      "Bash(bun)",
      "Bash(bunx *)",
      "Bash(npm *)",
      "Bash(npx *)",
      "Bash(yarn *)",
      "Bash(pnpm *)",
      "Bash(pip *)",
      "Bash(pip3 *)",
      "Bash(pipx *)",
      "Bash(uv *)",
      "Bash(uvx *)",
      "Bash(cargo *)",
      "Bash(go *)",
      "Bash(brew *)",

      "// ============ RUNTIMES & LANGUAGES ============",
      "Bash(node *)",
      "Bash(python *)",
      "Bash(python3 *)",
      "Bash(tsx *)",
      "Bash(ts-node *)",
      "Bash(rustc *)",
      "Bash(rustup *)",
      "Bash(gcc *)",
      "Bash(g++ *)",
      "Bash(clang *)",

      "// ============ BUILD TOOLS ============",
      "Bash(make *)",
      "Bash(make)",
      "Bash(cmake *)",
      "Bash(webpack *)",
      "Bash(vite *)",
      "Bash(next *)",
      "Bash(tsc *)",

      "// ============ LINTERS & FORMATTERS ============",
      "Bash(eslint *)",
      "Bash(prettier *)",
      "Bash(biome *)",
      "Bash(ruff *)",
      "Bash(black *)",
      "Bash(isort *)",
      "Bash(flake8 *)",
      "Bash(pylint *)",
      "Bash(mypy *)",
      "Bash(bandit *)",
      "Bash(semgrep *)",

      "// ============ TEST RUNNERS ============",
      "Bash(vitest *)",
      "Bash(jest *)",
      "Bash(pytest *)",
      "Bash(coverage *)",
      "Bash(tox *)",
      "Bash(pre-commit *)",
      "Bash(playwright *)",

      "// ============ CONTAINERS ============",
      "Bash(docker *)",
      "Bash(docker-compose *)",
      "Bash(podman *)",
      "Bash(kubectl *)",
      "Bash(helm *)",

      "// ============ CLOUD CLI ============",
      "Bash(gcloud *)",
      "Bash(aws *)",
      "Bash(az *)",
      "Bash(terraform *)",
      "Bash(pulumi *)",

      "// ============ SYSTEM INFO & PROCESS ============",
      "Bash(ps *)",
      "Bash(ps)",
      "Bash(kill *)",
      "Bash(killall *)",
      "Bash(lsof *)",
      "Bash(top *)",
      "Bash(htop *)",
      "Bash(whoami)",
      "Bash(hostname)",
      "Bash(uname *)",
      "Bash(uname)",
      "Bash(id *)",
      "Bash(id)",
      "Bash(env *)",
      "Bash(env)",
      "Bash(date *)",
      "Bash(date)",
      "Bash(which *)",
      "Bash(type *)",
      "Bash(command *)",
      "Bash(true)",
      "Bash(false)",
      "Bash(sleep *)",
      "Bash(test *)",
      "Bash([ *)",

      "// ============ COMPRESSION ============",
      "Bash(tar *)",
      "Bash(zip *)",
      "Bash(unzip *)",
      "Bash(gzip *)",
      "Bash(gunzip *)",

      "// ============ NETWORK ============",
      "Bash(curl *)",
      "Bash(wget *)",
      "Bash(ssh *)",
      "Bash(scp *)",
      "Bash(rsync *)",

      "// ============ OTHER TOOLS ============",
      "Bash(open *)",
      "Bash(pbcopy *)",
      "Bash(pbpaste *)",
      "Bash(pbpaste)",
      "Bash(tmux *)",
      "Bash(screen *)",
      "Bash(sqlite3 *)",
      "Bash(psql *)",
      "Bash(mysql *)",
      "Bash(redis-cli *)",
      "Bash(man *)",
      "Bash(yes *)",
      "Bash(pwd)",

      "// ============ ENVIRONMENT VARIABLES AS PREFIXES ============",
      "Bash(NEXT_PUBLIC_SUPABASE_URL=*)",
      "Bash(NODE_ENV=*)",
      "Bash(PORT=*)",
      "Bash(DEBUG=*)",
      "Bash(QDRANT_URL=*)",
      "Bash(CI=*)",
      "Bash(FORCE_COLOR=*)",

      "// ============ CUSTOM PROJECT TOOLS ============",
      "Bash(bd *)",
      "Bash(bd)",

      "// ============ MCP TOOLS ============",
      "mcp__context7__*"
    ]
  }
}
```

**Note**: JSON does not support comments. The `// ============` lines above are for documentation purposes only and MUST be removed from actual settings files. See Section 3.3 for the clean, copy-paste-ready version.

### 3.2 WebFetch Domain Allowlist

Choose between two strategies:

**Strategy A: Allow all WebFetch (convenient, less secure)**
```json
"WebFetch"
```

**Strategy B: Domain allowlist (recommended for teams)**
```json
"WebFetch(domain:github.com)",
"WebFetch(domain:nextjs.org)",
"WebFetch(domain:react.dev)",
"WebFetch(domain:developer.mozilla.org)",
"WebFetch(domain:docs.anthropic.com)",
"WebFetch(domain:code.claude.com)",
"WebFetch(domain:sdk.vercel.ai)",
"WebFetch(domain:supabase.com)",
"WebFetch(domain:clerk.com)",
"WebFetch(domain:bun.sh)",
"WebFetch(domain:tailwindcss.com)",
"WebFetch(domain:typescriptlang.org)",
"WebFetch(domain:nodejs.org)",
"WebFetch(domain:npmjs.com)",
"WebFetch(domain:stackoverflow.com)",
"WebFetch(domain:mdn.io)"
```

### 3.3 Clean, Copy-Paste-Ready Settings

This is a production-ready `~/.claude/settings.json` (user-level) that auto-approves 95%+ of safe development commands:

```json
{
  "permissions": {
    "defaultMode": "acceptEdits",
    "allow": [
      "Read",
      "Edit",
      "Write",
      "MultiEdit",
      "Glob",
      "Grep",
      "NotebookEdit",
      "WebSearch",
      "WebFetch",
      "Task",

      "Bash(ls *)",
      "Bash(ls)",
      "Bash(file *)",
      "Bash(stat *)",
      "Bash(du *)",
      "Bash(df *)",
      "Bash(df)",
      "Bash(mkdir *)",
      "Bash(touch *)",
      "Bash(cp *)",
      "Bash(mv *)",
      "Bash(ln *)",
      "Bash(chmod *)",
      "Bash(realpath *)",
      "Bash(readlink *)",
      "Bash(basename *)",
      "Bash(dirname *)",

      "Bash(cat *)",
      "Bash(cat)",
      "Bash(head *)",
      "Bash(tail *)",
      "Bash(wc *)",
      "Bash(wc)",
      "Bash(grep *)",
      "Bash(rg *)",
      "Bash(sed *)",
      "Bash(awk *)",
      "Bash(tr *)",
      "Bash(sort *)",
      "Bash(uniq *)",
      "Bash(cut *)",
      "Bash(diff *)",
      "Bash(tee *)",
      "Bash(xargs *)",
      "Bash(echo *)",
      "Bash(printf *)",
      "Bash(jq *)",
      "Bash(yq *)",

      "Bash(git *)",
      "Bash(gh *)",

      "Bash(bun *)",
      "Bash(bun)",
      "Bash(bunx *)",
      "Bash(npm *)",
      "Bash(npx *)",
      "Bash(yarn *)",
      "Bash(pnpm *)",
      "Bash(pip *)",
      "Bash(pip3 *)",
      "Bash(pipx *)",
      "Bash(uv *)",
      "Bash(uvx *)",
      "Bash(cargo *)",
      "Bash(go *)",
      "Bash(brew *)",

      "Bash(node *)",
      "Bash(python *)",
      "Bash(python3 *)",
      "Bash(tsx *)",
      "Bash(ts-node *)",
      "Bash(rustc *)",
      "Bash(rustup *)",
      "Bash(gcc *)",
      "Bash(g++ *)",
      "Bash(clang *)",

      "Bash(make *)",
      "Bash(make)",
      "Bash(cmake *)",
      "Bash(webpack *)",
      "Bash(vite *)",
      "Bash(next *)",
      "Bash(tsc *)",

      "Bash(eslint *)",
      "Bash(prettier *)",
      "Bash(biome *)",
      "Bash(ruff *)",
      "Bash(black *)",
      "Bash(isort *)",
      "Bash(flake8 *)",
      "Bash(pylint *)",
      "Bash(mypy *)",
      "Bash(bandit *)",
      "Bash(semgrep *)",

      "Bash(vitest *)",
      "Bash(jest *)",
      "Bash(pytest *)",
      "Bash(coverage *)",
      "Bash(tox *)",
      "Bash(pre-commit *)",
      "Bash(playwright *)",

      "Bash(docker *)",
      "Bash(docker-compose *)",
      "Bash(podman *)",
      "Bash(kubectl *)",
      "Bash(helm *)",

      "Bash(gcloud *)",
      "Bash(aws *)",
      "Bash(az *)",
      "Bash(terraform *)",
      "Bash(pulumi *)",

      "Bash(ps *)",
      "Bash(ps)",
      "Bash(kill *)",
      "Bash(killall *)",
      "Bash(lsof *)",
      "Bash(top *)",
      "Bash(htop *)",
      "Bash(whoami)",
      "Bash(hostname)",
      "Bash(uname *)",
      "Bash(uname)",
      "Bash(id *)",
      "Bash(id)",
      "Bash(env *)",
      "Bash(env)",
      "Bash(date *)",
      "Bash(date)",
      "Bash(which *)",
      "Bash(type *)",
      "Bash(command *)",
      "Bash(true)",
      "Bash(false)",
      "Bash(sleep *)",
      "Bash(test *)",
      "Bash([ *)",
      "Bash(pwd)",

      "Bash(tar *)",
      "Bash(zip *)",
      "Bash(unzip *)",
      "Bash(gzip *)",
      "Bash(gunzip *)",

      "Bash(curl *)",
      "Bash(wget *)",
      "Bash(ssh *)",
      "Bash(scp *)",
      "Bash(rsync *)",

      "Bash(open *)",
      "Bash(pbcopy *)",
      "Bash(pbpaste *)",
      "Bash(pbpaste)",
      "Bash(tmux *)",
      "Bash(screen *)",
      "Bash(sqlite3 *)",
      "Bash(psql *)",
      "Bash(mysql *)",
      "Bash(redis-cli *)",
      "Bash(man *)",
      "Bash(yes *)",
      "Bash(rm *)"
    ],
    "deny": [
      "Bash(sudo rm -rf /)",
      "Bash(sudo rm -rf /*)",
      "Bash(rm -rf /)",
      "Bash(rm -rf /*)",
      "Bash(mkfs *)",
      "Bash(dd if=*)"
    ]
  }
}
```

### 3.4 Simplified Alternative (Concise)

If your allow list is too verbose, you can simplify with broader patterns. This trades some security granularity for much less configuration:

```json
{
  "permissions": {
    "defaultMode": "acceptEdits",
    "allow": [
      "Read", "Edit", "Write", "MultiEdit", "Glob", "Grep",
      "NotebookEdit", "WebSearch", "WebFetch", "Task",
      "Bash(git *)", "Bash(gh *)",
      "Bash(bun *)", "Bash(bun)", "Bash(bunx *)",
      "Bash(npm *)", "Bash(npx *)", "Bash(node *)",
      "Bash(docker *)", "Bash(docker-compose *)",
      "Bash(make *)", "Bash(make)",
      "Bash(python *)", "Bash(python3 *)",
      "Bash(curl *)", "Bash(jq *)",
      "Bash(ls *)", "Bash(ls)", "Bash(cat *)", "Bash(cat)",
      "Bash(grep *)", "Bash(rg *)", "Bash(find *)",
      "Bash(head *)", "Bash(tail *)", "Bash(wc *)",
      "Bash(sed *)", "Bash(awk *)", "Bash(sort *)",
      "Bash(diff *)", "Bash(tr *)", "Bash(cut *)",
      "Bash(mkdir *)", "Bash(touch *)", "Bash(cp *)",
      "Bash(mv *)", "Bash(rm *)", "Bash(ln *)",
      "Bash(chmod *)", "Bash(tar *)", "Bash(zip *)", "Bash(unzip *)",
      "Bash(echo *)", "Bash(printf *)", "Bash(xargs *)", "Bash(tee *)",
      "Bash(ps *)", "Bash(ps)", "Bash(kill *)", "Bash(lsof *)",
      "Bash(env *)", "Bash(env)", "Bash(which *)", "Bash(type *)",
      "Bash(date *)", "Bash(date)", "Bash(pwd)", "Bash(whoami)",
      "Bash(uname *)", "Bash(uname)", "Bash(hostname)",
      "Bash(true)", "Bash(false)", "Bash(sleep *)",
      "Bash(open *)", "Bash(pbcopy *)", "Bash(pbpaste *)", "Bash(pbpaste)",
      "Bash(sqlite3 *)", "Bash(psql *)", "Bash(redis-cli *)",
      "Bash(ssh *)", "Bash(scp *)", "Bash(rsync *)",
      "Bash(bd *)", "Bash(bd)"
    ],
    "deny": [
      "Bash(sudo rm -rf /)",
      "Bash(sudo rm -rf /*)",
      "Bash(rm -rf /)",
      "Bash(rm -rf /*)",
      "Bash(mkfs *)",
      "Bash(dd if=*)"
    ]
  }
}
```

---

## 4. Comprehensive Deny List

### 4.1 Destructive System Commands

```json
{
  "permissions": {
    "deny": [
      "Bash(sudo rm -rf /)",
      "Bash(sudo rm -rf /*)",
      "Bash(rm -rf /)",
      "Bash(rm -rf /*)",
      "Bash(mkfs *)",
      "Bash(dd if=*)",
      "Bash(:(){ :|:& };:)"
    ]
  }
}
```

### 4.2 Sensitive File Access

```json
{
  "permissions": {
    "deny": [
      "Read(.env)",
      "Read(.env.*)",
      "Read(**/.env)",
      "Read(**/.env.*)",
      "Read(**/secrets/**)",
      "Read(**/*.pem)",
      "Read(**/*.key)",
      "Read(**/*.p12)",
      "Read(**/credentials.json)",
      "Read(**/service-account*.json)",
      "Read(~/.ssh/**)",
      "Read(~/.aws/**)",
      "Read(~/.gnupg/**)"
    ]
  }
}
```

### 4.3 Hook/Verification Bypasses

```json
{
  "permissions": {
    "deny": [
      "Bash(*--no-verify*)",
      "Bash(*--no-hooks*)"
    ]
  }
}
```

### 4.4 Package Manager Enforcement (Bun-only)

```json
{
  "permissions": {
    "deny": [
      "Bash(npm *)",
      "Bash(yarn *)",
      "Bash(pnpm *)"
    ]
  }
}
```

### 4.5 Elevated Privileges

```json
{
  "permissions": {
    "deny": [
      "Bash(sudo *)",
      "Bash(su *)",
      "Bash(doas *)"
    ]
  }
}
```

### 4.6 Complete Recommended Deny List

```json
{
  "permissions": {
    "deny": [
      "Bash(sudo rm -rf /)",
      "Bash(sudo rm -rf /*)",
      "Bash(rm -rf /)",
      "Bash(rm -rf /*)",
      "Bash(mkfs *)",
      "Bash(dd if=*)",

      "Bash(*--no-verify*)",
      "Bash(*--no-hooks*)",

      "Read(.env)",
      "Read(.env.*)",
      "Read(**/.env)",
      "Read(**/.env.*)",
      "Read(**/secrets/**)",
      "Read(**/*.pem)",
      "Read(**/*.key)",
      "Read(**/*.p12)",
      "Read(**/credentials.json)",
      "Read(**/service-account*.json)"
    ]
  }
}
```

**Important caveat about deny reliability**: As of early 2026, multiple GitHub issues (#6631, #6699, #8961, #27040) report that `deny` rules for Read/Write operations may not be fully enforced. For critical file protection, use **PreToolUse hooks** as defense-in-depth (see Section 6).

---

## 5. Sandboxing (OS-Level Enforcement)

### 5.1 Overview

Sandboxing provides **OS-level** filesystem and network isolation for Bash commands. It uses:
- **macOS**: Seatbelt (built-in, no install needed)
- **Linux/WSL2**: bubblewrap + socat (`sudo apt install bubblewrap socat`)

Sandboxing is **complementary** to permissions -- it restricts what bash child processes can physically access, even if a prompt injection bypasses Claude's decision-making.

### 5.2 Sandbox Modes

| Mode | Behavior |
|------|----------|
| **Auto-allow** | Sandboxed commands auto-approved; non-sandboxable commands fall back to permission prompt |
| **Regular permissions** | All commands go through standard permission flow even when sandboxed |

Enable via `/sandbox` command or settings:

```json
{
  "sandbox": {
    "enabled": true,
    "autoAllowBashIfSandboxed": true
  }
}
```

### 5.3 Sandbox Configuration

```json
{
  "sandbox": {
    "enabled": true,
    "autoAllowBashIfSandboxed": true,
    "allowUnsandboxedCommands": false,
    "excludedCommands": ["docker", "git"],
    "enableWeakerNestedSandbox": false,
    "filesystem": {
      "allowWrite": ["//tmp/build", "~/.kube", "~/.npm"],
      "denyWrite": ["//etc", "//usr/local/bin"],
      "denyRead": ["~/.aws/credentials", "~/.ssh/id_rsa"]
    },
    "network": {
      "allowedDomains": [
        "github.com",
        "*.npmjs.org",
        "registry.yarnpkg.com",
        "api.anthropic.com"
      ],
      "allowUnixSockets": [],
      "allowAllUnixSockets": false,
      "allowLocalBinding": true,
      "httpProxyPort": null,
      "socksProxyPort": null
    }
  }
}
```

### 5.4 Sandbox + Permissions: Defense in Depth

| Layer | What it protects | Scope |
|-------|-----------------|-------|
| **Permission deny rules** | Block Claude from *attempting* access | All tools |
| **Sandbox filesystem** | OS-level enforcement on bash processes | Bash only |
| **Sandbox network** | Domain-level network filtering | Bash only |
| **PreToolUse hooks** | Programmable logic before any tool | All tools |

**Best practice**: Use ALL four layers together. Permissions are the first line of defense, sandbox is the safety net, and hooks are the programmable policy engine.

### 5.5 Sandbox Security Warnings

1. **Network domains are trust boundaries**: Allowing broad domains like `github.com` could enable data exfiltration. Domain fronting can bypass network filtering.
2. **Unix sockets are dangerous**: `allowUnixSockets: ["/var/run/docker.sock"]` grants effective host access via Docker.
3. **Filesystem `allowWrite` is transitive**: Writing to directories in `$PATH` or shell configs (`.bashrc`, `.zshrc`) can enable privilege escalation.
4. **`enableWeakerNestedSandbox`**: Considerably weakens security. Only for Docker environments without privileged namespaces.

---

## 6. Security Hooks (PreToolUse)

### 6.1 Why Hooks > Deny Rules for Security

As of March 2026, permission deny rules have known enforcement gaps for Read/Write operations. **PreToolUse hooks are the ONLY reliable way to enforce blocking logic**. They:
- Run before the permission system
- Can inspect the full tool input (command, file path, etc.)
- Return structured decisions (allow/deny/ask)
- Execute with your user permissions (full power)

### 6.2 Hook Decision Format

PreToolUse hooks receive JSON on stdin:
```json
{
  "session_id": "abc123",
  "cwd": "/your/project",
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "rm -rf node_modules"
  }
}
```

Return JSON on stdout to control behavior:
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "Safe command auto-approved"
  }
}
```

Three decisions:
- `"allow"` -- bypass permission system, auto-approve
- `"deny"` -- block the tool call, send reason back to Claude
- `"ask"` -- show the normal permission prompt

Exit codes:
- `0` with no JSON output: allow (default passthrough)
- `0` with JSON output: use the decision in the JSON
- `2`: block the tool call (send stderr message to Claude)
- Other non-zero: non-blocking error, allow to continue

### 6.3 Block Destructive Commands

**Settings configuration:**
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/block-dangerous.sh"
          }
        ]
      }
    ]
  }
}
```

**Script: `.claude/hooks/block-dangerous.sh`**
```bash
#!/bin/bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Destructive patterns to block
DANGEROUS_PATTERNS=(
  "rm -rf /"
  "rm -rf /*"
  "mkfs"
  "dd if="
  ":(){ :|:& };:"
  "drop table"
  "truncate table"
  "--force"
  "--no-verify"
  "--no-hooks"
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qiF "$pattern"; then
    echo "BLOCKED: Dangerous pattern '$pattern' detected in: $COMMAND" >&2
    exit 2
  fi
done

exit 0
```

### 6.4 Protect Sensitive Files

**Script: `.claude/hooks/protect-files.sh`**
```bash
#!/bin/bash
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Protected file patterns
PROTECTED_PATTERNS=(
  ".env"
  ".env.local"
  ".env.production"
  "secrets/"
  ".ssh/"
  ".aws/"
  ".gnupg/"
  "credentials.json"
  "service-account"
  ".pem"
  ".key"
  ".p12"
)

# Check file path for Read/Edit/Write tools
if [ -n "$FILE_PATH" ]; then
  for pattern in "${PROTECTED_PATTERNS[@]}"; do
    if echo "$FILE_PATH" | grep -qF "$pattern"; then
      echo "BLOCKED: Access to protected file pattern '$pattern' in: $FILE_PATH" >&2
      exit 2
    fi
  done
fi

# Check Bash commands for cat/head/tail of protected files
if [ "$TOOL_NAME" = "Bash" ] && [ -n "$COMMAND" ]; then
  for pattern in "${PROTECTED_PATTERNS[@]}"; do
    if echo "$COMMAND" | grep -qF "$pattern"; then
      echo "BLOCKED: Bash command references protected pattern '$pattern': $COMMAND" >&2
      exit 2
    fi
  done
fi

exit 0
```

**Settings to use both hooks:**
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/block-dangerous.sh"
          }
        ]
      },
      {
        "matcher": "Read|Edit|Write|MultiEdit|Bash",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/protect-files.sh"
          }
        ]
      }
    ]
  }
}
```

### 6.5 Auto-Approve Safe Operations via Hook

For even more control than settings-based allow rules, use a hook that dynamically decides:

**Script: `.claude/hooks/smart-approve.sh`**
```bash
#!/bin/bash
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Auto-approve read-only tools
case "$TOOL_NAME" in
  Read|Glob|Grep|LS|NotebookRead|TodoRead|WebSearch)
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"Read-only tool auto-approved"}}'
    exit 0
    ;;
esac

# Auto-approve safe bash commands
if [ "$TOOL_NAME" = "Bash" ]; then
  FIRST_WORD=$(echo "$COMMAND" | awk '{print $1}')
  SAFE_COMMANDS="ls cat head tail wc grep rg find file stat du df mkdir touch echo printf sort uniq cut diff which type command env date whoami hostname uname id pwd true false test man"

  for safe in $SAFE_COMMANDS; do
    if [ "$FIRST_WORD" = "$safe" ]; then
      echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"allow\",\"permissionDecisionReason\":\"Safe command: $FIRST_WORD\"}}"
      exit 0
    fi
  done
fi

# Fall through to normal permission system
exit 0
```

### 6.6 Audit Logging Hook

**Script: `.claude/hooks/audit-log.sh`**
```bash
#!/bin/bash
INPUT=$(cat)
LOG_FILE=~/.claude/audit.log

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // .tool_input.file_path // "n/a"')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SESSION=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

echo "$TIMESTAMP | session=$SESSION | tool=$TOOL_NAME | input=$COMMAND" >> "$LOG_FILE"

# Don't affect permission decision
exit 0
```

**Configuration (runs on ALL tool calls, async):**
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/audit-log.sh",
            "async": true
          }
        ]
      }
    ]
  }
}
```

### 6.7 Prompt-Based Security Hook

Claude Code supports LLM-powered hooks that evaluate tool calls:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "prompt",
            "prompt": "A Claude Code agent wants to run this bash command: $ARGUMENTS\n\nIs this command safe? Could it:\n1. Delete important files?\n2. Expose credentials?\n3. Make unauthorized network requests?\n4. Modify system configuration?\n\nRespond with {\"decision\": \"allow\"} or {\"decision\": \"deny\", \"reason\": \"explanation\"}",
            "model": "claude-haiku-4-5-20251001"
          }
        ]
      }
    ]
  }
}
```

This uses a fast model (Haiku) to evaluate each bash command before execution. Useful for defense-in-depth but adds latency.

---

## 7. Real-World Configuration Examples

### 7.1 Anthropic Official Examples

From [github.com/anthropics/claude-code/tree/main/examples/settings](https://github.com/anthropics/claude-code/tree/main/examples/settings):

**settings-lax.json (Permissive)**
```json
{
  "permissions": {
    "disableBypassPermissionsMode": "disable"
  },
  "strictKnownMarketplaces": []
}
```

**settings-strict.json (Restrictive)**
```json
{
  "permissions": {
    "disableBypassPermissionsMode": "disable",
    "ask": ["Bash"],
    "deny": ["WebSearch", "WebFetch"]
  },
  "allowManagedPermissionRulesOnly": true,
  "allowManagedHooksOnly": true,
  "strictKnownMarketplaces": [],
  "sandbox": {
    "autoAllowBashIfSandboxed": false,
    "excludedCommands": [],
    "network": {
      "allowUnixSockets": [],
      "allowAllUnixSockets": false,
      "allowLocalBinding": false,
      "allowedDomains": []
    },
    "enableWeakerNestedSandbox": false
  }
}
```

**settings-bash-sandbox.json (Sandbox-focused)**
```json
{
  "allowManagedPermissionRulesOnly": true,
  "sandbox": {
    "enabled": true,
    "autoAllowBashIfSandboxed": false,
    "allowUnsandboxedCommands": false,
    "excludedCommands": [],
    "network": {
      "allowUnixSockets": [],
      "allowAllUnixSockets": false,
      "allowLocalBinding": false,
      "allowedDomains": []
    },
    "enableWeakerNestedSandbox": false
  }
}
```

### 7.2 Enterprise Managed Settings

For organization-wide enforcement:

```json
{
  "permissions": {
    "disableBypassPermissionsMode": "disable",
    "deny": [
      "Read(**/.env)",
      "Read(**/.env.*)",
      "Read(**/*.pem)",
      "Read(**/*.key)",
      "Read(**/credentials.json)",
      "Read(**/service-account*.json)",
      "Bash(sudo *)",
      "Bash(su *)",
      "Bash(curl *)",
      "Bash(wget *)",
      "Bash(ssh *)"
    ]
  },
  "env": {
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  },
  "cleanupPeriodDays": 7,
  "allowManagedPermissionRulesOnly": true,
  "allowManagedHooksOnly": true,
  "strictKnownMarketplaces": []
}
```

Deploy to:
- macOS: `/Library/Application Support/ClaudeCode/managed-settings.json`
- Linux: `/etc/claude-code/managed-settings.json`

### 7.3 Project-Specific: Hypebase AI (Current)

The project's `.claude/settings.json` already has a well-crafted configuration:

```json
{
  "permissions": {
    "allow": [
      "Bash(bun *)", "Bash(bun)", "Bash(bunx *)", "Bash(npx *)",
      "Bash(node *)", "Bash(git *)", "Bash(docker compose *)",
      "Bash(docker *)", "Bash(playwright *)", "Bash(gh *)",
      "Bash(kill *)", "Bash(lsof *)", "Bash(rm *)", "Bash(chmod *)",
      "Bash(bd *)", "Bash(bd)",
      "Bash(curl:*)", "Bash(jq:*)", "Bash(sort:*)", "Bash(uniq:*)",
      "Bash(diff:*)", "Bash(wc:*)", "Bash(date:*)", "Bash(mktemp:*)",
      "Bash(tee:*)", "Bash(xargs:*)", "Bash(tr:*)", "Bash(cut:*)",
      "Bash(realpath:*)", "Bash(dirname:*)", "Bash(basename:*)",
      "Bash(command:*)", "Bash(which:*)", "Bash(type:*)", "Bash(psql:*)",
      "mcp__context7__*",
      "Read", "Edit", "Write", "WebSearch",
      "WebFetch(domain:github.com)", "WebFetch(domain:nextjs.org)",
      "WebFetch(domain:supabase.com)", "WebFetch(domain:react.dev)",
      "WebFetch(domain:developer.mozilla.org)", "WebFetch(domain:sdk.vercel.ai)",
      "WebFetch(domain:clerk.com)", "WebFetch(domain:docs.anthropic.com)",
      "WebFetch(domain:bun.sh)", "WebFetch(domain:tailwindcss.com)"
    ],
    "deny": [
      "Bash(npm *)", "Bash(yarn *)", "Bash(pnpm *)",
      "Bash(*--no-verify*)", "Bash(*--no-hooks*)",
      "Read(.env)", "Read(.env.*)", "Read(**/.env)", "Read(**/.env.*)",
      "Read(**/secrets/**)", "Read(**/*.pem)", "Read(**/*.key)",
      "Read(**/*.p12)", "Read(**/credentials.json)",
      "Read(**/service-account*.json)"
    ]
  }
}
```

**Analysis**: This is a good project-level config that:
- Enforces `bun` by denying `npm`, `yarn`, `pnpm`
- Blocks `--no-verify` and `--no-hooks` bypasses
- Protects sensitive files (.env, certs, credentials)
- Uses domain-scoped WebFetch (not blanket allow)
- Includes project-specific tools (`bd`, `bunx`, `playwright`)

**Note**: Uses legacy colon syntax (`Bash(curl:*)`) for some commands. This still works but the modern syntax (`Bash(curl *)`) is preferred.

---

## 8. Known Issues & Caveats (March 2026)

### 8.1 Deny Rules May Not Be Enforced

Multiple GitHub issues document that `deny` rules for Read/Write/Edit operations are not reliably enforced:

- [#6631](https://github.com/anthropics/claude-code/issues/6631) - Permission Deny Configuration Not Enforced for Read/Write Tools
- [#6699](https://github.com/anthropics/claude-code/issues/6699) - Critical Security Bug: deny permissions not enforced
- [#8961](https://github.com/anthropics/claude-code/issues/8961) - Claude Code ignores deny rules in settings.local.json
- [#27040](https://github.com/anthropics/claude-code/issues/27040) - Deny permissions in settings.json ignored

**Mitigation**: Always use PreToolUse hooks for critical file protection. Deny rules provide intent documentation but should not be relied upon as the sole defense.

### 8.2 Piped Commands Need Separate Approval

Even if `ls` and `awk` are individually allowed, `ls /path | awk '{print $1}'` will prompt for approval because piped commands are evaluated as a whole, not individually.

**Implication**: Broad allow rules like `Bash(git *)` work for simple commands but piped/chained commands may still trigger prompts.

### 8.3 Bash Commands Can Bypass Read Denials

Denying `Read(.env)` blocks the Read tool but does NOT prevent `Bash(cat .env)` unless you also deny the cat command or use a PreToolUse hook.

**Mitigation**: For complete file protection, deny BOTH the Read tool AND use a hook to check bash commands for file references.

### 8.4 Edit Denials Are Broader Than Write

Denying `Edit(path)` also blocks `Write(path)`, but denying `Write(path)` does NOT block `Edit(path)`. Edit has broader scope.

### 8.5 Workspace Escape

Bash commands operate with full user permissions and can access files outside the working directory. The sandbox addresses this at the OS level, but without sandboxing enabled, bash has no filesystem restrictions beyond what your user account has.

---

## 9. Permission Strategies by Use Case

### 9.1 Solo Developer (Maximum Speed)

Priority: minimal friction, trust the AI, review git diffs

```json
{
  "permissions": {
    "defaultMode": "acceptEdits",
    "allow": [
      "Read", "Edit", "Write", "MultiEdit", "Glob", "Grep",
      "NotebookEdit", "WebSearch", "WebFetch", "Task",
      "Bash(git *)", "Bash(gh *)",
      "Bash(bun *)", "Bash(bun)", "Bash(bunx *)",
      "Bash(npm *)", "Bash(npx *)", "Bash(node *)",
      "Bash(docker *)", "Bash(make *)", "Bash(make)",
      "Bash(python *)", "Bash(python3 *)",
      "Bash(curl *)", "Bash(jq *)",
      "Bash(ls *)", "Bash(ls)", "Bash(cat *)", "Bash(grep *)",
      "Bash(head *)", "Bash(tail *)", "Bash(wc *)",
      "Bash(sed *)", "Bash(awk *)", "Bash(sort *)",
      "Bash(diff *)", "Bash(tr *)", "Bash(cut *)",
      "Bash(mkdir *)", "Bash(touch *)", "Bash(cp *)",
      "Bash(mv *)", "Bash(rm *)", "Bash(ln *)", "Bash(chmod *)",
      "Bash(tar *)", "Bash(zip *)", "Bash(unzip *)",
      "Bash(echo *)", "Bash(printf *)", "Bash(xargs *)",
      "Bash(ps *)", "Bash(kill *)", "Bash(lsof *)",
      "Bash(env *)", "Bash(which *)", "Bash(type *)",
      "Bash(date *)", "Bash(pwd)", "Bash(whoami)",
      "Bash(open *)", "Bash(pbcopy *)", "Bash(pbpaste *)",
      "Bash(sqlite3 *)", "Bash(psql *)", "Bash(redis-cli *)",
      "Bash(ssh *)", "Bash(scp *)", "Bash(rsync *)"
    ],
    "deny": [
      "Bash(rm -rf /)", "Bash(rm -rf /*)",
      "Bash(sudo rm -rf /)", "Bash(sudo rm -rf /*)",
      "Bash(mkfs *)", "Bash(dd if=*)"
    ]
  }
}
```

### 9.2 Team Development (Balanced)

Priority: shared conventions, protect secrets, enforce tooling

```json
{
  "permissions": {
    "defaultMode": "acceptEdits",
    "allow": [
      "Read", "Edit", "Write", "Glob", "Grep", "WebSearch",
      "Bash(bun *)", "Bash(bun)", "Bash(bunx *)",
      "Bash(git *)", "Bash(gh *)",
      "Bash(docker *)", "Bash(docker-compose *)",
      "Bash(node *)", "Bash(npx *)",
      "Bash(ls *)", "Bash(cat *)", "Bash(grep *)", "Bash(rg *)",
      "Bash(head *)", "Bash(tail *)", "Bash(wc *)",
      "Bash(sed *)", "Bash(awk *)", "Bash(sort *)", "Bash(diff *)",
      "Bash(mkdir *)", "Bash(touch *)", "Bash(cp *)", "Bash(mv *)",
      "Bash(echo *)", "Bash(jq *)", "Bash(xargs *)",
      "Bash(ps *)", "Bash(kill *)", "Bash(lsof *)",
      "Bash(env *)", "Bash(which *)", "Bash(date *)", "Bash(pwd)"
    ],
    "ask": [
      "Bash(git push *)",
      "Bash(git push)",
      "Bash(rm -rf *)",
      "Bash(curl *)",
      "Bash(wget *)"
    ],
    "deny": [
      "Bash(npm *)", "Bash(yarn *)", "Bash(pnpm *)",
      "Bash(*--no-verify*)", "Bash(*--no-hooks*)",
      "Read(.env)", "Read(.env.*)",
      "Read(**/.env)", "Read(**/.env.*)",
      "Read(**/secrets/**)", "Read(**/*.pem)", "Read(**/*.key)"
    ]
  }
}
```

### 9.3 CI/CD Pipeline (Locked Down)

Priority: deterministic, no network surprises, auditable

```json
{
  "permissions": {
    "defaultMode": "dontAsk",
    "allow": [
      "Read", "Edit", "Write", "Glob", "Grep",
      "Bash(bun *)", "Bash(bun)", "Bash(bunx *)",
      "Bash(git status *)", "Bash(git status)",
      "Bash(git diff *)", "Bash(git diff)",
      "Bash(git log *)", "Bash(git log)",
      "Bash(git add *)", "Bash(git commit *)",
      "Bash(ls *)", "Bash(cat *)", "Bash(grep *)",
      "Bash(head *)", "Bash(tail *)", "Bash(wc *)",
      "Bash(diff *)", "Bash(jq *)", "Bash(echo *)",
      "Bash(mkdir *)", "Bash(touch *)", "Bash(cp *)"
    ],
    "deny": [
      "WebFetch", "WebSearch",
      "Bash(curl *)", "Bash(wget *)", "Bash(ssh *)",
      "Bash(git push *)", "Bash(git push)",
      "Bash(rm -rf *)",
      "Bash(npm *)", "Bash(yarn *)", "Bash(pnpm *)",
      "Bash(*--no-verify*)", "Bash(*--no-hooks*)",
      "Read(.env)", "Read(.env.*)",
      "Read(**/.env)", "Read(**/.env.*)",
      "Read(**/secrets/**)"
    ]
  }
}
```

### 9.4 Security Audit / Penetration Testing

Priority: maximum restriction, every action logged

```json
{
  "permissions": {
    "defaultMode": "plan",
    "allow": [
      "Read", "Glob", "Grep"
    ],
    "ask": [
      "Bash", "Edit", "Write", "WebFetch", "WebSearch"
    ],
    "deny": [
      "Bash(rm *)", "Bash(curl *)", "Bash(wget *)",
      "Bash(ssh *)", "Bash(scp *)",
      "Bash(*--no-verify*)", "Bash(*--no-hooks*)",
      "Read(.env)", "Read(.env.*)",
      "Read(**/.env)", "Read(**/.env.*)",
      "Read(**/secrets/**)", "Read(**/*.pem)", "Read(**/*.key)"
    ]
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/audit-log.sh",
            "async": true
          }
        ]
      }
    ]
  }
}
```

---

## 10. Advanced Patterns

### 10.1 Sandbox + Permissions Combo (Recommended Production Setup)

The most secure development setup combines sandbox + permissions + hooks:

```json
{
  "permissions": {
    "defaultMode": "acceptEdits",
    "allow": [
      "Read", "Edit", "Write", "MultiEdit", "Glob", "Grep",
      "NotebookEdit", "WebSearch", "Task",
      "Bash(git *)", "Bash(gh *)",
      "Bash(bun *)", "Bash(bun)", "Bash(bunx *)",
      "Bash(node *)", "Bash(npx *)",
      "Bash(ls *)", "Bash(cat *)", "Bash(grep *)",
      "Bash(head *)", "Bash(tail *)", "Bash(wc *)",
      "Bash(echo *)", "Bash(jq *)", "Bash(diff *)"
    ],
    "deny": [
      "Bash(*--no-verify*)", "Bash(*--no-hooks*)",
      "Read(.env)", "Read(.env.*)",
      "Read(**/.env)", "Read(**/.env.*)"
    ]
  },
  "sandbox": {
    "enabled": true,
    "autoAllowBashIfSandboxed": true,
    "allowUnsandboxedCommands": false,
    "excludedCommands": ["docker", "git"],
    "filesystem": {
      "allowWrite": ["//tmp", "~/.bun"],
      "denyRead": ["~/.ssh", "~/.aws", "~/.gnupg"]
    },
    "network": {
      "allowedDomains": [
        "github.com",
        "*.npmjs.org",
        "registry.npmjs.org",
        "api.anthropic.com"
      ],
      "allowLocalBinding": true
    }
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/block-dangerous.sh"
          }
        ]
      },
      {
        "matcher": "Read|Edit|Write|MultiEdit|Bash",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/protect-files.sh"
          }
        ]
      }
    ]
  }
}
```

### 10.2 MCP Server Access Control

```json
{
  "permissions": {
    "allow": [
      "mcp__context7__*",
      "mcp__memory__*",
      "mcp__github__*"
    ],
    "deny": [
      "mcp__filesystem__*"
    ]
  },
  "enabledMcpjsonServers": ["context7", "memory", "github"],
  "disabledMcpjsonServers": ["filesystem"]
}
```

### 10.3 Environment Variable Protection

```json
{
  "env": {
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  },
  "sandbox": {
    "filesystem": {
      "denyRead": [
        "~/.aws/credentials",
        "~/.ssh/id_rsa",
        "~/.ssh/id_ed25519",
        "~/.gnupg/private-keys-v1.d",
        "~/.config/gcloud/application_default_credentials.json"
      ]
    }
  }
}
```

### 10.4 Network Restriction Patterns

**Block all network from bash** (use WebFetch for controlled access):
```json
{
  "permissions": {
    "deny": [
      "Bash(curl *)",
      "Bash(wget *)",
      "Bash(nc *)",
      "Bash(netcat *)",
      "Bash(ncat *)",
      "Bash(telnet *)"
    ],
    "allow": [
      "WebFetch(domain:github.com)",
      "WebFetch(domain:docs.example.com)"
    ]
  }
}
```

**Warning from official docs**: Denying `curl`/`wget` in bash does NOT prevent all network access if `Bash` is allowed. Claude can use other tools or techniques. For true network isolation, use the sandbox's `allowedDomains`.

### 10.5 PostToolUse Hooks for Quality

Auto-format after file edits:
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "bunx biome check --write --no-errors-on-unmatched $CLAUDE_FILE_PATH 2>/dev/null; exit 0",
            "timeout": 15
          }
        ]
      }
    ]
  }
}
```

### 10.6 ConfigChange Hook (Detect Settings Tampering)

```json
{
  "hooks": {
    "ConfigChange": [
      {
        "matcher": "project_settings|local_settings",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'WARNING: Configuration changed during session' >> ~/.claude/config-changes.log"
          }
        ]
      }
    ]
  }
}
```

---

## 11. Managed Settings for Organizations

### 11.1 Managed-Only Settings

These settings can ONLY be set in managed settings (not user/project):

| Setting | Purpose |
|---------|---------|
| `disableBypassPermissionsMode` | Set to `"disable"` to prevent `--dangerously-skip-permissions` |
| `allowManagedPermissionRulesOnly` | Only managed rules for allow/ask/deny |
| `allowManagedHooksOnly` | Only managed+SDK hooks allowed |
| `allowManagedMcpServersOnly` | Only managed MCP servers allowed |
| `blockedMarketplaces` | Block specific plugin sources |
| `sandbox.network.allowManagedDomainsOnly` | Only managed domains for network access |
| `strictKnownMarketplaces` | Control which plugin marketplaces users can add |
| `allow_remote_sessions` | Enable/disable Remote Control and web sessions |

### 11.2 Environment Variables for Hardening

```json
{
  "env": {
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
    "BASH_MAX_TIMEOUT_MS": "120000",
    "BASH_MAX_OUTPUT_LENGTH": "50000",
    "MCP_TIMEOUT": "30000",
    "MAX_MCP_OUTPUT_TOKENS": "25000"
  }
}
```

---

## 12. Security Best Practices Summary

### Do

1. **Layer your defenses**: permissions + sandbox + hooks + managed settings
2. **Use `acceptEdits` mode** for daily work (auto-approves file ops, still prompts for bash)
3. **Protect .env files** with BOTH deny rules AND PreToolUse hooks
4. **Enable sandboxing** on macOS (zero setup) or Linux (install bubblewrap)
5. **Use domain-scoped WebFetch** instead of blanket allow
6. **Commit `.claude/settings.json`** to version control for team consistency
7. **Keep personal overrides** in `.claude/settings.local.json` (gitignored)
8. **Audit permissions** regularly with `/permissions`
9. **Use `dontAsk` mode** for CI/CD (auto-denies non-allowlisted tools)
10. **Block `--no-verify` and `--no-hooks`** in deny rules

### Don't

1. **Don't use `bypassPermissions`** outside containers/VMs
2. **Don't rely solely on deny rules** for critical file protection (use hooks)
3. **Don't allow broad bash patterns** like `Bash(*)` without sandbox
4. **Don't allow `sudo`** in production settings
5. **Don't allow `docker.sock` access** via sandbox Unix sockets
6. **Don't allow writes to `$PATH` directories** in sandbox filesystem config
7. **Don't skip hooks** (`--no-verify`, `--no-hooks`) -- enforce via deny rules
8. **Don't run Claude as root**
9. **Don't store secrets in CLAUDE.md** or settings files
10. **Don't assume deny rules work** for Read/Write tools (known bugs as of 2026)

### Defense-in-Depth Architecture

```
Layer 1: Permission deny rules
  |-- Blocks at the intent level (Claude won't attempt)
  |-- Known issues: may not enforce for Read/Write tools

Layer 2: PreToolUse hooks
  |-- Programmable blocking logic
  |-- Inspects actual command/file path
  |-- Most reliable enforcement mechanism

Layer 3: OS-level sandbox
  |-- Filesystem isolation (Seatbelt/bubblewrap)
  |-- Network domain filtering
  |-- Cannot be bypassed by prompt injection

Layer 4: Managed settings
  |-- Organization-wide policies
  |-- Cannot be overridden by users/projects
  |-- Enforces bypass prevention
```

---

## 13. Quick Reference: Existing Project Analysis

### Hypebase AI Current Configuration

**User-level** (`~/.claude/settings.json`):
- Very comprehensive allow list (200+ commands)
- `defaultMode: "acceptEdits"`
- Minimal deny list (only catastrophic destruction)
- Includes ALL package managers (npm, yarn, pnpm, pip, cargo, go, etc.)

**Project-level** (`.claude/settings.json`):
- Enforces bun-only (denies npm/yarn/pnpm)
- Blocks `--no-verify` and `--no-hooks`
- Protects sensitive files (.env, certs, credentials)
- Domain-scoped WebFetch
- PostToolUse hook for Biome formatting
- TeammateIdle and TaskCompleted hooks for beads integration

**Effective configuration** (merged): Project deny rules override user allow rules. So even though the user allows `npm`, the project denies it -- project wins because deny always takes precedence.

### Recommendations for Hypebase AI

1. **Add PreToolUse hooks** for sensitive file protection (don't rely solely on deny rules)
2. **Enable sandbox** for OS-level enforcement
3. **Update legacy colon syntax** (`Bash(curl:*)` -> `Bash(curl *)`) in project settings
4. **Add `MultiEdit` and `Glob`** to project allow list (currently only in user settings)
5. **Consider adding audit logging hook** for team development visibility

---

*Research completed: 2026-03-05*
*Coverage: Official docs, community guides, real-world configs, GitHub issues, security analysis*
