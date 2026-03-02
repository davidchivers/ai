# Prototype web (phase 1, LyX Lite baseline)

This is a stripped-down Typora-like phase-1 prototype for AI Sci Word.

## What works now

1. Single clean one-page writing surface (no toolbar, no side panels).
2. Inline math mode toggle with `Ctrl+M` (type directly, no LaTeX prompt).
3. New display equation with `Ctrl+D`.
4. Exit math mode with `Ctrl+T` (or `Esc`).
5. Greek insertion mode with `Ctrl+G`, then letter (`a` => alpha symbol, etc.; `8` => infinity symbol).
6. Math templates in math mode:
   - `Ctrl+R` square root
   - `Ctrl+F` fraction
   - `Ctrl+I` integral
   - `Ctrl+H` or `Ctrl+Up` superscript
   - `Ctrl+L` or `Ctrl+Down` subscript
   - `Ctrl+9` parentheses
7. Unified LaTeX-like typography baseline with subtle math color cue.
8. Immediate visual math editing with MathLive.
9. Display equations are auto-numbered.

## Run locally

From `projects/ai_sci_word/prototype_web/`:

```powershell
python -m http.server 8080
```

Then open:

`http://localhost:8080`

If Python is unavailable:

```powershell
npx serve .
```

## Notes

1. This is intentionally simple and zero-build for fast iteration.
2. This baseline is focused on writing feel and math speed, not exact PDF output.
3. AI actions are not wired yet; inline command detection is placeholder only.
