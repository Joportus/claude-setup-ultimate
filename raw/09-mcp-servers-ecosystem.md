# MCP Servers Ecosystem - Comprehensive Catalog

> Research completed: March 2026
> Sources: Anthropic MCP Registry API, modelcontextprotocol GitHub org, awesome-mcp-servers, official docs, community guides

---

## Table of Contents

1. [What is MCP](#what-is-mcp)
2. [How MCP Works with Claude Code](#how-mcp-works-with-claude-code)
3. [Configuration Reference](#configuration-reference)
4. [Transport Types](#transport-types)
5. [Permission Patterns](#permission-patterns)
6. [Performance & Context Management](#performance--context-management)
7. [Server Catalog by Category](#server-catalog-by-category)
   - [Official Reference Servers](#1-official-reference-servers)
   - [Development & Git](#2-development--git)
   - [Databases](#3-databases)
   - [Browser & Web](#4-browser--web-automation)
   - [Search & Research](#5-search--research)
   - [Documentation](#6-documentation--knowledge)
   - [Project Management](#7-project-management)
   - [Communication](#8-communication--collaboration)
   - [Cloud & Infrastructure](#9-cloud--infrastructure)
   - [Design & Frontend](#10-design--frontend)
   - [Payments & Finance](#11-payments--finance)
   - [CRM & Sales](#12-crm--sales)
   - [Analytics & Observability](#13-analytics--observability)
   - [Automation & Workflows](#14-automation--workflows)
   - [File & System Operations](#15-file--system-operations)
   - [AI & ML](#16-ai--ml)
   - [Code Execution & Sandboxing](#17-code-execution--sandboxing)
   - [Content & CMS](#18-content--cms)
   - [Healthcare & Science](#19-healthcare--science)
   - [Aggregators & Meta-Servers](#20-aggregators--meta-servers)
   - [Specialized & Other](#21-specialized--other)
8. [Anthropic Official MCP Registry](#anthropic-official-mcp-registry)
9. [MCP Discovery Platforms](#mcp-discovery-platforms)
10. [Best Practices](#best-practices)
11. [Recommended Starter Setup](#recommended-starter-setup)

---

## What is MCP

**Model Context Protocol (MCP)** is an open-source standard (hosted by The Linux Foundation) for connecting AI applications to external tools, data sources, and workflows. Think of it as "USB-C for AI" -- a universal protocol so any AI client can connect to any MCP server.

**Key concepts:**
- **MCP Client**: The AI application (Claude Code, Claude Desktop, Cursor, VS Code, etc.)
- **MCP Server**: A process that exposes tools, resources, and/or prompts
- **Tools**: Functions the AI can call (e.g., `create_issue`, `run_query`)
- **Resources**: Data the AI can read (e.g., files, database schemas) -- referenced via `@server:protocol://path`
- **Prompts**: Pre-defined prompt templates exposed as slash commands (`/mcp__server__prompt`)

**Official site:** https://modelcontextprotocol.io
**GitHub org:** https://github.com/modelcontextprotocol
**Official registry:** https://registry.modelcontextprotocol.io
**Anthropic registry API:** https://api.anthropic.com/mcp-registry/v0/servers?version=latest

---

## How MCP Works with Claude Code

### Adding Servers

```bash
# HTTP transport (recommended for remote servers)
claude mcp add --transport http <name> <url>

# SSE transport (deprecated, use HTTP where possible)
claude mcp add --transport sse <name> <url>

# Stdio transport (local processes)
claude mcp add --transport stdio <name> -- <command> [args...]

# With environment variables
claude mcp add --transport stdio --env API_KEY=xxx myserver -- npx -y some-package

# With auth headers
claude mcp add --transport http --header "Authorization: Bearer token" myserver https://api.example.com/mcp

# Import from Claude Desktop
claude mcp add-from-claude-desktop

# Add from JSON config
claude mcp add-json myserver '{"type":"http","url":"https://example.com/mcp"}'
```

**Important:** All options (`--transport`, `--env`, `--scope`, `--header`) must come **before** the server name. Use `--` to separate server name from command/args.

### Managing Servers

```bash
claude mcp list              # List all configured servers
claude mcp get <name>        # Get details for a specific server
claude mcp remove <name>     # Remove a server
/mcp                         # Within Claude Code: check status, authenticate
```

### OAuth Authentication

Many remote servers require OAuth. After adding:
1. Run `/mcp` within Claude Code
2. Follow browser login flow
3. Tokens stored securely and refreshed automatically

For servers requiring pre-configured OAuth credentials:
```bash
claude mcp add --transport http \
  --client-id your-client-id --client-secret --callback-port 8080 \
  my-server https://mcp.example.com/mcp
```

### Claude Code as MCP Server

Claude Code can itself be an MCP server:
```bash
claude mcp serve  # Start as stdio MCP server
```

---

## Configuration Reference

### Scope Levels

| Scope | Storage | Visibility | Use Case |
|-------|---------|------------|----------|
| `local` (default) | `~/.claude.json` (project path) | You only, this project | Personal dev servers, experiments |
| `project` | `.mcp.json` at project root | Everyone (version controlled) | Team-shared servers |
| `user` | `~/.claude.json` (global) | You only, all projects | Personal utilities across projects |

```bash
# Specify scope
claude mcp add --scope local myserver ...   # Default
claude mcp add --scope project myserver ... # Creates .mcp.json
claude mcp add --scope user myserver ...    # Global for you
```

### .mcp.json (Project-Level Config)

```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/"
    },
    "supabase": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@supabase/mcp-server-supabase"],
      "env": {
        "SUPABASE_ACCESS_TOKEN": "${SUPABASE_ACCESS_TOKEN}"
      }
    },
    "context7": {
      "type": "http",
      "url": "https://mcp.context7.com/mcp"
    }
  }
}
```

### Environment Variable Expansion in .mcp.json

Supported syntax:
- `${VAR}` -- expands to value of `VAR`
- `${VAR:-default}` -- expands to `VAR` if set, otherwise `default`

Works in: `command`, `args`, `env`, `url`, `headers`

### Managed MCP (Enterprise)

For organizations needing centralized control:

**Option 1: Exclusive control** -- Deploy `managed-mcp.json`:
- macOS: `/Library/Application Support/ClaudeCode/managed-mcp.json`
- Linux/WSL: `/etc/claude-code/managed-mcp.json`
- Windows: `C:\Program Files\ClaudeCode\managed-mcp.json`

**Option 2: Policy-based** -- Use `allowedMcpServers` / `deniedMcpServers` in managed settings:
```json
{
  "allowedMcpServers": [
    { "serverName": "github" },
    { "serverUrl": "https://mcp.company.com/*" },
    { "serverCommand": ["npx", "-y", "@approved/package"] }
  ],
  "deniedMcpServers": [
    { "serverName": "dangerous-server" }
  ]
}
```

---

## Transport Types

| Transport | Protocol | Use Case | Status |
|-----------|----------|----------|--------|
| **HTTP (Streamable HTTP)** | HTTP POST/GET | Remote cloud services | Recommended |
| **SSE (Server-Sent Events)** | HTTP + SSE | Remote services (legacy) | Deprecated |
| **Stdio** | stdin/stdout | Local processes | Active |

- **HTTP** is the preferred transport for remote servers. Supports OAuth, headers, and streaming.
- **SSE** is deprecated but still supported. Some older servers only offer SSE.
- **Stdio** runs a local process. Best for filesystem access, custom scripts, local databases.

### Dynamic Tool Updates

Claude Code supports `list_changed` notifications -- servers can dynamically update available tools without reconnection.

---

## Permission Patterns

MCP tools follow the naming convention: `mcp__<server-name>__<tool-name>`

Examples:
- `mcp__github__create_issue`
- `mcp__playwright__browser_navigate`
- `mcp__supabase__run_query`

You can allow/deny specific MCP tools in settings:
```json
{
  "permissions": {
    "allow": ["mcp__github__*"],
    "deny": ["mcp__dangerous__delete_all"]
  }
}
```

Disable MCP Tool Search specifically:
```json
{
  "permissions": {
    "deny": ["MCPSearch"]
  }
}
```

---

## Performance & Context Management

### The Problem

Each MCP tool definition consumes ~600-800 tokens. An average server has 20-30 tools (~20,000 tokens). With 10 servers, you can consume 200,000+ tokens before doing any work.

### MCP Tool Search (Auto-Enabled)

Claude Code automatically enables Tool Search when MCP tool definitions exceed 10% of context. This dynamically loads tools on-demand instead of preloading all.

**Result:** ~85% reduction in context usage (72,000 tokens -> 8,700 tokens in benchmarks).

**Requirements:** Sonnet 4+ or Opus 4+. Haiku does not support tool search.

**Configuration:**
```bash
# Default: auto (activates at 10% threshold)
ENABLE_TOOL_SEARCH=auto claude

# Custom threshold (5%)
ENABLE_TOOL_SEARCH=auto:5 claude

# Always on
ENABLE_TOOL_SEARCH=true claude

# Disabled
ENABLE_TOOL_SEARCH=false claude
```

### Output Limits

```bash
# Default warning at 10,000 tokens, max at 25,000 tokens
MAX_MCP_OUTPUT_TOKENS=50000 claude  # Increase for large outputs
```

### Startup Timeout

```bash
MCP_TIMEOUT=10000 claude  # 10-second timeout for MCP server startup
```

### Best Practices for Performance

1. **Keep 5-6 servers active per project** -- disable unused ones
2. **Use `/mcp` to enable/disable** servers dynamically per session
3. **Use `/context` to monitor** context consumption per server
4. **Use MCP Server Selector tool** (github.com/henkisdabro/Claude-Code-MCP-Server-Selector) for TUI management
5. **Configure 20-30 servers globally** but keep only relevant ones enabled per project
6. **Write clear server instructions** so Tool Search knows when to load your tools
7. **Project-scope `.mcp.json`** keeps only project-relevant servers
8. **Use `disabledMcpServers` in project settings** to disable unused global servers

---

## Server Catalog by Category

### 1. Official Reference Servers

These are maintained by the MCP Steering Group. They demonstrate core MCP features.

| Server | Install | Description |
|--------|---------|-------------|
| **Everything** | `npx -y @modelcontextprotocol/server-everything` | Reference/test server with prompts, resources, and tools |
| **Fetch** | `npx -y @modelcontextprotocol/server-fetch` | Web content fetching and conversion for efficient LLM usage |
| **Filesystem** | `npx -y @modelcontextprotocol/server-filesystem /path/to/dir` | Secure file operations with configurable access controls |
| **Git** | `uvx mcp-server-git` or `pip install mcp-server-git` | Tools to read, search, and manipulate Git repositories |
| **Memory** | `npx -y @modelcontextprotocol/server-memory` | Knowledge graph-based persistent memory system |
| **Sequential Thinking** | `npx -y @modelcontextprotocol/server-sequentialthinking` | Dynamic and reflective problem-solving through thought sequences |
| **Time** | `npx -y @modelcontextprotocol/server-time` | Time and timezone conversion capabilities |

**Archived Reference Servers** (in `servers-archived` repo, no longer maintained):
AWS KB Retrieval, Brave Search, EverArt, GitHub, GitLab, Google Drive, Google Maps, PostgreSQL, Puppeteer, Redis, Sentry, Slack, SQLite

**Configuration example:**
```json
{
  "mcpServers": {
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/Users/me/projects"]
    }
  }
}
```

---

### 2. Development & Git

| Server | Type | Install / URL | Description |
|--------|------|---------------|-------------|
| **GitHub** (Official) | HTTP | `claude mcp add --transport http github https://api.githubcopilot.com/mcp/` | Issues, PRs, commits, branches, CI/CD. OAuth. |
| **GitLab** (Official) | HTTP | Remote MCP available | Merge requests, CI/CD, project management |
| **Git** (Reference) | Stdio | `uvx mcp-server-git` | Read, search, manipulate local Git repos |
| **Vercel** | HTTP | `claude mcp add --transport http vercel https://mcp.vercel.com/` | Analyze, debug, manage projects & deployments |
| **Netlify** | HTTP | `claude mcp add --transport http netlify https://netlify-mcp.netlify.app/mcp` | Create, deploy, manage websites |
| **Docker** | Stdio | Community servers available | Build, run, inspect containers |
| **JetBrains** | Stdio | IDE-integrated | IDE integration server |
| **GraphOS (Apollo)** | HTTP | `claude mcp add --transport http apollo https://mcp.apollographql.com` | Search Apollo docs, specs, best practices |
| **Clerk** | HTTP | `claude mcp add --transport http clerk https://mcp.clerk.com/mcp` | Authentication, organizations, billing |
| **Stytch** | HTTP | URL: `https://mcp.stytch.dev/mcp` | Auth project management |

**GitHub config example:**
```bash
claude mcp add --transport http github https://api.githubcopilot.com/mcp/
# Then authenticate: /mcp -> select GitHub -> browser flow
```

---

### 3. Databases

| Server | Type | Install / URL | Description |
|--------|------|---------------|-------------|
| **Supabase** (Official) | HTTP/Stdio | `claude mcp add --transport http supabase https://mcp.supabase.com/mcp` or `npx -y @supabase/mcp-server-supabase` | 20+ tools: migrations, SQL, TypeScript types, auth, storage |
| **PostgreSQL** | Stdio | `npx -y @modelcontextprotocol/server-postgres "postgresql://..."` | Natural language SQL queries, schema analysis |
| **MongoDB** | Stdio | `npx -y mongodb-mcp-server` | Document queries, schema exploration |
| **SQLite** | Stdio | `npx -y @modelcontextprotocol/server-sqlite` | SQLite database management |
| **Redis** | Stdio | `npx -y @modelcontextprotocol/server-redis` | Redis data management and search |
| **MySQL** | Stdio | Community servers | MySQL operations |
| **ClickHouse** (Official) | HTTP | Remote available | High-performance analytics, read-only |
| **Snowflake** | HTTP | Remote (requires setup URL) | Structured + unstructured data retrieval |
| **BigQuery** | HTTP | `claude mcp add --transport http bigquery https://bigquery.googleapis.com/mcp` | Google Cloud analytical insights |
| **Databricks** | HTTP | Remote (requires setup URL) | Unity Catalog, Mosaic AI |
| **PlanetScale** | HTTP | `claude mcp add --transport http planetscale https://mcp.pscale.dev/mcp/planetscale` | Postgres and MySQL DB access |
| **MotherDuck** | HTTP | URL: `https://api.motherduck.com/mcp` | Natural language data analysis |
| **DBHub** (@bytebase) | Stdio | `npx -y @bytebase/dbhub --dsn "postgresql://..."` | Multi-database connector |
| **Anyquery** | Stdio | Community | Multi-database query engine (40+ platforms) |

**PostgreSQL config example:**
```json
{
  "mcpServers": {
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres", "postgresql://user:pass@localhost:5432/mydb"]
    }
  }
}
```

**Supabase config example:**
```bash
# HTTP (recommended - auto OAuth)
claude mcp add --transport http supabase https://mcp.supabase.com/mcp

# Stdio (with access token)
claude mcp add --transport stdio -e SUPABASE_ACCESS_TOKEN=your_token supabase -- npx -y @supabase/mcp-server-supabase@latest
```

---

### 4. Browser & Web Automation

| Server | Type | Install / URL | Description |
|--------|------|---------------|-------------|
| **Playwright** (Microsoft, Official) | Stdio | `npx -y @playwright/mcp@latest` | Structured accessibility snapshots, browser automation |
| **Puppeteer** | Stdio | `npx -y @modelcontextprotocol/server-puppeteer` | Chrome automation (archived reference) |
| **Browserbase** | Stdio | `npx -y @browserbasehq/mcp-server-browserbase` | Cloud-based browser automation |
| **BrowserMCP** | Stdio | `npx -y @anthropic/browsermcp` | Chrome automation for local systems |
| **Firecrawl** | Stdio | `npx -y firecrawl-mcp` | Web scraping with JS rendering, batch processing |
| **Jina Reader** | Stdio | Community | Convert URLs to clean markdown |

**Playwright config example:**
```bash
claude mcp add playwright --transport stdio -- npx -y @playwright/mcp@latest
```

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest"]
    }
  }
}
```

---

### 5. Search & Research

| Server | Type | Install / URL | Description |
|--------|------|---------------|-------------|
| **Brave Search** | Stdio | `npx -y @modelcontextprotocol/server-brave-search` | Privacy-first web search. Env: `BRAVE_API_KEY` |
| **Tavily** | Stdio | `npx -y tavily-mcp@latest` | Real-time search, content extraction. 1,000 free credits/month |
| **Perplexity** (Official) | HTTP | Remote available | Fast search with citation-rich results, recency filtering |
| **Exa** (Official) | Stdio | `npx -y exa-mcp-server` | Web search, GitHub code retrieval, company research |
| **GPT Researcher** | Stdio | Community | Autonomous deep-research agent, citation-backed reports |
| **MCP Omnisearch** | Stdio | `npx -y mcp-omnisearch` | Unified: Tavily + Brave + Perplexity + Exa + Firecrawl + Kagi |
| **Scholar Gateway** | HTTP | URL: `https://connector.scholargateway.ai/mcp` | Scholarly research and citations |
| **Consensus** | HTTP | URL: `https://mcp.consensus.app/mcp` | Scientific research exploration |
| **PubMed** | HTTP | URL: `https://pubmed.mcp.claude.com/mcp` | Biomedical literature search |

**Brave Search config example:**
```json
{
  "mcpServers": {
    "brave-search": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-brave-search"],
      "env": {
        "BRAVE_API_KEY": "${BRAVE_API_KEY}"
      }
    }
  }
}
```

---

### 6. Documentation & Knowledge

| Server | Type | Install / URL | Description |
|--------|------|---------------|-------------|
| **Context7** | HTTP/Stdio | `claude mcp add --transport http context7 https://mcp.context7.com/mcp` or `npx -y @upstash/context7-mcp` | Up-to-date, version-specific docs for any library. Add "use context7" to prompts. |
| **Microsoft Learn** | HTTP | URL: `https://learn.microsoft.com/api/mcp` | Trusted Microsoft documentation |
| **Anthropic Docs** | HTTP | Available via registry | Claude/MCP documentation |
| **Fetch** (Reference) | Stdio | `npx -y @modelcontextprotocol/server-fetch` | Raw web content fetching |
| **Memory** (Reference) | Stdio | `npx -y @modelcontextprotocol/server-memory` | Knowledge graph-based persistent memory |

**Context7 config example:**
```bash
# HTTP (recommended - no API key needed for basic use)
claude mcp add --transport http context7 https://mcp.context7.com/mcp

# Stdio with API key for higher rate limits
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp --api-key YOUR_KEY
```

Usage: Add "use context7" to your prompts, e.g., "How do I use React Server Components? use context7"

---

### 7. Project Management

| Server | Type | Install / URL | Description |
|--------|------|---------------|-------------|
| **Linear** | HTTP | `claude mcp add --transport http linear https://mcp.linear.app/mcp` | Issues, projects, team workflows. OAuth. |
| **Atlassian (Jira/Confluence)** | HTTP | `claude mcp add --transport http atlassian https://mcp.atlassian.com/v1/mcp` | Jira issues, Confluence pages, Compass |
| **Asana** | HTTP | `claude mcp add --transport http asana https://mcp.asana.com/v2/mcp` | Tasks, projects, goals coordination |
| **Notion** | HTTP | `claude mcp add --transport http notion https://mcp.notion.com/mcp` | Pages, databases, documents. OAuth. |
| **ClickUp** | HTTP | `claude mcp add --transport http clickup https://mcp.clickup.com/mcp` | Project management & collaboration |
| **monday.com** | HTTP | `claude mcp add --transport http monday https://mcp.monday.com/mcp` | Projects, boards, workflows |
| **Smartsheet** | HTTP | URL: `https://mcp.smartsheet.com` | Data analysis and management |

---

### 8. Communication & Collaboration

| Server | Type | Install / URL | Description |
|--------|------|---------------|-------------|
| **Slack** (Official) | HTTP | `claude mcp add --transport http slack https://mcp.slack.com/mcp` | Messages, canvases, workspace data. OAuth. |
| **Discord** | Stdio | Community servers | Message sending, channel reading |
| **Gmail** | Stdio | Community / Google | Email management |
| **Intercom** | HTTP | URL: `https://mcp.intercom.com/mcp` | Customer insights and data |
| **Granola** | HTTP | URL: `https://mcp.granola.ai/mcp` | AI meeting notepad |
| **Fireflies** | HTTP | URL: `https://api.fireflies.ai/mcp` | Meeting transcript analysis |
| **Fellow.ai** | HTTP | URL: `https://fellow.app/mcp` | Meeting insights |
| **Circleback** | HTTP | URL: `https://app.circleback.ai/api/mcp` | Meeting search and access |
| **Jam** | HTTP | URL: `https://mcp.jam.dev/mcp` | Screen recording and bug context |

**Slack config example:**
```bash
# HTTP (recommended)
claude mcp add --transport http slack https://mcp.slack.com/mcp

# Stdio (legacy, needs bot token)
claude mcp add --transport stdio slack -- npx -y @modelcontextprotocol/server-slack
# Requires: SLACK_BOT_TOKEN, SLACK_TEAM_ID
```

---

### 9. Cloud & Infrastructure

| Server | Type | Install / URL | Description |
|--------|------|---------------|-------------|
| **AWS** (Official) | Various | Multiple servers at github.com/awslabs/mcp | EC2, S3, IAM, CloudWatch, CDK, CloudFormation, Bedrock |
| **Azure** (Official, Microsoft) | HTTP | Remote available | 40+ Azure services, Entra ID auth |
| **Cloudflare** (Official) | HTTP | URL: `https://bindings.mcp.cloudflare.com/mcp` | Workers, KV, R2, D1, DNS, security |
| **Google Compute Engine** | HTTP | URL: `https://compute.googleapis.com/mcp` | GCE management |
| **Terraform** (HashiCorp) | Stdio/Docker | `npx -y @hashicorp/terraform-mcp-server` | IaC development, registry docs |
| **Kubernetes** | Stdio | `npx -y @flux159/mcp-server-kubernetes` | Pod, deployment, service CRUD |
| **Docker** | Stdio | Community servers | Container management |
| **AWS Marketplace** | HTTP | URL: `https://marketplace-mcp.us-east-1.api.aws/mcp` | Discover, evaluate cloud solutions |

---

### 10. Design & Frontend

| Server | Type | Install / URL | Description |
|--------|------|---------------|-------------|
| **Figma** (Official) | HTTP | `claude mcp add --transport http figma https://mcp.figma.com/mcp` | Dev Mode: layer hierarchy, auto-layout, variants, tokens |
| **Canva** | HTTP | URL: `https://mcp.canva.com/mcp` | Search, create, autofill, export designs |
| **Excalidraw** | HTTP | URL: `https://mcp.excalidraw.com/mcp` | Interactive hand-drawn diagrams |
| **Mermaid Chart** | HTTP | URL: `https://chatgpt.mermaid.ai/anthropic/mcp` | Validate syntax, render SVG diagrams |
| **Magic UI** | Stdio | Community | React + Tailwind component library |
| **Magic Patterns** | HTTP | URL: `https://mcp.magicpatterns.com/mcp` | Discuss and iterate on designs |
| **Miro** | HTTP | URL: `https://mcp.miro.com/` | Board creation and content access |
| **BioRender** | HTTP | URL: `https://mcp.services.biorender.com/mcp` | Scientific templates and icons |

---

### 11. Payments & Finance

| Server | Type | Install / URL | Description |
|--------|------|---------------|-------------|
| **Stripe** (Official) | HTTP | `claude mcp add --transport http stripe https://mcp.stripe.com` | Payments, subscriptions, invoices |
| **PayPal** | HTTP | URL: `https://mcp.paypal.com/mcp` | Payment platform access |
| **Square** | HTTP | URL: `https://mcp.squareup.com/sse` | Transactions, merchant, payment data |
| **Ramp** | HTTP | URL: `https://ramp-mcp-remote.ramp.com/mcp` | Financial data analysis |
| **Mercury** | HTTP | URL: `https://mcp.mercury.com/mcp` | Financial search and analysis |
| **Crypto.com** | HTTP | URL: `https://mcp.crypto.com/market-data/mcp` | Real-time crypto prices, orders, charts |
| **Plaid** | HTTP | URL: `https://api.dashboard.plaid.com/mcp/sse` | Integration monitoring and debugging |
| **S&P Global** | HTTP | URL: `https://kfinance.kensho.com/integrations/mcp` | Financial datasets |
| **Morningstar** | HTTP | URL: `https://mcp.morningstar.com/mcp` | Investment and market insights |
| **FactSet** | HTTP | URL: `https://mcp.factset.com/content/v1` | Institutional financial data |
| **Moody's** | HTTP | URL: `https://api.moodys.com/genai-ready-data/m1/mcp` | Risk insights and analytics |
| **Daloopa** | HTTP | URL: `https://mcp.daloopa.com/server/mcp` | Financial KPIs with hyperlinks |
| **PitchBook** | HTTP | URL: `https://premium.mcp.pitchbook.com/mcp` | VC/PE data |

---

### 12. CRM & Sales

| Server | Type | Install / URL | Description |
|--------|------|---------------|-------------|
| **HubSpot** | HTTP | URL: `https://mcp.hubspot.com/anthropic` | CRM data and personalized insights |
| **Attio** | HTTP | URL: `https://mcp.attio.com/mcp` | CRM search, manage, update |
| **Clay** | HTTP | URL: `https://api.clay.com/v3/mcp` | Prospect research, outreach |
| **Apollo.io** | HTTP | URL: `https://mcp.apollo.io/mcp` | Lead discovery and meetings |
| **ZoomInfo** | HTTP | URL: `https://mcp.zoominfo.com/mcp` | Contact/account enrichment |
| **Crossbeam** | HTTP | URL: `https://mcp.crossbeam.com` | Partner ecosystem data |
| **Close** | HTTP | URL: `https://mcp.close.com/mcp` | Sales CRM access |
| **Clarify** | HTTP | URL: `https://api.clarify.ai/mcp` | CRM query and records |
| **Day AI** | HTTP | URL: `https://day.ai/api/mcp` | CRMx prospect/customer data |
| **Salesforce** | Various | Community + official | CRM platform |

---

### 13. Analytics & Observability

| Server | Type | Install / URL | Description |
|--------|------|---------------|-------------|
| **Sentry** | HTTP | `claude mcp add --transport http sentry https://mcp.sentry.dev/mcp` | Error search, query, debugging |
| **PostHog** | HTTP | URL: `https://mcp.posthog.com/mcp` | Query, analyze product insights |
| **Amplitude** | HTTP | URL: `https://mcp.amplitude.com/mcp` | Product analytics data |
| **Honeycomb** | HTTP | URL: `https://mcp.honeycomb.io/mcp` | Observability data and SLOs |
| **Datadog** | Stdio | Community: `mcp-server-datadog` | Query Datadog metrics |
| **Similarweb** | HTTP | URL: `https://mcp.similarweb.com` | Web, mobile, market data |
| **Pendo** | HTTP | Remote (requires setup) | Product and user insights |
| **Ahrefs** | HTTP | URL: `https://api.ahrefs.com/mcp/mcp` | SEO and AI search analytics |

---

### 14. Automation & Workflows

| Server | Type | Install / URL | Description |
|--------|------|---------------|-------------|
| **Zapier** | HTTP | Remote (requires setup) | Automate across thousands of apps |
| **n8n** | HTTP | Remote (requires setup) | Access and run n8n workflows |
| **Make** | HTTP | URL: `https://mcp.make.com` | Run Make scenarios, manage account |
| **Workato** | HTTP | Remote (requires setup) | Workflow automation, business app connection |

---

### 15. File & System Operations

| Server | Type | Install / URL | Description |
|--------|------|---------------|-------------|
| **Filesystem** (Reference) | Stdio | `npx -y @modelcontextprotocol/server-filesystem /path` | Secure file operations, configurable directories |
| **Desktop Commander** | Stdio | `npx -y @anthropic/desktop-commander` | Terminal, process management, ripgrep search, app launching |
| **Google Drive** | Stdio | Community / archived | Search, read, categorize files |
| **Box** | HTTP | URL: `https://mcp.box.com` | Content search and insights |
| **Egnyte** | HTTP | URL: `https://mcp-server.egnyte.com/mcp` | Secure content access |
| **Cloudinary** | HTTP | URL: `https://asset-management.mcp.cloudinary.com/sse` | Image/video management |

---

### 16. AI & ML

| Server | Type | Install / URL | Description |
|--------|------|---------------|-------------|
| **Hugging Face** | HTTP | URL: `https://huggingface.co/mcp?login&gradio=none` | Hub access, Gradio apps |
| **Ollama Bridge** | Stdio | Community | Local model integration |
| **OpenAI Bridge** | Stdio | Community | Multi-model access |
| **Sequential Thinking** (Reference) | Stdio | `npx -y @modelcontextprotocol/server-sequentialthinking` | Structured problem-solving |

---

### 17. Code Execution & Sandboxing

| Server | Type | Install / URL | Description |
|--------|------|---------------|-------------|
| **E2B** | Stdio | Community | Secure cloud sandbox: Python, JS, shell. CSV analysis, chart gen |
| **Replit** | Stdio | Community | Cloud code execution |
| **Code Runner** | Stdio | Various community servers | Local code execution |

---

### 18. Content & CMS

| Server | Type | Install / URL | Description |
|--------|------|---------------|-------------|
| **Webflow** | HTTP | URL: `https://mcp.webflow.com/mcp` | CMS, pages, assets, sites |
| **WordPress.com** | HTTP | URL: `https://public-api.wordpress.com/wpcom/v2/mcp/v1` | WordPress site management |
| **Wix** | HTTP | URL: `https://mcp.wix.com/mcp` | Site and app management |
| **Sanity** | HTTP | URL: `https://mcp.sanity.io` | Structured content management |
| **Airtable** | HTTP | URL: `https://mcp.airtable.com/mcp` | Structured data access |
| **Gamma** | HTTP | URL: `https://mcp.gamma.app/mcp` | Presentations, docs, sites |
| **Lumin** | HTTP | URL: `https://mcp.luminpdf.com/mcp` | Documents, signatures, Markdown->PDF |

---

### 19. Healthcare & Science

| Server | Type | Install / URL | Description |
|--------|------|---------------|-------------|
| **PubMed** | HTTP | URL: `https://pubmed.mcp.claude.com/mcp` | Biomedical literature search |
| **Clinical Trials** | HTTP | URL: `https://mcp.deepsense.ai/clinical_trials/mcp` | ClinicalTrials.gov data |
| **bioRxiv/medRxiv** | HTTP | URL: `https://mcp.deepsense.ai/biorxiv/mcp` | Preprint data access |
| **ChEMBL** | HTTP | URL: `https://mcp.deepsense.ai/chembl/mcp` | Chemical database |
| **ICD-10 Codes** | HTTP | URL: `https://mcp.deepsense.ai/icd10_codes/mcp` | Medical coding |
| **NPI Registry** | HTTP | URL: `https://mcp.deepsense.ai/npi_registry/mcp` | US provider identifiers |
| **CMS Coverage** | HTTP | URL: `https://mcp.deepsense.ai/cms_coverage/mcp` | CMS coverage database |
| **Open Targets** | HTTP | URL: `https://mcp.platform.opentargets.org/mcp` | Drug target discovery |
| **Synapse.org** | HTTP | URL: `https://mcp.synapse.org/mcp` | Scientific data metadata |
| **Benchling** | HTTP | Remote (requires setup) | R&D data and experiments |

---

### 20. Aggregators & Meta-Servers

| Server | Type | Install / URL | Description |
|--------|------|---------------|-------------|
| **MCP Omnisearch** | Stdio | `npx -y mcp-omnisearch` | Unified: Tavily + Brave + Perplexity + Exa + Firecrawl |
| **MetaMCP** | Stdio | GUI middleware | Manage multiple MCP connections |
| **MCPX** | Various | TheLunarCompany | Production gateway for MCP servers at scale |
| **CData Connect AI** | HTTP | URL: `https://mcp.cloud.cdata.com/mcp` | Managed platform for 350+ sources |
| **Paragon ActionKit** | Various | Community | 120+ SaaS integrations |
| **MCP Server Selector** | CLI | github.com/henkisdabro/Claude-Code-MCP-Server-Selector | TUI for enabling/disabling servers |

---

### 21. Specialized & Other

| Server | Type | Install / URL | Description |
|--------|------|---------------|-------------|
| **Docusign** | HTTP | URL: `https://mcp.docusign.com/mcp` | Contract management |
| **GoDaddy** | HTTP | URL: `https://api.godaddy.com/v1/domains/mcp` | Domain search & availability |
| **Bitly** | HTTP | URL: `https://api-ssl.bitly.com/v4/mcp` | Link shortening, QR codes |
| **Klaviyo** | HTTP | URL: `https://mcp.klaviyo.com/mcp` | Email marketing data |
| **MailerLite** | HTTP | URL: `https://mcp.mailerlite.com/mcp` | Email marketing assistant |
| **Indeed** | HTTP | URL: `https://mcp.indeed.com/claude/mcp` | Job search |
| **Dice** | HTTP | URL: `https://mcp.dice.com/mcp` | Tech job search |
| **Kiwi.com** | HTTP | URL: `https://mcp.kiwi.com` | Flight search |
| **Trivago** | HTTP | URL: `https://mcp.trivago.com/mcp` | Hotel comparison |
| **lastminute.com** | HTTP | URL: `https://mcp.lastminute.com/mcp` | Travel booking |
| **Wyndham Hotels** | HTTP | URL: `https://mcp.wyndhamhotels.com/claude/mcp` | Hotel discovery |
| **Blender** | Stdio | Community | 3D modeling control |
| **DaVinci Resolve** | Stdio | Community | Video editing |
| **REAPER** | Stdio | Community | Music production |
| **Google Maps** | Stdio | Community (archived) | Location, routes, geospatial |
| **Harvey** | HTTP | URL: `https://api.harvey.ai/hosted_mcp/mcp` | Legal queries and research |
| **LegalZoom** | HTTP | URL: `https://www.legalzoom.com/mcp/claude/v1` | Legal guidance and tools |
| **Midpage** | HTTP | URL: `https://app.midpage.ai/mcp` | Legal research |
| **Blockscout** | HTTP | URL: `https://mcp.blockscout.com/mcp` | Blockchain data analysis |
| **Udemy Business** | HTTP | URL: `https://api.udemy.com/mcp` | Skill-building resources |
| **Clockwise** | HTTP | URL: `https://mcp.getclockwise.com/mcp` | Scheduling and time management |
| **LILT** | HTTP | URL: `https://mcp.lilt.com/mcp` | Translation with human verification |
| **Guru** | HTTP | URL: `https://mcp.api.getguru.com/mcp` | Company knowledge search |
| **Mem** | HTTP | URL: `https://mcp.mem.ai/mcp` | AI notebook |
| **Glean** | HTTP | Remote (requires setup) | Enterprise context |

---

## Anthropic Official MCP Registry

The Anthropic MCP Registry (at `https://api.anthropic.com/mcp-registry/v0/servers`) contains **164+ commercially verified servers** as of March 2026. These are production-ready, company-maintained servers.

### Complete Registry List (Claude Code Compatible)

The following servers are explicitly marked as compatible with Claude Code:

**Productivity & Project Management:**
Notion, Linear, Asana, Atlassian (Jira/Confluence), ClickUp, monday.com, Smartsheet

**Communication:**
Slack, Intercom, Granola, Jam, Circleback

**Development:**
GitHub, Vercel, Netlify, Cloudflare, Clerk, GraphOS (Apollo), Supabase, PlanetScale

**Design:**
Figma, Canva, Magic Patterns, Miro

**Finance & Payments:**
Stripe, PayPal, Ramp, Mercury, Crypto.com, Square

**CRM & Sales:**
Clay, Attio, ZoomInfo, Crossbeam, Clarify, Day AI

**Analytics:**
Sentry, PostHog, Amplitude, Honeycomb, Ahrefs, Similarweb

**Documentation:**
Context7, Microsoft Learn

**Content & CMS:**
Webflow, WordPress.com, Wix, Sanity, Gamma, Lumin

**Automation:**
Zapier, n8n, Make, Workato

**Data:**
BigQuery, Snowflake, Databricks, MotherDuck

**Other:**
Hugging Face, Box, Egnyte, Cloudinary, Bitly, Klaviyo, MailerLite, GoDaddy, Dice, Trivago, lastminute.com, Clockwise, LILT, Guru, Mem, Glean, and many more

---

## MCP Discovery Platforms

| Platform | URL | Description |
|----------|-----|-------------|
| **Official MCP Registry** | registry.modelcontextprotocol.io | Official server discovery |
| **Anthropic Registry API** | api.anthropic.com/mcp-registry/v0/servers | Commercial verified servers |
| **MCP.so** | mcp.so | 18,000+ servers cataloged |
| **Smithery** | smithery.ai | Discovery + automated installation guides |
| **PulseMCP** | pulsemcp.com/servers | 8,600+ servers, daily updates |
| **LobeHub MCP** | lobehub.com/mcp | MCP server marketplace |
| **MCP Market** | mcpmarket.com | Top 100 by GitHub stars |
| **Glama** | glama.ai/mcp | Visual marketplace with previews |
| **Composio** | composio.dev | Production AI systems |
| **awesome-mcp-servers** | github.com/punkpeye/awesome-mcp-servers | Community-curated GitHub list |
| **awesome-mcp-servers** | github.com/wong2/awesome-mcp-servers | Another popular curated list |
| **MCP Servers Hub** | github.com/apappascs/mcp-servers-hub | Centralized catalog |

---

## Best Practices

### Security

1. **Trust but verify** -- Only install MCP servers from trusted sources
2. **Be cautious with content-fetching servers** -- They expose you to prompt injection risk
3. **Use project scope for team servers** -- `.mcp.json` is version-controlled
4. **Start with read-only servers** -- Documentation, search, observability first
5. **Narrow blast radius** -- Per-project API keys, limited directory scopes
6. **Log agent tool usage** -- Track what servers/tools are being called

### Performance

1. **Limit active servers to 5-6 per project** -- Disable unused ones
2. **Use Tool Search** -- Automatically reduces context by ~85%
3. **Monitor with `/context`** -- See token impact per server
4. **Configure `MAX_MCP_OUTPUT_TOKENS`** for servers with large outputs
5. **Use `MCP_TIMEOUT`** if servers are slow to start

### Organization

1. **Global (`user` scope)** -- Personal utilities used everywhere (Context7, memory, search)
2. **Project (`.mcp.json`)** -- Team-shared project-specific servers (Supabase, GitHub, Sentry)
3. **Local (default)** -- Experiments, personal dev servers, sensitive credentials
4. **Treat MCP like microservices** -- Each server has a clear responsibility

### Security Staged Approach

```
Stage 1: Read-only (docs, search, observability)
  -> Context7, Brave Search, Sentry, PostHog

Stage 2: Read-write within boundaries (project management, code)
  -> GitHub, Linear, Notion, Supabase

Stage 3: External actions (payments, communications)
  -> Stripe, Slack, email
```

---

## Recommended Starter Setup

### For Web Developers (Next.js/React)

```bash
# Documentation (always useful)
claude mcp add --scope user --transport http context7 https://mcp.context7.com/mcp

# Version control
claude mcp add --transport http github https://api.githubcopilot.com/mcp/

# Database
claude mcp add --transport http supabase https://mcp.supabase.com/mcp

# Error tracking
claude mcp add --transport http sentry https://mcp.sentry.dev/mcp

# Browser testing
claude mcp add playwright --transport stdio -- npx -y @playwright/mcp@latest

# Deployments
claude mcp add --transport http vercel https://mcp.vercel.com/

# Project management (pick one)
claude mcp add --transport http linear https://mcp.linear.app/mcp

# Communication
claude mcp add --transport http slack https://mcp.slack.com/mcp
```

### Minimal .mcp.json for Teams

```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/"
    },
    "supabase": {
      "type": "http",
      "url": "https://mcp.supabase.com/mcp"
    },
    "context7": {
      "type": "http",
      "url": "https://mcp.context7.com/mcp"
    },
    "sentry": {
      "type": "http",
      "url": "https://mcp.sentry.dev/mcp"
    },
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest"]
    }
  }
}
```

### For Data-Heavy Projects

```bash
claude mcp add --transport http bigquery https://bigquery.googleapis.com/mcp
claude mcp add --transport stdio postgres -- npx -y @modelcontextprotocol/server-postgres "postgresql://..."
claude mcp add --transport http posthog https://mcp.posthog.com/mcp
claude mcp add --transport http amplitude https://mcp.amplitude.com/mcp
```

---

## Key Takeaways

1. **164+ commercial servers** in Anthropic's official registry, **18,000+** community servers on MCP.so
2. **HTTP transport is preferred** for remote servers. SSE is deprecated. Stdio for local.
3. **Tool Search saves 85% context** -- auto-enabled when tools exceed 10% of window
4. **Keep 5-6 servers active** per project. Disable the rest.
5. **`.mcp.json` in project root** for team-shared config. `user` scope for personal utilities.
6. **OAuth is handled via `/mcp` command** in Claude Code. Tokens refresh automatically.
7. **Start with read-only servers** (Context7, search, docs) then add write servers.
8. **Environment variables in `.mcp.json`** use `${VAR}` or `${VAR:-default}` syntax.
9. **Claude Code can be an MCP server** itself (`claude mcp serve`).
10. **Enterprise control** via `managed-mcp.json` or `allowedMcpServers` / `deniedMcpServers`.

---

## Sources

- https://modelcontextprotocol.io/introduction
- https://code.claude.com/docs/en/mcp
- https://github.com/modelcontextprotocol/servers
- https://github.com/punkpeye/awesome-mcp-servers
- https://api.anthropic.com/mcp-registry/v0/servers?version=latest
- https://registry.modelcontextprotocol.io
- https://www.builder.io/blog/best-mcp-servers-2026
- https://desktopcommander.app/blog/2025/11/25/best-mcp-servers/
- https://github.com/microsoft/playwright-mcp
- https://github.com/awslabs/mcp
- https://github.com/hashicorp/terraform-mcp-server
- https://github.com/henkisdabro/Claude-Code-MCP-Server-Selector
- https://scottspence.com/posts/optimising-mcp-server-context-usage-in-claude-code
- https://claudefa.st/blog/tools/mcp-extensions/mcp-tool-search
- https://github.com/anthropics/claude-code/issues/3036
