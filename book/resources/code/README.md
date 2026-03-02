# Code

Purpose
- Scripts and notebooks that produce figures, tables, or checks used in the book.

What goes here
- Data prep scripts, analysis scripts, small utilities.
- Reproducible code for any numbers used in chapters.

Conventions
- Keep scripts small and focused.
- Reference inputs and outputs explicitly in comments.
- Put outputs in `figures/` or `Manuscript/`, not here.

Utility checks
- Run `powershell -ExecutionPolicy Bypass -File projects/book/resources/code/check_placeholders.ps1` before handing off drafts to catch unresolved markdown placeholder markers.
