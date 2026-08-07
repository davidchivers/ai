# Codex away workflow

Use this workflow when the user says they will be away from the keyboard for hours or a day and
wants Codex to keep working in a bounded, disciplined way.

## Important constraint

This is a handoff workflow, not true unsupervised background execution after a closed session.
Codex should not imply that it will continue indefinitely once the session is inactive. The value
of this workflow is that the user can leave a clear work packet and Codex will operate inside it
without repeated clarification.

## Default operating rules

- Stay inside the named project only.
- Do not switch projects or open side quests unless the handoff explicitly allows it.
- Work in ordered phases rather than bouncing across unrelated tasks.
- Prefer one main deliverable chain over many partially finished branches.
- Use conservative assumptions when blocked by minor ambiguity.
- If a blocker is material, record it clearly in `STATUS.md` rather than guessing. Add it to `memory.md` only when it is a durable path, constraint, or decision.
- Update `STATUS.md` when next tasks or current phase materially change.
- Update `memory.md` only for durable decisions or facts likely to matter in later sessions.
- Recommend a commit point when a real milestone is reached.
- If a notes-phase literature section is touched, benchmark its structure and level of detail
  against the stronger existing `research_ideas/*/notes/` literature files rather than leaving a
  thin placeholder.
- Do not leave a literature note with no references unless it is explicitly labeled as a temporary
  pre-verification search map and the absence of references is itself the point of the note.

## Good handoff packet

The user should ideally specify:

- project path
- single main objective
- allowed scope
- explicit non-goals
- stopping rule
- preferred deliverables
- whether web/literature search is expected
- whether sub-agents/delegation are expected

## Recommended execution order

1. Read project context progressively:
   - live sections of `STATUS.md` first
   - `README.md` for stable scope
   - `memory.md` only when durable paths or earlier decisions are relevant
2. Restate the objective and first step in a short progress update.
3. Do the main task chain first.
4. Keep notes and status in sync as decisions harden.
5. Stop when the stopping rule is hit, not when a tempting extension appears.

## Preferred stopping rules

Use one of these:

- `stop after one clean milestone`
- `stop when the named deliverable exists and is verified`
- `stop if blocked by source access, identification ambiguity, or missing files`
- `stop before broadening scope to a second project or second design branch`

## Suggested deliverables

- one updated notes file
- one built dataset or script
- one memo or summary in `data/processed/`
- updated `STATUS.md`, plus `memory.md` only if a durable decision changed

## Preferred invocation

Use the away-workflow skill: `_shared/skills/away-workflow-SKILL.md`. It automates
context reading, task identification, cost estimation, and execution planning.

Invoke with: `/away-workflow`, `$away-workflow`, or "use the away workflow".

## Manual handoff (fallback)

If the skill is not available, use the copy-paste template in `_shared/prompts/codex_away_handoff.md`.
