# Core Setup Prompts (1-5) -- The Ultimate Claude Code Configuration

> Copy-paste each prompt into Claude Code in order. Each is self-contained and idempotent.
> Version: 1.0.0 | Date: 2026-03-05 | Source: 16K lines of research across 12 files

---

## PROMPT 1: Discovery & Analysis

```
# Claude Code Setup -- Prompt 1: Discovery & Analysis
# Version: 1.0.0 | Date: 2026-03-05
# Self-updating: checks online docs before acting

IMPORTANT -- SELF-UPDATE PROTOCOL:
Before implementing ANYTHING in this prompt, you MUST:
1. WebFetch https://code.claude.com/docs/llms.txt
2. WebFetch https://code.claude.com/docs/en/best-practices
3. WebFetch https://raw.githubusercontent.com/anthropics/claude-code/main/README.md
4. If ANY information below conflicts with what you find online, USE THE ONLINE VERSION.
5. Note discrepancies in a "## Updates Found" section of your output.

---

## YOUR TASK

Analyze this repository and produce a structured detection report. Do NOT modify any files -- this is read-only analysis. Save the report to `/tmp/claude-setup-discovery.json` and display a human-readable summary.

## DETECTION CHECKLIST

Run these checks (all read-only). For each category, use the detection method listed:

### 1. Package Manager
Check for lock files in this order (first match wins):
- `bun.lockb` or `bun.lock` -> bun
- `pnpm-lock.yaml` -> pnpm
- `yarn.lock` -> yarn
- `package-lock.json` -> npm
- `Cargo.lock` -> cargo
- `go.sum` -> go
- `Pipfile.lock` or `poetry.lock` or `uv.lock` -> pip/poetry/uv
- `Gemfile.lock` -> bundler
- `composer.lock` -> composer

### 2. Framework & Language
- Read `package.json` (if exists): check `dependencies` and `devDependencies` for frameworks (next, react, vue, svelte, express, fastify, etc.)
- Check for `Cargo.toml` (Rust), `go.mod` (Go), `requirements.txt`/`pyproject.toml` (Python), `Gemfile` (Ruby)
- ALSO scan immediate subdirectories for these files (multi-component projects often nest configs):
  `find . -maxdepth 2 \( -name "pyproject.toml" -o -name "requirements.txt" -o -name "Cargo.toml" -o -name "go.mod" -o -name "Gemfile" \) -not -path "*/node_modules/*" 2>/dev/null`
- Count predominant file extensions to detect ALL languages present:
  `find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.py" -o -name "*.rs" -o -name "*.go" -o -name "*.rb" -o -name "*.java" \) -not -path "*/node_modules/*" -not -path "*/.venv/*" -not -path "*/target/*" 2>/dev/null | sed 's/.*\.//' | sort | uniq -c | sort -rn`
- If multiple languages have significant file counts (>10 files each), report as multi-language project and include ALL detected stacks
- Check for `tsconfig.json` (TypeScript), `.python-version`, `rust-toolchain.toml`

### 3. Existing Claude Code Configuration
- `CLAUDE.md` -- exists? line count? has sections for NEVER/ALWAYS/hooks?
- `.claude/` directory -- exists? has `settings.json`? has `hooks/`? has `agents/`? has `skills/`?
- `~/.claude/settings.json` -- exists? has permissions? has hooks? has env vars?
- `.claudeignore` -- exists? line count?
- `.mcp.json` -- exists? which servers configured?

### 4. Quality Tools
Detect installed tools by checking config files and package.json:
- Linters: ESLint, Biome, Ruff, clippy, golangci-lint, RuboCop
- Formatters: Prettier, Biome, Black, rustfmt, gofmt
- Type checkers: TypeScript (tsc/tsgo), mypy, pyright
- Test runners: Jest, Vitest, Bun test, pytest, cargo test, go test, RSpec
- Dead code: Knip, vulture
- Other: Semgrep, dependency-cruiser, Husky, lint-staged

### 5. Infrastructure
- Git: `.git/` exists? main branch name? existing git hooks in `.git/hooks/`?
- CI/CD: `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`, `.circleci/`, `bitbucket-pipelines.yml`
- Docker: `Dockerfile`, `docker-compose.yml` or `docker-compose.*.yml`
- Monorepo: `pnpm-workspace.yaml`, `lerna.json`, `nx.json`, `turbo.json`

### 6. External Services
Check `.env.example` or `.env.local.example` for service integrations:
- Auth (Clerk, Auth0, NextAuth, Supabase Auth)
- Database (Supabase, PostgreSQL, MongoDB, Redis)
- AI/LLM (OpenAI, Anthropic, Vercel AI SDK)
- Payments (Stripe)
- Monitoring (Sentry, PostHog)

### 7. Performance Baseline
- Shell startup time: run `time zsh -i -c exit 2>&1` (capture real time)
- Git fsmonitor: `git config core.fsmonitor` (true/false/empty)
- File descriptor limit: `ulimit -n`

## OUTPUT FORMAT

Save this exact JSON structure to `/tmp/claude-setup-discovery.json`:

{
  "timestamp": "<ISO 8601>",
  "claudeCodeVersion": "<from docs or 'unknown'>",
  "project": {
    "name": "<directory name>",
    "path": "<absolute path>",
    "language": "<primary language>",
    "framework": "<detected framework and version>",
    "packageManager": "<detected>",
    "monorepo": false,
    "monorepoTool": null
  },
  "existingConfig": {
    "claudeMd": { "exists": true/false, "lines": <number>, "hasSections": [] },
    "claudeDir": { "exists": true/false, "hasSettings": true/false, "hasHooks": true/false, "hasAgents": true/false, "hasSkills": true/false },
    "userSettings": { "exists": true/false, "hasPermissions": true/false, "hasHooks": true/false, "hasEnv": true/false },
    "mcp": { "exists": true/false, "servers": [] },
    "beads": { "installed": true/false, "initialized": true/false, "version": null },
    "claudeignore": { "exists": true/false, "lines": 0 }
  },
  "qualityTools": {
    "linter": "<name or null>",
    "formatter": "<name or null>",
    "typeChecker": "<name or null>",
    "testRunner": "<name or null>",
    "deadCode": "<name or null>",
    "other": []
  },
  "ci": { "platform": "<name or null>", "workflows": [] },
  "docker": { "exists": true/false, "compose": true/false },
  "services": [],
  "performance": {
    "shellStartupMs": <number>,
    "gitFsmonitor": true/false,
    "ulimitN": <number>
  },
  "recommendations": [
    "<actionable recommendation for subsequent prompts>"
  ]
}

## HUMAN-READABLE SUMMARY

After saving the JSON, display a summary like this:

=== Claude Code Setup Discovery ===

Project: <name> (<language> / <framework>)
Package Manager: <detected>
Path: <absolute path>

Existing Config:
  CLAUDE.md:      [EXISTS / MISSING] (<lines> lines)
  .claude/ dir:   [EXISTS / MISSING] (settings: Y/N, hooks: Y/N)
  User settings:  [EXISTS / MISSING]
  MCP servers:    [CONFIGURED / NONE] (<list>)
  Beads:          [INSTALLED / NOT FOUND]
  .claudeignore:  [EXISTS / MISSING]

Quality Tools: <linter>, <formatter>, <type checker>, <test runner>

Performance:
  Shell startup:  <N>ms (target: <100ms)
  Git fsmonitor:  [ENABLED / DISABLED]
  File desc limit: <N> (recommended: 65536)

Recommendations:
  1. <recommendation>
  2. <recommendation>
  ...

Next: Copy-paste Prompt 2 (Foundation) to set up settings, permissions, and CLAUDE.md.

## VERIFICATION

Before finishing, verify:
- [ ] `/tmp/claude-setup-discovery.json` exists and is valid JSON (test with `cat /tmp/claude-setup-discovery.json | python3 -m json.tool` or `jq .`)
- [ ] At least 3 recommendations are listed
- [ ] Shell startup time was measured (not skipped)
- [ ] All detected tools match reality (spot-check by running 2-3 detected tool commands)
```

---

## PROMPT 2: Foundation (Settings, Permissions, CLAUDE.md)

```
# Claude Code Setup -- Prompt 2: Foundation
# Version: 1.0.0 | Date: 2026-03-05
# Self-updating: checks online docs before acting

IMPORTANT -- SELF-UPDATE PROTOCOL:
Before implementing ANYTHING in this prompt, you MUST:
1. WebFetch https://code.claude.com/docs/en/settings
2. WebFetch https://code.claude.com/docs/en/permissions
3. WebFetch https://code.claude.com/docs/en/claude-md
4. WebFetch https://code.claude.com/docs/en/security
5. If ANY information below conflicts with what you find online, USE THE ONLINE VERSION.
6. Note discrepancies in a "## Updates Found" section of your output.

---

## YOUR TASK

Set up the three foundational configuration layers: user settings, project settings, and CLAUDE.md. This is the bedrock everything else builds on.

## STEP 0: Load Discovery

If `/tmp/claude-setup-discovery.json` exists (from Prompt 1), read it for stack detection. If not, perform inline detection:
- Check for lock files (bun.lock -> bun, pnpm-lock.yaml -> pnpm, yarn.lock -> yarn, etc.)
- Read package.json for framework detection
- Check for tsconfig.json, pyproject.toml, Cargo.toml, go.mod

## STEP 1: User Settings (~/.claude/settings.json)

Read the existing file first. MERGE new settings -- never replace existing ones. If the file does not exist, create it. Always back up the existing file to `~/.claude/settings.json.backup` before changes.

Add/merge these settings:

{
  "permissions": {
    "allow": [
      "Read",
      "Glob",
      "Grep",
      "Bash(git status*)",
      "Bash(git log *)",
      "Bash(git diff *)",
      "Bash(git branch *)",
      "Bash(which *)",
      "Bash(ls *)",
      "Bash(pwd)",
      "Bash(echo *)",
      "Bash(date)",
      "Bash(uname *)",
      "Bash(wc *)",
      "Bash(cat *)",
      "Bash(head *)",
      "Bash(tail *)",
      "mcp__context7__*"
    ],
    "deny": [
      "Read(.env)",
      "Read(.env.*)",
      "Read(**/secrets/**)",
      "Read(**/.aws/credentials)",
      "Bash(rm -rf /)",
      "Bash(rm -rf ~)",
      "Bash(rm -rf .)",
      "Bash(sudo rm *)",
      "Bash(curl * | bash)",
      "Bash(curl * | sh)",
      "Bash(wget * | bash)",
      "Bash(wget * | sh)",
      "Bash(chmod 777 *)",
      "Bash(eval *)"
    ]
  },
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}

## STEP 2: Project Settings (.claude/settings.json)

Create `.claude/` directory if it does not exist. Read existing `.claude/settings.json` if it exists -- MERGE, do not replace. Back up to `.claude/settings.json.backup` before changes.

The permissions MUST be adapted to the detected stack. Use this mapping:

### JavaScript/TypeScript (bun):
"Bash(bun install *)", "Bash(bun run *)", "Bash(bun test *)", "Bash(bun add *)", "Bash(bunx *)",
"Bash(npx tsc *)", "Bash(npx tsgo *)", "Bash(npx biome *)", "Bash(npx eslint *)", "Bash(npx knip *)"

### JavaScript/TypeScript (npm):
"Bash(npm install *)", "Bash(npm run *)", "Bash(npm test *)", "Bash(npx *)"

### JavaScript/TypeScript (pnpm):
"Bash(pnpm install *)", "Bash(pnpm run *)", "Bash(pnpm test *)", "Bash(pnpm add *)", "Bash(pnpx *)"

### JavaScript/TypeScript (yarn):
"Bash(yarn install *)", "Bash(yarn run *)", "Bash(yarn test *)", "Bash(yarn add *)"

### Python:
"Bash(pip install *)", "Bash(uv *)", "Bash(python -m *)", "Bash(python *)",
"Bash(pytest *)", "Bash(ruff *)", "Bash(mypy *)", "Bash(black *)"

### Rust:
"Bash(cargo build *)", "Bash(cargo run *)", "Bash(cargo test *)",
"Bash(cargo clippy *)", "Bash(cargo fmt *)", "Bash(cargo add *)"

### Go:
"Bash(go build *)", "Bash(go run *)", "Bash(go test *)",
"Bash(go vet *)", "Bash(go fmt *)", "Bash(golangci-lint *)",
"Bash(staticcheck *)", "Bash(go mod *)"

### Ruby:
"Bash(bundle *)", "Bash(rails *)", "Bash(rspec *)", "Bash(rubocop *)", "Bash(rake *)"

Always include these regardless of stack:
"Bash(git add *)", "Bash(git commit *)", "Bash(git stash *)", "Bash(git checkout *)",
"Bash(git switch *)", "Bash(git merge *)"

Always deny these regardless of stack:
"Bash(git push --force*)", "Bash(git push -f *)", "Bash(git reset --hard*)",
"Bash(rm -rf *)"

Add if Docker detected:
"Bash(docker compose *)", "Bash(docker logs *)", "Bash(docker ps *)"

Set `"defaultMode": "acceptEdits"` for smooth workflow.

## STEP 3: .claudeignore

If `.claudeignore` does not exist, create it. If it exists, extend it (do not duplicate entries).

Always include:
node_modules/
.pnpm/
vendor/
venv/
.venv/
__pycache__/
target/
.next/
dist/
build/
out/
.turbo/
coverage/
.nyc_output/
playwright-report/
test-results/
.DS_Store
Thumbs.db
*.min.js
*.min.css
*.bundle.js
*.map

Add stack-specific entries:
- JS/TS: `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `bun.lockb`
- Python: `*.egg-info/`, `.mypy_cache/`, `.ruff_cache/`
- Rust: `target/`
- Go: `vendor/`, `bin/`

## STEP 4: CLAUDE.md

If CLAUDE.md does NOT exist, create this scaffold (adapt all bracketed values to detected stack):

# CLAUDE.md -- [Project Name]

## Overview
[Read the project's README.md or package.json description to fill this in. If neither exists, write: "TODO: Add project description"]

**Stack:** [detected] | **Language:** [detected] | **Package Manager:** [detected]

## Quick Start
```bash
[detected install command]   # Install dependencies
[detected dev command]       # Start dev server
[detected build command]     # Production build
[detected test command]      # Run tests
```

## Architecture
[List top-level directories with 1-line descriptions. Read the actual directory structure.]

## Core Patterns
[Add 3-5 framework-specific patterns. For Next.js: App Router, Server Components, etc. For Django: views, models, serializers. For Rust: ownership, error handling.]

## Quality Gates
[List detected quality tools and their run commands in a table]

## NEVER
- No hardcoded API keys or credentials -- use environment variables
- No skipping quality gates before committing

## ALWAYS
- Run quality checks before every commit
- Follow existing code conventions in the codebase

## Self-Updating Rule
When you learn something useful from debugging, bugfixing, or implementing -- update this file immediately.

If CLAUDE.md ALREADY exists:
- Read it completely
- Check which sections are missing from the scaffold above
- APPEND only the missing sections (never modify or remove existing content)
- Tell the user exactly what sections you added

## STEP 5: Directory Structure

Ensure these directories exist:
- `.claude/` (created in Step 2)
- `.claude/hooks/` (will be populated by Prompt 3)
- `.claude/skills/` (for custom skills)
- `.claude/agents/` (for custom agent definitions)

## VERIFICATION

Run these checks and report results:

1. `~/.claude/settings.json` -- valid JSON? has permissions.allow? has permissions.deny?
2. `.claude/settings.json` -- valid JSON? has stack-specific permissions? has deny rules?
3. `CLAUDE.md` -- exists? has >= 5 sections (count lines starting with ##)?
4. `.claudeignore` -- exists? has >= 10 patterns?
5. `.claude/hooks/` directory exists?
6. No existing configuration was destroyed (backup files exist if originals were modified)?

Display results:
=== Foundation Setup Complete ===
[PASS/FAIL] User settings (~/.claude/settings.json)
[PASS/FAIL] Project settings (.claude/settings.json)
[PASS/FAIL] CLAUDE.md (<N> sections, <N> lines)
[PASS/FAIL] .claudeignore (<N> patterns)
[PASS/FAIL] Directory structure (.claude/hooks/, skills/, agents/)
[PASS/FAIL] No config destroyed (backups created)

Next: Copy-paste Prompt 3 (Hooks & Quality Gates) to install lifecycle hooks.
```

---

## PROMPT 3: Hooks & Quality Gates

```
# Claude Code Setup -- Prompt 3: Hooks & Quality Gates
# Version: 1.0.0 | Date: 2026-03-05
# Self-updating: checks online docs before acting

IMPORTANT -- SELF-UPDATE PROTOCOL:
Before implementing ANYTHING in this prompt, you MUST:
1. WebFetch https://code.claude.com/docs/en/hooks
2. WebFetch https://code.claude.com/docs/en/hooks-guide
3. If ANY information below conflicts with what you find online, USE THE ONLINE VERSION.
4. Note discrepancies in a "## Updates Found" section of your output.

---

## YOUR TASK

Install the hooks system -- Claude Code's most powerful automation feature. Create hook scripts and configure them in settings.json.

## PREREQUISITES

`.claude/settings.json` must exist (from Prompt 2). If it does not, tell the user to run Prompt 2 first.

## STEP 0: Detect Context

1. Read `.claude/settings.json` -- check for existing hooks (preserve them)
2. Read `/tmp/claude-setup-discovery.json` (if exists) for quality tools
3. If no discovery file, detect: which linter? which formatter? which type checker?
4. Detect OS: `uname -s` (Darwin = macOS, Linux = Linux)

## STEP 1: Create Hook Scripts

Create all scripts in `.claude/hooks/`. Make each executable with `chmod +x`.

### A. block-dangerous.sh (ALWAYS install -- security critical)

#!/bin/bash
# Block dangerous commands before execution
# Hook: PreToolUse (matcher: Bash)
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

BLOCKED_PATTERNS=(
  "rm -rf /"
  "rm -rf ~"
  "rm -rf ."
  ":(){ :|:& };:"
  "curl * | sh"
  "curl * | bash"
  "wget * | sh"
  "wget * | bash"
  "chmod 777"
  "dd if="
  "mkfs"
  "> /dev/sd"
  "git push --force origin main"
  "git push --force origin master"
  "git push -f origin main"
  "git push -f origin master"
  "DROP DATABASE"
  "DROP TABLE"
  "TRUNCATE TABLE"
  "sudo rm"
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if [[ "$COMMAND" == *"$pattern"* ]]; then
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"reason\":\"BLOCKED: matches dangerous pattern '$pattern'\"}}"
    exit 0
  fi
done
echo '{}'

### B. post-tool-lint.sh (Install if linter/formatter detected)

#!/bin/bash
# Auto-format files after edits
# Hook: PostToolUse (matcher: Write|Edit|MultiEdit)
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[ -z "$FILE_PATH" ] && exit 0
[ ! -f "$FILE_PATH" ] && exit 0

# Detect and run the appropriate formatter
# Adapt this section based on what the discovery report found:

# JavaScript/TypeScript (Biome)
if command -v npx &>/dev/null && { [ -f "biome.json" ] || [ -f "biome.jsonc" ]; }; then
  case "$FILE_PATH" in
    *.ts|*.tsx|*.js|*.jsx|*.json|*.css)
      npx biome format --write "$FILE_PATH" 2>/dev/null
      ;;
  esac

# JavaScript/TypeScript (Prettier)
elif command -v npx &>/dev/null && { [ -f ".prettierrc" ] || [ -f ".prettierrc.json" ] || [ -f "prettier.config.js" ]; }; then
  case "$FILE_PATH" in
    *.ts|*.tsx|*.js|*.jsx|*.json|*.css|*.md)
      npx prettier --write "$FILE_PATH" 2>/dev/null
      ;;
  esac

# Python (Ruff)
elif command -v ruff &>/dev/null; then
  case "$FILE_PATH" in
    *.py)
      ruff format "$FILE_PATH" 2>/dev/null
      ;;
  esac

# Python (Black)
elif command -v black &>/dev/null; then
  case "$FILE_PATH" in
    *.py)
      black --quiet "$FILE_PATH" 2>/dev/null
      ;;
  esac

# Rust
elif command -v rustfmt &>/dev/null; then
  case "$FILE_PATH" in
    *.rs)
      rustfmt "$FILE_PATH" 2>/dev/null
      ;;
  esac

# Go
elif command -v gofmt &>/dev/null; then
  case "$FILE_PATH" in
    *.go)
      gofmt -w "$FILE_PATH" 2>/dev/null
      ;;
  esac
fi

### C. session-start.sh (ALWAYS install)

#!/bin/bash
# Initialize session with project context
# Hook: SessionStart
echo "=== Session Start ==="
echo "Project: $(basename "$(pwd)")"
echo "Branch: $(git branch --show-current 2>/dev/null || echo 'not a git repo')"
git status --short 2>/dev/null | head -20
echo ""
# Beads integration (safe to fail if not installed)
if command -v bd &>/dev/null && [ -d ".beads" ]; then
  bd prime 2>/dev/null
fi

### D. pre-compact.sh (ALWAYS install)

#!/bin/bash
# Save state before context compaction
# Hook: PreCompact
echo "=== Pre-Compact: Saving State ==="
# Commit beads state if available
if command -v bd &>/dev/null && [ -d ".beads" ]; then
  bd sync 2>/dev/null
fi
# Log current work context
echo "Working directory: $(pwd)"
echo "Branch: $(git branch --show-current 2>/dev/null)"
echo "Modified files:"
git diff --name-only 2>/dev/null | head -10

### E. notification.sh (ALWAYS install)

#!/bin/bash
# Desktop notification when Claude needs attention
# Hook: Notification (async)
INPUT=$(cat)
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Claude Code needs your attention"')

if [[ "$(uname -s)" == "Darwin" ]]; then
  osascript -e 'display notification "'"${MESSAGE//\"/\\\"}"'" with title "Claude Code"' 2>/dev/null
elif command -v notify-send &>/dev/null; then
  notify-send "Claude Code" "$MESSAGE" 2>/dev/null
fi

### F. stop-summary.sh (ALWAYS install)

#!/bin/bash
# Show summary when Claude stops
# Hook: Stop
echo ""
echo "=== Session Summary ==="
echo "Modified files since session start:"
git diff --name-only 2>/dev/null | head -20
echo ""
echo "Uncommitted changes:"
git status --short 2>/dev/null | wc -l | xargs echo "  files:"

### G. tdd-enforce.sh (OPTIONAL -- install if project has tests)

#!/bin/bash
# Encourage test creation alongside new code
# Hook: Stop (fires when Claude finishes a response)
# This checks if new source files were created without corresponding tests
INPUT=$(cat)

# Only check if there are staged/modified files
MODIFIED=$(git diff --name-only --cached 2>/dev/null; git diff --name-only 2>/dev/null)
[ -z "$MODIFIED" ] && exit 0

# Count new source files (not test files)
NEW_SRC=$(echo "$MODIFIED" | grep -vE '(test|spec|__tests__|e2e|\.test\.|\.spec\.)' | grep -E '\.(ts|tsx|js|jsx|py|rs|go|rb)$' | wc -l | tr -d ' ')
# Count new test files
NEW_TESTS=$(echo "$MODIFIED" | grep -E '(test|spec|__tests__|\.test\.|\.spec\.)' | wc -l | tr -d ' ')

if [ "$NEW_SRC" -gt 0 ] && [ "$NEW_TESTS" -eq 0 ]; then
  echo "TDD reminder: $NEW_SRC source file(s) modified but no test files changed." >&2
  echo "Consider adding tests for new code before committing." >&2
  # Exit 0 (advisory only, don't block). Change to exit 2 to enforce.
  exit 0
fi

exit 0

## STEP 2: Configure Hooks in Settings

Read `.claude/settings.json`, MERGE the following hooks block into the existing configuration. Do NOT replace existing hooks -- add alongside them.

{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/session-start.sh",
            "timeout": 10000
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/block-dangerous.sh",
            "timeout": 5000
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/post-tool-lint.sh",
            "timeout": 30000
          }
        ]
      }
    ],
    "PreCompact": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/pre-compact.sh",
            "timeout": 10000
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/stop-summary.sh",
            "timeout": 10000
          }
        ]
      }
    ],
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/notification.sh",
            "timeout": 5000,
            "async": true
          }
        ]
      }
    ]
  }
}

## STEP 3: Global Hooks (User Settings)

If beads is detected (from discovery or `which bd`), add these to `~/.claude/settings.json` (merge, do not replace):

{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bd prime 2>/dev/null || true",
            "timeout": 10000
          }
        ]
      }
    ],
    "PreCompact": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bd sync 2>/dev/null || true",
            "timeout": 15000
          }
        ]
      }
    ]
  }
}

If beads is NOT detected, skip this step and note: "Beads hooks will be added by Prompt 4."

## VERIFICATION

1. All hook scripts exist and are executable:
   ls -la .claude/hooks/*.sh

2. Test the dangerous command blocker:
   echo '{"tool_input":{"command":"rm -rf /"}}' | .claude/hooks/block-dangerous.sh
   (Should output JSON with permissionDecision: "deny")

3. Test with a safe command:
   echo '{"tool_input":{"command":"git status"}}' | .claude/hooks/block-dangerous.sh
   (Should output {})

4. `.claude/settings.json` has a valid hooks block (parse with jq)

5. Hook scripts handle missing jq gracefully -- if jq is not installed, warn the user:
   "Install jq for full hook functionality: brew install jq (macOS) or sudo apt install jq (Linux)"

Display results:
=== Hooks Setup Complete ===
[PASS/FAIL] block-dangerous.sh -- blocks "rm -rf /", allows "git status"
[PASS/FAIL] post-tool-lint.sh -- created with [biome/prettier/ruff/black/rustfmt/gofmt] formatter
[PASS/FAIL] session-start.sh -- shows git status
[PASS/FAIL] pre-compact.sh -- saves state
[PASS/FAIL] notification.sh -- sends desktop notification
[PASS/FAIL] stop-summary.sh -- shows session summary
[PASS/FAIL] settings.json hooks block -- valid JSON, 6 events configured
[PASS/FAIL] All scripts executable (chmod +x)

Scripts created: <N>
Events configured: <N>

Next: Copy-paste Prompt 4 (Beads Integration) to install the persistent issue tracker.
```

---

## PROMPT 4: Beads Integration

```
# Claude Code Setup -- Prompt 4: Beads Integration
# Version: 1.0.0 | Date: 2026-03-05
# Self-updating: checks online docs before acting

IMPORTANT -- SELF-UPDATE PROTOCOL:
Before implementing ANYTHING in this prompt, you MUST:
1. WebFetch https://raw.githubusercontent.com/steveyegge/beads/main/README.md
2. WebFetch https://github.com/steveyegge/beads/releases (check latest version)
3. If ANY information below conflicts with what you find online, USE THE ONLINE VERSION.
   In particular, check if installation commands, CLI syntax, or hook integration has changed.
4. Note discrepancies in a "## Updates Found" section of your output.

---

## YOUR TASK

Install the Beads issue tracker, initialize it for this project, configure hooks integration, and add usage instructions to CLAUDE.md.

Beads gives Claude Code agents persistent, structured memory that survives context compaction. It is the backbone of multi-agent coordination.

## STEP 0: Check Prerequisites

1. Hooks system installed? Check for `.claude/hooks/` directory and hooks in `.claude/settings.json`
   - If missing, warn: "Run Prompt 3 first for full integration. Continuing with beads-only setup."
2. Check if beads is already installed: `which bd`
3. Check if already initialized: `test -d .beads`
4. Detect OS: `uname -s`

## STEP 1: Install Beads

If `bd` is NOT found:

### macOS (preferred):
brew install steveyegge/tap/beads

### Fallback (any OS with npm/bun):
If brew is not available or fails:
- bun install -g @beads/bd    (if bun detected)
- npm install -g @beads/bd    (fallback)

NOTE: Check the README you fetched in the self-update step for the CURRENT installation method. The package name or tap may have changed.

### Verify installation:
bd version
(Should print a version number. If it fails, check PATH and try restarting shell.)

## STEP 2: Initialize in Project

If `.beads/` does NOT exist:

bd init

This creates the `.beads/` directory with a Dolt database.

If `.beads/` already exists, skip and note: "Beads already initialized."

Verify: `bd info` should return project information without error.

## STEP 3: Configure Hooks Integration

### A. Global Hooks (SessionStart + PreCompact)

Add to `~/.claude/settings.json` (MERGE with existing hooks -- do NOT replace):

SessionStart hook: "bd prime 2>/dev/null || true" (timeout: 10000)
PreCompact hook: "bd sync 2>/dev/null || true" (timeout: 15000)

The `|| true` ensures the hook does not fail if beads is not initialized in the current project.

If these hooks were already added by Prompt 3, verify they exist and skip.

### B. Team Hooks (TeammateIdle + TaskCompleted)

Create `.claude/hooks/teammate-idle-check.sh`:

#!/bin/bash
# Verify agents close beads issues before going idle
# Hook: TeammateIdle
INPUT=$(cat)
# Check for in-progress beads in the project
if command -v bd &>/dev/null && [ -d ".beads" ]; then
  OPEN=$(bd list --status in_progress --json 2>/dev/null | jq 'length' 2>/dev/null || echo "0")
  if [[ "$OPEN" -gt 0 ]]; then
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"TeammateIdle\",\"permissionDecision\":\"deny\",\"reason\":\"Agent has $OPEN in-progress beads issue(s). Close them with 'bd close <id> --reason ...' before going idle.\"}}"
    exit 0
  fi
fi
echo '{}'

Create `.claude/hooks/task-completed-check.sh`:

#!/bin/bash
# Verify beads issue is closed before CC task completes
# Hook: TaskCompleted
INPUT=$(cat)
SUBJECT=$(echo "$INPUT" | jq -r '.task.subject // empty')
# Extract beads ID from task subject (format: [project-XXXX])
BEAD_ID=$(echo "$SUBJECT" | grep -oE '\[[a-z]+-[a-z]+-[a-z0-9]+\]' | tr -d '[]')
if [[ -n "$BEAD_ID" ]] && command -v bd &>/dev/null && [ -d ".beads" ]; then
  STATUS=$(bd show "$BEAD_ID" --json 2>/dev/null | jq -r '.status // "unknown"' 2>/dev/null)
  if [[ "$STATUS" != "closed" && "$STATUS" != "done" ]]; then
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"TaskCompleted\",\"permissionDecision\":\"deny\",\"reason\":\"Beads issue $BEAD_ID is still '$STATUS'. Close it with 'bd close $BEAD_ID --reason ...' before completing this task.\"}}"
    exit 0
  fi
fi
echo '{}'

Make both executable: `chmod +x .claude/hooks/teammate-idle-check.sh .claude/hooks/task-completed-check.sh`

Add to `.claude/settings.json` hooks block (MERGE):

"TeammateIdle": [
  {
    "hooks": [
      {
        "type": "command",
        "command": ".claude/hooks/teammate-idle-check.sh",
        "timeout": 10000
      }
    ]
  }
],
"TaskCompleted": [
  {
    "hooks": [
      {
        "type": "command",
        "command": ".claude/hooks/task-completed-check.sh",
        "timeout": 10000
      }
    ]
  }
]

## STEP 4: Add Beads Section to CLAUDE.md

Read CLAUDE.md. If it does NOT already contain a "Beads" or "Task Tracking" section, append:

## Task Tracking (Beads)

Beads (`bd`) is this project's persistent, git-backed issue tracker. It gives agents memory that survives context compaction.

**Key commands:**
```bash
bd ready                                   # What can I work on now?
bd create "Title" -p 1 --description="..." --json  # Create a task
bd update <id> --status in_progress --json # Claim a task
bd close <id> --reason "..." --json        # Complete a task
bd dep add <child> <parent>                # Wire dependency
bd sync                                    # Save state
bd prime                                   # Inject state into context
```

**Rules:**
- Always claim a bead before starting work (`bd update <id> --status in_progress`)
- Always close a bead when done (`bd close <id> --reason="..."`)
- Include detailed descriptions when creating tasks (enough for any agent to pick up cold)
- Use dependencies (`bd dep add`) for related tasks

## STEP 5: Create a Test Issue

Create a test issue to verify the full pipeline:

bd create "Setup: Verify beads integration" -p 3 --description="Test issue created by setup prompt. Safe to close." --json

Then immediately close it:

bd close <id-from-above> --reason "Setup verification complete" --json

## VERIFICATION

1. `bd version` returns a version number
2. `.beads/` directory exists
3. `bd ready` runs without error
4. `bd prime` produces output (1-2k tokens of context)
5. Team hooks exist and are executable: `.claude/hooks/teammate-idle-check.sh`, `.claude/hooks/task-completed-check.sh`
6. TeammateIdle and TaskCompleted hooks are in `.claude/settings.json`
7. CLAUDE.md contains beads section
8. Test issue was created and closed successfully

Display results:
=== Beads Integration Complete ===
[PASS/FAIL] Beads installed (version: <version>)
[PASS/FAIL] Project initialized (.beads/ exists)
[PASS/FAIL] SessionStart hook (bd prime)
[PASS/FAIL] PreCompact hook (bd sync)
[PASS/FAIL] TeammateIdle hook (teammate-idle-check.sh)
[PASS/FAIL] TaskCompleted hook (task-completed-check.sh)
[PASS/FAIL] CLAUDE.md updated with beads section
[PASS/FAIL] Test issue created and closed

Next: Copy-paste Prompt 5 (Agent Teams) to configure multi-agent workflows.
```

---

## PROMPT 5: Agent Teams Configuration

```
# Claude Code Setup -- Prompt 5: Agent Teams Configuration
# Version: 1.0.0 | Date: 2026-03-05
# Self-updating: checks online docs before acting

IMPORTANT -- SELF-UPDATE PROTOCOL:
Before implementing ANYTHING in this prompt, you MUST:
1. WebFetch https://code.claude.com/docs/en/agent-teams
2. WebFetch https://code.claude.com/docs/en/claude-md
3. If ANY information below conflicts with what you find online, USE THE ONLINE VERSION.
   Pay special attention to: TeamCreate parameters, spawn options, available modes, and any new team features.
4. Note discrepancies in a "## Updates Found" section of your output.

---

## YOUR TASK

Configure Claude Code's agent teams feature for multi-agent workflows. Set up team patterns, create reusable agent definitions, integrate with beads, and add orchestration instructions to CLAUDE.md.

## STEP 0: Check Prerequisites

1. Agent teams enabled? Check `~/.claude/settings.json` for `"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"` in env
   - If missing, add it now (Prompt 2 should have done this)
2. Beads installed? `which bd` and `test -d .beads`
   - If not, warn: "Beads not found. Agent teams work without beads, but you lose persistent task tracking. Consider running Prompt 4 first."
3. Team hooks configured? Check `.claude/settings.json` for TeammateIdle and TaskCompleted hooks
   - If missing, warn: "Team hooks not found. Consider running Prompt 4 first for full enforcement."

## STEP 1: Create Agent Definitions

Create `.claude/agents/` directory if it does not exist. Create these reusable agent definition files:

### A. .claude/agents/researcher.md

---
name: researcher
model: sonnet
tools: Read, Grep, Glob, WebFetch, WebSearch
description: Research agent for exploring codebases, documentation, and the web
---

You are a research agent. You explore, read, and analyze -- you NEVER modify files.

## Rules
- Read-only operations only (Read, Grep, Glob, WebFetch, WebSearch)
- Report findings with exact file paths and line numbers
- Include relevant code snippets in your findings
- Summarize concisely -- the team lead needs actionable information, not verbose reports
- If you find something unexpected or concerning, flag it explicitly

## Output Format
Structure your findings as:
1. **Summary** (2-3 sentences)
2. **Key Findings** (bullet list with file:line references)
3. **Recommendations** (what should be done next)

### B. .claude/agents/implementer.md

---
name: implementer
model: opus
tools: Read, Write, Edit, Bash, Grep, Glob
description: Implementation agent for writing and modifying production code
---

You are an implementation agent. You write production-quality code.

## Rules
- Always read existing code before modifying it
- Run the project's type checker after making changes
- Follow all coding standards from CLAUDE.md
- If beads is available: claim the bead before starting, close it when done
- Keep changes minimal and focused -- do not refactor surrounding code
- Test your changes if a test runner is available

## Workflow
1. Read the task description and all relevant files
2. Claim the beads issue (if using beads): `bd update <id> --status in_progress`
3. Implement the changes
4. Run quality checks (lint, typecheck)
5. Close the beads issue: `bd close <id> --reason="<what you did>"`

### C. .claude/agents/reviewer.md

---
name: reviewer
model: sonnet
tools: Read, Grep, Glob
description: Code review agent that checks for quality, security, and correctness
---

You are a code review agent. You review changes for quality issues.

## Review Checklist
- Security: no hardcoded secrets, no injection vulnerabilities, proper auth checks
- Error handling: all error paths handled, no swallowed exceptions
- Type safety: no `any` types, proper null checks
- Performance: no N+1 queries, no unnecessary re-renders, no blocking operations
- Testing: changes have corresponding tests or test updates

## Output Format
For each issue found:
- **Severity**: CRITICAL / WARNING / INFO
- **File**: path:line
- **Issue**: description
- **Fix**: suggested fix

## STEP 2: Add Agent Teams Section to CLAUDE.md

Read CLAUDE.md. If it does NOT already contain an "Agent Team" section, append:

## Agent Team Orchestration

### Team Size Guidance
- 3-5 teammates for most workflows
- 5-6 tasks per teammate keeps everyone productive
- Three focused teammates outperform five scattered ones
- Never exceed 5 teammates without explicit justification

### DO
- **mode: "bypassPermissions"** for all agents (they block on permission prompts otherwise)
- Agents work on main repo directly -- no worktree isolation
- Each agent documents work in beads (claim before starting, close when done)
- Agent prompts must be exhaustive: exact file paths, what to change, acceptance criteria, which bead to close
- Coordinator verifies after agents complete (typecheck, file checks, bead status)
- Use `subagent_type: "general-purpose"` for any agent that needs to edit files

### DO NOT
- NEVER use `isolation: "worktree"` -- worktrees are temporary git copies cleaned on agent exit, all changes lost
- NEVER spawn agents without a specific task assignment
- NEVER assume agents completed successfully -- always verify
- NEVER exceed 5 teammates without explicit justification
- NEVER mark CC tasks complete without closing the corresponding beads issue

### Dual Task System (Beads + CC Tasks)
- Beads = primary, persistent tracker (survives compaction, git-backed)
- CC tasks (TaskCreate/TaskUpdate) = bridge for real-time team coordination
- CC task subjects MUST include beads ID: "[project-XXXX] Title"
- TeammateIdle hook verifies beads closed before agent goes idle
- TaskCompleted hook verifies beads closed before CC task completes

### Team Lifecycle
1. Create beads issues with `bd create` (detailed descriptions, dependencies)
2. TeamCreate (new team per phase)
3. TaskCreate for each beads issue (subject includes beads ID)
4. Agents: claim beads -> work -> close beads
5. Coordinator verifies (typecheck, file checks, bead status)
6. SendMessage shutdown_request to all agents
7. TeamDelete
8. git commit + push

## STEP 3: Verify Agent Teams Feature

Run a quick check to confirm agent teams are available:
- Check that `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is set in settings
- Verify `.claude/agents/` has at least the 3 agent definitions
- Verify CLAUDE.md has the agent teams section

Note: We do NOT spawn a test team here (that costs tokens and requires subscription). The full E2E test is in Prompt 8 (Verification).

## VERIFICATION

1. `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is "1" in `~/.claude/settings.json`
2. `.claude/agents/researcher.md` exists with proper frontmatter
3. `.claude/agents/implementer.md` exists with proper frontmatter
4. `.claude/agents/reviewer.md` exists with proper frontmatter
5. CLAUDE.md contains agent teams section with DO/DO NOT rules
6. CLAUDE.md contains dual task system instructions
7. TeammateIdle and TaskCompleted hooks are configured (from Prompt 4)

Display results:
=== Agent Teams Setup Complete ===
[PASS/FAIL] Agent teams enabled (env var set)
[PASS/FAIL] researcher.md agent definition
[PASS/FAIL] implementer.md agent definition
[PASS/FAIL] reviewer.md agent definition
[PASS/FAIL] CLAUDE.md agent teams section
[PASS/FAIL] Team lifecycle hooks (TeammateIdle, TaskCompleted)

Your Claude Code installation now supports multi-agent workflows.

=== CORE SETUP COMPLETE ===
Prompts 1-5 have configured:
  - Discovery & analysis (project detection)
  - Foundation (settings, permissions, CLAUDE.md)
  - Hooks & quality gates (6 lifecycle hooks)
  - Beads integration (persistent task tracking)
  - Agent teams (multi-agent coordination)

Optional next steps:
  - Prompt 6: MCP Servers & External Tools
  - Prompt 7: System & Performance Optimization
  - Prompt 8: Verification & Testing (full E2E check)
```

---

## Notes for Developers

### Running Order
Prompts have dependencies: **1 -> 2 -> 3 -> 4 -> 5**. Run them in order. Each prompt checks for prerequisites and warns if a prior prompt was skipped. Note: P3->P4 and P4->P5 are "soft" dependencies -- these prompts warn and continue if the prior was skipped. P1->P2->P3 are hard dependencies (later prompts need the config files created by earlier ones).

### Idempotency
Every prompt is safe to run multiple times. It checks what exists before creating, merges instead of replacing, and backs up before modifying.

### Self-Updating
Every prompt fetches the latest documentation before acting. If official docs have changed since these prompts were written, the online version takes precedence.

### Token Budget
Each prompt is designed to stay within 3,000-6,000 tokens, leaving room for Claude's response within context limits.

### Customization
These prompts detect your stack automatically. If detection fails or you want different behavior, edit the relevant section before pasting.
