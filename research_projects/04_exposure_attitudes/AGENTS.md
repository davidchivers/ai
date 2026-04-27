# AGENTS.md — Project 04 exposure attitudes

Read this file before working on this project.

## Startup

At the start of a session, read these files in order:

1. Repository-level `AGENTS.md`
2. `_shared/memory/RESEARCH_STYLE.md`
3. `research_projects/04_exposure_attitudes/STATUS.md`
4. `research_projects/04_exposure_attitudes/README.md`
5. `research_projects/04_exposure_attitudes/memory.md`
6. `research_projects/04_exposure_attitudes/DATA_POLICY.md`

Then check `STATUS.md` for the current "Next 3 tasks" before proposing or making a plan.

## Data rule

Do not read, copy, commit, paste, or summarize raw Dewey, Advan, SafeGraph, or other restricted row-level data.

The Dropbox source folder contains a large `data/` tree. Treat it as restricted unless Dave explicitly says otherwise for a specific file and the policy is updated.

Safe project work includes:

- Markdown notes
- code that accesses data locally
- schemas and metadata
- aggregate regression outputs
- non-reconstructable summary statistics
- project status and workflow files

Unsafe project work includes:

- raw rows or row samples
- downloaded data files
- spreadsheets or logs containing raw rows
- credentials, API keys, tokens, cookies, or `.env` files
- provider files that are not licensed for redistribution

## Collaboration rule

Dave is organizing the project structure. Eren and Diego may work on separate branches and should use their own workstream files unless Dave asks for a canonical update.

Use:

- `STATUS.md` for canonical project state, decisions, blockers, and next tasks
- `memory.md` for stable facts, paths, and conventions
- `workstreams/<name>.md` for individual branch notes and partial work

Do not overwrite another person's workstream file unless explicitly asked.

## Git rule

Use branches for substantial edits. The active project branch is:

```text
research_projects/04_exposure_attitudes
```

Before pushing, check for data files, secrets, large generated outputs, and accidental Dropbox copies.
