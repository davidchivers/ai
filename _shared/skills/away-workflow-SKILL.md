---
name: away-workflow
description: Plan and execute bounded away-from-keyboard work sessions with explicit scope, duration or milestone guards, safe checkpoints, and a useful handoff. Use when the user is stepping away and wants Codex to continue autonomously without broadening authority, crossing project boundaries, or consuming an open-ended budget.
---

# Away Workflow

Read `_shared/standards/codex_away_workflow.md` and treat it as the canonical operating standard. This skill supplies the planning and handoff structure; repository and project instructions continue to govern the work.

## Define the work packet

Infer the project, objective, available duration or stopping milestone, requested deliverables, and existing authorization from the user's request and live project context. Read the live sections of `STATUS.md` first, then `README.md` for stable scope and `memory.md` only for durable paths, constraints, or decisions relevant to the work.

Ask only when a missing choice changes the safe scope or deliverable. If the user has already authorized the work packet, do not pause for a duplicate approval.

Select tasks that are sufficiently specified, self-contained, and useful without mid-task judgment. Exclude side projects, speculative branches, and actions outside the authority already granted. Do not push, publish, send messages, spend money, expose data, or take destructive action unless the user explicitly authorized that action.

## Present a bounded plan when approval is still needed

Use this compact schema:

```text
AWAY PLAN
Project:
Objective:
Budget: [duration, token limit, or stopping milestone]

#  Task                         Output                    Estimate  Depends on
1  [bounded task]               [verifiable deliverable] [time]    [input]

Stopping rules
- [completion, time, or blocker rule]

Will not touch
- [explicit non-goals]

Deliverables
- [expected files, checks, and handoff]
```

Order tasks by dependency, then value. Use conservative estimates and reserve time for verification and handoff. If the plan does not fit, defer whole lower-priority tasks rather than starting many partial ones.

## Execute within the guard

1. Work through the numbered tasks in order and keep one main deliverable chain active.
2. Before each task, check the remaining budget and prerequisites. Skip work that cannot finish and be verified within the guard.
3. Make scoped checkpoints after material milestones. Update `STATUS.md` only when current state, blockers, decisions, or next tasks change materially. Update `memory.md` only with durable paths, conventions, or user decisions, not a session diary.
4. If a material ambiguity or missing input blocks a task, record the exact blocker and continue only with another independent task already inside the approved plan.
5. Stop when the named deliverable is verified, the budget expires, or a stopping rule fires. Do not extend the session because an adjacent task looks useful.

Do not imply indefinite background execution. Describe the bounded work actually completed in the active session.

## Hand off

Return:

```text
AWAY SESSION HANDOFF

Completed
- [deliverable and verification]

Changed
- [files, state, or external actions]

Blocked or deferred
- [item, reason, and what would unblock it]

Next 3 tasks
1. [next bounded action]
2. [...]
3. [...]

Budget used: [actual of planned] | Tasks: [completed of planned]
```

Report incomplete or unverified work plainly. Do not label a milestone complete merely because time expired.
