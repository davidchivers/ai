# Research plan

Last updated: 2026-03-13
Status: preferred empirical route locked to the displacement-based worker-to-business design;
next deliverables are the FSRDC scoping memo and fallback data wish list

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

Current design decision:
proceed with option 1, the displacement-based worker-to-business design, as the preferred
empirical route.

Preferred data path:
a Census FSRDC linked worker-business package centered on LEHD plus the startup and business
history files needed to separate nonemployer and employer entry and to follow first payroll and
early survival. The ranked shortlist is in `10_displacement_design_data_options.md`.

Backup within option 1:
if the FSRDC route is blocked, fall back to a one-state or few-state administrative linkage that
combines worker wage records with employer files and business-start records.

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

- Codex: draft the short FSRDC scoping memo that asks for the exact worker, startup-type, first-
  payroll, and survival files needed for the displacement design.
- Dave and Codex: confirm whether the preferred nonemployer-owner linkage layer is currently
  requestable through the FSRDC route, or whether the project should be framed around the stable
  LEHD plus startup-panel package first.
- Codex: write the one-state fallback wish list so the worker-level design can continue if the
  FSRDC route is blocked.
