# Interviews System

This folder provides a repeatable, idempotent workflow for book interviews.

It supports starting from:
- raw audio (`.mp3`, `.m4a`, `.wav`, etc.)
- raw transcript (`.txt`, `.docx`, `.md`, etc.)
- platform transcript export (`.vtt`, `.srt`)

Everything is organized under `interviews/` with one folder per interview:
`YYYY-MM-DD__GuestName__topic-slug`

Google Drive front-door folders:
- `G:\My Drive\The Target Trap (Book Project)\Interviews\Raw`: input drop folder.
- `G:\My Drive\The Target Trap (Book Project)\Interviews\`: final notes files (for example `Chapter 2 - Daisy Christodoulou.md`).

Local fallback folders are still available:
- `interview_raw/`
- `interview_notes/`

## Top-Level Contents

- `master_index.md` and `master_index.csv`: generated interview register.
- `templates/`: reusable markdown templates for packets and note passes.
- `skills/`: concise task instructions for transcript and notes workflows.
- `agents/interview_pipeline.md`: single source of truth for end-to-end flow.
- `scripts/`: local automation scripts (no network required).
- `tom_and_dave_interview_process.md`: human workflow guide.
- `tom_and_dave_interview_process.docx`: Word version of the same guide.
- `interview_raw/`: local input fallback.
- `interview_notes/`: local output fallback.

## Scripts

All scripts support `--help`.

- `scripts/process_from_excel.py` (recommended)
  - Reads interview details from Excel (`Interview list.xlsx`).
  - Selects by `--name` (or auto-picks next dated not-done interview).
  - Creates/updates interview folder and metadata.
  - Searches `G:\My Drive\The Target Trap (Book Project)\Interviews\Raw` first, then local fallback folders.
  - Ingests matched files and updates `master_index.*`.
  - Creates a simple notes file in `G:\My Drive\The Target Trap (Book Project)\Interviews\` named like `Chapter N - Guest Name.md` (plus local fallback copy).

- `scripts/auto_process_drive.py` (optional auto mode)
  - Watches `G:\My Drive\The Target Trap (Book Project)\Interviews\Raw` (or `--drive-root`) for new files.
  - Matches filename to guest names in Excel.
  - Auto-runs `process_from_excel.py` on matched files.

- `scripts/watcher_manager.py` (recommended for always-on mode)
  - Starts/stops/checks the background watcher process.
  - Default watcher source is Google Drive `Interviews\Raw`.

- `scripts/new_interview.py`
  - Creates a new interview folder scaffold.
  - Creates `_meta/metadata.yml`, packet, and output note files.
  - Detects and links Excel tracker if available.
  - Optionally prefills metadata from readable Excel.
  - Updates `master_index.*`.

- `scripts/ingest_files.py`
  - Copies or moves files into the correct interview subfolder.
  - Auto-detects file kind (`audio`, `transcript`, `export`, `excel`, `attachment`) or accepts `--kind`.
  - Updates metadata source paths/status and `master_index.*`.

- `scripts/update_index.py`
  - Scans interview metadata.
  - Refreshes `master_index.md` and `master_index.csv`.
  - Detects Excel links and writes back missing metadata fields.

## Excel Handling

The scripts try these tracker patterns:

1. `--excel <path>` (if provided)
2. `interviews/interview_tracker.xlsx`
3. common interview tracker names in `interviews/` and its parent (for example `../Interview list.xlsx`)
4. per-interview workbooks found inside each interview folder

If `pandas` + `openpyxl` are installed, scripts attempt to prefill missing metadata from readable Excel rows.
If not installed or unreadable, scripts continue and still store `excel_link`.

Optional install:

```powershell
python -m pip install pandas openpyxl
```

## Quick Start

```powershell
# 1) Drop files into G:\My Drive\The Target Trap (Book Project)\Interviews\Raw, then process one guest
python projects/book/interviews/scripts/process_from_excel.py --name "Jonathan Wilson"

# 2) Optional: run watcher for automatic processing of new files
python projects/book/interviews/scripts/watcher_manager.py start

# Check watcher status
python projects/book/interviews/scripts/watcher_manager.py status

# Stop watcher
python projects/book/interviews/scripts/watcher_manager.py stop

# 3) If needed, manually ingest extra files
python projects/book/interviews/scripts/ingest_files.py --interview "2026-02-25__JaneSmith__school-choice-evidence" --file "C:\path\interview_audio.m4a"

# 4) Refresh master index
python projects/book/interviews/scripts/update_index.py
```

## Very Simple Workflow (what you actually do)

1. Keep `Interview list.xlsx` updated (name + interview date + chapter).
2. Drop transcript/audio into `G:\My Drive\The Target Trap (Book Project)\Interviews\Raw` with the guest name in the filename.
3. Ask Codex to process the interview end-to-end (no manual scripts needed).

Example:

`Process the interview for Jonathan Wilson from Interview list.xlsx, use files in G:\My Drive\The Target Trap (Book Project)\Interviews\Raw, ingest them, and draft notes.`

## Idempotency Rules

- Re-running `new_interview.py` does not delete existing content.
- Existing files are preserved unless `--force`/`--overwrite` is provided.
- Source file lists and metadata links are deduplicated.
- `update_index.py` can be run at any time.
