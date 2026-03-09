---
name: setup-ultimate
description: Configure Claude Code to expert-level using the claude-setup-ultimate prompt sequence. Analyzes your repo, detects your stack, and applies production-grade settings, hooks, permissions, and more.
user-invocable: true
argument-hint: "[lite|full|verify] (default: lite)"
---

# Setup Ultimate Skill

You have been invoked as the `/setup-ultimate` skill. Your job is to run the claude-setup-ultimate prompt sequence against the current repository.

## Determine which prompts to run

Check the argument provided by the user:

- **`lite`** (or no argument): Run Prompts 1-3 only. This is the recommended starting point -- it covers discovery, foundation settings, and hooks, which deliver the highest ROI.
- **`full`**: Run Prompts 1-8. The complete setup including beads, agent teams, MCP servers, performance optimization, and verification.
- **`verify`**: Run Prompt 8 only. Validates an existing setup and produces a health report.

The argument is: `$ARGUMENTS`

If `$ARGUMENTS` is empty or not one of the above, default to `lite`.

## Locate the prompt files

The prompt files live in the claude-setup-ultimate repository. Find them by resolving the symlink of this skill file:

1. This skill file is a symlink. Its real path reveals the repo location.
2. The repo contains:
   - `prompts/core-setup-prompts.md` -- Prompts 1-5 (Discovery, Foundation, Hooks, Beads, Agent Teams)
   - `prompts/advanced-setup-prompts.md` -- Prompts 6-8 (MCP Servers, Performance, Verification)

Run this to find the repo:
```bash
SKILL_REAL_PATH="$(readlink -f ~/.claude/skills/setup-ultimate.md 2>/dev/null || readlink ~/.claude/skills/setup-ultimate.md 2>/dev/null)"
REPO_DIR="$(dirname "$(dirname "$SKILL_REAL_PATH")")"
echo "claude-setup-ultimate repo: $REPO_DIR"
```

If the repo cannot be found (e.g., skill was copied instead of symlinked), search common locations:
```bash
for dir in ~/Documents/claude-setup-ultimate ~/Projects/claude-setup-ultimate ~/Code/claude-setup-ultimate; do
  [ -f "$dir/prompts/core-setup-prompts.md" ] && echo "Found: $dir" && break
done
```

If still not found, tell the user: "Could not locate the claude-setup-ultimate repository. Please ensure it is cloned and the skill is installed via install-skill.sh."

## Read the prompt files

Once you have the repo path:

1. Read `$REPO_DIR/prompts/core-setup-prompts.md` to get Prompts 1-5.
2. If running `full` or `verify`, also read `$REPO_DIR/prompts/advanced-setup-prompts.md` to get Prompts 6-8.

Each prompt is delimited by a `## PROMPT N:` heading and enclosed in a code fence. Extract the prompt text from inside the code fence for each prompt you need to run.

## Execute the prompts in sequence

For each prompt in the selected range:

1. **Announce** which prompt you are about to run (e.g., "Running Prompt 1: Discovery & Analysis").
2. **Execute** the instructions in the prompt text against the current repository. Follow every instruction exactly as written, including:
   - The self-update protocol (WebFetch to check latest docs)
   - All detection, generation, and validation steps
   - Writing output files where specified
3. **Report** a brief summary of what was done and any issues found.
4. **Continue** to the next prompt.

### Prompt ranges by mode

| Mode | Prompts | What they do |
|------|---------|-------------|
| lite | P1, P2, P3 | Discovery + Foundation (CLAUDE.md, settings, permissions) + Hooks |
| full | P1, P2, P3, P4, P5, P6, P7, P8 | Everything: lite + Beads + Agent Teams + MCP + Performance + Verification |
| verify | P8 | Verification & Testing only (validates existing setup) |

## After completion

Provide a summary report:

1. List which prompts were executed.
2. For each prompt, note: what was created/modified, any warnings or issues.
3. If running `lite`, suggest: "Run `/setup-ultimate full` to add beads, agent teams, MCP servers, and performance optimizations."
4. If running `full`, note: "Run `/setup-ultimate verify` at any time to re-validate your setup."
5. List any manual steps the user still needs to take (e.g., installing beads, setting API keys).
