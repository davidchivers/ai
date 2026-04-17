# 29 Breakout branch parking memo

Last updated: 2026-04-09
Status: branch decision lock after the final bounded recovery pass

## Decision

Park the breakout-demand branch at feasibility stage.

Do not move to event-study estimation under the current treatment build.

## Why the branch is being parked

The branch still fails its own descriptive gate even after the latest source upgrades.

The current best relaxed stack remains:

- `9` retained first-breakout events
- `153` positive-capability city-event cells at `t = -1`
- `11,438` zero-capability city-event cells at `t = -1`
- pre-period same-genre starts:
  - positive capability: `0.1176`
  - zero capability: `0.0015`
- post-period same-genre starts:
  - positive capability: `0.0730`
  - zero capability: `0.0024`
- dominant event:
  - `deu_power_metal_2012_carolus_rex` with `39` positive-capability cities

That is still too thin and too imbalanced to justify a stacked event study.

## What the final recovery pass changed

The branch is cleaner than before, but not better enough.

### Brazil

- `Angra - Rebirth`
  - now has observed certification timing:
    - Whiplash reports the gold award being delivered during the Sao Paulo show on `2001-12-15`
    - article publication date: `2001-12-17`
  - official Aquiles Priester press bios corroborate the gold certification
  - still not a chart-entry event

- `Angra - Temple of Shadows`
  - now has an archived `Epoca` weekly chart page
  - publication date: `2005-11-17`
  - chart period: `2005-11-08` to `2005-11-15`
  - rank: `10`
  - still not a direct official chart-entry archive comparable to the European sources

### Italy

- `Lacuna Coil - Comalies`
  - the official FIMI search environment still returns only the generic title-history page
  - no recoverable chart table or certification object has been found in the live official source
  - so `Comalies` remains a real official dead end under the current workflow

## Practical implication

The recovery work improved the broader `country x year` treatment file more than it improved the
stacked breakout-event branch.

That means:

- keep the main paper focused on the scene-emergence reduced-form result
- keep the breakout branch as a documented follow-on feasibility object
- stop spending active workflow time on event-study estimation for this branch

## Re-entry rule

Only reopen the breakout branch if at least one of the following becomes true:

1. an official or archive-clean chart-entry date is recovered for `Comalies`, `Rebirth`, or
   `Temple of Shadows`
2. at least `3` additional first-breakout events with non-flat pre-shock capability are added to
   the retained stack
3. the design is changed away from the current stacked first-breakout event-study requirement

If none of those happen, the branch should remain parked.

## Working interpretation

The branch succeeded as a feasibility audit, not as a regression-ready causal design.

That is a useful outcome:

- it clarified what the current treatment build can support
- it cleaned several important home-market rows
- it reduced the risk of drifting into a weak quasi-causal side project
