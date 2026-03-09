---
name: setup-mcp
description: "Install and configure MCP (Model Context Protocol) servers and external developer tools. Adds Context7 (docs), GitHub (PRs), Playwright (browser), plus stack-specific servers (Supabase, Sentry, Stripe, etc.). Configures permissions and performance settings."
user-invocable: true
argument-hint: ""
---

# MCP Servers & External Tools (Prompt 6 of 8)

Configure MCP servers and external developer tools for this project.

## Self-Update Protocol

Before implementing anything:
1. WebFetch `https://code.claude.com/docs/en/mcp`
2. Optionally check `https://registry.modelcontextprotocol.io` for new servers
3. If any information below conflicts with online docs, USE THE ONLINE VERSION.

## Step 1: Detect Current State

1. `claude mcp list` -- existing servers
2. Read `.mcp.json` and `~/.claude/settings.json` for MCP config
3. Detect project stack from package.json, Cargo.toml, pyproject.toml, etc.
4. Check for API keys: `env | grep -iE '(GITHUB|SUPABASE|BRAVE|SENTRY|OPENAI).*(TOKEN|KEY)' | sed 's/=.*/=***/'`

Report findings before proceeding.

## Step 2: Install Essential MCP Servers

Install any that are missing:

### A. Context7 (Documentation Lookup -- HIGHEST VALUE)
```bash
claude mcp add --scope user --transport http context7 https://mcp.context7.com/mcp
```
Usage: Add "use context7" to any prompt.

### B. GitHub (Issues, PRs, Code Search)
```bash
claude mcp add --transport http github https://api.githubcopilot.com/mcp/
```

### C. Playwright (Browser Automation & Testing)
```bash
claude mcp add playwright --transport stdio -- npx -y @playwright/mcp@latest
```

## Step 3: Stack-Specific Servers

Install ONLY what the project uses (each adds ~600-800 tokens overhead). Keep to 5-6 max:

| Detected | Server | Command |
|----------|--------|---------|
| Supabase | Supabase | `claude mcp add --transport http supabase https://mcp.supabase.com/mcp` |
| PostgreSQL | PostgreSQL | `claude mcp add postgres --transport stdio -- npx -y @modelcontextprotocol/server-postgres "$DATABASE_URL"` |
| Sentry | Sentry | `claude mcp add --transport http sentry https://mcp.sentry.dev/mcp` |
| Vercel | Vercel | `claude mcp add --transport http vercel https://mcp.vercel.com/` |
| Stripe | Stripe | `claude mcp add --transport http stripe https://mcp.stripe.com` |
| Slack | Slack | `claude mcp add --transport http slack https://mcp.slack.com/mcp` |

## Step 4: Create .mcp.json

For team-shared config (no personal API keys):
```json
{
  "mcpServers": {
    "context7": { "type": "http", "url": "https://mcp.context7.com/mcp" },
    "playwright": { "command": "npx", "args": ["-y", "@playwright/mcp@latest"] }
  }
}
```

## Step 5: External Developer Tools

Offer to install if missing:
- **ccusage** (token tracking): `bunx ccusage@latest daily` or `bun install -g ccusage`
- **Claude Squad** (multi-session): `brew install claude-squad` or `go install github.com/smtg-ai/claude-squad@latest`
- **Graphite** (PR stacking): `brew install withgraphite/tap/graphite`

## Step 6: Configure Performance & Permissions

Add to settings:
```json
{
  "env": { "ENABLE_TOOL_SEARCH": "auto:5", "MCP_TIMEOUT": "10000", "MAX_MCP_OUTPUT_TOKENS": "25000" },
  "permissions": {
    "allow": ["mcp__context7__*", "mcp__playwright__*", "mcp__github__*"],
    "deny": ["mcp__*__delete_*", "mcp__*__drop_*"]
  }
}
```

## Verification

1. `claude mcp list` shows all installed servers
2. Context7 is configured
3. No API key errors
4. `.mcp.json` is valid JSON (if created)
5. Permissions configured for MCP tools

Display results. Next: `/setup-optimize` for performance tuning.
