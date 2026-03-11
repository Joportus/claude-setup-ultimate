---
name: setup-discover
description: "Analyze a repository to detect its tech stack, existing Claude Code configuration, quality tools, infrastructure, and performance baseline. Produces a structured JSON report and human-readable summary. Read-only -- does not modify any files."
user-invocable: true
argument-hint: ""
---

# Discovery & Analysis (Prompt 1 of 8)

You are running the discovery phase of Claude Code setup. Analyze the current repository and produce a structured detection report. Do NOT modify any files -- this is read-only analysis.

## Self-Update Protocol

Before implementing anything, fetch the latest docs to ensure current knowledge:
1. WebFetch `https://code.claude.com/docs/llms.txt`
2. WebFetch `https://code.claude.com/docs/en/best-practices`
3. If any information below conflicts with what you find online, USE THE ONLINE VERSION.
4. Note discrepancies in a "## Updates Found" section of your output.

## Detection Checklist

### 1. Package Manager
Check for lock files (first match wins):
- `bun.lockb` or `bun.lock` -> bun
- `pnpm-lock.yaml` -> pnpm
- `yarn.lock` -> yarn
- `package-lock.json` -> npm
- `Cargo.lock` -> cargo
- `go.sum` -> go
- `Pipfile.lock` / `poetry.lock` / `uv.lock` -> pip/poetry/uv
- `Gemfile.lock` -> bundler
- `composer.lock` -> composer

### 2. Framework & Language
- Read `package.json` (if exists): check dependencies for frameworks (next, react, vue, svelte, express, fastify, etc.)
- Check for `Cargo.toml`, `go.mod`, `pyproject.toml`/`requirements.txt`, `Gemfile`, `pom.xml`, `build.gradle`
- Scan immediate subdirectories for nested config files (multi-component projects)
- Count file extensions to detect ALL languages: `.ts`, `.tsx`, `.py`, `.rs`, `.go`, `.rb`, `.java`, `.kt`, `.scala`
- If multiple languages have >10 files each, report as multi-language
- Check for `tsconfig.json`, `.python-version`, `rust-toolchain.toml`

### 3. Existing Claude Code Configuration
- `CLAUDE.md` -- exists? line count? has NEVER/ALWAYS sections?
- `.claude/` directory -- has `settings.json`? `hooks/`? `agents/`? `skills/`?
- `~/.claude/settings.json` -- has permissions? hooks? env vars?
- `.claudeignore` -- exists? line count?
- `.mcp.json` -- exists? which servers?

### 4. Quality Tools
Detect by checking config files and package.json:
- Linters: ESLint, Biome, Ruff, clippy, golangci-lint, RuboCop
- Formatters: Prettier, Biome, Black, rustfmt, gofmt
- Type checkers: TypeScript, mypy, pyright
- Test runners: Jest, Vitest, Bun test, pytest, cargo test, go test, RSpec
- Other: Semgrep, Knip, Husky, lint-staged

### 5. Infrastructure
- Git: main branch name, existing hooks in `.git/hooks/`
- CI/CD: `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`, `.circleci/`
- Docker: `Dockerfile`, `docker-compose.yml`
- Monorepo: `pnpm-workspace.yaml`, `lerna.json`, `nx.json`, `turbo.json`

### 6. External Services
Check `.env.example` or `.env.local.example` for integrations (Auth, DB, AI, Payments, Monitoring)

### 7. Performance Baseline
- Shell startup: `time zsh -i -c exit 2>&1`
- Git fsmonitor: `git config core.fsmonitor`
- File descriptor limit: `ulimit -n`

## Output

Save to `/tmp/claude-setup-discovery.json` with this structure:
```json
{
  "timestamp": "<ISO 8601>",
  "project": { "name": "", "path": "", "language": "", "framework": "", "packageManager": "", "monorepo": false },
  "existingConfig": { "claudeMd": {}, "claudeDir": {}, "userSettings": {}, "mcp": {}, "claudeignore": {} },
  "qualityTools": { "linter": null, "formatter": null, "typeChecker": null, "testRunner": null },
  "ci": { "platform": null, "workflows": [] },
  "docker": { "exists": false, "compose": false },
  "services": [],
  "performance": { "shellStartupMs": 0, "gitFsmonitor": false, "ulimitN": 0 },
  "recommendations": []
}
```

Then display a human-readable summary with project info, existing config status, quality tools, performance baseline, and at least 3 recommendations.

## Verification

- `/tmp/claude-setup-discovery.json` is valid JSON
- At least 3 recommendations listed
- Shell startup time was measured
- Detected tools verified by running 2-3 tool commands

Next step: Run `/setup-foundation` to configure settings, permissions, and CLAUDE.md.
