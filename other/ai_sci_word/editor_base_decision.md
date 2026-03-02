# editor base decision (marktext/muya vs current prototype)

Date: 2026-02-27
Project: `projects/ai_sci_word/`

## question

Should AI Sci Word fork MarkText (or adopt Muya) as the editor base, or continue with the current lightweight prototype direction?

## verified facts

1. MarkText is open source under MIT.
2. MarkText desktop latest GitHub release shown is `0.17.1` from 2022-03-07.
3. The MarkText org still shows repository activity (MarkText repo updated 2025-11-19; Muya repo updated 2025-11-17).
4. Muya README states it is still under development and should not be used for production.

## inference from facts

1. MarkText is a useful reference for UX and architecture ideas, but forking it as the core v1 path is high-risk:
   - old desktop release cadence
   - larger codebase than needed for our keyboard-first math MVP
   - likely substantial customization for SciWord-style `Ctrl+M` math-toggle workflow
2. Muya is interesting for future browser embedding, but the project itself warns against production use.
3. For AI Sci Word phase 1, the lowest-risk path is to continue the current minimal Typora-like web prototype and add features incrementally.

## decision (v1 baseline)

Continue with current prototype as primary path.

- Do not fork MarkText for v1.
- Treat MarkText/Muya as reference inputs only.

## what this means for next work

1. Keep the UI minimal (single readable page, keyboard-first math flow).
2. Prioritize save/load and stability before richer formatting.
3. Re-evaluate Muya integration only after phase-1 behavior is stable and tested.

## sources

1. MarkText repository (license and project context): https://github.com/marktext/marktext
2. MarkText releases page (latest desktop release metadata): https://github.com/marktext/marktext/releases
3. MarkText org repositories page (recent update timestamps): https://github.com/marktext
4. Muya repository README (development/production warning): https://github.com/marktext/muya
