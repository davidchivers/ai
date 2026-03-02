# Project Memory - AI Sci Word

Most recent session first.

---

### Session: 2026-02-27 (editor base decision: marktext/muya)

- Added `editor_base_decision.md` to decide base-editor path.
- Logged verified status for MarkText and Muya and compared integration risk.
- Locked v1 decision: do not fork MarkText now; continue current Typora-like lightweight prototype.
- Position MarkText/Muya as reference inputs only for later phases.
- Updated canonical tracker `STATUS.md` with this decision reference.

---

### Session: 2026-02-27 (Typora-like LyX Lite simplification)

- Simplified prototype to a single-page readable writing surface.
- Removed toolbar/preview/context-menu layers from phase-1 baseline to reduce clutter.
- Preserved keyboard-first math workflow:
  - `Ctrl+M` math toggle
  - `Ctrl+D` display equation
  - `Ctrl+Up/Down` super/subscript
  - `Ctrl+G` Greek insertion mode
- Kept display equation numbering and immediate visual math editing.
- Updated prototype docs and canonical tracker for continuity.

---

### Session: 2026-02-27 (Ctrl+Up/Ctrl+Down reliability hardening)

- Hardened math shortcut routing for superscript/subscript in nested MathLive focus contexts.
- Added key/code variant handling for arrow shortcuts.
- Added fallback behavior: if `Ctrl+Up/Down` is used in editor context without active math, create inline math and insert super/sub template.
- Confirmed fix is incremental and does not require rewriting the editor core.
- Updated canonical tracker `STATUS.md` and session continuity log.

---

### Session: 2026-02-27 (wishlist capture: handwriting math pad)

- Added deferred feature request for handwriting math pad shortcut.
- Created `projects/ai_sci_word/wishlist.md` to track non-core ideas.
- Marked handwriting-to-math as out-of-scope for first cycle in `simple_start_plan.md`.
- Updated canonical tracker `STATUS.md` for this session.

---

### Session: 2026-02-27 (legacy shortcut and context menu pass)

- Added `Ctrl+Up` and `Ctrl+Down` as superscript/subscript shortcuts in math mode.
- Added equation numbering for display equations.
- Added custom right-click menu:
  - selected text: Title, Subtitle, Section, Paragraph, Bold, Italic
  - math: Inline/Display mode and Exit math mode
- Updated prototype readme/instructions and session continuity log.
- Updated canonical tracker `STATUS.md` for this session.

---

### Session: 2026-02-27 (toggle reliability and focus cue softening)

- Moved editor shortcut handling to document-level capture so `Ctrl+M` toggles off reliably while focus is inside math fields.
- Softened math focus styling from dark box to thin math-colored line.
- Kept math keyboard/menu chrome hidden.
- Updated session continuity log and canonical tracker.

---

### Session: 2026-02-27 (inline math baseline tuning)

- Tuned inline math and body text line-height to improve mixed line readability.
- Adjusted inline math baseline shift and horizontal spacing to reduce visual mismatch.
- Updated session continuity log and canonical tracker.

---

### Session: 2026-02-27 (math field ui cleanup)

- Removed math-field focus underline to reduce visual distraction.
- Hid math-field keyboard/menu UI chrome through CSS parts.
- Logged this pass in `session_log.md`.
- Updated canonical tracker `STATUS.md` for this session.

---

### Session: 2026-02-27 (mathlive immediate visual math pass)

- Switched in-editor math input to MathLive (`math-field`) for immediate visual math rendering while typing.
- Preserved legacy shortcut direction:
  - `Ctrl+M` inline math toggle
  - `Ctrl+D` new display equation
  - `Ctrl+G` Greek mode
  - `Ctrl+R`, `Ctrl+F`, `Ctrl+I`, `Ctrl+H`, `Ctrl+L`, `Ctrl+9` in math mode
- Adjusted typography to reduce mismatch:
  - unified LaTeX-like baseline for text
  - subtle color distinction for math
- Updated session continuity log and prototype README.
- Updated canonical tracker `STATUS.md` for this session.

---

### Session: 2026-02-27 (phase 1 implementation start and iterations)

- Created `projects/ai_sci_word/prototype_web/` initial runnable prototype.
- Added core files:
  - `index.html` (single-page writing UI)
  - `styles.css` (clean paper-style visual baseline)
  - `app.js` (shortcut handling and math flow)
  - `README.md` (run instructions)
- Added `projects/ai_sci_word/session_log.md` as per-session continuity tracker.
- Iterated shortcut and math-mode behavior toward Scientific Word style.
- Updated canonical tracker `STATUS.md` throughout the session.

---

### Session: 2026-02-27 (planning lock)

- Added `projects/ai_sci_word/MVP_SPEC.md` and `projects/ai_sci_word/simple_start_plan.md`.
- Locked project direction:
  - paper-first workflow
  - start small, web-first prototype
  - Google Docs-like simplicity
  - optional chat plus configurable quick invoke
- Created side project `projects/ai_sci_word/ai_sci_word_bibtex/` for citation lookup and BibTeX insertion.
- Added market scan in `projects/ai_sci_word/market_scan.md`.

---

## Key files

| Role | Path |
|---|---|
| Project overview | `projects/ai_sci_word/README.md` |
| Canonical status tracker | `projects/ai_sci_word/STATUS.md` |
| MVP requirements | `projects/ai_sci_word/MVP_SPEC.md` |
| Similar-tool scan | `projects/ai_sci_word/market_scan.md` |
| Simple rollout plan | `projects/ai_sci_word/simple_start_plan.md` |
| Prototype docs | `projects/ai_sci_word/prototype_web/README.md` |
| Session continuity log | `projects/ai_sci_word/session_log.md` |
| Persistent project memory | `projects/ai_sci_word/memory.md` |

## Working conventions

- Use `projects/ai_sci_word/STATUS.md` as the single status source.
- Keep per-session handoff notes in `session_log.md`.
- Keep implementation incremental: stabilize phase 1 before phase 2.
