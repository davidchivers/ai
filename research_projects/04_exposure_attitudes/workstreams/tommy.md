# Tommy workstream

## Active branch

- Branch:
- Focus: newer CBG and POI exposure-segregation pipeline
- Started:

## Notes

- Dropbox context says Tommy is handling the newer exposure-segregation pipeline under `data/Exposure_segregation/`.
- Handoff run order reported in project notes:
  1. `pipeline_poi.py`
  2. `pipeline_msa.py`
  3. `pipeline_cbg.py`
- Important implementation notes from email/context:
  - restore `MIN_WEEKS_OBSERVED` to `26` for production after testing
  - distinguish `dest_*`, `origin_*`, and `origin_nondiag_*` measures
  - add distance-based SES and racial-composition exposure measures
  - crosswalk choice between NBER 2020 county-to-CBSA and older Chandler Lutz crosswalk remains an open design point

## Session log

- 2026-04-27: Initial workstream placeholder created from Dropbox intake.
