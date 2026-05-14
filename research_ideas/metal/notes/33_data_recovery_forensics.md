# Data recovery forensics

Date: 2026-05-13

## What happened

The missing metal data were not in GitHub, Dropbox, Google Drive, local OneDrive exports, or the
recycle bins I could inspect. The strongest evidence points to a local junction-following cleanup:

- `research_ideas/metal/data/raw` and `research_ideas/metal/data/processed` are junctions into
  `D:\AI_data\research_ideas\metal`.
- Archived logs show the raw member dump and processed scene-network files still existed on
  `2026-04-24`.
- Archived logs show `C:\Users\Dave_\AI\.claude\worktrees\research_ideas_metal` existed on branch
  `research_ideas/metal` before a cleanup.
- At `2026-04-30 10:11:41-10:11:51` local time, a cleanup session recursively removed
  `C:\Users\Dave_\AI\.claude\worktrees`.
- The real `D:` target folders `D:\AI_data\research_ideas\metal\raw` and
  `D:\AI_data\research_ideas\metal\processed` both have `LastWriteTime = 2026-04-30 10:11:51`.

Inference: the recursive deletion of the old Claude worktree root followed the metal project's data
junctions and emptied the real `D:` raw/processed folders.

## Searches performed

- Local exact filename searches across `C:` and `D:`.
- Local Dropbox and OneDrive folder searches.
- Dropbox active and deleted-file search for exact filenames.
- Google Drive search for exact filenames.
- GitHub/Git history, object, reflog, LFS, and branch checks.
- Windows recycle-bin checks on `C:` and `D:`.
- Windows shadow-copy checks; standard listing requires elevation in this session.
- Gmail search attempt; blocked by insufficient OAuth scope.

## Rebuilt on 2026-05-13

The band-level and treatment-side data were regenerated from reproducible local sources:

- Restored the expected pointer from the old learning-by-viewing raw DB path to
  `D:\research_data\learning_by_viewing\music\strategy_8_music_pilot\raw\metal_archives`.
- Reran `code/02_build_all_metal_outcome.py`.
- Reran `code/03_build_core_treatment_panel.py`.
- Reran `code/04_build_band_influence_memo.py`.
- Reran `code/05_analyze_genre_trends.py`.
- Reran `code/06_build_country_genre_growth_panel.py`.
- Reran `code/22_build_genre_emergence.py`.

Restored headline files include:

- `data/processed/metal_archives_all_metal_band_clean.csv`
- `data/processed/metal_archives_all_metal_country_year_panel.csv`
- `data/processed/blockbuster_album_country_hits_core.csv`
- `data/processed/blockbuster_country_year_hit_panel.csv`
- `data/processed/blockbuster_band_influence_memo.md`
- `data/processed/scene_networks/city_genre_first_appearance.csv`

## Restored later on 2026-05-13

The missing delivered archives were later found in local downloads/Outlook attachment cache:

- `band_members_20260325.zip`
- `bands_and_first_releases.zip`

They were moved to `D:\AI_data\research_ideas\metal\raw`, which is the project raw-data junction
target. Known copies in Downloads and the Outlook attachment cache were removed after the D-drive
copies were verified.

The restored member dump was reingested:

- raw member-role rows: `1,038,533`
- unique member-band edges: `971,877`
- matched bands: `156,729`
- unmatched bands: `29,469`

The external-arrival branch was then rebuilt through the own-band-excluded final audit:

- `code/20_ingest_member_data.py`
- `code/24_test_community_precedes_label.py`
- `code/32_build_scene_cluster_richer_extensions.py`
- `code/83_build_external_arrival_event_study.py`
- `code/84_build_external_arrival_matched_control.py`
- `code/85_build_external_arrival_final_audit.py`

The main remaining risk is not missing data. It is whether the external-arrival result survives
country/genre concentration checks and manual event inspection.
