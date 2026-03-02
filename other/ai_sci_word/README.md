# AI Sci Word

**Project type**: software product concept and prototype
**Status**: planning stage
**Last updated**: 2026-02-27
**Canonical status tracker**: `projects/ai_sci_word/STATUS.md`

---

## What this project is

AI Sci Word is a modern writing tool inspired by Scientific Word:

- fast text-first writing
- immediate visual math editing
- keyboard-first shortcuts (especially `Ctrl+M` for math)
- optional inline AI directives for formatting and editing actions
- Overleaf-like live output preview and team-friendly workflow, without requiring deep LaTeX knowledge

The goal is to preserve the low-friction equation workflow while adding local/AI-assisted document operations.

## Current focus

1. Paper writing workflow is phase 1.
2. Slide writing workflow is phase 2.
3. Citation lookup and BibTeX insertion is handled in side project `projects/ai_sci_word/ai_sci_word_bibtex/`.
4. Start small: web-first prototype first, desktop packaging later if needed.

## Current status

Authoritative live status is maintained in `STATUS.md`. This section is a short snapshot.

- [x] Problem statement and user pain points captured
- [x] Initial interaction model drafted (`Ctrl+M`, immediate math rendering, directive notes)
- [x] MVP product spec written (`MVP_SPEC.md`)
- [ ] Prototype editor with working math shortcuts
- [ ] AI directive parsing and apply pipeline

## Core UX principles

1. Math should be as fast as typing text.
2. Shortcuts should be memorable and consistent.
3. AI assistance should be explicit and controllable.
4. Formatting operations should be reversible and inspectable.
5. The default writing view should stay simple and uncluttered.
6. Collaboration and live preview should feel easy, not technical.
7. On-screen math should look clean and readable while typing, even before full compile.
8. Formatting should feel as easy as Google Docs.
9. AI assistance should work both from chat and inline typing commands.

## Input approach (locked for MVP)

MVP should support all three entry styles without forcing one workflow:

1. Scientific Word-style shortcuts (`Ctrl+M` inline math, `Ctrl+Shift+M` display math).
2. LaTeX-native typing (`$...$`, `$$...$$`, math macros).
3. Hybrid "auto" behavior where shortcuts and LaTeX coexist.

This keeps the experience familiar for shortcut users and LaTeX users while preserving a simple UI.

## Initial MVP scope

1. Rich text editor with inline and display math nodes.
2. Shortcut layer (`Ctrl+M`, `Ctrl+Shift+M`, exit/edit navigation).
3. LaTeX-compatible math parsing and rendering in both inline and display nodes.
4. Directive syntax (for example `[[page-break]]`) that is visible in draft mode and omitted from final export.
5. Optional AI actions designed to work with Codex/Claude through a provider adapter.
6. One-click "Apply AI Notes" action to transform directives into concrete document edits.
7. Live preview pane that reflects current document output quickly.
8. Export path to LaTeX and PDF-compatible workflow.
9. Shareable project format so collaborators can read/edit without raw LaTeX-heavy workflow.
10. Paper-first document structure (title, authors, abstract, sections, references).
11. Simple version history model (snapshots, diff view, restore).
12. Dual render modes:
   - fast draft math view while typing (smooth, pretty symbols/fonts)
   - exact PDF preview mode for compile-accurate output
13. Math typography baseline with high-quality math font defaults and complete symbol visibility.
14. Simple formatting model:
   - core controls only (headings, bold, italics, lists, links, comments)
   - low-friction defaults (spacing, numbering, references)
   - no requirement to use raw LaTeX commands for ordinary formatting
15. User-selectable LLM settings:
   - choose provider and model (for example Codex or Claude)
   - choose default model per action type
   - support both chat interaction and inline command interaction
16. Configurable AI invoke patterns:
   - optional inline command triggers while typing
   - optional AI-mode hotkey toggle
   - optional chat assistant panel

## Next 3 concrete tasks

1. Build a paper-first prototype of the editor interaction loop (typing, shortcut math insert, LaTeX math parse, render, cursor exit).
2. Implement dual preview pipeline (fast draft render and exact PDF preview) and verify compile consistency.
3. Implement Google Docs-like formatting controls and add configurable AI invoke flow plus lightweight version history with `ai_sci_word_bibtex` integration contract.

## Open source intent

This project is intended to be open source and published on Git/GitHub.

## Current prototype

Phase 1 implementation is currently in:

`projects/ai_sci_word/prototype_web/`

## Wishlist (deferred)

1. Handwriting math pad shortcut:
   - open a small drawing canvas
   - draw with mouse/stylus
   - convert drawing to math
   - insert result at cursor
