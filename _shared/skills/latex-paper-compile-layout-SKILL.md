---
name: latex-paper-compile-layout
description: Compile and visually QA LaTeX economics paper PDFs, especially when the user asks to compile/open a PDF, fix PDF layout, place figures near discussion, make references/cross-references clickable with hidden links, keep footnotes at the bottom of pages, or clean odd page breaks and stretched spacing.
---

# LaTeX Paper Compile And Layout

Use this skill for paper-stage LaTeX/PDF work where layout matters, not merely whether LaTeX compiles.

## Core Rule

Treat the canonical manuscript PDF as the live output. Rebuild the same PDF in place, visually inspect the affected pages, and reopen the same file. Do not create a second temporary PDF as the user's live copy just to avoid a file lock.

## Workflow

1. Identify the canonical `.tex` and `.pdf`.
   - Prefer the current project paper source and its matching PDF.
   - Check `C:` free space before rendering pages or creating artifacts. Follow the repository guard: if free space is below 20 GB, stop and report it before continuing. When work may resume, keep rebuildable renders and scratch outputs on `D:\AI_storage\spillover\`.

2. Check PDF viewer locking before compiling.
   - SumatraPDF is preferred for live viewing because it usually refreshes cleanly.
   - If compilation cannot write the PDF, close only the PDF viewer, rebuild the same canonical PDF, then reopen it.
   - Do not kill unrelated apps.

3. Compile correctly.
   - Run LaTeX from the manuscript directory.
   - Run at least two passes after changing labels, references, captions, `hyperref`, section ordering, or figure placement.
   - Treat unresolved references, missing figures, and write-lock failures as not ready.
   - When the preamble is in scope and compatible with the document, retain or add `microtype`, `xurl`, and `\setlength{\emergencystretch}{3em}` to reduce avoidable overflow. If `xurl` is unavailable, use the document's existing URL handling or `\usepackage[hyphens]{url}`.
   - Prefer `\href{...}{short descriptive text}` to long raw URLs in body text and source notes.

4. Use invisible links.
   - Prefer `\usepackage[hidelinks]{hyperref}` after `babel` and before `\begin{document}`.
   - Compile twice and check that references resolve.
   - Hidden links should not show colored boxes or visibly styled link text.
   - Manual bibliography text will not become clickable citations unless a citation system is introduced.

5. Place figures like a working paper.
   - Describe a figure first, then place the figure directly underneath or as close as LaTeX reasonably allows.
   - For several figures, use text-then-figure, text-then-figure, not a block of text followed by several delayed figures.
   - Avoid forced `[H]` if it creates blank pages, stranded footnotes, or large awkward whitespace.
   - If `[H]` is necessary, verify the rendered page. Resize, move, or relax the float if the page looks wrong.
   - Do not leave placeholder boxes in the paper unless the user explicitly wants a visible placeholder.
   - If a graph is missing because data are unavailable, document the missing input rather than faking the figure.

6. Keep footnotes at the page bottom.
   - Footnotes should sit at the bottom of the page, not directly under a paragraph with a large empty region below.
   - Do not use global page stretching such as `\flushbottom` if it creates visibly stretched paragraph spacing.
   - If a footnote is stranded high on the page, first try shortening the note, moving detail into the text or a figure/table note, relaxing a forced float, resizing a nearby figure, or moving the figure/text boundary.

7. Avoid ugly spacing.
   - Prefer a little white space to distorted paragraph gaps.
   - Check for large blank regions before or after `[H]` floats, section headings stranded at the bottom of a page, and figures separated from their explanatory text.
   - Keep references before appendices unless the user or journal says otherwise.

8. Visually QA the changed pages.
   - Render the changed page and at least one page before and after to PNG on `D:` when `C:` is tight.
   - Check: footnote placement, figure placement, caption fit, link styling, page breaks, cross-reference text, and whether graphs are actually the intended outputs.
   - Use the rendered images, not only the compile log, before calling the PDF ready.

## Common Fixes

- **PDF locked:** close SumatraPDF, compile in place, reopen the canonical PDF.
- **Footnote appears mid-page:** relax or move the nearby float, shorten the footnote, or move detail out of the footnote. Do not solve this with `\flushbottom` if it creates paragraph gaps.
- **Figure floats away from text:** move the figure block closer to the paragraph, use `[!htbp]`, or use `[H]` only after checking the rendered page.
- **Large blank page before a figure:** reduce figure size, allow normal float placement, or move the figure earlier/later.
- **Visible hyperlink boxes:** use `hidelinks` and compile twice.
- **Wrong graph inserted:** remove it immediately and leave a documented missing-output note or correct figure path.

## Final Report

Report only the relevant outcome:

- whether the PDF compiled cleanly;
- whether it was reopened;
- which pages were visually checked;
- remaining layout risks or missing graph/data inputs.

Do not describe internal scratch scripts or renders unless the user asks.
