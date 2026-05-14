# NIMBY Compiled Sidecar

This folder is the standalone compiled solver workspace for the NIMBY
`extensions/re_no_politics` branch.

## Current scope

- The first compiled target is the reduced-form rational-expectations solver
  in `../solve_reduced_form_price_path.m`.
- The second compiled target is the expensive structural `run_transition_pass`
  object inside `../solve_transition_re_no_politics.m`, currently in the
  default `full_backward` mode on bounded diagnostic packs.
- The third compiled target is a bounded standalone outer RE loop for the same
  no-politics transition object on exported fixed-terminal packs.
- The fourth compiled target is the bounded fixed-policy bridge branch
  (`transition_policy_mode = steady_state_fixed_price`) for both the
  structural transition pass and the bounded outer RE loop.
- The fifth compiled target is a standalone steady-state reference solver
  that the sidecar can use to build policy/value objects on demand at
  changing prices.
- The sixth compiled target is the solver-side diagnostic payload used by the
  bounded RE workflows, including nested `selection_diagnostics` and the
  optional `density_by_period_age` forward-simulation detail.
- The sidecar now also covers the first full-political Bellman inner object on
  a fixed guessed price path:
  the structural `transition_pass` can compute the perturbed-price Bellman
  branch, build `sign(V^{dp} - V)`, and aggregate equal-weight or
  coalition-weighted vote paths in compiled C++.
- The sidecar now also has a first compiled outer political wrapper on top of
  that political inner object:
  it iterates on the equal-weight vote path, supports
  `price_update_mode = political_only`, and supports both
  `political_update_rule = fixed_step` and `diagonal_secant` in log space.
- The exporter can now also write frontier-style bounded RE packs for the
  blended by-period policy-reference branch, including fertility-style outer
  iteration settings and explicit warm-start price paths.
- The sidecar also now has a compiled retry-aware CLI for frontier-style
  bounded RE packs, using the same two-attempt classification rule as the
  MATLAB alpha-frontier workflow.
- The sidecar now also has a compiled frontier runner for those packs:
  it can scan a supplied `alpha` grid across horizons `k`, reuse the same
  warm-start ladder logic as the MATLAB frontier workflow, and write
  frontier-summary CSVs plus per-case attempt folders.
- That frontier runner now also supports resume from its own live/final CSV
  outputs, so long scans do not need to restart from `k = 1`.
- The sidecar now also has a bounded 12-hour away-workflow driver:
  `run_transition_re_12h_workflow.ps1`
  - exports a full-horizon frontier base pack if needed
  - runs a coarse compiled frontier scan to `k = 9`
  - runs a refined edge scan around the current `0.18` branch
  - reruns the known `k = 4` and `k = 5` edge packs under `50 + 50`
  - writes a live log, manifest CSV, and Markdown handoff summary
- The sidecar also now has a narrower full-horizon bracket workflow:
  `run_transition_re_full_horizon_away_workflow.ps1`
  - resumes from compact state under `truth/tr_full_horizon_away_live/`
  - probes only the current full-horizon midpoint bracket
  - keeps the best stable `k = 8` and `k = 9` price paths
  - has already closed the live bracket below the default `1e-6` target width
- The sidecar now also has a compiled multi-case diagnostic runner:
  `nimby_transition_re_case_sweep_cli.exe`
  - reads a case-spec CSV with per-case start paths and iteration budgets
  - writes compact summary and path tables
  - supports per-case input packs when frontier-style diagnostics need the
    embedded transition-pass `price_path` to change with the warm start
- That same case-sweep layer now also covers the old `k = 4` restart-check
  packets at `alpha = 0.15` and `0.20`, not just the earlier `alpha = 0.14`
  warm-start packet.
- Workflow note: the restart-check validators should be run sequentially, not
  in parallel, because the MATLAB export path still reuses the same local
  steady-state scratch file.
- The transition-RE CLI now also writes per-iteration current, implied, and
  selected price-path traces for outer-loop debugging.
- MATLAB remains the truth implementation.
- The sidecar reads an exported input pack, solves the reduced-form RE path in
  compiled C++, and writes side-by-side outputs for comparison.

## Layout

- `src/`: compiled solver and CLI entry point
- `include/`: public headers
- `matlab/`: exporter that writes input packs and MATLAB truth outputs
- `truth/`: generated input packs and side-by-side output files
- `tools/`: portable toolchain helper

## Quick start

Canonical entry point:

- `.\run_compiled_sidecar.ps1`
  - default mode `bounded_re` runs the bounded outer-RE validation object
  - `-Mode retryaware_edge` runs the local retry-aware knife-edge wrapper
  - `-Mode warm_start_k4` runs the old `alpha = 0.14`, `k = 4` warm-start diagnostic
  - `-Mode restart_checks_k4 -Alpha 0.15` runs the old `alpha = 0.15`, `k = 4` restart checks
  - `-Mode restart_checks_k4 -Alpha 0.20` runs the old `alpha = 0.20`, `k = 4` restart checks
  - `-Mode full_horizon_live` resumes the live full-horizon bracket workflow

1. Run `.\bootstrap_portable_toolchain.ps1` once.
2. Export a pack from MATLAB:
   - `.\export_reduced_form_input.ps1 -PackName reduced_form_one_step -K 1`
3. Build the CLI:
   - `.\build.ps1`
4. Run the compiled solver:
   - `.\run_reduced_form_cli.ps1 -PackName reduced_form_one_step`

Structural transition-pass path:

1. Export a bounded truth pack:
   - `.\export_transition_pass_input.ps1 -PackName transition_pass_t4_diag -Horizon 4 -PriceLevel 2.0`
   - optional fixed-policy bridge pack:
     - `.\export_transition_pass_input.ps1 -PackName transition_pass_t4_fixed_policy_2_0 -TransitionPolicyMode steady_state_fixed_price -PolicyReferencePrice 2.0`
   - optional political diagnostic pack:
     - `.\export_transition_pass_input.ps1 -PackName transition_pass_t4_political_diag -Horizon 4 -PriceLevel 2.0 -ComputePoliticalPath`
2. Run the compiled structural pass:
   - `.\run_transition_pass_cli.ps1 -PackName transition_pass_t4_diag`
3. Validate against MATLAB truth:
   - `.\validate_transition_pass.ps1 -PackName transition_pass_t4_diag`

Standalone steady-state reference path:

1. Export a steady-state truth pack:
   - `.\export_steady_state_input.ps1 -PackName steady_state_p2_rb0_03 -PriceLevel 2.0 -RbPos 0.03`
2. Run the compiled steady-state solver:
   - `.\run_steady_state_cli.ps1 -PackName steady_state_p2_rb0_03`
3. Validate against MATLAB truth:
   - `.\validate_steady_state.ps1 -PackName steady_state_p2_rb0_03`

Compiled steady-state price-sweep path:

1. Export the anchor steady-state pack once:
   - `.\export_steady_state_input.ps1 -PackName steady_state_p2_rb0_03 -PriceLevel 2.0 -RbPos 0.03`
2. Run the compiled price sweep around that anchor:
   - `.\run_steady_state_sweep_cli.ps1 -PackName steady_state_p2_rb0_03 -PriceMin 1.8 -PriceMax 2.2 -PriceCount 30`
3. Read the outputs under `truth\<pack>_steady_state_sweep\`:
   - `sidecar_steady_state_sweep.csv` for the full price grid
   - `sidecar_best_summary.csv` for the best grid point
   - `best\` for the Bellman/value/policy/density payload at that best price

House-price compiled supervisor:

1. Start the hidden watcher:
   - `.\start_house_price_compiled_supervisor.ps1`
2. Let it watch the compiled-sidecar source tree and rerun the bounded validation packet on changes.
3. Check live state under:
   - `truth\house_price_compiled_supervisor_live\watcher_log.txt`
   - `truth\house_price_compiled_supervisor_live\watcher_state.json`
   - `truth\house_price_compiled_supervisor_live\latest_run.txt`
4. Stop it cleanly:
   - `.\stop_house_price_compiled_supervisor.ps1`

Political Bellman compiled supervisor:

1. Start the hidden watcher:
   - `.\start_political_bellman_compiled_supervisor.ps1`
2. Let it run the compiled political wrapper on the bounded `T = 4` fixed-step
   smoke pack and the `T = 9` diagonal-secant smoke pack.
3. Check live state under:
   - `truth\political_bellman_compiled_supervisor_live\watcher_log.txt`
   - `truth\political_bellman_compiled_supervisor_live\watcher_state.json`
   - `truth\political_bellman_compiled_supervisor_live\latest_run.txt`
4. Stop it cleanly:
   - `.\stop_political_bellman_compiled_supervisor.ps1`

Bounded outer RE path:

1. Export the bounded fixed-terminal pack:
   - `.\export_transition_re_input.ps1 -PackName transition_re_t4_fixed_terminal`
   - optional fixed-policy bridge pack:
     - `.\export_transition_re_input.ps1 -PackName transition_re_t4_fixed_terminal_fixed_policy_2_0 -TransitionPolicyMode steady_state_fixed_price -PolicyReferencePrice 2.0`
   - optional broader candidate-selection packs:
     - `.\export_transition_re_input.ps1 -PackName transition_re_t4_fixed_terminal_focus -CandidateSelectionMode focus`
     - `.\export_transition_re_input.ps1 -PackName transition_re_t4_fixed_terminal_hybrid_focus -CandidateSelectionMode hybrid_focus`
   - optional frontier-style debug pack:
     - `.\export_transition_re_input.ps1 -PackName transition_re_k3_frontier_alpha_0_190899658203125 -Horizon 3 -TransitionPolicyMode steady_state_by_period_price -PolicyReferencePrice 2.0 -TerminalReferenceMode fixed_price -TerminalReferencePrice 2.0 -PolicyReferenceMode blended_current_and_fixed_price -PolicyReferenceBlendWeight 0.190899658203125 -SolverProfile frontier_fertility_style -InitialPricePathCsv <warm_start_csv>`
   - optional input-only frontier pack for direct sidecar retry-aware checks:
     - `.\export_transition_re_input_only.ps1 -PackName transition_re_k4_frontier_alpha_0_190899658203125_input_only -Horizon 4 -TransitionPolicyMode steady_state_by_period_price -PolicyReferencePrice 2.0 -TerminalReferenceMode fixed_price -TerminalReferencePrice 2.0 -PolicyReferenceMode blended_current_and_fixed_price -PolicyReferenceBlendWeight 0.190899658203125 -SolverProfile frontier_fertility_style -InitialPricePathCsv <warm_start_csv>`
2. Run the standalone bounded outer RE solver:
   - `.\run_transition_re_cli.ps1 -PackName transition_re_t4_fixed_terminal`
   - canonical wrapper:
     - `.\run_compiled_sidecar.ps1`
    - optional retry-aware frontier wrapper:
    - `.\run_transition_re_retryaware.ps1 -PackName transition_re_k4_frontier_alpha_0_190899658203125_input_only`
    - canonical wrapper:
      - `.\run_compiled_sidecar.ps1 -Mode retryaware_edge`
   - optional longer-budget robustness rerun through the same compiled path:
     - `.\run_transition_re_retryaware.ps1 -PackName transition_re_k4_frontier_alpha_0_190899658203125_input_only -PerAttemptMaxIter 50`
    - optional compiled warm-start diagnostic for the old `alpha = 0.14`, `k = 4`
      restart check:
      - `.\run_transition_re_policy_bridge_k4_warm_start_sidecar.ps1`
      - `.\run_compiled_sidecar.ps1 -Mode warm_start_k4`
    - optional compiled restart-check wrappers for the old `alpha = 0.15` and
      `0.20`, `k = 4` packets:
      - `.\run_transition_re_policy_bridge_k4_restart_checks_sidecar.ps1 -Alpha 0.15`
      - `.\run_transition_re_policy_bridge_k4_restart_checks_sidecar.ps1 -Alpha 0.20`
      - `.\run_compiled_sidecar.ps1 -Mode restart_checks_k4 -Alpha 0.15`
      - `.\run_compiled_sidecar.ps1 -Mode restart_checks_k4 -Alpha 0.20`
   - optional compiled frontier scan from one exported base pack:
     - `.\run_transition_re_frontier_cli.ps1 -PackName transition_re_frontier_base_k6_anchor_input_only -MaxK 4 -AlphaGrid 0.20 -AnchorPathCsv .\truth\frontier_anchor_fixed_price_2_0_k6.csv -AnchorSource transition_re_k_step_policy_bridge_steady_state_fixed_price_2_0_results.final_price_path`
   - optional resume on an existing frontier output directory:
     - `.\run_transition_re_frontier_cli.ps1 -PackName transition_re_frontier_base_k6_anchor_input_only -OutputDir .\truth\transition_re_frontier_single_0_20_k4_sidecar_v2 -MaxK 6 -AlphaGrid 0.20 -AnchorPathCsv .\truth\frontier_anchor_fixed_price_2_0_k6.csv -AnchorSource transition_re_k_step_policy_bridge_steady_state_fixed_price_2_0_results.final_price_path -Resume`
   - optional 12-hour away workflow:
     - `.\run_transition_re_12h_workflow.ps1`
3. Validate against MATLAB truth:
   - `.\validate_transition_re.ps1 -PackName transition_re_t4_fixed_terminal -RunCli`
   - optional warm-start diagnostic validator:
     - `.\validate_transition_re_policy_bridge_k4_warm_start_sidecar.ps1 -RunCli`
   - optional restart-check validators:
     - `.\validate_transition_re_policy_bridge_k4_restart_checks_sidecar.ps1 -Alpha 0.15 -RunCli`
     - `.\validate_transition_re_policy_bridge_k4_restart_checks_sidecar.ps1 -Alpha 0.20 -RunCli`
   - optional frontier-summary validator on overlapping rows:
     - `.\validate_transition_re_frontier.ps1 -SidecarSummaryPath .\truth\transition_re_frontier_single_0_20_k4_sidecar_v2\sidecar_frontier_summary.csv -MatlabSummaryPath ..\transition_re_policy_bridge_alpha_frontier_single_0_20_k4_retryaware_sidecar_check_summary_live.csv -MaxK 3`

The input pack will contain:

- `operator_path.csv`
- `operator_scalars.csv`
- `params_scalars.csv`
- `initial_guess.csv`
- `matlab_solution_path.csv`
- `matlab_summary.csv`
- `matlab_iteration_log.csv`

The compiled CLI writes:

- `sidecar_solution_path.csv`
- `sidecar_summary.csv`
- `sidecar_iteration_log.csv`

## Validation rule

For any exported pack, the compiled outputs should match the MATLAB outputs
for:

- `final_price`
- `implied_price`
- `implied_price_unbounded`
- `next_price_reference`
- convergence status and max-gap diagnostics

## Next target

The next target is no longer the local `k = 4` and `k = 5` retry-aware
knife-edge checks. Those now match. The live long-run target is the
full-horizon compiled continuation:

- keep using MATLAB as the reference/export harness for structural truth
- use the compiled sidecar as the runtime engine for the higher-horizon
  retry-aware branch
- treat the current full-horizon bracket
  `0.18083671212196353 / 0.18083722352981568` as the live compiled reference
- rerun `workflow_transition_re_full_horizon_away.md` only if a tighter or
  robustness-focused bracket is needed
- use `workflow_transition_re_full_horizon_away.md` and
  `run_transition_re_full_horizon_away_workflow.ps1` for bounded 12-hour
  continuation, resume, and compact artifact handling under disk pressure

## Current read

- `validate_transition_pass.ps1` still matches MATLAB on the bounded structural
  `transition_pass_t4_diag` pack:
  - exact policy indices
  - aggregate-path differences at floating-point noise
  - value-function max difference about `7.15e-06`
- The compiled transition-pass layer now also matches MATLAB on the new
  political diagnostic packs:
  - `transition_pass_t4_political_diag`
  - `transition_pass_t9_political_diag`
  - exact policy indices
  - value-function max difference about `5.25e-06`
  - vote/share path differences at floating-point noise
  - `density_by_period_age` differences at floating-point noise
- OpenMP is now enabled in the portable LLVM-MinGW build by default.
- The standalone steady-state reference solver now matches MATLAB on
  `steady_state_p2_rb0_03`:
  - exact policy indices
  - value-function max difference about `5.25e-06`
  - density differences at floating-point noise
- Measured compiled structural-pass time on `transition_pass_t4_diag` is now
  about `5.10s`, down from about `25.52s` before the OpenMP speed pass.
- The fixed-policy bridge transition-pass pack
  `transition_pass_t4_fixed_policy_2_0` now also matches MATLAB:
  - exact policy indices
  - value-function max difference about `1.19e-07`
  - bounded compiled runtime about `1.65s`
- The bounded standalone outer RE CLI on
  `transition_re_t4_fixed_terminal` now finishes in about `49.7s`.
- `validate_transition_re.ps1` now passes on the bounded fixed-terminal packs:
  - final price path matches MATLAB to floating-point noise
  - implied price path matches MATLAB to floating-point noise
  - iteration log labels match exactly
  - summary max-gap / residual differences are around `1e-15`
- The bounded candidate-selection modes are now exported through
  `re_params_strings.csv` and matched in the compiled solver:
  - `transition_re_t4_fixed_terminal`
  - `transition_re_t4_fixed_terminal_focus`
  - `transition_re_t4_fixed_terminal_hybrid_focus`
- The bounded fixed-policy bridge outer-RE pack now also matches MATLAB:
  - pack: `transition_re_t4_fixed_terminal_fixed_policy_2_0`
  - final max gap about `0.070564`
  - final residual norm about `0.044122`
  - bounded compiled runtime about `0.76s`
- The sidecar now also matches MATLAB on the dynamic reference branches that
  previously required repeated MATLAB steady-state calls:
  - `transition_re_t4_fixed_terminal_by_period_policy`
  - `transition_re_t4_path_end_terminal`
  - `transition_re_t4_blended_policy_band`
- The transition-pass layer also matches MATLAB on the frontier-style blended
  by-period policy branch:
  - pack: `transition_pass_k3_frontier_iter1`
  - exact policy indices
  - value-function max difference about `5.25e-06`
  - implied-price differences at floating-point noise
- A stale frontier mismatch was traced to the exporter, not the compiled outer
  RE core:
  - earlier frontier packs embedded `price_path.csv` at the scalar
    `PriceLevel` even when `re_initial_price_path.csv` was a non-constant warm
    start, so the sidecar outer loop began from a transition-pass input with
    the wrong initial density / supply normalization
  - the exporter now passes the explicit warm-start path through to the
    embedded transition-pass pack
- Fresh frontier-style one-shot packs now validate on the blended fertility
  profile:
  - pack: `transition_re_k3_frontier_alpha_0_190899658203125_fresh`
  - final price path matches MATLAB exactly
  - implied price path differences are at floating-point noise
  - final max-gap and residual differences are about `1e-15`
  - iteration log labels and per-iteration updates match exactly
- Frontier base-pack rule:
  - when the sidecar is used for broader frontier scans, the exported
    input-only base pack must be built with the same warm-start path that the
    frontier runner will treat as its anchor
  - using a flat `2.0` embedded `price_path.csv` while the runner uses a
    fixed-price benchmark anchor path changes the one-step and short-horizon
    frontier rows, even if the outer RE loop itself is unchanged
- The sidecar retry-aware wrapper now also matches MATLAB on the local
  `k = 4` frontier knife-edge:
  - stable pack:
    `transition_re_k4_frontier_alpha_0_190899658203125_input_only`
  - sidecar status: `ok_after_retry`
  - sidecar final max gap: about `0.031897826461325`
  - MATLAB status:
    `transition_re_policy_bridge_alpha_frontier_single_0_190899658203125_k4_retryaware_summary.csv`
    row `k = 4`: `ok_after_retry`
  - unstable pack:
    `transition_re_k4_frontier_alpha_0_19090576171875_input_only`
  - sidecar status: `ok_retry_failed`
  - sidecar final max gap: about `0.794702946857174`
  - MATLAB status:
    `transition_re_policy_bridge_alpha_frontier_single_0_19090576171875_k4_retryaware_summary.csv`
    row `k = 4`: `ok_retry_failed`
- Practical rule after this fix:
  - the compiled outer RE core is now suitable for fresh one-shot
    frontier-style packs and local retry-aware edge checks
  - MATLAB should still remain the reference workflow for the broader
    retry-aware alpha-frontier scans until higher-horizon packs are validated
    the same way
- The retry-aware wrapper is now itself compiled:
  - executable: `build/nimby_transition_re_retryaware_cli.exe`
  - wrapper: `run_transition_re_retryaware.ps1`
  - default-budget local `k = 4` edge packs still reproduce the expected
    statuses exactly:
    - `transition_re_k4_frontier_alpha_0_190899658203125_input_only`:
      `ok_after_retry`, final max gap about `0.031897826461325`
    - `transition_re_k4_frontier_alpha_0_19090576171875_input_only`:
      `ok_retry_failed`, final max gap about `0.794702946857174`
  - the same compiled path also reproduces the longer-budget robustness read:
    - stable-side pack with `-PerAttemptMaxIter 50`:
      `ok` on attempt `1`, same final max gap about `0.031897826461325`
    - unstable-side pack with `-PerAttemptMaxIter 50`:
      `ok_retry_failed`, final max gap about `0.261580942721814`
- The old `alpha = 0.14`, `k = 4` warm-start diagnostic is now compiled too:
  - runner:
    `run_transition_re_policy_bridge_k4_warm_start_sidecar.ps1`
  - validator:
    `validate_transition_re_policy_bridge_k4_warm_start_sidecar.ps1`
  - the sidecar summary and path tables match the old MATLAB diagnostic CSVs
    to floating-point noise:
    - summary max numeric diff about `7.55e-15`
    - path max numeric diff about `7.55e-15`
    - zero string mismatches
- The compiled sidecar now also has a reusable away-workflow wrapper for
  longer unattended sessions:
  - script: `run_transition_re_12h_workflow.ps1`
  - default chain:
    - export `transition_re_frontier_base_k9_anchor_input_only`
    - run a coarse `k <= 9` frontier on
      `{0.18, 0.180009765625, 0.180078125, 0.180625, 0.18125, 0.1825, 0.185, 0.19, 0.2}`
    - run a refined edge frontier on
      `{0.18, 0.180009765625, 0.18001953125, 0.1800390625, 0.180078125, 0.18015625, 0.1803125, 0.180625, 0.18125}`
    - rerun the known `k = 4` and `k = 5` edge packs under `50 + 50`
  - outputs:
    `truth/away_12h_workflow/workflow_log.txt`,
    `workflow_manifest.csv`,
    `workflow_summary.md`
  - smoke test:
    `run_transition_re_12h_workflow.ps1 -DurationHours 1 -WorkflowName away_12h_workflow_smoke3 -MaxTasks 1 -SkipBuild`
    completed cleanly and wrote the expected handoff files
- First compiled frontier-runner validation:
  - base pack:
    `transition_re_frontier_base_k6_anchor_input_only`
  - compiled frontier output:
    `truth/transition_re_frontier_single_0_20_k4_sidecar_v2/sidecar_frontier_summary.csv`
  - current MATLAB retry-aware reference:
    `../transition_re_policy_bridge_alpha_frontier_single_0_20_k4_retryaware_sidecar_check_summary_live.csv`
  - completed rows `k = 1..3` match to floating-point noise on:
    final prices, gap/residual diagnostics, policy-reference prices, and
    warm-start labels
  - the MATLAB `k = 4` reference run did not finish in-session here, so the
    broader frontier-runner parity claim is not yet closed above those
    completed rows
- Frontier resume smoke test:
  - seeded partial output:
    `truth/transition_re_frontier_single_0_20_k4_resume_smoke`
  - resumed with `-Resume` from saved `k = 1..2` live files
  - reproduced the full `k = 1..4` sidecar frontier summary exactly
- Completed compiled retry-aware `alpha = 0.20` continuation:
  - resumed the compiled frontier run from `k = 4` out to `k = 6`
  - output:
    `truth/transition_re_frontier_single_0_20_k4_sidecar_v2/sidecar_frontier_summary.csv`
  - current compiled retry-aware read:
    - stable through `k = 3`
    - `k = 4`: `ok_retry_failed`, max gap about `0.02814`, but price path hits the lower bound `0.4`
    - `k = 5`: `ok_retry_failed`, max gap about `65.41739`
    - `k = 6`: `ok_retry_failed`, max gap about `65.41739`
  - comparison rule:
    - the older MATLAB `transition_re_policy_bridge_alpha_frontier_single_0_20_k6_summary.csv`
      is a one-pass packet and is still useful as a coarse unstable-region
      reference
    - it is not the exact parity target for the new retry-aware compiled
      frontier runner once the second-attempt logic matters
- The sidecar retry-aware wrapper also matches MATLAB on the local
  `k = 5` frontier knife-edge:
  - stable pack:
    `transition_re_k5_frontier_alpha_0_185_input_only`
  - sidecar status: `ok_after_retry`
  - sidecar final max gap: about `0.00375549054146518`
  - MATLAB status:
    `transition_re_policy_bridge_alpha_frontier_single_0_185_k5_retryaware_summary.csv`
    row `k = 5`: `ok_after_retry`
  - unstable pack:
    `transition_re_k5_frontier_alpha_0_185625_input_only`
  - sidecar status: `ok_retry_failed`
  - sidecar final max gap: about `0.334707558145002`
  - MATLAB status:
    `transition_re_policy_bridge_alpha_frontier_single_0_185625_k5_retryaware_summary.csv`
    row `k = 5`: `ok_retry_failed`
- First compiled-only `k = 6` retry-aware probe was conservative:
  - the initial frontier-style packs seeded from the `k = 5` frontier path
    gave a local bracket of `[0.18, 0.180009765625]`
  - that was not the end of the story, because the boundary is warm-start
    sensitive
- Same-`k` compiled continuation at `k = 6`:
  - starting from the solved `k = 6`, `alpha = 0.18` path, the sidecar also
    stabilizes:
    - `0.180009765625`
    - `0.180078125`
    - `0.1803125`
    - `0.18140625`
  - but `0.181953125` is unstable after retry
  - current compiled same-`k` `k = 6` bracket:
    `[0.18140625, 0.181953125]`
- Higher-horizon compiled continuation from the rescued branch:
  - stable full-horizon continuation:
    - `alpha = 0.1807080078125` is stable through `k = 8` and `k = 9`
    - `alpha = 0.1807952880859375` is stable through `k = 8` and `k = 9`
    - `alpha = 0.18082801818847656` is stable through `k = 8` and `k = 9`
    - `alpha = 0.18083620071411133` is stable at `k = 8` and `k = 9`
    - `alpha = 0.18083671212196353` is stable at `k = 8` and `k = 9`
  - unstable full-horizon continuation:
    - `alpha = 0.18140625` is stable at `k = 7` but fails at `k = 8`
    - `alpha = 0.18105712890625`, `0.18092620849609375`,
      `0.180882568359375`, `0.180860748291015625`, and
      `0.18084438323974609` all fail at `k = 8`
    - `alpha = 0.1808402919769287` also fails at `k = 8`
    - `alpha = 0.18083824634552` also fails at `k = 8`
    - `alpha = 0.18083722352981568` also fails at `k = 8`
  - current compiled full-horizon bracket:
    stable at `0.18083671212196353`, unstable at `0.18083722352981568`
  - practical read from the compiled continuation:
    - the naive `0.18` ceiling was a warm-start artifact
    - same-`k` continuation materially enlarges the admissible region
    - under the current retry-aware compiled workflow, the practical
      full-horizon ceiling is now around `0.18084`, not `0.18`
- Added a bounded away-workflow runner for that full-horizon continuation:
  - note: `workflow_transition_re_full_horizon_away.md`
  - entry point: `run_transition_re_full_horizon_away_workflow.ps1`
  - current default packet:
    - resumeable state and handoff files under
      `truth/tr_full_horizon_away_live/`
    - compact per-probe artifacts only
    - explicit disk guard on `C:`
    - stable-path carry-forward for both `k = 8` and `k = 9`
  - current live result:
    - reached the target bracket width after two additional probes
    - current live bracket:
      `[0.18083671212196353, 0.18083722352981568]`
    - current live width:
      `5.1140785217729245e-07`
- The bounded outer RE solver now also matches MATLAB on the workflow-used
  diagnostic payloads:
  - pack: `transition_re_t4_fixed_terminal_history`
  - nested selection diagnostics exported as normalized CSV tables
  - selection-iteration, pass, and candidate rows all match to floating-point
    noise with zero string mismatches
- The optional forward-simulation density payload is now compiled too:
  - transition-pass pack: `transition_pass_t4_diag_period_details`
  - outer-RE pack: `transition_re_t4_fixed_terminal_full_details`
  - `density_by_period_age` matches MATLAB to floating-point noise
