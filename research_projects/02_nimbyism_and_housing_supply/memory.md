# Project Memory - NIMBYism and the Housing Supply

Most recent session first.

---

### Session: 2026-04-26 (full demographic-price RE clarification)
- Clarified an important terminology/modeling issue: the current annual Hamilton lane is
  not a full future-house-price-path RE transition. It solves household choices with
  current-price/random-walk house-price expectations, then moves the realized economy
  forward through smoothed political pass-through.
- The desired paper object is a deterministic full demographic-price RE, or
  perfect-foresight, transition: households know the future demographic path and forecast
  the implied future house-price path before making today's housing choices.
- Updated `original_annual_political_re/annual_political_re_paper_workflow.md` with a new
  Gate 0 for the full RE lane. The required algorithm is: guess a full price path, solve a
  time-indexed household problem backward, simulate demographics forward, generate a new
  political/price path, and iterate with damping until guessed and generated paths agree.
- Updated `STATUS.md` so the current no-aggregate-RE annual jobs are treated as a useful
  comparison/control lane, not as the benchmark full RE result.
- Added `original_annual_political_re/run_annual_political_full_re_price_path.m`. This is
  the first actual full price-path RE runner in the annual lane: current choices use
  `P_t`, continuation/resale values use `P_{t+1}`, and the generated political price path
  is damped back into the guessed future path. It includes a `TailYears` option so short
  reported horizons are not contaminated by an artificial terminal price cliff.
- Local syntax/unit smokes passed for `T = 1`. A local `T = 4` run without an expectation
  tail showed why the tail is needed: the final reported period can be distorted by a
  forced return to steady state. The runner now separates reported horizon from internal
  expectation horizon.
- Added `original_annual_political_re/submit_annual_full_re_price_path_hamilton.ps1` and
  submitted the first Hamilton smoke: job `16893956`, stage `annre_T4_20260426_1445`,
  remote directory `/nobackup/hfnt93/nimby_annual_runs/annre_T4_20260426_1445`. It runs
  `fixed_age_share`, `baby_boom`, and `secular_decline` at `T = 4`, `TailYears = 20`,
  `eta = 0.090`, and `OuterIter = 3`. The `fixed_age_share` task is the no-demographic
  unit test and must pass before any promotion to `T = 20`.
- Added `original_annual_political_re/watch_annual_full_re_price_path_hamilton.ps1` and
  `start_annual_full_re_price_path_watchdog.ps1`. Started hidden watcher PID `53160` with
  `AutoSubmitT20`; it polls job `16893956`, downloads result summaries after completion,
  and submits `T20` only if the fixed-age unit test and both shock smokes pass.
- New Hamilton naming rule: keep stage and task labels short. The first full RE smoke used
  descriptive labels and the jobs ran correctly, but local collection hit Windows path
  friction from long nested names. Future submissions should use compact labels like
  `reT4_04261535`, `t4_fix_e09`, `t4_bb_e09`, and `t4_dec_e09`.
- First full RE Hamilton smoke `16893956` completed cleanly. The no-demographic unit test
  passed (`fixed_age_share` max path gap about `0.0038`). The baby-boom and secular-decline
  shock tasks were survivors, with max path gaps about `0.0456` and `0.0313`. This supports
  the RE plumbing but is not yet tight enough to promote.
- Submitted short-name refinement `16893972`, stage `reT4_04261540`, using
  `OuterIter = 8`, `PathRelaxation = 0.10`, and `TailYears = 20`. Started hidden watcher
  PID `28744` with strict auto-promotion: submit `T20` only if all three `T4` tasks are
  usable.
- Added terminal-anchor support after the secular-decline discussion. `TerminalAnchor =
  terminal_fixed_point` solves a constant terminal price from the terminal demographic age
  vector and uses that price in the expectation tail, instead of forcing the old steady
  state. Local `T = 1` syntax smoke passed.
- Submitted terminal-anchor Hamilton refinement `16893980`, stage `reT4_04261553`, using
  `TerminalAnchor = terminal_fixed_point`, `TerminalIter = 12`, `OuterIter = 8`,
  `PathRelaxation = 0.10`, and `TailYears = 20`. Started hidden watcher PID `50424`.
- Full RE refinements `16893972` and `16893980` completed cleanly. Final rows show
  `fixed_age_share` usable, `secular_decline` usable, and `baby_boom` still a survivor
  with max path gap about `0.045`. No `T20` was submitted. The watcher status was manually
  marked stopped and stale watcher PID `50424` was stopped.
- Submitted two follow-up Hamilton runs after the baby-boom diagnosis:
  - `16894030`, stage `reT40_04261648`: promotes the passers only
    (`fixed_age_share` and `secular_decline`) to `T = 40`
  - `16894032`, stage `reT4BBTail_04261648`: keeps baby boom at reported `T = 4`
    but gives it an 80-year tail so households can see the temporary boom end
- Interim poll result:
  fixed-age `T40` is usable by outer iteration 4 with path gap about `0.0054`;
  baby-boom long-tail `T4` is usable by outer iteration 4 with path gap about
  `0.0197`; secular-decline `T40` is improving but remains a survivor at iteration 4
  with path gap about `0.0433`.
- Added a non-popup scheduled poll/fetch automation because the recursive watcher path had
  been sketchy:
  `original_annual_political_re/poll_annual_full_re_hamilton_once.ps1` and
  `original_annual_political_re/register_annual_full_re_hamilton_poll_task.ps1`.
  The registered task is `NimbyAnnualFullREPoll`; it runs every 15 minutes for up to
  24 hours, fetches latest Hamilton summaries while jobs are active, fetches all CSV
  outputs once jobs are inactive, stores them under
  `original_annual_political_re/truth/annual_full_re_hamilton_poll/`, writes
  `latest_report.md` and `latest_state.json`, and unregisters itself when jobs
  `16894030` and `16894032` are inactive and all three expected summaries have been fetched.
- Workflow decision:
  do not jump all scenarios to `T = 80`. If fixed-age/secular-decline finish cleanly at
  `T40`, promote those passers to `T80`; if baby-boom long-tail stays usable, climb it
  through `T20` or `T40` before `T80`; if it fails again, stop adding horizon and switch
  to a path-level solver update.
- User reminded us that the published paper also has the future demographic projection /
  immigration exercise. Confirmed from the paper and old `LOOP.m` that the projection
  figure used low, medium, and high immigration assumptions. The source MAT file contains
  `forecast_lower`, `forecast_median`, and `forecast_upper`, each `56 x 81`.
- Patched `run_annual_political_full_re_price_path.m` so full-RE runs can use explicit
  projection scenarios:
  `forecast_low`, `forecast_median`, and `forecast_high`. Patched
  `submit_annual_full_re_price_path_hamilton.ps1` with short projection stages:
  `T4Proj`, `T20Proj`, `T40Proj`, and `T80Proj`.
- Local syntax smoke `local_syntax_T1_projection_median` completed and was usable, with
  path gap about `0.0153` and vote residual about `0.0034`. This is only a wiring check,
  not a paper result.
- User asked for paper updates but then clarified: keep this LaTeX-only and do not update
  LyX until explicitly asked. Added
  `original_annual_political_re/paper_full_re_blue_inserts.tex` with blue draft text for
  the full-RE revision, projection exercise, baby-boom exercise, permanent entrant-decline
  exercise, computational appendix, and figure plan. The LyX source should not be touched
  for this until the user gives approval.
- Added `original_annual_political_re/paper_figure_and_calibration_plan.md`. The plan says
  to keep the steady-state demographic figures, add dynamic figures comparing
  current-price/non-RE and full price-path RE on the same axes, put hard-sign and
  random-price checks mostly in the appendix, and add a small transition-parameter table
  rather than recalibrating the whole model.
- User asked why not send the broad 80-year run now while also running a damped secular
  backup. Agreed and submitted:
  - `16894205`, stage `reT80A_04262004`: six-task `T80All` packet covering
    fixed-age, baby boom, secular decline, and low/medium/high immigration projections at
    `eta = 0.090`
  - `16894209`, stage `reT80D_04262004`: two-task secular-decline backup at `eta = 0.090`
    and `0.105`, with `OuterIter = 16` and `PathRelaxation = 0.05`
- Updated `poll_annual_full_re_hamilton_once.ps1` so the scheduled poller now watches the
  live baby-tail job plus the two new T80 jobs and expects nine summary files before
  self-stopping.

---

### Session: 2026-04-25 (annual political pass-through re-anchor)
- Corrected the timing interpretation after Zac's note: the current steady-state `LOOP.m`
  family uses one-year periods (`param.modperiod = 1`). The recent
  `original_5yr_political_re/` runs remain diagnostic, but should not be treated as the
  serious quantitative transition lane.
- Stopped the stale local 5-year phi smoke and marked its status as stopped in
  `original_5yr_political_re/truth/political_permit_passthrough/latest_status.json`.
- Added `original_annual_political_re/annual_political_permit_passthrough_workflow.md`
  to formalize the annual workflow: saved-grid map smoke, then annual `T = 4`, then
  `T = 8`, then `T = 12/16`, with no 80-year Hamilton run until the short gates pass.
- Added the saved-grid annual map smoke runner:
  `original_annual_political_re/run_annual_political_permit_passthrough_map_smoke.m`
  plus PowerShell wrappers. It loads
  `C:\Users\Dave_\Dropbox\Zac and David\Code\SteadyState\Mod_IRF\loop101_output_extended.mat`
  and does not rerun the household Bellman solver.
- First smoke output:
  `original_annual_political_re/truth/annual_political_permit_passthrough_map/annual_map_initial_classified_20260425/`.
  Constant-reference-price max vote residual is `0.03817`. The best soft pass-through
  rows reduce this to about `0.01143` with no grid hits and max log price movement
  around `0.096`; examples are `(rho, phi, gamma) = (0, 0.10, 1.00)`,
  `(0, 0.20, 0.50)`, and `(0.50, 0.10, 0.50)`.
- Ran the saved-grid map ladder at `T = 4, 8, 16, 80`. All four horizons had usable
  no-grid-hit rows; best max vote residuals were `0.00331`, `0.00566`, `0.00566`, and
  `0.01143`. Added `original_annual_political_re/annual_map_ladder_summary_20260425.md`.
- Interpretation: this is good map-level news, not an equilibrium result. It supports
  building a real annual `T = 4` transition smoke with political pressure feeding permits
  and permits feeding prices, rather than forcing political vote residuals to zero each
  period.
- Added the annual transition fail-safe runner:
  `original_annual_political_re/run_annual_political_transition_fail_safe.m`, with
  PowerShell foreground and hidden starters. The runner uses the annual `Mod_IRF`
  household/distribution code and moves the distribution forward with `solve_dyndist`.
- First validation exposed a calibration mismatch: loading `estimationoutput.mat` gave
  reference price about `8.98` rather than the map source's `6.06`. Patched the runner
  to load `loop101_output_extended.mat`, giving reference price `6.057576`, target vote
  `0.877426`, and recomputed baseline vote `0.879148`.
- Local annual transition `T = 4` fail-safe completed under
  `truth/annual_political_transition_fail_safe/annual_transition_T4_failsafe_20260425/`.
  All three candidates were usable: max vote residuals `0.00534`, `0.00641`, and
  `0.00547`; max log price movement `0.018-0.023`.
- Since `T = 4` passed, launched local annual transition `T = 8` fail-safe under
  run tag `annual_transition_T8_failsafe_20260425`. It completed cleanly; all three
  candidates remained usable. Max vote residuals were `0.00534`, `0.00690`, and
  `0.00547`, with max log price movement `0.020-0.026`.
- Local annual transition `T = 12` fail-safe completed under run tag
  `annual_transition_T12_failsafe_20260425`. All three candidates remained usable.
  Max vote residuals were `0.00534`, `0.00698`, and `0.00547`, with max log price
  movement `0.020-0.026`. Next step is a broader pass-through parameter grid, not more
  single-lane horizon climbing.
- Added and launched annual broad-grid fail-safe:
  `original_annual_political_re/run_annual_political_broad_grid_fail_safe.ps1`.
  Run tag: `annual_broad_grid_T12_20260425_b`. It ran a saved-grid map over 108
  combinations of `phi`, `gamma`, `rho`, and `vote_scale`, selected 9 no-grid-hit
  usable candidates, and started the sequential annual dynamic `T = 12` stage.
- Broad-grid `T = 12` completed: all 9 selected annual dynamic candidates were usable.
  Max vote residuals ranged from `0.00632` to `0.00755`; max log price movement was
  about `0.018-0.024`. Best rows by vote-scale:
  `(0.015, rho=0, phi=0.06, gamma=1.00)`,
  `(0.020, rho=0, phi=0.15, gamma=0.50)`, and
  `(0.030, rho=0, phi=0.10, gamma=1.00)`.
  Interpretation: the robust annual pass-through region is roughly no persistence with
  effective pass-through `phi * gamma` around `0.06-0.10`.
- Submitted annual Hamilton ladder with Slurm array job `16893451`, stage
  `annpol_lad_20260425_184041`, remote run directory
  `/nobackup/hfnt93/nimby_annual_runs/annpol_lad_20260425_184041`. It runs `T = 20/40`
  crossed with vote scales `0.015, 0.020, 0.030` and 3 survivor candidates per vote
  scale. All six tasks later hit the 6-hour Slurm limit without writing candidate
  summaries. Logs show MATLAB was using the slow `.m` version of a CompEcon routine rather
  than a compiled MEX version, so the failure is a runtime/setup problem rather than a
  model-result rejection.
- Added `original_annual_political_re/annual_political_hamilton_fail_safe_workflow.md`
  plus a thin Hamilton submit/check pair:
  `submit_annual_political_hamilton_thin_ladder.ps1` and
  `check_annual_political_hamilton_thin_ladder.ps1`. The thin workflow ships full
  CompEcon `CEtools`, including Linux `.mexa64` binaries and private MEX routines, and
  runs one candidate per Slurm task.
- Submitted thin annual Hamilton `T = 20` job `16893773`, stage
  `annpol_thin_T20_20260426_023209`, remote directory
  `/nobackup/hfnt93/nimby_annual_runs/annpol_thin_T20_20260426_023209`. It runs three
  best local broad-grid candidates, one per vote scale, with 12-hour walltime.
- Thin Hamilton `T = 20` completed cleanly. All three candidates were usable:
  `(0.015, rho=0, phi=0.06, gamma=1.00)` with max vote residual `0.006323`,
  `(0.020, rho=0, phi=0.15, gamma=0.50)` with max vote residual `0.006371`, and
  `(0.030, rho=0, phi=0.10, gamma=1.00)` with max vote residual `0.006514`.
  Runtimes were about 15-39 minutes now that Hamilton used Linux `.mexa64` CompEcon
  routines.
- Submitted thin annual Hamilton `T = 40` job `16893818`, stage
  `annpol_thin_T40_20260426_060144`, remote directory
  `/nobackup/hfnt93/nimby_annual_runs/annpol_thin_T40_20260426_060144`. It is pending
  for priority and will run the same three candidates one per task.
- Thin Hamilton `T = 40` completed cleanly. All three candidates were usable:
  `(0.015, rho=0, phi=0.06, gamma=1.00)` with max vote residual `0.013988`,
  `(0.020, rho=0, phi=0.15, gamma=0.50)` with max vote residual `0.013786`, and
  `(0.030, rho=0, phi=0.10, gamma=1.00)` with max vote residual `0.014112`.
  Runtimes were about 30 minutes. Interpretation: the annual pass-through mechanism
  survives to a 40-year horizon; next decision is whether to stop at `T = 40` or run one
  final thin `T = 80` feasibility check.
- Patched the thin submitter to support `T = 80` and submitted thin annual Hamilton
  feasibility job `16893825`, stage `annpol_thin_T80_20260426_075131`, remote directory
  `/nobackup/hfnt93/nimby_annual_runs/annpol_thin_T80_20260426_075131`. It is pending
  for priority and runs the same three candidates one per task.
- Thin Hamilton `T = 80` completed. All three candidates were survivors rather than
  strict usable rows: `(0.015, rho=0, phi=0.06, gamma=1.00)` with max vote residual
  `0.018439`, `(0.020, rho=0, phi=0.15, gamma=0.50)` with max vote residual
  `0.017571`, and `(0.030, rho=0, phi=0.10, gamma=1.00)` with max vote residual
  `0.017865`. Runtimes were about 57-64 minutes. Interpretation: the long-horizon
  annual pass-through remains stable and close, but `T = 80` is weaker than the clean
  `T = 40` result under the strict threshold.
- Added `original_annual_political_re/annual_political_benchmark_transition_workflow.md`
  to define the benchmark transition as a one-effective-parameter closure:
  `rho = 0`, `vote_scale = 0.020`, `gamma = 1`, and `phi = eta`.
- Added `original_annual_political_re/annual_political_paper_usability_next_steps.md`
  to define the route from current Hamilton evidence to a paper-usable transition
  package: select benchmark eta, rerun benchmark horizons, rerun random-price/placebo
  paths with corrected voter weights, rebuild graphs, and frame the paper claim as the
  transition analogue of the published paper's reduced-form political supply channel.
- Submitted Hamilton one-parameter `T = 80` refinement job `16893840`, stage
  `annpol_thin_T80Refine_20260426_090934`, remote directory
  `/nobackup/hfnt93/nimby_annual_runs/annpol_thin_T80Refine_20260426_090934`. It runs
  `eta = 0.060, 0.075, 0.090, 0.105, 0.120, 0.150` with `PeriodIter = 4`.
- Hamilton `T = 80` one-parameter refinement completed. `eta = 0.090, 0.105, 0.120,
  0.150` were usable under the strict cutoff; `eta = 0.060, 0.075` were survivors.
  Larger eta improves vote residuals but also increases price movement, so the benchmark
  choice should not mechanically pick the largest eta.
- Added lagged pass-through support to `run_annual_political_transition_fail_safe.m` and
  `submit_annual_political_hamilton_thin_ladder.ps1`. Under `LaggedPassThrough`, the
  price path in year `t` uses the previous restriction state, while pressure in year `t`
  updates the restriction/price environment for year `t+1`.
- Submitted Hamilton lag robustness job `16893855`, stage
  `annpol_thin_T80Lag_20260426_102942`, remote directory
  `/nobackup/hfnt93/nimby_annual_runs/annpol_thin_T80Lag_20260426_102942`. It runs the
  same one-parameter eta grid with lagged pass-through and is pending for priority.
- Hamilton lag robustness completed. With one-year lagged pass-through, `eta = 0.105,
  0.120, 0.150` were usable and lower eta rows were survivors, so the one-year lag does
  not kill the mechanism.
- Confirmed the annual transition runner uses annual `age_share(:, year)` vectors for
  voter aggregation, not the old equal-age-bin shortcut. The remaining death caveat is
  timing: baseline terminal-age agents vote in their final living year and exit before
  the next year; there is no additional within-period stochastic mortality adjustment.
- Added and submitted death/terminal-age robustness job `16893866`, stage
  `annpol_thin_T80Death_20260426_105020`, remote directory
  `/nobackup/hfnt93/nimby_annual_runs/annpol_thin_T80Death_20260426_105020`. It checks
  baseline terminal-age voting, half terminal-age weight, and dropping terminal-age voters
  over `eta = 0.075, 0.090, 0.105`.
- Hamilton death/terminal-age robustness completed. `eta = 0.075` is a survivor under
  all terminal-age treatments. `eta = 0.090` is usable under baseline, terminal-half, and
  terminal-drop treatments, with max vote residuals about `0.0141-0.0143` and max log
  price movement about `0.0537-0.0547`. `eta = 0.105` is also usable, with similar max
  vote residuals but larger price movement about `0.0597-0.0626`. Provisional benchmark
  should be `eta = 0.090` unless the full shock runs require the extra strength of
  `eta = 0.105`.
- Submitted long supply-adjustment lag robustness checks on Hamilton. `T80Lag5` is job
  `16893926`, stage `annpol_thin_T80Lag5_20260426_134257`; `T80Lag10` is job
  `16893930`, stage `annpol_thin_T80Lag10_20260426_134326`. Each runs eta values
  `0.090`, `0.105`, `0.120`, and `0.150` at `T = 80` and `PeriodIter = 4`. Interpret
  these as permit/construction-to-price lags, not delayed political pressure.
- Submitted full paper demographic-shock experiments on Hamilton. `T80Boom` is job
  `16893936`, stage `annpol_thin_T80Boom_20260426_140248`; `T80Decline` is job
  `16893937`, stage `annpol_thin_T80Decline_20260426_140310`. Each runs eta values
  `0.060, 0.075, 0.090, 0.105, 0.120, 0.150` at `T = 80` and `PeriodIter = 4`.
- Clarified the interpretation of the current annual transition lane: households retain
  current-price/random-walk house-price expectations in the Bellman problem, while the
  realized price path evolves endogenously through smoothed political pass-through. This
  is the requested no-house-price-RE comparison, not a full future-price-path RE solve.
- Added `original_annual_political_re/annual_political_comparison_experiments_workflow.md`
  plus the saved-grid comparison runner
  `original_annual_political_re/run_annual_political_comparison_map.m`.
- Ran full comparison map `annual_comparison_map_full_20260426` with `T = 80` and 200
  random AR(1) paths per amplitude. Smooth `tau = 0.020` rows get max residuals around
  `0.0189-0.0204`; constant price is `0.0382`; best hard-sign `tau = 0` is only
  `0.0361`; larger hard-sign etas are dead. Random price paths do not produce usable
  rows, with median max residuals around `0.0386-0.0521` across amplitudes. This is a
  saved-grid diagnostic, not the final dynamic comparison, but it strongly supports
  smoothing as doing real work.
- Patched `run_annual_political_transition_fail_safe.m` with `PressureMode = smooth |
  hard_sign`, and added Hamilton stage `T80Hard` in the thin submitter for the full
  dynamic hard-sign comparison.
- Added annual demographic-shock support to `run_annual_political_transition_fail_safe.m`:
  `DemographicScenario = source_path | flat_entrant | baby_boom | secular_decline`.
  Non-source paths shock age-25 entrants, mechanically age older cohorts forward with
  annual survival, and normalize each annual age vector before voting.
- Added `original_annual_political_re/annual_political_demographic_shock_workflow.md`.
  Local `T = 4` smokes passed for both `baby_boom` and `secular_decline` at
  `eta = 0.105`, with max vote residuals around `0.00505` and `0.00517`. Added Hamilton
  stages `T80Boom` and `T80Decline` for full annual checks.
- Added `original_annual_political_re/annual_political_re_paper_workflow.md` to organize
  the paper route: benchmark eta, smoothing/no-smoothing robustness, random-price
  comparison, demographic shocks, figures, and blue write-up edits.
- Added blue draft inserts to `Gross and Chivers (2025) NIMBYism and the Housing Supply.lyx`.
  The additions describe the annual transition motivation, smoothed political-pressure
  rule, pressure equation, annual-age demographic shock interpretation, and the role of
  random-price and hard-sign diagnostics. These are draft paper edits pending final
  benchmark and graph results.
- Added local diagnosis packet:
  `original_annual_political_re/annual_political_pass_through_diagnosis_20260425.md`.
- Added local Hamilton checker:
  `original_annual_political_re/check_annual_political_hamilton_ladder.ps1`.

---

### Session: 2026-04-24 (smoothed political RE tail workflow)
- Active side worktree: `C:\Users\Dave_\AI\.claude\worktrees\nimby_smoothed_permits`
  on branch `codex/nimby-smoothed-permits`.
- Current target is the original 5-year political RE transition under smoothed voting and a
  supply-wedge continuation in `original_5yr_political_re/`.
- The accepted `k = 10` seed remains
  `truth/joint_supply_wedge/local_smoothk14_full_s020_relaxed/k10/`.
- Added a tail-active frozen-prefix mode: the known-good prefix is fixed exactly, the unlocked
  tail is forced into the political residual, and tail/prefix vote and housing-gap diagnostics are
  written to the trace and summaries.
- Current live local run is `local_smoothtail_tailactive_s020_k11_12_b2_i1`. It attaches to the
  accepted `k = 10` seed and tests whether periods `11` and `12` can be appended at
  `political_response_sigma = 0.20`.
- The bounded fail-safe wrapper is now a conditional overnight queue: finish/attach to the current
  `sigma = 0.20` tail-active run, append `k = [13, 14]` only from a real `k = 12` seed, try the
  analogous `sigma = 0.40` lane only if needed, then run one narrow `k = 11` diagnostic with a
  one-block tail wedge and deeper housing clearing if no lane reaches `k = 12`.
- If this bounded queue exhausts, the next strategic move is terminal/ghost-tail closure diagnostics
  followed by a stacked joint residual solve. Do not keep broad-restarting the ladder.
- Later in the session, Zac suggested simplifying the demographic process: make age-25 entrants
  the primitive path and let older cohorts age forward mechanically with deaths/survival. The
  smoothed-tail MATLAB processes and wrapper were stopped, and a stop marker was written to
  `truth/original_5yr_transition_smoothed_tail_fail_safe_live/stop.txt`.
- Added the entrant-survival demographic builder:
  `original_5yr_political_re/build_original_5yr_demographic_entrant_survival_path.m`.
  It supports `flat`, `baby_boom`, and `secular_decline` entrant paths with fixed five-year
  survival rates.
- Added a hard-sign runner for this lane:
  `original_5yr_political_re/run_original_5yr_joint_wedge_hard.m`.
  The first pass deliberately does not use political smoothing.
- Added a local bounded queue:
  `original_5yr_political_re/run_original_5yr_entrant_survival_hard_local_queue.ps1`
  and starter `start_original_5yr_entrant_survival_hard_local_queue.ps1`.
  Queue order is flat, baby boom, secular decline, each through `k = [2, 4, 6]`.
- Workflow decision rule updated after the first flat-path evidence: let the current
  hard-sign `k = 4` outer step finish. If final `k = 4` max vote residual stays around
  `0.10` or worse, stop the hard-sign queue and combine the entrant-survival demographic
  law with smoothed politics (`sigma = 0.20`) on the same short queue.
- The hard-sign entrant-survival queue was stopped before spending time on boom/decline:
  flat `k = 2` had max vote residual `0.0544`, but the `k = 4` stage-init value was back
  near `0.10`, so the marginal problem looked like the political kink rather than the
  demographic law alone.
- Added the smoothed entrant-survival local queue:
  `original_5yr_political_re/run_original_5yr_entrant_survival_smooth_local_queue.ps1`
  and starter `start_original_5yr_entrant_survival_smooth_local_queue.ps1`.
  It runs flat, baby-boom, and secular-decline entrant scenarios through `k = [2, 4, 6]`
  at `political_response_sigma = 0.20`.
- The smoothed local queue is currently running in
  `truth/entrant_survival_smooth_local_queue_live/`. The first hidden-launch attempt failed
  because Windows split the MATLAB path/`-batch` command; the wrapper now writes a small
  per-stage `.m` batch file plus MATLAB stdout/stderr logs before launching each stage.
- Early trace evidence from the corrected smoothed flat run is favorable but not yet a
  completed stage result: `k = 2` stage-init max vote residual is about `0.0060`, versus
  `0.0544` for the hard-sign flat `k = 2` result.
- The first smooth queue revealed a workflow bug, not just a model failure. Flat `k = 2`
  finished well (`vote = 0.00534`, `gap = 0.00115`), and flat `k = 4` opened with a
  very good stage-init point (`vote = 0.00232`, `gap = 0.00880`), but the run timed out
  because the subsequent wedge-search candidates were mostly worse. Boom `k = 4` showed
  the same pattern (`stage-init vote = 0.00257`, `gap = 0.00665`).
- Patched `run_original_5yr_transition_joint_supply_wedge_continuation.m` with an
  early-accept rule for smoothed politics: for `k >= 4`, accept stage-init immediately
  when `max_abs_vote <= 0.005`, `max_abs_gap <= 0.01`, and `merit <= 1e-4`.
- Restarted the clean early-accept ladder in
  `truth/entrant_survival_smooth_early_accept_local_queue_live/`.
- The first clean early-accept restart began at `k = 2`, but this was redundant because
  the smooth `k = 2` seed had already been computed. That run was stopped, the long-path
  seed files were copied into `truth/seeds/flat_s020_k02_price.csv` and
  `truth/seeds/flat_s020_k02_wedge.csv`, and the queue was restarted from `k = 4`.
- Active flat run tag: `local_entsurv_smooth_ea_s020_flat_k4_14_i1`, with
  `k_schedule = [4, 6, 8, 10, 12, 14]`.
- Verified early-accept behavior at `k = 4`: stage-init produced `vote = 0.00232`,
  `gap = 0.00880`, and `merit = 3.24e-5`; the early-accept gate fired and the ladder
  moved directly to `k = 6`.
- After user pushback, clarified the workflow distinction: the immediate objective is a
  probe ladder to `k = 14`, not solving/improving every rung. The `k = 6` solve ladder
  was stopped and the continuation code now supports `stage_init_accept_mode =
  'stage_init_only'`, which records exactly one stage-init evaluation per rung and moves
  on.
- Active probe run tag: `local_entsurv_smooth_probe_s020_flat_k4_14`.
  It uses the saved `k = 2` seed, evaluates `k_schedule = [4, 6, 8, 10, 12, 14]`, and
  has already verified `k = 4` probe acceptance with `vote = 0.00232`, `gap = 0.00880`,
  `merit = 3.24e-5`.
- The stage-init-only flat probe completed through `k = 14`. Results: `k = 4` vote
  `0.00232`, gap `0.00880`; `k = 6` vote `0.04048`, gap `0.01385`; `k = 8` vote
  `0.03400`, gap `0.00512`; `k = 10` vote `0.15609`, gap `0.00920`; `k = 12` vote
  `0.15808`, gap `0.00669`; `k = 14` vote `0.15808`, gap `0.00677`.
- Interpretation after completion: the ladder mechanics and housing/price clearing are not
  the main failure. The first sharp break is the political/tail residual at `k = 10`.
  Next work should target `k = 10` from the good `k = 8` probe seed before spending time
  on broad restarts or boom/decline paths.
- Literature check on the proposed continuation-tail defence found it is consistent with
  standard perfect-foresight transition practice: solve on a longer horizon than the reported
  shock window, then verify reported periods are invariant to further horizon extensions.
- Patched `run_original_5yr_transition_joint_supply_wedge_continuation.m` with an optional
  objective horizon. When set, the inner solve can use a longer internal horizon while
  political residual scoring and wedge updates are based only on the first `objective_horizon`
  periods. This enables a direct ghost-tail test.
- Added and launched the bounded ghost-tail diagnostic:
  `original_5yr_political_re/run_original_5yr_ghost_tail_diagnostic.ps1` via
  `start_original_5yr_ghost_tail_diagnostic.ps1`. Live root:
  `truth/ghost_tail_k10_live/`. It copies the good `k = 8` probe seed into
  `truth/seeds/flat_probe_s020_k08_price.csv` and
  `truth/seeds/flat_probe_s020_k08_wedge.csv`, then runs `G = [0, 2, 4, 6]`
  with internal horizons `H = [10, 12, 14, 16]`, objective horizon `10`,
  smoothed politics `sigma = 0.20`, `basis_count = 4`, and one strict outer iteration.
- Added and launched a bounded watchdog:
  `original_5yr_political_re/watch_original_5yr_ghost_tail_diagnostic.ps1` via
  `start_original_5yr_ghost_tail_diagnostic_watchdog.ps1`. It checks the same live root
  every five minutes, does not launch duplicates while the runner or MATLAB process is
  alive, and relaunches the bounded queue only if both disappear before completion.
  Watchdog status: `truth/ghost_tail_k10_live/watchdog_status.json`.
- The ghost-tail diagnostic later completed/ended. `G = 0` and `G = 2` timed out without
  summaries; `G = 4` completed with target-window vote `0.09062`, target gap `0.01924`,
  full/ghost vote `0.17195`; `G = 6` did not write a summary. This suggests continuation
  tails help but do not resolve the political residual, and the continuation tail itself
  remains politically imbalanced.
- Added `original_5yr_political_re/audit_original_5yr_political_vote_composition.m`.
  The audit recomputes a detailed political path for a saved price/wedge path and writes
  period, period-age, and period-group CSVs under `truth/political_vote_audit/`.
- Ran the audit on the entrant-survival `k = 10` probe path:
  `truth/political_vote_audit/vote_audit_probe_k10_s020/`. Worst period is 1990/period 9
  with vote `+0.15808`. The residual is dominated by old homeowners: age 90 mass is
  `0.4243` and contributes `+0.0831`; old owners have mass `0.8400` and contribute
  `+0.1469`; very old owners have mass `0.7635` and contribute `+0.1400`.
- Ran the same audit using historical age shares on the same price/wedge path:
  `truth/political_vote_audit/vote_audit_probe_k10_hist_s020/`. Worst vote falls to
  `+0.12345`, age 90 mass is `0.1349`, and old-owner contribution is `+0.0940`.
  Interpretation: the entrant-survival simplification creates an exaggerated terminal
  old-age pile-up, but even historical age shares leave a large old-homeowner residual and
  very weak renter counterweight. Next useful work is a demographic/ownership composition
  sanity check, not another broad solver ladder.
- Important correction: the transition solver's `build_target_age_masses` used
  `cohort_scale_by_age(1,:)` as the baseline, which equals a vector of ones. This made
  baseline voter age bins effectively equal-sized rather than weighted by actual
  `population_by_age`. Patched `extensions/re_no_politics/solve_transition_re_no_politics.m`
  so that, when `demographic_path.population_by_age` exists, age masses are built from
  row-normalized population counts/shares directly.
- Added named terminal-age demographic variants through
  `build_original_5yr_demographic_entrant_survival_path.m`, including
  `flat_terminal_exit` and suffixes like `flat_terminal_s025`, so the `90+` bin can be
  stress-tested without changing the default entrant-survival law.
- Re-ran the `k = 10` vote audit after the population-weight fix. On the saved old
  entrant-survival flat price/wedge path,
  `truth/political_vote_audit/vote_audit_probe_k10_s020_popweights/`, worst vote falls to
  `+0.09393` at period 10. The age-90 mass is now around `0.047` in period 10 rather than
  the previous artifact `0.424` in period 9. However, the saved price path is no longer
  housing-clearing under corrected age masses: the one-pass audit shows gaps around
  `0.05-0.06`.
- Terminal-exit stress test on the same path,
  `truth/political_vote_audit/vote_audit_probe_k10_s020_popweights_terminal_exit/`, gives
  worst vote around `+0.09192`. This means terminal-bin survival is not the main remaining
  issue once age masses are corrected.
- Corrected historical-age audit on the same path,
  `truth/political_vote_audit/va_k10_hist_pw/`, gives worst vote `+0.08689`. The remaining
  issue is not a giant `90+` pile-up; it is broad pro-high-price owner preferences plus
  almost no renter counterweight after age 25. Next solver work should rerun the ladder
  fresh under corrected population weights, starting with a short `k = [4, 6, 8, 10]`
  probe.
- A follow-up policy check on
  `truth/political_vote_audit/vote_audit_probe_k10_s020_popweights/` shows that the lack
  of older renters is not just pre-decision audit timing. Ages 65-85 choose essentially
  zero owner mass into the renter state in periods 8-10; age 90 sells about `13-16%` of
  owner mass into renting. The transition household code has explicit bequest parameters
  (`bequestweight1`, `bequestweight2`) and no medical/health/liquidity shocks, so a
  plausible next robustness is a weak-bequest/no-bequest or late-life expense shock proxy
  before interpreting the remaining positive vote as a true political corner.
- Added and ran
  `original_5yr_political_re/audit_original_5yr_political_empirical_tenure_counterfactual.m`
  on the corrected `k = 10` audit MAT file. This is a mechanical counterfactual, not an
  equilibrium solve: it keeps the saved value-function responses and age masses fixed, then
  replaces owner/renter shares with empirical homeownership rates by age. Result:
  actual max vote `0.09393`; all-age empirical tenure reweight `0.08860`; `65+`-only
  reweight `0.08599`; `75+`-only reweight `0.08757`. Interpretation: forcing the
  age-tenure distribution toward the data helps only modestly, so it is not defensible to
  say that the model would solve if ownership by age matched the data. The remaining issue
  is broader: even synthetic renter tails often still have positive permit/price responses
  on the saved path, and the value-function incentives remain pro-high-price in late periods.
- Added and ran
  `original_5yr_political_re/audit_original_5yr_political_preference_shift_counterfactual.m`.
  It keeps the saved path fixed and asks what additive shift inside the smoothed voting
  index would set each period's equal-weight vote to zero. On the same saved corrected
  `k = 10` path with `political_response_sigma = 0.20`, the required late-period shift is
  about `-0.038` (`-0.0379` in 1990 and `-0.0380` in 1995). This is a more promising
  diagnostic than ownership reweighting, but it still has to be rerun on a fresh
  housing-clearing corrected path before being used as an equilibrium story.
- Patched
  `original_5yr_political_re/run_original_5yr_transition_joint_supply_wedge_continuation.m`
  so the local demographic truncation preserves `population_by_age`. This is necessary
  because the corrected voter-age mass logic in `solve_transition_re_no_politics.m`
  only fires if that field reaches the solver.
- Added and launched the hidden local corrected decision workflow:
  `original_5yr_political_re/run_original_5yr_corrected_parallel_decision_workflow.ps1`
  and
  `original_5yr_political_re/start_original_5yr_corrected_parallel_decision_workflow.ps1`.
  Live status:
  `original_5yr_political_re/truth/corrected_parallel_decision_live/latest_status.json`.
  It runs the corrected flat entrant-survival smoothed probe `k = [4, 6, 8, 10]`,
  `sigma = 0.20`, `stage_init_only`, using the saved `k = 2` seed.

---

### Session: 2026-03-16 (extension completion cleanup)
- Clarified project intent after runtime validation: the interesting experiment is not the current
  steady-state no-politics closure. The main target is a demographic forecast with rational
  expectations over house prices along the transition path, under the simplification of no voting
  coalitions.
- Added the first transition-path RE scaffold files:
  `run_demographic_forecast_re_no_politics.m`,
  `build_demographic_path_from_age_state_csv.m`,
  `solve_transition_re_no_politics.m`, and
  `update_price_path_re_no_politics.m`.
- Verified that the transition scaffold runner executes in MATLAB, resolves the transition matrix
  correctly, and saves `transition_re_no_politics_scaffold.mat`. The remaining missing piece is the
  actual household transition solve and forward distribution update inside the placeholder solver.
- The scaffold now uses a real demographic path from `code/data/age state.csv` rather than a fake
  placeholder path. On the current mapping, the aggregate cohort-scale path over 2010-2018 is
  approximately `[1.000, 1.014, 1.031, 1.046, 1.063, 1.080, 1.097, 1.116, 1.133]`.
- Upgraded the transition scaffold into a real first-pass backward-forward transition solver.
  `run_demographic_forecast_re_no_politics` now performs one RE update step: solve given a guessed
  price path, simulate demand forward, and compute an implied next price path. Runtime on this
  machine is long (about 20 minutes for the 2010-2018 path), and the first-pass update is not yet
  stable enough to claim convergence.
- Fixed a timing bug in the forward transition pass: the extension now applies period-`t` policy
  rules before aging households and applying the `z` transition, matching the baseline steady-state
  logic rather than incorrectly using `t+1` policy indices.
- Fixed a scaling problem in the transition supply block: instead of carrying over the arbitrary
  steady-state benchmark value `Hbar = 5`, the transition experiment now auto-anchors `Hbar` to the
  household block's baseline housing demand at the initial reference price. On this machine, that
  anchor is `Hbar = 0.038416` at `Pbar = 2.0`.
- Runtime verification result after the supply normalization fix: the default one-step RE update no
  longer collapses prices. Starting from a flat path at `2.0`, the implied path moves roughly in
  the range `1.91` to `2.17`, and the damped updated path moves to roughly `1.98` to `2.04`, with
  max absolute gap about `0.1678`.
- Added a bounded log-price update to prevent multi-iteration blowups. This keeps iterates from
  exploding mechanically, but a 3-iteration test still did not converge, so the next hard step is a
  more robust fixed-point/update scheme rather than more scaffolding.
- Added period-by-period transition diagnostics to the saved results object: housing demand,
  housing supply at the guessed and updated price paths, excess demand, and raw/smoothed log-price
  residuals by period.
- Added smoothing and a terminal anchor inside the price-path update. On this machine, the default
  one-step run now reports max smoothed RE price gap about `0.1518`, and the worst excess-demand
  period in the first pass is `t = 3` with excess demand about `0.003223`.
- A 3-iteration test with the smoothed bounded update still did not converge, but it no longer
  blows up immediately. The final test path stayed in a bounded range of roughly `1.90` to `2.00`,
  while the largest residuals shifted into middle/late periods rather than the terminal date alone.
- Replaced the local smoother with a regularized whole-path log-price update. The solver now
  smooths in log space and solves for the updated path with a curvature penalty plus a terminal
  anchor, which is a materially better approximation to a real transition-path fixed-point step.
- Runtime verification result after the regularized log update: a 3-iteration test remained bounded
  with final prices roughly `1.917` to `1.991`, and the smoothed log residuals became much more
  coherent than under the previous level-smoothing scheme.
- A 5-iteration test still did not converge in residual space, but the path stayed numerically
  stable and close to the original level range rather than exploding. That suggests the remaining
  issue is localized bad residual periods, not total failure of the transition solver.
- Added targeted residual correction to the price updater and expanded `iteration_log` to track the
  worst gap period and worst excess-demand period each iteration.
- Runtime note after targeted correction: the default one-step run now identifies periods `2-4` as
  the main first-pass problem area, with period `3` still the worst excess-demand date.
- A 5-iteration run still did not converge, but the new iteration log shows the problematic dates
  migrating across the path rather than remaining fixed at the terminal period. That is useful for
  the next stage, which should likely move from whole-path heuristics to block or sequential solves.
- Reclassified the current no-politics steady-state object as a side benchmark worth keeping for
  reference/debugging, but not the main quantitative exercise.
- Confirmed that `extensions/re_no_politics/` now contains both completed first-pass extensions:
  `solve_ss_no_politics.m` / `ClearMarkets_no_politics.m` / `run_re_no_politics_extension.m` and
  `solve_ss_coalition.m` / `compute_coalition_vote.m` / `ClearMarkets_coalition.m` /
  `run_political_coalition_extension.m`.
- Converted both `ClearMarkets_*` drivers from scripts into MATLAB functions so the runner wrappers
  can call them without relying on script execution in a function workspace.
- Updated the extension README plus project `STATUS.md` to reflect that the solver copies exist and
  the immediate next step is runtime validation rather than initial implementation.
- Runtime note: `TransitionMatrix.mat` for this project does exist on `D:\research_data\zac_and_david\Code\SteadyState\TransitionMatrix.mat`.
  The first Matlab failure came from path precedence: Matlab loaded another `TransitionMatrix.mat`
  lacking `initialdist`, so the extension now needs to resolve the steady-state file explicitly.
- Runtime verification result: `run_re_no_politics_extension` completed successfully once the loader
  was changed to resolve a usable transition bundle explicitly. On this machine, the working source
  file for `transitionmatrix`, `y_mid`, and `z_lifecycle` is
  `C:\Users\Dave_\Dropbox\Zac and David\Code\Codes_ABB\TransitionMatrix.mat`; `initialdist` is then
  sourced separately (or reconstructed if needed). The imported `D:\research_data\zac_and_david\Code\SteadyState\TransitionMatrix.mat`
  alone is not sufficient because it lacks `y_mid` and `z_lifecycle`.
- Runtime verification result: `run_political_coalition_extension` also completed successfully with
  the same transition-matrix loader. On the current 30-point price grid, the best coalition result
  was at price `1.8276` with weighted vote `-0.4875` and distance `0.2376`.
- Matlab became callable later in the session via the full executable path, and the no-politics
  extension runner was executed successfully after the transition-matrix loader fix.

### Session: 2026-03-13 (extension workspace, coalition direction, and portability pass)
- Created extension workspace at `extensions/re_no_politics/`.
- Added `implementation_plan.md` and `run_re_no_politics_extension.m` to separate the no-politics RE path from the published baseline code.
- Added `political_coalition_extension.md` and `compute_coalition_vote.m` for a first political-side extension that makes NIMBYism stronger via coalition-weighted voting rather than equal vote weights.
- Added `ensure_external_matlab_data_paths.m` in both `code/steadystate/` and
  `code/codes_abb/`, and updated the main MATLAB entry files to call the helper before loading
  external `.mat` assets.
- Updated `code/data/merge data.do` to try `D:\research_data\zac_and_david\Data` first and
  then fall back to `C:\Users\Dave_\Dropbox\Zac and David\Data`.
- Practical next step if coding continues: validate the extension entry points in MATLAB and decide
  whether the baseline `d_a_price` rent leak should be fixed upstream or left as an extension-only correction.

### Session: 2026-02-23 (single canonical status tracker)
- Added canonical tracker: `projects/02_nimbyism_and_housing_supply/STATUS.md`
- Set rule that "where are we" and to-do updates should be made in `STATUS.md` first.

### Session: 2026-02-22 (workflow note)
- Checked for WSL path artifacts in this project (`/mnt/c`, bash shebangs, Linux-only path assumptions): none found.
- Preferred shell for this project is PowerShell/Windows because core tooling is MATLAB + Stata + LyX on Windows paths.
- If doing PDF-heavy extraction/search work, consider running those specific tasks in WSL tools, while keeping core project runs in PowerShell.

### Session: 2026-02-19 (repo reorganisation)
- Project moved from `PaperProjects/02_nimbyism_and_housing_supply/` to `projects/02_nimbyism_and_housing_supply/`
- `README.md` and `memory.md` created as part of workspace standard
- No changes to paper content

### Session: 2026-02 (initial setup — nimbyism-housing-supply branch)
- Project imported from Dropbox (selective copy; large data/mat files excluded)
- MATLAB scripts, Stata do-files, figures, literature, slides, submission files present
- LyX source and published PDF present
- Setup plan documented in `PROJECT_PLAN.md` (now archived to `_playground/nimbyism_setup_plan.md`)

---

## Key files

| Role | Path |
|---|---|
| Paper source (LyX) | `projects/02_nimbyism_and_housing_supply/Gross and Chivers (2025) NIMBYism and the Housing Supply.lyx` |
| Published PDF | `projects/02_nimbyism_and_housing_supply/Gross and Chivers (2025) NIMBYism and the Housing Supply.pdf` |
| MATLAB steady-state | `projects/02_nimbyism_and_housing_supply/code/steadystate/SolveSS.m` |
| Stata data pipeline | `projects/02_nimbyism_and_housing_supply/code/data/merge data.do` |
| Upstream fix log | `projects/02_nimbyism_and_housing_supply/UPSTREAM_FIX_LOG.md` |
| Referee reports | `projects/02_nimbyism_and_housing_supply/referee/Economic Journal Referee Reports.docx` |

## Upstream relationship

This project is upstream of `03_Fertility_and_Housing_Supply`.
Any fix found here that affects the model structure should be:
1. Applied here
2. Logged in `UPSTREAM_FIX_LOG.md`
3. Evaluated for porting to project 03 via `03/.../UPSTREAM_SYNC_LOG.md`

## What is excluded (large files not in repo)

- All `.mat` files (MATLAB intermediates, ~6 × 161MB each)
- All `.dta` files (Stata binary data — regenerable from `.do` scripts)
- Previous draft versions (v1–v12 of the LyX file)
- Raw data subfolders (Buildings/, CPS age data/, IPUMS*, Maps/)

## Key conventions

- LyX is the authoritative paper format.
- MATLAB code in `Codes_ABB/` follows Arellano-Blundell-Bond notation.
- Do NOT commit `.mat` or `.dta` files (already in `.gitignore`).
- Shell preference for this project: PowerShell first; use WSL selectively for PDF-heavy utilities.
