# Handoff For Claude

## Context
- Project: `projects/BOOK`
- Type: popular science book project (not academic paper workflow)
- Main collaboration folder: `G:\My Drive\The Target Trap (Book Project)`
- Collaborator: Tom Chivers should be able to view/edit in Google Docs via Drive sharing

## What is already set up
- `projects/BOOK/README.md` reframed for book workflow
- `projects/BOOK/memory.md` updated with collaboration context
- `_shared/memory/RESEARCH_STYLE.md` updated with global book preferences
- `projects/BOOK/googledrive/INDEX.md` contains current Google Docs index
- `projects/BOOK/googledrive/refresh_drive_index.ps1` refreshes `INDEX.md`

## Important technical limitation in this shell
- Can list Google Drive `.gdoc` files via metadata.
- Cannot reliably read/copy `.gdoc` payloads.
- Cannot create privileged filesystem link/junction into `projects/BOOK` from this session.

## Requested user preference
- Do not bring "How to Read Numbers" materials into this repository.
- User will retrieve those separately.

## Suggested next action in Claude
1. Use Claude Gmail/Google integrations to locate authoritative doc links.
2. Confirm sharing permissions for Tom on `The Target Trap (Book Project)`.
3. Keep this repo as structure/index/tracking; keep live co-writing in Google Docs.
