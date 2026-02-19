# User Preferences

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
