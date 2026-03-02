# Agent: Interview Pipeline (Single Source of Truth)

This file defines the canonical workflow for friendly book interviews in this repository.

## Objective

Turn raw interview inputs into chapter-usable artifacts with clear provenance:
- organized source files
- structured notes (Pass 1/2/3)
- quote bank with timestamps
- fact-check queue
- up-to-date master index

## Preferred Starting Point

Use Excel + Drive naming as the default:
1. Interview details are in `Interview list.xlsx`.
2. Transcript/audio file is saved in local Google Drive sync folder with guest name in filename.
3. Run `scripts/process_from_excel.py --name "<Guest Name>"`.

Other starting points still work:
- raw audio (`.mp3`, `.m4a`, `.wav`, etc.)
- raw transcript (`.txt`, `.docx`, `.md`, etc.)
- platform exports (`.vtt`, `.srt`)

## Folder Canon

Per interview folder:

`YYYY-MM-DD__GuestName__topic-slug/`

Required subfolders:
- `_meta/`
- `audio/`
- `transcript/raw/`
- `transcript/cleaned/`
- `transcript/chunks/`
- `outputs/`
- `consent/`
- `attachments/`

Required metadata file:
- `_meta/metadata.yml`

Simple front-door folders:
- `G:\My Drive\The Target Trap (Book Project)\Interviews\Raw` for incoming files.
- `G:\My Drive\The Target Trap (Book Project)\Interviews\` for final human-readable notes files named `Chapter N - Guest Name.md`.

## Status Lifecycle

`planned -> recorded -> transcribed -> notes_done -> quoted -> fact_checked`

Only advance status when outputs actually exist.

## Pipeline Steps (Simple Mode)

1. Run Excel-first processor  
   Use `scripts/process_from_excel.py` to create/update the interview folder and auto-ingest matching files from Google Drive `Interviews/Raw`.

Optional always-on mode:
- `scripts/auto_process_drive.py` watches Google Drive `Interviews/Raw` and auto-runs processing for new files.

2. Normalize transcript  
   Apply `skills/normalize_transcript.md` to produce readable `transcript/cleaned/` content.

3. Chunk transcript  
   Apply `skills/chunk_transcript.md` for thematic/time chunks in `transcript/chunks/`.

4. Pass 1 notes  
   Fill `outputs/notes_pass1_index.md`: time-coded outline, themes, best moments.

5. Pass 2 notes  
   Fill `outputs/notes_pass2_booknotes.md`: thesis implications, anecdotes, frameworks, tensions, chapter links.

6. Pass 3 quotes  
   Fill `outputs/notes_pass3_quotes.md`: quote bank with context/usefulness/fact-check flags.

7. Fact checks  
   Fill `outputs/fact_checks.md` with claim-level verification tasks and status.

8. Update index  
   Run `scripts/update_index.py` so `master_index.*` reflects current state.

## Excel Policy

- Track interviews via:
  - one global workbook, or
  - one workbook per interview.
- Always store a link in `metadata.yml` (`excel_link`).
- If readable with `pandas` + `openpyxl`, use Excel only to prefill missing metadata fields.
- Never overwrite confirmed metadata values with uncertain Excel values.

## Repeatability and Idempotency

- Re-running scripts should be safe.
- Scripts should avoid duplicate `source_files` entries.
- Existing manual notes must not be overwritten unless explicitly forced.
- Index regeneration is safe to run anytime.
