# Skill: Normalize Transcript

## Input
- Raw transcript in `transcript/raw/` (`.txt`, `.docx`, `.md`) or export in `transcript/raw/exports/` (`.vtt`, `.srt`).

## Output
- Cleaned transcript markdown in `transcript/cleaned/`.
- Basic speaker labels, corrected obvious OCR/export noise, preserved timestamps when available.

## Rules
- Do not rewrite meaning; only normalize formatting and readability.
- Keep uncertain text marked as `[unclear]`.
- Preserve all timing markers if present.
- Mark inferred speaker labels explicitly with `[inferred]` when uncertain.

## Procedure
1. Convert line breaks and remove duplicate whitespace/noise tokens.
2. Keep one block per speaking turn where possible.
3. Normalize speaker tags (`Interviewer`, `Guest`, `Other`).
4. Retain or reconstruct timestamps at section boundaries.
5. Save as `transcript/cleaned/<source_stem>_cleaned.md`.

