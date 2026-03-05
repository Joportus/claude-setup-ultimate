# R8: Token Optimization and Cost Reduction Strategies

> Comprehensive guide to minimizing Claude Code token consumption and costs without reducing effectiveness.

---

## Table of Contents

1. [Model Pricing Reference](#1-model-pricing-reference)
2. [Cost Tracking Tools](#2-cost-tracking-tools)
3. [Context Window Management](#3-context-window-management)
4. [CLAUDE.md Optimization](#4-claudemd-optimization)
5. [Prompt Caching](#5-prompt-caching)
6. [Model Selection Strategies](#6-model-selection-strategies)
7. [Command Output Optimization](#7-command-output-optimization)
8. [Efficient Tool Use](#8-efficient-tool-use)
9. [Subagent Cost Management](#9-subagent-cost-management)
10. [Agent Team Cost Management](#10-agent-team-cost-management)
11. [Environment Variables for Cost Control](#11-environment-variables-for-cost-control)
12. [Prompt Engineering](#12-prompt-engineering)
13. [Hooks for Preprocessing](#13-hooks-for-preprocessing)
14. [Skills vs CLAUDE.md](#14-skills-vs-claudemd)
15. [.claudeignore Patterns](#15-claudeignore-patterns)
16. [External Token Tracking Tools](#16-external-token-tracking-tools)
17. [Workflow Patterns](#17-workflow-patterns)
18. [Subscription vs API Cost Comparison](#18-subscription-vs-api-cost-comparison)

---

## 1. Model Pricing Reference

### Current Pricing (March 2026)

| Model | Input (MTok) | Output (MTok) | Cache Write (5min) | Cache Write (1hr) | Cache Read | Batch Input | Batch Output |
|-------|-------------|---------------|-------------------|-------------------|------------|-------------|--------------|
| **Opus 4.6** | $5 | $25 | $6.25 | $10 | $0.50 | $2.50 | $12.50 |
| **Sonnet 4.6** | $3 | $15 | $3.75 | $6 | $0.30 | $1.50 | $7.50 |
| **Haiku 4.5** | $1 | $5 | $1.25 | $2 | $0.10 | $0.50 | $2.50 |
| **Opus 4.6 Fast** | $30 | $150 | - | - | - | N/A | N/A |

*(MTok = per million tokens)*

### Long Context Premium (>200K input tokens)

| Model | Input | Output |
|-------|-------|--------|
| Opus 4.6 | $10/MTok (2x) | $37.50/MTok (1.5x) |
| Sonnet 4.6 | $6/MTok (2x) | $22.50/MTok (1.5x) |

### Key Cost Ratios

- **Opus vs Sonnet**: Opus costs ~1.67x more for input, ~1.67x more for output
- **Sonnet vs Haiku**: Sonnet costs 3x more for input, 3x more for output
- **Opus vs Haiku**: Opus costs 5x more for input, 5x more for output
- **Cache read vs standard input**: 10x cheaper (90% savings)
- **Batch API**: 50% discount on all models

### Tool Use Overhead

Each tool definition adds tokens to every request:

| Tool | Additional Input Tokens |
|------|------------------------|
| Tool use system prompt | 346 tokens (auto/none), 313 tokens (any/tool) |
| Text editor tool | 700 tokens |
| Bash tool | 245 tokens |

### Average Cost Benchmarks

- Average cost: **$6 per developer per day**
- 90th percentile: under **$12 per day**
- Monthly average with Sonnet: **$100-200 per developer**
- Background token usage: typically under **$0.04 per session**

Sources:
- [Official Pricing](https://platform.claude.com/docs/en/about-claude/pricing)
- [Cost Management Docs](https://code.claude.com/docs/en/costs)

---

## 2. Cost Tracking Tools

### Built-in: `/cost` Command

Shows API token usage statistics for the current session:

```
Total cost:            $0.55
Total duration (API):  6m 19.7s
Total duration (wall): 6h 33m 10.2s
Total code changes:    0 lines added, 0 lines removed
```

- For API users only (not relevant for Claude Max/Pro subscribers)
- Subscribers use `/stats` for usage patterns

### Built-in: `/context` Command

Shows what is consuming context space, categorized by type. Useful for identifying which MCP servers, files, or tools are wasting tokens.

### Built-in: Status Line

Configure a persistent display at the bottom of Claude Code showing real-time token usage:

```bash
/statusline show the model name and context usage percentage
```

The status line receives JSON data via stdin containing:
- `context_window.used_percentage` - percentage of context consumed (input tokens only)
- `context_window.current_usage` - current token counts
- Model name, costs, git status, etc.

Setup in settings.json:
```json
{
  "statusLine": {
    "command": "~/.claude/statusline.sh"
  }
}
```

### Workspace Spend Limits (Teams)

- Set workspace spend limits in [Claude Console](https://platform.claude.com)
- View cost and usage reporting per workspace
- "Claude Code" workspace auto-created on first auth

### Rate Limit Recommendations (Teams)

| Team Size | TPM per User | RPM per User |
|-----------|-------------|-------------|
| 1-5 | 200k-300k | 5-7 |
| 5-20 | 100k-150k | 2.5-3.5 |
| 20-50 | 50k-75k | 1.25-1.75 |
| 50-100 | 25k-35k | 0.62-0.87 |
| 100-500 | 15k-20k | 0.37-0.47 |
| 500+ | 10k-15k | 0.25-0.35 |

Sources:
- [Cost Management Docs](https://code.claude.com/docs/en/costs)
- [Status Line Docs](https://code.claude.com/docs/en/statusline)

---

## 3. Context Window Management

### How Context Works

Claude's context window holds your entire conversation: every message, every file read, every command output. Context fills up fast -- a single debugging session can consume tens of thousands of tokens. LLM performance degrades as context fills.

**This is the single most important resource to manage.**

### Auto-Compaction

- Triggers at approximately **95% capacity** by default (configurable)
- Automatically summarizes conversation history
- Preserves important code, decisions, and file states
- Can be customized with CLAUDE.md instructions:

```markdown
# Compact instructions
When you are using compact, please focus on test output and code changes
```

### Manual Compaction

```
/compact                              # Basic compaction
/compact Focus on code samples        # Directed compaction preserving specific content
/compact Focus on API changes         # Preserve API-related context
```

Best practice: compact manually at logical breakpoints rather than hitting limits mid-task.

### Partial Compaction via Rewind

- `Esc + Esc` or `/rewind` opens rewind menu
- Select a message checkpoint
- Choose **"Summarize from here"** to compact only messages after that point
- Keeps earlier context intact while trimming recent verbose output

### Context Reset

```
/clear                # Full context reset between unrelated tasks
/rename oauth-work    # Name session before clearing for later reference
/resume               # Return to a named session
```

**Critical rule**: Use `/clear` between unrelated tasks. Stale context wastes tokens on every subsequent message.

### PreCompact Hooks

Preserve critical state before compaction:
```json
{
  "hooks": {
    "PreCompact": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bd sync"
          }
        ]
      }
    ]
  }
}
```

### Multi-Session Strategy

Run multiple Claude Code instances simultaneously on the same project. Each session has its own 200k-token window -- this is horizontal scaling of context.

Sources:
- [Best Practices](https://code.claude.com/docs/en/best-practices)
- [Cost Management](https://code.claude.com/docs/en/costs)

---

## 4. CLAUDE.md Optimization

### Size Guidelines

- **Target: under 500 lines** (official recommendation)
- CLAUDE.md loads into context at EVERY session start
- Every line costs tokens on every single message
- A bloated CLAUDE.md causes Claude to ignore your actual instructions

### What to Include

| Include | Exclude |
|---------|---------|
| Bash commands Claude can't guess | Anything Claude can figure out by reading code |
| Code style rules differing from defaults | Standard language conventions Claude already knows |
| Testing instructions and preferred runners | Detailed API documentation (link instead) |
| Repository etiquette (branch naming, PRs) | Information that changes frequently |
| Architectural decisions specific to project | Long explanations or tutorials |
| Developer environment quirks | File-by-file descriptions of the codebase |
| Common gotchas or non-obvious behaviors | Self-evident practices like "write clean code" |

### Optimization Techniques

1. **Bullet points over paragraphs**: More concise, same information
2. **One example per concept**: Not three
3. **Reference file paths** instead of embedding full contents
4. **Use `@path/to/file` imports** for modular loading:
   ```markdown
   See @README.md for overview and @package.json for npm commands.
   # Additional Instructions
   - Git workflow: @docs/git-instructions.md
   ```
5. **Hierarchical CLAUDE.md files**: Child directory CLAUDE.md files only load when Claude works in that directory
6. **Regular pruning**: If Claude already does something correctly without the instruction, delete it

### Tiered Loading Architecture (claude-token-optimizer)

A project called [claude-token-optimizer](https://github.com/nadimtuhin/claude-token-optimizer) demonstrates reducing session-start tokens from 11,000 to 1,300 (~90% reduction):

```
project-root/
├── CLAUDE.md              # Essential (~800 tokens total)
├── .claudeignore           # Prevents unwanted auto-loading
├── .claude/
│   ├── COMMON_MISTAKES.md  # Only bugs requiring >1hr to debug
│   ├── QUICK_START.md      # Frequently-used commands
│   ├── ARCHITECTURE_MAP.md # Project structure overview
│   ├── completions/        # Archived tasks (on-demand)
│   └── sessions/           # Historical context (on-demand)
└── docs/learnings/         # Topic-specific files (~500 tokens each)
```

### Emphasis for Adherence

Add emphasis to critical rules: "IMPORTANT", "YOU MUST", "NEVER", "ALWAYS" -- improves adherence to rules that Claude tends to ignore.

Sources:
- [Best Practices](https://code.claude.com/docs/en/best-practices)
- [claude-token-optimizer](https://github.com/nadimtuhin/claude-token-optimizer)

---

## 5. Prompt Caching

### How It Works in Claude Code

Claude Code automatically enables prompt caching. It places cache breakpoints on:
1. The system prompt
2. Tool definitions
3. CLAUDE.md content
4. Conversation history up to the most recent messages

The breakpoint slides forward each turn to include the latest assistant response (auto-caching).

### Cost Impact

| Operation | Cost vs Standard | TTL |
|-----------|-----------------|-----|
| 5-minute cache write | 1.25x base input | 5 minutes |
| 1-hour cache write | 2x base input | 1 hour |
| Cache read (hit) | 0.1x base input (90% savings) | Same as write |

**Break-even**: 5-min cache pays off after 1 read. 1-hour cache pays off after 2 reads.

### Real Impact Example

Without prompt caching: a long Opus coding session (100 turns with compaction cycles) costs **$50-100** in input tokens.
With prompt caching: **$10-19** -- a 5-10x reduction.

### Configuration

```bash
# Disable prompt caching entirely (NOT recommended)
export DISABLE_PROMPT_CACHING=1

# Disable only for Haiku models
export DISABLE_PROMPT_CACHING_HAIKU=1
```

**Recommendation**: Keep prompt caching enabled (default). It's one of the biggest automatic cost savers.

### Optimization Strategy

- Keep system prompts and tool definitions stable across turns (they get cached)
- Don't change CLAUDE.md mid-session (invalidates cache)
- Longer conversations benefit more from caching (amortizes write cost)

Sources:
- [Prompt Caching Docs](https://platform.claude.com/docs/en/build-with-claude/prompt-caching)
- [Claude Code Camp](https://www.claudecodecamp.com/p/how-prompt-caching-actually-works-in-claude-code)

---

## 6. Model Selection Strategies

### When to Use Each Model

| Model | Use For | Cost Profile |
|-------|---------|--------------|
| **Opus 4.6** | Complex architecture decisions, multi-step reasoning, difficult debugging | $5/$25 per MTok |
| **Sonnet 4.6** | 80% of coding tasks: implementation, refactoring, routine coding | $3/$15 per MTok |
| **Haiku 4.5** | Quick validation, formatting, simple queries, subagent exploration | $1/$5 per MTok |

### Switching Models

```
/model          # Switch model mid-session
/config         # Set default model
```

### Per-Subagent Model Selection

```yaml
---
name: code-reviewer
model: sonnet    # Use cheaper model for this subagent
---
```

The built-in Explore subagent already uses Haiku by default for fast, cheap codebase exploration.

### Cost Savings from Model Selection

- Using Sonnet instead of Opus for routine tasks: **40% savings** on input, **40% on output**
- Using Haiku for simple subagent tasks: **67% savings** vs Sonnet, **80%** vs Opus
- The "80/20 rule": Sonnet handles 80% of work at 60% of Opus cost

### Effort Level (Opus 4.6 & Sonnet 4.6)

Effort level controls thinking depth and token consumption:

```bash
export CLAUDE_CODE_EFFORT_LEVEL=medium  # low | medium | high
```

- **low**: Faster, cheaper, less deep reasoning
- **medium**: Balanced
- **high**: Maximum reasoning depth (default for complex tasks)

Lower effort = fewer thinking tokens = lower cost for simple tasks.

Sources:
- [Cost Management](https://code.claude.com/docs/en/costs)
- [Model Config](https://code.claude.com/docs/en/model-config)

---

## 7. Command Output Optimization

### Git Flags That Reduce Output

```bash
git status --short              # Compact status (vs verbose default)
git log --oneline -10           # One line per commit, last 10
git diff --stat                 # Summary only, not full diff
git diff --name-only            # Just filenames changed
git diff --name-status          # Filenames + change type (M/A/D)
git log --no-stat               # Skip diffstat in log
git commit --quiet              # Suppress verbose output
git push --quiet                # Suppress transfer output
```

### Package Manager Flags

```bash
bun install --silent            # Suppress installation output
npm install --silent            # Suppress installation output
npm test --silent               # Suppress test runner chrome
```

### Search Flags

```bash
grep --files-with-matches       # Only filenames, not matching lines
grep -c                         # Count matches only
grep -l                         # List filenames only
```

### Docker Flags

```bash
docker ps --format "{{.Names}}: {{.Status}}"  # Only needed fields
docker logs --tail 50           # Last 50 lines only
```

### General CLI Principles

1. Use `--quiet` / `--silent` / `-q` when available
2. Use `--format` to get only needed fields
3. Pipe through `| head -N` to limit output
4. Use `| tail -N` for recent entries only
5. Use `| wc -l` when you only need counts
6. Prefer structured output (`--json`) when parsing is needed

### Claude Code Specific

- Use Read tool with `offset` and `limit` for large files instead of reading entire file
- Use Glob instead of `find` (native, structured, fewer tokens)
- Use Grep instead of `grep`/`rg` (native, structured output)
- Use Read instead of `cat` (numbered lines, more structured)
- Use Write instead of `echo`/heredoc (native tool)

Sources:
- [Best Practices](https://code.claude.com/docs/en/best-practices)

---

## 8. Efficient Tool Use

### Native Tools vs Bash

| Task | Use This (Native) | Not This (Bash) | Why |
|------|-------------------|-----------------|-----|
| Read files | `Read` tool | `cat`, `head`, `tail` | Structured numbered output |
| Search files | `Glob` tool | `find`, `ls` | Pattern matching, sorted results |
| Search content | `Grep` tool | `grep`, `rg` | Structured, fewer tokens |
| Write files | `Write` tool | `echo`, heredoc | Direct, no shell overhead |
| Edit files | `Edit` tool | `sed`, `awk` | Diff-based, minimal tokens |

### Parallel Tool Calls

Make independent tool calls in parallel, not sequential. This reduces round trips:

```
# Good: 3 independent reads in parallel (1 round trip)
Read file1.ts, Read file2.ts, Read file3.ts

# Bad: 3 sequential reads (3 round trips)
Read file1.ts → Read file2.ts → Read file3.ts
```

### When to Use Subagents vs Direct Tools

| Scenario | Approach | Why |
|----------|----------|-----|
| Quick file lookup | Direct Glob/Grep | Faster, no subagent overhead |
| Deep codebase exploration | Explore subagent | Keeps exploration out of main context |
| Running tests | Subagent | Verbose output stays in subagent context |
| Fetching docs | Subagent | Large content isolated from main context |
| Simple file edit | Direct Edit | No overhead |
| Complex multi-file change | Main conversation | Needs context of all changes |

### MCP Server Token Overhead

Each MCP server adds tool definitions to context, even when idle:
- Run `/context` to see what's consuming space
- Run `/mcp` to see and disable unused servers
- **Prefer CLI tools** when available: `gh`, `aws`, `gcloud`, `sentry-cli` are more context-efficient

### Tool Search Threshold

When MCP tool descriptions exceed 10% of context, Claude Code auto-defers them:

```bash
# Lower threshold to save more context
export ENABLE_TOOL_SEARCH=auto:5    # Trigger at 5% instead of 10%
```

Deferred tools only enter context when actually used.

### Code Intelligence Plugins

Install language server plugins for typed languages. A single "go to definition" call replaces grep + reading multiple candidate files. Catches type errors automatically after edits without running compiler.

Sources:
- [Cost Management](https://code.claude.com/docs/en/costs)
- [Sub-agents Docs](https://code.claude.com/docs/en/sub-agents)

---

## 9. Subagent Cost Management

### How Subagents Affect Tokens

Each subagent runs in its own context window. The verbose output stays in the subagent's context while only a summary returns to your main conversation.

### Built-in Subagent Models

| Subagent | Default Model | Token Impact |
|----------|--------------|--------------|
| Explore | Haiku (cheapest) | Read-only, fast |
| Plan | Inherits parent | Research only |
| General-purpose | Inherits parent | Full capabilities |
| Claude Code Guide | Haiku | Questions about CC features |

### Cost Optimization Patterns

1. **Isolate high-volume operations**: Tests, logs, doc fetching
   ```
   Use a subagent to run the test suite and report only failing tests
   ```

2. **Parallel research**: Multiple independent investigations
   ```
   Research auth, database, and API modules in parallel using separate subagents
   ```

3. **Route to cheaper models**: Set `model: haiku` for simple subagents
   ```yaml
   ---
   name: file-finder
   model: haiku
   tools: Read, Grep, Glob
   ---
   ```

4. **Resume instead of restart**: Subagents retain full history when resumed
   ```
   Continue that code review and now analyze the authorization logic
   ```

5. **Background subagents**: Run concurrently while you continue working (`Ctrl+B`)

### Auto-Compaction for Subagents

Subagents support the same auto-compaction as main conversation:
```bash
# Compact subagents earlier
export CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=50
```

### Warning: Subagent Result Size

When many subagents return detailed results, the summaries can consume significant main context. Keep return summaries focused.

Sources:
- [Sub-agents Docs](https://code.claude.com/docs/en/sub-agents)

---

## 10. Agent Team Cost Management

### Token Scaling

Agent teams use approximately **7x more tokens** than standard sessions when teammates run in plan mode:
- Each teammate maintains its own context window
- Each teammate runs as a separate Claude instance
- Token usage is roughly proportional to team size

### Cost Reduction Strategies

1. **Use Sonnet for teammates** (not Opus): Balances capability and cost
2. **Keep teams small**: 3-5 teammates max; coordination overhead scales quadratically
3. **Keep spawn prompts focused**: Everything in the prompt adds to context from the start
4. **Clean up teams when done**: Active teammates consume tokens even if idle
5. **Keep tasks small and self-contained**: Limits per-teammate token usage

### Broadcast Warning

Broadcasting sends a separate message to EVERY teammate:
- N teammates = N separate message deliveries
- Each delivery consumes API resources
- Use `message` (DM) instead of `broadcast` whenever possible

### Team Size Guidance

- **3-5 teammates** for most workflows
- **5-6 tasks per teammate** keeps everyone productive
- Three focused teammates outperform five scattered ones
- Never exceed 5 without explicit justification

Sources:
- [Agent Teams](https://code.claude.com/docs/en/agent-teams)
- [Cost Management](https://code.claude.com/docs/en/costs)

---

## 11. Environment Variables for Cost Control

### Token & Context Management

| Variable | Default | Purpose |
|----------|---------|---------|
| `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` | ~95% | Trigger compaction earlier (e.g., `50`) |
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS` | 32,000 | Max output tokens (max: 64,000). Higher = less context |
| `CLAUDE_CODE_FILE_READ_MAX_OUTPUT_TOKENS` | - | Override token limit for file reads |
| `MAX_THINKING_TOKENS` | 31,999 | Budget for extended thinking (output tokens) |

### Model & Reasoning

| Variable | Default | Purpose |
|----------|---------|---------|
| `CLAUDE_CODE_EFFORT_LEVEL` | - | `low`, `medium`, or `high` reasoning depth |
| `CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING` | - | Set to `1` to use fixed thinking budget |

### Cost Reduction

| Variable | Default | Purpose |
|----------|---------|---------|
| `DISABLE_PROMPT_CACHING` | - | Set to `1` to disable caching (NOT recommended) |
| `DISABLE_PROMPT_CACHING_HAIKU` | - | Set to `1` to disable caching for Haiku only |
| `DISABLE_NON_ESSENTIAL_MODEL_CALLS` | - | Set to `1` to skip non-essential generation (flavor text) |
| `ENABLE_TOOL_SEARCH` | `auto:10` | Lower threshold (e.g., `auto:5`) to defer more tools |

### Background Tasks

| Variable | Default | Purpose |
|----------|---------|---------|
| `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS` | - | Set to `1` to disable all background task functionality |

### Configuration in settings.json

```json
{
  "env": {
    "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "50",
    "DISABLE_NON_ESSENTIAL_MODEL_CALLS": "1",
    "CLAUDE_CODE_EFFORT_LEVEL": "medium",
    "ENABLE_TOOL_SEARCH": "auto:5"
  }
}
```

Sources:
- [Settings Docs](https://code.claude.com/docs/en/settings)
- [Cost Management](https://code.claude.com/docs/en/costs)

---

## 12. Prompt Engineering

### Specific Prompts Save Tokens

| Vague (Expensive) | Specific (Cheap) |
|-------------------|------------------|
| "improve this codebase" | "add input validation to the login function in auth.ts" |
| "fix the login bug" | "users report login fails after session timeout. Check auth flow in src/auth/, especially token refresh" |
| "add tests for foo.py" | "write a test for foo.py covering the edge case where user is logged out. Avoid mocks." |
| "make the dashboard look better" | "[paste screenshot] implement this design. Take a screenshot and compare" |

### Prompt Structure for Efficiency

1. **Front-load requirements**: Comprehensive first prompt > five refinement exchanges
2. **Set output constraints**: Request brief answers or specific formats
3. **Batch related work**: Create functions with tests together in single sessions
4. **Include verification targets**: Test cases, screenshots, expected output
5. **Scope investigations**: "Check src/auth/" not "investigate the codebase"

### The Interview Pattern (for Large Features)

```
I want to build [brief description]. Interview me in detail using the
AskUserQuestion tool. Ask about technical implementation, UI/UX, edge
cases, concerns, and tradeoffs. Keep interviewing until we've covered
everything, then write a complete spec to SPEC.md.
```

Then start a fresh session to execute the spec -- clean context, focused implementation.

### Correction Strategy

- If Claude goes wrong, press `Esc` to stop immediately
- After 2 failed corrections, `/clear` and write a better initial prompt
- A clean session with a better prompt always outperforms accumulated corrections

Sources:
- [Best Practices](https://code.claude.com/docs/en/best-practices)

---

## 13. Hooks for Preprocessing

### Why Hooks Save Tokens

Instead of Claude reading a 10,000-line log file, a hook can `grep` for errors and return only matching lines. This reduces context from tens of thousands of tokens to hundreds.

### Example: Filter Test Output to Failures Only

**settings.json**:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/filter-test-output.sh"
          }
        ]
      }
    ]
  }
}
```

**filter-test-output.sh**:
```bash
#!/bin/bash
input=$(cat)
cmd=$(echo "$input" | jq -r '.tool_input.command')

# If running tests, filter to show only failures
if [[ "$cmd" =~ ^(npm test|pytest|go test|bun test) ]]; then
  filtered_cmd="$cmd 2>&1 | grep -A 5 -E '(FAIL|ERROR|error:)' | head -100"
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"allow\",\"updatedInput\":{\"command\":\"$filtered_cmd\"}}}"
else
  echo "{}"
fi
```

### Other Preprocessing Ideas

- Filter Docker logs to show only errors
- Truncate git diff output to first N lines per file
- Summarize long API responses before they enter context
- Strip verbose npm/bun install output

Sources:
- [Cost Management](https://code.claude.com/docs/en/costs)
- [Hooks Docs](https://code.claude.com/docs/en/hooks)

---

## 14. Skills vs CLAUDE.md

### Why Move Content to Skills

CLAUDE.md loads at EVERY session start. Skills load on-demand only when invoked.

**Move to skills**:
- PR review workflows
- Database migration procedures
- Deployment checklists
- Framework-specific patterns
- Testing methodologies

**Keep in CLAUDE.md**:
- Build commands
- Code style rules
- Project structure essentials
- Common gotchas that apply to ALL work

### Savings Calculation

If your CLAUDE.md has 1,000 lines of specialized instructions:
- At ~4 tokens/word, ~10 words/line: ~40,000 tokens loaded every session
- Moving 60% to skills: ~24,000 tokens saved per session start
- Over 50 messages: 24,000 * 50 = 1.2M tokens saved
- At Sonnet rates ($3/MTok): ~$3.60 saved per session

### Skill Example

```markdown
# .claude/skills/pr-review/SKILL.md
---
name: pr-review
description: Review pull requests following team conventions
---

## PR Review Checklist
1. Check for breaking changes
2. Verify test coverage
3. Check for security issues
...
```

Sources:
- [Cost Management](https://code.claude.com/docs/en/costs)
- [Skills Docs](https://code.claude.com/docs/en/skills)

---

## 15. .claudeignore Patterns

### What to Ignore

`.claudeignore` works like `.gitignore`. Generated files often consume more than 50,000 tokens each:

```gitignore
# Build outputs
dist/
build/
.next/
out/
.nuxt/

# Dependencies
node_modules/
vendor/
.venv/

# Lock files (30,000-80,000 tokens each!)
package-lock.json
yarn.lock
pnpm-lock.yaml
bun.lockb
composer.lock
Gemfile.lock
poetry.lock

# Generated/compiled
*.min.js
*.min.css
*.bundle.js
*.chunk.js
*.map
*.d.ts

# Coverage and test output
coverage/
.nyc_output/
__snapshots__/

# Data and binary files
*.sqlite
*.db
*.csv
*.parquet

# IDE and OS
.idea/
.vscode/
*.swp
.DS_Store

# Docker volumes
docker-data/

# Large documentation
docs/api-reference/generated/
```

### Token Savings Example

| File | Approximate Tokens |
|------|-------------------|
| `package-lock.json` | 30,000 - 80,000 |
| `bundle.js` (compiled) | 100,000+ |
| `node_modules/` (any file) | Variable, huge |
| Coverage reports | 10,000 - 50,000 |

A well-configured `.claudeignore` can save **50-90% of tokens** that would be wasted on generated files.

Sources:
- [12 Proven Techniques](https://aslamdoctor.com/12-proven-techniques-to-save-tokens-in-claude-code/)
- [Token Optimizer](https://github.com/nadimtuhin/claude-token-optimizer)

---

## 16. External Token Tracking Tools

### ccusage

The most popular token tracking tool for Claude Code. Analyzes JSONL files locally.

**Installation**:
```bash
npx ccusage@latest          # Run without installing
bunx ccusage                # Using Bun
```

**Commands**:
```bash
npx ccusage daily           # Daily token usage
npx ccusage monthly         # Monthly aggregated
npx ccusage session         # Session-grouped usage
npx ccusage blocks          # 5-hour billing windows
npx ccusage statusline      # Compact status line output
```

**Options**:
```bash
--json                      # JSON output
--breakdown                 # Per-model cost breakdown
--compact                   # Force compact layout
--offline                   # Use pre-cached pricing
--since 2026-03-01          # Date filtering
--until 2026-03-05
--timezone America/Vancouver
--instances                 # Multi-instance grouping
```

**Features**:
- 11.2k stars on GitHub
- Daily, monthly, session-based reports
- 5-hour billing window tracking
- Model identification and per-model cost breakdown
- Cache token tracking (creation and read separately)
- Status line integration
- JSON export

**Repo**: [github.com/ryoppippi/ccusage](https://github.com/ryoppippi/ccusage)

### Claude-Code-Usage-Monitor

Real-time terminal monitoring tool with ML-based predictions.

**Features**:
- Real-time token consumption tracking
- Burn rate analysis
- Cost analysis
- Intelligent predictions about session limits

**Repo**: [github.com/Maciek-roboblog/Claude-Code-Usage-Monitor](https://github.com/Maciek-roboblog/Claude-Code-Usage-Monitor)

### ccstatusline

Customizable status line for Claude Code with Powerline support.

**Features**:
- Model name, git branch, token usage display
- Session duration, block timer
- Powerline-style rendering
- Multi-line support
- Themes

**Repo**: [github.com/sirmalloc/ccstatusline](https://github.com/sirmalloc/ccstatusline)

### LiteLLM (Enterprise)

Open-source proxy for tracking spend by key. Used by large enterprises on Bedrock, Vertex, and Foundry where Claude Code doesn't send metrics from your cloud.

**Docs**: [docs.litellm.ai](https://docs.litellm.ai/docs/proxy/virtual_keys#tracking-spend)

Sources:
- [ccusage](https://github.com/ryoppippi/ccusage)
- [Claude-Code-Usage-Monitor](https://github.com/Maciek-roboblog/Claude-Code-Usage-Monitor)
- [ccstatusline](https://github.com/sirmalloc/ccstatusline)

---

## 17. Workflow Patterns

### The "Kitchen Sink" Anti-Pattern

**Problem**: Start with one task, ask something unrelated, go back. Context fills with irrelevant information.
**Fix**: `/clear` between unrelated tasks.

### The "Correction Loop" Anti-Pattern

**Problem**: Claude does something wrong, you correct, still wrong, correct again. Context polluted with failed approaches.
**Fix**: After 2 failed corrections, `/clear` and write a better initial prompt.

### The "Infinite Exploration" Anti-Pattern

**Problem**: Ask Claude to "investigate" without scoping. Claude reads hundreds of files.
**Fix**: Scope narrowly or use subagents.

### Plan-First Workflow

1. **Explore**: Plan Mode -- Claude reads files, answers questions
2. **Plan**: Create detailed implementation plan
3. **Implement**: Switch to Normal Mode, execute against plan
4. **Commit**: Descriptive message and PR

Skip planning for simple/obvious tasks.

### Session Handoff Pattern

Before starting fresh:
1. `/compact Focus on [key aspects]`
2. Log summaries to `docs/progress.md`
3. `/clear` to reset
4. New session loads only `CLAUDE.md` + `docs/progress.md`

### Writer/Reviewer Pattern

| Session A (Writer) | Session B (Reviewer) |
|-------------------|---------------------|
| Implement feature | Review implementation |
| Address feedback | Verify fixes |

Fresh context in reviewer session prevents bias toward code just written.

### Fan-Out Pattern for Migrations

```bash
for file in $(cat files.txt); do
  claude -p "Migrate $file from React to Vue. Return OK or FAIL." \
    --allowedTools "Edit,Bash(git commit *)"
done
```

Test on 2-3 files first, then scale to full set.

### Incremental Testing

Write one file, test it, then continue. Catches issues early when cheap to fix.

Sources:
- [Best Practices](https://code.claude.com/docs/en/best-practices)

---

## 18. Subscription vs API Cost Comparison

### Plans

| Plan | Monthly Cost | Included | Best For |
|------|-------------|----------|----------|
| Claude Pro | $20 | Moderate CC usage | Light users |
| Claude Max 5x | $100 | 5x Pro usage | Moderate daily users |
| Claude Max 20x | $200 | 20x Pro usage | Heavy daily users |
| API (Pay-per-use) | Variable | Pay per token | Automation, CI/CD, teams |

### Break-Even Analysis

- Light users (few uses/month): API is cheaper ($5-15/month typical)
- Moderate users (~$15-20/month API cost): Pro plan ($20) breaks even
- Heavy daily users: Max 5x ($100) or Max 20x ($200) provides predictable costs
- Teams: API with workspace spend limits for per-developer control

### API Cost Control for Teams

- Set workspace spend limits in Console
- Use rate limit recommendations (see Section 2)
- LiteLLM proxy for Bedrock/Vertex/Foundry cost tracking
- Small pilot group first to establish usage patterns

Sources:
- [Cost Management](https://code.claude.com/docs/en/costs)
- [thecaio.ai Cost Guide](https://www.thecaio.ai/blog/reduce-claude-code-costs)

---

## Quick Reference: Top 10 Highest-Impact Strategies

1. **Use Sonnet for 80% of work** -- 40% savings vs Opus
2. **Configure `.claudeignore`** -- 50-90% savings on generated file tokens
3. **`/clear` between tasks** -- eliminates stale context waste
4. **Keep CLAUDE.md under 500 lines** -- move specialized content to skills
5. **Use subagents for verbose operations** -- isolates test output, logs, docs
6. **Prompt caching** (auto-enabled) -- 90% savings on cached input reads
7. **Specific prompts** -- "fix auth.ts line 42" not "fix the login bug"
8. **Lower thinking budget for simple tasks** -- `CLAUDE_CODE_EFFORT_LEVEL=low`
9. **Disable unused MCP servers** -- each adds tool definitions to every request
10. **Use hooks to preprocess** -- filter test output, log files before they enter context

---

## Sources

- [Official Cost Management](https://code.claude.com/docs/en/costs)
- [Official Best Practices](https://code.claude.com/docs/en/best-practices)
- [Official Sub-agents](https://code.claude.com/docs/en/sub-agents)
- [Official Settings](https://code.claude.com/docs/en/settings)
- [Official Status Line](https://code.claude.com/docs/en/statusline)
- [Official Pricing](https://platform.claude.com/docs/en/about-claude/pricing)
- [Prompt Caching](https://platform.claude.com/docs/en/build-with-claude/prompt-caching)
- [ccusage](https://github.com/ryoppippi/ccusage)
- [claude-token-optimizer](https://github.com/nadimtuhin/claude-token-optimizer)
- [Claude-Code-Usage-Monitor](https://github.com/Maciek-roboblog/Claude-Code-Usage-Monitor)
- [ccstatusline](https://github.com/sirmalloc/ccstatusline)
- [12 Proven Techniques](https://aslamdoctor.com/12-proven-techniques-to-save-tokens-in-claude-code/)
- [Stop Wasting Tokens (Medium)](https://medium.com/@jpranav97/stop-wasting-tokens-how-to-optimize-claude-code-context-by-60-bfad6fd477e5)
- [Reduce Claude Code Costs Guide](https://www.thecaio.ai/blog/reduce-claude-code-costs)
- [Claude Code Pricing Guide](https://claudefa.st/blog/guide/development/usage-optimization)
- [Token Workflow Gist](https://gist.github.com/dholdaway/8009f089d3407e14f3d753f2a70eb63e)
- [Claude Code Tips (45 tips)](https://github.com/ykdojo/claude-code-tips)
- [SFEIR Context Management](https://institute.sfeir.com/en/claude-code/claude-code-context-management/optimization/)
- [LiteLLM](https://docs.litellm.ai/docs/proxy/virtual_keys#tracking-spend)
