# Old/Young Proxy Diagnostic

This branch is a diagnostic, not a replacement paper specification.

## Purpose

Test whether the full rational-expectations transition becomes easier to move
when demographic variation is collapsed from the full age-profile path to two
broad blocks:

- `young`: ages `25-50`
- `old`: ages `55+`

Within each block, baseline within-group age composition is held fixed. Only
the total mass of the two blocks moves over time.

## Why this branch exists

The question is whether the main RE difficulty is:

- the solver class itself, or
- the high-dimensional age-distribution object feeding the transition/political
  block.

If the two-group proxy starts admitting movement where the full historical age
path does not, that is evidence that the detailed age structure is part of the
numerical bottleneck.

If it still sticks at the same incumbent, that points back toward the outer RE
solver architecture rather than the demographic richness.

## Entry points

- Local reduced-path Jacobian / Dynare runners:
  use `DemographicSourceMode = historical_1950_two_group`
- Hamilton convenience launcher:
  `submit_original_5yr_hamilton_old_young_proxy_packet.ps1`

## Interpretation rule

Treat this branch as a diagnostic model object. Do not silently replace the
paper baseline with it. Use it to learn whether the age-distribution dimension
is part of the fixed-point difficulty.
