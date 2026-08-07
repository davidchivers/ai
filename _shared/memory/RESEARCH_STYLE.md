# Research style and durable preferences

This file contains stable, cross-project preferences. Load the more detailed resource named below only when the current task needs it.

## Evidence and research judgment

- Never invent references. Cite only sources confirmed in project files or through a verified bibliographic source. Mark unresolved citations as `[UNVERIFIED - check before submitting]`.
- Separate evidence from inference. Use declarative language for supported facts and label interpretation, extrapolation, and uncertainty explicitly.
- Infer context from the request and repository first. Ask only about unresolved choices that would materially change the result.
- Test supportive, null, and contradictory evidence. Do not claim causality without the design and diagnostics needed to support it.
- Check calibration values and equations against the live implementation. Report discrepancies rather than silently reconciling them.

## Writing and explanation

- For academic prose, load `academic_voice.md`. Use the user's strong prior papers as the first style reference when available.
- For `BOOK`, *The Target Trap*, blogs, and long-form articles, use the `book-voice` skill and `book_blog_article_voice.md`.
- Do not use em dashes in academic prose. Book voice follows its own punctuation and cadence guidance.
- Avoid stock throat-clearing, novelty inflation, empty roadmaps, synonym cycling, and generic chatbot phrasing.
- Prefer paragraph-first explanation. Use lists when the information is genuinely a checklist, comparison, or sequence.
- For model explanations, present intuition first, variables second, and equations third. Define every symbol before use and retain the minimum mathematics needed for precision.
- Avoid `benchmark` as a generic label. Use `baseline` only when there is a natural main case, or choose a precise label such as `preferred specification`, `current-price rule`, or `comparison case`.

## Research project organization

- In pre-paper phases, use the exact flat, numbered Markdown layout in `_shared/standards/notes_phase_standard.md`. Do not create TeX, LyX, or PDF outputs until the user asks to begin paper writing.
- For paper-phase folders, canonical filenames, source locations, and milestone versions, use `_shared/standards/paper_project_structure_standard.md`.
- Create folders lazily, only when adding the first file.
- Use stable descriptive working filenames and update them in place. Use dates or version suffixes only for an explicit milestone, archive, or user request.
- Use lowercase snake_case for new project folders and working filenames. Keep standardized governance names uppercase: `README.md`, `STATUS.md`, `AGENTS.md`, and `CLAUDE.md`.
- Treat the project's identified LyX or TeX file as authoritative. Confirm the live source before editing and do not round-trip through another format casually.

## Live project context

- `STATUS.md` is the one live source for current state, in-progress work, blockers, decisions, and exactly three next tasks.
- `README.md` is a short, stable project overview and points to `STATUS.md`; it does not duplicate the live task list.
- `memory.md` contains durable paths, conventions, and author decisions; it is not a chronological session diary.
- Follow `_shared/standards/project_status_standard.md` and the `project-status-updater` agent for status work.

## Task-specific routing

- Paper drafting and structural revision: `academic-paper-writer` skill plus `academic_voice.md`.
- LaTeX compilation, figure placement, footnotes, links, page breaks, and visual QA: `latex-paper-compile-layout` skill.
- Referee responses: `_shared/standards/referee_response_standard.md` and the named template.
- Notes-phase literature synthesis: `_shared/standards/notes_phase_standard.md`; use verified references and do not leave a thin placeholder when evidence is available.
- Bounded unattended work: `away-workflow` skill and `_shared/standards/codex_away_workflow.md`.
- Shell, storage, Hamilton, Git handoff, and editor preferences: `_shared/standards/environment_workflow.md`.

## Communication

- If the user writes `u` by itself in an active project or monitoring context, interpret it as "update".
- Distinguish clearly between immediate blockers, open decisions, current evidence, and later enhancements.
- Preserve a requested output layout exactly when it carries meaning for the user; concision is not permission to redesign the deliverable.
