# BOOK

## Purpose
This is a co-authored book project for Tom and David. The structure is designed to keep early drafts separate from polished chapters and to make supporting material easy to find.

## Folder guide
- `Draft Chapters/` is where first drafts go.
- `Final Chapters/` is where polished, ready-to-use versions go.
- `Resources/` is for anything useful during writing, including the three PDF books we have written.

## Why the three PDF books are in Resources
- They are there so you can learn and mirror our style and tone.
- They are not primarily for quoting.
- PDFs can be slower to digest, so if we can obtain Word versions later we should consider adding those for better search and editing.

## How we use Resources
- We may ask you to look something up or search the PDFs for examples, phrasing, or stylistic patterns.

## Root files
- `Bookmaster Plan.md` is the master outline and structure of the book.
- `To Do List.md` is the shared checklist of decisions and tasks to tick off.

## Usage rules
- Keep drafts in `Draft Chapters/` and only polished chapters in `Final Chapters/`.
- Do not put old versions in the root. Use `Resources/old/` for archives.
- Keep this structure simple and tidy so it remains novice-proof.
- Do not use wrapped placeholder markers in any draft; use explicit tags like `[TODO: clarify this claim]`.
- Before handoff, run `powershell -ExecutionPolicy Bypass -File projects/book/resources/code/check_placeholders.ps1`.
