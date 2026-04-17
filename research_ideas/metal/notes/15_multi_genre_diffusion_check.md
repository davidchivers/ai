# 15 Multi-genre diffusion check

Last updated: 2026-03-27
Status: exploratory cross-genre diffusion comparison

## Why this note exists

The first serious diffusion exposure panel was built for `black_metal`. The obvious next question
was whether that pattern was genre-specific or whether the same logic holds across other major
genres.

This note records the first narrow comparison across:

- `black_metal`
- `death_metal`
- `thrash_metal`
- `doom_metal`
- `power_metal`

## What was run

The same script was run on each genre:

- `code/50_build_scene_diffusion_exposure_panel.py`

Each pass uses:

- geography-clean matched city cells
- an at-risk sample from `first_band_year` to `emergence_year`
- lagged local same-genre band stock
- lagged distance-weighted exposure to already-emerged same-genre hubs
- lagged distance-weighted active-band stock in already-emerged hubs

## Main read

The cross-genre comparison does **not** currently support a strong general diffusion headline.

### Black metal

- external hub exposure is positive on its own
- so is hub active-band exposure
- but both wash out once lagged local same-genre band stock is included

### Death metal

- external exposure terms are not positive even on their own in the first pass
- lagged local same-genre band stock remains strongly positive

### Thrash metal

- external exposure terms are near zero
- lagged local same-genre band stock remains strongly positive

### Doom metal

- descriptive exposure bins slope upward
- but the first reduced-form exposure terms are not robust
- lagged local same-genre band stock still dominates

### Power metal

- no useful diffusion signal in the first reduced-form pass
- lagged local same-genre band stock remains the main term

## Working interpretation

This is a useful result even though it is not the most exciting one.

The diffusion branch still matters descriptively:

- genres clearly spread across places
- the animated maps show hub formation and later spread

But the first multi-genre empirical pass says the external diffusion terms are mostly not carrying
independent predictive power once local thickness is already in the model.

So the current ranking should be:

1. main empirical object:
   local scene formation
2. useful descriptive complement:
   scene diffusion maps
3. not yet a headline result:
   diffusion exposure regressions

## Practical implication

The project should not pivot into a diffusion paper right now. The cleaner use of this branch is:

- keep the maps as visual support
- mention the diffusion-panel check as a secondary diagnostic
- treat the null or weak multi-genre exposure result as reassurance that the main paper is really
  about local scene thickening rather than just external imitation
