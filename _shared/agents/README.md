# Shared agents

Agents in this folder are narrow, repo-specific operating prompts.

Discovery rule: if the user asks whether an agent exists or should be used, check this repo-level
folder before relying on installed system skills or saying the agent is unavailable.

Use an agent when the task depends on this repository's project structure, naming rules, or file handoff conventions.

## Recommended defaults

- Literature search and ranking: `literature-scout.md`
- Literature drafting from verified papers: `lit-review-drafter.md`
- Claim and citation verification: `evidence-checker.md`
- Empirical design generation: `empirical-idea-generator.md`
- Math and equation audit: `math-auditor.md`
- Code-versus-paper audit: `code-paper-crosswalk.md`
- Bounded replication and run audit: `replication-package-auditor.md`
- Referee response drafting: `referee-response-drafter.md`
- Prose diagnosis after content is settled: `style-editor.md`
- Whole-book chapter continuity and callback control: `book-whole-reader.md`
- Whole-book continuity, repetition, and voice audit: `book-continuity-checker.md`
- Approved text insertion into the authoritative `.lyx` or `.tex`: `tex-integrator.md`
- Notes hygiene: `notes-organizer.md`
- Canonical status maintenance and session wrap-up: `project-status-updater.md`

## Boundary with skills

- Keep an item in `agents/` when it is mainly about local workflow orchestration.
- Keep an item in `skills/` when it is a broader reusable method or tool workflow.

## Default literature pipeline

- `literature-scout.md`: discover and triage candidates
- `_shared/templates/reference_checklist_template.csv`: copy this into a project-local `literature/checklist/reference_checklist.csv` and use `confirm_yn` as the gate
- `lit-review-drafter.md`: draft prose from confirmed rows only
- `evidence-checker.md`: final citation and claim audit

## Retired overlap

- `literature-reviewer.md` was renamed and tightened into `lit-review-drafter.md`, which drafts only from source-verified material.
- `lit-review-writer.md` was retired because its overlapping drafting role is now carried by `lit-review-drafter.md`. Git history retains the earlier files.
