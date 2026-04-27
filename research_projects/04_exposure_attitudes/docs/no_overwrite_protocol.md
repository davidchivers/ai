# No-overwrite protocol

This repo is designed so several people can work at once.

The basic rule is: branch separately, write to owned files by default, then merge deliberately.

## Owned files

Each project has personal workstream files:

```text
workstreams/dave.md
workstreams/eren.md
workstreams/diego.md
workstreams/codex.md
```

Default ownership:

- Dave edits `dave.md`
- Eren edits `eren.md`
- Diego edits `diego.md`
- Codex edits `codex.md`, unless it is assisting a named person

If Codex is assisting Eren, it may update `eren.md`. If assisting Diego, it may update `diego.md`. It should not edit anyone else's file unless asked.

## Shared files

These files are shared and should be edited carefully:

- `README.md`
- `STATUS.md`
- `WORKSTREAMS.md`
- `memory.md`
- repo policy files
- `shared_code/`

Before changing shared files, Codex should understand the current branch and explain what it is going to update.

## Canonical status

`STATUS.md` is not a scratchpad.

Use it for:

- current canonical project state
- next 3 tasks
- accepted decisions
- blockers
- active branches that are meant for review

Use workstream files for:

- experiments
- rough plans
- branch logs
- partial ideas
- individual notes

## Consolidation

When a branch is ready, summarize it into `STATUS.md` or `WORKSTREAMS.md`.

Dave normally does final consolidation unless he asks someone else to do it.

## Conflict behavior

If Git reports a conflict:

1. stop
2. explain which files conflict
3. identify whose work may be affected
4. ask before discarding or rewriting anything

Never resolve a policy or status conflict by guessing.
