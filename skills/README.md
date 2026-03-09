# setup-ultimate Skill

A Claude Code skill that configures any repository to expert-level by running the claude-setup-ultimate prompt sequence.

## What it does

When you invoke `/setup-ultimate` inside Claude Code, it reads the prompt files from this repository and executes them against your current project. It detects your stack, creates a tailored CLAUDE.md, configures permissions, sets up hooks, and more.

## Install

```bash
# From the claude-setup-ultimate repo directory:
bash install-skill.sh
```

This creates a symlink at `~/.claude/skills/setup-ultimate.md` pointing to this repo's skill file.

**Manual alternative:** If you prefer, create the symlink yourself:

```bash
mkdir -p ~/.claude/skills
ln -s /path/to/claude-setup-ultimate/skills/setup-ultimate.md ~/.claude/skills/setup-ultimate.md
```

## Usage

Inside any project in Claude Code:

| Command | What it runs | Best for |
|---------|-------------|----------|
| `/setup-ultimate` | P1-P3 (lite) | First-time setup -- discovery, settings, hooks |
| `/setup-ultimate lite` | P1-P3 | Same as above (explicit) |
| `/setup-ultimate full` | P1-P8 | Complete setup including beads, teams, MCP, optimization |
| `/setup-ultimate verify` | P8 only | Validate an existing setup |

## Update

The skill is a symlink, so it always reads the latest version from this repo:

```bash
cd /path/to/claude-setup-ultimate
git pull
```

No reinstall needed.

## Uninstall

```bash
bash install-skill.sh --uninstall
```

Or remove the symlink manually:

```bash
rm ~/.claude/skills/setup-ultimate.md
```
