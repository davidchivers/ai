# STATUS - 02_Nimbyism_and_Housing_Supply

## Snapshot

- Last updated: 2026-04-26
- Overall state: published paper; active side worktree has re-anchored the political
  transition work from the 5-year diagnostic sandbox to the annual `LOOP.m` code family.
- Canonical tracker: this file is the single source of truth for status and next actions.

## Completed

- Paper published in Journal of Monetary Economics (2025).
- Codebase migrated into repository (MATLAB steady-state, Stata pipeline, figures, literature, submission materials).
- Upstream relationship documented for syncing fixes into project 03.
- Added external-path portability helpers so the MATLAB and Stata code can prefer
  `D:\research_data\zac_and_david\...` with Dropbox fallback.
- Added a first post-publication extension workspace under `extensions/re_no_politics/`.
- Added runnable extension copies for a no-politics housing-clearing steady-state benchmark and a
  coalition-weighted voting steady-state benchmark.

## In Progress

- Post-publication maintenance workflow setup (PowerShell-first; optional WSL utilities for PDF-heavy tasks).
- Preparation for first structured code review pass of MATLAB model folders.
- Original 5-year political RE transition: smoothed voting helps early horizons, but the
  late tail remained the binding failure zone and did not clear `k = 12` in the strict
  frozen-prefix diagnostic.
- Current local lane combines the entrant-survival simplification with smoothed politics
  and a stage-init-only probe ladder:
  age-25 entrants are the primitive demographic path, older cohorts age forward
  mechanically with fixed survival rates, and permit support uses the smooth response
  rule at `sigma = 0.20`.
- Timing correction: Zac's current steady-state `LOOP.m` code uses one-year model periods
  (`param.modperiod = 1`). The original `SolveSS_iter.m` family and the recent
  `original_5yr_political_re/` experiments remain useful diagnostics, but they are not the
  right quantitative lane for a serious transition implementation.
- Added a new annual lane under `original_annual_political_re/`. Its first saved-grid
  map smoke uses `Mod_IRF/loop101_output_extended.mat` without rerunning the household
  Bellman solver. The smoke tests a soft political-pressure rule:
  vote residual -> bounded pressure -> permit/supply restriction -> price pass-through.
- First annual map smoke completed in
  `original_annual_political_re/truth/annual_political_permit_passthrough_map/annual_map_initial_classified_20260425/`.
  The constant-reference-price path has max vote residual `0.03817`. The best soft
  pass-through rows reduce this to about `0.01143` with no price-grid hits and max log
  price movement around `0.096`; examples include `(rho, phi, gamma) = (0, 0.10, 1.00)`,
  `(0, 0.20, 0.50)`, and `(0.50, 0.10, 0.50)`. This is map-only evidence, not a solved
  transition equilibrium.
- Repeated the saved-grid smoke as a ladder at annual horizons `T = 4, 8, 16, 80`.
  All four horizons had usable rows with no grid hits. The best rows were around
  `phi * gamma = 0.06-0.10`, with max vote residuals `0.00331`, `0.00566`, `0.00566`,
  and `0.01143`, respectively. Summary:
  `original_annual_political_re/annual_map_ladder_summary_20260425.md`.
- Added a local annual transition fail-safe runner under
  `original_annual_political_re/`. Unlike the saved-grid map, this uses the annual
  `Mod_IRF` household/distribution code and moves the distribution forward with
  `solve_dyndist`. It loads the same `loop101_output_extended.mat` source as the
  map smoke, giving reference price `6.057576`, target vote `0.877426`, and
  recomputed baseline vote `0.879148`.
- Local annual transition `T = 4` fail-safe completed:
  `original_annual_political_re/truth/annual_political_transition_fail_safe/annual_transition_T4_failsafe_20260425/`.
  All three tested pass-through candidates were usable. Max vote residuals were
  `0.00534`, `0.00641`, and `0.00547`, with max log price movements only
  `0.018-0.023`. This is the first dynamic annual evidence that the soft political
  pass-through survives beyond the saved-grid map.
- Local annual transition `T = 8` fail-safe is now running under run tag
  `annual_transition_T8_failsafe_20260425`. It completed cleanly; all three candidates
  remained usable. Max vote residuals were `0.00534`, `0.00690`, and `0.00547`, with
  max log price movement `0.020-0.026`.
- Local annual transition `T = 12` fail-safe completed under run tag
  `annual_transition_T12_failsafe_20260425`. All three candidates remained usable. Max
  vote residuals were `0.00534`, `0.00698`, and `0.00547`, with max log price movement
  `0.020-0.026`. Interpretation: the annual dynamic-distribution pass-through mechanism
  survives the short ladder through `T = 12`; next step should be a broader pass-through
  grid rather than more single-lane climbing.
- Added and launched the annual broad-grid fail-safe under run tag
  `annual_broad_grid_T12_20260425_b`. The controller first ran a cheap saved-grid map
  over 108 combinations: `phi = 0.03, 0.06, 0.10, 0.15`,
  `gamma = 0.50, 1.00, 1.50`, `rho = 0, 0.50, 0.85`, and
  `vote_scale = 0.015, 0.020, 0.030`. It selected 9 no-grid-hit usable dynamic
  candidates, 3 per vote scale, and ran them sequentially through the annual dynamic
  `T = 12` fail-safe.
- Broad-grid result: all 9 selected annual dynamic `T = 12` candidates were usable.
  Max vote residuals ranged from `0.00632` to `0.00755`, with max log price movements
  around `0.018-0.024`. Best rows by vote-scale were `(vote_scale, rho, phi, gamma)`
  equal to `(0.015, 0, 0.06, 1.00)`, `(0.020, 0, 0.15, 0.50)`, and
  `(0.030, 0, 0.10, 1.00)`. Interpretation: the mechanism is not a one-parameter fluke;
  the robust region is roughly no persistence and effective pass-through
  `phi * gamma` around `0.06-0.10`.
- Submitted annual Hamilton ladder:
  Slurm array job `16893451`, stage `annpol_lad_20260425_184041`, remote run directory
  `/nobackup/hfnt93/nimby_annual_runs/annpol_lad_20260425_184041`. It runs six array
  tasks: `T = 20/40` crossed with vote scales `0.015, 0.020, 0.030`, using three
  survivor candidates per vote scale. All six tasks later hit the 6-hour Slurm limit
  without writing candidate summaries. Logs show MATLAB was using the slow `.m` version
  of a CompEcon routine rather than a compiled MEX version, so this is currently a
  runtime/setup failure rather than evidence against the pass-through mechanism.
- Added a Hamilton fail-safe workflow:
  `original_annual_political_re/annual_political_hamilton_fail_safe_workflow.md`.
  The new thin submitter ships full CompEcon `CEtools`, including Linux `.mexa64`
  binaries and private MEX routines, and runs one candidate per Slurm task so completed
  candidates write summaries even if other tasks time out.
- Submitted thin annual Hamilton `T = 20` stage:
  Slurm array job `16893773`, stage `annpol_thin_T20_20260426_023209`, remote run
  directory `/nobackup/hfnt93/nimby_annual_runs/annpol_thin_T20_20260426_023209`.
  It runs three tasks, one best local broad-grid candidate per vote scale
  (`0.015`, `0.020`, `0.030`), with a 12-hour walltime.
- Thin Hamilton `T = 20` completed cleanly. All three candidates were usable:
  `(vote_scale, rho, phi, gamma, max vote residual, max log price move)` =
  `(0.015, 0, 0.06, 1.00, 0.006323, 0.023853)`,
  `(0.020, 0, 0.15, 0.50, 0.006371, 0.023085)`, and
  `(0.030, 0, 0.10, 1.00, 0.006514, 0.021348)`. Runtimes were about
  15-39 minutes with CompEcon resolving to Linux `.mexa64`.
- Submitted thin annual Hamilton `T = 40` stage:
  Slurm array job `16893818`, stage `annpol_thin_T40_20260426_060144`, remote run
  directory `/nobackup/hfnt93/nimby_annual_runs/annpol_thin_T40_20260426_060144`.
  It is pending for priority and will run the same three candidates one per task.
- Thin Hamilton `T = 40` completed cleanly. All three candidates were usable:
  `(vote_scale, rho, phi, gamma, max vote residual, max log price move)` =
  `(0.015, 0, 0.06, 1.00, 0.013988, 0.043862)`,
  `(0.020, 0, 0.15, 0.50, 0.013786, 0.044809)`, and
  `(0.030, 0, 0.10, 1.00, 0.014112, 0.043812)`. Runtimes were about 30 minutes.
  Interpretation: the annual political pass-through survives to a 40-year horizon.
- Submitted thin annual Hamilton `T = 80` feasibility stage:
  Slurm array job `16893825`, stage `annpol_thin_T80_20260426_075131`, remote run
  directory `/nobackup/hfnt93/nimby_annual_runs/annpol_thin_T80_20260426_075131`.
  It is pending for priority and runs the same three candidates one per task.
- Thin Hamilton `T = 80` feasibility stage completed. All three candidates were
  classified as survivors rather than strict usable rows:
  `(vote_scale, rho, phi, gamma, max vote residual, max log price move)` =
  `(0.015, 0, 0.06, 1.00, 0.018439, 0.050542)`,
  `(0.020, 0, 0.15, 0.50, 0.017571, 0.052198)`, and
  `(0.030, 0, 0.10, 1.00, 0.017865, 0.052839)`. Runtimes were about 57-64 minutes.
  Interpretation: the long-horizon pass-through remains numerically stable and close,
  but the strict usable threshold is crossed after 40 years.
- Added benchmark-transition workflow:
  `original_annual_political_re/annual_political_benchmark_transition_workflow.md`.
  The benchmark closure collapses the political block to one effective pass-through
  parameter `eta` by fixing `rho = 0`, `vote_scale = 0.020`, and `gamma = 1`.
- Added paper-usability workflow:
  `original_annual_political_re/annual_political_paper_usability_next_steps.md`. It
  frames the annual transition as the paper-consistent reduced-form political supply
  channel, not as a new construction-stock model, and lists the benchmark,
  placebo/random-price, robustness, and figure steps needed before paper use.
- Submitted Hamilton `T = 80` one-parameter refinement:
  Slurm array job `16893840`, stage `annpol_thin_T80Refine_20260426_090934`, remote run
  directory `/nobackup/hfnt93/nimby_annual_runs/annpol_thin_T80Refine_20260426_090934`.
  It runs `eta = 0.060, 0.075, 0.090, 0.105, 0.120, 0.150` with `PeriodIter = 4`.
- Hamilton `T = 80` one-parameter refinement completed. `eta = 0.090, 0.105, 0.120,
  0.150` were usable under the strict cutoff; `eta = 0.060, 0.075` were survivors. Best
  residuals came from larger eta, but benchmark selection should trade off residual fit
  against price movement and parsimony.
- Added lagged pass-through robustness to the annual runner. When `LaggedPassThrough` is
  true, political pressure in year `t` updates the restriction/price environment for
  year `t+1`, rather than feeding back contemporaneously within the same year.
- Submitted Hamilton `T = 80` lag robustness:
  Slurm array job `16893855`, stage `annpol_thin_T80Lag_20260426_102942`, remote run
  directory `/nobackup/hfnt93/nimby_annual_runs/annpol_thin_T80Lag_20260426_102942`.
  It runs the same one-parameter eta grid with the lagged pass-through rule. It completed;
  `eta = 0.105, 0.120, 0.150` were usable, while lower eta rows were survivors.
- Added death/terminal-age robustness to the annual runner. The verified annual code uses
  annual `age_share` weights and not the old equal-age-bin shortcut, but it does not add
  an extra within-period stochastic mortality adjustment. The baseline lets terminal-age
  agents vote in their final living year and exit before the next year.
- Submitted Hamilton death/terminal-age robustness:
  Slurm array job `16893866`, stage `annpol_thin_T80Death_20260426_105020`, remote run
  directory `/nobackup/hfnt93/nimby_annual_runs/annpol_thin_T80Death_20260426_105020`.
  It checks baseline, half terminal-age voting weight, and dropping terminal-age voters
  over `eta = 0.075, 0.090, 0.105`.
- Hamilton death/terminal-age robustness completed cleanly. All nine tasks completed in
  about 56-57 minutes using the Linux CompEcon MEX path. `eta = 0.075` remains a survivor
  under all terminal-age treatments, with max vote residuals around `0.0162-0.0176`.
  `eta = 0.090` is usable under baseline, terminal-half, and terminal-drop treatments,
  with max vote residuals around `0.0141-0.0143` and max log price movement around
  `0.0537-0.0547`. `eta = 0.105` is also usable under all treatments, with similar max
  vote residuals around `0.0143-0.0145` but somewhat larger price movement around
  `0.0597-0.0626`. Interpretation: death/terminal-age timing does not overturn the
  annual political transition; benchmark choice can favor `eta = 0.090` on parsimony and
  smaller price movement unless later shock runs require `eta = 0.105`.
- Submitted long supply-adjustment lag robustness checks. `T80Lag5` is Slurm job
  `16893926`, stage `annpol_thin_T80Lag5_20260426_134257`; `T80Lag10` is Slurm job
  `16893930`, stage `annpol_thin_T80Lag10_20260426_134326`. Each runs `T = 80`,
  `PeriodIter = 4`, and eta values `0.090`, `0.105`, `0.120`, and `0.150`. These should
  be interpreted as reduced-form permit/construction-to-price lags, not delayed political
  pressure.
- Submitted the full paper demographic-shock experiments under the current-price
  house-price-expectations lane with smoothed political pass-through. `T80Boom` is Slurm
  job `16893936`, stage `annpol_thin_T80Boom_20260426_140248`; `T80Decline` is Slurm job
  `16893937`, stage `annpol_thin_T80Decline_20260426_140310`. Each runs the one-parameter
  eta grid `0.060, 0.075, 0.090, 0.105, 0.120, 0.150` over `T = 80` with `PeriodIter = 4`.
  These runs retain the paper's no-house-price-RE/current-price expectation in the
  household Bellman problem while allowing the realized price path to evolve through
  smoothed political pass-through.
- Clarified the main modeling target after coauthor/user discussion: the paper's desired
  transition is a full demographic-price RE, or deterministic perfect-foresight, path.
  In that object households forecast future house-price changes induced by future
  demographics before making today's housing choices. The current annual Hamilton jobs
  remain useful as the current-price-expectations comparison lane, but they should not be
  described as the full RE result.
- Added the full price-path RE runner:
  `original_annual_political_re/run_annual_political_full_re_price_path.m`. This runner
  treats demographics as an exogenous known path and solves households with perfect
  foresight over the future house-price path. It replaces the period-by-period
  current-price Bellman solve with a backward time-indexed Bellman solve: current choices
  use `P_t`, while continuation and resale values use `P_{t+1}` and the later guessed
  path. Political pressure then generates a new price path, which is damped back into the
  next path guess.
- Added Hamilton submitter:
  `original_annual_political_re/submit_annual_full_re_price_path_hamilton.ps1`. The first
  controlled Hamilton smoke is Slurm job `16893956`, stage `annre_T4_20260426_1445`,
  remote directory `/nobackup/hfnt93/nimby_annual_runs/annre_T4_20260426_1445`. It runs
  three tasks: `fixed_age_share`, `baby_boom`, and `secular_decline`, all with `T = 4`,
  `TailYears = 20`, `eta = 0.090`, `OuterIter = 3`, and `PathRelaxation = 0.25`. The
  `fixed_age_share` task is the unit test: with no demographic change, the path should
  stay near steady state. Do not submit `T = 20` unless this unit test passes.
- Added fail-safe watcher:
  `original_annual_political_re/watch_annual_full_re_price_path_hamilton.ps1` plus hidden
  starter `start_annual_full_re_price_path_watchdog.ps1`. A hidden watcher process
  (`PID 53160`) is monitoring job `16893956`; if and only if the fixed-age unit test and
  both shock smokes pass, it will submit the `T20` full price-path RE stage. Otherwise it
  writes a stopped status and does not promote.
- Hamilton naming rule for this lane: use short stage and task names only. The first full
  RE smoke used descriptive names and the Slurm jobs completed cleanly, but local result
  collection hit Windows/SSH path friction from long nested directories. Future stages
  should use compact labels such as `reT4_04261535`, `t4_fix_e09`, `t4_bb_e09`, and
  `t4_dec_e09`.
- First full RE Hamilton smoke `16893956` completed cleanly. Final `T = 4` rows:
  `fixed_age_share` was usable with max path gap `0.0038`; `baby_boom` was a survivor
  with max path gap `0.0456`; `secular_decline` was a survivor with max path gap `0.0313`.
  Interpretation: the price-path RE plumbing passes the no-demographic-change unit test,
  but the shock fixed points need more damping before promotion.
- Submitted short-name full RE `T = 4` refinement: Slurm job `16893972`, stage
  `reT4_04261540`, remote directory `/nobackup/hfnt93/nimby_annual_runs/reT4_04261540`.
  It uses `OuterIter = 8`, `PathRelaxation = 0.10`, `TailYears = 20`, and short tasks
  `t4_fix_e09`, `t4_bb_e09`, `t4_dec_e09`. Hidden watcher PID `28744` is monitoring it
  and will submit `T20` only if all three tasks are strictly usable.
- Added terminal-anchor support for permanent/secular demographic transitions. The runner
  now has `TerminalAnchor = reference | terminal_fixed_point`; the terminal fixed-point
  option solves a constant terminal price from the terminal demographic age vector and uses
  that price as the expectation-tail anchor. This is intended mainly for secular decline,
  where forcing the old steady state into the tail is economically wrong.
- Submitted short-name full RE `T = 4` terminal-anchor refinement: Slurm job `16893980`,
  stage `reT4_04261553`, remote directory `/nobackup/hfnt93/nimby_annual_runs/reT4_04261553`.
  It uses `TerminalAnchor = terminal_fixed_point`, `TerminalIter = 12`, `OuterIter = 8`,
  `PathRelaxation = 0.10`, and `TailYears = 20`. Hidden watcher PID `50424` is monitoring
  it with the same strict `T20` promotion rule.
- Full RE `T = 4` refinements `16893972` and `16893980` completed cleanly. Both show the
  same pattern: `fixed_age_share` is usable, `secular_decline` is now usable, and
  `baby_boom` remains a survivor with max path gap about `0.045`. No `T20` was submitted.
  The stale watcher was stopped manually and statuses were marked stopped. Interpretation:
  the RE price-path machinery works and the secular-decline terminal-anchor concern is
  fixed at the short horizon; the next blocker is the baby-boom path fixed point, not the
  decline tail.
- Current full-RE Hamilton runs: job `16894030`, stage `reT40_04261648`, bumps the
  passers (`fixed_age_share` and `secular_decline`) to `T = 40`; job `16894032`, stage
  `reT4BBTail_04261648`, gives the temporary baby-boom case a long tail so agents can see
  the boom end before the terminal anchor bites. Interim poll after iteration 4: fixed-age
  `T40` is usable with path gap about `0.0054`; baby-boom long-tail `T4` is usable with
  path gap about `0.0197`; secular-decline `T40` is improving but still only a survivor
  with path gap about `0.0433`.
- Added a non-popup Hamilton poll/fetch automation for the current full-RE jobs:
  `original_annual_political_re/poll_annual_full_re_hamilton_once.ps1` and
  `original_annual_political_re/register_annual_full_re_hamilton_poll_task.ps1`.
  Scheduled task `NimbyAnnualFullREPoll` runs every 15 minutes, fetches the latest
  Hamilton summaries while jobs are active, fetches all CSV outputs once jobs are inactive,
  stores them under
  `original_annual_political_re/truth/annual_full_re_hamilton_poll/`, writes
  `latest_report.md` and `latest_state.json`, and unregisters itself once jobs `16894030`
  and `16894032` are no longer active and all three expected summaries have been fetched.
- Added explicit full-RE projection scenarios for the paper's immigration-forecast exercise.
  The full-RE runner now recognizes `forecast_low`, `forecast_median`, and `forecast_high`
  using `forecast_lower`, `forecast_median`, and `forecast_upper` from
  `loop101_output_extended.mat`. The Hamilton submitter now has short projection stages:
  `T4Proj`, `T20Proj`, `T40Proj`, and `T80Proj`. Local syntax smoke
  `local_syntax_T1_projection_median` passed and was usable, so the projection data are
  wired correctly.
- Added LaTeX-only blue draft inserts for the paper:
  `original_annual_political_re/paper_full_re_blue_inserts.tex`. This file explains the
  full price-path RE revision, how it compares to the current-price/non-RE transition,
  why the steady-state demographic figures should remain, and how to plot both
  expectation assumptions. Do not integrate these edits into the LyX source until the
  user explicitly asks.
- Added the paper figure and calibration plan:
  `original_annual_political_re/paper_figure_and_calibration_plan.md`. It keeps the
  steady-state figures as a separate benchmark, makes the main transition graphs compare
  current-price expectations against full price-path RE on the same axes, and adds a
  calibration table plan for the transition-only parameters (`tau`, `eta`, terminal-tail
  rule, and demographic source).
- Submitted the aggressive full-RE T80 packet plus a cheaper secular-decline damping backup.
  Broad run: job `16894205`, stage `reT80A_04262004`, six tasks at `eta = 0.090`
  (`fixed_age_share`, `baby_boom`, `secular_decline`, `forecast_low`,
  `forecast_median`, `forecast_high`). I initially submitted the secular backup at `T80`
  as job `16894209`, then cancelled it before it started because the intended backup was
  `T40`. Correct backup run: job `16894254`, stage `reT40D_04262131`, secular decline
  only at `eta = 0.090` and `0.105`, with `T = 40`, `OuterIter = 16`, and
  `PathRelaxation = 0.05`. The poll automation now watches jobs `16894032`, `16894205`,
  and `16894254`.
- Caveat on the `T80All` projection rows: these are an aggressive stress test, not the
  validated paper projection workflow. The old paper forecast exercise is specifically
  the 2020-2100 low/medium/high immigration projection. Before treating projection
  results as paper-ready, run the separate `T4Proj -> T40Proj/T80Proj` ladder with the
  projection terminal steady-state anchor.
- Cancelled the low/high forecast tasks in the broad `T80All` array (`16894205_3` and
  `16894205_5`) and kept the median forecast task (`16894205_4`) running. Rationale:
  solve or diagnose the median projection first, then run low/high once the forecast
  workflow is stable.
- Patched `run_annual_political_full_re_price_path.m` with an explicit `ReferenceYear`
  option. This matters for the forecast exercise: the paper projection lane should start
  from the 2020 age distribution, not silently default to the old year-2000 reference
  column. Local smoke `local_syntax_T1_projection_median_2020` passed with max path gap
  `0.01636` and max vote residual `0.00368`.
- Added and launched a guarded local median-projection ladder:
  `original_annual_political_re/run_local_median_projection_ladder.ps1`. Active run
  prefix `local_medproj_2020_20260426_213908` climbs `T = 4, 8, 12, 20` for
  `forecast_median`, `ReferenceYear = 2020`, `TerminalAnchor = terminal_fixed_point`,
  `OuterIter = 6`, and `PathRelaxation = 0.08`. It warm-starts each rung from the
  previous generated path and stops if the verdict is `dead` or the price-path gap
  exceeds `0.06`.
- Patched `submit_annual_full_re_price_path_hamilton.ps1` so projection stages
  (`T4Proj`, `T20Proj`, `T40Proj`, `T80Proj`) default to `ReferenceYear = 2020`;
  non-projection stages still default to `NaN` and keep the old reference behavior.
- Overnight local median projection ladder `local_medproj_2020_20260426_213908`
  stopped at `T = 12`: `T4` was a survivor with path gap `0.03022`, `T8` was usable
  with path gap `0.01055`, and `T12` was dead with path gap `0.06705` and vote residual
  `0.02308`. Interpretation: the corrected 2020 median projection is not ready for a
  paper `T80` upload, but the failure is close enough to justify another safer local
  retry.
- Started safer local retry `local_medproj_safe_20260427_054207` with slower path
  relaxation (`0.04`), more outer iterations (`10`), longer tails (`40/60`), and stronger
  terminal fixed-point work (`TerminalIter = 16`, `TerminalRelaxation = 0.15`).
- Hamilton re-check from already-fetched CSVs shows the broad `T80All` stress run improved
  materially after the stale early rows. Final fetched rows: fixed-age `T80` usable
  (`0.00316` path gap), secular `T80` survivor (`0.02681`), baby-boom `T80` survivor
  (`0.04974`), and forecast-median `T80` survivor (`0.04955`). The forecast-median row is
  still not paper-ready because this was the aggressive stress test submitted before the
  `ReferenceYear = 2020` projection correction. Direct SSH to Hamilton is currently
  stalling during the handshake, so treat this as a fetched-results update rather than a
  live queue verification.
- Added smoothing-function robustness support to the full-RE runner:
  `PressureMode = smooth/tanh`, `softnorm`, `linear_clip`, `logit`, and `hard_sign`.
  The benchmark default remains `smooth`/`tanh`; this is for smoke diagnostics and
  robustness.
- Started local smoothing-function smoke `smooth_func_smoke_20260427_061403`. It waits
  for the current MATLAB median retry to finish, then tests the corrected 2020
  `forecast_median` path at the `T = 12` failure margin using `smooth:0.030`,
  `smooth:0.040`, `softnorm:0.030`, and `logit:0.030`. Stop file:
  `original_annual_political_re/truth/annual_full_re_smoothing_function_smoke/STOP.flag`.
- Local safer median retry update: `T = 4` completed and became usable at iteration
  `10/10` with path gap `0.01980` and vote residual `0.00643`. The run has moved to
  `T = 8`, but no `T8` summary row has been written yet. If the machine is restarted now,
  the saved `T4` result is preserved, but the in-progress `T8` work will be lost.
- Added the annual comparison experiment workflow:
  `original_annual_political_re/annual_political_comparison_experiments_workflow.md`.
  It sets up the clean comparison against random/exogenous price paths and the hard-sign
  `tau = 0` limit.
- Added and ran the saved-grid comparison map:
  `original_annual_political_re/run_annual_political_comparison_map.m`.
  Full run `annual_comparison_map_full_20260426` uses the same annual price/vote map,
  `T = 80`, and 200 random AR(1) paths per amplitude. On this diagnostic, the smooth
  `tau = 0.020` rules reduce the max vote residual to about `0.0189-0.0204`, versus
  `0.0382` for the constant-price path. The hard-sign `tau = 0` rule is much weaker:
  best `eta = 0.090` gives `0.0361`, while larger eta values are dead. Random price
  paths do not get close: across amplitudes `0.03-0.10`, median max residuals range
  from about `0.0386` to `0.0521`, with zero usable draws. Interpretation: on the
  annual saved grid, smoothing is doing real stabilizing work rather than merely
  reproducing arbitrary price noise.
- Patched the full annual dynamic runner to allow `PressureMode = hard_sign`, and added
  Hamilton stage `T80Hard` to the thin submitter. This makes the next full dynamic
  comparison easy if the saved-grid result needs to be checked in the full household
  transition.
- Added demographic-shock support to the annual transition runner:
  `DemographicScenario = source_path | flat_entrant | baby_boom | secular_decline`.
  For non-source scenarios, the runner starts from the annual baseline age distribution,
  shocks age-25 entrants, ages older cohorts forward with a simple annual survival
  profile, and normalizes the age vector before voting. This is a solvability/mechanism
  test, not a final demographic calibration.
- Added demographic-shock workflow:
  `original_annual_political_re/annual_political_demographic_shock_workflow.md`.
  Local `T = 4` smokes passed for both `baby_boom` and `secular_decline` with eta
  `0.105`: max vote residuals were about `0.00505` and `0.00517`, with max log price
  moves about `0.0230` and `0.0265`. Hamilton stages `T80Boom` and `T80Decline` are now
  available for full 80-year checks.
- Added paper workflow:
  `original_annual_political_re/annual_political_re_paper_workflow.md`. It organizes the
  remaining work into gates: full demographic-price RE, benchmark eta,
  smoothing/no-smoothing comparison, random-price comparison, demographic shocks, figures,
  and blue paper text.
- Added blue draft text to the main LyX source. The inserts cover the annual
  transition motivation, smoothed political pressure, the pressure
  equation, annual-age demographic shock interpretation, and the random-price/hard-sign
  diagnostic comparisons. These are draft inserts and should remain blue until the
  benchmark and graph package are finalized.
- Added local diagnosis packet:
  `original_annual_political_re/annual_political_pass_through_diagnosis_20260425.md`.
- Added local Hamilton checker:
  `original_annual_political_re/check_annual_political_hamilton_ladder.ps1`.
- The earlier stage-init-only flat probe finished through `k = 14`. Results showed that the
  housing/price side remains numerically well behaved, but the political residual jumps
  at `k = 10`: `k = 4` vote `0.00232`, `k = 6` vote `0.04048`, `k = 8` vote
  `0.03400`, `k = 10` vote `0.15609`, `k = 12` vote `0.15808`, `k = 14` vote
  `0.15808`. Housing gaps at `k = 10-14` stay small, roughly `0.0067-0.0092`.
- Those results are now superseded as quantitative evidence because the transition solver
  built voter age masses from relative cohort scales as if baseline age bins were equal
  sized. `solve_transition_re_no_politics.m` now uses `population_by_age` directly when
  available, row-normalized to voter age masses.
- The ghost-tail `k = 10` diagnostic completed. `G = 0` and `G = 2` timed out without
  summaries; `G = 4` completed with target-window vote `0.09062`, target gap `0.01924`,
  full/ghost vote `0.17195`; `G = 6` did not write a summary before the bounded queue
  ended. Interpretation: a continuation tail helps relative to the original `0.156`
  spike, but does not clear politics and shifts large residuals into the continuation
  tail.
- Added a political vote-composition audit:
  `original_5yr_political_re/audit_original_5yr_political_vote_composition.m`. On the
  saved `k = 10` probe path after the population-weight fix, the worst vote falls from
  the old artifact value `+0.15808` to `+0.09393`. Adding a terminal-exit rule for the
  `90+` bin gives `+0.09192`; switching to historical age shares gives `+0.08689`.
  Interpretation: the large `90+` pile-up was mostly an age-mass implementation artifact,
  not the main remaining issue. The remaining residual is broader: many owner ages like
  higher prices, and the only renter group in the simulated distribution is age 25.
  The saved old `k = 10` price path is also no longer housing-clearing under corrected
  age masses, with audit gaps around `0.05-0.09`, so the next solver run must be fresh.
- A follow-up policy check confirms the renter issue is not only an audit timing artifact.
  On the corrected-weight `k = 10` audit path, ages 65-85 choose essentially zero mass
  into the renter state; only age 90 sells into renting, at roughly `13-16%` of its owner
  mass in periods 8-10. The household block also contains an explicit terminal bequest
  term and has no medical/health/liquidity shocks, so late-life home liquidation is likely
  too weak in the current extension.
- Added an empirical tenure counterfactual audit:
  `original_5yr_political_re/audit_original_5yr_political_empirical_tenure_counterfactual.m`.
  It keeps the saved value-function responses fixed, but mechanically reweights each age
  bin to empirical homeownership rates. On the corrected `k = 10` audit path, the max vote
  residual only falls from `0.09393` to `0.08860` when all ages are reweighted, to `0.08599`
  when ages `65+` are reweighted, and to `0.08757` when only ages `75+` are reweighted.
  Interpretation: missing old renters and excessive ownership matter, but tenure composition
  alone is not enough to claim the model would solve if the age-tenure distribution matched
  the data.
- Added a political-preference shift counterfactual audit:
  `original_5yr_political_re/audit_original_5yr_political_preference_shift_counterfactual.m`.
  On the same saved corrected `k = 10` path, an additive smoothed-voting shift of about
  `-0.038` in the late periods would mechanically clear the vote residual at
  `political_response_sigma = 0.20`. This is not an equilibrium result, but it says the
  missing political-wedge story is quantitatively more promising than the ownership-tail
  story on this saved path.
- Patched the joint supply-wedge continuation runner so its local demographic truncation
  preserves `population_by_age`; without this, fresh runs could still silently drop the
  corrected voter age masses before reaching `solve_transition_re_no_politics.m`.
- Launched the corrected-weight smoothed decision workflow in one hidden local MATLAB lane:
  `original_5yr_political_re/start_original_5yr_corrected_parallel_decision_workflow.ps1`.
  Live status is in
  `original_5yr_political_re/truth/corrected_parallel_decision_live/latest_status.json`.
  It runs the fresh flat entrant-survival ladder `k = [4, 6, 8, 10]`, `sigma = 0.20`,
  `stage_init_only`, with the corrected `population_by_age` path preserved.

## Next 3 Tasks

1. Let safer local retry `local_medproj_safe_20260427_054207` finish or fail fast. If it
   passes through `T = 20`, submit a corrected Hamilton median projection run with
   `ReferenceYear = 2020`; do not upload median `T80` before this gate.
2. After the safer median retry clears the machine, review smoothing-function smoke
   `smooth_func_smoke_20260427_061403`; if a smoother pressure rule materially improves
   `T = 12`, promote it only as a robustness/diagnostic candidate first.
3. Once SSH to Hamilton behaves again, fetch final full outputs/logs for `T80All` and
   `T40D`; then submit safer `T80` reruns for secular and baby-boom only if the fetched
   paths confirm they need more damping.

## Blockers

- No formal code-review output document yet in the project.
- The large external MATLAB `.mat` inputs still live outside this git repo, so portability
  improvements reduce friction but do not make the project fully self-contained.
- The hard-sign entrant-survival flat lane reached a decent `k = 2` vote residual (`0.0544`)
  but its `k = 4` stage-init vote residual was back near `0.10`; smoothing fixed that
  margin, while the remaining issue was the update/search routine overworking good points.
- The old smoothed stage-init probe reached `k = 14`, but those numbers used the old
  equal-baseline age-mass construction and should not be treated as final.
- The transition distribution has almost no renter counterweight after age 25; this is now
  the main composition concern after fixing voter age masses.
- The annual pass-through smoke is currently reduced-form. It uses saved vote-by-price
  grids and does not yet solve annual household transitions, annual construction/stock
  dynamics, or a true joint market-clearing path.
- The annual transition fail-safe is closer to the real model because it moves the
  household distribution forward, but it is still not the final structural solver: the
  permit/supply-to-price block remains reduced-form through `gamma`.
- The full future-house-price-path RE lane is implemented, but the corrected 2020 median
  projection has not yet passed a clean long-horizon ladder.

## Open Decisions

- Whether the corrected `k = 10` political residual reflects a real corner tendency toward
  tighter supply or a broader value-function misspecification. The saved-path empirical
  tenure audit suggests it is not mainly an ownership-composition artifact.
- Whether the political closure should be an interior zero-residual condition or a corner/
  complementarity condition when the corrected electorate still wants tighter supply.
- Whether boom/decline entrant paths should wait until the flat `k = 10` failure is fixed;
  current evidence says yes, because the flat path already exposes the binding margin.
- How to specify the annual permit/supply-to-price pass-through in the real transition:
  the saved-grid smoke says moderate soft pass-through is promising, but the next test
  must make that link structural enough to be defensible.

## References

- Project overview: `projects/02_nimbyism_and_housing_supply/README.md`
- Session log: `projects/02_nimbyism_and_housing_supply/memory.md`
- Upstream fix log: `projects/02_nimbyism_and_housing_supply/UPSTREAM_FIX_LOG.md`
- Referee report source file: `projects/02_nimbyism_and_housing_supply/referee/Economic Journal Referee Reports.docx`

## Working Rule

- When asked "where are we?" or to update the to-do list, update this file first.
