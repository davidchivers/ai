#!/usr/bin/env bash
set -euo pipefail

LOCAL_EXPORT='/mnt/c/Users/Dave_/OneDrive/Desktop/Economics/projects/03_fertility_and_housing_supply/exports/david_ai_output_with_zac_and_david/'
DROPBOX_AI='/mnt/c/Users/Dave_/Dropbox/Zac and David/David AI Output/'
LOCAL_LIT='/mnt/c/Users/Dave_/OneDrive/Desktop/Economics/projects/03_fertility_and_housing_supply/literature/'
DROPBOX_LIT='/mnt/c/Users/Dave_/Dropbox/Zac and David/literature/'

for d in "$LOCAL_EXPORT" "$DROPBOX_AI" "$LOCAL_LIT" "$DROPBOX_LIT"; do
  [[ -d "$d" ]] || { echo "Missing dir: $d" >&2; exit 1; }
done

# Mirror local export folder to Dropbox AI output
rsync -av --delete --exclude '.*' "$LOCAL_EXPORT" "$DROPBOX_AI"

# Mirror local fertility literature PDFs into Zac-and-David literature folder
rsync -av --exclude 'old/' --exclude '*/' --exclude '.*' "$LOCAL_LIT" "$DROPBOX_LIT"

echo 'Export + literature sync complete.'
