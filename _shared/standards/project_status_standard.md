# Project status standard

This standard defines a single canonical status document for numbered paper projects and for any other project that adopts status tracking.

## Canonical file

- Each numbered paper project must have exactly one status file at:
  - `research_projects/<name>/STATUS.md`
- Non-paper projects may omit `STATUS.md`; when they use one, it is the single live status source and `README.md` remains the stable overview.
- `STATUS.md` contains live state only and is the source of truth for:
  - what is done
  - what is in progress
  - what is next
  - blockers and open decisions

## Required sections

Use these sections in order:

1. `# STATUS - <project name>`
2. `## Snapshot` (1-3 lines: current state, last update date)
3. `## Completed`
4. `## In Progress`
5. `## Next 3 Tasks`
6. `## Blockers`
7. `## Open Decisions`
8. `## References` (links to key files, reports, or experiment docs)

## Update rules

- Keep exactly one occurrence of every required heading.
- Keep `## Snapshot` to 1-3 lines and `## Next 3 Tasks` to exactly three concrete tasks.
- Keep recent, decision-relevant milestones in `## Completed`; move detailed experiment history to linked project notes or rely on Git history.
- `README.md` contains the stable project overview and links to `STATUS.md`; it does not duplicate the live task list.
- `memory.md` contains durable paths, conventions, and decisions; it is not a session diary or parallel status log.
- A request such as "where are we?" is read-only unless the user asks for an update or the current task has changed project state.
- Do not create new ad hoc to-do files when `STATUS.md` exists.
- Existing specialized notes are allowed (for example experiment notes), but they must be linked from `## References` and not replace `STATUS.md`.
- Update `memory.md` only when a durable path, convention, author decision, or otherwise irreplaceable context changes.

## Migration guidance

- Preserve unique human work and genuine milestone records in a clearly named supporting document when needed; routine status history remains recoverable from Git.
- Mark retained supporting documents in `## References`.
- Do not duplicate the same action items across multiple active lists.
- For an oversized legacy project, use `project_records/project_history.md` for dated checkpoints and `project_records/reference_index.md` for canonical paths, job IDs, hashes, manifests, and commands. Create the folder lazily during a real migration.
- Reconcile the shared checkout with the project's active worktree before shortening dirty or divergent files.
- Copy unique history and provenance verbatim first, then verify that date headings, job IDs, hashes, external paths, and manifests remain represented.
- Shorten the canonical files in a separate, reviewable step. Do not deduplicate or reinterpret research history during the extraction step.
