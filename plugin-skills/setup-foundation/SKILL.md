---
name: setup-foundation
description: "Set up the three foundational configuration layers: user settings (~/.claude/settings.json), project settings (.claude/settings.json), CLAUDE.md, and .claudeignore. Adapts all permissions and patterns to the detected tech stack. Creates backups before modifying existing files."
user-invocable: true
argument-hint: ""
---

# Foundation Setup (Prompt 2 of 8)

Set up the three foundational configuration layers: user settings, project settings, and CLAUDE.md.

## Self-Update Protocol

Before implementing anything:
1. WebFetch `https://code.claude.com/docs/en/settings`
2. WebFetch `https://code.claude.com/docs/en/permissions`
3. WebFetch `https://code.claude.com/docs/en/claude-md`
4. If any information below conflicts with online docs, USE THE ONLINE VERSION.

## Step 0: Load Discovery

Read `/tmp/claude-setup-discovery.json` (from `/setup-discover`). If it does not exist, perform inline stack detection (check lock files, package.json, tsconfig.json, pyproject.toml, etc.).

## Step 1: User Settings (~/.claude/settings.json)

Read existing file first. MERGE -- never replace. Back up to `~/.claude/settings.json.backup` before changes.

Add/merge:
- `permissions.allow`: Read, Glob, Grep, `Bash(git status*)`, `Bash(git log *)`, `Bash(git diff *)`, `Bash(git branch *)`, `Bash(which *)`, `Bash(ls *)`, `Bash(pwd)`, `Bash(echo *)`, `Bash(wc *)`, `Bash(cat *)`, `Bash(head *)`, `Bash(tail *)`, `mcp__context7__*`
- `permissions.deny`: `Read(.env)`, `Read(.env.*)`, `Read(**/secrets/**)`, `Bash(rm -rf /)`, `Bash(rm -rf ~)`, `Bash(rm -rf .)`, `Bash(sudo rm *)`, `Bash(curl * | bash)`, `Bash(curl * | sh)`, `Bash(wget * | bash)`, `Bash(wget * | sh)`, `Bash(chmod 777 *)`, `Bash(eval *)`, `Bash(git checkout -- *)`, `Bash(git restore *)`, `Bash(npm publish*)`, `Bash(cargo publish*)`
- `env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`: "1"

## Step 2: Project Settings (.claude/settings.json)

Create `.claude/` directory if needed. Read existing settings, MERGE, back up first.

Adapt permissions to the detected stack:

| Stack | Allow |
|-------|-------|
| JS/TS (bun) | `Bash(bun install *)`, `Bash(bun run *)`, `Bash(bun test *)`, `Bash(bun add *)`, `Bash(bunx *)` |
| JS/TS (npm) | `Bash(npm install *)`, `Bash(npm run *)`, `Bash(npm test *)`, `Bash(npx *)` |
| JS/TS (pnpm) | `Bash(pnpm install *)`, `Bash(pnpm run *)`, `Bash(pnpm test *)`, `Bash(pnpx *)` |
| JS/TS (yarn) | `Bash(yarn install *)`, `Bash(yarn run *)`, `Bash(yarn test *)` |
| Python | `Bash(pip install *)`, `Bash(uv *)`, `Bash(python -m *)`, `Bash(pytest *)`, `Bash(ruff *)`, `Bash(mypy *)` |
| Rust | `Bash(cargo build *)`, `Bash(cargo run *)`, `Bash(cargo test *)`, `Bash(cargo clippy *)`, `Bash(cargo fmt *)` |
| Go | `Bash(go build *)`, `Bash(go run *)`, `Bash(go test *)`, `Bash(go vet *)`, `Bash(golangci-lint *)` |
| Ruby | `Bash(bundle *)`, `Bash(rails *)`, `Bash(rspec *)`, `Bash(rubocop *)`, `Bash(rake *)` |

Always include: `Bash(git add *)`, `Bash(git commit *)`, `Bash(git stash *)`, `Bash(git checkout *)`, `Bash(git switch *)`, `Bash(git merge *)`

Always deny: `Bash(git push --force*)`, `Bash(git push -f *)`, `Bash(git reset --hard*)`, `Bash(rm -rf *)`

If Docker detected: add `Bash(docker compose *)`, `Bash(docker logs *)`, `Bash(docker ps *)`

Set `"defaultMode": "acceptEdits"`.

## Step 3: .claudeignore

Create or extend (do not duplicate). Always include: `node_modules/`, `.pnpm/`, `vendor/`, `venv/`, `.venv/`, `__pycache__/`, `target/`, `.next/`, `dist/`, `build/`, `out/`, `.turbo/`, `coverage/`, `.nyc_output/`, `playwright-report/`, `test-results/`, `.DS_Store`, `*.min.js`, `*.min.css`, `*.bundle.js`, `*.map`

Add stack-specific: lock files for JS/TS, `*.egg-info/` for Python, `target/` for Rust, `vendor/` for Go.

## Step 4: CLAUDE.md

If CLAUDE.md does NOT exist, create a scaffold with: Overview, Stack info, Quick Start (detected commands), Architecture (directory listing), Core Patterns, Quality Gates, NEVER section, ALWAYS section, Self-Updating Rule.

If CLAUDE.md ALREADY exists: read it, check which sections are missing, APPEND only the missing ones. Never modify or remove existing content.

## Step 5: Directory Structure

Ensure these exist: `.claude/`, `.claude/hooks/`, `.claude/skills/`, `.claude/agents/`

## Verification

Check all 6 items:
1. `~/.claude/settings.json` -- valid JSON, has allow/deny permissions
2. `.claude/settings.json` -- valid JSON, stack-specific permissions, deny rules
3. `CLAUDE.md` -- exists, >= 5 sections
4. `.claudeignore` -- exists, >= 10 patterns
5. `.claude/hooks/` directory exists
6. No config destroyed (backups exist for modified files)

Display PASS/FAIL for each. Next: Run `/setup-hooks` to install lifecycle hooks.
