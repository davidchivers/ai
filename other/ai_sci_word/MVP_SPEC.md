# AI Sci Word MVP spec

Last updated: 2026-02-27

## Product intent

Build a minimal, pleasant math-writing environment that combines:

1. Scientific Word-like shortcut speed.
2. Direct LaTeX input compatibility.
3. Explicit AI notes/actions without disrupting writing flow.
4. Paper writing as the first shipped workflow.
5. Google Docs-level simplicity for everyday formatting.

## Primary users

1. Writers who prefer keyboard-first equation entry.
2. LaTeX users who want immediate visual feedback.
3. Users who want optional AI assistance for formatting and cleanup.

## Must-have behaviors

1. `Ctrl+M` inserts inline math at cursor.
2. `Ctrl+Shift+M` inserts display math block.
3. Math displays immediately while editing (no separate dialog windows).
4. LaTeX syntax can be typed directly and rendered (`$...$`, `$$...$$`, common macros).
5. Cursor movement in/out of math is predictable with Enter, arrows, and Esc.
6. Document text remains editable without mode confusion.
7. Paper-mode structure supports title, abstract, headings, figures, and references.
8. Live output preview updates quickly while writing.
9. Version history supports automatic snapshots, manual checkpoints, and one-click restore.
10. User can switch between:
   - fast draft render mode (optimized for typing comfort and speed)
   - exact preview mode (compile-accurate PDF output)
11. Default math typography uses high-quality math fonts (for example STIX Two Math or Latin Modern Math fallback).
12. Symbol rendering should remain readable and familiar while typing, including common Greek letters and operators.
13. Everyday formatting is done with simple editor controls (not manual LaTeX commands).
14. Common paper structure tasks (headings, lists, emphasis, references) are one-click or shortcut actions.
15. User can choose AI provider and model from settings (for example Codex/Claude).
16. AI actions can run from:
   - configurable quick-invoke method while typing (for example inline command triggers)
   - command/shortcut actions on selection
   - optional chat assistant panel

## AI notes and actions

1. Directive syntax uses double brackets, for example:
   - `[[page-break]]`
   - `[[make this a theorem]]`
   - `[[tighten wording]]`
2. Directives are visible in draft mode and can be toggled hidden in clean reading mode.
3. `Apply AI Notes` executes directives and returns a reversible diff/undo path.
4. AI providers are abstracted behind a simple adapter:
   - provider id (`claude`, `codex`, etc.)
   - command
   - selected scope (selection/paragraph/document)
   - structured result payload
5. Provider settings include:
   - selectable provider and model
   - API key management path
   - per-action model defaults (for example rewrite vs formatting vs citation assist)
6. Execution UX is command-palette style with diff review and accept/reject.
7. Quick-invoke trigger is configurable:
   - inline command trigger syntax (if enabled)
   - hotkey toggle into AI mode (if enabled)
8. Chat is available but optional, and all chat-applied edits use the same diff accept/reject flow.

## Simplicity constraints

1. Single main writing pane by default.
2. Minimal toolbar; shortcut-first interaction.
3. Chat panel is optional and collapsible; core writing view remains uncluttered.
4. No floating modal equation editor for MVP.
5. Start with the easiest runtime: web-first prototype before desktop packaging.
6. Fast draft render must remain the default typing experience.
7. Formatting UI should resemble familiar word processors (Google Docs-like), not technical LaTeX editors.
8. Preserve standard shortcuts by default; AI hotkeys must be configurable.

## Export requirements

1. Export to LaTeX with deterministic mapping from document nodes.
2. Omit AI directives from final export unless explicitly requested.
3. Keep equations stable under round-trip editing.
4. Paper output compiles to PDF with stable section and reference ordering.
5. Exact preview PDF should use the same export/compile path as final PDF export.

## Non-goals (MVP)

1. Real-time multi-user collaboration.
2. Slide authoring workflow (phase 2 after paper workflow).
3. Complex template marketplace.
4. Mobile-first editor parity.
5. Full citation-manager UI in core app (handled first via `ai_sci_word_bibtex` side project).
6. Exposing raw LaTeX formatting commands as the primary user workflow.
7. Making chat the only AI interaction model (inline and command invocation must also work).

## MVP acceptance criteria

1. A user can draft 2 pages with at least 20 equations using only keyboard shortcuts and LaTeX input.
2. Fast draft rendering remains responsive and visually clear during normal writing.
3. At least 3 directive types execute correctly and are undoable.
4. Exported LaTeX compiles with equations matching editor output.
5. A user can restore an earlier snapshot without losing current work.
6. Switching to exact preview produces a PDF view consistent with exported output.
7. A non-LaTeX user can apply core formatting tasks without typing raw LaTeX.
8. A user can switch AI provider/model in settings and run the same command workflow without UI changes.
9. At least one non-chat quick invoke path (inline trigger or hotkey mode) executes with diff-based accept/reject.
