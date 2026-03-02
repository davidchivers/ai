# AI Sci Word simple start plan

Last updated: 2026-02-27

## Goal

Ship the smallest useful paper-writing prototype quickly, then layer on advanced features.

## Principles

1. Start single-user, web-first.
2. Prioritize writing feel over feature count.
3. Keep formatting and controls minimal.
4. Keep every AI edit reversible.
5. Defer LaTeX/PDF output quality work until editor feel is stable.

## Phase 1: core writing shell (week 1)

1. Build one-page editor with clean typography.
2. Add math entry:
   - `Ctrl+M` inline math
   - `Ctrl+Shift+M` display math
3. Add fast draft rendering for equations while typing.
4. Add readable preview toggle for writing feedback (not compile-accurate yet).
5. Improve baseline spacing and visual consistency between text and math.

Exit criteria:
- User can draft text with equations comfortably.
- Preview updates reliably.
- Editor looks clean and readable enough for daily writing use.

## Phase 2: simple formatting and structure (week 2)

1. Add minimal formatting set:
   - heading levels
   - bold/italics
   - bullet and numbered lists
   - links and comments
2. Add paper structure blocks:
   - title
   - authors
   - abstract
   - sections
   - references placeholder

Exit criteria:
- Non-LaTeX user can create a clean paper draft layout.

## Phase 3: AI assist baseline (week 3)

1. Add provider/model settings (Codex/Claude via adapter).
2. Add three invoke paths:
   - selection command actions
   - optional chat panel
   - optional quick invoke mode (hotkey or inline trigger)
3. Add diff-based accept/reject for all AI edits.

Shortcut policy:
- Keep default `Ctrl+A` as Select All.
- AI mode hotkey must be configurable in settings.

Exit criteria:
- User can apply AI formatting/writing actions without losing control.

## Phase 4: version history + BibTeX hook (week 4)

1. Add auto snapshots and manual checkpoints.
2. Add restore flow with clear version labels.
3. Add integration hook for `ai_sci_word_bibtex` lookup/insert flow.

Exit criteria:
- User can restore previous versions.
- Citation insertion path is wired end-to-end.

## Out of scope for this first cycle

1. Full real-time multiplayer collaboration.
2. Slide editor.
3. Large template/theme system.
4. Perfect LaTeX output parity during typing.
5. Handwriting-to-math pad (draw and insert) workflow.
