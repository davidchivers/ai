# Transition RE follow-up report

Generated: 2026-03-22 07:23:19

## Best tuning config

- Config ID: 11
- Residual norm: 0.128123139190
- Max gap: 0.165893855901
- Accepted update: sequential_block_p2_4_6_0.01
- Worst periods: gap 3, excess demand 3
- Parameters: damping=0.15, smoothing=8, targeted=0.2, scales=[0.1 0.05 0.02 0.01]

## Block-search follow-up

- Best block-search row: fine_p3_b6
- Residual norm: 0.128095783321
- Max gap: 0.165900836585
- Persistence: last nontrivial iteration = 4; max nontrivial update count = 4
- Repeated bottleneck: worst gap period 3, worst excess-demand period 3

## Candidate-selection follow-up

- Status: completed
- Best row: aggressive_p2_b8_hybrid_relaxed
- Residual norm: 0.128074177550
- Max gap: 0.166384245139
- Persistence: last nontrivial iteration = 4, nontrivial update count = 4
- Mode: hybrid_focus; greedy = 0; residual slack = 0.0002

## Validation pack

- Status: completed
- Best validation row: best_variant_validation
- Source case: aggressive_p2_b8_hybrid_relaxed
- Residual norm: 0.128074177550
- Max gap: 0.166384245139
- Persistence: last nontrivial iteration = 4, nontrivial update count = 4

## Focus-objective follow-up

- Status: completed
- Best focus-objective row: config11_focus_relaxed
- Residual norm: 0.128660740438
- Max gap: 0.165893855901
- Persistence: last nontrivial iteration = 2, nontrivial update count = 2
- Mode: focus; focus gap tol = 5e-05; focus slack = 0.0005

## Focus-objective validation

- Status: not started or not finished yet

## Lambda continuation

- Status: completed
- Final lambda row: lambda = 1
- Residual norm: 0.128180623096
- Max gap: 0.165930860077
- Worst periods: gap 3, excess demand 3
- Warm start source: lambda_0.75_final_path

## Interpretation

- The main bottleneck is still localized rather than global: the summaries keep pointing back to period 3 and the 4-6 block region.
- The candidate-selection run is designed to test whether a different acceptance rule extends nontrivial updates beyond the current iteration-3/4 plateau.
- The validation pack is the next check after candidate selection: baseline control versus the best non-baseline candidate under a slightly longer horizon.
- The focus-objective follow-up is the next bounded test if the goal is to improve the worst-period metric rather than average residual fit.
- The focus-objective validation stage only runs if a completed focus-objective case actually beats the canonical control on max gap.
- The lambda continuation workflow is the bounded next-step if we want RE intuition without another broad tuning sweep.
- Rerun this script at any point to refresh the report in place.
