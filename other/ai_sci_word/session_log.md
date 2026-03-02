# AI Sci Word session log

Purpose: keep a clean day-to-day handoff so work can resume quickly.

## Logging rule (every session)

1. At start: add one line for session goal.
2. During work: list key file changes.
3. At end: list what works, what is incomplete, and the next first action.

---

## 2026-02-27 - session 12 (editor base decision note)

### Goal

Decide whether to fork MarkText/Muya or continue current prototype baseline.

### Changed files

1. `projects/ai_sci_word/editor_base_decision.md`
2. `projects/ai_sci_word/STATUS.md`
3. `projects/ai_sci_word/memory.md`
4. `projects/ai_sci_word/session_log.md`

### What works

1. Added a concrete decision memo with verified sources and recommendation.
2. Locked v1 direction: continue current lightweight prototype; do not fork MarkText for v1.
3. Preserved continuity by linking the decision in status and memory.

### Incomplete

1. Save/load persistence is still not implemented.
2. AI inline command execution is still not implemented.
3. Exact PDF-fidelity path is still deferred.

### Next first action

Implement save/load in the current minimal editor without adding UI clutter.

---

## 2026-02-27 - session 11 (Typora-like LyX Lite simplification)

### Goal

Reduce UI complexity to a single readable page with keyboard-first math flow.

### Changed files

1. `projects/ai_sci_word/prototype_web/index.html`
2. `projects/ai_sci_word/prototype_web/styles.css`
3. `projects/ai_sci_word/prototype_web/app.js`
4. `projects/ai_sci_word/prototype_web/README.md`
5. `projects/ai_sci_word/session_log.md`
6. `projects/ai_sci_word/memory.md`
7. `projects/ai_sci_word/STATUS.md`

### What works

1. Prototype now uses a Typora-like single-page writing layout.
2. Removed toolbar, preview pane, and context-menu complexity for this baseline.
3. Kept core shortcut model: `Ctrl+M` inline math toggle, `Ctrl+D` display equation, `Ctrl+Up/Down` super/subscript, `Ctrl+G` Greek mode.
4. Display equation numbering and MathLive immediate visual math editing remain active.

### Incomplete

1. Save/load persistence is still not implemented.
2. AI inline command execution is still not implemented.
3. Exact PDF-fidelity path is still deferred.

### Next first action

User validation on this minimal writing feel, then add save/load without reintroducing UI clutter.

---

## 2026-02-27 - session 10 (Ctrl+Up/Ctrl+Down reliability hardening)

### Goal

Fix unreliable superscript/subscript shortcuts without rewriting the editor core.

### Changed files

1. `projects/ai_sci_word/prototype_web/app.js`
2. `projects/ai_sci_word/session_log.md`
3. `projects/ai_sci_word/memory.md`
4. `projects/ai_sci_word/STATUS.md`

### What works

1. `Ctrl+Up` and `Ctrl+Down` now route from math event path (shadow DOM safe) and insert super/sub reliably.
2. Arrow shortcut matching supports both key and code variants.
3. If user presses `Ctrl+Up/Down` in editor context with no active math field, inline math is opened and the template is inserted.
4. No rewrite needed; fix stays within current MathLive + contenteditable architecture.

### Incomplete

1. Save/load persistence is still not implemented.
2. Exact PDF-accurate preview remains deferred.

### Next first action

User validation of `Ctrl+Up/Down` in normal typing flow, then implement save/load.

---

## 2026-02-27 - session 6 (math field chrome cleanup)

### Goal

Remove distracting math-field UI chrome (keyboard toggle and underline line).

### Changed files

1. `projects/ai_sci_word/prototype_web/styles.css`
2. `projects/ai_sci_word/session_log.md`
3. `projects/ai_sci_word/memory.md`

### What works

1. Math field underline/focus line is removed.
2. Virtual keyboard and menu toggle parts are hidden via CSS.
3. Math still renders in-place with the same shortcut flow.

### Incomplete

1. Exact PDF-accurate preview is still not complete.
2. Save/load persistence is still not implemented.

### Next first action

User visual validation of this pass, then save/load implementation.

---

## 2026-02-27 - session 9 (legacy shortcut polish and right-click formatting)

### Goal

Add legacy super/sub shortcut behavior and quick formatting actions from right click.

### Changed files

1. `projects/ai_sci_word/prototype_web/app.js`
2. `projects/ai_sci_word/prototype_web/styles.css`
3. `projects/ai_sci_word/prototype_web/index.html`
4. `projects/ai_sci_word/prototype_web/README.md`
5. `projects/ai_sci_word/session_log.md`
6. `projects/ai_sci_word/memory.md`
7. `projects/ai_sci_word/STATUS.md`

### What works

1. `Ctrl+Up` inserts superscript in math mode.
2. `Ctrl+Down` inserts subscript in math mode.
3. Display equations are auto-numbered.
4. Right-click menu supports Title/Subtitle/Section and other quick formatting options.
5. Right-click on math gives inline/display/exit math options.

### Incomplete

1. Save/load persistence is still not implemented.
2. Exact PDF-accurate preview remains deferred.

### Next first action

User validation of shortcut/menu behavior, then save/load implementation.

---

## 2026-02-27 - session 8 (math toggle reliability and focus styling)

### Goal

Fix inconsistent `Ctrl+M` toggle-off behavior and reduce aggressive focus box on math selection.

### Changed files

1. `projects/ai_sci_word/prototype_web/app.js`
2. `projects/ai_sci_word/prototype_web/styles.css`
3. `projects/ai_sci_word/session_log.md`
4. `projects/ai_sci_word/memory.md`
5. `projects/ai_sci_word/STATUS.md`

### What works

1. Shortcut handling moved to document-level capture, so `Ctrl+M` works reliably inside math fields.
2. Math focus indicator changed from aggressive dark box to a thin, math-colored line.
3. Keyboard/menu UI chrome remains hidden.

### Incomplete

1. Save/load persistence is still not implemented.
2. Exact PDF-accurate preview remains deferred.

### Next first action

User validation of toggle/focus behavior, then implement save/load.

---

## 2026-02-27 - session 7 (inline math baseline adjustment)

### Goal

Make inline math adjust more naturally inside running text.

### Changed files

1. `projects/ai_sci_word/prototype_web/styles.css`
2. `projects/ai_sci_word/session_log.md`
3. `projects/ai_sci_word/memory.md`
4. `projects/ai_sci_word/STATUS.md`

### What works

1. Editor and preview line-height tuned for smoother mixed text/math lines.
2. Inline math baseline shifted to sit more like LaTeX inline formulas.
3. Inline math horizontal spacing tuned to reduce visual bumps.

### Incomplete

1. Exact PDF-accurate preview is still not complete.
2. Save/load persistence is still not implemented.

### Next first action

User visual check on paragraph-level inline math flow; then implement save/load.

---

## 2026-02-27 - session 5 (immediate visual math engine switch)

### Goal

Make in-editor math look closer to LaTeX output while typing.

### Changed files

1. `projects/ai_sci_word/prototype_web/index.html`
2. `projects/ai_sci_word/prototype_web/app.js`
3. `projects/ai_sci_word/prototype_web/styles.css`
4. `projects/ai_sci_word/prototype_web/README.md`
5. `projects/ai_sci_word/session_log.md`
6. `projects/ai_sci_word/memory.md`
7. `projects/ai_sci_word/STATUS.md`

### What works

1. Math input is now immediate visual editing using MathLive (`math-field`) in the editor.
2. `Ctrl+M` toggles inline math on and off.
3. `Ctrl+D` creates a new display equation.
4. `Ctrl+G` then letter inserts Greek commands into math mode; rendered output shows symbols.
5. Text and math now use a unified LaTeX-like baseline with subtle math color cue.

### Incomplete

1. Exact PDF-accurate preview is still not complete.
2. Save/load persistence is still not implemented.

### Next first action

Get user validation on this visual pass, then implement save/load.

---

## 2026-02-27 - session 1 to 4 summary

### Scope completed

1. Phase-1 prototype scaffold created.
2. Keyboard-first math flow implemented and iterated.
3. Legacy-style shortcut set added (`Ctrl+R`, `Ctrl+F`, `Ctrl+I`, `Ctrl+H`, `Ctrl+L`, `Ctrl+9`, `Ctrl+G`).
4. Style pass performed to reduce visual mismatch between body text and math.

### Remaining phase-1 gaps

1. Save/load persistence.
2. Stronger exact preview path.
