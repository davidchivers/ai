# 13 Band world animation workflow

Last updated: 2026-03-27
Status: exploratory band-level animation branch

## Why this branch exists

The diffusion branch shows how genres spread from city to city. This branch goes one level lower:
it tries to show the bands themselves on a world map over time.

The idea is simple:

- each dot is a band
- the band appears in the years it is active
- the map moves from the first active bands to the modern-day scene

That is useful because it makes the project visually legible as a world-scale creative process,
not just as a city-level panel.

## Prototype choice

The first genre is `black_metal`.

That is the best default for a first pass because:

- it has enough bands to make the map interesting
- it has a long time span
- it is geographically broad enough to test whether the animation is readable

## Data and assumptions

The prototype uses the cleaned band panel in:

- `data/processed/band_success/band_birth_panel.csv`

It relies on the same active-window logic used in the member ingest helper:

- parse spans like `1988-1993, 2004-present`
- treat `present` or `?` as open-ended through the current data window
- fall back to `formed_year` if the activity string is unusable

The map also uses the geography-clean city filter from the scene branch, so region-like labels are
not treated as world-map points.

## Working files

- `code/49_build_band_genre_world_animation.py`
- `data/processed/scene_networks/band_world_animation/black_metal_band_world_animation.html`
- `data/processed/scene_networks/band_world_animation/black_metal_band_world_animation_panel.csv`
- `data/processed/scene_networks/band_world_animation/black_metal_band_world_animation_coordinates.csv`
- `data/processed/scene_networks/band_world_animation/black_metal_band_world_animation_yearly_summary.csv`
- `data/processed/scene_networks/band_world_animation/black_metal_band_world_animation_summary.md`

## Read

This is still exploratory. The main question is not whether the map can be made. It is whether the
result is visually useful enough to keep.

If it works, the branch can serve as a more vivid way to show the world-scale spread of a genre.
If it does not, the cleanest fallback is to keep only the diffusion branch and leave this as an
abandoned prototype.
