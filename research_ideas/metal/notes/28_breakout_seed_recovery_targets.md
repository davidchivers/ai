# 28 Breakout seed recovery targets

Last updated: 2026-04-09
Status: ranked next-step target list for the breakout-demand branch

## Why this note exists

The breakout branch is now at a point where another chart cutoff does not solve the main problem.

The strict and relaxed screens both say the same thing:

- the branch is real
- the branch is not exhausted
- but the current retained event set is still not good enough to justify event-study estimation

So the next useful question is no longer:

- should the cutoff be top `10`, top `15`, or top `20`?

The next useful question is:

- which missing or weakly recovered **home-market** seeds could actually change the first-breakout
  branch if recovered cleanly?

The machine-readable target file is:

- `data/processed/country_genre_analysis/breakout_seed_recovery_targets.csv`

## Main read

The strongest expansion margin is not another relaxed chart screen. It is recovering earlier or
missing home-market breakouts that would materially change the relaxed first-breakout set.

Three facts now matter:

1. Italy still has the cleanest source path and one remaining earlier target.
2. Sweden is no longer the main recovery bottleneck because `Carolus Rex` has now been recovered
   into the live branch.
3. Brazil looks substantively strong but remains the hardest source environment in the current
   setup.

## High-priority targets

### 1. `Lacuna Coil - Comalies` (`ITA`, `gothic_metal`, `2002`)

Why it matters:

- provisional positive-capability cities at home: `30`
- it would replace the current relaxed Italian gothic-metal first breakout
- the current relaxed branch now uses `Lacuna Coil - Karmacode` in `2006`
- moving that first breakout back to `2002` would still materially improve historical depth

Why it is attractive:

- source path is `FIMI`
- the source environment is already labeled low difficulty in `source_matrix.csv`

Current problem:

- the seed note says the current official FIMI title page returns no chart or certification
  evidence

So this remains the cleanest next recovery target, but it is now a second-step Italy target rather
than the only usable Italian gothic-metal row. `Karmacode` has already been recovered as the live
official FIMI first breakout in `2006`.

### 2. `Angra - Rebirth` (`BRA`, `power_metal`, `2001`)

Why it matters:

- provisional positive-capability cities at home: `35`
- it would add a new Brazilian power-metal home-market first breakout
- it is earlier than `Temple of Shadows` and therefore the right first-breakout object if it can
  be recovered cleanly

Current problem:

- the current Brazil workflow is still blocked on direct Pro-Music Brasil retrieval
- the row is now stronger than before because Whiplash reports the gold award being delivered on
  `2001-12-15`, and official Aquiles Priester press bios corroborate the certification
- but it is still a certification-timed signal rather than a true chart-entry breakout

### 3. `Angra - Temple of Shadows` (`BRA`, `power_metal`, `2004`)

Why it matters:

- provisional positive-capability cities at home: `39`
- it would also add a Brazilian power-metal home-market first breakout if the earlier `Rebirth`
  case remains unrecoverable

Current problem:

- the current row is now stronger than before because it has an archived `Epoca` chart page with
  publication on `2005-11-17` and a top-10 ranking for the week of `2005-11-08` to `2005-11-15`
- but it still lacks a direct official chart page and remains operationally weaker than the core
  European archive recoveries
- Brazil remains high difficulty in the source matrix

Brazil therefore looks substantively valuable but operationally expensive.

## Lower-priority or non-branch-changing targets

### `Rammstein - Sehnsucht` (`DEU`, `industrial_metal`, `1997`)

- provisional positive-capability cities at home: `2`
- it would move the German industrial first breakout earlier than `Mutter`
- but the capability margin looks thin enough that it is not a top recovery target

### `Nightwish - Dark Passion Play` (`FIN`, `symphonic_metal`, `2007`)

- provisional positive-capability cities at home: `4`
- but it would not change the Finnish first breakout, because `Once` already anchors `FIN`
  symphonic metal in `2004`

### `Rhapsody of Fire - Triumph or Agony` (`ITA`, `power_metal`, `2006`)

- strong local capability
- but it does not improve the relaxed first-breakout set because `Power of the Dragonflame`
  already anchors `ITA` power metal in `2002`

## Practical order

If the branch is pushed one step further, the sensible recovery order is:

1. `Lacuna Coil - Comalies` in `ITA`
2. `Angra - Rebirth` in `BRA`
3. `Angra - Temple of Shadows` in `BRA`

That order balances:

- branch relevance
- likely payoff for the first-breakout set
- current source feasibility

Sweden is now off this list because `Sabaton - Carolus Rex` has already been recovered as the
live Swedish power-metal first breakout from the official Sverigetopplistan archive.

## Bottom line

The branch now has a real next-step map.

If we keep pushing, the best targets are not generic new albums. They are a short list of missing
home-market recoveries that could actually change the retained first-breakout stack:

- `Comalies`
- `Rebirth`
- `Temple of Shadows`

If those do not move, the branch should probably stay at feasibility stage.
