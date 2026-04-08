# Data notes

This folder holds early data scaffolds for the `metal` idea.

Current rule:

- do not duplicate the existing Metallum outcome files yet
- keep outcome reuse documented in the notes
- use this folder for treatment-side source maps and extraction templates
- stage externally delivered raw files inside this project once they become part of the active
  workflow
- git/storage split for this machine:
  - track small hand-built source files in this folder
  - keep rebuildable large data in `data/raw/` and `data/processed/` on
    `D:\AI_data\research_ideas\metal\` via local junctions
  - keep `data/exploration/` as rebuildable local diagnostics rather than tracked source

## Current files

- `raw/`
  - read-only delivered source archives used by the active workflow
  - currently includes:
    - `band_members_20260325.zip`
      - full Metal Archives member dump delivered on `2026-03-26`
- `source_matrix.csv`
  - official-source audit for the first core country set
- `blockbuster_album_seed_template.csv`
  - template for the curated blockbuster album seed
- `blockbuster_album_seed.csv`
  - active curated seed for the first treatment build
  - now also carries the Italy cleanup pass:
    - `Comalies` retained only as a historical benchmark dead end on official FIMI
    - `Delirium`, `Power of the Dragonflame`, and `Triumph or Agony` added as exact
      FIMI-recoverable Italian flagship rows
- `blockbuster_hit_rule.md`
  - operational rule for seed inclusion and country-level hit timing
- `blockbuster_album_country_hits_template.csv`
  - template for album-country hit observations from official charts and certifications
- `blockbuster_album_country_hits_pilot_sample.csv`
  - small hand-built UK/Italy pilot sample showing the fields that can already be extracted from
    official album pages and official chart databases
  - note: the Linkin Park row is now a workflow stress test, not part of the active metal seed
- `blockbuster_album_country_hits_deu_manual.csv`
  - manual official-source supplement for Germany because `offiziellecharts.de` blocks scripted
    requests in this environment
- `blockbuster_album_country_hits_bra_manual.csv`
  - manual Brazil supplement because direct Pro-Musica retrieval is blocked in this environment
  - now mixes:
    - one official band press release
    - named historical and journalistic Sepultura sources
    - some remaining weaker secondary chart and certification traces
- `exploration/`
  - reproducible outcome-scope diagnostics using the reused Metallum band file
  - includes country summaries, core-country yearly panels, top-country rankings, and descriptive
    pilot hit windows
- `processed/`
  - current all-metal outcome build from the full Metallum snapshot
  - includes cleaned band-level rows, an all-metal country-year panel, a core-country summary, and
    an all-metal overview note
  - now also includes the scene-network branch unlocked by the full member dump:
    - `scene_networks/full_musician_band_edges.csv`
    - `scene_networks/full_member_ingest_summary.md`
    - `scene_networks/city_network_stats.csv`
    - `scene_networks/city_band_band_edges.csv`
    - `scene_networks/city_network_summary.md`
    - `scene_networks/mechanism_test_merged.csv`
    - `scene_networks/mechanism_test_results.md`
  - now also includes the first four-market treatment build:
    - `blockbuster_album_country_hits_core.csv`
      - now includes seed-linked home-versus-foreign exposure columns
    - `blockbuster_country_year_hit_panel.csv`
      - now includes split treatment columns such as `hit_home_top10_ct` and `hit_foreign_top10_ct`
      - country-year summaries should now be read using chart-weeks as well as top-10 and
        certification counts
    - `blockbuster_country_year_hit_summary.md`
    - `blockbuster_band_influence_event_windows.csv`
      - now carries an `event_definition` column so the same file compares `presence`,
        `certification`, and `top10`
    - `blockbuster_band_influence_ranking.csv`
      - now carries definition-specific rankings rather than only a top-10 ranking
    - `blockbuster_band_influence_event_study.csv`
    - `blockbuster_band_influence_memo.md`
