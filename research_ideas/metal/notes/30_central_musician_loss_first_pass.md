# Central musician loss first pass

## What I tried

I treated the central-musician-loss idea as a bounded feasibility audit rather than as a new paper.
The workflow was:

1. use the live member-edge data to identify musicians with fully observed terminal years
2. keep only musicians with at least `3` lifetime bands
3. locate the musician's strongest `city x genre_family x terminal_year` cell
4. require at least `2` active same-genre local bands for the musician in the terminal year
5. require at least `5` active same-genre bands in the local scene
6. when the exact terminal-year scene row is missing, fall back to the most recent earlier
   `city x genre_family` scene snapshot
7. cap the fallback gap at `2` years
8. web-audit the top shortlist for actual deaths or clearly permanent exits

The reusable code object is:

- `code/77_build_central_loss_audit_shortlist.py`

The first generated outputs are:

- `data/processed/scene_networks/central_loss_candidate_cells.csv`
- `data/processed/scene_networks/central_loss_audit_shortlist.csv`
- `data/processed/scene_networks/central_loss_audit_summary.md`
- `data/processed/scene_networks/central_loss_audit_shortlist_recovery.csv`
- `data/processed/scene_networks/central_loss_audit_summary_recovery.md`
- `data/processed/scene_networks/central_loss_audit_shortlist_recovery3.csv`
- `data/processed/scene_networks/central_loss_audit_summary_recovery3.md`
- `data/processed/scene_networks/central_loss_audit_shortlist_recovery_loose.csv`
- `data/processed/scene_networks/central_loss_audit_summary_recovery_loose.md`
- `data/processed/scene_networks/central_loss_audit_shortlist_recovery_anycurrent.csv`
- `data/processed/scene_networks/central_loss_audit_summary_recovery_anycurrent.md`
- `data/processed/scene_networks/central_loss_manual_audit_first_pass.csv`
- `data/processed/scene_networks/central_loss_verified_death_events.csv`
- `data/processed/scene_networks/central_loss_event_preview.csv`
- `data/processed/scene_networks/central_loss_event_window_preview.csv`
- `data/processed/scene_networks/central_loss_event_preview_summary.md`

## Mechanical screen read

Under the conservative baseline screen:

- `1,698` musicians survive as clean terminal-year candidates after requiring `3+` lifetime bands
- these collapse to `32` plausible `member x city x genre x terminal_year` connector cells after
  the capped fallback scene merge
- the one-row-per-member shortlist has `31` rows

This is already informative. The pool is not huge once the screen demands:

- no blank `last_year_in_band` anywhere for the musician
- nontrivial local same-genre overlap
- a scene that is actually thick enough to matter

## Manual audit read

The first web audit gives a useful mixed picture.

### Clear or near-clear positive cases

- `L-G Petrov` (`Stockholm x death_metal x 2021`) is now recovered as a real death event once the
  scene merge is allowed to fall back to the most recent earlier scene snapshot
- `Kory Alvarez` (`Los Angeles x death_metal x 2022`) looks like a real death event
- `Miguel Angel` (`Mexico City x death_metal x 2019`) looks like a real death event
- `Jasmine You` (`Tokyo x power_metal x 2009`) looks like a real death event
- `Eric Wagner` (`Chicago x doom_metal x 2021`) looks like a real death event
- `Nattdal` (`Stockholm x black_metal x 2011`) also looks like a real death event, though the
  source quality is more specialist than official
- `Andre Matos` (`Sao Paulo x power_metal x 2019`) looks like a real death event
- `Mortifer` (`Warsaw x death_metal x 2013`) looks like a real death event
- `Geoff Nicholls` (`Birmingham x heavy_metal x 2017`) looks like a real death event
- `Reverend Jim Forrester` (`Baltimore x stoner_metal x 2017`) looks like a real death event
- `Evgeny Reutov` (`Moscow x heavy_metal x 2010`) looks like a real death event, though the
  currently recovered date is year-only
- `Sergey Stankov` (`St. Petersburg x thrash_metal x 2016`) looks like a real death event

### Clear false positives for a death-shock design

- `Moritz Bossmann` is alive and publicly active in `2024-2025`
- `Aidan Smith` is still listed in current band materials
- `Tragisk` is still listed with an active band on the artist page
- `Ilya Zudilov` is still listed as living on the artist page
- `Luke Tolcher` is still listed as living on the artist page
- `N. Schner` is still listed as living and tied to another project
- `Kriger Morket` appears to be alive; no death event found
- `Andrew Power` does not show death evidence and remains better treated as a false lead
- `Tommy Henriksen` is publicly active in current touring and recording work

So the conservative shortlist is not nonsense. It does recover real deaths. But it also surfaces ordinary terminal-year artifacts that are not usable shocks.

### Possible permanent exits, but not death shocks

- `Capricornus` looks like a reported quit-from-music case around `2005`
- `Ariersohn` looks like a reported project-termination case in `2014`

These are worth retaining in the broader audit ledger, but not yet in the clean death-event file.

## Important limitation

The cleanest limitation is now different.

The branch can recover true deaths once the scene merge is softened slightly, but it still produces
false positives because a terminal year in the membership data is not itself a shock. That means:

- the no-blank-terminal-year rule is useful for precision
- the capped fallback scene merge is useful for late cases
- but the design still depends on external audit to distinguish genuine death shocks from ordinary
  disappearance or stale metadata

So the live shortlist is good enough for a feasibility branch, but not good enough to be used as an
automatic treatment file.

## Practical interpretation

The branch now looks feasible in a narrow sense:

- yes, the data can rank plausible central local connectors
- yes, a targeted web audit can recover real death events from that shortlist
- the current audited set already includes several names outside only the most famous global cases
- yes, a small fallback to the latest available scene snapshot recovers important late cases
- no, the shortlist is still not sufficient on its own because terminal years generate false
  positives without external event verification

The practical result is that the branch now has a first actual event object:

- the clean verified-death file now contains `20` cases

That is enough to treat the branch as a serious feasibility object, but not enough on its own to
justify estimation.

## Preview-panel read

The first panel preview is sobering in a useful way.

- the verified death file now contains `20` cases
- only `9` events currently have at least `3` pre years, the event year, and at least `1` post
  year in the live `city x genre x year` panel
- `18` of the `20` verified deaths occur in cells that are already post-emergence
- the remaining `2` cases currently have no matched emergence record rather than clearly
  pre-emergence deaths

So the branch no longer looks like a plausible causal design for **scene emergence** itself.
Instead, if it works at all, it looks more like a design for **post-emergence scene activity**:

- same-genre band starts after a central death
- changes in local multi-band depth
- changes in local spawning or embedded entry

That is still interesting, but it is a different causal margin from the one in the main paper.

The right next design move is therefore not a full event study yet. It is a second-pass
event-definition workflow with two parts:

1. keep the current clean-terminal shortlist with a capped scene-gap fallback as the precision-first baseline
2. expand through the relaxed recovery shortlists before deciding whether the event count is good enough for estimation

In other words, the branch is alive and more plausible than it looked at the start of the session,
but it is still in audit mode rather than estimation mode.

## Recovery frontier after the deeper audit

The broader recovery workflow is now also largely exhausted under the current conservative
standard.

- the `any-current` recovery shortlist has been fully audited
- it did **not** produce additional verified deaths beyond the `20` already in the clean event file
- instead it mostly collapsed into `false_positive_or_alive` cases once current lineups, recent
  releases, interviews, and artist pages were checked
- the remaining uncertain bucket is now small and identity-heavy rather than obviously promising

Current ledger counts are:

- `20` `death_verified`
- `105` `not_loss_or_false_positive`
- `2` `possible_permanent_exit`
- `9` `unresolved`

The remaining unresolved names are:

- `Wizard`
- `Domjan Laszlo`
- `Roger Stachow`
- `Marcelo Bartolozzi`
- `Eliud Tamez`
- `Andrey Kapachev`
- `Sinister`
- `Dawidek`
- `Q_Snc`

So the search bottleneck is no longer raw effort. It is identity quality and weak public
memorial surface.

## First post-emergence descriptive read

The branch now has a first descriptive post-emergence summary built from the clean event file:

- `code/79_build_central_loss_post_emergence_summary.py`
- `data/processed/scene_networks/central_loss_post_emergence_event_window.csv`
- `data/processed/scene_networks/central_loss_post_emergence_relative_year_summary.csv`
- `data/processed/scene_networks/central_loss_post_emergence_summary.md`

This object takes the `20` verified deaths and keeps the `9` post-emergence cases with at least
`3` pre years, the event year, and at least `1` post year.

The descriptive read is mixed and does **not** yet support a simple collapse story:

- focal same-genre active-band stock keeps rising in the short window
- focal same-genre multi-band stock also rises modestly
- city-wide total band starts soften slightly on average after the death
- city-wide spawning flow is roughly flat to slightly higher

So the branch has now moved beyond obituary collection into a first outcome read, but it still
needs a clearer estimand and a more careful design if it is going to become a serious follow-on.

## First matched-control prototype

The branch now also has a first descriptive matched-control object:

- `code/81_build_central_loss_matched_control_prototype.py`
- `data/processed/scene_networks/central_loss_matched_controls.csv`
- `data/processed/scene_networks/central_loss_matched_relative_year_summary.csv`
- `data/processed/scene_networks/central_loss_matched_event_comparison.csv`
- `data/processed/scene_networks/central_loss_matched_control_summary.md`

This prototype takes the same `9` usable post-emergence deaths and matches each one to `3`
same-genre control cities with similar pre-event focal starts, focal stock, and focal multi-band
depth, while excluding nearby death events in the control cells.

That matched read is more informative than the raw event-window averages:

- focal same-genre band starts fall more in treated scenes than in matched controls on average
- the average DID-style change in focal same-genre band starts is `-0.932`
- `6` of the `9` event-level DID-style band-start deltas are negative
- by contrast, city-wide spawning flow does **not** fall relative to matched controls:
  - average DID-style change is `0.784`
  - only `3` of the `9` event-level DID-style spawning deltas are negative

So the most plausible live interpretation is now narrower and clearer:

- central local deaths may suppress **focal same-genre entry** at the scene margin
- they do **not** yet show a clean descriptive collapse in focal stock or in broad city-wide
  spawning

That is a better post-emergence design target than the broader `scene collapses after a central
death` story.

## First stacked fixed-effects prototype

The branch now also has a first formal stacked specification built on top of the matched-control
objects:

- `code/82_build_central_loss_stacked_spec.py`
- `data/processed/scene_networks/central_loss_stacked_event_panel.csv`
- `data/processed/scene_networks/central_loss_stacked_did_results.csv`
- `data/processed/scene_networks/central_loss_stacked_event_study_results.csv`
- `data/processed/scene_networks/figures/central_loss_stacked_event_study.png`
- `data/processed/scene_networks/central_loss_stacked_spec_summary.md`

This specification keeps the same `9` usable post-emergence deaths, stacks them against the
matched same-genre control cities, and estimates:

- a parsimonious treated-by-post fixed-effects DID
- a short event-study for focal same-genre band starts with `t-1` as the reference year

The useful read from that prototype is:

- the focal same-genre entry margin stays negative in the stacked FE design:
  - event-weighted treated-by-post coefficient: `-0.932`
  - unique-shock treated-by-post coefficient: `-0.993`
- the duplicate `Warsaw x death_metal x 2013` shock-year therefore does **not** drive the result
- the event-study path is consistent with an immediate event-year dip rather than a long smooth
  collapse:
  - `t-3 = -0.370`
  - `t-2 = -1.000`
  - `t = -2.333`
  - `t+1 = -0.444`
- the same stacked FE design is weaker on other margins:
  - focal multi-band depth is positive, not negative
  - city-wide spawning flow is also positive, not negative

So the branch is now past pure audit mode. It has a real, if still small-sample, estimation
prototype. The narrowest live interpretation is now:

- central local deaths may reduce **focal same-genre band starts**
- they do **not** currently look like a broad negative shock to overall city spawning or to local
  scene stock
