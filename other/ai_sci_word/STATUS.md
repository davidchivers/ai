# STATUS - AI Sci Word

## Snapshot

- Last updated: 2026-02-27
- Overall state: phase 1 implementation active with immediate visual math editing in the web prototype.
- Canonical tracker: this file is the single source of truth for status and next actions.

## Completed

- Captured core user needs: immediate math feedback, keyboard-first math insertion, and less clunky UI than LyX.
- Chosen project direction: build a modern Scientific Word-inspired tool rather than retrofit legacy code.
- Established initial concept for inline AI directives (for example `[[page-break]]`) with explicit apply behavior.
- Created canonical project governance files (`README.md`, `STATUS.md`, `memory.md`).
- Locked MVP input direction: support Scientific Word-style shortcuts and direct LaTeX typing in one editor.
- Added integration target: provider-style hooks so Codex/Claude actions can be attached without UI clutter.
- Created initial requirements baseline in `MVP_SPEC.md`.
- Locked phased scope: paper writing first, slides second.
- Split citation/BibTeX automation into side project `projects/ai_sci_word/ai_sci_word_bibtex/`.
- Locked build strategy: web-first prototype as easiest path, desktop packaging deferred.
- Added version control requirement inspired by Google Docs history (snapshots and restore).
- Completed market scan of similar tools and reusable infrastructure (`market_scan.md`).
- Locked UX requirement: formatting should be Google Docs-like and easy for non-LaTeX users.
- Locked AI interaction model: support both optional chat and inline commands while typing.
- Added staged rollout document: `simple_start_plan.md`.
- Added deferred ideas tracker: `wishlist.md`.
- Added editor-base decision memo: `editor_base_decision.md` (continue current prototype; use MarkText/Muya as references only).
- Started phase 1 implementation in `prototype_web/` with:
  - writing surface
  - inline/display math shortcuts
  - fast math rendering
  - single-page readability-first baseline
- Completed seamless math typing pass in `prototype_web/`:
  - direct typed math entry (no prompt)
  - math mode exit shortcuts
  - LaTeX-like typography and cleaner visual blending
  - legacy-style shortcut additions (`Ctrl+D` display equation, `Ctrl+G` Greek mode, math templates)
  - MathLive-based immediate visual math editing in the main writing view
  - Greek insertion flow update (`Ctrl+G` then letter inserts Greek command in math mode and renders symbol)
  - UI chrome cleanup (hidden math keyboard toggles and removed math underline line)
  - Inline math baseline and spacing tuning for smoother in-text adjustment
  - `Ctrl+M` toggle reliability fix in math-field focus context
  - Softer math focus indicator (thin math-colored cue)
  - Legacy shortcut extension (`Ctrl+Up` superscript, `Ctrl+Down` subscript)
  - Shortcut reliability hardening for `Ctrl+Up/Ctrl+Down` across math-field focus paths, with inline fallback insertion
  - Auto-numbered display equations
  - Typora-like simplification pass: removed toolbar, preview pane, and context menu from baseline

## In Progress

- Building first implementation plan from `MVP_SPEC.md`, including:
  - paper-first prototype editor interaction loop
  - provider adapter contract
  - hybrid AI invocation model (chat, configurable quick invoke, command palette)
  - first export path (live preview intentionally deferred)
  - simple formatting controls
  - lightweight version history path
  - cross-project integration point for BibTeX insertion
- Executing phase 1 implementation with daily handoff logging in `session_log.md`.

## Next 3 Tasks

1. Close phase 1 gaps in `prototype_web/` (save/load and final readability polish).
2. Defer LaTeX/PDF output fidelity work; prioritize editor writing feel.
3. After phase 1 signoff, proceed to phase 2 minimal formatting set from `simple_start_plan.md`.

## Blockers

- AI integration boundary is not locked (local model/tooling only vs optional API-backed features).
- Open-source release details not locked (license and public repo naming).
- Storage model for version history is not locked (local-first vs server-backed).
- Implementation base not locked (fork existing open editor vs start custom).
- Exact preview strategy is deferred until after editor-feel stabilization.

## Open Decisions

- Final editor stack selection (for example ProseMirror/Tiptap plus math component choice).
- Final directive syntax contract and validation rules.
- Product scope boundary for v1 collaboration features (single-user with history vs light shared editing).
- Initial AI command set for Codex/Claude (minimum useful verbs vs broader assistant features).
- Open-source license choice (MIT vs Apache-2.0 vs MPL-2.0).
- Exact MVP formatting control set (shortcut-first baseline with optional minimal menu).
- Final inline AI command grammar (`//command//` rules and escaping behavior).
- Default quick-invoke UX (hotkey toggle vs inline trigger as default path).
- Save/load persistence format for prototype documents.
- Recognition approach for handwriting-to-math pad (future wishlist item).

## References

- Project overview: `projects/ai_sci_word/README.md`
- MVP spec: `projects/ai_sci_word/MVP_SPEC.md`
- Market scan: `projects/ai_sci_word/market_scan.md`
- Simple start plan: `projects/ai_sci_word/simple_start_plan.md`
- Wishlist: `projects/ai_sci_word/wishlist.md`
- Editor base decision: `projects/ai_sci_word/editor_base_decision.md`
- Prototype implementation: `projects/ai_sci_word/prototype_web/README.md`
- Session handoff log: `projects/ai_sci_word/session_log.md`
- BibTeX side project: `projects/ai_sci_word/ai_sci_word_bibtex/README.md`
- Session memory: `projects/ai_sci_word/memory.md`
- Governance instructions: `AGENTS.md`
- Status format standard: `_shared/standards/project_status_standard.md`
