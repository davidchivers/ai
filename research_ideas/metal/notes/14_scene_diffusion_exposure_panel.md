# 14 Scene diffusion exposure panel

Last updated: 2026-03-27
Status: first serious diffusion panel note

## Why this note exists

The animated maps are useful, but they are still descriptive. The real next question is whether
later local scene emergence tracks prior exposure to already-emerged same-genre hubs.

That is the first object in this project that treats diffusion as an empirical panel rather than as
a visual story.

## Preferred black-metal prototype

The first serious pass is deliberately narrow:

- genre family:
  `black_metal`
- sample:
  geography-clean `city x year` rows after the first local band appears
- outcome:
  `emergence_this_year_i`
- key external regressors:
  - distance-weighted stock of already-emerged same-genre hubs
  - distance-weighted lagged active-band stock in already-emerged hubs

The local comparison is important. This branch should not ask whether diffusion matters instead of
local thickness. It should ask whether external hub exposure matters in addition to local same-genre
capacity.

## Working files

- `code/50_build_scene_diffusion_exposure_panel.py`
- `data/processed/scene_networks/diffusion/black_metal_diffusion_exposure_panel.csv`
- `data/processed/scene_networks/diffusion/black_metal_diffusion_exposure_results.csv`
- `data/processed/scene_networks/diffusion/black_metal_diffusion_exposure_bins.csv`
- `data/processed/scene_networks/diffusion/black_metal_diffusion_exposure_summary.md`

## Role in the project

This is still secondary to the main scene-emergence paper, but it is the right kind of secondary
branch. If it works, it makes the project much easier to describe as a paper about localized niche
formation and diffusion rather than only as a paper about one strange dataset.
