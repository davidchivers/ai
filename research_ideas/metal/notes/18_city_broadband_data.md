# City broadband data workflow

## What now exists

There is now a reusable city-broadband raw store on `D:` built from official `Ookla Open Data`
fixed-broadband parquet files.

Raw mirror root:

- `D:\AI_data\shared\connectivity\ookla_open_data\`

Raw coverage currently mirrored:

- service type: `fixed`
- format: `parquet`
- horizon: `2019 Q1` to `2025 Q4`
- files: `28`
- total raw size: about `8.57 GB`

The reusable shared scripts are:

- `C:\Users\Dave_\AI\_shared\scripts\download_ookla_open_data.py`
- `C:\Users\Dave_\AI\_shared\scripts\aggregate_ookla_tiles_to_city_points.py`

## Why this is useful

This is the first real city-level broadband workflow on this machine that can be reused across
projects. The raw Ookla data are tile-level rather than city-level, but the aggregation script now
turns any city-point file with `latitude` and `longitude` into a city-quarter panel using a radius
rule.

## First proof-of-concept panel

For the metal diffusion branch, the black-metal city list now has a working city-quarter broadband
panel:

- `data/processed/scene_networks/diffusion/black_metal_city_broadband_2019_2025_radius15km.csv`

Current coverage:

- `895` cities
- `28` quarters
- `25,060` city-quarter rows
- nonzero tile coverage in all `25,060` rows
- radius rule: `15 km`

Simple descriptive read:

- median city download speed rises from about `55.2 Mbps` in `2019 Q1` to `269.2 Mbps` in
  `2025 Q4`
- median upload speed rises from about `19.6 Mbps` to `149.5 Mbps`
- median latency falls from about `22.4 ms` to `12.2 ms`

## Important limitation

This is a strong reusable city-broadband object for recent years, but it does **not** solve the
early internet-era problem in the main metal paper. The mirrored fixed-broadband panel starts in
`2019`, so it is more naturally useful for newer city-level creative-industry work and for the
other project than for explaining scene spread in the `1990s` or `2000s`.

If we need a longer-run city-level internet series later, the next candidate is `M-Lab`, but that
would be a different, heavier workflow.
