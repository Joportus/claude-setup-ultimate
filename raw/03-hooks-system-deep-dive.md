# Claude Code Hooks System - Complete Deep Dive

> Comprehensive reference for Claude Code's hooks system: all 18 hook events, 4 handler types, JSON schemas, decision control, async execution, and real-world recipes.

**Sources:** [Official Hooks Reference](https://code.claude.com/docs/en/hooks) | [Hooks Guide](https://code.claude.com/docs/en/hooks-guide) | [Anthropic Blog: How to Configure Hooks](https://claude.com/blog/how-to-configure-hooks) | [disler/claude-code-hooks-mastery](https://github.com/disler/claude-code-hooks-mastery) | [johnlindquist/claude-hooks](https://github.com/johnlindquist/claude-hooks) | [ChrisWiles/claude-code-showcase](https://github.com/ChrisWiles/claude-code-showcase) | [decider/claude-hooks](https://github.com/decider/claude-hooks) | [karanb192/claude-code-hooks](https://github.com/karanb192/claude-code-hooks)

---

## Table of Contents

1. [What Are Hooks](#1-what-are-hooks)
2. [Hook Lifecycle Overview](#2-hook-lifecycle-overview)
3. [Configuration Structure](#3-configuration-structure)
4. [Hook Locations (Scope)](#4-hook-locations-scope)
5. [Handler Types](#5-handler-types)
6. [Common Input Fields (All Events)](#6-common-input-fields-all-events)
7. [Exit Code Behavior](#7-exit-code-behavior)
8. [JSON Output Schema](#8-json-output-schema)
9. [Decision Control Reference](#9-decision-control-reference)
10. [Matcher Patterns](#10-matcher-patterns)
11. [All 18 Hook Events - Complete Reference](#11-all-18-hook-events---complete-reference)
12. [Async Hooks (Background Execution)](#12-async-hooks-background-execution)
13. [Prompt-Based Hooks](#13-prompt-based-hooks)
14. [Agent-Based Hooks](#14-agent-based-hooks)
15. [HTTP Hooks](#15-http-hooks)
16. [Hooks in Skills and Agents (Frontmatter)](#16-hooks-in-skills-and-agents-frontmatter)
17. [CLAUDE_ENV_FILE (Environment Persistence)](#17-claude_env_file-environment-persistence)
18. [The /hooks Interactive Menu](#18-the-hooks-interactive-menu)
19. [Security Considerations](#19-security-considerations)
20. [Debugging Hooks](#20-debugging-hooks)
21. [Real-World Recipes & Patterns](#21-real-world-recipes--patterns)
22. [Community Hook Collections](#22-community-hook-collections)
23. [Limitations & Troubleshooting](#23-limitations--troubleshooting)

---

## 1. What Are Hooks

Hooks are user-defined shell commands, HTTP endpoints, or LLM prompts that execute automatically at specific points in Claude Code's lifecycle. They provide **deterministic control** over Claude Code's behavior -- certain actions always happen rather than relying on the LLM to choose to run them.

**Key characteristics:**
- Fire at specific lifecycle points (18 events total)
- Can block, allow, modify, or observe actions
- Support 4 handler types: command, http, prompt, agent
- Matcher patterns filter when hooks fire
- All matching hooks run in parallel; identical handlers are deduplicated
- Configurable at global, project, local, managed policy, plugin, or skill/agent level

---

## 2. Hook Lifecycle Overview

The hooks system covers the complete Claude Code session lifecycle:

```
Session Lifecycle:
  SessionStart ─────────────────────────────────────────┐
  InstructionsLoaded (fires at start + lazy loads)      │
                                                        │
  ┌─── Agentic Loop ──────────────────────────────────┐ │
  │  UserPromptSubmit                                  │ │
  │  PreToolUse ──> PermissionRequest                  │ │
  │  PostToolUse / PostToolUseFailure                  │ │
  │  Notification                                      │ │
  │  SubagentStart ──> SubagentStop                    │ │
  │  Stop                                              │ │
  │  TeammateIdle / TaskCompleted                      │ │
  └────────────────────────────────────────────────────┘ │
                                                        │
  PreCompact (before context compaction)                │
  ConfigChange (async, when config files change)        │
  WorktreeCreate / WorktreeRemove (async)               │
  SessionEnd ───────────────────────────────────────────┘
```

### Complete Event Table

| Event                | When it fires                                                            | Can Block? |
|:---------------------|:-------------------------------------------------------------------------|:-----------|
| `SessionStart`       | Session begins or resumes                                                | No         |
| `InstructionsLoaded` | CLAUDE.md or `.claude/rules/*.md` loaded into context                    | No         |
| `UserPromptSubmit`   | User submits a prompt, before Claude processes it                        | Yes        |
| `PreToolUse`         | Before a tool call executes                                              | Yes        |
| `PermissionRequest`  | When a permission dialog appears                                         | Yes        |
| `PostToolUse`        | After a tool call succeeds                                               | No*        |
| `PostToolUseFailure` | After a tool call fails                                                  | No         |
| `Notification`       | Claude Code sends a notification                                         | No         |
| `SubagentStart`      | A subagent is spawned                                                    | No         |
| `SubagentStop`       | A subagent finishes                                                      | Yes        |
| `Stop`               | Claude finishes responding                                               | Yes        |
| `TeammateIdle`       | Agent team teammate about to go idle                                     | Yes        |
| `TaskCompleted`      | Task being marked as completed                                           | Yes        |
| `ConfigChange`       | Configuration file changes during session                                | Yes**      |
| `WorktreeCreate`     | Worktree being created (replaces default git behavior)                   | Yes        |
| `WorktreeRemove`     | Worktree being removed                                                   | No         |
| `PreCompact`         | Before context compaction                                                | No         |
| `SessionEnd`         | Session terminates                                                       | No         |

*PostToolUse can provide feedback to Claude via `decision: "block"` but the tool has already run.
**`policy_settings` changes cannot be blocked.

---

## 3. Configuration Structure

Hooks are defined in JSON settings files with three levels of nesting:

```json
{
  "hooks": {
    "<HookEvent>": [           // 1. Choose a hook event
      {
        "matcher": "<pattern>", // 2. Filter when it fires (regex)
        "hooks": [              // 3. One or more handlers
          {
            "type": "command",  // Handler type
            "command": "...",   // What to run
            "timeout": 600,     // Optional: seconds before canceling
            "async": false,     // Optional: run in background
            "statusMessage": "" // Optional: custom spinner message
          }
        ]
      }
    ]
  }
}
```

### Configuration Levels

1. **Hook Event**: The lifecycle point (`PreToolUse`, `Stop`, etc.)
2. **Matcher Group**: Regex filter for when the hook fires
3. **Hook Handler**: The command, HTTP endpoint, prompt, or agent that runs

---

## 4. Hook Locations (Scope)

| Location                                    | Scope                         | Shareable                         |
|:--------------------------------------------|:------------------------------|:----------------------------------|
| `~/.claude/settings.json`                   | All your projects             | No, local to your machine         |
| `.claude/settings.json`                     | Single project                | Yes, can be committed to repo     |
| `.claude/settings.local.json`               | Single project                | No, gitignored                    |
| Managed policy settings                     | Organization-wide             | Yes, admin-controlled             |
| Plugin `hooks/hooks.json`                   | When plugin is enabled        | Yes, bundled with plugin          |
| Skill or agent frontmatter                  | While component is active     | Yes, defined in component file    |

**Key rules:**
- Project settings override user settings
- `disableAllHooks: true` in settings disables all hooks (respects managed settings hierarchy)
- Direct edits to settings files don't take effect immediately -- Claude Code snapshots hooks at startup
- External changes require review in `/hooks` menu before they apply (security measure)
- Enterprise admins can use `allowManagedHooksOnly` to block user, project, and plugin hooks

---

## 5. Handler Types

### 5.1 Command Hooks (`type: "command"`)

Run a shell command. Receives JSON on stdin, communicates via exit codes + stdout/stderr.

| Field           | Required | Description                                              |
|:----------------|:---------|:---------------------------------------------------------|
| `type`          | yes      | `"command"`                                              |
| `command`       | yes      | Shell command to execute                                 |
| `timeout`       | no       | Seconds before canceling (default: 600 = 10 min)        |
| `async`         | no       | If `true`, runs in background without blocking           |
| `statusMessage` | no       | Custom spinner message while running                     |
| `once`          | no       | If `true`, runs only once per session (skills only)      |

```json
{
  "type": "command",
  "command": "jq -r '.tool_input.file_path' | xargs npx prettier --write",
  "timeout": 30
}
```

### 5.2 HTTP Hooks (`type: "http"`)

POST event data to a URL. Same JSON input as command hooks, same JSON output format.

| Field            | Required | Description                                                  |
|:-----------------|:---------|:-------------------------------------------------------------|
| `type`           | yes      | `"http"`                                                     |
| `url`            | yes      | URL to POST to                                               |
| `headers`        | no       | Key-value pairs. Values support `$VAR_NAME` interpolation    |
| `allowedEnvVars` | no       | List of env var names allowed in header interpolation         |
| `timeout`        | no       | Seconds before canceling (default: 600)                      |
| `statusMessage`  | no       | Custom spinner message                                       |

```json
{
  "type": "http",
  "url": "http://localhost:8080/hooks/pre-tool-use",
  "timeout": 30,
  "headers": {
    "Authorization": "Bearer $MY_TOKEN"
  },
  "allowedEnvVars": ["MY_TOKEN"]
}
```

**Error handling:** Non-2xx responses, connection failures, and timeouts produce non-blocking errors. To block, return 2xx with JSON body containing decision fields.

**Note:** HTTP hooks must be configured by editing settings JSON directly. The `/hooks` menu only supports command hooks.

### 5.3 Prompt Hooks (`type: "prompt"`)

Single-turn LLM evaluation. Sends prompt + hook input to a Claude model (Haiku by default).

| Field           | Required | Description                                                     |
|:----------------|:---------|:----------------------------------------------------------------|
| `type`          | yes      | `"prompt"`                                                      |
| `prompt`        | yes      | Prompt text. `$ARGUMENTS` = placeholder for hook input JSON     |
| `model`         | no       | Model to use (default: fast model / Haiku)                      |
| `timeout`       | no       | Seconds (default: 30)                                           |
| `statusMessage` | no       | Custom spinner message                                          |

**Response schema:**
```json
{
  "ok": true,       // true = allow, false = block
  "reason": "..."   // Required when ok is false
}
```

```json
{
  "type": "prompt",
  "prompt": "Check if all tasks are complete. Context: $ARGUMENTS. Respond with {\"ok\": false, \"reason\": \"what remains\"} if not.",
  "timeout": 30
}
```

### 5.4 Agent Hooks (`type: "agent"`)

Multi-turn verification with tool access. Spawns a subagent that can use Read, Grep, Glob, and other tools.

| Field           | Required | Description                                                     |
|:----------------|:---------|:----------------------------------------------------------------|
| `type`          | yes      | `"agent"`                                                       |
| `prompt`        | yes      | What to verify. `$ARGUMENTS` = hook input JSON                  |
| `model`         | no       | Model to use (default: fast model)                              |
| `timeout`       | no       | Seconds (default: 60)                                           |
| `statusMessage` | no       | Custom spinner message                                          |

Same `ok`/`reason` response schema as prompt hooks. Up to **50 tool-use turns**.

```json
{
  "type": "agent",
  "prompt": "Verify that all unit tests pass. Run the test suite and check results. $ARGUMENTS",
  "timeout": 120
}
```

### Event Compatibility by Handler Type

Events supporting ALL 4 types (command, http, prompt, agent):
- `PermissionRequest`, `PostToolUse`, `PostToolUseFailure`, `PreToolUse`, `Stop`, `SubagentStop`, `TaskCompleted`, `UserPromptSubmit`

Events supporting ONLY `type: "command"`:
- `ConfigChange`, `InstructionsLoaded`, `Notification`, `PreCompact`, `SessionEnd`, `SessionStart`, `SubagentStart`, `TeammateIdle`, `WorktreeCreate`, `WorktreeRemove`

---

## 6. Common Input Fields (All Events)

Every hook event receives these fields as JSON (stdin for commands, POST body for HTTP):

| Field             | Description                                                                |
|:------------------|:---------------------------------------------------------------------------|
| `session_id`      | Current session identifier                                                 |
| `transcript_path` | Path to conversation JSONL file                                            |
| `cwd`             | Current working directory when hook was invoked                            |
| `permission_mode` | Current mode: `"default"`, `"plan"`, `"acceptEdits"`, `"dontAsk"`, `"bypassPermissions"` |
| `hook_event_name` | Name of the event that fired                                               |

**Additional fields in agent/subagent contexts:**

| Field        | Description                                                                    |
|:-------------|:-------------------------------------------------------------------------------|
| `agent_id`   | Unique subagent identifier (only inside subagent calls)                        |
| `agent_type` | Agent name (e.g., `"Explore"`, `"security-reviewer"`)                          |

Example:
```json
{
  "session_id": "abc123",
  "transcript_path": "/home/user/.claude/projects/.../transcript.jsonl",
  "cwd": "/home/user/my-project",
  "permission_mode": "default",
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "npm test"
  }
}
```

---

## 7. Exit Code Behavior

| Exit Code   | Meaning          | Effect                                                                        |
|:------------|:-----------------|:------------------------------------------------------------------------------|
| **0**       | Success          | Action proceeds. stdout parsed for JSON. For UserPromptSubmit/SessionStart, stdout added as context |
| **2**       | Blocking error   | Action blocked (for blocking-capable events). stderr fed to Claude as error   |
| **Any other** | Non-blocking error | Execution continues. stderr shown in verbose mode only                      |

### Exit Code 2 Behavior Per Event

| Hook Event           | Can Block? | What Happens on Exit 2                                                       |
|:---------------------|:-----------|:-----------------------------------------------------------------------------|
| `PreToolUse`         | Yes        | Blocks the tool call                                                         |
| `PermissionRequest`  | Yes        | Denies the permission                                                        |
| `UserPromptSubmit`   | Yes        | Blocks prompt processing and erases the prompt                               |
| `Stop`               | Yes        | Prevents Claude from stopping, continues conversation                        |
| `SubagentStop`       | Yes        | Prevents subagent from stopping                                              |
| `TeammateIdle`       | Yes        | Prevents teammate from going idle (continues working)                        |
| `TaskCompleted`      | Yes        | Prevents task from being marked complete                                     |
| `ConfigChange`       | Yes        | Blocks config change from taking effect (except `policy_settings`)           |
| `WorktreeCreate`     | Yes        | Any non-zero exit causes creation to fail                                    |
| `PostToolUse`        | No         | Shows stderr to Claude (tool already ran)                                    |
| `PostToolUseFailure` | No         | Shows stderr to Claude (tool already failed)                                 |
| `Notification`       | No         | Shows stderr to user only                                                    |
| `SubagentStart`      | No         | Shows stderr to user only                                                    |
| `SessionStart`       | No         | Shows stderr to user only                                                    |
| `SessionEnd`         | No         | Shows stderr to user only                                                    |
| `PreCompact`         | No         | Shows stderr to user only                                                    |
| `WorktreeRemove`     | No         | Failures logged in debug mode only                                           |
| `InstructionsLoaded` | No         | Exit code is ignored                                                         |

---

## 8. JSON Output Schema

For structured control beyond exit codes, exit 0 and print JSON to stdout.

**Important:** Choose ONE approach per hook -- exit codes OR JSON. Claude Code only processes JSON on exit 0. If you exit 2, any JSON is ignored.

### Universal Fields (All Events)

| Field            | Default | Description                                                           |
|:-----------------|:--------|:----------------------------------------------------------------------|
| `continue`       | `true`  | If `false`, Claude stops entirely. Overrides event-specific decisions |
| `stopReason`     | none    | Message shown to user when `continue` is `false`                      |
| `suppressOutput` | `false` | If `true`, hides stdout from verbose mode                             |
| `systemMessage`  | none    | Warning message shown to user                                         |

Example -- stop Claude entirely:
```json
{ "continue": false, "stopReason": "Build failed, fix errors before continuing" }
```

---

## 9. Decision Control Reference

| Events                                                                         | Decision Pattern               | Key Fields                                                        |
|:-------------------------------------------------------------------------------|:-------------------------------|:------------------------------------------------------------------|
| UserPromptSubmit, PostToolUse, PostToolUseFailure, Stop, SubagentStop, ConfigChange | Top-level `decision`           | `decision: "block"`, `reason`                                     |
| TeammateIdle, TaskCompleted                                                    | Exit code or `continue: false` | Exit 2 blocks with stderr. JSON `continue: false` stops entirely  |
| PreToolUse                                                                     | `hookSpecificOutput`           | `permissionDecision` (allow/deny/ask), `permissionDecisionReason` |
| PermissionRequest                                                              | `hookSpecificOutput`           | `decision.behavior` (allow/deny)                                  |
| WorktreeCreate                                                                 | stdout path                    | Print absolute path. Non-zero exit fails creation                 |
| WorktreeRemove, Notification, SessionEnd, PreCompact, InstructionsLoaded       | None                           | No decision control. Side effects only                            |

### Top-Level Decision Pattern
Used by UserPromptSubmit, PostToolUse, PostToolUseFailure, Stop, SubagentStop, ConfigChange:
```json
{
  "decision": "block",
  "reason": "Test suite must pass before proceeding"
}
```

### PreToolUse Decision Pattern
Three outcomes: allow, deny, or ask. Can also modify tool input:
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Database writes are not allowed",
    "updatedInput": { "command": "npm run lint" },
    "additionalContext": "Current environment: production"
  }
}
```

| Field                      | Description                                                         |
|:---------------------------|:--------------------------------------------------------------------|
| `permissionDecision`       | `"allow"` bypasses permission, `"deny"` blocks, `"ask"` prompts user |
| `permissionDecisionReason` | For allow/ask: shown to user. For deny: shown to Claude             |
| `updatedInput`             | Modifies tool input before execution                                |
| `additionalContext`        | Added to Claude's context before tool executes                      |

**Deprecation note:** PreToolUse previously used top-level `decision`/`reason`. Use `hookSpecificOutput` instead. Old `"approve"`/`"block"` map to `"allow"`/`"deny"`.

### PermissionRequest Decision Pattern
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PermissionRequest",
    "decision": {
      "behavior": "allow",
      "updatedInput": { "command": "npm run lint" },
      "updatedPermissions": [{ "type": "toolAlwaysAllow", "tool": "Bash" }],
      "message": "Permission denied: reason",
      "interrupt": false
    }
  }
}
```

| Field                | Description                                                         |
|:---------------------|:--------------------------------------------------------------------|
| `behavior`           | `"allow"` grants permission, `"deny"` denies it                    |
| `updatedInput`       | For allow only: modify tool input                                   |
| `updatedPermissions` | For allow only: apply "always allow" rules                          |
| `message`            | For deny only: tells Claude why                                     |
| `interrupt`          | For deny only: if `true`, stops Claude                              |

---

## 10. Matcher Patterns

The `matcher` field is a regex string that filters when hooks fire. Use `"*"`, `""`, or omit `matcher` entirely to match all.

| Event                                                                                                 | What Matcher Filters  | Example Values                                                           |
|:------------------------------------------------------------------------------------------------------|:----------------------|:-------------------------------------------------------------------------|
| `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest`                                | Tool name             | `Bash`, `Edit\|Write`, `mcp__.*`                                         |
| `SessionStart`                                                                                        | How session started   | `startup`, `resume`, `clear`, `compact`                                  |
| `SessionEnd`                                                                                          | Why session ended     | `clear`, `logout`, `prompt_input_exit`, `bypass_permissions_disabled`, `other` |
| `Notification`                                                                                        | Notification type     | `permission_prompt`, `idle_prompt`, `auth_success`, `elicitation_dialog`  |
| `SubagentStart`, `SubagentStop`                                                                       | Agent type            | `Bash`, `Explore`, `Plan`, custom agent names                            |
| `PreCompact`                                                                                          | Compaction trigger    | `manual`, `auto`                                                         |
| `ConfigChange`                                                                                        | Config source         | `user_settings`, `project_settings`, `local_settings`, `policy_settings`, `skills` |
| `UserPromptSubmit`, `Stop`, `TeammateIdle`, `TaskCompleted`, `WorktreeCreate`, `WorktreeRemove`, `InstructionsLoaded` | **No matcher support** | Always fires on every occurrence                                        |

### Matcher Examples
- `"Bash"` -- exact tool match
- `"Edit|Write"` -- regex OR (matches either)
- `"Notebook.*"` -- regex prefix match
- `"mcp__github__.*"` -- all tools from GitHub MCP server
- `"mcp__.*__write.*"` -- any "write" tool from any MCP server
- Matchers are **case-sensitive**

### MCP Tool Naming Pattern
MCP tools follow: `mcp__<server>__<tool>`:
- `mcp__memory__create_entities`
- `mcp__filesystem__read_file`
- `mcp__github__search_repositories`

---

## 11. All 18 Hook Events - Complete Reference

### 11.1 SessionStart

**When:** Session begins or resumes. Runs on EVERY session -- keep hooks fast.
**Only supports:** `type: "command"` hooks.
**Matcher values:** `startup` | `resume` | `clear` | `compact`

**Input fields** (in addition to common):

| Field        | Description                                                              |
|:-------------|:-------------------------------------------------------------------------|
| `source`     | `"startup"`, `"resume"`, `"clear"`, or `"compact"`                       |
| `model`      | Model identifier (e.g., `"claude-sonnet-4-6"`)                           |
| `agent_type` | Present when started with `claude --agent <name>`                        |

```json
{
  "session_id": "abc123",
  "transcript_path": "/Users/.../.claude/projects/.../transcript.jsonl",
  "cwd": "/Users/...",
  "permission_mode": "default",
  "hook_event_name": "SessionStart",
  "source": "startup",
  "model": "claude-sonnet-4-6"
}
```

**Decision control:**
- stdout text is added as context for Claude
- `additionalContext` field in hookSpecificOutput also adds context
- Cannot block session start

```json
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "Reminder: use Bun, not npm. Current sprint: auth refactor."
  }
}
```

**Special feature: CLAUDE_ENV_FILE** -- See [Section 17](#17-claude_env_file-environment-persistence).

**Practical example -- inject git context after compaction:**
```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "compact",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Reminder: use Bun, not npm. Run bun test before committing. Current sprint: auth refactor.'"
          }
        ]
      }
    ]
  }
}
```

---

### 11.2 InstructionsLoaded

**When:** CLAUDE.md or `.claude/rules/*.md` file loaded into context. Fires at session start for eager loads and later for lazy loads (e.g., nested CLAUDE.md in subdirectories, `paths:` frontmatter matches).
**Only supports:** `type: "command"` hooks.
**No matcher support** -- fires on every load.

**Input fields** (in addition to common):

| Field               | Description                                                          |
|:--------------------|:---------------------------------------------------------------------|
| `file_path`         | Absolute path to loaded file                                         |
| `memory_type`       | `"User"`, `"Project"`, `"Local"`, or `"Managed"`                     |
| `load_reason`       | `"session_start"`, `"nested_traversal"`, `"path_glob_match"`, `"include"` |
| `globs`             | Path glob patterns from `paths:` frontmatter (for `path_glob_match`) |
| `trigger_file_path` | File whose access triggered this load (for lazy loads)               |
| `parent_file_path`  | Parent instruction file that included this one (for `include` loads) |

```json
{
  "hook_event_name": "InstructionsLoaded",
  "file_path": "/Users/my-project/CLAUDE.md",
  "memory_type": "Project",
  "load_reason": "session_start"
}
```

**Decision control:** None. Cannot block or modify instruction loading. Use for audit logging/compliance only.

---

### 11.3 UserPromptSubmit

**When:** User submits a prompt, before Claude processes it.
**Supports:** command, http, prompt, agent.
**No matcher support** -- fires on every prompt.

**Input fields** (in addition to common):

| Field    | Description                  |
|:---------|:-----------------------------|
| `prompt` | The text the user submitted  |

```json
{
  "hook_event_name": "UserPromptSubmit",
  "prompt": "Write a function to calculate the factorial of a number"
}
```

**Decision control:**
- **Plain text stdout (exit 0):** Added as context (visible in transcript)
- **JSON `additionalContext`:** Added more discretely
- **`decision: "block"`:** Prevents prompt processing and erases from context

| Field               | Description                                                        |
|:--------------------|:-------------------------------------------------------------------|
| `decision`          | `"block"` prevents the prompt. Omit to allow                      |
| `reason`            | Shown to user when blocking. Not added to context                  |
| `additionalContext` | String added to Claude's context                                   |

```json
{
  "decision": "block",
  "reason": "This prompt is not allowed",
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "Additional context if needed"
  }
}
```

---

### 11.4 PreToolUse

**When:** After Claude creates tool parameters, before tool call executes.
**Supports:** command, http, prompt, agent.
**Matcher:** Tool name (`Bash`, `Edit`, `Write`, `Read`, `Glob`, `Grep`, `Agent`, `WebFetch`, `WebSearch`, MCP tools).

**Input fields** (in addition to common):

| Field        | Description                           |
|:-------------|:--------------------------------------|
| `tool_name`  | Name of the tool being called         |
| `tool_input` | Tool-specific input parameters (JSON) |
| `tool_use_id`| Unique identifier for this tool call  |

**Tool-specific `tool_input` schemas:**

#### Bash
| Field               | Type    | Description                           |
|:--------------------|:--------|:--------------------------------------|
| `command`           | string  | Shell command to execute              |
| `description`       | string  | Optional description                  |
| `timeout`           | number  | Optional timeout in ms                |
| `run_in_background` | boolean | Whether to run in background          |

#### Write
| Field       | Type   | Description             |
|:------------|:-------|:------------------------|
| `file_path` | string | Absolute path to file   |
| `content`   | string | Content to write        |

#### Edit
| Field         | Type    | Description                    |
|:--------------|:--------|:-------------------------------|
| `file_path`   | string  | Absolute path to file          |
| `old_string`  | string  | Text to find and replace       |
| `new_string`  | string  | Replacement text               |
| `replace_all` | boolean | Replace all occurrences?       |

#### Read
| Field       | Type   | Description                  |
|:------------|:-------|:-----------------------------|
| `file_path` | string | Absolute path to file        |
| `offset`    | number | Optional start line          |
| `limit`     | number | Optional number of lines     |

#### Glob
| Field     | Type   | Description             |
|:----------|:-------|:------------------------|
| `pattern` | string | Glob pattern            |
| `path`    | string | Optional directory      |

#### Grep
| Field         | Type    | Description                                          |
|:--------------|:--------|:-----------------------------------------------------|
| `pattern`     | string  | Regex pattern                                        |
| `path`        | string  | Optional file/directory                              |
| `glob`        | string  | Optional file filter                                 |
| `output_mode` | string  | `"content"`, `"files_with_matches"`, or `"count"`    |
| `-i`          | boolean | Case insensitive                                     |
| `multiline`   | boolean | Multiline matching                                   |

#### WebFetch
| Field    | Type   | Description                |
|:---------|:-------|:---------------------------|
| `url`    | string | URL to fetch               |
| `prompt` | string | Prompt for fetched content |

#### WebSearch
| Field             | Type  | Description                   |
|:------------------|:------|:------------------------------|
| `query`           | string| Search query                  |
| `allowed_domains` | array | Include only these domains    |
| `blocked_domains` | array | Exclude these domains         |

#### Agent
| Field           | Type   | Description              |
|:----------------|:-------|:-------------------------|
| `prompt`        | string | Task for the agent       |
| `description`   | string | Short description        |
| `subagent_type` | string | `"Explore"`, `"Plan"`, etc. |
| `model`         | string | Optional model alias     |

**Decision control:** See [Section 9 - PreToolUse Decision Pattern](#pretooluse-decision-pattern).

---

### 11.5 PermissionRequest

**When:** Permission dialog is about to be shown to the user.
**Supports:** command, http, prompt, agent.
**Matcher:** Tool name (same as PreToolUse).
**Note:** Does NOT fire in non-interactive mode (`-p`). Use PreToolUse for automated decisions.

**Input fields** (in addition to common):

| Field                    | Description                                          |
|:-------------------------|:-----------------------------------------------------|
| `tool_name`              | Tool requesting permission                           |
| `tool_input`             | Tool parameters                                      |
| `permission_suggestions` | Array of "always allow" options from permission dialog |

```json
{
  "hook_event_name": "PermissionRequest",
  "tool_name": "Bash",
  "tool_input": {
    "command": "rm -rf node_modules",
    "description": "Remove node_modules directory"
  },
  "permission_suggestions": [
    { "type": "toolAlwaysAllow", "tool": "Bash" }
  ]
}
```

**Decision control:** See [Section 9 - PermissionRequest Decision Pattern](#permissionrequest-decision-pattern).

---

### 11.6 PostToolUse

**When:** Immediately after a tool completes successfully.
**Supports:** command, http, prompt, agent.
**Matcher:** Tool name.

**Input fields** (in addition to common):

| Field           | Description                                |
|:----------------|:-------------------------------------------|
| `tool_name`     | Name of the tool that ran                  |
| `tool_input`    | Arguments sent to the tool                 |
| `tool_response` | Result returned by the tool                |
| `tool_use_id`   | Unique identifier for this tool call       |

```json
{
  "hook_event_name": "PostToolUse",
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/path/to/file.txt",
    "content": "file content"
  },
  "tool_response": {
    "filePath": "/path/to/file.txt",
    "success": true
  },
  "tool_use_id": "toolu_01ABC123..."
}
```

**Decision control:**

| Field                  | Description                                                    |
|:-----------------------|:---------------------------------------------------------------|
| `decision`             | `"block"` prompts Claude with the reason                       |
| `reason`               | Explanation shown to Claude                                    |
| `additionalContext`    | Additional context for Claude                                  |
| `updatedMCPToolOutput` | For MCP tools only: replaces the tool's output                 |

---

### 11.7 PostToolUseFailure

**When:** After a tool call fails (throws error or returns failure).
**Supports:** command, http, prompt, agent.
**Matcher:** Tool name.

**Input fields** (in addition to common):

| Field          | Description                                                |
|:---------------|:-----------------------------------------------------------|
| `tool_name`    | Tool that failed                                           |
| `tool_input`   | Arguments sent to the tool                                 |
| `tool_use_id`  | Unique identifier                                          |
| `error`        | String describing what went wrong                          |
| `is_interrupt` | Boolean -- whether failure was from user interruption      |

```json
{
  "hook_event_name": "PostToolUseFailure",
  "tool_name": "Bash",
  "tool_input": { "command": "npm test" },
  "tool_use_id": "toolu_01ABC123...",
  "error": "Command exited with non-zero status code 1",
  "is_interrupt": false
}
```

**Decision control:** `additionalContext` only (provides context alongside error).

---

### 11.8 Notification

**When:** Claude Code sends a notification.
**Only supports:** `type: "command"` hooks.
**Matcher:** Notification type -- `permission_prompt`, `idle_prompt`, `auth_success`, `elicitation_dialog`.

**Input fields** (in addition to common):

| Field               | Description               |
|:--------------------|:--------------------------|
| `message`           | Notification text         |
| `title`             | Optional title            |
| `notification_type` | Which type fired          |

```json
{
  "hook_event_name": "Notification",
  "message": "Claude needs your permission to use Bash",
  "title": "Permission needed",
  "notification_type": "permission_prompt"
}
```

**Decision control:** Cannot block notifications. Can return `additionalContext`.

---

### 11.9 SubagentStart

**When:** Claude Code subagent is spawned via Agent tool.
**Only supports:** `type: "command"` hooks.
**Matcher:** Agent type (`Bash`, `Explore`, `Plan`, custom agent names).

**Input fields** (in addition to common):

| Field        | Description                      |
|:-------------|:---------------------------------|
| `agent_id`   | Unique subagent identifier       |
| `agent_type` | Agent name (used for matching)   |

```json
{
  "hook_event_name": "SubagentStart",
  "agent_id": "agent-abc123",
  "agent_type": "Explore"
}
```

**Decision control:** Cannot block. Can inject context via `additionalContext`.

---

### 11.10 SubagentStop

**When:** Subagent finishes responding.
**Supports:** command, http, prompt, agent.
**Matcher:** Agent type (same as SubagentStart).

**Input fields** (in addition to common):

| Field                    | Description                                               |
|:-------------------------|:----------------------------------------------------------|
| `stop_hook_active`       | `true` if already continuing from a stop hook             |
| `agent_id`               | Unique subagent identifier                                |
| `agent_type`             | Agent name (for matcher filtering)                        |
| `agent_transcript_path`  | Subagent's own transcript (in `subagents/` folder)        |
| `last_assistant_message` | Text of subagent's final response                         |

```json
{
  "hook_event_name": "SubagentStop",
  "stop_hook_active": false,
  "agent_id": "def456",
  "agent_type": "Explore",
  "agent_transcript_path": "~/.claude/projects/.../subagents/agent-def456.jsonl",
  "last_assistant_message": "Analysis complete. Found 3 potential issues..."
}
```

**Decision control:** Same as Stop hooks (`decision: "block"` + `reason`).

---

### 11.11 Stop

**When:** Main Claude Code agent finishes responding. Does NOT fire on user interrupts.
**Supports:** command, http, prompt, agent.
**No matcher support.**

**Input fields** (in addition to common):

| Field                    | Description                                                |
|:-------------------------|:-----------------------------------------------------------|
| `stop_hook_active`       | `true` when already continuing from a stop hook            |
| `last_assistant_message` | Text content of Claude's final response                    |

```json
{
  "hook_event_name": "Stop",
  "stop_hook_active": true,
  "last_assistant_message": "I've completed the refactoring. Here's a summary..."
}
```

**Decision control:**

| Field      | Description                                                           |
|:-----------|:----------------------------------------------------------------------|
| `decision` | `"block"` prevents Claude from stopping                               |
| `reason`   | Required when blocking -- tells Claude why it should continue         |

**Critical: Infinite loop prevention.** Check `stop_hook_active` to avoid infinite loops:
```bash
#!/bin/bash
INPUT=$(cat)
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then
  exit 0  # Allow Claude to stop
fi
# ... rest of hook logic
```

---

### 11.12 TeammateIdle

**When:** Agent team teammate about to go idle after finishing its turn.
**Only supports:** `type: "command"` hooks.
**No matcher support.**

**Input fields** (in addition to common):

| Field           | Description                                   |
|:----------------|:----------------------------------------------|
| `teammate_name` | Name of teammate about to go idle             |
| `team_name`     | Name of the team                              |

```json
{
  "hook_event_name": "TeammateIdle",
  "teammate_name": "researcher",
  "team_name": "my-project"
}
```

**Decision control:**
- **Exit 2:** Teammate receives stderr as feedback and continues working
- **JSON `{"continue": false, "stopReason": "..."}`:** Stops teammate entirely

Example -- require build artifact before idle:
```bash
#!/bin/bash
if [ ! -f "./dist/output.js" ]; then
  echo "Build artifact missing. Run the build before stopping." >&2
  exit 2
fi
exit 0
```

---

### 11.13 TaskCompleted

**When:** Task being marked as completed (via TaskUpdate tool or teammate finishing with in-progress tasks).
**Only supports:** `type: "command"` hooks.
**No matcher support.**

**Input fields** (in addition to common):

| Field              | Description                                             |
|:-------------------|:--------------------------------------------------------|
| `task_id`          | Task identifier                                         |
| `task_subject`     | Task title                                              |
| `task_description` | Detailed description (may be absent)                    |
| `teammate_name`    | Teammate completing the task (may be absent)            |
| `team_name`        | Team name (may be absent)                               |

```json
{
  "hook_event_name": "TaskCompleted",
  "task_id": "task-001",
  "task_subject": "Implement user authentication",
  "task_description": "Add login and signup endpoints",
  "teammate_name": "implementer",
  "team_name": "my-project"
}
```

**Decision control:**
- **Exit 2:** Task not marked complete; stderr fed back to model
- **JSON `{"continue": false, "stopReason": "..."}`:** Stops teammate entirely

Example -- require passing tests:
```bash
#!/bin/bash
INPUT=$(cat)
TASK_SUBJECT=$(echo "$INPUT" | jq -r '.task_subject')
if ! npm test 2>&1; then
  echo "Tests not passing. Fix failing tests before completing: $TASK_SUBJECT" >&2
  exit 2
fi
exit 0
```

---

### 11.14 ConfigChange

**When:** Configuration file changes during session.
**Only supports:** `type: "command"` hooks.
**Matcher:** Config source -- `user_settings`, `project_settings`, `local_settings`, `policy_settings`, `skills`.

**Input fields** (in addition to common):

| Field       | Description                    |
|:------------|:-------------------------------|
| `source`    | Which config type changed      |
| `file_path` | Path to changed file (optional)|

```json
{
  "hook_event_name": "ConfigChange",
  "source": "project_settings",
  "file_path": "/Users/.../my-project/.claude/settings.json"
}
```

**Decision control:**

| Field      | Description                                                           |
|:-----------|:----------------------------------------------------------------------|
| `decision` | `"block"` prevents config change. Omit to allow                      |
| `reason`   | Shown to user when blocking                                           |

**Note:** `policy_settings` changes CANNOT be blocked (enterprise managed settings always take effect). Hooks still fire for audit logging.

Example -- audit log:
```json
{
  "hooks": {
    "ConfigChange": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "jq -c '{timestamp: now | todate, source: .source, file: .file_path}' >> ~/claude-config-audit.log"
          }
        ]
      }
    ]
  }
}
```

---

### 11.15 WorktreeCreate

**When:** Worktree being created via `--worktree` or `isolation: "worktree"`. **Replaces** default git behavior.
**Only supports:** `type: "command"` hooks.
**No matcher support.**

**Input fields** (in addition to common):

| Field  | Description                                           |
|:-------|:------------------------------------------------------|
| `name` | Slug identifier for new worktree (e.g., `bold-oak-a3f2`) |

```json
{
  "hook_event_name": "WorktreeCreate",
  "name": "feature-auth"
}
```

**Output:** Must print absolute path to created worktree on stdout. Non-zero exit = creation fails.

Example -- SVN checkout:
```json
{
  "hooks": {
    "WorktreeCreate": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'NAME=$(jq -r .name); DIR=\"$HOME/.claude/worktrees/$NAME\"; svn checkout https://svn.example.com/repo/trunk \"$DIR\" >&2 && echo \"$DIR\"'"
          }
        ]
      }
    ]
  }
}
```

---

### 11.16 WorktreeRemove

**When:** Worktree being removed (session exit or subagent finishes).
**Only supports:** `type: "command"` hooks.
**No matcher support.**

**Input fields** (in addition to common):

| Field           | Description                               |
|:----------------|:------------------------------------------|
| `worktree_path` | Absolute path to worktree being removed   |

```json
{
  "hook_event_name": "WorktreeRemove",
  "worktree_path": "/Users/.../my-project/.claude/worktrees/feature-auth"
}
```

**Decision control:** None. Cannot block removal. Hook failures logged in debug mode only.

---

### 11.17 PreCompact

**When:** Before context compaction.
**Only supports:** `type: "command"` hooks.
**Matcher:** `manual` (from `/compact`) or `auto` (context window full).

**Input fields** (in addition to common):

| Field                 | Description                                        |
|:----------------------|:---------------------------------------------------|
| `trigger`             | `"manual"` or `"auto"`                             |
| `custom_instructions` | User input from `/compact` (empty for auto)        |

```json
{
  "hook_event_name": "PreCompact",
  "trigger": "manual",
  "custom_instructions": ""
}
```

**Decision control:** None. Cannot block compaction. Use for backups/side effects.

---

### 11.18 SessionEnd

**When:** Session terminates.
**Only supports:** `type: "command"` hooks.
**Matcher:** Exit reason -- `clear`, `logout`, `prompt_input_exit`, `bypass_permissions_disabled`, `other`.

**Input fields** (in addition to common):

| Field    | Description       |
|:---------|:------------------|
| `reason` | Why session ended |

| Reason                        | Description                           |
|:------------------------------|:--------------------------------------|
| `clear`                       | `/clear` command                      |
| `logout`                      | User logged out                       |
| `prompt_input_exit`           | User exited at prompt                 |
| `bypass_permissions_disabled` | Bypass permissions disabled           |
| `other`                       | Other exit reasons                    |

```json
{
  "hook_event_name": "SessionEnd",
  "reason": "other"
}
```

**Decision control:** None. Cannot block termination. Use for cleanup/logging.

---

## 12. Async Hooks (Background Execution)

Set `"async": true` on command hooks to run them in the background without blocking Claude.

### Configuration
```json
{
  "type": "command",
  "command": "/path/to/run-tests.sh",
  "async": true,
  "timeout": 120
}
```

### Behavior
1. Claude Code starts hook process and immediately continues
2. Hook receives same JSON stdin as sync hooks
3. After background process exits, if hook produced `systemMessage` or `additionalContext`, it's delivered on next conversation turn
4. If session is idle, response waits until next user interaction

### Limitations
- Only `type: "command"` supports async. Prompt/agent hooks cannot be async
- Async hooks CANNOT block or return decisions (action already completed)
- Output delivered on next conversation turn, not immediately
- Each execution creates separate background process (no deduplication across firings)
- Default timeout: 600 seconds (10 minutes), configurable per hook

### Example: Background test runner
```bash
#!/bin/bash
# run-tests-async.sh
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ "$FILE_PATH" != *.ts && "$FILE_PATH" != *.js ]]; then
  exit 0
fi

RESULT=$(npm test 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo "{\"systemMessage\": \"Tests passed after editing $FILE_PATH\"}"
else
  echo "{\"systemMessage\": \"Tests failed after editing $FILE_PATH: $RESULT\"}"
fi
```

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/run-tests-async.sh",
            "async": true,
            "timeout": 300
          }
        ]
      }
    ]
  }
}
```

---

## 13. Prompt-Based Hooks

### How They Work
1. Hook input + your prompt sent to Claude model (Haiku by default)
2. LLM responds with structured JSON decision
3. Claude Code processes decision automatically

### Response Schema
```json
{
  "ok": true,       // true = allow, false = block
  "reason": "..."   // Required when ok is false; shown to Claude
}
```

### Example: Multi-criteria Stop verification
```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "You are evaluating whether Claude should stop working. Context: $ARGUMENTS\n\nAnalyze the conversation and determine if:\n1. All user-requested tasks are complete\n2. Any errors need to be addressed\n3. Follow-up work is needed\n\nRespond with JSON: {\"ok\": true} to allow stopping, or {\"ok\": false, \"reason\": \"your explanation\"} to continue working.",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

### When to Use Prompt vs Agent Hooks
- **Prompt hooks:** When the hook input data alone is enough to decide (single LLM call)
- **Agent hooks:** When you need to verify against actual codebase state (multi-turn with file access)

---

## 14. Agent-Based Hooks

### How They Work
1. Spawns a subagent with your prompt + hook's JSON input
2. Subagent can use tools: Read, Grep, Glob, etc.
3. After up to 50 turns, returns `{ "ok": true/false }` decision
4. Same processing as prompt hooks

### Example: Verify tests pass before stopping
```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "agent",
            "prompt": "Verify that all unit tests pass. Run the test suite and check the results. $ARGUMENTS",
            "timeout": 120
          }
        ]
      }
    ]
  }
}
```

---

## 15. HTTP Hooks

### Response Handling
- **2xx + empty body:** Success (equivalent to exit 0, no output)
- **2xx + plain text body:** Success, text added as context
- **2xx + JSON body:** Success, parsed as JSON output
- **Non-2xx:** Non-blocking error, execution continues
- **Connection failure / timeout:** Non-blocking error, continues

To block via HTTP: return **2xx** with JSON body containing decision fields (cannot block via status codes alone).

### Example: Audit service
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "hooks": [
          {
            "type": "http",
            "url": "http://localhost:8080/hooks/tool-use",
            "headers": {
              "Authorization": "Bearer $MY_TOKEN"
            },
            "allowedEnvVars": ["MY_TOKEN"]
          }
        ]
      }
    ]
  }
}
```

---

## 16. Hooks in Skills and Agents (Frontmatter)

Hooks can be defined in skill or subagent YAML frontmatter. Scoped to component lifecycle -- active only while component runs, cleaned up when it finishes.

### Skill Example
```yaml
---
name: secure-operations
description: Perform operations with security checks
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/security-check.sh"
---
```

### Key Behaviors
- All hook events supported
- For subagents, `Stop` hooks auto-convert to `SubagentStop`
- `once: true` field: runs only once per session then removed (skills only, not agents)
- Same configuration format as settings-based hooks

---

## 17. CLAUDE_ENV_FILE (Environment Persistence)

Available **only** in `SessionStart` hooks. Provides a file path where you can persist environment variables for all subsequent Bash commands in the session.

### Set Individual Variables
```bash
#!/bin/bash
if [ -n "$CLAUDE_ENV_FILE" ]; then
  echo 'export NODE_ENV=production' >> "$CLAUDE_ENV_FILE"
  echo 'export DEBUG_LOG=true' >> "$CLAUDE_ENV_FILE"
  echo 'export PATH="$PATH:./node_modules/.bin"' >> "$CLAUDE_ENV_FILE"
fi
exit 0
```

### Capture All Environment Changes from Setup Commands
```bash
#!/bin/bash
ENV_BEFORE=$(export -p | sort)

# Run setup commands
source ~/.nvm/nvm.sh
nvm use 20

if [ -n "$CLAUDE_ENV_FILE" ]; then
  ENV_AFTER=$(export -p | sort)
  comm -13 <(echo "$ENV_BEFORE") <(echo "$ENV_AFTER") >> "$CLAUDE_ENV_FILE"
fi
exit 0
```

### Important Notes
- Use append (`>>`) to preserve variables set by other hooks
- Variables available in ALL subsequent Bash commands during the session
- `CLAUDE_ENV_FILE` is NOT available in other hook types -- SessionStart only

---

## 18. The /hooks Interactive Menu

Type `/hooks` in Claude Code to open the interactive hooks manager.

### Features
- View all configured hooks across all sources
- Add new hooks interactively
- Delete existing hooks
- Toggle all hooks on/off (`disableAllHooks: true`)

### Source Labels
- `[User]` -- from `~/.claude/settings.json`
- `[Project]` -- from `.claude/settings.json`
- `[Local]` -- from `.claude/settings.local.json`
- `[Plugin]` -- from plugin's `hooks/hooks.json` (read-only)

### Important
- Hooks added via `/hooks` take effect immediately
- Manual file edits require reload or restart
- HTTP hooks must be configured by editing JSON directly (not through `/hooks` menu)

---

## 19. Security Considerations

### Warning
Command hooks run with your system user's **full permissions**. They can modify, delete, or access any files your user account can access.

### Best Practices
1. **Validate and sanitize inputs** -- never trust input data blindly
2. **Always quote shell variables** -- use `"$VAR"` not `$VAR`
3. **Block path traversal** -- check for `..` in file paths
4. **Use absolute paths** -- `"$CLAUDE_PROJECT_DIR"` for project root
5. **Skip sensitive files** -- avoid `.env`, `.git/`, keys, etc.
6. **Review all hook commands** before adding to configuration

### Enterprise Controls
- `allowManagedHooksOnly` -- blocks user, project, and plugin hooks
- `disableAllHooks` respects managed settings hierarchy
- `policy_settings` changes cannot be blocked by hooks
- Direct edits require `/hooks` review before taking effect

### Environment Variables in Hooks
- `$CLAUDE_PROJECT_DIR` -- project root directory
- `${CLAUDE_PLUGIN_ROOT}` -- plugin root directory (for plugin hooks)
- `$CLAUDE_CODE_REMOTE` -- set to `"true"` in remote web environments
- `$CLAUDE_ENV_FILE` -- env file path (SessionStart only)

---

## 20. Debugging Hooks

### Methods
1. **`claude --debug`** -- full execution details: which hooks matched, exit codes, output
2. **`Ctrl+O`** -- toggle verbose mode in transcript to see hook progress
3. **Manual testing** -- pipe sample JSON to your script:
   ```bash
   echo '{"tool_name":"Bash","tool_input":{"command":"ls"}}' | ./my-hook.sh
   echo $?  # Check exit code
   ```

### Debug Output Example
```
[DEBUG] Executing hooks for PostToolUse:Write
[DEBUG] Getting matching hook commands for PostToolUse with query: Write
[DEBUG] Found 1 hook matchers in settings
[DEBUG] Matched 1 hooks for query "Write"
[DEBUG] Found 1 hook commands to execute
[DEBUG] Executing hook command: <Your command> with timeout 600000ms
[DEBUG] Hook command completed with status 0: <Your stdout>
```

### Wrapper Script for Detailed Logging
```bash
#!/bin/bash
# log-wrapper.sh
LOG=~/.claude/hooks.log
INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // "n/a"')
EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // "n/a"')
echo "=== $(date) | $EVENT | $TOOL ===" >> "$LOG"
echo "$INPUT" | "$1"
CODE=$?
echo "Exit: $CODE" >> "$LOG"
exit $CODE
```

---

## 21. Real-World Recipes & Patterns

### Recipe 1: Desktop Notifications (macOS)
```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "osascript -e 'display notification \"Claude Code needs your attention\" with title \"Claude Code\"'"
          }
        ]
      }
    ]
  }
}
```

### Recipe 2: Auto-Format with Prettier After Edits
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.tool_input.file_path' | xargs npx prettier --write"
          }
        ]
      }
    ]
  }
}
```

### Recipe 3: Block Edits to Protected Files
Script: `.claude/hooks/protect-files.sh`
```bash
#!/bin/bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

PROTECTED_PATTERNS=(".env" "package-lock.json" ".git/")

for pattern in "${PROTECTED_PATTERNS[@]}"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    echo "Blocked: $FILE_PATH matches protected pattern '$pattern'" >&2
    exit 2
  fi
done
exit 0
```

Configuration:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/protect-files.sh"
          }
        ]
      }
    ]
  }
}
```

### Recipe 4: Re-Inject Context After Compaction
```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "compact",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Reminder: use Bun, not npm. Run bun test before committing. Current sprint: auth refactor.'"
          }
        ]
      }
    ]
  }
}
```

### Recipe 5: Block Dangerous Shell Commands
```bash
#!/bin/bash
COMMAND=$(jq -r '.tool_input.command')

if echo "$COMMAND" | grep -q 'rm -rf'; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "Destructive command blocked by hook"
    }
  }'
else
  exit 0
fi
```

### Recipe 6: Log All Bash Commands
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.tool_input.command' >> ~/.claude/command-log.txt"
          }
        ]
      }
    ]
  }
}
```

### Recipe 7: Clean Up on Session End (/clear)
```json
{
  "hooks": {
    "SessionEnd": [
      {
        "matcher": "clear",
        "hooks": [
          {
            "type": "command",
            "command": "rm -f /tmp/claude-scratch-*.txt"
          }
        ]
      }
    ]
  }
}
```

### Recipe 8: Audit Configuration Changes
```json
{
  "hooks": {
    "ConfigChange": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "jq -c '{timestamp: now | todate, source: .source, file: .file_path}' >> ~/claude-config-audit.log"
          }
        ]
      }
    ]
  }
}
```

### Recipe 9: Auto-Allow Read-Only Operations (PermissionRequest)
```bash
#!/bin/bash
INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name')

case "$TOOL" in
  Read|Glob|Grep)
    jq -n '{
      hookSpecificOutput: {
        hookEventName: "PermissionRequest",
        decision: { behavior: "allow" }
      }
    }'
    ;;
  *)
    exit 0  # Let normal permission flow happen
    ;;
esac
```

### Recipe 10: Force Beads Closure Before Task Completion (Hypebase Pattern)
```bash
#!/bin/bash
INPUT=$(cat)
TASK_SUBJECT=$(echo "$INPUT" | jq -r '.task_subject // ""')

# Extract beads ID from task subject: [hypebase-ai-XXXX]
BEADS_ID=$(echo "$TASK_SUBJECT" | grep -oP '\[hypebase-ai-[a-z0-9]+\]' | tr -d '[]')

if [ -z "$BEADS_ID" ]; then
  echo "Task subject must include beads ID: [hypebase-ai-XXXX]" >&2
  exit 2
fi

# Check if beads issue is closed
STATUS=$(bd show "$BEADS_ID" --json 2>/dev/null | jq -r '.status // "unknown"')

if [ "$STATUS" != "closed" ]; then
  echo "Beads issue $BEADS_ID is not closed (status: $STATUS). Close it before completing the task." >&2
  exit 2
fi

exit 0
```

### Recipe 11: Prompt-Based Stop Verification
```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Check if all tasks are complete. If not, respond with {\"ok\": false, \"reason\": \"what remains to be done\"}."
          }
        ]
      }
    ]
  }
}
```

### Recipe 12: Agent-Based Test Verification Before Stop
```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "agent",
            "prompt": "Verify that all unit tests pass. Run the test suite and check the results. $ARGUMENTS",
            "timeout": 120
          }
        ]
      }
    ]
  }
}
```

### Recipe 13: SessionStart -- Load Git Context + Recent Issues
```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "git status --short && echo '---' && git log --oneline -5 && echo '---' && cat TODO.md 2>/dev/null || true"
          }
        ]
      }
    ]
  }
}
```

### Recipe 14: TeammateIdle -- Require Build Artifact
```bash
#!/bin/bash
if [ ! -f "./dist/output.js" ]; then
  echo "Build artifact missing. Run the build before stopping." >&2
  exit 2
fi
exit 0
```

### Recipe 15: HTTP Hook -- External Audit Service
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "hooks": [
          {
            "type": "http",
            "url": "http://localhost:8080/hooks/tool-use",
            "headers": {
              "Authorization": "Bearer $MY_TOKEN"
            },
            "allowedEnvVars": ["MY_TOKEN"]
          }
        ]
      }
    ]
  }
}
```

### Recipe 16: Prevent `--no-verify` on Git Commands
```bash
#!/bin/bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

if echo "$COMMAND" | grep -qE '\-\-no\-verify|\-\-no\-hooks'; then
  echo "Blocked: --no-verify and --no-hooks flags are not allowed. Quality gates are mandatory." >&2
  exit 2
fi
exit 0
```

### Recipe 17: MCP Tool Monitoring
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "mcp__github__.*",
        "hooks": [
          {
            "type": "command",
            "command": "echo \"GitHub tool called: $(jq -r '.tool_name')\" >&2"
          }
        ]
      }
    ]
  }
}
```

### Recipe 18: Environment Setup via CLAUDE_ENV_FILE
```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "if [ -n \"$CLAUDE_ENV_FILE\" ]; then echo 'export NODE_ENV=development' >> \"$CLAUDE_ENV_FILE\"; echo 'export PATH=\"$PATH:./node_modules/.bin\"' >> \"$CLAUDE_ENV_FILE\"; fi"
          }
        ]
      }
    ]
  }
}
```

---

## 22. Community Hook Collections

### disler/claude-code-hooks-mastery
- 13+ hook event types implemented as UV single-file Python scripts
- TTS (text-to-speech) integration with ElevenLabs/OpenAI/pyttsx3
- Security blocking (dangerous commands, sensitive files)
- Transcript extraction and logging
- Ruff + type checking validators
- Builder/validator agent patterns
- Status line customizations (9 versions)
- URL: https://github.com/disler/claude-code-hooks-mastery

### johnlindquist/claude-hooks
- TypeScript-based hook implementations
- Full type safety for hook input/output
- URL: https://github.com/johnlindquist/claude-hooks

### ChrisWiles/claude-code-showcase
- Comprehensive project configuration example
- Hooks, skills, agents, commands, and GitHub Actions
- URL: https://github.com/ChrisWiles/claude-code-showcase

### decider/claude-hooks
- Clean code practices enforcement
- Workflow automation patterns
- URL: https://github.com/decider/claude-hooks

### karanb192/claude-code-hooks
- Growing collection of copy-paste-customize hooks
- URL: https://github.com/karanb192/claude-code-hooks

### Official Example
- Bash command validator: https://github.com/anthropics/claude-code/blob/main/examples/hooks/bash_command_validator_example.py

---

## 23. Limitations & Troubleshooting

### Known Limitations
1. Command hooks communicate through stdout/stderr/exit codes only -- cannot trigger tools directly
2. Default timeout: 600 seconds (10 min) for commands, 30 for prompts, 60 for agents
3. `PostToolUse` hooks cannot undo actions (tool already executed)
4. `PermissionRequest` hooks do NOT fire in non-interactive mode (`-p`). Use `PreToolUse` instead
5. `Stop` hooks fire whenever Claude finishes responding, not only at task completion. Do not fire on user interrupts
6. Async hooks cannot block or return decisions (action already completed)
7. HTTP hooks can only be configured via JSON editing, not `/hooks` menu
8. `policy_settings` ConfigChange events cannot be blocked

### Hook Not Firing
- Run `/hooks` and confirm hook appears under correct event
- Check matcher is case-sensitive and matches tool name exactly
- Verify correct event type (PreToolUse = before execution, PostToolUse = after)
- For `PermissionRequest` in non-interactive mode, switch to `PreToolUse`

### Hook Error in Output
- Test manually: `echo '{"tool_name":"Bash","tool_input":{"command":"ls"}}' | ./my-hook.sh`
- "command not found" -- use absolute paths or `$CLAUDE_PROJECT_DIR`
- "jq: command not found" -- install jq or use Python/Node
- Script not running -- `chmod +x ./my-hook.sh`

### /hooks Shows No Hooks
- Restart session or open `/hooks` to reload
- Verify JSON is valid (no trailing commas or comments)
- Confirm file in correct location

### Stop Hook Runs Forever
Check `stop_hook_active` field:
```bash
#!/bin/bash
INPUT=$(cat)
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then
  exit 0  # Allow Claude to stop
fi
# ... hook logic
```

### JSON Validation Failed
Shell profile `echo` statements interfere with JSON output. Fix:
```bash
# In ~/.zshrc or ~/.bashrc
if [[ $- == *i* ]]; then
  echo "Shell ready"  # Only in interactive shells
fi
```

The `$-` variable contains shell flags; `i` means interactive. Hooks run in non-interactive shells.

---

## Summary

The Claude Code hooks system provides 18 lifecycle events with 4 handler types for deterministic automation. Key takeaways:

1. **Hooks provide certainty** -- unlike prompts that rely on LLM judgment, hooks always execute
2. **4 handler types** cover all needs: command (scripts), http (services), prompt (LLM judgment), agent (multi-turn verification)
3. **Decision control** varies by event: PreToolUse uses `hookSpecificOutput`, Stop/PostToolUse use top-level `decision`, TeammateIdle/TaskCompleted use exit codes
4. **Matchers are regex** on event-specific fields (tool name, session source, config source, etc.)
5. **Async hooks** (`async: true`) enable background execution without blocking
6. **CLAUDE_ENV_FILE** in SessionStart persists environment variables for the entire session
7. **Security first** -- hooks run with full user permissions; validate inputs, quote variables, use absolute paths
8. **Infinite loop prevention** -- always check `stop_hook_active` in Stop/SubagentStop hooks
9. **6 configuration scopes** -- from global user settings to skill/agent frontmatter
10. **Debug with `claude --debug`** or `Ctrl+O` verbose mode
