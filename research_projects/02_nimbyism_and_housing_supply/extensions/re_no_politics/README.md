# RE no-politics extension workspace

This subfolder is the implementation workspace for the no-politics rational-expectations extension described in `../re_no_politics_experiment.md`.

## Current status

- Published baseline code remains untouched.
- Extension A now has a copied steady-state solver, grid-search driver, and runnable entry point.
- Extension B now has a copied steady-state solver, coalition vote helper, grid-search driver, and runnable entry point.
- Both extension drivers are MATLAB functions so they can be called safely from the entry-point wrappers.
- The current no-politics object is a steady-state benchmark only. It is not the main experiment.
- The transition-path RE workspace now has a useful qualitative diagnostic result, but not a clean
  fully converged benchmark. The current extension goal is therefore qualitative intuition plus a
  computational-hardness explanation, not further heavy tuning of the same solver family.
- The no-politics steady-state solver and the transition-path RE solver now share one household
  Bellman layer:
  `solve_household_path_nimby.m` for value/policy solves and
  `build_stationary_cross_section_nimby.m` for the stationary cross section.
- That shared Bellman layer can now also return the old political preference object in reusable
  form:
  a price-perturbed branch plus state-level `sign(V^{dp} - V)` objects for both stationary and
  transition-path solves.
- The transition solver can now aggregate those preference signs with pre-decision densities to
  produce a time-varying political vote path, including equal-weight and coalition-weighted vote
  summaries by period.
- A bounded vote-weight sweep now also exists for that political packet. Current evidence says the
  sign conflict is robust across the tested weight grid: the political adjustment keeps pushing
  prices down while the housing-clearing map keeps pushing prices up in the middle periods.
- A bounded overnight workflow now also exists for the political RE branch. It refreshes the
  bounded political-path packet, the bounded joint price-vote packet, and the vote-weight sweep,
  snapshots the artifacts into a live run directory, and uses a hidden watcher to restart the
  child run if it dies before the milestone chain completes.
- There is now also a bounded full-political Bellman wrapper. It captures the exact current-path
  transition Bellman pass, extracts the path-level equal-weight political residual, and iterates on
  that political object directly rather than only reporting politics after a housing update.
- There is now also a fertility-style `k`-ladder for that political Bellman branch. It starts at
  `k = 1`, warm-starts longer horizons from the shorter political solution, and now reaches the
  full `T = 9` sample without crashing or hitting the price bounds under the one-iteration joint
  housing-plus-politics update.
- A separate fertility-style RE transplant branch now exists for the NIMBY transition solver.
  It is useful as a diagnostic, but the direct whole-path relaxation does not currently converge
  cleanly in this model.
- A bounded-horizon `k`-step ladder now also exists for that transplant. It starts at `k = 1` and
  warm-starts longer truncated horizons, and current evidence says the instability appears already
  at `k = 2`.
- A dedicated `k = 2` bridge workflow now also exists. Its first pass varies only the terminal
  steady-state tail, and current evidence says that tail simplification alone does not materially
  fix the `k = 2` instability.
- A dedicated policy-bridge workflow now also exists. It replaces the full backward-looking
  within-path policy map with steady-state policy rules, and current evidence says this is the
  first simplification that materially stabilizes the NIMBY RE object. In particular, a
  fixed-price policy bridge at `2.0` stays numerically well behaved across the full 2010-2018
  horizon.
- A new reduced-form-first workflow now also exists. It fits a smooth aggregate price operator on
  the stable fixed-price policy-bridge benchmark and then solves bounded one-step and finite-
  horizon RE on that smoother object. Current evidence says this branch is numerically tame through
  the full forward horizon, which is the closest NIMBY analogue yet to the fertility sequence of
  "reduced form first, then longer horizons".
- A separate compiled sidecar workspace now also exists for this reduced-form branch. It exports a
  reduced-form input pack from MATLAB and solves the same bounded RE fixed point in standalone
  C++ as a first step toward a compiled NIMBY solver.
- That sidecar now also contains a compiled bounded structural transition-pass solver for the
  default `full_backward` no-politics object. On the current `T = 4` diagnostic pack it matches
  MATLAB exactly on policy indices and to machine precision on aggregate paths.
- A new policy-bridge blend workflow now also exists. It reintroduces current-price feedback
  gradually between the fixed-price bridge and the by-period bridge. Current evidence says the
  full-horizon blend frontier is sharp, but the matched-budget `k`-ladder frontier is softer:
  shorter ladders can absorb some current-price feedback before instability returns.

## What this is and is not

- This workspace currently contains a useful side benchmark: a no-politics steady-state object with housing-clearing prices.
- It is not the main rational-expectations experiment the project now wants.
- The main target is a transition-path forecast with future demographic changes and model-consistent house-price expectations, while abstracting from coalition formation.
- In other words, the interesting object is not "new steady state under a different closure". It is "forecasting under RE house prices along a demographic transition path".

## Recommended code base

Use `../../code/steadystate/SolveSS_iter.m` as the main baseline for the first extension pass.

Why this file:

- it is already the object called by `../../code/steadystate/ClearMarkets.m`
- it returns useful diagnostics: `distance`, `a_price`, `rbPos`, `totalvote`, `debtstock`
- its terminal object is explicit: `distance = sum(dens4.*pref4,'all')^2`
- the political target is concentrated near the end of the file, which makes the eventual split cleaner

Do not start from `SolveSS.m` unless a script-style version is specifically needed for replication output.

## What the political block currently does

In `SolveSS_iter.m`, the code computes:

- the derivative of the value function with respect to prices
- a state-level sign preference over higher prices
- an age-weighted aggregate vote statistic
- a scalar `distance` that squares the aggregate vote imbalance

That means the current equilibrium object is a political fixed point in price space, not a rational-expectations housing-clearing fixed point.

## Implemented side benchmarks

### Extension A: no-politics RE steady state

- Solver: `solve_ss_no_politics.m`
- Driver: `ClearMarkets_no_politics.m`
- Runner: `run_re_no_politics_extension.m`
- Equilibrium condition: `distance = (Hdemand - Hsupply)^2`
- Supply rule: `Hsupply = Hbar * (a_price / Pbar)^eta_s`
- Output file: `SS_no_politics_iter.mat`

### Extension B: coalition-weighted voting

- Solver: `solve_ss_coalition.m`
- Driver: `ClearMarkets_coalition.m`
- Helper: `compute_coalition_vote.m`
- Runner: `run_political_coalition_extension.m`
- Equilibrium condition: `distance = stats.weighted_vote^2`
- Output file: `SS_coalition_iter.mat`

## Main experiment still to build

- Keep the baseline transition structure rather than collapsing to a new steady state.
- Feed in an exogenous demographic path.
- Replace the ad hoc house-price expectation rule with a guessed future price path.
- Solve household decisions using that full expected path.
- Simulate the cross-sectional distribution forward.
- Update the price path until it is consistent with the model's own implied future prices.
- Do this without coalition voting if the no-coalition political assumption remains the target simplification.

## Files in this workspace

- `implementation_plan.md`: concrete refactor map from published baseline to extension code
- `house_price_re_equilibrium_definition.md`: exact fixed-point definition for the current
  house-price RE target, distinguishing it from both a given-price transition pass and full
  political RE
- `transition_re_intuition_note.md`: current qualitative RE takeaway and explanation of why the
  full transition-path RE problem is computationally hard
- `workflow_re_lambda_continuation.md`: bounded coarse continuation workflow that scales the
  demographic transition with `lambda`
- `workflow_extension_away.md`: one-day workflow chaining the coarse RE continuation run into the
  benchmark-based coalition sensitivity run
- `re_extension_section/`: standalone paper-style RE extension section with generated figures and a
  compiled PDF
- `nimby_and_housing_extensions/`: combined paper-style packet
  `NIMBY and Housing Extensions: RE and Coalitions`, with a compiled PDF and coalition figure
- `coalition_extension_from_benchmark.md`: roadmap for doing the coalition extension as a clean
  perturbation of the published benchmark
- `workflow_re_intuition.md`: bounded lightweight workflow for the extension's current goal
- `run_re_no_politics_extension.m`: entry point for the no-politics extension
- `solve_household_path_nimby.m`: shared household Bellman/value-function layer used by the
  no-politics steady-state and transition RE code
- `build_stationary_cross_section_nimby.m`: builds the stationary age-by-state cross section from
  the shared constant-price household solution
- `solve_ss_no_politics.m`: copied steady-state solver with housing clearing replacing voting
- `ClearMarkets_no_politics.m`: function driver for the no-politics price grid
- `run_demographic_forecast_re_no_politics.m`: entry point for the transition-path RE scaffold
- `build_demographic_path_from_age_state_csv.m`: maps `code/data/age state.csv` into model age bins
- `scale_demographic_path_lambda.m`: scales the demographic transition path toward the 2010
  baseline for coarse continuation runs
- `run_linear_age_price_rule.m`: regression-based diagnostic that forecasts log prices as a linear
  function of the economy's mean age; it iterates the RE solver, writes summary CSVs, and saves the
  final fits and implied path
- `solve_transition_re_no_politics.m`: transition-path solver interface and diagnostics scaffold
- `update_price_path_re_no_politics.m`: damped price-path update helper for RE iteration
- `run_demographic_forecast_re_no_politics_fertility_style.m`: separate runner for the direct
  fertility-style whole-path relaxation transplant
- `run_transition_re_no_politics_k_step_ladder.m`: bounded-horizon continuation runner that starts
  at `k = 1` and extends the fertility-style transplant one period at a time
- `run_transition_re_k2_bridge_followup.m`: bounded diagnostic that compares simplified terminal
  bridge objects on the first nontrivial `k = 2` problem
- `run_transition_re_k2_policy_bridge_followup.m`: bounded diagnostic that compares simplified
  within-path policy bridges on the first nontrivial `k = 2` problem
- `run_transition_re_k_step_policy_bridge_ladder.m`: short-horizon ladder for the best
  within-path policy bridge
- `transition_re_fertility_style_note.md`: note on what the direct transplant does and why it does
  not yet solve the NIMBY RE problem cleanly
- `workflow_re_k2_bridge.md`: bounded workflow note for the `k = 2` bridge comparison
- `workflow_re_policy_bridge.md`: bounded workflow note for the within-path policy bridge branch
- `run_transition_re_k2_bridge_followup.ps1`: PowerShell wrapper for the `k = 2` bridge run
- `run_transition_re_k2_bridge_workflow.ps1`: workflow wrapper for the `k = 2` bridge run plus
  report refresh
- `write_transition_re_k2_bridge_report.ps1`: report writer for the `k = 2` bridge outputs
- `run_transition_re_k2_policy_bridge_followup.ps1`: PowerShell wrapper for the `k = 2` policy
  bridge run
- `run_transition_re_k_step_policy_bridge_ladder.ps1`: PowerShell wrapper for the short policy
  bridge ladder
- `write_transition_re_policy_bridge_report.ps1`: report writer for the policy bridge outputs
- `run_transition_re_policy_bridge_workflow.ps1`: workflow wrapper for the full policy bridge
  packet
- `run_transition_re_policy_bridge_floor_sweep.m`: full-horizon floor sweep around the by-period
  policy bridge
- `run_transition_re_policy_bridge_floor_sweep.ps1`: PowerShell wrapper for the floor sweep
- `write_transition_re_policy_bridge_floor_report.ps1`: report writer for the floor-sweep outputs
- `workflow_re_policy_bridge_floor_sweep.md`: workflow note for the anchored-expectations floor
  follow-up
- `run_transition_re_policy_bridge_band_sweep.m`: full-horizon narrow-band sweep around the
  by-period policy bridge
- `run_transition_re_policy_bridge_band_sweep.ps1`: PowerShell wrapper for the band sweep
- `write_transition_re_policy_bridge_band_report.ps1`: report writer for the band-sweep outputs
- `run_transition_re_policy_bridge_fixed_price_sweep.m`: full-horizon sweep over constant fixed
  policy-reference prices
- `run_transition_re_policy_bridge_fixed_price_sweep.ps1`: PowerShell wrapper for the fixed-price
  sweep
- `write_transition_re_policy_bridge_fixed_price_report.ps1`: report writer for the coarse
  fixed-price sweep
- `transition_re_policy_bridge_fixed_price_local_report.md`: refined local bracket for the stable
  fixed-price neighborhood
- `run_transition_re_policy_bridge_blend_sweep.m`: refined full-horizon blend sweep between the
  fixed-price policy bridge and the by-period-price bridge
- `run_transition_re_policy_bridge_blend_sweep.ps1`: PowerShell wrapper for the full-horizon blend
  sweep
- `run_transition_re_policy_bridge_blend_ladder.m`: matched-budget `k`-ladder over the same blend
  object
- `run_transition_re_policy_bridge_blend_ladder.ps1`: PowerShell wrapper for the blend ladder
- `workflow_re_policy_bridge_blend.md`: workflow note for the policy-bridge blend frontier
- `workflow_re_policy_bridge_blend_ladder.md`: workflow note for the blend ladder by horizon
- `transition_re_policy_bridge_blend_report.md`: current summary note for the blend frontier and
  ladder follow-up
- `build_reduced_form_price_operator_from_policy_bridge.m`: fits the smooth reduced-form operator
  on the stable fixed-price policy-bridge benchmark
- `solve_reduced_form_price_path.m`: bounded reduced-form RE solver on that smooth operator
- `run_transition_re_reduced_form_one_step.m`: first reduced-form rung that solves only the next
  forecasted year off the benchmark tail
- `run_transition_re_reduced_form_k_step_ladder.m`: finite-horizon reduced-form ladder over RE
  weights and horizons
- `run_transition_re_reduced_form_one_step.ps1`: PowerShell wrapper for the reduced-form one-step
  run
- `run_transition_re_reduced_form_k_step_ladder.ps1`: PowerShell wrapper for the reduced-form
  ladder run
- `run_transition_re_reduced_form_workflow.ps1`: workflow wrapper for the reduced-form packet
- `workflow_re_reduced_form.md`: workflow note for the reduced-form-first NIMBY RE branch
- `transition_re_reduced_form_report.md`: current summary note for the reduced-form-first branch
- `compiled_sidecar/`: standalone compiled solver workspace for the reduced-form RE branch
- `run_transition_re_lambda_continuation.m`: coarse lambda continuation runner for the RE extension
- `run_transition_re_lambda_continuation.ps1`: PowerShell wrapper for the lambda continuation run
- `run_transition_re_lambda_workflow.ps1`: workflow wrapper for lambda continuation plus report
  refresh
- `run_transition_re_political_path_diagnostic.m`: bounded `T = 4` transition packet that combines
  the shared Bellman preference-sign object with period-by-period political aggregation
- `run_transition_re_political_path_diagnostic.ps1`: PowerShell wrapper for the bounded political
  path packet
- `run_transition_re_political_path_workflow.ps1`: workflow wrapper for the bounded political path
  packet plus report refresh
- `write_transition_re_political_path_report.ps1`: report writer for the bounded political path
  outputs
- `workflow_re_political_path.md`: workflow note for the first bounded political-path packet
- `run_transition_re_joint_price_vote_experiment.m`: bounded joint update experiment that feeds a
  small coalition-vote adjustment back into the price path after each housing solve
- `run_transition_re_joint_price_vote_experiment.ps1`: PowerShell wrapper for the bounded joint
  price-and-vote packet
- `run_transition_re_joint_price_vote_workflow.ps1`: workflow wrapper for the bounded joint
  price-and-vote packet plus report refresh
- `write_transition_re_joint_price_vote_report.ps1`: report writer for the bounded joint
  price-and-vote outputs
- `workflow_re_joint_price_vote.md`: workflow note for the bounded joint update experiment
- `run_transition_re_joint_price_vote_weight_sweep.m`: bounded robustness sweep over the political
  update weight while holding the `T = 4` housing solve fixed
- `run_transition_re_joint_price_vote_weight_sweep.ps1`: PowerShell wrapper for the vote-weight
  sweep
- `run_transition_re_joint_price_vote_weight_sweep_workflow.ps1`: workflow wrapper for the
  vote-weight sweep plus report refresh
- `write_transition_re_joint_price_vote_weight_sweep_report.ps1`: report writer for the vote-weight
  sweep outputs
- `workflow_re_joint_price_vote_weight_sweep.md`: workflow note for the bounded vote-weight sweep
- `political_re_overnight_workflow.ps1`: bounded overnight workflow that refreshes the main
  political-path packet, the bounded joint price-vote packet, and the vote-weight sweep
- `solve_transition_political_bellman_nimby.m`: bounded political-Bellman outer wrapper that uses
  the shared transition Bellman block plus the current-path political residual as its own update
  target
- `run_transition_political_bellman_bounded.m`: bounded `T = 4` runner for that political-Bellman
  wrapper
- `run_transition_political_bellman_bounded.ps1`: PowerShell wrapper for the bounded political-
  Bellman packet
- `run_transition_political_bellman_k_step_ladder.m`: fertility-style `k = 1..T` continuation
  runner for the political Bellman branch
- `run_transition_political_bellman_k_step_ladder.ps1`: PowerShell wrapper for the political
  Bellman ladder
- `workflow_re_political_bellman_ladder.md`: workflow note for climbing the political Bellman
  branch horizon by horizon
- `watch_political_re_overnight.ps1`: hidden overseer that restarts the overnight child run if it
  exits early and stops cleanly on success, stop request, or time budget
- `start_political_re_overnight.ps1`: launcher for the overnight watcher
- `stop_political_re_overnight.ps1`: stop script for the overnight watcher and active child
- `workflow_political_re_overnight.md`: note describing the overnight packet, live state folder,
  stop rules, and non-goals
- `run_coalition_benchmark_sensitivity.m`: benchmark-based coalition sensitivity runner
- `run_coalition_benchmark_sensitivity.ps1`: PowerShell wrapper for the coalition benchmark run
- `write_coalition_benchmark_report.ps1`: report writer for coalition benchmark outputs
- `run_extension_away_workflow.ps1`: away-workflow orchestrator for the current extension packet
- `political_coalition_extension.md`: extension note for making NIMBY politics stronger
- `compute_coalition_vote.m`: coalition-weighted replacement for the equal-weight vote aggregator
- `solve_ss_coalition.m`: copied steady-state solver with coalition-weighted vote aggregation
- `ClearMarkets_coalition.m`: function driver for the coalition price grid
- `run_political_coalition_extension.m`: entry point for political-side extension work

## How to run

From MATLAB:

- `run_re_no_politics_extension`
- `run_political_coalition_extension`
- `run_demographic_forecast_re_no_politics`
- `run_demographic_forecast_re_no_politics_fertility_style`
- `run_transition_re_no_politics_k_step_ladder`
- `run_transition_re_k2_bridge_followup`
- `run_transition_re_k2_policy_bridge_followup`
- `run_transition_re_k_step_policy_bridge_ladder`
- `run_transition_re_policy_bridge_floor_sweep`
- `run_transition_re_policy_bridge_band_sweep`
- `run_transition_re_policy_bridge_blend_sweep`
- `run_transition_re_policy_bridge_blend_ladder`
- `run_transition_re_reduced_form_one_step`
- `run_transition_re_reduced_form_k_step_ladder`
- `run_linear_age_price_rule`

The transition runner now does a real first-pass backward-forward transition solve. It loads the transition matrix through the robust resolver, builds a demographic-path object from `code/data/age state.csv`, solves the household problem for a guessed finite price path, simulates the distribution forward, and returns an implied price path for the next RE update.

Verified on this machine: `run_demographic_forecast_re_no_politics` runs successfully and saves `transition_re_no_politics_results.mat`.
The transition supply curve is now auto-anchored to the baseline household demand scale at the initial reference price, so the default one-step RE update no longer mechanically collapses prices toward zero.
The runner now also saves period-by-period diagnostics for housing demand, supply, excess demand, and raw/smoothed log-price residuals.
The price updater now works in log prices and applies a regularized whole-path update rather than a purely local ad hoc smoother. This materially improves stability in multi-iteration tests.
The updater now also applies a targeted local correction to the worst residual periods, and the iteration log records which periods are driving the current error.
The current implementation is still not a finished quantitative result. Multi-iteration paths now stay numerically bounded and the bad periods are easier to diagnose, but some period residuals still spike sharply, so full RE convergence remains unresolved.
The fertility-style transplant runner is now also available. It replaces candidate search with the
same full-path relaxation logic used in the fertility annual branch, but on this NIMBY transition
map it currently either wanders into implausible prices or saturates at imposed bounds rather than
finding a clean fixed point. The current read is in `transition_re_fertility_style_note.md`.
The bounded-horizon ladder sharpens that diagnosis: `k = 1` solves immediately, but by `k = 2` the
second-period price hits the imposed upper bound while the implied second-period price is still
about `164.4`, so the problem shows up as soon as the model has to internalize one period ahead.
The new `k = 2` bridge workflow narrows the next question further. Holding the terminal
steady-state tail fixed at the period-1 price or at the baseline price `2.0` lowers the implied
second-period price only modestly, from about `164.4` to about `163.0`, while the final bounded
second-period price still sticks at `5.0`. So the terminal tail matters a bit, but it is not the
sole bottleneck.
The policy bridge goes further and gives the first real simplification result. If the full dynamic
within-path policy block is replaced by steady-state policy rules, the `k = 2` max gap falls from
about `158` to about `0.0065`. If those steady-state policy rules are still allowed to react to the
current price each period, the ladder remains numerically well behaved through `k = 3` before
breaking again by `k = 4`. But if the same bridge is fixed at policy price `2.0`, it stays stable
through the full 9-period horizon, with refreshed max gap about `0.0001` and price range about
`[1.9081, 2.1682]`.

The new anchored-expectations follow-up sharpens that interpretation. A floor-only clip on the
by-period policy reference path does not recover the fixed-price branch: even a floor at `2.0`
still leaves max gap about `0.2103`, and lower floors are much worse. A narrow benchmark band does
not recover it either: the best tested band, `[1.95, 2.05]`, still leaves max gap about `0.1516`.
A coarse sweep over fixed policy prices then showed that `2.0` was the only stable value on the
grid `{1.85, 1.90, 1.95, 2.00, 2.05, 2.10, 2.15}`. The refined local sweep shows the stable branch
is not literally a single point, but it is still narrow and benchmark-centered: stable roughly on
the tested interval `[1.970, 2.002]`, unstable already at `1.965` and `2.003`.

So the fixed-price branch is stronger than either a low-price floor or a narrow current-price band,
but slightly weaker than a literal point mass at `2.0`. The best current reduced-form
interpretation is therefore a narrow benchmark-price neighborhood centered on the calibration
price, not a generic clipped-current-price rule.

The new blend frontier refines that statement. On the full 9-period horizon, the refined blend
sweep is still sharp: `alpha = 0.00`, `0.01`, and `0.015` are stable, while `alpha = 0.02` is the
first unstable tested case and `alpha = 0.05` is materially worse again. But the matched-budget
`k`-ladder is softer than the full-horizon sweep: the pure by-period bridge (`alpha = 1.00`) stays
stable through `k = 3` and fails at `k = 4`, `alpha = 0.05` stays stable through `k = 4`, and
`alpha = 0.02` stays stable through at least `k = 5`. So the instability depends on both the
amount of current-price feedback and the length of the forward-looking horizon.

The new reduced-form-first branch goes one rung lower than that policy bridge. It fits a smooth
aggregate operator on the stable fixed-price benchmark path and then solves bounded RE directly on
that smoother object. On this reduced-form branch, one-step RE is tame and the `k`-step ladder
stays stable through the full forward horizon (`k = 8`) for all tested RE weights
`{0.25, 0.50, 0.75, 1.00, 1.25}`. That is the closest NIMBY analogue so far to the fertility
workflow: reduced form first, then longer horizons.

This also sharpens the interpretation of the old failures. Once the harsh household-policy feedback
is replaced by a smooth aggregate operator, the bounded RE problem is easy. So the hard part of the
NIMBY transition is not the demographic path by itself. It is the structural within-path
household-policy feedback block.
For the extension, the current recommendation is to treat the completed RE runs as qualitative
evidence unless a later simplified sanity check reveals a clearly different message.

## Guardrails

- Do not edit the published baseline files until the extension interface is stable.
- When a genuine upstream bug is found in baseline code, log it in `../../UPSTREAM_FIX_LOG.md` separately from extension work.
