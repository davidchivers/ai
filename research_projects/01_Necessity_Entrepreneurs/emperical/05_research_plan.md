# Research plan

## Chosen research question and estimand

The best empirical question is not "Which entrepreneurs are necessity entrepreneurs in a full
binary sense?" The cleaner question is:

How much does an exogenous deterioration in wage-work outside options raise low-scale
nonemployer entry relative to employer entry?

The main estimands should be:

- the effect on nonemployer entry,
- the effect on employer entry,
- the difference between those two responses,
- conditional-on-entry effects on initial payroll, initial employment, and early survival.

This is the closest empirical analogue to the paper's formal distinction.

## Top design choices with rationale

Top choice 1 is the displacement-based worker-to-business design. It is the best match to the
model because it shifts the outside option at the worker level and lets us follow entry type and
early scale. If the data are good enough, this is the cleanest design in the folder.

Top choice 2 is the local labor-demand public-data design. It is weaker at the individual level,
but it is much more feasible and fits the sidecar work already done on business counts, business
applications, and self-employment companions. It is the right fallback if restricted linked data
are unrealistic in the near term.

The UI-policy design is worth keeping as a robustness or extension, but it should not be the
first empirical pillar unless a particularly sharp policy discontinuity becomes available.

## Data access decision and fallback

Preferred data path:
restricted worker-business linked records that separate nonemployer and employer entry and allow
early payroll and survival outcomes.

Fallback path:
public local-area panels combining business applications, high-propensity application shares,
nonemployer versus employer business counts, and CPS transition or self-employment objects.

Current local starting point:
the repository already contains national public-series scaffolding for the fallback path in
`data/us_business_counts_by_size_annual.csv`, `data/us_business_applications_annual.csv`,
`data/us_self_employment_rates_annual.csv`, and the GEM sidecar files. So the fallback path
is not hypothetical; it is already partly built.

What we should not do as the main design:
use GEM motives alone, or use a single broad self-employment series as if it identified the
structural object.

We also should not define opportunity entrepreneurship mechanically as "starts larger" or
"starts with more capital." Those are useful outcomes, but even opportunity firms can start
small and some opportunity entrepreneurs can remain self-employed.

## Decision log

Rejected as the headline design:

- GEM-only motive evidence, because it proves overlap rather than delivering clean classification.
- Broad self-employment counts alone, because they collapse own-account and employer margins.
- Prior status at entry as a standalone classifier, because it is informative but still endogenous.
- Initial size or startup capital as a standalone classifier, because both necessity and
  opportunity entrepreneurs can begin at small scale.

Retained:

- outside-option shock designs,
- separate nonemployer and employer outcomes,
- post-entry scale and payroll outcomes.

## Next 3 tasks

- Dave: decide whether the near-term empirical route is restricted linked microdata or the public-
  data fallback, because the note pack is now developed enough to narrow the project.
- Codex: if the public-data fallback is chosen, sketch the actual panel build around local labor-
  demand shocks, business applications, and nonemployer versus employer outcomes.
- Dave and Codex: if the linked-data route is chosen, write the exact data request or wish list
  needed to observe worker status, business start type, first payroll, and early survival.
