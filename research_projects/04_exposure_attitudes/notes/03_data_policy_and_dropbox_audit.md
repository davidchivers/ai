# Data policy and Dropbox audit

## What was checked

Codex inspected safe orientation documents and filename metadata from the local synced Dropbox folder.

Codex did not open raw data, processed data, spreadsheets, compressed data, Stata data, Parquet files, SQLite files, or row-level outputs.

## Dropbox data situation

The Dropbox project contains a large `data/` tree.

Visible folder names include:

- `Dewey_raw`
- `Dewey_processed`
- `Exposure_segregation`
- `ACS`
- `Chetty et al (2022)`
- `Land Unavailability`
- `opportunity_insights`
- `Residential Segregation`
- `ZeroSum_Survey_Stantcheva`
- `Yelp`
- `Outscraper`

The project's own `PROJECT.md` says `data/Dewey_raw/` and `data/Dewey_processed/` are restricted.

## Git status from Dropbox

The Dropbox source folder has its own `.git` directory. A quick status attempt showed many added files, including code, outputs, logs, figures, and some spreadsheets outside the `data/` folder. Full Git checks were slow or timed out because the Dropbox folder is large.

Important: the Dropbox `.gitignore` ignores `data/`, `*.csv`, `*.gz`, `*.dta`, `*.zip`, `*.xlsx`, logs, PDFs, and Word files. This suggests the source repo already tries to keep large data out of Git, but the working tree still needs a careful cleanup before any push.

## Deletion issue

The user noted that there is a data file in Dropbox that should be deleted.

Codex did not delete anything because:

- the Dropbox connector was not authenticated
- the local folder contains a large `data/` tree, not one obvious single file
- Dropbox deletion is destructive and should be confirmed with an exact target path

Recommended next step:

1. identify the exact Dropbox data file or folder to remove
2. confirm whether it should be deleted from Dropbox or moved to approved local/secure storage
3. delete only after confirmation
4. record the cleanup in `STATUS.md`

## Safe rule going forward

Keep this Git repo as a clean coordination and code/documentation layer. Do not store or paste Dewey raw data, row samples, or reconstructable data outputs here.
