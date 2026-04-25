---
name: away-workflow
description: Plan and execute bounded away-from-keyboard work sessions
workflow_stage: planning
compatibility:
  - claude-code
  - codex
author: Dave Chivers
version: 1.0.0
user_invocable: true
tags:
  - workflow
  - automation
  - planning
  - away
---

# Away Workflow

Automate the planning and execution of away-from-keyboard work sessions.
When the user steps away, this skill reads project context, identifies safe
tasks, estimates time, and — once approved — works through them in order.

Trigger phrases: "use the away workflow", "I'm stepping away",
"plan next steps, I'm going away", `/away-workflow`, `$away-workflow`.

Follows the operating rules in `_shared/standards/codex_away_workflow.md`.
Read and apply those rules directly — do not duplicate them here.


## Workflow

### 1. Parse user input

Extract:
  - Project   — path or name (e.g. "project 01", "fertility")
  - Duration  — how long they will be away (default: 2 hours)
  - Requests  — any specific tasks or goals mentioned

If the project is ambiguous, ask. Everything else can use defaults.


### 2. Read project context

Read for the identified project:
  1. STATUS.md  — current phase, next tasks, blockers
  2. README.md  — project scope and structure
  3. memory.md  — session history, known runtimes, past decisions

Also read:
  - `_shared/standards/codex_away_workflow.md` — operating rules


### 3. Identify away-suitable tasks

Scan STATUS.md, memory.md, and any queued work for candidate tasks.

Include tasks that are:
  - Long-running  — calibrations, grid searches, parameter sweeps, transitions
  - Low-ambiguity — clear inputs and outputs, no design decisions
  - Self-contained — no mid-task user input required
  - Already queued — listed in STATUS.md next tasks or memory.md

Exclude tasks that:
  - Require design decisions or creative judgment
  - Touch shared state (git push, PR creation, external APIs)
  - Are exploratory or open-ended
  - Would require switching projects
  - Need files or data that may not be available


### 4. Build the task plan

For each candidate task, estimate:
  - Wall-clock time — from memory.md runtimes or typical durations
  - Cost weight    — light / moderate / heavy (informational only)
      light    = shell-heavy (run a calibration, execute a script)
      moderate = file generation (tables, figures, status updates)
      heavy    = writing-intensive (memos, lit review, draft text)
  - Priority       — by dependency chain, then impact

Fit tasks to the user's stated duration. If total time exceeds the
available hours, trim from the bottom and note what was deferred.

Present as a numbered plan:

    AWAY PLAN — Project 01 (Necessity Entrepreneurs)
    Duration: 3 hours

    #  Task                              Time     Cost
    1  Run case147 vacancy sweep         45 min   light
    2  Generate welfare table            10 min   moderate
    3  Update STATUS.md and memory.md     5 min   light
    ─────────────────────────────────────────────────────
       Total                            ~60 min

    Overall cost: low — mostly shell execution and small file writes

Cost flag (one line after the table):
  - "low — mostly shell execution and small file writes"
  - "moderate — mix of execution and file generation"
  - "high — significant writing or many tasks; expect heavy token usage"


### 5. Present the plan for approval

Show the user the numbered task plan from step 4, plus:

    Stopping rules
    - Stop after completing the task list or at [duration]
    - Stop if blocked by missing data or ambiguous requirements
    - Do not broaden scope to other projects

    Will not touch
    - [Explicit non-goals, e.g. paper draft, git push, lit search]

    Deliverables
    - [Expected output files and updates]

    Approve, modify, or reject?

Format for fast scanning — the user should be able to approve in
30 seconds before walking away.


### 6. Execute (if approved)

Work through tasks in numbered order:
  1. Before each task, check remaining time against the estimate.
  2. If a task would overrun the session, skip it and log why.
  3. Update STATUS.md when phase or next-tasks materially change.
  4. Update memory.md at milestones.

If blocked:
  - Log the blocker in STATUS.md and memory.md.
  - Move to the next task if possible.
  - Do not guess past material ambiguity.


### 7. Handoff summary

When finished (all tasks done, time up, or blocked), present:

    AWAY SESSION COMPLETE

    What changed
    - [Concrete outputs and changes]

    Blocked
    - [Any blockers encountered, or "None"]

    Next 3 tasks
    1. [Next logical task]
    2. [...]
    3. [...]

    Session: ~Xh of Yh used | N of M tasks completed

Update STATUS.md and memory.md with this information.


## Time guard

Runs throughout execution:
  - Track cumulative wall-clock time after each task.
  - Before starting a new task, check it fits in the remaining duration.
  - If not: "Skipped [task] — would overrun session (~Xm left, needs ~Ym)".
  - Always reserve time for the handoff summary and STATUS/memory updates.


## Notes

- This skill replaces the manual template in `_shared/prompts/codex_away_handoff.md`.
- The old template remains available as a fallback for manual use.
- Time and cost estimates are rough guides — err on the conservative side.
