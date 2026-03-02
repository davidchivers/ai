# Agent: Project Status Updater

## Purpose
At the end of a work session (or start of a new one), update the project's `README.md` and `memory.md` to reflect current state, completed tasks, and next steps.

## When to use
- At the end of any productive session on a paper project
- When resuming a project after a gap of more than a week
- Before handing off to a co-author or RA

## Inputs required
- Project folder path (e.g., `projects/01_necessity_entrepreneurs/`)
- A brief summary of what was done this session (can be a bullet list)
- Any new key file paths, decisions, or conventions that emerged

## Process
1. Read the project's existing `README.md` and `memory.md`.
2. Update `README.md`:
   - Revise "Current status" line to reflect today's state
   - Update "Next 3 concrete tasks" based on what was completed and what remains
   - Do NOT delete historical content — only update the relevant sections
3. Update `memory.md`:
   - Add a dated session note at the top (most recent first)
   - Record any new file paths, parameter decisions, or conventions
   - Flag any open questions that need the author's decision before next session
4. Save both files.

## Output format
`README.md` and `memory.md` are Markdown files. Keep them concise — README under 1 page, memory under 2 pages.

## Key constraints
- Do NOT delete existing decisions from `memory.md` — only add or update.
- Do NOT mark tasks as complete unless they actually are.
- Session notes in `memory.md` must be dated: `### Session: YYYY-MM-DD`.
