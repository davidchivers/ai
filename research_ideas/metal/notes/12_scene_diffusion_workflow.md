# 12 Scene diffusion workflow

Last updated: 2026-03-27
Status: exploratory scene-diffusion branch

## Why this branch exists

The main paper is about local scene emergence. But that still leaves a broader question open:
once a genre becomes legible in one set of hubs, how do later local scenes appear elsewhere?

That is a better framing than a narrow `distance from Finland` story. Many genres do not have a
single uncontested birthplace, and the more interesting object is not proximity to one origin. It
is scene-to-scene diffusion:

- an early city becomes a dense hub in a genre
- that hub makes the genre more legible elsewhere
- later other cities accumulate enough local entry to form their own scene

Economically, this is a diffusion question about how new creative niche templates spread across
places and later become locally viable.

## First prototype

The first prototype keeps the branch simple and descriptive. It uses `black_metal` as the initial
genre because it has broad international spread and enough city-level emergence to make an
animated map worthwhile.

Current build:

- `code/48_build_scene_diffusion_map.py`
- `data/processed/scene_networks/diffusion/black_metal_city_coordinates.csv`
- `data/processed/scene_networks/diffusion/black_metal_scene_diffusion_panel.csv`
- `data/processed/scene_networks/diffusion/black_metal_scene_diffusion_map.html`
- `data/processed/scene_networks/diffusion/black_metal_scene_diffusion_summary.md`

## What the map does

The map does not try to show direct listening or citation. It shows the spread of local scene
thickness over time.

- unit on the map:
  geography-clean cities that eventually reach local scene emergence
- marker size:
  active local bands in the focal genre in that year
- marker color:
  active before local emergence versus already emerged local scene

This is a useful first object because it visually separates two moments:

- first local presence
- later local scene emergence

That distinction is exactly what the paper needs if it wants to describe diffusion without
pretending that every scattered early band is already a scene.

## What this branch can become

If the descriptive map looks compelling, the next real step is an exposure panel rather than a
prettier map.

The preferred outcome would be:

- `emergence this year` for a `city x genre_family x year` cell

The preferred diffusion regressors would be things like:

- distance-weighted stock of already-emerged same-genre cities at `t-1`
- distance-weighted stock of same-genre bands in already-emerged hubs at `t-1`
- maybe a hub-weighted version where bigger scenes count more

That would let the branch ask whether later scene emergence tracks prior external exposure to
existing genre hubs, not merely local scene thickness.

## What not to claim

- do not say we observe ideas directly
- do not say the map identifies causal diffusion
- do not force a single birthplace narrative when the genre's origin is contested

Safer language is:

- scene diffusion
- spread of genre templates
- spread of legible niche models
- later emergence after exposure to already-active hubs

## Role in the project

This branch is not the main paper object. The core paper remains the local scene-emergence panel.
The diffusion branch is useful because it helps answer the obvious external question:

if local scenes matter, how do new local scenes then spread across places?

That makes the project read less like a niche case study and more like a paper about localized
innovation and diffusion in a project-based creative industry.
