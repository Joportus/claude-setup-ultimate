# CLAUDE.md -- claude-setup-ultimate

## Overview

A comprehensive 8-prompt sequence that configures any Claude Code installation to expert-level. Includes self-updating prompts, an automation shell script, research files, and synthesis docs.

**Stack:** Markdown/Shell | **Language:** Bash, Markdown | **Package Manager:** N/A (documentation project)

## Quick Start

```bash
# Run specific prompts manually by copy-pasting from:
cat prompts/core-setup-prompts.md      # Prompts 1-5
cat prompts/advanced-setup-prompts.md   # Prompts 6-8

# Or use the automation script:
bash prompts/setup-claude-ultimate.sh
bash prompts/setup-claude-ultimate.sh --verify-only
```

## Architecture

```
prompts/                    # User-facing prompt files (source of truth)
  core-setup-prompts.md     # Prompts 1-5: Discovery, Foundation, Hooks, Beads, Teams
  advanced-setup-prompts.md # Prompts 6-8: MCP, Optimization, Verification
  setup-claude-ultimate.sh  # Automation script that runs all prompts
synthesis/                  # Architecture and synthesis docs
  00-MASTER-SYNTHESIS.md    # Comprehensive synthesis of all research
  01-PROMPT-ARCHITECTURE.md # Design reference for prompt structure
raw/                        # Raw research files (12 files, 16K+ lines)
  01-beads-deep-dive.md     # through 12-security-permissions.md
REVIEW.md                   # Comprehensive review with issue tracking
meeting-analysis.md         # Meeting notes and enhancement integration
```

## Source of Truth Hierarchy

1. **Actual prompts** (`prompts/`) are the source of truth for all behavior
2. **Architecture doc** (`synthesis/01-PROMPT-ARCHITECTURE.md`) is the design reference -- must match prompts
3. **Raw research** (`raw/`) is reference material -- prompts take precedence if they diverge
4. When editing the architecture doc, always verify changes match the actual prompts

## Editing Conventions

- Prompts use plain text inside code fences (no markdown inside the fenced blocks)
- Shell scripts use `set -euo pipefail` and support `--yes` for non-interactive mode
- Hook scripts read JSON from stdin via `INPUT=$(cat)` and parse with `jq`
- Hook output for PreToolUse must use: `{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","reason":"..."}}`
- Timeout values in hook configs are in **milliseconds** (5000, 10000, 30000), not seconds
- MCP servers use HTTP transport where available (`--transport http`), stdio for local tools
- Beads install: `brew install steveyegge/tap/beads` (needs tap prefix)

## Quality Gates

| Check | Command |
|-------|---------|
| JSON validity | `jq . .claude/settings.json` |
| Hook executable | `test -x .claude/hooks/block-dangerous.sh` |
| Code fence balance | Count opening/closing fences are even per file |
| Cross-file consistency | Grep for key values (AUTOCOMPACT, TOOL_SEARCH) across all files |

## Testing

```bash
# Validate settings files
jq . .claude/settings.json && echo "PASS"
jq . .mcp.json && echo "PASS"

# Test dangerous command blocker
echo '{"tool_input":{"command":"rm -rf /"}}' | .claude/hooks/block-dangerous.sh
# Expected: JSON with permissionDecision: "deny"

echo '{"tool_input":{"command":"git status"}}' | .claude/hooks/block-dangerous.sh
# Expected: {}

# Check cross-file consistency
grep -rn 'AUTOCOMPACT.*"[0-9]*"' synthesis/ prompts/
# All should show "60"
```

## NEVER

- Never treat the architecture doc as source of truth over the actual prompts
- Never use `$schema` in settings.json examples (Claude Code settings don't use it)
- Never use tilde (`~`) in JSON env values -- use `$HOME` instead
- Never use seconds for hook timeouts -- always milliseconds
- Never use `@anthropic-ai/mcp-playwright` -- correct package is `@playwright/mcp@latest`
- Never use `*.lock` wildcard in .claudeignore -- list individual lock files

## ALWAYS

- Verify architecture doc matches actual prompts after any change to either
- Use `hookSpecificOutput` pattern for hook deny/allow output (not bare `{"decision":"block"}`)
- Use HTTP transport for MCP servers that support it (Context7, GitHub, Supabase, Sentry, etc.)
- Run the validation report after multi-file changes: check /tmp/claude-setup-validation-report.txt
- Keep env var values consistent across all files (architecture, prompts, synthesis)

## Self-Updating Rule

When you learn something useful from debugging, bugfixing, or implementing -- update this file immediately.

---

## Optimization Measurement Framework

### Purpose

This framework defines how to measure how well-optimized a Claude Code repository is. It provides quantitative metrics, qualitative scoring, and a validation methodology.

### A. Quantitative Metrics

| Metric | Target | How to Measure | Impact |
|--------|--------|----------------|--------|
| Shell startup time | < 100ms | `ZDOTDIR=~/.config/zsh-claude time zsh -i -c exit` | Compounds across 200-500 Bash calls/session |
| Permission prompts per session | 0 for normal ops | Count interruptions during a typical workflow | Each prompt breaks flow by 5-15 seconds |
| Hook execution overhead | < 500ms total | `time echo '{}' \| .claude/hooks/block-dangerous.sh` per hook | Runs on every tool use |
| .claudeignore effectiveness | > 80% reduction | Compare `find . -type f \| wc -l` vs files Claude actually scans | Saves 50-90% of token waste |
| Context utilization | Compact at 60% | Check `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` setting | Prevents quality degradation at high context |
| MCP server response time | < 2s first call | Test with a simple query after cold start | Slow MCP blocks entire tool pipeline |
| Time-to-first-action | < 30s | Measure from session start to first meaningful tool use | SessionStart hook + bd prime latency |
| Git status time | < 100ms | `time git status --short` | Called frequently by hooks and Claude |
| File descriptor limit | >= 10000 | `ulimit -n` | Low limits cause failures with many MCP servers |

### B. Qualitative Metrics (Scoring Rubric)

#### CLAUDE.md Completeness (0-20 points)

| Component | Points | Check |
|-----------|--------|-------|
| Project description | 2 | Has ## Overview with stack info |
| Quick start commands | 3 | Has install, dev, build, test commands |
| Architecture section | 3 | Lists directories with descriptions |
| NEVER rules | 3 | Has >= 3 specific prohibitions |
| ALWAYS rules | 3 | Has >= 3 specific requirements |
| Quality gates | 3 | Lists tools with run commands |
| Self-updating rule | 3 | Instructs Claude to update this file |

#### Settings Coverage (0-20 points)

| Component | Points | Check |
|-----------|--------|-------|
| User-level permissions | 4 | `~/.claude/settings.json` has allow + deny |
| Project-level permissions | 4 | `.claude/settings.json` has stack-specific rules |
| Deny rules for destructive ops | 4 | rm -rf, force push, hard reset blocked |
| Secret protection | 4 | .env, .aws/credentials in deny list |
| Agent teams enabled | 4 | CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 |

#### Hook Coverage (0-20 points)

| Component | Points | Check |
|-----------|--------|-------|
| Dangerous command blocking | 5 | PreToolUse hook with pattern matching |
| Auto-formatting | 4 | PostToolUse hook for Write/Edit/MultiEdit |
| Session start | 3 | SessionStart with git status + beads prime |
| Context compaction | 3 | PreCompact saves state |
| Notifications | 2 | Notification hook with OS detection |
| Session summary | 3 | Stop hook with modified files list |

#### Agent Team Readiness (0-20 points)

| Component | Points | Check |
|-----------|--------|-------|
| Agent definitions exist | 4 | >= 3 agents in .claude/agents/ with frontmatter |
| CLAUDE.md team section | 4 | DO/DO NOT rules, dual task system |
| TeammateIdle hook | 4 | Enforces beads closure before idle |
| TaskCompleted hook | 4 | Enforces beads closure before completion |
| Beads installed + initialized | 4 | `bd version` works, `.beads/` exists |

#### Security Posture (0-20 points)

| Component | Points | Check |
|-----------|--------|-------|
| Dangerous command deny rules | 5 | rm -rf, sudo rm, pipe-to-bash blocked |
| Secret file deny rules | 4 | .env, .aws/credentials, secrets/ blocked |
| Force push protection | 3 | git push --force denied |
| Hook input sanitization | 4 | Scripts handle malformed JSON gracefully |
| MCP permissions scoped | 4 | Only trusted MCP tools in allow list |

**Total: 100 points**

| Score | Rating |
|-------|--------|
| 90-100 | Excellent -- production-grade optimization |
| 70-89 | Good -- covers essentials, some gaps |
| 50-69 | Adequate -- basic protection, missing advanced features |
| 30-49 | Minimal -- significant gaps in coverage |
| 0-29 | Unconfigured -- needs full setup |

### C. Empirical Validation (the real test)

The static checks above measure **inputs** (does the config exist?) not **outcomes** (does it make Claude better?). The only way to know if a setup is actually good is to test it against real work.

#### Method: Comparative Task Evaluation

Take the same repo, the same task, and run it under different configurations. Compare the results.

#### Step 1: Pick Test Repositories

Choose 3-5 real repos that cover different stacks and complexities:

| Repo | Why |
|------|-----|
| A small CLI tool (Go/Rust/Python) | Tests basic code understanding, simple feature adds |
| A web app with tests (Next.js/Django/Rails) | Tests framework awareness, test-driven workflows |
| A monorepo with multiple packages | Tests navigation, cross-package understanding |
| A repo with existing CI/CD | Tests whether hooks conflict with existing quality gates |
| This repo (claude-setup-ultimate) | Meta-test: can it improve itself? |

#### Step 2: Define Standard Tasks

For each repo, define 3 repeatable tasks at different difficulty levels:

1. **Bug fix**: Find and fix a specific bug (real or planted). Measure: correctness, number of iterations, files touched unnecessarily.
2. **Feature add**: Add a small feature (e.g., "add a --verbose flag", "add input validation to this endpoint"). Measure: code quality, test coverage, adherence to project conventions.
3. **Refactor**: Refactor a specific module (e.g., "extract this into a utility function"). Measure: whether it preserved behavior, whether tests still pass, code cleanliness.

#### Step 3: Run Under Different Configurations

| Config | Description |
|--------|-------------|
| **Baseline** | Zero config. No CLAUDE.md, no settings, no hooks, no .claudeignore. Just `claude` in a raw repo. |
| **Minimal** | CLAUDE.md with project description + test commands. Nothing else. |
| **Standard** | CLAUDE.md + .claude/settings.json with permissions + .claudeignore. No hooks. |
| **Full** | Everything: CLAUDE.md, settings, hooks, agents, MCP servers, .claudeignore. The full 8-prompt setup. |
| **Over-engineered** | Full + excessive rules, 15 MCP servers, 50+ .claudeignore patterns, verbose CLAUDE.md. Tests whether more is actually worse. |

Use `git worktree` or fresh clones to isolate each run. Use `claude -p` (print mode) for reproducible non-interactive runs where possible.

#### Step 4: Score Results

For each task x config combination, score on:

| Criterion | Weight | How to evaluate |
|-----------|--------|-----------------|
| **Correctness** | 30% | Does the output actually work? Do tests pass? |
| **Efficiency** | 20% | How many tool calls / iterations did it take? How much context was consumed? |
| **Convention adherence** | 20% | Did it follow project patterns? (naming, file structure, test style) |
| **Safety** | 15% | Did it do anything destructive? Touch files it shouldn't have? |
| **Autonomy** | 15% | How many permission prompts / interruptions? Could it flow without intervention? |

#### Step 5: Analyze Patterns

Look for:
- **Where does config help most?** (usually: permissions reduce interruptions, CLAUDE.md improves convention adherence)
- **Where does config not matter?** (usually: simple bug fixes work fine without any config)
- **Where does config hurt?** (usually: over-engineered setups waste context on bloated CLAUDE.md, slow hooks)
- **Diminishing returns curve**: at what config level do scores plateau?

#### Expected Findings (hypotheses to test)

- Baseline -> Minimal is the biggest jump (CLAUDE.md with test commands is the single highest-value config)
- Minimal -> Standard is meaningful (permissions eliminate flow interruptions)
- Standard -> Full has diminishing returns (hooks add safety but don't change output quality much)
- Full -> Over-engineered is negative (wasted context, slower execution)
- The value of MCP servers depends entirely on whether the task needs external knowledge
- Agent teams only help for tasks that are genuinely parallelizable

#### Automation Script Sketch

```bash
#!/usr/bin/env bash
# comparative-eval.sh -- Run same task under different configs
REPO_URL="$1"           # repo to test
TASK_PROMPT="$2"        # task description
CONFIGS=("baseline" "minimal" "standard" "full")

for config in "${CONFIGS[@]}"; do
  WORKDIR=$(mktemp -d)
  git clone "$REPO_URL" "$WORKDIR/repo"

  # Apply config (copy from templates/)
  case "$config" in
    baseline) ;; # nothing
    minimal)  cp templates/minimal/CLAUDE.md "$WORKDIR/repo/" ;;
    standard) cp -r templates/standard/{CLAUDE.md,.claude,.claudeignore} "$WORKDIR/repo/" ;;
    full)     cp -r templates/full/{CLAUDE.md,.claude,.claudeignore,.mcp.json} "$WORKDIR/repo/" ;;
  esac

  # Run task, capture output and metrics
  cd "$WORKDIR/repo"
  START=$(date +%s%N)
  claude -p "$TASK_PROMPT" --output-format json > "$WORKDIR/result.json" 2>&1
  END=$(date +%s%N)

  # Extract metrics
  DURATION=$(( (END - START) / 1000000 ))
  TOOL_CALLS=$(jq '[.[] | select(.type == "tool_use")] | length' "$WORKDIR/result.json")

  echo "$config: ${DURATION}ms, $TOOL_CALLS tool calls"

  # Run project tests to check correctness
  # (detect and run: npm test, pytest, cargo test, go test, etc.)
done
```

This is a sketch -- a real implementation would need structured output parsing, test result capture, and a scoring aggregator. But the core idea is simple: same task, different configs, compare.

### D. Static Health Check (quick sanity check)

The empirical method above is the real validation. This static check is just a quick sanity pass:

```bash
# 1. Settings valid?
jq . ~/.claude/settings.json >/dev/null 2>&1 && echo "PASS: User settings" || echo "FAIL: User settings"
jq . .claude/settings.json >/dev/null 2>&1 && echo "PASS: Project settings" || echo "FAIL: Project settings"

# 2. CLAUDE.md exists with sections?
[ -f CLAUDE.md ] && echo "PASS: CLAUDE.md ($(grep -c '^##' CLAUDE.md) sections)" || echo "FAIL: No CLAUDE.md"

# 3. Hooks executable?
[ -d .claude/hooks ] && echo "PASS: $(find .claude/hooks -name '*.sh' -type f \( -perm -u+x -o -perm -g+x -o -perm -o+x \) | wc -l | tr -d ' ') executable hooks" || echo "FAIL: No hooks"

# 4. .claudeignore exists?
[ -f .claudeignore ] && echo "PASS: .claudeignore ($(grep -cv '^#\|^$' .claudeignore) patterns)" || echo "WARN: No .claudeignore"

# 5. Shell startup time?
STARTUP=$({ time zsh -i -c exit; } 2>&1 | grep real | awk '{print $2}')
echo "INFO: Shell startup: $STARTUP"
```

### E. Limitations and Honest Assessment

#### The Hard Truth About Measuring Optimization

Most "optimization scoring" is theater. Checking whether `.claudeignore` exists tells you nothing about whether Claude produces better code. The only honest measurement is **comparative task evaluation** (Section C above), and even that has confounds:

- **Non-determinism**: Claude doesn't produce identical output for identical inputs. You need multiple runs per config to get signal.
- **Task dependency**: A config that helps with React refactoring might not help with Go bug fixes. Results don't generalize across stacks easily.
- **Context matters**: A bloated CLAUDE.md hurts on small tasks (wastes context) but helps on large ones (provides guardrails). There's no single "best" config.
- **Human factor**: The biggest variable is the prompt, not the config. A good prompt with zero config beats a bad prompt with perfect config.

#### What We Know Works (high confidence)

- CLAUDE.md with test commands is the single highest-ROI config item
- Permission allow-lists eliminate interruptions (measurable: count prompts per session)
- .claudeignore reduces wasted file scanning (measurable: context usage)
- Dangerous command blocking prevents real mistakes (measurable: blocked command count)

#### What We Think Works (medium confidence, needs empirical testing)

- Hooks for auto-linting after edits
- MCP servers for documentation lookup (Context7)
- Agent teams for parallelizable work
- Pre-compaction state saving

#### Where Subjective Judgment Matters

- How many permission rules is "enough" vs "too restrictive"
- Whether agent definitions match the project's actual workflow
- Whether CLAUDE.md is helpful vs bloated (the 200-line truncation limit is real)
- Whether MCP servers add value or just token overhead (~600-800 tokens per server)

#### Diminishing Returns Thresholds

- Shell startup: below 50ms, further optimization has negligible impact
- .claudeignore: beyond 30 patterns, additional rules rarely match new files
- Permission rules: beyond 40 allow rules, complexity outweighs convenience
- Hooks: beyond 8 scripts, execution overhead starts to matter
- MCP servers: beyond 5-6, token overhead from tool definitions dominates
- CLAUDE.md: beyond 150 lines, context cost outweighs instruction value

The right amount of optimization is the minimum needed for your actual workflow. Three well-chosen hooks beat ten generic ones. And the only way to know if your setup is actually good is to test it on real tasks.
