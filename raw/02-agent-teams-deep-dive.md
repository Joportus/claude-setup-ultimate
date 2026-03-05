# Claude Code Agent Teams -- Deep Dive Research

> Compiled from official docs (code.claude.com), community guides, blog posts, and GitHub resources.
> Date: 2026-03-05

---

## Table of Contents

1. [Overview and Status](#1-overview-and-status)
2. [Enabling Agent Teams](#2-enabling-agent-teams)
3. [Architecture and Components](#3-architecture-and-components)
4. [Starting a Team (TeamCreate)](#4-starting-a-team-teamcreate)
5. [Task System (TaskCreate / TaskList / TaskUpdate / TaskGet)](#5-task-system)
6. [Teammate Spawning Options](#6-teammate-spawning-options)
7. [Display Modes](#7-display-modes)
8. [Spawn Backends](#8-spawn-backends)
9. [Communication and Messaging](#9-communication-and-messaging)
10. [Plan Approval Workflow](#10-plan-approval-workflow)
11. [Hooks: TeammateIdle and TaskCompleted](#11-hooks-teammateidle-and-taskcompleted)
12. [Direct Teammate Interaction](#12-direct-teammate-interaction)
13. [Task Dependencies and Auto-Unblocking](#13-task-dependencies-and-auto-unblocking)
14. [Self-Claiming Patterns](#14-self-claiming-patterns)
15. [File Locking for Concurrent Claims](#15-file-locking-for-concurrent-claims)
16. [Team Size Guidance](#16-team-size-guidance)
17. [Token Costs: Teams vs Subagents vs Single Session](#17-token-costs)
18. [Subagents vs Agent Teams Comparison](#18-subagents-vs-agent-teams-comparison)
19. [Orchestration Patterns](#19-orchestration-patterns)
20. [Best Practices (Official + Community)](#20-best-practices)
21. [Troubleshooting Guide](#21-troubleshooting-guide)
22. [Known Limitations](#22-known-limitations)
23. [Real-World Examples](#23-real-world-examples)
24. [Environment Variables Reference](#24-environment-variables-reference)
25. [File and Storage Paths](#25-file-and-storage-paths)
26. [TeamDelete / Cleanup](#26-teamdelete--cleanup)
27. [Permissions in Teams](#27-permissions-in-teams)
28. [Settings Reference](#28-settings-reference)
29. [Version History and Recent Fixes](#29-version-history-and-recent-fixes)
30. [External Resources and Plugins](#30-external-resources-and-plugins)

---

## 1. Overview and Status

Agent teams let you coordinate multiple Claude Code instances working together as a team. One session acts as the **team lead**, coordinating work, assigning tasks, and synthesizing results. **Teammates** work independently, each in its own context window, and communicate directly with each other.

**Status**: Experimental. Disabled by default. Must be explicitly enabled.

> **WARNING**: Agent teams are experimental and disabled by default. Enable them by adding `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` to your settings.json or environment. Agent teams have known limitations around session resumption, task coordination, and shutdown behavior.

Unlike subagents (which run within a single session and can only report back to the main agent), agent team teammates can interact with individual teammates directly without going through the lead.

### When to Use Agent Teams

Agent teams are most effective for tasks where **parallel exploration adds real value**:

- **Research and review**: Multiple teammates investigate different aspects simultaneously, then share and challenge each other's findings
- **New modules or features**: Teammates each own a separate piece without stepping on each other
- **Debugging with competing hypotheses**: Teammates test different theories in parallel and converge faster
- **Cross-layer coordination**: Changes spanning frontend, backend, and tests, each owned by a different teammate

Agent teams add coordination overhead and use significantly more tokens than a single session. They work best when teammates can operate **independently**. For sequential tasks, same-file edits, or work with many dependencies, a single session or subagents are more effective.

---

## 2. Enabling Agent Teams

### Method 1: Environment Variable

```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

### Method 2: settings.json (persistent)

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

This can go in:
- `~/.claude/settings.json` (user-level, all projects)
- `.claude/settings.json` (project-level)
- `.claude/settings.local.json` (local, gitignored)

---

## 3. Architecture and Components

An agent team consists of four components:

| Component     | Role                                                                                       |
|:--------------|:-------------------------------------------------------------------------------------------|
| **Team Lead** | The main Claude Code session that creates the team, spawns teammates, and coordinates work |
| **Teammates** | Separate Claude Code instances that each work on assigned tasks                            |
| **Task List** | Shared list of work items that teammates claim and complete                                |
| **Mailbox**   | Messaging system for communication between agents                                          |

### Storage Locations

```
~/.claude/teams/{team-name}/
  config.json              # Team configuration with members array
  inboxes/
    team-lead.json         # Inbox for the lead
    worker-1.json          # Inbox for each teammate
    worker-2.json

~/.claude/tasks/{team-name}/
  1.json                   # Task files
  2.json
  3.json
```

### Team Config Structure

```json
{
  "name": "my-project",
  "description": "Working on feature X",
  "leadAgentId": "team-lead@my-project",
  "createdAt": 1706000000000,
  "members": [
    {
      "agentId": "team-lead@my-project",
      "name": "team-lead",
      "agentType": "team-lead",
      "color": "#4A90D9",
      "joinedAt": 1706000000000,
      "backendType": "in-process"
    },
    {
      "agentId": "worker-1@my-project",
      "name": "worker-1",
      "agentType": "Explore",
      "model": "haiku",
      "prompt": "Analyze the codebase structure...",
      "color": "#D94A4A",
      "planModeRequired": false,
      "joinedAt": 1706000001000,
      "tmuxPaneId": "in-process",
      "cwd": "/Users/me/project",
      "backendType": "in-process"
    }
  ]
}
```

### Task File Structure

`~/.claude/tasks/{team-name}/1.json`:

```json
{
  "id": "1",
  "subject": "Review authentication module",
  "description": "Review all files in app/services/auth/...",
  "status": "in_progress",
  "owner": "security-reviewer",
  "activeForm": "Reviewing auth module...",
  "blockedBy": [],
  "blocks": ["3"],
  "createdAt": 1706000000000,
  "updatedAt": 1706000001000
}
```

---

## 4. Starting a Team (TeamCreate)

There are two ways agent teams get started:

1. **You request a team**: Give Claude a task that benefits from parallel work and explicitly ask for an agent team
2. **Claude proposes a team**: If Claude determines your task would benefit from parallel work, it may suggest creating a team. You confirm before it proceeds.

In both cases, you stay in control. Claude won't create a team without your approval.

### Natural Language Examples

```
I'm designing a CLI tool that helps developers track TODO comments across
their codebase. Create an agent team to explore this from different angles: one
teammate on UX, one on technical architecture, one playing devil's advocate.
```

```
Create a team with 4 teammates to refactor these modules in parallel.
Use Sonnet for each teammate.
```

### Programmatic (via TeammateTool)

```javascript
// Create a team
Teammate({
  operation: "spawnTeam",
  team_name: "feature-auth",
  description: "Implementing OAuth2 authentication"
})
```

This creates:
- `~/.claude/teams/feature-auth/config.json`
- `~/.claude/tasks/feature-auth/` directory
- The calling agent becomes the team leader

### Three-Phase Tool Sequence

Every team session follows this pattern:

**Setup Phase:**
```
TeamCreate() -> TaskCreate() x N -> Task(spawn) x N
```

**Execution Phase (each teammate independently):**
```
TaskList() -> TaskUpdate(claim) -> do_work -> TaskUpdate(complete) -> SendMessage(report) -> check_for_more_tasks
```

**Teardown Phase:**
```
SendMessage(shutdown_request) x N -> SendMessage(shutdown_response) x N -> TeamDelete()
```

---

## 5. Task System

### TaskCreate -- Create Work Items

```javascript
TaskCreate({
  subject: "Review authentication module",
  description: "Review all files in app/services/auth/ for security vulnerabilities",
  activeForm: "Reviewing auth module..."
})
```

Fields:
- `subject` (required): Brief description of the task (imperative form, e.g., "Run tests")
- `description` (optional): Detailed description
- `activeForm` (optional): Present continuous form shown in spinner when in_progress (e.g., "Running tests")

### TaskList -- See All Tasks

```javascript
TaskList()
```

Returns a summary of each task:
- **id**: Task identifier (use with TaskGet, TaskUpdate)
- **subject**: Brief description
- **status**: 'pending', 'in_progress', or 'completed'
- **owner**: Agent ID if assigned, empty if available
- **blockedBy**: List of open task IDs that must be resolved first

Example output:
```
#1 [completed] Analyze codebase structure
#2 [in_progress] Review authentication module (owner: security-reviewer)
#3 [pending] Generate summary report [blocked by #2]
```

### TaskGet -- Get Task Details

```javascript
TaskGet({ taskId: "2" })
```

Returns full task with description, status, blockedBy, etc. Always read latest state with TaskGet before updating.

### TaskUpdate -- Update Task Status

```javascript
// Claim a task
TaskUpdate({ taskId: "2", owner: "security-reviewer" })

// Start working
TaskUpdate({ taskId: "2", status: "in_progress" })

// Mark complete
TaskUpdate({ taskId: "2", status: "completed" })

// Set up dependencies
TaskUpdate({ taskId: "3", addBlockedBy: ["1", "2"] })

// Change subject or description
TaskUpdate({ taskId: "2", subject: "New title", description: "Updated description" })

// Delete a task
TaskUpdate({ taskId: "2", status: "deleted" })
```

Status progresses: `pending` -> `in_progress` -> `completed`. Use `deleted` to permanently remove.

### Updatable fields:
- `status`: pending | in_progress | completed | deleted
- `subject`: Change the task title
- `description`: Change the task description
- `activeForm`: Present continuous form shown in spinner when in_progress
- `owner`: Change the task owner (agent name)
- `metadata`: Merge metadata keys into the task (set a key to null to delete it)
- `addBlocks`: Mark tasks that cannot start until this one completes
- `addBlockedBy`: Mark tasks that must complete before this one can start

---

## 6. Teammate Spawning Options

### Two Methods to Spawn Agents

#### Method 1: Task Tool (Subagents -- No Team)

For short-lived, focused work that returns a result:

```javascript
Task({
  subagent_type: "Explore",
  description: "Find auth files",
  prompt: "Find all authentication-related files in this codebase",
  model: "haiku"  // Optional: haiku, sonnet, opus
})
```

Characteristics:
- Runs synchronously (blocks until complete) or async with `run_in_background: true`
- Returns result directly to you
- No team membership required
- Best for: searches, analysis, focused research

#### Method 2: Task Tool + team_name + name (Teammates)

For persistent teammates with ongoing collaboration:

```javascript
Task({
  team_name: "my-project",
  name: "security-reviewer",
  subagent_type: "general-purpose",
  prompt: "Review all authentication code for vulnerabilities. Send findings to team-lead.",
  run_in_background: true
})
```

Characteristics:
- Joins team, appears in config.json
- Communicates via inbox messages
- Can claim tasks from shared task list
- Persists until shutdown
- Best for: parallel work, ongoing collaboration, pipeline stages

### Key Spawning Parameters

| Parameter | Values | Description |
|-----------|--------|-------------|
| `subagent_type` | `"Explore"`, `"Plan"`, `"general-purpose"`, `"Bash"`, custom agent names | Type of agent to spawn |
| `model` | `"haiku"`, `"sonnet"`, `"opus"`, `"inherit"` | Model to use (default: inherit from parent) |
| `prompt` | string | Task-specific instructions for the teammate |
| `team_name` | string | Team to join (makes it a teammate) |
| `name` | string | Teammate's name (required with team_name) |
| `run_in_background` | boolean | Run asynchronously (default: false) |
| `mode` | `"plan"`, `"bypassPermissions"`, etc. | Permission mode |
| `isolation` | `"worktree"` | Run in isolated git worktree |

### Built-in Agent Types

| Type | Tools | Model | Best For |
|------|-------|-------|----------|
| **Explore** | Read-only (no Edit, Write) | Haiku (fast) | Codebase exploration, file search |
| **Plan** | Read-only | Inherits | Architecture planning, implementation strategies |
| **general-purpose** | All tools (*) | Inherits | Multi-step tasks, research + action |
| **Bash** | Bash only | Inherits | Git operations, command execution |
| **claude-code-guide** | Read-only + WebFetch + WebSearch | -- | Questions about Claude Code |
| **statusline-setup** | Read, Edit only | Sonnet | Configuring status line |

### Subagent Type vs Teammate Comparison

| Aspect | Task (subagent) | Task + team_name + name (teammate) |
|--------|-----------------|-----------------------------------|
| Lifespan | Until task complete | Until shutdown requested |
| Communication | Return value | Inbox messages |
| Task access | None | Shared task list |
| Team membership | No | Yes |
| Coordination | One-off | Ongoing |

---

## 7. Display Modes

Agent teams support two display modes:

### In-Process (Default)

All teammates run inside your main terminal. Use Shift+Down to cycle through teammates and type to message them directly. Works in any terminal, no extra setup required.

### Split Panes

Each teammate gets its own pane. You can see everyone's output at once and click into a pane to interact directly. Requires tmux or iTerm2.

### Configuration

Default is `"auto"`, which uses split panes if you're already running inside a tmux session, and in-process otherwise.

```json
{
  "teammateMode": "auto|in-process|tmux"
}
```

CLI override for a single session:
```bash
claude --teammate-mode in-process
```

### tmux/iTerm2 Setup

**tmux**: Install through your system's package manager.
```bash
brew install tmux  # macOS
```

**iTerm2**: Install the `it2` CLI, then enable the Python API in iTerm2 Settings > General > Magic > Enable Python API.
```bash
uv tool install it2
# OR
pipx install it2
```

> **Note**: `tmux` has known limitations on certain operating systems and traditionally works best on macOS. Using `tmux -CC` in iTerm2 is the suggested entrypoint.

---

## 8. Spawn Backends

A backend determines how teammate Claude instances actually run. Three backends are supported with auto-detection.

### Backend Comparison

| Backend | How It Works | Visibility | Persistence | Speed |
|---------|-------------|-----------|-------------|-------|
| **in-process** | Same Node.js process as leader | Hidden (background) | Dies with leader | Fastest |
| **tmux** | Separate terminal in tmux session | Visible in tmux | Survives leader exit | Medium |
| **iterm2** | Split panes in iTerm2 window | Visible side-by-side | Dies with window | Medium |

### Auto-Detection Logic

1. Running inside tmux? (`$TMUX` set) -> Use tmux backend
2. Running in iTerm2? (`$TERM_PROGRAM === "iTerm.app"`) -> Use iterm2 backend (if `it2` CLI installed)
3. tmux available? (`which tmux`) -> Use tmux (external session)
4. Otherwise: Use in-process

### Forcing a Backend

```bash
export CLAUDE_CODE_SPAWN_BACKEND=in-process  # fastest, no visibility
export CLAUDE_CODE_SPAWN_BACKEND=tmux        # visible panes, persistent
unset CLAUDE_CODE_SPAWN_BACKEND              # auto-detect (default)
```

### Troubleshooting Backends

| Issue | Cause | Solution |
|-------|-------|----------|
| "No pane backend available" | Neither tmux nor iTerm2 available | Install tmux: `brew install tmux` |
| "it2 CLI not installed" | In iTerm2 but missing it2 | Run `uv tool install it2` |
| "Python API not enabled" | it2 can't communicate with iTerm2 | Enable in iTerm2 Settings > General > Magic |
| Workers not visible | Using in-process backend | Start inside tmux or iTerm2 |
| Workers dying unexpectedly | Outside tmux, leader exited | Use tmux for persistence |

---

## 9. Communication and Messaging

### SendMessage Tool

The primary communication mechanism between teammates:

#### Direct Message (type: "message")

```javascript
SendMessage({
  type: "message",
  recipient: "security-reviewer",
  content: "Please prioritize the authentication module.",
  summary: "Prioritize auth module review"
})
```

#### Broadcast (type: "broadcast") -- USE SPARINGLY

```javascript
SendMessage({
  type: "broadcast",
  content: "Status check: Please report your progress",
  summary: "Status check for all teammates"
})
```

**WARNING**: Broadcasting is expensive. Each broadcast sends a separate message to every teammate (N teammates = N messages). Use `message` for targeted communication.

#### Shutdown Request (type: "shutdown_request")

```javascript
SendMessage({
  type: "shutdown_request",
  recipient: "researcher",
  content: "Task complete, wrapping up the session"
})
```

#### Shutdown Response (type: "shutdown_response")

```javascript
// Approve shutdown
SendMessage({
  type: "shutdown_response",
  request_id: "abc-123",
  approve: true
})

// Reject shutdown
SendMessage({
  type: "shutdown_response",
  request_id: "abc-123",
  approve: false,
  content: "Still working on task #3, need 5 more minutes"
})
```

#### Plan Approval Response (type: "plan_approval_response")

```javascript
// Approve plan
SendMessage({
  type: "plan_approval_response",
  request_id: "abc-123",
  recipient: "researcher",
  approve: true
})

// Reject plan
SendMessage({
  type: "plan_approval_response",
  request_id: "abc-123",
  recipient: "researcher",
  approve: false,
  content: "Please add error handling for the API calls"
})
```

### Message Formats (JSON in Inboxes)

**Regular Message:**
```json
{
  "from": "team-lead",
  "text": "Please prioritize the auth module",
  "timestamp": "2026-01-25T23:38:32.588Z",
  "read": false
}
```

**Shutdown Request:**
```json
{
  "type": "shutdown_request",
  "requestId": "shutdown-abc123@worker-1",
  "from": "team-lead",
  "reason": "All tasks complete",
  "timestamp": "2026-01-25T23:38:32.588Z"
}
```

**Idle Notification (auto-sent when teammate stops):**
```json
{
  "type": "idle_notification",
  "from": "worker-1",
  "timestamp": "2026-01-25T23:40:00.000Z",
  "completedTaskId": "2",
  "completedStatus": "completed"
}
```

**Plan Approval Request:**
```json
{
  "type": "plan_approval_request",
  "from": "architect",
  "requestId": "plan-xyz789",
  "planContent": "# Implementation Plan\n\n1. ...",
  "timestamp": "2026-01-25T23:41:00.000Z"
}
```

**Permission Request:**
```json
{
  "type": "permission_request",
  "requestId": "perm-123",
  "workerId": "worker-1@my-project",
  "workerName": "worker-1",
  "workerColor": "#4A90D9",
  "toolName": "Bash",
  "toolUseId": "toolu_abc123",
  "description": "Run npm install",
  "input": {"command": "npm install"},
  "permissionSuggestions": ["Bash(npm *)"],
  "createdAt": 1706000000000
}
```

### Key Communication Rules

- **Teammates' plain text output is NOT visible to the team lead or other teammates.** To communicate, they MUST use SendMessage.
- Messages from teammates are automatically delivered (no need to poll).
- When a teammate finishes and stops, they automatically notify the lead via idle notification.
- All agents can see task status and claim available work through the shared task list.

---

## 10. Plan Approval Workflow

For complex or risky tasks, you can require teammates to plan before implementing. The teammate works in read-only plan mode until the lead approves their approach.

### Requesting Plan Mode

```
Spawn an architect teammate to refactor the authentication module.
Require plan approval before they make any changes.
```

### Flow

1. Teammate spawns in plan mode (read-only exploration)
2. Teammate creates a plan and sends a `plan_approval_request` to the lead
3. Lead reviews the plan
4. Lead approves or rejects with feedback:

```javascript
// Approve
SendMessage({
  type: "plan_approval_response",
  request_id: "plan-456",
  recipient: "architect",
  approve: true
})

// Reject with feedback
SendMessage({
  type: "plan_approval_response",
  request_id: "plan-456",
  recipient: "architect",
  approve: false,
  content: "Please add error handling for the API calls"
})
```

5. If rejected, teammate stays in plan mode, revises, and resubmits
6. Once approved, teammate exits plan mode and begins implementation

### Important Behaviors

- **Plan mode is evaluated every turn**, not one-time. It filters every action throughout a teammate's lifetime.
- **Fixed lifetime**: Once spawned in a mode, teammates stay in that mode forever. To transition from planning to execution, spawn a new default-mode teammate and hand off the plan.
- The lead makes approval decisions autonomously. Influence the lead's judgment by giving it criteria: "only approve plans that include test coverage" or "reject plans that modify the database schema."

### Environment Variable

```
CLAUDE_CODE_PLAN_MODE_REQUIRED=true
```

Auto-set by Claude Code when spawning teammates that require plan approval.

---

## 11. Hooks: TeammateIdle and TaskCompleted

These two hooks are the quality gate mechanism for agent teams.

### TeammateIdle Hook

**When it fires**: When an agent team teammate is about to go idle after finishing its turn.

**Purpose**: Enforce quality gates before a teammate stops working (e.g., require passing lint checks, verify output files exist).

**Matchers**: Does NOT support matchers -- fires on every occurrence.

#### TeammateIdle Input

```json
{
  "session_id": "abc123",
  "transcript_path": "/Users/.../.claude/projects/.../transcript.jsonl",
  "cwd": "/Users/...",
  "permission_mode": "default",
  "hook_event_name": "TeammateIdle",
  "teammate_name": "researcher",
  "team_name": "my-project"
}
```

| Field           | Description                                   |
|:----------------|:----------------------------------------------|
| `teammate_name` | Name of the teammate that is about to go idle |
| `team_name`     | Name of the team                              |

#### TeammateIdle Decision Control

Two ways to control behavior:

1. **Exit code 2**: The teammate receives the stderr message as feedback and **continues working** instead of going idle.
2. **JSON `{"continue": false, "stopReason": "..."}`**: Stops the teammate entirely (matches Stop hook behavior). The `stopReason` is shown to the user.

#### TeammateIdle Example Script

```bash
#!/bin/bash
# Check that a build artifact exists before allowing idle

if [ ! -f "./dist/output.js" ]; then
  echo "Build artifact missing. Run the build before stopping." >&2
  exit 2
fi

exit 0
```

#### TeammateIdle Configuration (settings.json)

```json
{
  "hooks": {
    "TeammateIdle": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/teammate-idle-check.sh"
          }
        ]
      }
    ]
  }
}
```

### TaskCompleted Hook

**When it fires**: Two situations:
1. When any agent explicitly marks a task as completed through the TaskUpdate tool
2. When an agent team teammate finishes its turn with in-progress tasks

**Purpose**: Enforce completion criteria like passing tests or lint checks before a task can close.

**Matchers**: Does NOT support matchers -- fires on every occurrence.

#### TaskCompleted Input

```json
{
  "session_id": "abc123",
  "transcript_path": "/Users/.../.claude/projects/.../transcript.jsonl",
  "cwd": "/Users/...",
  "permission_mode": "default",
  "hook_event_name": "TaskCompleted",
  "task_id": "task-001",
  "task_subject": "Implement user authentication",
  "task_description": "Add login and signup endpoints",
  "teammate_name": "implementer",
  "team_name": "my-project"
}
```

| Field              | Description                                             |
|:-------------------|:--------------------------------------------------------|
| `task_id`          | Identifier of the task being completed                  |
| `task_subject`     | Title of the task                                       |
| `task_description` | Detailed description of the task. May be absent         |
| `teammate_name`    | Name of the teammate completing the task. May be absent |
| `team_name`        | Name of the team. May be absent                         |

#### TaskCompleted Decision Control

Two ways to control:

1. **Exit code 2**: The task is NOT marked as completed. The stderr message is fed back to the model as feedback.
2. **JSON `{"continue": false, "stopReason": "..."}`**: Stops the teammate entirely (matches Stop hook behavior).

#### TaskCompleted Example Script

```bash
#!/bin/bash
INPUT=$(cat)
TASK_SUBJECT=$(echo "$INPUT" | jq -r '.task_subject')

# Run the test suite
if ! npm test 2>&1; then
  echo "Tests not passing. Fix failing tests before completing: $TASK_SUBJECT" >&2
  exit 2
fi

exit 0
```

#### TaskCompleted Configuration (settings.json)

```json
{
  "hooks": {
    "TaskCompleted": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/task-completed-check.sh"
          }
        ]
      }
    ]
  }
}
```

### Hook Exit Code Summary for Team Hooks

| Hook event     | Can block? | Exit 2 behavior                                                   |
|:---------------|:-----------|:-------------------------------------------------------------------|
| TeammateIdle   | Yes        | Prevents the teammate from going idle (teammate continues working) |
| TaskCompleted  | Yes        | Prevents the task from being marked as completed                   |

---

## 12. Direct Teammate Interaction

Each teammate is a full, independent Claude Code session. You can message any teammate directly.

### In-Process Mode

- **Shift+Down**: Cycle through teammates
- **Enter**: View a teammate's session
- **Escape**: Interrupt their current turn
- **Ctrl+T**: Toggle the task list
- **Ctrl+J**: Toggle agent view

After the last teammate, Shift+Down wraps back to the lead.

### Split-Pane Mode

Click into a teammate's pane to interact with their session directly. Each teammate has a full view of their own terminal.

### Shutting Down a Teammate

```
Ask the researcher teammate to shut down
```

The lead sends a shutdown request. The teammate can approve (exiting gracefully) or reject with an explanation. Teammates finish their current request or tool call before shutting down, which can take time.

---

## 13. Task Dependencies and Auto-Unblocking

Tasks can depend on other tasks. A pending task with unresolved dependencies cannot be claimed until those dependencies are completed.

### Setting Up Dependencies

```javascript
// Create pipeline
TaskCreate({ subject: "Step 1: Research" })        // #1
TaskCreate({ subject: "Step 2: Implement" })       // #2
TaskCreate({ subject: "Step 3: Test" })            // #3
TaskCreate({ subject: "Step 4: Deploy" })          // #4

// Set up dependencies
TaskUpdate({ taskId: "2", addBlockedBy: ["1"] })   // #2 waits for #1
TaskUpdate({ taskId: "3", addBlockedBy: ["2"] })   // #3 waits for #2
TaskUpdate({ taskId: "4", addBlockedBy: ["3"] })   // #4 waits for #3
```

### Auto-Unblocking

When a teammate completes a task that other tasks depend on, blocked tasks unblock without manual intervention:

- When #1 completes, #2 auto-unblocks
- When #2 completes, #3 auto-unblocks
- etc.

### Wave Execution

Tasks execute in waves based on dependencies:
- **Wave 1**: Tasks with no dependencies run in parallel
- **Wave 2**: Tasks blocked by Wave 1 remain pending until dependencies complete
- **Wave 3+**: Sequential waves based on dependency chain

---

## 14. Self-Claiming Patterns

Teammates can self-claim tasks from the shared task list. The lead can assign tasks explicitly, or teammates can claim on their own.

### Swarm Worker Pattern

```javascript
const swarmPrompt = `
You are a swarm worker. Your job is to continuously process available tasks.
LOOP:
1. Call TaskList() to see available tasks
2. Find a task that is:
   - status: 'pending'
   - no owner
   - not blocked
3. If found:
   - Claim it: TaskUpdate({ taskId: "X", owner: "YOUR_NAME" })
   - Start it: TaskUpdate({ taskId: "X", status: "in_progress" })
   - Do the review work
   - Complete it: TaskUpdate({ taskId: "X", status: "completed" })
   - Send findings to team-lead via SendMessage
   - Go back to step 1
4. If no tasks available:
   - Send idle notification to team-lead
   - Wait and try again (up to 3 times)
   - If still no tasks, exit
Replace YOUR_NAME with your actual agent name.
`
```

### Workflow

1. After completing your current task, call TaskList to find available work
2. Look for tasks with status 'pending', no owner, and empty blockedBy
3. **Prefer tasks in ID order** (lowest ID first) -- earlier tasks often set up context for later ones
4. Claim an available task using TaskUpdate (set `owner` to your name)
5. If blocked, focus on unblocking tasks or notify the team lead

---

## 15. File Locking for Concurrent Claims

Task claiming uses **file locking** to prevent race conditions when multiple teammates try to claim the same task simultaneously.

This is handled automatically by Claude Code's task system. When a teammate calls `TaskUpdate` to claim a task, the system:
1. Acquires a file lock on the task JSON file
2. Checks if the task is still available (pending, no owner, not blocked)
3. If available, assigns the owner and changes status
4. Releases the lock

This ensures that even with multiple teammates racing to claim work, each task is claimed by exactly one teammate.

---

## 16. Team Size Guidance

There's no hard limit on the number of teammates, but practical constraints apply:

### Official Recommendations

- **Start with 3-5 teammates** for most workflows
- **5-6 tasks per teammate** keeps everyone productive without excessive context switching
- Having 15 independent tasks? 3 teammates is a good starting point
- **Three focused teammates often outperform five scattered ones**
- Scale up only when the work genuinely benefits from having teammates work simultaneously

### Why These Limits

- **Token costs scale linearly**: Each teammate has its own context window
- **Coordination overhead increases**: More teammates means more communication, task coordination, and potential for conflicts
- **Diminishing returns**: Beyond a certain point, additional teammates don't speed up work proportionally

### Task Sizing

- **Too small**: Coordination overhead exceeds the benefit
- **Too large**: Teammates work too long without check-ins, increasing risk of wasted effort
- **Just right**: Self-contained units that produce a clear deliverable (a function, a test file, a review)

---

## 17. Token Costs

### Average Costs

- Average Claude Code cost: ~$6 per developer per day ($100-200/month with Sonnet 4.6)
- 90% of users stay below $12/day

### Agent Team Token Scaling

Agent teams use approximately **7x more tokens** than standard sessions when teammates run in plan mode, because each teammate maintains its own context window.

| Approach | Approximate Tokens | Best For |
|----------|-------------------|----------|
| Solo session | ~200k | Direct control, small tasks |
| 3 subagents | ~440k | Focused parallel research |
| 3-person team | ~800k | Multi-file features, coordination |
| 5-person team | ~1.2M+ | Large-scale parallel work |

### Cost Optimization Tips

1. **Use Sonnet for teammates**: Balances capability and cost for coordination tasks
2. **Keep teams small**: Each teammate runs its own context window
3. **Keep spawn prompts focused**: Everything in the spawn prompt adds to context from start
4. **Clean up teams when work is done**: Active teammates continue consuming tokens even if idle
5. **Delegate verbose operations to subagents**: Use subagents for test running, log processing
6. **Use Plan mode first**: Plan is cheaper (read-only), then execute with a team

### Rate Limit Recommendations (Per-User)

| Team size     | TPM per user | RPM per user |
|---------------|-------------|-------------|
| 1-5 users     | 200k-300k  | 5-7         |
| 5-20 users    | 100k-150k  | 2.5-3.5     |
| 20-50 users   | 50k-75k    | 1.25-1.75   |
| 50-100 users  | 25k-35k    | 0.62-0.87   |
| 100-500 users | 15k-20k    | 0.37-0.47   |
| 500+ users    | 10k-15k    | 0.25-0.35   |

---

## 18. Subagents vs Agent Teams Comparison

|                   | Subagents                                        | Agent Teams                                         |
|:------------------|:-------------------------------------------------|:----------------------------------------------------|
| **Context**       | Own context window; results return to the caller | Own context window; fully independent               |
| **Communication** | Report results back to the main agent only       | Teammates message each other directly               |
| **Coordination**  | Main agent manages all work                      | Shared task list with self-coordination             |
| **Best for**      | Focused tasks where only the result matters      | Complex work requiring discussion and collaboration |
| **Token cost**    | Lower: results summarized back to main context   | Higher: each teammate is a separate Claude instance |
| **Session**       | Within a single session                          | Across separate sessions                            |
| **Topology**      | Hub-and-spoke                                    | Mesh communication                                  |
| **Nesting**       | Cannot spawn other subagents                     | Cannot spawn nested teams                           |

**Use subagents when**: You need quick, focused workers that report back. Only the result matters.

**Use agent teams when**: Teammates need to share findings, challenge each other, and coordinate on their own.

---

## 19. Orchestration Patterns

### Pattern 1: Parallel Specialists (Leader Pattern)

Multiple specialists review code simultaneously:

```javascript
// 1. Create team
Teammate({ operation: "spawnTeam", team_name: "code-review" })

// 2. Spawn specialists in parallel
Task({
  team_name: "code-review",
  name: "security",
  subagent_type: "general-purpose",
  prompt: "Review PR for security vulnerabilities. Focus on: SQL injection, XSS, auth bypass. Send findings to team-lead.",
  run_in_background: true
})

Task({
  team_name: "code-review",
  name: "performance",
  subagent_type: "general-purpose",
  prompt: "Review PR for performance issues. Focus on: N+1 queries, memory leaks, slow algorithms.",
  run_in_background: true
})

Task({
  team_name: "code-review",
  name: "simplicity",
  subagent_type: "general-purpose",
  prompt: "Review PR for unnecessary complexity. Focus on: over-engineering, YAGNI violations.",
  run_in_background: true
})

// 3. Wait for results, synthesize findings
// 4. Shutdown teammates and cleanup
```

### Pattern 2: Pipeline (Sequential Dependencies)

Each stage depends on the previous:

```javascript
// Create tasks with dependencies
TaskCreate({ subject: "Research" })      // #1
TaskCreate({ subject: "Plan" })          // #2
TaskCreate({ subject: "Implement" })     // #3
TaskCreate({ subject: "Test" })          // #4
TaskCreate({ subject: "Review" })        // #5

TaskUpdate({ taskId: "2", addBlockedBy: ["1"] })
TaskUpdate({ taskId: "3", addBlockedBy: ["2"] })
TaskUpdate({ taskId: "4", addBlockedBy: ["3"] })
TaskUpdate({ taskId: "5", addBlockedBy: ["4"] })

// Spawn workers -- they'll auto-claim as tasks unblock
```

### Pattern 3: Swarm (Self-Organizing)

Workers grab available tasks from a pool:

```javascript
// Create independent tasks (no dependencies)
for (const file of fileList) {
  TaskCreate({
    subject: `Review ${file}`,
    description: `Review ${file} for issues`
  })
}

// Spawn worker swarm with self-claim instructions
// Workers race to claim tasks, naturally load-balance
```

### Pattern 4: Research + Implementation

Research first (cheap), then implement (expensive):

```javascript
// 1. Synchronous research (returns results)
const research = await Task({
  subagent_type: "Explore",
  prompt: "Research caching best practices..."
})

// 2. Use research to guide implementation
Task({
  subagent_type: "general-purpose",
  prompt: `Implement caching based on: ${research.content}`
})
```

### Pattern 5: Competing Hypotheses (Debate)

```
Spawn 5 agent teammates to investigate different hypotheses about
why the app exits after one message. Have them talk to each other to
try to disprove each other's theories, like a scientific debate.
```

The debate structure is key. Sequential investigation suffers from anchoring: once one theory is explored, subsequent investigation is biased. With multiple independent investigators actively trying to disprove each other, the surviving theory is more likely to be correct.

### Pattern 6: Coordinated Multi-File Refactoring

```javascript
// Create tasks with clear file boundaries
TaskCreate({ subject: "Refactor User model", description: "Extract auth methods to concern" })
TaskCreate({ subject: "Refactor Session controller", description: "Update to use new concern" })
TaskCreate({ subject: "Update specs", description: "Update all auth specs" })

// Specs depend on both refactors completing
TaskUpdate({ taskId: "3", addBlockedBy: ["1", "2"] })

// Spawn workers for each task (different file sets)
```

---

## 20. Best Practices (Official + Community)

### Context and Clarity

1. **Give teammates enough context**: They load project context automatically (CLAUDE.md, MCP servers, skills) but don't inherit the lead's conversation history. Include task-specific details in the spawn prompt.

```
Spawn a security reviewer teammate with the prompt: "Review the authentication module
at src/auth/ for security vulnerabilities. Focus on token handling, session
management, and input validation. The app uses JWT tokens stored in
httpOnly cookies. Report any issues with severity ratings."
```

2. **Write exhaustive spawn prompts**: Include exact file paths, what to change, acceptance criteria, constraints, which bead to close. Agents have NO conversation history from the leader.

### File Ownership (Critical)

3. **Avoid file conflicts**: Two teammates editing the same file leads to overwrites. Break the work so each teammate owns a different set of files. Assign by directory boundaries.

4. **Mark unavoidable shared files** as "coordinate before editing" in CLAUDE.md.

### Task Management

5. **Size tasks appropriately**: 5-6 tasks per teammate keeps everyone productive. Self-contained units that produce a clear deliverable.

6. **Use task dependencies**: Let the system manage unblocking via `addBlockedBy`. Don't make teammates poll.

7. **The description field is the agent's instruction**: Pack detail here -- specific URLs, file paths, acceptance criteria.

### Team Management

8. **Enable delegate mode** (`Shift+Tab`) immediately when starting a team. This restricts the lead to coordination-only tools, preventing it from grabbing implementation tasks.

9. **Monitor and steer**: Check in via Ctrl+T regularly. Redirect approaches that aren't working. Letting a team run unattended too long increases risk of wasted effort.

10. **Wait for teammates to finish**: Sometimes the lead starts implementing tasks itself. If noticed:
```
Wait for your teammates to complete their tasks before proceeding
```

### Starting Out

11. **Start with research and review** if new to agent teams. Tasks with clear boundaries that don't require writing code: reviewing a PR, researching a library, investigating a bug.

### Cleanup

12. **Always cleanup**: Don't leave orphaned teams. Always call cleanup when done.
13. **Shut down all teammates before cleanup**: Cleanup will fail if teammates are still active.

### Permission Pre-Configuration

14. **Pre-approve common operations** in your permission settings before spawning teammates to reduce interruptions.

### CLAUDE.md Optimization

15. **Structure CLAUDE.md with verification criteria** so teammates know what "verified" means. This activates self-reporting without lead guidance.

### Model Selection

16. **Use Opus for lead** (coordination, complex reasoning), **Sonnet for teammates** (execution, cheaper).

### Phased Execution

17. **Run sequential smaller teams** rather than one massive parallel team for cleaner results.
18. **Plan first with plan mode** (cheap, read-only), then execute with a team (expensive but fast).

---

## 21. Troubleshooting Guide

### Teammates Not Appearing

- In in-process mode, press Shift+Down to cycle through active teammates (they may be running but not visible)
- Check that the task was complex enough to warrant a team
- If you requested split panes, ensure tmux is installed: `which tmux`
- For iTerm2, verify `it2` CLI is installed and Python API is enabled

### Too Many Permission Prompts

- Pre-approve common operations in your permission settings before spawning teammates
- Use `mode: "bypassPermissions"` for teammates (see Permissions section)

### Teammates Stopping on Errors

- Check their output using Shift+Down (in-process) or by clicking the pane (split mode)
- Give them additional instructions directly
- Spawn a replacement teammate to continue the work

### Lead Shuts Down Before Work Is Done

- Tell the lead to keep going
- Tell the lead to wait for teammates to finish before proceeding
- Use delegate mode to prevent lead from implementing

### Orphaned tmux Sessions

```bash
tmux ls                       # List sessions
tmux kill-session -t <name>   # Kill specific session
```

### File Conflicts Between Teammates

- Define explicit file boundaries in spawn prompt
- Use directory ownership (each teammate owns different directories)

### Task Status Stuck

- Check manually if work is actually done
- Prompt teammate to update status
- Update task status via TaskUpdate if needed

### Bedrock/Vertex/Foundry Failures

- Update to v2.1.45+

### Crash on Settings Toggle

- Update to v2.1.34+

### tmux Messaging Failures

- Update to v2.1.33+

---

## 22. Known Limitations

| Limitation | Details |
|------------|---------|
| **No session resumption** | `/resume` and `/rewind` do not restore in-process teammates. After resuming, the lead may attempt to message teammates that no longer exist. Tell the lead to spawn new teammates. |
| **Task status can lag** | Teammates sometimes fail to mark tasks as completed, which blocks dependent tasks. Check manually and update status if needed. |
| **Shutdown can be slow** | Teammates finish their current request or tool call before shutting down. |
| **One team per session** | A lead can only manage one team at a time. Clean up the current team before starting a new one. |
| **No nested teams** | Teammates cannot spawn their own teams or teammates. Only the lead can manage the team. |
| **Lead is fixed** | The session that creates the team is the lead for its lifetime. No promotion or transfer. |
| **Permissions set at spawn** | All teammates start with the lead's permission mode. Can change individually after spawning, but not per-teammate at spawn time. |
| **Split panes limited** | Requires tmux or iTerm2. Not supported in VS Code integrated terminal, Windows Terminal, or Ghostty. |
| **Plan mode is permanent** | Once spawned in plan mode, teammates stay in plan mode forever. Spawn a new teammate for execution. |
| **5-minute heartbeat timeout** | If a teammate crashes, it's automatically marked inactive after 5 minutes. Other teammates can then claim its tasks. |

---

## 23. Real-World Examples

### Example 1: Blog QA Swarm (from Addy Osmani)

A developer ran a 5-agent QA team against a blog at `localhost:4321`:

**Prompt**: "Use a team of agents that will do QA against my blog."

**Task Breakdown**:
- Agent 1: Verified 16 core URLs return HTTP 200 with valid HTML
- Agent 2: Tested 83 blog posts for h1 tags, meta tags, working images
- Agent 3: Checked 146 internal links for broken references
- Agent 4: Validated RSS feeds, robots.txt, SEO metadata (og:tags, JSON-LD)
- Agent 5: Audited heading hierarchy, ARIA attributes, theme toggle

**Results**:
- All agents completed in ~3 minutes running in parallel
- Identified 10 issues ranked by severity (4 major, 2 medium, 4 minor)
- Lead synthesized findings into single prioritized report
- Cost: ~1.2M tokens total (~200k per agent + 200k for lead)

### Example 2: CLI Tool Design (from official docs)

```
I'm designing a CLI tool that helps developers track TODO comments across
their codebase. Create an agent team to explore this from different angles:
one teammate on UX, one on technical architecture, one playing devil's advocate.
```

Three roles are independent and can explore without waiting on each other. The devil's advocate challenges the other two's findings.

### Example 3: Parallel Code Review

```
Create an agent team to review PR #142. Spawn three reviewers:
- One focused on security implications
- One checking performance impact
- One validating test coverage
Have them each review and report findings.
```

Each reviewer works from the same PR but applies a different filter. The lead synthesizes findings.

### Example 4: Debugging with Competing Hypotheses

```
Users report the app exits after one message instead of staying connected.
Spawn 5 agent teammates to investigate different hypotheses. Have them talk to
each other to try to disprove each other's theories, like a scientific debate.
```

Multiple independent investigators actively trying to disprove each other. The theory that survives is more likely to be the actual root cause.

### Example 5: Cross-Layer Feature Implementation

```
Create a team with two teammates:
- one implementing the new /api/users endpoint in src/routes/
- another building the user profile component in src/components/
They should coordinate on the API contract.
```

Each teammate owns separate component, coordinates through task list without file conflicts.

---

## 24. Environment Variables Reference

### Agent Team Variables

| Variable | Purpose | Auto-set? |
|----------|---------|-----------|
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | Enable agent teams (set to `1`) | No, user must set |
| `CLAUDE_CODE_TEAM_NAME` | Name of the agent team this teammate belongs to | Yes, auto-set on teammates |
| `CLAUDE_CODE_AGENT_ID` | Unique identifier for the agent | Yes, auto-set |
| `CLAUDE_CODE_AGENT_NAME` | Agent's name within the team | Yes, auto-set |
| `CLAUDE_CODE_AGENT_TYPE` | Agent type (e.g., "Explore", "general-purpose") | Yes, auto-set |
| `CLAUDE_CODE_AGENT_COLOR` | Agent's color for UI display | Yes, auto-set |
| `CLAUDE_CODE_PLAN_MODE_REQUIRED` | Whether plan approval is required (set to "true") | Yes, auto-set when applicable |
| `CLAUDE_CODE_PARENT_SESSION_ID` | Session ID of the parent/lead session | Yes, auto-set |
| `CLAUDE_CODE_SPAWN_BACKEND` | Force backend: `in-process`, `tmux`, or unset for auto-detect | No, user may set |
| `CLAUDE_CODE_SUBAGENT_MODEL` | Configure model for subagents | No, user may set |
| `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS` | Set to `1` to disable all background task functionality | No, user may set |

### Using in Prompts

```javascript
Task({
  team_name: "my-project",
  name: "worker",
  subagent_type: "general-purpose",
  prompt: "Your name is $CLAUDE_CODE_AGENT_NAME. Use it when sending messages."
})
```

---

## 25. File and Storage Paths

| Path | Contents |
|------|----------|
| `~/.claude/teams/{team-name}/config.json` | Team configuration (members, lead, colors) |
| `~/.claude/teams/{team-name}/inboxes/{agent}.json` | Agent inbox (messages) |
| `~/.claude/tasks/{team-name}/` | Task JSON files |
| `~/.claude/tasks/{team-name}/N.json` | Individual task files |
| `~/.claude/projects/{project}/{sessionId}/subagents/` | Subagent transcripts |
| `~/.claude/projects/{project}/{sessionId}/subagents/agent-{agentId}.jsonl` | Individual subagent transcript |

### Debugging Commands

```bash
# Check team config
cat ~/.claude/teams/{team}/config.json | jq '.members[] | {name, agentType, backendType}'

# Check teammate inboxes
cat ~/.claude/teams/{team}/inboxes/{agent}.json | jq '.'

# List all teams
ls ~/.claude/teams/

# Check task states
cat ~/.claude/tasks/{team}/*.json | jq '{id, subject, status, owner, blockedBy}'

# Watch for new messages
tail -f ~/.claude/teams/{team}/inboxes/team-lead.json
```

---

## 26. TeamDelete / Cleanup

### Via TeammateTool

```javascript
Teammate({ operation: "cleanup" })
```

This removes:
- `~/.claude/teams/{team-name}/` directory (config and inboxes)
- `~/.claude/tasks/{team-name}/` directory (all tasks)

### Important Rules

- **Will fail if teammates are still active** -- call `requestShutdown` for all teammates first
- **Always use the lead to clean up** -- teammates should not run cleanup because their team context may not resolve correctly
- **Wait for shutdown approvals** before calling cleanup

### Graceful Shutdown Sequence

```javascript
// 1. Request shutdown for all teammates
Teammate({ operation: "requestShutdown", target_agent_id: "worker-1" })
Teammate({ operation: "requestShutdown", target_agent_id: "worker-2" })

// 2. Wait for shutdown approvals
// Check for {"type": "shutdown_approved", ...} messages

// 3. Verify no active members
// Read ~/.claude/teams/{team}/config.json

// 4. Only then cleanup
Teammate({ operation: "cleanup" })
```

### Handling Crashed Teammates

Teammates have a 5-minute heartbeat timeout. If a teammate crashes:
1. They'll be automatically marked as inactive after timeout
2. Their tasks remain in the task list
3. Another teammate can claim their tasks
4. Cleanup will work after timeout expires

---

## 27. Permissions in Teams

### How Permissions Work

- Teammates start with the lead's permission settings
- If the lead runs with `--dangerously-skip-permissions`, all teammates do too
- After spawning, you can change individual teammate modes
- You cannot set per-teammate modes at spawn time

### Permission Modes

| Mode | Description |
|------|-------------|
| `default` | Standard permission checking with prompts |
| `acceptEdits` | Auto-accept file edits |
| `dontAsk` | Auto-deny permission prompts (explicitly allowed tools still work) |
| `bypassPermissions` | Skip all permission checks (use with caution) |
| `plan` | Plan mode (read-only exploration) |

### Practical Recommendation

For teams, use `mode: "bypassPermissions"` on teammates to prevent them from blocking on permission prompts and going idle. This is the most common pattern for productive teams.

```json
{
  "permissions": {
    "allow": [
      "Bash(npm run *)",
      "Bash(git commit *)",
      "Edit",
      "Write",
      "Read"
    ]
  }
}
```

Pre-approve common operations before spawning to avoid permission prompt floods.

---

## 28. Settings Reference

### Agent Team Settings

| Setting | Values | Description |
|---------|--------|-------------|
| `teammateMode` | `"auto"`, `"in-process"`, `"tmux"` | How teammates display |
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | `"1"` | Enable agent teams |
| `CLAUDE_CODE_SPAWN_BACKEND` | `"in-process"`, `"tmux"`, unset | Force spawn backend |

### CLI Flags

| Flag | Description |
|------|-------------|
| `--teammate-mode <mode>` | Override teammateMode for this session |
| `--dangerously-skip-permissions` | Bypass all permission checks (propagates to teammates) |
| `--agents <json>` | Define session-only subagents as JSON |

### Related Settings

| Setting | Description |
|---------|-------------|
| `disableAllHooks` | Disables all hooks (affects TeammateIdle, TaskCompleted) |
| `allowManagedHooksOnly` | Only managed hooks and SDK hooks (managed settings only) |
| `model` | Default model for all agents and subagents |
| `plansDirectory` | Where plan files are stored (relevant for plan approval) |
| `permissions.allow/deny` | Permission rules affecting all teammates |

---

## 29. Version History and Recent Fixes

| Version | Changes |
|---------|---------|
| **v2.1.33** | Added TeammateIdle/TaskCompleted hooks, Task spawn restrictions, persistent memory, fixed tmux messaging |
| **v2.1.34** | Fixed settings toggle crash |
| **v2.1.41** | Fixed model identifiers for Bedrock/Vertex/Foundry, added speed attribute to observability |
| **v2.1.45** | Fixed environment variable propagation to tmux, corrected skill visibility in main session |

---

## 30. External Resources and Plugins

### Official Documentation

- Agent Teams: https://code.claude.com/docs/en/agent-teams
- Sub-agents: https://code.claude.com/docs/en/sub-agents
- Costs: https://code.claude.com/docs/en/costs
- Hooks: https://code.claude.com/docs/en/hooks
- Settings: https://code.claude.com/docs/en/settings
- Permissions: https://code.claude.com/docs/en/permissions

### Community Resources

- **ClaudeFast Complete Guide**: https://claudefa.st/blog/guide/agents/agent-teams
- **ClaudeFast Best Practices**: https://claudefa.st/blog/guide/agents/agent-teams-best-practices
- **Addy Osmani - Claude Code Swarms**: https://addyosmani.com/blog/claude-code-agent-teams/
- **Swarm Orchestration Skill Gist**: https://gist.github.com/kieranklaassen/4f2aba89594a4aea4ad64d753984b2ea
- **AlexOp - From Tasks to Swarms**: https://alexop.dev/posts/from-tasks-to-swarms-agent-teams-in-claude-code/
- **Cobus Greyling (Medium)**: https://cobusgreyling.medium.com/claude-code-agent-teams-ca3ec5f2d26a
- **Dara Sobaloju (Medium)**: https://darasoba.medium.com/how-to-set-up-and-use-claude-code-agent-teams-and-actually-get-great-results-9a34f8648f6d
- **Isaac Kargar (Medium)**: https://kargarisaac.medium.com/agent-teams-with-claude-code-and-claude-agent-sdk-e7de4e0cb03e
- **NxCode Tutorial**: https://www.nxcode.io/resources/news/claude-agent-teams-parallel-ai-development-guide-2026
- **Claude Code Camp**: https://www.claudecodecamp.com/p/claude-code-agent-teams-how-they-work-under-the-hood

### Plugins

- **Compound Engineering Plugin**: https://github.com/EveryInc/compound-engineering-plugin
  - `/workflows:plan` -- Convert feature ideas into detailed implementation specs
  - `/workflows:review` -- Multi-agent code review (security, performance, architecture lenses)
  - `/workflows:compound` -- Document learnings for future agent benefit
  - Provides specialized review agents: security-sentinel, performance-oracle, architecture-strategist, code-simplicity-reviewer, and many more
  - Provides specialized research agents: best-practices-researcher, framework-docs-researcher, git-history-analyzer

- **ClaudeFast Code Kit**: Implements 5-tier complexity system with `/team-plan` and `/team-build` commands for production-ready orchestration scaffolding

### TeammateTool Operations (Complete Reference)

| Operation | Who | Description |
|-----------|-----|-------------|
| `spawnTeam` | Lead | Create a new team |
| `discoverTeams` | Any | List available teams |
| `requestJoin` | Any | Request to join a team |
| `approveJoin` | Lead | Accept join request |
| `rejectJoin` | Lead | Decline join request |
| `write` | Any | Message one teammate |
| `broadcast` | Any | Message ALL teammates (expensive) |
| `requestShutdown` | Lead | Ask teammate to exit |
| `approveShutdown` | Teammate | Accept shutdown request |
| `rejectShutdown` | Teammate | Decline shutdown request |
| `approvePlan` | Lead | Approve teammate's plan |
| `rejectPlan` | Lead | Reject plan with feedback |
| `cleanup` | Lead | Remove team resources |

---

## Appendix: Quick Reference Card

### Create and Run a Team

```bash
# 1. Enable
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1

# 2. Start Claude Code
claude

# 3. Request a team (natural language)
> Create an agent team with 3 teammates to...
```

### Keyboard Shortcuts (In-Process Mode)

| Shortcut | Action |
|----------|--------|
| Shift+Down | Cycle through teammates |
| Enter | View teammate's session |
| Escape | Interrupt current turn |
| Ctrl+T | Toggle task list |
| Ctrl+J | Toggle agent view |
| Shift+Tab | Toggle delegate mode (restrict lead to coordination) |

### Team Lifecycle

```
Enable -> Start Claude -> Request team -> Claude creates team ->
Spawns teammates -> Assigns tasks -> Teammates self-claim and work ->
Teammates report -> Lead synthesizes -> Shutdown teammates -> Cleanup
```

### File Locations

```
~/.claude/teams/{name}/config.json     # Team config
~/.claude/teams/{name}/inboxes/*.json  # Agent inboxes
~/.claude/tasks/{name}/*.json          # Task files
```
