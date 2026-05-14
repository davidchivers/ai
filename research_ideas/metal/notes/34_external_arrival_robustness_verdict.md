# External arrival robustness verdict

Date: 2026-05-14

## Bottom line

The experienced outside-musician arrival branch survives the first serious mechanical robustness
gate. It should stay alive as a follow-on sidecar. It should not be folded into the stabilized main
paper yet.

The current result is positive after excluding the arriving musician's observed own band from
treated outcomes. It also survives leave-country-out, leave-genre-out, geography-clean, and
minimum-control-count checks. The remaining weakness is not the average sign. It is event quality:
the largest event-level positives include some high pre-period paths, event-year jumps, sparse
control sets, and a few administrative geography labels in treated or control locations.

## Evidence from the current audit

Current strict matched stack:

- matched treated events: `184`
- mean normalized pre coefficient, `t=-5` to `t=-2`: `0.016`
- event-year normalized coefficient, `t=0`: `0.011`
- mean normalized post coefficient, `t=+1` to `t=+3`: `0.130`

Leave-one-out checks:

- weakest leave-country-out post read: omit `Mexico`, post = `0.118`
- strongest leave-country-out post read: omit `United States`, post = `0.150`
- weakest leave-genre-out post read: omit `black_metal`, post = `0.088`
- strongest leave-genre-out post read: omit `death_metal`, post = `0.204`

Geography and match-quality checks:

- drop treated region-like labels: `177` events, post = `0.137`
- drop any region-like control label: `150` events, post = `0.121`
- drop treated or control region-like labels: `146` events, post = `0.139`
- require at least `5` controls: `130` events, post = `0.123`
- require no treated/control region-like labels and at least `5` controls: `98` events, post =
  `0.120`

These checks make the result harder to dismiss as a single-country, single-genre, sparse-control,
or region-label artifact.

## Manual audit read from the top events

The top-event target file is:

`data/processed/scene_networks/external_arrival_top_event_audit_targets.csv`

The first manual inspection gives a mixed but not fatal read:

- The largest positive treated rows are mostly real city labels: `Nuremberg`, `Madrid`, `Kuopio`,
  `Glasgow`, `Lisbon`, `Tijuana`, `Cancun`, `Levice`, `Lowell`, `Mons`, `Nancy`, and `Leon`.
- The largest negative treated rows are also mostly real city labels: `Orebro`, `Ipswich`,
  `Framingham`, `Edinburgh`, `Toronto`, `Arendal`, `Kenosha`, `Vastervik`, `Carlos Barbosa`, and
  `Khmelnytskyi`.
- The flagged treated-location problems are visible but not dominant: examples include
  `North Carolina, United States`, `Helsinki/Espoo, Finland`, and
  `Vastra Gotaland, Sweden`.
- Some matched controls are also administrative or missing labels, such as `Black Forest`,
  `Indiana`, `Ohio`, `Scotland`, and `N/A`.
- Several of the largest positives already have high pre-period or event-year paths. Examples:
  `Nuremberg x black_metal x 1998`, `Madrid x thrash_metal x 1991`,
  `Kuopio x heavy_metal x 2001`, and `Glasgow x brutal_death_metal x 2010`.

Interpretation: the average post-arrival pattern is robust enough to keep, but the top event-level
rows are not yet clean enough to sell as quasi-experimental evidence.

## Decision

Keep the branch as an active sidecar and convert it into a clean follow-on note only if the next
pass holds in the more conservative stack:

- no treated region-like location;
- no region-like control location;
- at least `5` matched controls;
- strict `cross_country_same_genre` definition;
- own-band-excluded treated outcomes.

The current clean-stack benchmark is `98` events with post `t=+1` to `t=+3` equal to `0.120`.

## Next steps

1. Recompute the leave-country-out and leave-genre-out tables inside the `98`-event clean stack.
2. Manually audit the top `10` positive and top `10` negative events in that clean stack.
3. If the result still holds, draft a short sidecar memo around experienced outside arrivals.
4. Keep the main paper focused on the field-journal scene-emergence result unless this sidecar
   survives the clean-stack event audit.
