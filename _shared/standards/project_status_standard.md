# Project Status Standard

This standard defines a single canonical status document per project.

## Canonical file

- Each project must have exactly one status file at:
  - `research_projects/<name>/STATUS.md`
- This is the source of truth for:
  - what is done
  - what is in progress
  - what is next
  - blockers and open decisions

## Required sections

Use these sections in order:

1. `# STATUS — <project name>`
2. `## Snapshot` (1-3 lines: current state, last update date)
3. `## Completed`
4. `## In Progress`
5. `## Next 3 Tasks`
6. `## Blockers`
7. `## Open Decisions`
8. `## References` (links to key files, reports, or experiment docs)

## Update rules

- If the user asks "where are we?" or asks for a to-do list, update `STATUS.md` first.
- Do not create new ad hoc to-do files when `STATUS.md` exists.
- Existing specialized notes are allowed (for example experiment notes), but they must be linked from `## References` and not replace `STATUS.md`.
- At session end, append a short dated bullet in project `memory.md` that `STATUS.md` was updated.

## Migration guidance

- Keep old to-do/checklist files for traceability if needed.
- Mark them as supporting documents in `## References`.
- Do not duplicate the same action items across multiple active lists.

