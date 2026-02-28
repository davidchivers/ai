#!/usr/bin/env bash
set -euo pipefail

SRC='/mnt/c/Users/Dave_/OneDrive/Desktop/Economics/projects/03_fertility_and_housing_supply/literature/'
DST='/mnt/c/Users/Dave_/Dropbox/Zac and David/literature/'

if [[ ! -d "$SRC" ]]; then
  echo "Source not found: $SRC" >&2
  exit 1
fi
if [[ ! -d "$DST" ]]; then
  echo "Destination not found: $DST" >&2
  exit 1
fi

rsync -av --exclude 'old/' --exclude '*/' --exclude '.*' "$SRC" "$DST"
echo 'Sync complete.'
