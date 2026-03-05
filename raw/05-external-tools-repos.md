# External Tools, Repos, and Packages That Enhance Claude Code

> Comprehensive catalog of the Claude Code ecosystem as of March 2026.

---

## Table of Contents

1. [Awesome Lists & Meta-Catalogs](#1-awesome-lists--meta-catalogs)
2. [Official Anthropic Tools](#2-official-anthropic-tools)
3. [Agent Orchestrators & Multi-Agent Management](#3-agent-orchestrators--multi-agent-management)
4. [Issue Trackers & Task Managers](#4-issue-trackers--task-managers)
5. [MCP Servers — Essential](#5-mcp-servers--essential)
6. [MCP Servers — Database & Data](#6-mcp-servers--database--data)
7. [MCP Servers — Web & Search](#7-mcp-servers--web--search)
8. [MCP Servers — Specialized](#8-mcp-servers--specialized)
9. [UI / Browser Tools](#9-ui--browser-tools)
10. [Agent Skills & Skill Libraries](#10-agent-skills--skill-libraries)
11. [Plugins & Plugin Registries](#11-plugins--plugin-registries)
12. [Session Management & Continuity](#12-session-management--continuity)
13. [Memory & Context Persistence](#13-memory--context-persistence)
14. [Cost Tracking & Usage Monitoring](#14-cost-tracking--usage-monitoring)
15. [Observability & Telemetry](#15-observability--telemetry)
16. [IDE & Editor Integrations](#16-ide--editor-integrations)
17. [GUI Clients & Desktop Apps](#17-gui-clients--desktop-apps)
18. [Docker, Sandboxing & Isolation](#18-docker-sandboxing--isolation)
19. [Configuration & Framework Tools](#19-configuration--framework-tools)
20. [Hooks & Hook Utilities](#20-hooks--hook-utilities)
21. [Status Lines & Terminal UI](#21-status-lines--terminal-ui)
22. [Slash Commands & Command Collections](#22-slash-commands--command-collections)
23. [Workflow & Project Management Systems](#23-workflow--project-management-systems)
24. [Code Quality & Review Tools](#24-code-quality--review-tools)
25. [CI/CD & GitHub Actions](#25-cicd--github-actions)
26. [Mobile & Remote Access](#26-mobile--remote-access)
27. [Voice & Speech Tools](#27-voice--speech-tools)
28. [Notification & Communication](#28-notification--communication)
29. [Transcript & Log Tools](#29-transcript--log-tools)
30. [Knowledge & Documentation Guides](#30-knowledge--documentation-guides)

---

## 1. Awesome Lists & Meta-Catalogs

| Name | URL | Stars | Description |
|------|-----|-------|-------------|
| **awesome-claude-code** (hesreallyhim) | [GitHub](https://github.com/hesreallyhim/awesome-claude-code) | 26.4k | The largest curated list of skills, hooks, slash-commands, agent orchestrators, applications, and plugins |
| **awesome-claude-code** (jqueryscript) | [GitHub](https://github.com/jqueryscript/awesome-claude-code) | - | Curated list of tools, IDE integrations, frameworks, and resources |
| **awesome-claude-code-toolkit** | [GitHub](https://github.com/rohitg00/awesome-claude-code-toolkit) | - | Most comprehensive toolkit: 135 agents, 35 skills (+15K via SkillKit), 42 commands, 120 plugins, 19 hooks, 15 rules, 7 templates, 6 MCP configs |
| **awesome-claude-code-plugins** (ccplugins) | [GitHub](https://github.com/ccplugins/awesome-claude-code-plugins) | - | Curated list of slash commands, subagents, MCP servers, and hooks |
| **awesome-claude-plugins** | [GitHub](https://github.com/quemsah/awesome-claude-plugins) | - | Automated collection of plugin adoption metrics using n8n workflows |
| **awesome-claude** | [GitHub](https://github.com/tonysurfly/awesome-claude) | - | General Anthropic Claude resources |
| **awesome-claude-code-agents** | [GitHub](https://github.com/hesreallyhim/awesome-claude-code-agents) | 1.1k | Curated list of Claude Code Sub-Agents |
| **awesome-agent-skills** (VoltAgent) | [GitHub](https://github.com/VoltAgent/awesome-agent-skills) | - | 500+ agent skills from official dev teams and community |
| **Claude Code Repos Index** | [GitHub](https://github.com/danielrosehill/Claude-Code-Repos-Index) | - | Index of 75+ Claude Code related repositories |
| **Claude Code Tips** | [GitHub](https://github.com/ykdojo/claude-code-tips) | - | 35+ brief but information-dense Claude Code tips |
| **AwesomeClaude.ai** | [Website](https://awesomeclaude.ai/) | - | Web-based Claude AI resources directory |
| **ClaudePluginHub** | [Website](https://claudecodeplugins.io/) | - | Web-based plugin discovery hub |

---

## 2. Official Anthropic Tools

| Name | URL | Stars | Description | Install |
|------|-----|-------|-------------|---------|
| **claude-code** | [GitHub](https://github.com/anthropics/claude-code) | 55k | Official CLI agentic coding tool | `npm i -g @anthropic-ai/claude-code` |
| **claude-code-action** | [GitHub](https://github.com/anthropics/claude-code-action) | 5k | GitHub Action for PRs and issues — code review, implementation, issue triage | `/install-github-app` |
| **claude-code-base-action** | [GitHub](https://github.com/anthropics/claude-code-base-action) | 550 | Base action for building custom GitHub Actions | N/A |
| **claude-code-security-review** | [GitHub](https://github.com/anthropics/claude-code-security-review) | 2.8k | AI-powered security review GitHub Action — found 500+ vulnerabilities | GitHub Marketplace |
| **claude-code-sdk-python** | [GitHub](https://github.com/anthropics/claude-code-sdk-python) | 4k | Official Python SDK for Claude Code | `pip install anthropic-claude-code-sdk` |
| **@anthropic-ai/claude-agent-sdk** | [npm](https://www.npmjs.com/package/@anthropic-ai/claude-agent-sdk) | - | SDK for building autonomous agents with Claude Code capabilities | `npm i @anthropic-ai/claude-agent-sdk` |
| **claude-plugins-official** | [GitHub](https://github.com/anthropics/claude-plugins-official) | 2.8k | Anthropic-managed directory of high quality Claude Code Plugins | N/A |
| **skills** (Anthropic) | [GitHub](https://github.com/anthropics/skills) | 37.5k | Public repository for Agent Skills | N/A |

---

## 3. Agent Orchestrators & Multi-Agent Management

| Name | URL | Stars | Description | Integration Type |
|------|-----|-------|-------------|-----------------|
| **claude-squad** | [GitHub](https://github.com/smtg-ai/claude-squad) | 5.6k | Terminal app managing multiple AI agents (Claude Code, Aider, Codex, OpenCode, Amp) in separate tmux workspaces with git worktrees | CLI companion (`brew install claude-squad`) |
| **Claude-Flow** | [GitHub](https://github.com/ruvnet/claude-flow) | 11.4k | Enterprise-grade AI orchestration platform | CLI tool |
| **claude-swarm** | [GitHub](https://github.com/parruda/claude-swarm) | 1.6k | Launch Claude Code session connected to swarm of agents | CLI tool |
| **Claude Task Master** | [GitHub](https://github.com/eyaltoledano/claude-task-master) | - | Task management system for AI-driven development workflows | CLI/Plugin |
| **claude_code_agent_farm** | [GitHub](https://github.com/Dicklesworthstone/claude_code_agent_farm) | 619 | Runs multiple Claude Code sessions in parallel | Python tool |
| **crystal** | [GitHub](https://github.com/stravu/crystal) | 2.7k | Run multiple Claude Code sessions in parallel | CLI tool |
| **Auto-Claude** | [GitHub](https://github.com/AndyMik90/Auto-Claude) | - | Autonomous multi-agent coding framework with kanban UI | Framework |
| **Claude Code Flow** | [GitHub](https://github.com/ruvnet/claude-code-flow) | - | Code-first orchestration layer for autonomous development | SDK |
| **Claude Task Runner** | [GitHub](https://github.com/grahama1970/claude-task-runner) | - | Context isolation and focused task execution | CLI tool |
| **sudocode** | [GitHub](https://github.com/sudocode-ai/sudocode) | - | Lightweight agent orchestration dev tool that lives in your repo | CLI tool |
| **TSK** | [GitHub](https://github.com/dtormoen/tsk) | - | Rust CLI tool delegating tasks to agents in sandboxed Docker environments | CLI tool |
| **The Agentic Startup** | [GitHub](https://github.com/rsmdt/the-startup) | - | Collection of agents and commands for shipping production code | Framework |
| **agents** (wshobson) | [GitHub](https://github.com/wshobson/agents) | 25k | Production-ready subagents for Claude Code | Subagents |
| **agents** (contains-studio) | [GitHub](https://github.com/contains-studio/agents) | 11.4k | Specialized AI agents for rapid development | Subagents |
| **async-code** | [GitHub](https://github.com/ObservedObserver/async-code) | 504 | Multiple parallel tasks with personal agent | CLI tool |
| **ccmanager** | [GitHub](https://github.com/kbwo/ccmanager) | 747 | Session manager for Claude Code / Gemini CLI / Codex CLI / Cursor Agent | CLI tool |
| **agent-of-empires** | [GitHub](https://github.com/njbrake/agent-of-empires) | 873 | Coding Agent Terminal Session manager | CLI tool |
| **conductor** | - | - | Run multiple Claude Codes in parallel | CLI tool |

---

## 4. Issue Trackers & Task Managers

| Name | URL | Stars | Description | Integration Type |
|------|-----|-------|-------------|-----------------|
| **Beads** | [GitHub](https://github.com/steveyegge/beads) | - | Distributed, git-backed graph issue tracker for AI agents. Dolt-powered version-controlled SQL database with cell-level merge, native branching, and auto-ready task detection | CLI (`bd`), hooks, plugin |
| **Claude Code PM (ccpm)** | [GitHub](https://github.com/automazeio/ccpm) | 6k | Project management using GitHub Issues with comprehensive workflow | CLI tool |
| **Claude Task Master** | [GitHub](https://github.com/eyaltoledano/claude-task-master) | - | Task management system for AI-driven development | CLI/Plugin |
| **Simone** | [GitHub](https://github.com/Helmi/claude-simone) | 528 | Broader project management workflow with documents and guidelines | Framework |
| **ScopeCraft** | [GitHub](https://github.com/scopecraft/command) | - | Comprehensive SDLC commands for project management, implementation, planning, and release | Commands |

---

## 5. MCP Servers -- Essential

| Name | URL | Description | Install |
|------|-----|-------------|---------|
| **Context7** | [GitHub](https://github.com/upstash/context7) | Up-to-date library documentation for LLMs. Resolves library IDs and fetches version-specific docs with code examples | `claude mcp add context7 -- npx -y @upstash/context7-mcp` |
| **GitHub MCP** | [GitHub](https://github.com/modelcontextprotocol/servers) | Official GitHub integration — repos, PRs, issues, CI/CD workflows, code search | `claude mcp add github -- npx -y @modelcontextprotocol/server-github` |
| **Filesystem MCP** | [GitHub](https://github.com/modelcontextprotocol/servers) | Advanced file operations, large file handling, directory ops, file search, streaming writes | `claude mcp add filesystem -- npx -y @modelcontextprotocol/server-filesystem` |
| **Playwright MCP** | [GitHub](https://github.com/microsoft/playwright-mcp) | Browser automation via accessibility snapshots (no screenshots needed). Testing, validation, navigation | `claude mcp add playwright -- npx -y @anthropic-ai/mcp-playwright` |
| **Brave Search MCP** | [GitHub](https://github.com/modelcontextprotocol/servers) | Anthropic-recommended search: web, local, image, video, news | `claude mcp add brave-search -- npx -y @modelcontextprotocol/server-brave-search` |
| **claude-code-mcp** (steipete) | [GitHub](https://github.com/steipete/claude-code-mcp) | Use Claude Code itself as a one-shot MCP server (agent-in-agent) | `npx -y claude-code-mcp` |
| **claude-context-mode** | [GitHub](https://github.com/mksglu/claude-context-mode) | MCP server reducing context usage by 98% | MCP server |

---

## 6. MCP Servers -- Database & Data

| Name | URL | Description | Install |
|------|-----|-------------|---------|
| **PostgreSQL MCP** | [GitHub](https://github.com/modelcontextprotocol/servers) | Natural language database queries, schema inspection, read-only access | `claude mcp add postgres -- npx -y @modelcontextprotocol/server-postgres` |
| **SQLite MCP** | [GitHub](https://github.com/modelcontextprotocol/servers) | SQLite database management and queries | `claude mcp add sqlite -- npx -y @modelcontextprotocol/server-sqlite` |
| **Supabase Agent Skills** | [GitHub](https://github.com/supabase/agent-skills) | 833 stars. Agent Skills for Supabase developers | Skill |
| **read-only-postgres** | [GitHub](https://github.com/jawwadfirdousi/agent-skills) | Read-only PostgreSQL query skill with strict validation | Skill |
| **claude-context-local** | [GitHub](https://github.com/FarhanAliRaza/claude-context-local) | 154 stars. Code search MCP with local embeddings | MCP server |

---

## 7. MCP Servers -- Web & Search

| Name | URL | Description | Install |
|------|-----|-------------|---------|
| **Firecrawl MCP** | [GitHub](https://github.com/firecrawl/firecrawl-mcp-server) | Powerful web scraping and search — 8 tools: scrape, batch scrape, crawl, search, extract, map, plus async ops. Returns clean markdown or structured JSON | `claude mcp add firecrawl -- npx -y firecrawl-mcp` |
| **Context7 HTTP** | [GitHub](https://github.com/lrstanley/context7-http) | Context7 MCP Server with HTTP SSE and Streamable transport | MCP server |
| **Composio Connect-Apps** | [Website](https://composio.dev/) | Instantly link Claude to 500+ SaaS applications | MCP server |
| **Browserbase Plugin** | - | Cloud browsers for web interaction | Plugin |

---

## 8. MCP Servers -- Specialized

| Name | URL | Description | Install |
|------|-----|-------------|---------|
| **stt-mcp-server-linux** | [GitHub](https://github.com/marcindulak/stt-mcp-server-linux) | Push-to-talk speech transcription using Python MCP | MCP server |
| **VoiceMode MCP** | [GitHub](https://github.com/mbailey/voicemode) | Natural conversations to Claude Code via voice | MCP server |
| **mcp-builder** | - | Guides designing and implementing high-quality MCP servers | MCP server |
| **Stitch MCP** | [GitHub](https://github.com/google-labs-code/stitch-skills) | 886 stars. Agent Skills for Stitch MCP server (Google Labs) | MCP server + Skills |

---

## 9. UI / Browser Tools

| Name | URL | Stars | Description | Integration Type |
|------|-----|-------|-------------|-----------------|
| **React Grab** | [GitHub](https://github.com/aidenybai/react-grab) | - | Cmd+C over any UI element to capture React component context (file path, line number, component hierarchy, HTML) and send to Claude Code. Makes frontend editing 3x faster | npm: `react-grab` + `@react-grab/claude-code` |
| **dev-browser** | [GitHub](https://github.com/SawyerHood/dev-browser) | 3.3k | Claude Skill for web browser capability | Skill |
| **visual-claude** | [GitHub](https://github.com/thetronjohnson/visual-claude) | 208 | Browser coding agent interface | Web app |
| **visual-explainer** | [GitHub](https://github.com/nicobailon/visual-explainer) | 731 | Generate rich HTML pages for visual diffs | Skill |
| **Vercel agent-browser** | [GitHub](https://github.com/vercel-labs/agent-browser) | - | Browser automation CLI for AI agents | CLI tool |
| **Claude in Chrome** | - | - | Official Chrome extension — Claude sees, clicks, types, and navigates in your browser | Chrome extension |
| **executeautomation/mcp-playwright** | [GitHub](https://github.com/executeautomation/mcp-playwright) | - | Playwright MCP Server for browser and API automation in Claude Desktop, Cline, Cursor IDE | MCP server |

---

## 10. Agent Skills & Skill Libraries

### Tier 1: Major Skill Libraries

| Name | URL | Stars | Description | Install |
|------|-----|-------|-------------|---------|
| **Superpowers** | [GitHub](https://github.com/obra/superpowers) | 27.9k | Comprehensive skills library for software engineering — structured lifecycle planning, TDD, debugging, code review | `npx skills add obra/superpowers -a claude-code` |
| **agent-skills** (Vercel) | [GitHub](https://github.com/vercel-labs/agent-skills) | 12k | Vercel's official collection for Vercel deployments | `npx skills add vercel-labs/agent-skills` |
| **Everything Claude Code** | [GitHub](https://github.com/affaan-m/everything-claude-code) | 50k | Anthropic Hackathon Winner — skills, instincts, memory, security, research-first development | Framework |
| **skills** (Anthropic) | [GitHub](https://github.com/anthropics/skills) | 37.5k | Official public repository for Agent Skills | N/A |
| **skills** (Microsoft) | [GitHub](https://github.com/microsoft/skills) | 1.3k | Skills and MCP servers for coding agents | N/A |
| **add-skill** (Vercel) | [GitHub](https://github.com/vercel-labs/add-skill) | 1.1k | Install agent skills from any git repository | `npx skills add <repo>` |
| **ui-ux-pro-max-skill** | [GitHub](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) | 16.9k | Design intelligence for professional UI/UX | Skill |

### Tier 2: Domain-Specific Skills

| Name | URL | Stars | Description |
|------|-----|-------|-------------|
| **planning-with-files** | [GitHub](https://github.com/OthmanAdi/planning-with-files) | 9.7k | Manus-style persistent markdown planning |
| **obsidian-skills** | [GitHub](https://github.com/kepano/obsidian-skills) | 7k | Claude Skills for Obsidian |
| **claude-scientific-skills** | [GitHub](https://github.com/K-Dense-AI/claude-scientific-skills) | 6.4k | Skills for research, science, engineering, analysis, finance, writing |
| **marketingskills** | [GitHub](https://github.com/coreyhaines31/marketingskills) | 4.8k | Marketing: CRO, copywriting, SEO |
| **antfu's skills** | [GitHub](https://github.com/antfu/skills) | 3.5k | Curated collection of agent skills |
| **humanizer** | [GitHub](https://github.com/blader/humanizer) | 2.9k | Removes AI-generated writing signatures |
| **notebooklm-skill** | [GitHub](https://github.com/PleasePrompto/notebooklm-skill) | 2.7k | Communicate with Google NotebookLM |
| **Agent-Skills-for-Context-Engineering** | [GitHub](https://github.com/muratcankoylan/Agent-Skills-for-Context-Engineering) | 7.8k | Context engineering and multi-agent architectures |
| **n8n-skills** | [GitHub](https://github.com/czlonkowski/n8n-skills) | 2.2k | Build flawless n8n workflows |
| **AI-research-SKILLs** | [GitHub](https://github.com/Orchestra-Research/AI-research-SKILLs) | 2.2k | Visual Skills Pack for Obsidian |
| **Trail of Bits Security Skills** | [GitHub](https://github.com/trailofbits/skills) | 1.3k | Professional security-focused skills — vulnerability detection, security research |
| **claude-skills** (alirezarezvani) | [GitHub](https://github.com/alirezarezvani/claude-skills) | 2.3k | Collection of real-world usage skills and subagents |
| **claude-skills** (Jeffallan) | [GitHub](https://github.com/Jeffallan/claude-skills) | 1.5k | 66 specialized skills for full-stack developers |
| **playwright-skill** | [GitHub](https://github.com/lackeyjb/playwright-skill) | 1.5k | Browser automation with Playwright — Claude autonomously writes and executes tests |
| **Claudeception** | [GitHub](https://github.com/blader/Claudeception) | 1.5k | Autonomous skill extraction and learning |
| **last30days-skill** | [GitHub](https://github.com/mvanhorn/last30days-skill) | 1.3k | Research topics across Reddit + X from last 30 days |
| **code-review-expert** | [GitHub](https://github.com/sanyuan0704/code-review-expert) | 1.9k | Comprehensive code review skill |
| **claude-design-engineer** | [GitHub](https://github.com/Dammyjay93/claude-design-engineer) | 1.1k | Design engineering for consistent UI |
| **aws-agent-skills** | [GitHub](https://github.com/itsmostafa/aws-agent-skills) | 977 | AWS cloud engineering across 18 services |

### Tier 3: Specialized & Niche Skills

| Name | URL | Stars | Description |
|------|-----|-------|-------------|
| **next-skills** (Vercel) | [GitHub](https://github.com/vercel-labs/next-skills) | 424 | Agent skills for Next.js workflows |
| **Expo-Skills** | [GitHub](https://github.com/expo/skills) | 749 | AI agent skills for Expo projects |
| **vue-skills** | [GitHub](https://github.com/vuejs-ai/skills) | 799 | Agent skills for Vue 3 development |
| **rust-skills** | [GitHub](https://github.com/actionbook/rust-skills) | 595 | Rust Developer AI Assistance System |
| **nuxt-skills** | [GitHub](https://github.com/onmax/nuxt-skills) | 475 | Vue, Nuxt, and NuxtHub skills |
| **cloudflare-skill** | [GitHub](https://github.com/dmmulroy/cloudflare-skill) | 639 | Cloudflare platform reference docs |
| **Youtube-clipper-skill** | [GitHub](https://github.com/op7418/Youtube-clipper-skill) | 633 | Download videos, generate chapters, clip segments |
| **ui-skills** | [GitHub](https://github.com/ibelick/ui-skills) | 629 | Skills to polish interfaces built by agents |
| **threejs-skills** | [GitHub](https://github.com/CloudAI-X/threejs-skills) | 904 | Three.js skill collection for 3D elements |
| **solana-dev-skill** | [GitHub](https://github.com/solana-foundation/solana-dev-skill) | 250 | Modern Solana development |
| **web-quality-skills** (Addy Osmani) | [GitHub](https://github.com/addyosmani/web-quality-skills) | 250 | Optimize web quality based on Lighthouse |
| **SkillForge** | [GitHub](https://github.com/tripleyak/SkillForge) | 467 | Meta-skill for generating Claude Code skills |
| **VibeSec-Skill** | [GitHub](https://github.com/BehiSecc/VibeSec-Skill) | 496 | Help Claude write secure code |
| **Pretty-mermaid-skills** | [GitHub](https://github.com/imxv/Pretty-mermaid-skills) | 487 | Mermaid chart rendering capability |
| **ios-simulator-skill** | [GitHub](https://github.com/conorluddy/ios-simulator-skill) | 440 | iOS Simulator Skill for Claude Code |
| **claude-seo** | [GitHub](https://github.com/AgriciDaniel/claude-seo) | 1.5k | Universal SEO skill |
| **gemini-skills** | [GitHub](https://github.com/google-gemini/gemini-skills) | 2k | Skills for Gemini API and SDK |
| **manim_skill** | [GitHub](https://github.com/adithya-s-k/manim_skill) | 328 | Agent skills for Manim animations |
| **callstackincubator** | [GitHub](https://github.com/callstackincubator/agent-skills) | 328 | React Native skills for AI coding assistants |
| **claude-office-skills** | [GitHub](https://github.com/tfriedel/claude-office-skills) | 232 | Office document creation and editing skills |
| **solid-skills** | [GitHub](https://github.com/ramziddin/solid-skills) | 205 | Senior-engineer quality code through SOLID principles |
| **x-research-skill** | [GitHub](https://github.com/rohunvora/x-research-skill) | 781 | X/Twitter research skill |
| **skill-codex** | [GitHub](https://github.com/skills-directory/skill-codex) | 512 | Delegate prompts to Codex from Claude Code |
| **frontend-slides** | [GitHub](https://github.com/zarazhangrui/frontend-slides) | 519 | Create animation-rich HTML presentations |
| **claude-skill-homeassistant** | [GitHub](https://github.com/komal-SkyNET/claude-skill-homeassistant) | 206 | Manage Home Assistant workflows |
| **csv-data-summarizer** | [GitHub](https://github.com/coffeefuelbump/csv-data-summarizer-claude-skill) | 206 | Analyze CSV files with Python and pandas |
| **nano-image-generator-skill** | [GitHub](https://github.com/lxfater/nano-image-generator-skill) | 110 | Generate images using Gemini 3 Pro |

---

## 11. Plugins & Plugin Registries

| Name | URL | Stars | Description |
|------|-----|-------|-------------|
| **claude-plugins-official** (Anthropic) | [GitHub](https://github.com/anthropics/claude-plugins-official) | 2.8k | Anthropic-managed directory of high quality plugins |
| **claude-code-plugins-plus-skills** | [GitHub](https://github.com/jeremylongshore/claude-code-plugins-plus-skills) | 1.5k | 270+ plugins with 739 agent skills |
| **CCPlugins** | [GitHub](https://github.com/brennercruvinel/CCPlugins) | 2.6k | Claude Code Plugins that save time |
| **claude-hud** | [GitHub](https://github.com/jarrodwatts/claude-hud) | - | Shows context usage, active tools, agents, todo progress |
| **claude-code-safety-net** | [GitHub](https://github.com/kenryu42/claude-code-safety-net) | 722 | Catches destructive git and filesystem commands before execution |
| **adversarial-spec** | [GitHub](https://github.com/zscole/adversarial-spec) | 205 | Iteratively refines specs through LLM debate |
| **cartographer** | [GitHub](https://github.com/kingbootoshi/cartographer) | - | Maps and documents codebases |
| **claude-review-loop** | [GitHub](https://github.com/hamelsmu/claude-review-loop) | - | Automated code review loop |
| **ensue-skill** | [GitHub](https://github.com/mutable-state-inc/ensue-skill) | - | Persistent knowledge tree |
| **homunculus** | - | - | Learns work patterns over time |
| **Local-Review** | - | - | Parallel local diff code reviews to catch issues before committing |
| **Plannotator** | - | - | Makes planning mode clearer with structured, annotated plans |
| **claude-workflow-v2** | [GitHub](https://github.com/CloudAI-X/claude-workflow-v2) | - | Universal workflow plugin with agents, skills |
| **laravel/claude-code** | [GitHub](https://github.com/laravel/claude-code) | - | Claude Code plugins for PHP/Laravel |
| **n-skills** | [GitHub](https://github.com/numman-ali/n-skills) | 789 | Curated plugin marketplace for AI agents |
| **design-plugin** | [GitHub](https://github.com/0xdesign/design-plugin) | 176 | UI design decisions through rapid iteration |
| **arscontexta** | [GitHub](https://github.com/agenticnotetaking/arscontexta) | - | Generates individualized knowledge systems |
| **call-me** | [GitHub](https://github.com/ZeframLou/call-me) | - | Minimal plugin that lets Claude Code call you (phone) |

---

## 12. Session Management & Continuity

| Name | URL | Stars | Description | Integration Type |
|------|-----|-------|-------------|-----------------|
| **cc-sessions** | [GitHub](https://github.com/GWUDCAP/cc-sessions) | 1.5k | Opinionated extension set: hooks, subagents, commands, task/git management | Extension set |
| **claude-session-restore** | [GitHub](https://github.com/ZENG3LD/claude-session-restore) | - | Restore context from previous sessions with multi-factor data collection | CLI tool |
| **claude-code-tools** | [GitHub](https://github.com/pchalasani/claude-code-tools) | - | Well-crafted toolset for session continuity | CLI tool |
| **claude-sessions** | [GitHub](https://github.com/iannuttall/claude-sessions) | 1.1k | Comprehensive development session tracking | CLI tool |
| **recall** | [GitHub](https://github.com/zippoxer/recall) | 100 | Full-text search Claude Code sessions in terminal | CLI tool |
| **cchistory** | [GitHub](https://github.com/eckardt/cchistory) | - | Like shell `history` command but for Claude Code sessions | CLI tool |
| **flashbacker** | [GitHub](https://github.com/agentsea/flashbacker) | 54 | State management with session continuity | CLI tool |
| **ccheckpoints** | [GitHub](https://github.com/p32929/ccheckpoints) | 26 | Checkpoint system for sessions | CLI tool |
| **Continuous-Claude-v2** | [GitHub](https://github.com/parcadei/Continuous-Claude-v2) | 2.2k | Context management with hooks and ledgers | Framework |
| **Continuous Claude** | [GitHub](https://github.com/AnandChowdhary/continuous-claude) | 1.1k | Run Claude Code in continuous loop | CLI tool |

---

## 13. Memory & Context Persistence

| Name | URL | Stars | Description | Integration Type |
|------|-----|-------|-------------|-----------------|
| **claude-mem** | [GitHub](https://github.com/thedotmack/claude-mem) | 13.1k | Automatically captures tool usage observations, generates semantic summaries, injects relevant context into future sessions. Stores in local SQLite with FTS5 search. Saves ~2,250 tokens per session | Plugin (`/plugin install claude-mem`) |
| **cipher** | [GitHub](https://github.com/campfirein/cipher) | 3.4k | Open-source memory layer for coding agents | Plugin |
| **claude-cognitive** | [GitHub](https://github.com/GMaN1911/claude-cognitive) | 399 | Working memory for Claude Code | Plugin |
| **claude-user-memory** | [GitHub](https://github.com/irenicj/claude-user-memory) | 125 | Comprehensive user memory system | Plugin |
| **claude-code-auto-memory** | [GitHub](https://github.com/severity1/claude-code-auto-memory) | 81 | Automatically maintains CLAUDE.md files | Hook |
| **claude-code-semantic-memory** | [GitHub](https://github.com/gtrusler/claude-code-heavy) | 70 | Persistent semantic memory system | Plugin |
| **Severance** | [GitHub](https://github.com/blas0/Severance) | 41 | Semantic memory system | Plugin |
| **claude-self-reflect** | [GitHub](https://github.com/ramakay/claude-self-reflect) | 189 | Fix Claude's memory issues through self-reflection | Hook/Tool |
| **ContextKit** | [GitHub](https://github.com/FlineDev/ContextKit) | - | Systematic development framework with 4-phase methodology | Framework |
| **context-forge** | [GitHub](https://github.com/webdevtodayjason/context-forge) | 134 | CLI tool for context engineering documentation | CLI tool |

---

## 14. Cost Tracking & Usage Monitoring

| Name | URL | Stars | Description | Integration Type |
|------|-----|-------|-------------|-----------------|
| **ccusage** | [GitHub](https://github.com/ryoppippi/ccusage) | - | CLI tool analyzing Claude Code usage from local JSONL files. Token usage/costs by date, week, month. Session grouping, model breakdown | CLI (`npx ccusage`) |
| **Claude-Code-Usage-Monitor** | [GitHub](https://github.com/Maciek-roboblog/Claude-Code-Usage-Monitor) | - | Real-time terminal monitoring with ML-based predictions, Rich UI, burn rate analysis | CLI tool |
| **ccflare** | [GitHub](https://github.com/snipeship/ccflare) | - | Claude Code usage dashboard with web-UI | Web app |
| **better-ccflare** | [GitHub](https://github.com/tombii/better-ccflare/) | - | Feature-enhanced fork of ccflare with performance improvements | Web app |
| **Claudex** | [GitHub](https://github.com/kunwar-shah/claudex) | - | Web-based browser for exploring conversation history | Web app |
| **viberank** | [GitHub](https://github.com/sculptdotfun/viberank) | - | Community-driven leaderboard for Claude Code usage statistics | Web app |
| **ClaudeUsageBar** | [GitHub](https://github.com/Artzainnn/ClaudeUsageBar) | 22 | Track Claude usage from Mac menu bar | macOS app |
| **cc-monitor-rs** | [GitHub](https://github.com/ZhangHanDong/cc-monitor-rs) | 22 | Real-time usage monitor with Rust UI | CLI tool |
| **cc-monitor-worker** | [GitHub](https://github.com/cometkim/cc-monitor-worker) | 13 | Monitoring with Cloudflare Workers | Web service |
| **Claude Code Usage Tracker** | [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=YahyaShareef.claude-code-usage-tracker) | - | VS Code extension for usage tracking | VS Code extension |
| **ccusage Raycast Extension** | [Raycast Store](https://www.raycast.com/nyatinte/ccusage) | - | ccusage in Raycast launcher | Raycast extension |
| **Vibe-Log** | [GitHub](https://github.com/vibe-log/vibe-log-cli) | - | Analyzes Claude Code prompts with session analysis guidance | CLI tool |

---

## 15. Observability & Telemetry

| Name | URL | Stars | Description | Integration Type |
|------|-----|-------|-------------|-----------------|
| **claude-code-otel** | [GitHub](https://github.com/ColeMurray/claude-code-otel) | - | Full observability stack: Claude Code -> OTEL Collector -> Prometheus (metrics) + Loki (logs) -> Grafana | Docker stack |
| **claude_telemetry** | [GitHub](https://github.com/TechNickAI/claude_telemetry) | - | OTEL wrapper for Claude Code CLI — logs tool calls, token usage, costs, traces to Logfire/Sentry/Honeycomb/Datadog. Drop-in `claude` replacement | `pip install claude-telemetry` |
| **claude-code-hooks-multi-agent-observability** | [GitHub](https://github.com/disler/claude-code-hooks-multi-agent-observability) | 893 | Real-time monitoring for Claude Code agents | Hooks |
| **Langfuse** | [Website](https://langfuse.com/integrations/frameworks/claude-agent-sdk) | - | Observability for Claude Agent SDK | Integration |

---

## 16. IDE & Editor Integrations

| Name | URL | Stars | Description | Editor |
|------|-----|-------|-------------|--------|
| **claudecode.nvim** | [GitHub](https://github.com/coder/claudecode.nvim) | 1.7k | Claude Code Neovim IDE Extension (official) | Neovim |
| **claude-code.nvim** | [GitHub](https://github.com/greggh/claude-code.nvim) | 1.7k | Seamless Neovim integration for Claude Code | Neovim |
| **claude-code-ide.el** | [GitHub](https://github.com/manzaltu/claude-code-ide.el) | 1.2k | Claude Code IDE for Emacs with MCP and ediff-based suggestions | Emacs |
| **claude-code.el** | [GitHub](https://github.com/stevemolitor/claude-code.el) | 577 | Claude Code Emacs interface | Emacs |
| **Claude Code Chat** | [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=AndrePimenta.claude-code-chat) | 968 | Beautiful Claude Code chat interface for VS Code | VS Code |
| **Claudix** | [GitHub](https://github.com/Haleclipse/Claudix) | - | VS Code extension with chat, session management, file operations | VS Code |
| **Claude-Autopilot** | [GitHub](https://github.com/benbasha/Claude-Autopilot) | 197 | VS Code/Cursor extension for automation | VS Code/Cursor |
| **minuet-ai.nvim** | [GitHub](https://github.com/milanglacier/minuet-ai.nvim) | 938 | Code completion from popular LLMs | Neovim |
| **getspecstory** | [GitHub](https://github.com/specstoryai/getspecstory) | 777 | Extensions for GH Copilot, Cursor, Claude Code | Multi-editor |
| **n8n-nodes-claudecode** | - | 70 | n8n automation workflows for Claude Code | n8n |

---

## 17. GUI Clients & Desktop Apps

| Name | URL | Stars | Description | Platform |
|------|-----|-------|-------------|----------|
| **Claudia** | [GitHub](https://github.com/getAsterisk/claudia) / [Website](https://claudia.so/) | 19.9k | Powerful GUI app for Claude Code. Built with Tauri 2 + React 18 + Rust. Custom agents, session management, usage tracking. Y Combinator-backed | macOS, Windows, Linux |
| **Claude Code Desktop** | [Docs](https://code.claude.com/docs/en/desktop) | - | Official Anthropic desktop app for Claude Code | macOS |
| **CloudCLI (Claude Code UI)** | [GitHub](https://github.com/siteboon/claudecodeui) | - | Open-source web UI for managing Claude Code sessions remotely on mobile and web | Web |
| **claude-canvas** | [GitHub](https://github.com/dvdsgl/claude-canvas) | 1.1k | TUI toolkit for Claude Code display | Terminal |
| **claude-code-studio** | [GitHub](https://github.com/arnaldo-delisio/claude-code-studio) | 190 | Complete development studio with AI agents | Desktop |

---

## 18. Docker, Sandboxing & Isolation

| Name | URL | Stars | Description | Integration Type |
|------|-----|-------|-------------|-----------------|
| **Docker Sandboxes** | [Docs](https://docs.docker.com/ai/sandboxes/) | - | Official Docker sandboxes for Claude Code — disposable isolated environments on dedicated microVMs. Network isolation, persistent workspaces, full Docker-in-Docker | Docker Desktop |
| **Container Use** (Dagger) | [GitHub](https://github.com/dagger/container-use) | - | Development environments for coding agents with Dagger | Docker |
| **claude-code-sandbox** | [GitHub](https://github.com/textcortex/claude-code-sandbox) | 255 | Run Claude Code safely in local Docker containers (archived, see Spritz) | Docker |
| **claudebox** | [GitHub](https://github.com/RchGrav/claudebox) | 795 | Claude Code Docker Development Environment | Docker |
| **run-claude-docker** | [GitHub](https://github.com/icanhasjonas/run-claude-docker) | 58 | Docker runner forwarding workspace to isolated container | Docker |
| **viwo-cli** | [GitHub](https://github.com/OverseedAI/viwo) | - | Run Claude Code in Docker with git worktrees | Docker + Git |
| **claude-code-container** | [GitHub](https://github.com/tintinweb/claude-code-container) | 76 | Docker container for dangerously-skip mode | Docker |
| **claude-code-containers** | [GitHub](https://github.com/ghostwriternr/claude-code-containers) | 227 | Use Claude Code on Cloudflare | Cloud |

---

## 19. Configuration & Framework Tools

| Name | URL | Stars | Description | Integration Type |
|------|-----|-------|-------------|-----------------|
| **SuperClaude** | [GitHub](https://github.com/NomenAK/SuperClaude) | 20k | Configuration framework with specialized commands and personas | Framework |
| **SuperClaude_Framework** | [GitHub](https://github.com/SuperClaude-Org/SuperClaude_Framework) | 20k | Enhanced framework with personas and methodologies | Framework |
| **claude-code-router** | [GitHub](https://github.com/musistudio/claude-code-router) | 25.3k | Use Claude Code as foundation for coding infrastructure | CLI tool |
| **claude-code-templates** | [GitHub](https://github.com/davila7/claude-code-templates) | 15.4k | CLI tool for configuring and monitoring Claude Code with dashboard | CLI (`npm i -g claude-code-templates`) |
| **ClaudeForge** | [GitHub](https://github.com/alirezarezvani/ClaudeForge) | 117 | CLAUDE.md Generator and Maintenance tool | CLI tool |
| **Rulesync** | [GitHub](https://github.com/dyoshikawa/rulesync) | - | Node.js CLI that automatically generates configs for multiple AI tools | CLI tool |
| **ccmate** | [GitHub](https://github.com/djyde/ccmate) | 546 | Configure Claude Code without pain | CLI tool |
| **ccexp** | [GitHub](https://github.com/nyatinte/ccexp) | - | Interactive CLI for discovering and managing Claude Code configuration | CLI tool |
| **claude-code-settings** | [GitHub](https://github.com/feiskyer/claude-code-settings) | 1.1k | Settings and commands for vibe coding | Config |
| **claude-code-configs** | [GitHub](https://github.com/Matt-Dionis/claude-code-configs) | 591 | Production-grade configurations and workflows | Config |
| **claude-config-editor** | [GitHub](https://github.com/gagarinyury/claude-config-editor) | 150 | Web tool to optimize config files | Web tool |
| **claude-starter-kit** | [GitHub](https://github.com/serpro69/claude-starter-kit) | - | Starter template with pre-configured MCP servers | Template |
| **claude-setup** | [GitHub](https://github.com/AizenvoltPrime/claude-setup) | 269 | Comprehensive configuration with MCP servers | Config |
| **ClaudeCTX** | [GitHub](https://github.com/foxj77/claudectx) | - | Switch entire Claude Code configuration with single command | CLI tool |
| **claude-modular** | [GitHub](https://github.com/oxygen-fragment/claude-modular) | 269 | Production-ready modular framework | Framework |
| **claude-rules-doctor** | [GitHub](https://github.com/nulone/claude-rules-doctor) | - | CLI that detects dead `.claude/rules/` files | CLI tool |
| **claude-select** | [GitHub](https://github.com/aeitroc/claude-select) | 100 | Unified launcher for LLM backend selection | CLI tool |
| **cc-mirror** | [GitHub](https://github.com/numman-ali/cc-mirror) | 1.3k | Multiple Claude Code variants with custom providers | CLI tool |
| **@aihubmix/claude-code** | [npm](https://www.npmjs.com/package/@aihubmix/claude-code) | - | Use Claude Code without Anthropic account, route to another LLM provider | npm package |
| **meridian** | [GitHub](https://github.com/markmdev/meridian) | 123 | Zero-config setup with task scaffolding | Framework |
| **claude-code-spec-workflow** | [GitHub](https://github.com/Pimzino/claude-code-spec-workflow) | 3.3k | Automated Kiro-style Spec workflow | Framework |

---

## 20. Hooks & Hook Utilities

| Name | URL | Stars | Description |
|------|-----|-------|-------------|
| **cc-tools** | [GitHub](https://github.com/Veraticus/cc-tools) | - | High-performance Go implementation of Claude Code hooks |
| **cchooks** | [GitHub](https://github.com/GowayLee/cchooks) | - | Lightweight Python SDK simplifying hook writing |
| **Claude Code Hook Comms (HCOM)** | [GitHub](https://github.com/aannoo/claude-hook-comms) | - | CLI tool for real-time communication in hooks |
| **parry** | [GitHub](https://github.com/vaporif/parry) | - | Prompt injection scanner for Claude Code hooks |
| **Dippy** | [GitHub](https://github.com/ldayton/Dippy) | - | Auto-approve safe bash commands, prompt for destructive ones |
| **Britfix** | [GitHub](https://github.com/Talieisin/britfix) | - | Converts American spellings to British English intelligently |
| **claude-code-prompt-improver** | [GitHub](https://github.com/severity1/claude-code-prompt-improver) | 1k | Intelligent prompt improver hook |
| **claude-code-boost** | [GitHub](https://github.com/yifanzz/claude-code-boost) | 160 | Hook utilities with intelligent auto-approval |
| **claude-code-hooks** | [GitHub](https://github.com/karanb192/claude-code-hooks) | 122 | Collection of useful hooks |
| **rins_hooks** | [GitHub](https://github.com/rinadelph/rins_hooks) | 101 | Universal hooks collection |
| **tdd-guard** | [GitHub](https://github.com/nizos/tdd-guard) | 1.7k | Automated TDD enforcement via hooks |
| **ccguard** | [GitHub](https://github.com/pomterre/ccguard) | 45 | Enforce net-negative LOC constraints |

---

## 21. Status Lines & Terminal UI

| Name | URL | Stars | Description |
|------|-----|-------|-------------|
| **claude-powerline** | [GitHub](https://github.com/Owloops/claude-powerline) | 678 | Vim-style powerline statusline for Claude Code |
| **CCometixLine** | [GitHub](https://github.com/Haleclipse/CCometixLine) | - | High-performance Claude Code statusline in Rust |
| **ccstatusline** | [GitHub](https://github.com/sirmalloc/ccstatusline) | - | Highly customizable status line formatter |
| **claude-code-statusline** | [GitHub](https://github.com/rz1989s/claude-code-statusline) | - | Enhanced 4-line statusline with themes |
| **claudia-statusline** | [GitHub](https://github.com/hagan/claudia-statusline) | - | High-performance Rust-based statusline with persistent stats |
| **Claude Code Tamagotchi** | [GitHub](https://github.com/Ido-Levi/claude-code-tamagotchi) | 240 | Digital friend in statusline |
| **tweakcc** | [GitHub](https://github.com/Piebald-AI/tweakcc) | 810 | Customize Claude Code styling and appearance |
| **claude-code-thinking-patch** | [GitHub](https://github.com/aleks-apostle/claude-code-thinking-patch) | 38 | Make thinking blocks visible by default |

---

## 22. Slash Commands & Command Collections

| Name | URL | Stars | Description |
|------|-----|-------|-------------|
| **commands** (wshobson) | [GitHub](https://github.com/wshobson/commands) | 1.7k | Production-ready slash commands collection |
| **Claude-Command-Suite** | [GitHub](https://github.com/qdhenry/Claude-Command-Suite) | 904 | Professional slash commands for workflows |
| **claude-commands** | [GitHub](https://github.com/badlogic/claude-commands) | 484 | Global Claude Code commands and workflows |
| **claude-cmd** | [GitHub](https://github.com/kiliczsh/claude-cmd) | 273 | Claude Code Commands Manager |
| **ClaudoPro Directory** | [GitHub](https://github.com/JSONbored/claudepro-directory) | - | Well-crafted selection of hooks, slash commands |

---

## 23. Workflow & Project Management Systems

| Name | URL | Stars | Description |
|------|-----|-------|-------------|
| **AgentSys** | [GitHub](https://github.com/avifenesh/agentsys) / [GitHub](https://github.com/agent-sh/agentsys) | 473 | Workflow automation with 14 plugins, 43 agents, 30 skills |
| **Compound Engineering Plugin** | [GitHub](https://github.com/EveryInc/compound-engineering-plugin) | - | Pragmatic agents, skills, and commands |
| **Context Engineering Kit** | [GitHub](https://github.com/NeoLabHQ/context-engineering-kit) | - | Hand-crafted collection of context engineering techniques |
| **RIPER Workflow** | [GitHub](https://github.com/tony/claude-code-riper-5) | - | Research, Innovate, Plan, Execute, Review phases |
| **AB Method** | [GitHub](https://github.com/ayoubben18/ab-method) | - | Spec-driven workflow transforming problems into focused missions |
| **Claude CodePro** | [GitHub](https://github.com/maxritter/claude-codepro) | - | Professional environment with spec-driven workflow and TDD |
| **Agentic Workflow Patterns** | [GitHub](https://github.com/ThibautMelen/agentic-workflow-patterns) | - | Comprehensive collection of documented agentic patterns |
| **spec-based-claude-code** | [GitHub](https://github.com/papaoloba/spec-based-claude-code) | 103 | Spec-Driven Development workflow |
| **Ralph Wiggum Loop** | Various repos | - | Autonomous AI development technique with safety guardrails |
| **ralph-orchestrator** | [GitHub](https://github.com/mikeyobrien/ralph-orchestrator) | - | Robust Ralph implementation cited in Anthropic docs |
| **The Ralph Playbook** | [GitHub](https://github.com/ClaytonFarr/ralph-playbook) | - | Comprehensive guide to the Ralph Wiggum technique |
| **ralph-claude-code** | [GitHub](https://github.com/frankbria/ralph-claude-code) | 1.2k | Autonomous AI development framework with safety guardrails |
| **claude-on-rails** | [GitHub](https://github.com/obie/claude-on-rails) | 691 | Development framework for Rails developers |

---

## 24. Code Quality & Review Tools

| Name | URL | Stars | Description |
|------|-----|-------|-------------|
| **AgentCheck** | [GitHub](https://github.com/devlyai/AgentCheck) | 33 | Local AI-powered code review agents |
| **claude-review-loop** | [GitHub](https://github.com/hamelsmu/claude-review-loop) | - | Automated code review loop |
| **code-review-expert** | [GitHub](https://github.com/sanyuan0704/code-review-expert) | 1.9k | Comprehensive code review skill |
| **design-engineer-auditor-package** | - | - | Motion design audits |
| **claude-code-test-runner** | [GitHub](https://github.com/firstloophq/claude-code-test-runner) | 20 | Automated E2E natural language test runner |
| **shotgun-alpha** | [GitHub](https://github.com/shotgun-sh/shotgun-alpha) | 3 | Codebase-aware spec engine |

---

## 25. CI/CD & GitHub Actions

| Name | URL | Stars | Description |
|------|-----|-------|-------------|
| **claude-code-action** (Anthropic) | [GitHub](https://github.com/anthropics/claude-code-action) | 5k | Official GitHub Action for PRs and issues. Supports Anthropic API, Bedrock, Vertex AI, Foundry. CI failure fixes, issue triage, docs, security scanning |
| **claude-code-base-action** | [GitHub](https://github.com/anthropics/claude-code-base-action) | 550 | Base action for building custom GitHub Actions |
| **claude-code-security-review** | [GitHub](https://github.com/anthropics/claude-code-security-review) | 2.8k | AI-powered security review GitHub Action |
| **Claude Hub** | [GitHub](https://github.com/claude-did-this/claude-hub) | 325 | Deploy Claude Code as autonomous GitHub bot via webhooks |
| **superclaude** (gwendall) | [GitHub](https://github.com/gwendall/superclaude) | 305 | Supercharge GitHub workflow with Claude AI |

---

## 26. Mobile & Remote Access

| Name | URL | Stars | Description | Platform |
|------|-----|-------|-------------|----------|
| **Happy Coder** | [GitHub](https://github.com/slopus/happy) / [Website](https://happy.engineering/) | - | Free open-source mobile app for Claude Code. Spawn and control multiple Claude Codes from phone or desktop. Real-time voice, encryption, full terminal state capture | iOS, Android, Web |
| **Moltty** | [Website](https://moltty.com/) | - | Open-source remote terminal multiplexer. Mac runs Claude Code with native credentials, any device can view and interact with sessions | Web |
| **Claude-Code-Remote** | [GitHub](https://github.com/JessyTsui/Claude-Code-Remote) | 943 | Control Claude Code remotely via email | Email |
| **CloudCLI** | [GitHub](https://github.com/siteboon/claudecodeui) | - | Web UI for managing Claude Code sessions remotely | Web |
| **claude-island** | [GitHub](https://github.com/farouqaldori/claude-island) | 639 | Claude Code notifications without context switch | Desktop |
| **claudecode-macmenu** | [GitHub](https://github.com/PiXeL16/claudecode-macmenu) | 32 | Mac Menu for Claude Code with notifications | macOS |

---

## 27. Voice & Speech Tools

| Name | URL | Description |
|------|-----|-------------|
| **VoiceMode MCP** | [GitHub](https://github.com/mbailey/voicemode) | VoiceMode MCP brings natural conversations to Claude Code |
| **stt-mcp-server-linux** | [GitHub](https://github.com/marcindulak/stt-mcp-server-linux) | Push-to-talk speech transcription MCP |
| **claude-code-voice** | [GitHub](https://github.com/mckaywrigley/claude-code-voice) | Hands-free voice control for macOS |
| **claude-code-voice-skill** | [GitHub](https://github.com/abracadabra50/claude-code-voice-skill) | Talk to Claude about projects over phone |

---

## 28. Notification & Communication

| Name | URL | Description |
|------|-----|-------------|
| **CC Notify** | [GitHub](https://github.com/dazuiba/CCNotify) | Desktop notifications for Claude Code with jump-back feature |
| **peon-ping** | [GitHub](https://github.com/PeonPing/peon-ping) | 2.4k stars. Warcraft III Peon voice notifications |
| **call-me** | [GitHub](https://github.com/ZeframLou/call-me) | Minimal plugin that lets Claude Code call you (phone) |
| **claude-blocker** | [GitHub](https://github.com/T3-Content/claude-blocker) | Block distracting websites during inference |

---

## 29. Transcript & Log Tools

| Name | URL | Stars | Description |
|------|-----|-------|-------------|
| **claude-code-transcripts** | [GitHub](https://github.com/simonw/claude-code-transcripts) | 733 | Tools for publishing Claude Code session transcripts (Simon Willison) |
| **cclogviewer** | [GitHub](https://github.com/Brads3290/cclogviewer) | - | Utility for viewing .jsonl conversation files |
| **claude-code-log** | [GitHub](https://github.com/daaain/claude-code-log) | 620 | Convert JSONL transcripts to HTML format |
| **cctrace** | [GitHub](https://github.com/jimmc414/cctrace) | 140 | Export Claude Code sessions to markdown/XML |
| **claude-prune** | [GitHub](https://github.com/DannyAziz/claude-prune) | 78 | Fast CLI tool for pruning old sessions |
| **claude-esp** | [GitHub](https://github.com/phiat/claude-esp) | - | Go-based TUI streaming Claude Code's hidden output |

---

## 30. Knowledge & Documentation Guides

| Name | URL | Description |
|------|-----|-------------|
| **Claude Code Ultimate Guide** | [GitHub](https://github.com/FlorianBruniaux/claude-code-ultimate-guide) | Tremendous documentation covering beginner to power user |
| **Claude Code Handbook** | [Website](https://nikiforovall.blog/claude-code-rules/) | Best practices with distributable plugins |
| **Claude Code System Prompts** | [GitHub](https://github.com/Piebald-AI/claude-code-system-prompts) | All parts of Claude Code's system prompt, updated per version |
| **Claude Code Documentation Mirror** | [GitHub](https://github.com/ericbuess/claude-code-docs) | Mirror of Anthropic docs, updated hourly |
| **claude-code-docs** (costiash) | [GitHub](https://github.com/costiash/claude-code-docs) | Mirror with full-text search and query-time updates |
| **Learn Claude Code** | [GitHub](https://github.com/shareAI-lab/learn-claude-code) | Analysis of agent design with minimal code reconstruction |
| **ClaudeLog** | [Website](https://claudelog.com/) | Docs, guides, tutorials, and best practices |
| **claudefa.st** | [Website](https://claudefa.st/) | Blog with curated MCP server guides and best practices |

---

## Summary Statistics

| Category | Count |
|----------|-------|
| Awesome Lists & Meta-Catalogs | 12 |
| Official Anthropic Tools | 8 |
| Agent Orchestrators | 18+ |
| Issue Trackers & Task Managers | 5 |
| MCP Servers (Essential) | 7 |
| MCP Servers (Database) | 5 |
| MCP Servers (Web/Search) | 4 |
| MCP Servers (Specialized) | 4 |
| UI/Browser Tools | 7 |
| Agent Skills (Tier 1) | 7 |
| Agent Skills (Tier 2) | 19 |
| Agent Skills (Tier 3) | 27 |
| Plugins & Plugin Registries | 17 |
| Session Management | 10 |
| Memory & Context Persistence | 10 |
| Cost Tracking & Usage Monitoring | 12 |
| Observability & Telemetry | 4 |
| IDE & Editor Integrations | 10 |
| GUI Clients & Desktop Apps | 5 |
| Docker & Sandboxing | 8 |
| Configuration & Framework Tools | 20 |
| Hooks & Hook Utilities | 12 |
| Status Lines & Terminal UI | 8 |
| Slash Commands | 5 |
| Workflow & Project Management | 13 |
| Code Quality & Review | 6 |
| CI/CD & GitHub Actions | 5 |
| Mobile & Remote Access | 6 |
| Voice & Speech | 4 |
| Notification & Communication | 4 |
| Transcript & Log Tools | 6 |
| Knowledge & Documentation | 8 |
| **Total unique tools/repos cataloged** | **~300+** |

---

## Highest Priority Tools for Hypebase AI

Based on relevance to this project (Next.js, Supabase, multi-agent teams, Docker dev):

1. **Beads** - Already in use. Git-backed issue tracker for agent memory
2. **Context7 MCP** - Already configured. Library docs in context
3. **React Grab** - Already integrated. UI element capture for frontend work
4. **Playwright MCP** - Already configured. E2E browser testing
5. **claude-squad** - Session management if running multiple parallel agents outside CC teams
6. **claude-mem** - Session continuity and memory compression
7. **claude-code-action** - GitHub PR review and CI integration
8. **ccusage** - Cost tracking and usage analysis
9. **Superpowers** - Comprehensive skills library for engineering workflows
10. **Docker Sandboxes** - Already using Docker dev; consider sandboxing for agent isolation
11. **claude-code-otel** - Observability if running agents at scale
12. **tdd-guard** - Automated TDD enforcement via hooks
13. **claude-code-safety-net** - Catches destructive commands
14. **Supabase Agent Skills** - Directly relevant to our Supabase stack
15. **next-skills** (Vercel) - Agent skills for Next.js workflows
