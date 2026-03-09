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

See [docs/optimization-framework.md](docs/optimization-framework.md) for the full scoring rubric and empirical validation methodology.
