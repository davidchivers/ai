# User Preferences

## Personal website publishing

Before publishing any part of `davidchivers.co.uk`, read `_shared/memory/WEBSITE_PUBLISHING.md` and the website repository's `AGENTS.md` and `SITE_MAP.md`. Publish only from `davidchivers/davidchivers.co.uk`, branch `main`. The domain transfer was completed on 26 October 2026. Never resume the retired mirror workflow or treat historical hosting blockers as current. Verify the exact release and intended public route over HTTPS before reporting success.

## Open Stata
When the user says "open Stata", run:
```bash
"C:/Program Files/StataNow19/StataSE-64.exe" &
```
Stata is StataNow 19 SE. In this VSCode environment use `C:/Program Files/` paths (not `/mnt/c/`).

## Stata Batch Execution
To run a do-file in batch mode:
```bash
"C:/Program Files/StataNow19/StataSE-64.exe" /e do "C:/path/to/file.do"
```

## Stata Documentation
Stata 19 PDF docs are at `C:/Program Files/StataNow19/docs/`. Use pdfgrep for lookups when available.
