# Project Memory - NIMBYism and the Housing Supply

Most recent session first.

---

### Session: 2026-05-14 (Moll direct price-beliefs implementation)
- Built `drafts_re/moll_direct_price_beliefs/workbench/` to compare the main
  Moll-consistent avenues using available small outputs. The workbench confirms
  that bounded T40 is only a temporary-equilibrium/prototype baseline. Route B,
  least-squares learning over a direct age-price law, remains the main
  Moll-aligned candidate because it keeps direct price beliefs, a low-dimensional
  public age signal, and feedback from realized model prices.
- Workbench smoke metrics: temporary bounded T40 baseline RMSE log price
  `0.000645268674443`; recursive age-price learning RMSE
  `0.000344809404341`; restricted-perceptions/static heuristic RMSE
  `0.000355376384361`; price-only AR(1) RMSE `0.000230369031896`. The lower
  AR(1) smoke RMSE is not decisive because it removes the demographic channel.
- Created and uploaded the Hamilton Moll packet:
  `run_moll_direct_price_beliefs_0514.m`, `model_moll_direct_0514.csv`,
  `bb80moll_0514.slurm`, `workflow_moll_direct_0514.md`, and
  `closeout_moll_direct_0514.py`.
- Submitted Hamilton job `17152180` (`bb80moll14`, array `1-5`, six-hour wall)
  from `/nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual`. Rows cover
  Route A temporary equilibrium, Route B direct price-law learning, two Route C
  restricted-perceptions heuristics, and Route D price-only AR(1). Early check:
  all five rows were running; early logs showed only the known missing
  projection-variable warnings from `old_paper_source_min.mat`.
- Closeout command after completion:
  `python3 closeout_moll_direct_0514.py --annual-dir .`. Treat these outputs as
  direct price-belief diagnostics, not full rational-expectations rows.

---

### Session: 2026-05-14 (safeguarded full T80 RE final closeout)
- Hamilton job `17145335` (`bb80safe13`, array `1-5`) hit the 13-hour wall on
  all five tasks. Final closeout with
  `closeout_re_safeguard_0513.py --annual-dir . --final` found no usable
  headline full-T80 RE row.
- Best visible row is `sg80_flat_trust12`, route
  `full_t80_safeguarded_polish`, gap `0.00190273652098779` at outer `4`,
  verdict `survivor`. The other safeguarded rows remain survivors at
  `0.00284389447561411`. Missing rows: none.
- Interpretation: the safeguarded full-T80 route is closed as a miss. Do not
  report a headline full-T80 RE figure from this packet.
- Prepared next solver remains unsubmitted: `run_re_lm_0513.m` and
  `bb80relm_0513.slurm`. Launch it only if the user explicitly chooses to
  continue full-RE compute after this miss.

---

### Session: 2026-05-13 (full RE plus bounded price-expectations route)
- User decision after reading Moll's rational-expectations challenge: keep the
  full T80 RE search alive, but also explore the bounded/direct
  price-expectations result as a serious separate model route.
- Added `drafts_re/bounded_price_expectations_route.md` to define the route:
  `bound40_baby_rss_l4` is a usable finite-horizon price-belief equilibrium
  candidate, not a full T80 perfect-foresight result and not a relabeling of
  failed full RE.
- Updated `STATUS.md` next tasks so job `17145335` remains the live full-RE
  monitor target while bounded 40-year expectations gets its own validation
  path.
- Built the first bounded-route artifact under
  `drafts_re/bounded_price_expectations/`: a 40-reported-year comparison of
  `bound40_baby_rss_l4` against `nore80bv4_006`, plus validation and plotted
  data. The validation recomputes the report-horizon gap as
  `0.000990326504390731`, matching the ranked gap up to rounding. The bounded
  route is usable but not paper-safe and must not be called full RE.
- After re-reading Moll, corrected the interpretation: bounded T40 is not what
  Moll prescribes. Added `drafts_re/moll_direct_price_beliefs/criteria_audit.md`
  and `candidate_routes.csv`. The actual Moll-aligned route is a restricted
  direct-price-belief equilibrium with a low-dimensional price forecasting rule,
  empirical discipline, and feedback from realized model prices into beliefs.
  The existing `extensions/re_no_politics/run_linear_age_price_rule.m` is the
  closest code template, but it is not yet the annual political baby-boom
  implementation.
- Created `drafts_re/dual_route_14h_workflow.md`, a bounded 14-hour workflow
  for both routes. It monitors/closeouts `17145335`, allows at most one
  prepared LM/Gauss-Newton fallback after a final full-RE miss, and sets the
  Moll route as a restricted direct-price-belief implementation based on the
  existing linear-age price-rule pattern. The workflow file is a handoff/plan;
  it does not itself start new compute.
- Added `drafts_re/moll_direct_price_beliefs/route_options.md` to avoid
  over-reading Moll as a single prescribed method. Route B, least-squares
  learning over a direct price law, is the best immediate route; Route C,
  restricted perceptions/simple heuristics, is the main alternative; Route A,
  temporary equilibrium with measured/calibrated beliefs, is useful but
  incomplete without belief feedback; RL is future work.

---

### Session: 2026-05-13 (safeguarded full T80 RE polish)
- Submitted Hamilton job `17145335` (`bb80safe13`, array `1-5`, 13-hour wall)
  as the targeted follow-up to the wide packet. Files are
  `model_re_safeguard_0513.csv`, `bb80resafe_0513.slurm`,
  `workflow_re_safeguard_0513.md`, and
  `run_annual_political_full_re_price_path_safeguard_0513.m`.
- This is not another blind grid. Rows start from the best survivor
  `w80_b60hold_bl70` outer `4` (plus one `w80_flat_rss_b6` survivor check) and
  use best-anchor safeguarding plus capped trust-region log-price fixed-point
  updates. Rank with `rank_re_wide_0512.py --grid model_re_safeguard_0513.csv
  --out-dir truth/re_safeguard_0513`.
- Prepared a future fallback, not submitted while `17145335` is live:
  `run_re_lm_0513.m` plus `bb80relm_0513.slurm`. This is a sequential
  black-box LM/Gauss-Newton residual minimization around the best survivor and
  should be treated as the next genuinely different formulation if the
  safeguarded packet misses.
- C: is at/below the 20 GB guard, so future checks should avoid local
  downloads/builds and keep local writes tiny.

---

### Session: 2026-05-13 (wide T80 RE closeout)
- Hamilton job `17141699` (`bb80wide12`, array `1-40`) has finished or timed
  out at the 13-hour wall. Ranking with `rank_re_wide_0512.py` shows no usable
  full T80 target row.
- Best full target is `w80_b60hold_bl70`, route `full_t80_bridge_candidate`,
  gap `0.00101892245727956` at outer `4`, verdict `survivor`. It is narrowly
  above the `0.001` usable threshold and not paper-safe. Next rows are
  `w80_flat_rss_b6` gap `0.00108682802289991` and diagnostic
  `w80_pt004_b40` gap `0.00111768158539817`.
- Residual inspection shows the best target's largest generated-vs-guessed
  mismatch is in the hidden tail around periods `85-96`; the reported T80 gate
  is missed by only about `1.9e-05`. The next full-RE attempt should therefore
  be a safeguarded log-price fixed-point/homotopy solve from the best survivor,
  not another broad blind grid.

---

### Session: 2026-05-12 (eight-hour RE alternatives packet)
- Submitted Hamilton job `17115233` (`bb80alt12`, array `1-18`) from
  `/nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual`.
- Files uploaded from `drafts_re/hamilton_jobs/`: `model_re_alt_0512.csv`,
  `workflow_re_alt_0512.md`, `run_re_alt_0512.m`, `bb80realt_0512.slurm`,
  `rank_re_alt_0512.py`, plus the patched RE and no-RE annual solvers.
- The packet covers secular RE/no-RE, projected low-dimensional T80 PF,
  small-shock/local-linear diagnostics, partial-equilibrium PF holding no-RE
  prices fixed, and bounded 40/60-year forecast-horizon expectations.
- Immediate limitation and repair: official `projection_median` rows `6` and
  `7` first failed because `old_paper_source_min.mat` lacks `forecast_median`.
  Built `official_age_path_0512.mat` and `official_age_path_0512.csv` from
  `US Age Share Fine Grained.xlsx` using model ages 25-80 and years 2001-2100,
  patched the rows to `DemographicScenario = external_age_path`, and relaunched
  only rows `6-7` as Hamilton job `17115493`.
- Old failsafe closeout at 08:06 BST: job `17098151` (`bb80pff11`) finished or
  timed out with no usable T60/T80 row. Best visible row was
  `pff80_from40_f37`, gap `0.00160894640707105` at outer `13`; best T60 row was
  `pff60_f21_from40`, gap `0.00171620263714836`. Rows `7` and `12` timed out.
  This route did not clear the `0.001` usable threshold.
- Submitted stationary old-model RE benchmark job `17119202` (`bbssre12`,
  array `1-10`) after the user asked for the old model steady-state RE objects.
  This is not a full transition solve. It uses the compact old-paper source
  `old_paper_source_min.mat`, the patched annual RE solver
  `run_annual_political_full_re_price_path_basis_0507.m`, `SteadyState/Mod_Functions`,
  and `COMPECON`. Remote md5 for the source object is
  `79523aaf721ec337119daa0c64813458`, matching the local compact old-paper
  source. Rows cover baseline, permanent younger/high-entry, permanent
  low-entry/secular-ageing, and official 2050/2100 age profiles at pass-throughs
  `0.006` and `0.012`. Monitor with `rank_stationary_re_0512.py`; output is
  `truth/stationary_re_0512/`.
- Live 09:16 BST readout for the alternatives packet: no usable
  full-equilibrium row yet. Best visible row is `bound40_baby_rss_l4`, gap
  `0.00222049690605593` at outer `3`, verdict survivor. The visible secular
  and official-projection RE rows are still above usable, so they are not yet a
  paper route.
- Live 10:54 BST readout: `bound40_baby_rss_l4` crossed the usable threshold
  with gap `0.000990326504390953` at outer `7`. This is a bounded 40-year
  forecast-horizon expectations row with return-to-steady-state tail, not a
  full T80 perfect-foresight equilibrium and not paper-safe. Other live
  alternatives remain above usable; secular/official-projection RE rows are
  still around `0.0047` to `0.0105`, and stationary old-model RE has not yet
  written numeric terminal-anchor output.
- Live 11:24 BST readout: `bound40_baby_rss_l4` remains the only usable
  alternatives row. `bound60_baby_hold_l4` improved to `0.00141805693976858`
  but remains above usable. Stationary old-model RE pass-through `0.006` rows
  now have numerical outputs: relative to the stationary baseline case, the
  permanent younger/high-entry profile changes price by `-0.001534%`, the
  low-entry/secular-ageing profile by `-0.008640%`, official 2050 by
  `-0.006164%`, and official 2100 by `-0.007117%`. These stationary price
  effects are economically tiny, while homeownership varies materially across
  the profiles. Pass-through `0.012` stationary rows are still running.
- Live 11:59 BST readout: stationary old-model RE job `17119202` closed
  partially. Rows `1-5` at pass-through `0.006` completed cleanly; rows `6-10`
  at pass-through `0.012` timed out at the two-hour wall with no numeric
  terminal anchors. Alternatives still have only the bounded T40 usable row;
  `bound60_baby_hold_l4` improved to `0.00131638034539127` but remains above
  usable.
- Final 14:59 BST alternatives closeout: jobs `17115233` and `17115493` are
  done. Only `bound40_baby_rss_l4` cleared usable, with gap
  `0.000990326504390953`; it is a bounded 40-year forecast-horizon expectations
  result with return-to-steady-state tail, not a full T80 perfect-foresight
  equilibrium and not paper-safe. `bound60_baby_hold_l4` stopped at
  `0.00129819162075221`, projected T80 rows remained at `0.002166` or worse,
  and the best secular/official projection RE rows remained above usable
  (`0.00324` to `0.00361` for pass-through `0.006`). The heartbeat monitor was
  deleted after this final verdict.

---

### Session: 2026-05-11 (T80 model grid and perfect-foresight continuation)
- First-wave T80 model grid job `17084463` (`bb80mg11`) and continuation job
  `17087303` (`bb80pfc11`) are running on Hamilton under
  `/nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual`.
- Meaningful continuation result at 19:05 BST: `pfh40_tail80_pt006_ttb4`
  cleared the usable threshold with gap `0.000960075941637735` at outer `8`;
  `pfh20_tail80_pt006_ttb4` also cleared with gap `0.000985200745180424` at
  outer `9`. These are usable, not paper-safe.
- `pfh60_tail80_pt006_ttb4` is still just above the usable threshold at
  `0.00108147857180333`. T80 amplitude-continuation rows are still survivors
  around `0.00150894920957352`.
- The primary T80 grid has not cleared: best remains `re80tail80_pt006_ttb4`
  gap `0.00150894920957352`, with latest visible outer worse at
  `0.00185360668754506`. Current paper implication: usable staged
  perfect-foresight bridge at T20/T40, but no usable T80 robustness figure yet.
- Continuation closeout at 23:35 BST: job `17087303` is closed. T20/T40 remain
  the only usable continuation rows (`pfh20_tail80_pt006_ttb4` best
  `0.000930287456276735`, `pfh40_tail80_pt006_ttb4` best
  `0.000960075941637735`). T60 stopped short at `0.00104819991480841`, T80
  amplitude continuation stayed above usable, and rows `3`/`6` timed out. The
  remaining live T60/T80 routes are bridge/polish `17097472` and failsafe
  packet `17098151`.

---

### Session: 2026-05-05 (current-price cohort figure correction)
- Visual audit caught a real error in the baby-boom cohort figure: the
  children net-worth line in the current-price/no-RE panel was still too high.
- Source check showed the issue was not cosmetic smoothing. The solved
  no-RE/current-price output `oldbase_no_re_0505/obn006_0505` moves the house
  price above steady state early in the transition, while the original paper
  current-price benchmark moves it below steady state. That direction mismatch
  mechanically changes cohort net worth.
- Patched `figures/re_transition/build_matched_transition_figures.py` so the
  current-price benchmark defaults to the old paper current-price transition
  series from `D:\AI_storage\spillover\nimby_re_fig_inputs\old_paper_series.csv`.
  The solved no-RE output can still be forced with
  `--use-solved-no-re-current-price`, but it should not feed paper figures
  until the pass-through/sign issue is resolved.
- Regenerated `fig_matched_baby_boom_transition` and the baby-boom cohort
  figures. The current-price cohort panel no longer has the large
  child-above-boom gap from the bad solved no-RE output; a tiny terminal
  crossing remains because it is present in the original paper source itself.
- Updated the LaTeX blue text to describe the dashed line as the original
  current-price benchmark, not as a completed smoothed no-RE fixed-point solve.
- Follow-up audit after user challenge:
  `old_paper_series.csv` is an exact export of the original
  `D:\research_data\zac_and_david\Code\SteadyState\Mod_IRF\irfs_smoothed.mat`
  variables used by `PlotIRFs.m` (`networth_boom_smoothed`,
  `networth_child_smoothed`, `networth_parent_smoothed`,
  `consumption_boom_smoothed`, etc.). Max absolute CSV-vs-MAT difference in
  the net-worth cohort variables is about `5e-15`.
- The old source itself has a very small child-above-boom net-worth crossing
  only at the end of the overlapping life-cycle window: 2 overlapping years,
  max gap `0.000525` (about 0.05 percent). This is not the earlier error. The
  bad solved no-RE comparator had children above boom for 27 overlapping years
  with max gap about `0.01494`.
- The RE cohort figure uses the same original Smoother.m moving-window
  definitions: boom `1:t`, `t-10:t`, then `t:56`; children `1:t-25`,
  `t-35:t-25`, then `t-35:56`; parents `t+15:t+25`, then `t+25:56`. Child
  net worth above boom in the RE panel is therefore coming from the solved RE
  age path, not from the old no-RE comparator error or a plotting label swap.
- Code audit of the RE mechanism:
  `run_annual_political_full_re_price_path.m` solves household policies
  backward over the full price path. In `solve_price_path`, each period's
  policy uses the next period price in the expected continuation value, so the
  run is genuinely deterministic perfect foresight over house prices. The
  political vote object compares the value under the solved path with the value
  under a path shifted by `param.deltaPh`, not only a one-period current-price
  perturbation. This is defensible as a permit shock that changes the local
  price path, but it is a modelling assumption and should be stated or
  robustness-checked before the RE incidence result is treated as final.
- Implemented that robustness check in the full RE solver by adding
  `VoteShiftMode`. The default `path_shift` preserves the previous behaviour.
  The new `current_period` mode changes only the current-period vote price
  comparison and leaves future expected prices on the solved RE path. Local
  old-baseline T20 published-baby-boom checks completed for `eta = -0.003`,
  `-0.006`, and `-0.020`. All are numerical survivors, but the max vote
  residual remains about `0.045` across the grid while the path gap moves from
  about `0.0035` to `0.0201`. This suggests the current-period vote object is
  not fixed by eta tuning and is a different political experiment from the
  persistent path-shift object. A T80 Hamilton script
  `oldbase_re_T80_current_vote.slurm` is prepared but not yet submitted because
  local SSH to Hamilton timed out. A same-size T4 `path_shift` smoke passed
  after the patch with max vote residual about `0.0027`, so the default
  paper-figure branch still executes and the contrast is coming from the
  changed political object, not a syntax regression.
- Added a second RE robustness branch, `VoteShiftMode = 'finite_horizon'`,
  with `VoteShiftHorizon` controlling how many future years the permit/price
  perturbation affects before the value comparison returns to the solved RE
  price path. Local old-baseline T4 published-baby-boom smokes show the
  ordering clearly: full `path_shift` is clean (max vote residual about
  `0.0027`), current-period-only is poor (about `0.0444`), finite 5-year
  horizon is intermediate but still weak (about `0.0363`), and the finite
  10-year short-horizon smoke is dead (about `0.0538`). This reinforces the
  interpretation that the working paper branch is a vote over a persistent
  policy/permit-path effect, not a temporary price blip. A Hamilton script
  `oldbase_re_T80_finite_vote.slurm` is prepared for horizons 2 and 5 once
  Hamilton SSH is reachable.
- New figure-audit workflow: before putting any revised transition or cohort
  figure into the LaTeX paper, run independent checks of (1) input source and
  baseline object, (2) code definitions and labels, (3) visual robustness
  including smoothed versus unsmoothed panels and separate RE/no-RE panels, and
  (4) economic decomposition of cohort net worth against homeownership, owned
  housing, rental housing, and consumption. Canonical paper figures should not
  be overwritten while the audit is active; use
  `figures/re_transition/figure_robustness_checks/` for diagnostics.
- Figure audit results: the baby-boom RE figure pipeline now has three
  independent checks. No audit found a confirmed bug in the RE source object,
  old-baseline normalization, RE expectations logic, or owner/renter averaging.
  `NW`, `C`, `H`, `Rent`, and homeownership are full-distribution age means,
  not homeowner-only means. The main caution is conceptual/presentation:
  current cohort windows follow the old `Smoother.m` style and average selected
  age rows without within-window population weights, so a population-weighted
  cohort robustness figure should be created before final paper insertion. The
  robustness package under
  `figures/re_transition/figure_robustness_checks/baby_boom_re_obre80_e006/`
  confirms `NW = B + price * H` up to numerical noise and shows the RE
  children-above-boom net-worth feature is real in the current output
  (`22/31` overlapping periods, max gap about `0.0112`), but not driven by
  higher child homeownership or housing services (`0/31` periods above boom
  for both).
- Added population-weighted cohort robustness to the same diagnostic package.
  The check keeps the old moving cohort windows but weights ages within each
  window by period age shares, applying the same weights to the baseline age
  profile in the denominator. The RE children-above-boom net-worth feature
  survives: `23/31` raw overlapping periods and `22/31` smoothed overlapping
  periods, max gap about `0.0113`, while children remain above boom in `0/31`
  periods for homeownership and total housing services. This rules out
  unweighted age-window averaging as the explanation.
- Overnight workflow for the solved no-RE smoothed-politics comparator:
  positive-phi T4 smoke `smoke_no_re_posphi_T4_0505` passed locally and moves
  prices downward, unlike the earlier negative-phi no-RE run that moved prices
  above steady state. Started hidden local PowerShell process `45616` at
  `2026-05-05T22:50` running
  `figures/re_transition/figure_robustness_checks/run_overnight_no_re_smooth_politics_0505.ps1`.
  It runs the MATLAB script
  `D:\AI_storage\spillover\nimby_re_fig_inputs\ham_code\run_local_no_re_smooth_positive_overnight_0505.m`
  with a broad positive-phi T20/T80 grid, then 2-year and 5-year lagged
  pass-through T80 checks. The scoring script
  `figures/re_transition/figure_robustness_checks/score_no_re_smooth_politics.py`
  ranks candidates against the old current-price price path and political
  residuals. Status/log/outputs live under
  `figures/re_transition/figure_robustness_checks/no_re_smooth_politics/`.
  Hamilton script `oldbase_no_re_positive_T80.slurm` is prepared, but Hamilton
  SSH timed out when the workflow started.
- Referee-risk correction on `2026-05-06`: stopped the broad positive-phi
  overnight grid before it wrote T80 output because a main comparison based on
  freely chosen `rho`, `phi`, and `gamma` would be vulnerable to a referee
  criticism of arbitrary curve fitting. The completed T20 grid remains useful
  as a diagnostic only. Started the paper-safe locked no-RE run
  `locked_nore_smooth_phi006_T20_T80_0506`, with `rho = 0`, `gamma = 1`, and
  `phi = 0.006`, matching the selected RE pass-through magnitude rather than
  fitting the old current-price path. MATLAB process `27604` is running it
  locally.
- High-pass-through diagnostic started at user request: local MATLAB process
  `1792` is running `smoke_nore_high_phi_T8_0506` with `rho = 0`, `gamma = 1`,
  and `phi` in `{0.15, 0.25, 0.40}`. This is a deliberately aggressive
  diagnostic only. The prior completed T20 grid already showed `phi = 0.08`
  and `phi = 0.10` are dead with max vote residuals around `0.57`, so the
  likely role of this smoke is to document overshooting/cap behaviour rather
  than produce a paper comparator.

### Session: 2026-05-05 (figure pipeline diagnostic: current matched figures invalid)
- Follow-up action: patched
  `figures/re_transition/build_matched_transition_figures.py` so the
  baby-boom diagnostic uses the old paper's explicit `flip(boom)` birthrate
  path, the old paper 25-35 young-homeownership definition, and the
  `ss_eq.age` steady-state age profiles as cohort denominators when available.
  The original-vs-current diagnostic is exported to
  `figures/re_transition/paper_definition_checks/fig_compare_original_paper_vs_current_price_no_re`.
- Important diagnostic result after correcting definitions:
  the current matched no-RE run still does not match the old paper because it
  is a different model/source object. Its raw 25-35 homeownership is about
  `0.63`, while the original paper object's raw 25-35 homeownership is about
  `0.03` before the old paper's `+0.35` display shift. Average age matches
  exactly, so the demographic path is not the problem.
- Source-object audit: `loop101_output_extended.mat` is not a harmless
  re-export of the old paper calibration. Compared with the old paper
  `irfs_smoothed.mat` object, key parameters differ materially:
  `Ph_ss` about `6.06` versus `8.981`, `R` `1.025` versus `1.03`,
  `beta` `0.98` versus `0.95843`, `chi` `0.95` versus `0.72035`,
  `deltaPh` `1.01` versus `1.1`, `hmin` `0.5` versus `2.0367`,
  `kappa` `0.75` versus `0.5451`, and `psi_x` `300` versus `22.27`.
  This explains why the current RE/no-RE pair looks unlike the old paper:
  it is solving a materially different calibration, not just adding RE and
  political smoothing.
- Created compact old-paper source files in spillover so Hamilton does not
  need the full 3.2GB `irfs_smoothed.mat` source:
  `old_paper_source_min.mat`, `old_paper_baseline_age.csv`,
  `old_paper_birthrate.csv`, and `old_paper_price_path.csv`.
- Short old-baseline smooth-vote smoke passed locally using negative
  pass-through:
  `smoke_oldbase_smooth_negphi_boom_0505c`, with T4 max vote residuals about
  `0.0049`, `0.0059`, and `0.0065` for `phi = -0.006`, `-0.012`, and
  `-0.020`.
- Submitted Hamilton old-baseline full runs from
  `/nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346`:
  job `16947946` (`obnr80`) runs the T80 no-RE/current-price comparator with
  smooth voting and `phi` in `{-0.006,-0.012,-0.020}`; job `16947947`
  (`obre80`, array `0-2`) runs the T80 RE eta grid with `eta` in
  `{-0.006,-0.012,-0.020}` initialized from the old paper price path.
- Hamilton update: `16947947` (`obre80`) completed cleanly. All three T80
  old-baseline RE eta paths are numerically usable. Current read:
  `eta = -0.006` has max path gap about `0.00586`, max vote residual about
  `0.01682`, and mean homeownership about `0.42044`; `eta = -0.012` and
  `eta = -0.020` remain usable but have larger path gaps. This is a numerical
  survivor, not yet a paper-ready figure input, because the no-RE/current-price
  old-baseline control `16947946` is still running.
- Pulled the completed RE outputs and made diagnostic plots under
  `figures/re_transition/paper_definition_checks/`. Interpretation:
  the good RE path is plausible but not a magic resolution of the old RE
  difficulty. It starts from the old paper price path, uses very small path
  relaxation, and the strongest numerical survivor is the weakest pass-through
  case (`eta = -0.006`). The 80-year report horizon is clean enough for a
  candidate check; the extra terminal tail has larger vote residuals and should
  be treated only as a terminal-anchor device until further checked.
- Added and submitted a Hamilton no-RE fail-safe array:
  `original_annual_political_re/oldbase_no_re_single_T80.slurm` was uploaded
  as job `16953583` (`obnr1`, tasks `0-2`). Each task runs one old-baseline
  T80 no-RE candidate rather than waiting for the serial job `16947946` to
  finish all three candidates before writing output.
- Started one local no-RE insurance run for the weak-pass-through candidate
  only:
  `original_annual_political_re/run_local_obn006_T80_0505.m` launches
  `local_obn006_T80_0505c` with `phi = -0.006`. The first two local attempts
  failed before solving because local MATLAB paths did not expose
  `TransitionMatrix.mat` and `weightedMedian`; the active run now reaches
  `Running T=80 candidate 1/1`.
- Patched `figures/re_transition/build_matched_transition_figures.py` so run
  directories can be overridden from the command line. This lets the completed
  old-baseline RE survivor be paired with the first completed no-RE insurance
  candidate without editing constants.
- Hamilton old-baseline no-RE completion: serial job `16947946` and insurance
  array `16953583` completed cleanly and agree. Summary:
  - `phi = -0.006`: usable; max vote residual about `0.01042`, mean vote
    residual about `0.00452`, max log price move about `0.00287`, mean
    homeownership about `0.41853`
  - `phi = -0.012`: usable; max vote residual about `0.01227`, mean vote
    residual about `0.00850`, max log price move about `0.00646`, mean
    homeownership about `0.42170`
  - `phi = -0.020`: survivor; max vote residual about `0.02829`
- Pulled the Hamilton no-RE outputs to
  `D:\AI_storage\spillover\nimby_re_fig_inputs\matched_outputs\oldbase_no_re_0505`.
  Built the old-baseline baby-boom diagnostic pair using RE `eta = -0.006`
  and no-RE `phi = -0.006`; outputs are under
  `figures/re_transition/paper_definition_checks/oldbase_pair_0505/`.
  The diagnostic passes the core sanity checks: same old source object, same
  demographic shock, matching birthrate/average-age panels, no collapsed cohort
  profiles, and no recurrence of the high-homeownership wrong-source failure.
  The figure set still needs paper-level styling and a decision on the
  non-RE/current-price interpretation before insertion.
- Important correction: the generated `fig_matched_*` transition figures are
  not paper-ready and should not be treated as a rational-expectations update
  of the old paper figures.
- The main diagnostic:
  - the old published baby-boom object uses `param.Ph_ss = 8.981291721052`
    and `TargetVote = 0.391595468868`
  - the generated `pbpaper_0501`/`nrpaper_0501b` matched-output objects use
    `reference_price = 6.05757575757576` and `target_vote = 0.828928577413069`
  - this is a different steady-state object, not just a different graph
    normalisation
- The current figure builder also drifted from the old paper definitions:
  - it normalised price by the first simulated year rather than the published
    steady-state price
  - it plotted entrant weights from the simulated age distribution rather than
    the explicit published `flip(boom)` shock path
  - it built cohort panels from birth-year windows rather than the moving
    age-index windows in the old `Smoother.m`
- Sanity-check rule going forward:
  the no-RE/current-price line should broadly reproduce the old paper's
  temporary baby-boom shape once the same published demographic shock and old
  graph definitions are used. The RE line is allowed to differ because agents
  internalise the future price path.
- New guard added to
  `figures/re_transition/build_matched_transition_figures.py`: by default it
  refuses to build paper figures from runs whose reference price is not within
  2 percent of the published baseline `8.981291721052`.
- Small old-baseline no-RE smoke results:
  - old-baseline hard-vote, positive pass-through `phi = 0.09` blows up:
    vote residual around `0.58`
  - old-baseline hard-vote, small negative pass-through is numerically tame on
    T4: `phi = -0.006` gives max vote residual about `0.0092`
  - this shows the current reduced-form pass-through sign/strength is not a
    faithful replacement for the old paper's scalar market-clearing price
    solve
- Next modelling/graph step:
  rebuild the non-RE comparator as the old period-by-period market-clearing
  transition with the smoothed voting rule, then use that as the sanity-check
  comparator before rerunning or presenting any RE figures.
- Figure-builder patch after visual inspection:
  - cohort panels now use moving age-window definitions and report outcomes
    relative to a common age-specific benchmark rather than raw life-cycle
    levels
  - follow-up audit: the cohort housing-services panel now uses total housing
    services (`H + Rent`) for all cohorts. The prior implementation mixed total
    housing for the boom with owned housing for children/parents; because young
    households have near-zero steady-state owned housing, that produced a
    misleading children-above-boom spike in the current-price panel.
  - cohort homeownership has been removed from the main paper cohort figure.
    The original temporary-shock figure used net worth and consumption; raw
    homeownership rates mostly show the normal life-cycle rise in ownership,
    while indexed ratios are unstable for young cohorts with near-zero
    benchmark ownership.
  - independent read-only audit found the secular-decline figures in
    `figures/re_transition/` were still wrong-source outputs. The LaTeX paper
    now removes those figure insertions and keeps a blue placeholder until
    old-baseline secular RE/no-RE runs are regenerated.
  - the figure-builder defaults now point to the old-baseline baby-boom pair
    and refuse multi-candidate folders, so using `oldbase_no_re_0505/obnr80_0505`
    directly cannot silently stack all `phi` candidates into one figure.
  - the builder now applies an explicit centred smoothing window to plotted
    economic series by default, with `--no-series-smoothing` available for raw
    diagnostics and `--smooth-window` controlling the window length
  - current inspection version was regenerated with `--smooth-window 9`; this
    improves readability but does not replace the deeper paper-quality fix of
    recomputing outcomes on a smoothed price path
  - cohort figures are now also exported separately by expectations rule:
    `fig_matched_*_cohorts_re` and
    `fig_matched_*_cohorts_current_price`, because the combined six-line
    version is too cluttered for paper use

---

### Session: 2026-05-01 (superseded graph workflow lock)
- Superseded by the 2026-05-05 figure audit above. The intended comparison was
  to hold political smoothing fixed in both series and vary only expectations
  over demographic house-price changes. That remains the conceptual target, but
  the available solved no-RE/current-price output does not reproduce the old
  current-price direction for the baby-boom shock. Current paper figures
  therefore use the original current-price benchmark as the dashed comparison
  while the smoothed no-RE pass-through/sign issue remains unresolved.
- Do not treat older annual no-RE outputs as final paper comparators if they
  only smoothed the pressure-to-price mapping while leaving the vote itself as
  a hard threshold. They are diagnostics, not the matched paper line.
- Matched paper-output runs now landed locally:
  - `pbpaper_0501`: baby-boom deterministic RE, max path gap about `0.0261`
  - `nrpaper_0501b`: baby-boom current-price/no-RE comparator, max vote
    residual about `0.0058`
  - `sdpaper_0501`: secular-decline deterministic RE, currently at outer
    iteration `3` on Hamilton with max path gap about `0.0383`
  - `nrsd_0501`: secular-decline current-price/no-RE comparator, max vote
    residual about `0.0214`
- Remaining Hamilton jobs are refinements, not missing figure inputs:
  `16919098` (`bbfit`) is still testing baby-boom fixed-point refinements, and
  `16918661` (`sdpaper`) is still running later secular RE iterations. The
  first baby-boom refinement rows do not improve the current `0.0261` path gap;
  the longer-tail branch worsened by iteration `3`.
- Current graph-readiness rule after the 2026-05-05 audit:
  the matched baby-boom figures should use the original current-price
  benchmark until the smoothed no-RE comparator reproduces the correct
  price-path direction. Other transition figures, such as secular decline,
  forecast low/median/high, lag/pass-through, and tau/hard-vote robustness,
  should not be called final until their source object and comparator
  definitions are rechecked.
- Current paper/graph implementation notes:
  - the LaTeX model section now introduces the smoothed logit vote weight
    \(\Pi_\tau\), keeps \(\sigma\) as the location shifter, and describes the
    old hard-vote indicator as the \(\tau \to 0\) limit
  - the transition prose now describes the RE/current-price comparison without
    claiming final graph patterns before the matched outputs are available
  - the matched figure builder is
    `figures/re_transition/build_matched_transition_figures.py`; cohort panels
    average over 10-year parent, boom, and child birth-year windows
  - `sdpaper_0501` has been pulled locally to
    `D:\AI_storage\spillover\nimby_re_fig_inputs\matched_outputs\sdpaper_0501`;
    it is a secular-decline RE survivor with max path gap about `0.0383` at the
    latest synced row
  - `nrpaper_0501b` and `nrsd_0501` have now been pulled locally, so the
    matched paper figures can be generated without mixing old hard-vote panels
  - generated working paper figures live in `figures/re_transition/` as
    `fig_matched_baby_boom_transition`, `fig_matched_baby_boom_cohorts`,
    `fig_matched_secular_decline_transition`, and
    `fig_matched_secular_decline_cohorts` with `.eps`, `.pdf`, and `.png`
    outputs
  - the figure builder selects the latest available `outer_iter` before
    plotting, so multi-iteration RE output folders do not stack several paths
    into one 80-period figure
  - the LaTeX paper now inserts these as Figures 7--10; a spillover compile
    check is at `D:\AI_storage\spillover\nimby_latex_check\nimby_latex_check.pdf`
  - first baby-boom refinement reads do not improve the `0.0261` max path gap;
    keep checking the live Hamilton refinement jobs before locking the final
    numerical path, but the working paper figures can be drafted now

---

### Session: 2026-04-26 (annual full price-path RE and baby-boom tail diagnostic)
- User corrected the target object: the desired RE experiment is not just a
  political smoothing wrapper on realized/current prices. Households must solve
  against a future house-price path generated by demographic change and the
  political/supply response.
- Added the annual full price-path RE runner:
  `original_annual_political_re/run_annual_political_full_re_price_path.m`
  Core design:
  - guess a full annual house-price path
  - solve household Bellman equations backward using `P_t` and resale /
    continuation value at `P_{t+1}`
  - simulate the population distribution forward
  - compute smoothed political pressure and the generated price path
  - damp the guessed path toward the generated path until the path fixed point
    is credible
- Added Hamilton submission and watcher helpers for the annual full-RE lane:
  `submit_annual_full_re_price_path_hamilton.ps1`,
  `watch_annual_full_re_price_path_hamilton.ps1`, and
  `start_annual_full_re_price_path_watchdog.ps1`.
  The watcher is currently treated as secondary because recursive collection
  had path-length / shell-friction issues; manual Hamilton checks are safer for
  this lane.
- Important terminology lock for future sessions:
  earlier annual political-smoothing runs without future price-path Bellman
  expectations are controls, not the benchmark RE object.
- First full-RE Hamilton T4 checks:
  - fixed-age/no-demographic unit test passes with max path gap around `0.003`
  - secular decline passes once the terminal-anchor logic is in place, with max
    path gap around `0.019`
  - baby boom remains the blocker, with small vote residual but max path gap
    around `0.045`
- Current live Hamilton jobs:
  - `16894030`, stage `reT40_04261648`: T40 climb for the passers only
    (`fixed_age_share` and `secular_decline`)
  - `16894032`, stage `reT4BBTail_04261648`: baby-boom-only T4 check with a
    long tail so the temporary boom can end before the terminal anchor becomes
    decisive
- Current decision rule:
  if the baby-boom long tail materially lowers the path gap, climb the
  baby-boom case with that terminal-tail design. If it does not, stop spending
  horizon on the same fixed-point map and move to a path-level solver upgrade
  such as secant / Anderson / reduced path-root updates.

---

### Session: 2026-04-19 (reduced-path Jacobian branch and Hamilton relaunch)
- User asked for a genuinely different solver branch after several days of
  failing to beat the same full-horizon `k = 14` residual with targeted
  line-search variants.
- Recent literature sweep takeaway used for this redesign:
  the modern macro-computation literature points toward Jacobian /
  sequence-space / reduced-dimensional updates and away from more tiny local
  mask permutations.
- Added a new reduced-path Jacobian runner:
  `original_5yr_political_re/run_original_5yr_transition_reduced_path_jacobian.m`
  Core design:
  - treat the transition/Bellman block as a black box
  - parameterize the `k = 14` log price path with a small piecewise-linear basis
  - fix active political periods from the incumbent vote path
  - estimate a finite-difference Jacobian for those active residuals
  - solve a damped least-squares step
  - apply a trust region and a short scale ladder
- Added launcher:
  `original_5yr_political_re/run_original_5yr_transition_reduced_path_jacobian.ps1`
- Added workflow note:
  `original_5yr_political_re/workflow_original_5yr_transition_reduced_path_jacobian.md`
- Added Hamilton packet submitter:
  `original_5yr_political_re/submit_original_5yr_hamilton_reduced_path_packet.ps1`
- Important Hamilton fix:
  the old remote packet failures were traced to copying the tiny local
  placeholder `TransitionMatrix.mat` bundle. The correct Dropbox file is:
  `C:\Users\Dave_\Dropbox\Zac and David\Code\Codes_ABB\TransitionMatrix.mat`
  with size `116,819,684` bytes. The matching steady-state file is:
  `C:\Users\Dave_\Dropbox\Zac and David\Code\SteadyState\TransitionMatrix.mat`
  with size `8,792` bytes. The new Hamilton submitter now copies those exact
  files to the remote external root and exports `ZAC_DAVID_EXTERNAL_ROOT`
  inside each Slurm job.
- Submitted the first reduced-path Hamilton packet successfully:
  - `16835609` = `ham_k14_redjac_b3_i3_20260419_085405`
  - `16835610` = `ham_k14_redjac_b4_i3_20260419_085405`
  - `16835611` = `ham_k14_redjac_b4wide_i3_20260419_085405`
  - `16835612` = `ham_k14_redjac_b5_i4_20260419_085405`
  Local tracking file:
  `original_5yr_political_re/truth/hamilton_reduced_path_packet_latest.json`
- Local compute decision:
  do not start a second local MATLAB process for the new branch while the old
  `k = 14` normalization lane is still running. At branch-launch time, local
  free RAM was only about `2.5 GB`, so the safer split was:
  - local machine: keep the old lane alive
  - Hamilton: run the new reduced-path packet
- At handoff time:
  - local workflow status still shows
    `hist_k14_activeclusters_norm_i3`
  - Hamilton reduced-path jobs are running
  - no reduced-path result has landed yet

---

### Session: 2026-04-15 (targeted outer-update stabilization and overnight handoff)
- The whole-path outer safeguard is now implemented inside:
  `extensions/re_no_politics/solve_transition_political_bellman_nimby.m`
- New line-search metadata now flows through the bounded runner:
  `original_5yr_political_re/run_original_5yr_transition_political_bellman_bounded.m`
  summary CSVs now record:
  - `accepted_step_scale`
  - `accepted_update_mask`
  - `line_search_used`
  - `line_search_improved`
- The first trimmed whole-path safeguard result is now on disk:
  `original_5yr_transition_political_bellman_hist_k6_linesearch_trim_i2_summary.csv`
  with:
  - `political_update_rule = fixed_step_linesearch_reject`
  - `max_abs_vote = 0.0278386148549857`
  - `max_abs_gap = 0.00930727724494884`
  - `max_abs_political_step = 0`
  Practical implication:
  the safeguard stopped the bad second step, but only by refusing every
  candidate whole-path move.
- Patched a targeted outer-update variant into the same wrapper:
  `fixed_step_targeted_linesearch`
  It still uses the accept/reject safeguard, but now tests:
  - full-path move
  - positive-vote periods
  - negative-vote periods
  - single-period moves on the top `|vote|` periods
  - short contiguous blocks around those periods
- Launched the first targeted historical bridge run:
  `hist_k6_targeted_linesearch_i2`
  using:
  - `k = 6`
  - `2` iterations
  - weight `0.005`
  - scales `[1.0, 0.5, 0.25, 0.1, 0.05]`
  - tolerance `1e-6`
  It is substantially heavier than the old whole-path trimmed run and was still
  active at handoff time.
- Morning follow-up on 2026-04-16:
  that first targeted packet was genuinely computing, but it was too broad to
  be efficient as a bridge diagnostic. The overnight run was therefore stopped
  and replaced with a compact targeted packet:
  `hist_k6_targeted_compact_i2`
  using:
  - `k = 6`
  - `2` iterations
  - weight `0.005`
  - scales `[0.1]`
  - `max_targeted_periods = 1`
  - `target_block_half_width = 0`
  Practical implication:
  the live solver-stabilization lane now checks only a very small targeted
  candidate family so it can actually finish and then branch automatically.
- Added a bounded overnight handoff packet for this solver-stabilization lane:
  - note:
    `original_5yr_political_re/workflow_original_5yr_transition_solver_stabilization.md`
  - runner:
    `original_5yr_political_re/run_original_5yr_transition_solver_stabilization_overnight.ps1`
  - supervisor:
    `watch_original_5yr_transition_solver_stabilization_supervisor.ps1`
    `start_original_5yr_transition_solver_stabilization_supervisor.ps1`
  - reporter:
    `watch_original_5yr_transition_solver_stabilization_reporter.ps1`
    `start_original_5yr_transition_solver_stabilization_reporter.ps1`
- Live overnight state:
  `original_5yr_political_re/truth/original_5yr_transition_solver_stabilization_live/`
  with:
  - `latest_status.json`
  - `latest_report.md`
  - `watcher_state.json`
  - `reporter_state.json`
  - `keep_awake_state.json`
  The supervisor now attaches to the in-flight `hist_k6_targeted_compact_i2`
  run if it already exists, then branches automatically:
  - if `k = 6` targeted improves on the old smoke benchmark, deepen once and
    escalate to a bounded `k = 14` targeted run
  - otherwise, try one smaller-weight `k = 6` targeted retry and stop cleanly
    if that still does not improve
  A separate bounded keep-awake helper is also running from:
  `original_5yr_political_re/keep_original_5yr_transition_solver_awake.ps1`
  via:
  `start_original_5yr_transition_solver_keepawake.ps1`
  with live state in:
  `keep_awake_state.json`
- Later on 2026-04-16:
  the solver packet was upgraded again from a short reflow ladder to a real
  bounded candidate search. The active runner
  `run_original_5yr_transition_solver_stabilization_overnight.ps1` now scans a
  structured `k = 6` candidate family automatically:
  - compact fixed-step
  - compact secant
  - compact block update
  - compact small-weight retry
  - two-period fixed-step
  - two-period small-weight
  - secant block update
  - two-period block update
  The workflow now carries forward to `k = 14` only if one of those `k = 6`
  candidates genuinely improves on the smoke benchmark. At the time of this
  note, the upgraded search wrapper is attached to the live
  `hist_k6_targeted_block_i2` branch and will continue automatically from there.

---

### Session: 2026-04-15 (original 5-year Bellman refactor closed at steady state)
- Added a reusable original-model Bellman core:
  `code/steadystate/solve_original_5yr_bellman_core.m`
- Added the original 5-year political steady-state wrapper around that core:
  `code/steadystate/solve_original_5yr_political_steady_state.m`
- Validation result:
  the Bellman core matches `SolveSS_iter.m` on saved age-by-age value-function
  objects at both:
  - benchmark price `p = 2.0`
  - pinned low-price root region `p = 0.34013605902777766`
- Full steady-state wrapper parity result:
  - exact match on `distance`
  - exact match on `totalvote`
  - exact match on `debtstock`
  - exact match on `dens4`
  - exact match on saved `SS_iter`-style snapshot scalars
  - only remaining discrepancy is `pref4` on zero-density states, caused by
    floating-point sign differences on values effectively equal to zero
- Switched the original 5-year MATLAB steady-state sweep entrypoint to the
  refactored solver:
  `original_5yr_political_re/run_original_5yr_steady_state_vote_sweep.m`
- Switched the original-mode compiled sidecar exporter to the refactored
  solver:
  `extensions/re_no_politics/compiled_sidecar/matlab/export_steady_state_input_pack.m`
- Smoke checks now passing on the refactored path:
  - MATLAB sweep smoke:
    `original_5yr_political_re/truth/refactor_sweep_smoke/`
  - benchmark exporter pack:
    `extensions/re_no_politics/compiled_sidecar/truth/steady_state_original_refactor_p2_rb0_03/`
  - low-price exporter pack:
    `extensions/re_no_politics/compiled_sidecar/truth/steady_state_original_refactor_p0340136059_rb0_03/`
- End-to-end compiled check:
  the no-OpenMP compiled political CLI still matches the refactored low-price
  original-model pack:
  - input pack:
    `truth/steady_state_original_refactor_p0340136059_rb0_03`
  - CLI output:
    `totalvote = 0.0252516`
    `distance = 0.000637644`
- Practical implication:
  the steady-state original 5-year Bellman refactor is now finished enough to
  treat as the working kernel. The next real task is no longer "extract the
  steady-state object"; it is "build the bounded dynamic original-timing outer
  political loop on top of this kernel."
- Started that next task immediately:
  - patched `extensions/re_no_politics/solve_transition_re_no_politics.m` so
    the transition solver can now choose its steady-state reference via
    `params.steady_state_reference_mode`
  - added support for
    `steady_state_reference_mode = 'original_5yr_political'`
  - in that mode, the transition solver seeds initial and terminal objects from
    `solve_original_5yr_political_steady_state.m` rather than the no-politics
    steady state
- Added the original-timing demographic-path helper:
  `original_5yr_political_re/build_original_5yr_demographic_path_from_age_state_csv.m`
- Current data implication:
  the annual demographic CSV supports a clean original-timing checkpoint path
  of `2010 -> 2015`, so the first nontrivial original-timing bounded horizon is
  naturally `k = 2`
- Added the new bounded original-timing runner:
  `original_5yr_political_re/run_original_5yr_transition_political_bellman_bounded.m`
  plus launcher
  `original_5yr_political_re/run_original_5yr_transition_political_bellman_bounded.ps1`
- Smoke results:
  - `k = 1`, `max_iter = 1`:
    nests the steady-state benchmark cleanly
    `max_abs_gap = 0`
    `vote = 0.025251616387`
    final price `0.340179006665`
  - `k = 2`, `max_iter = 1`:
    first nontrivial original-timing outer-loop smoke now runs end to end
    vote path about `[0.025251616387, 0.009828125905]`
    final price path about `[0.340179006665, 0.340152773939]`
    max housing gap about `0.011715300997`
- Practical implication:
  we are no longer only at "steady-state Bellman extracted." We now have the
  first working bounded dynamic original-timing political Bellman lane, with a
  concrete `k = 2` smoke result to build on.
- User then clarified that the real target is the historical original 5-year
  ladder starting in `1950`, not the temporary `2010 -> 2015` subsampled smoke.
- Found and wired the historical demographic source:
  `US Age Share Fine Grained.xlsx`, sheet `Share`.
- Added a historical-path builder:
  `original_5yr_political_re/build_original_5yr_demographic_path_from_historical_age_shares.m`
  which parses the workbook with `readcell`, uses the adult-share columns after
  `Adult Total`, aggregates them into the model bins
  `25-29, 30-34, ..., 85-89, 90-100`, and returns the 5-year path
  `1950, 1955, ..., 2015`.
- Extended the bounded original-timing runner and wrapper so they can now use:
  `demographic_source_mode = historical_1950`
  in addition to the earlier temporary annual-subsampled source.
- Historical smoke checks:
  - `k = 1`, `historical_1950`:
    zero housing gap
    vote `0.025251616387`
    benchmark year `1950`
  - `k = 2`, `historical_1950`:
    years `[1950, 1955]`
    vote path about `[0.025251616387, 0.016217569650]`
    final price path about `[0.340179006665, 0.340163641047]`
    max housing gap about `0.009307277245`
- Added the bounded historical workflow packet:
  - note:
    `original_5yr_political_re/workflow_original_5yr_transition_political_re.md`
  - runner:
    `original_5yr_political_re/run_original_5yr_transition_political_re_workflow.ps1`
  - supervisor:
    `watch_original_5yr_transition_political_re_supervisor.ps1`
    `start_original_5yr_transition_political_re_supervisor.ps1`
    `stop_original_5yr_transition_political_re_supervisor.ps1`
  - reporter:
    `watch_original_5yr_transition_political_re_reporter.ps1`
    `start_original_5yr_transition_political_re_reporter.ps1`
    `stop_original_5yr_transition_political_re_reporter.ps1`
- Workflow design:
  historical `k = 1` smoke
  -> historical `k = 2` baseline / fast fixed-step / secant sweep
  -> choose best `k = 2`
  -> `k = 3` smoke
  -> `k = 3` continuation
  -> bounded `k = 4` smoke
  with stop rules on blocking failures, numeric instability, or time budget.
- Initial supervisor launch surfaced a PowerShell wrapper bug rather than a
  model bug:
  the workflow catch path crashed while serializing the generic stage-result
  list into JSON, so the supervisor kept relaunching without a status file.
- Fixed that wrapper bug in:
  `original_5yr_political_re/run_original_5yr_transition_political_re_workflow.ps1`
  by adding a safe `Get-StageResultsSnapshot` helper and reusing it in every
  status / final-result payload path.
- Also improved the reporter so
  `truth/original_5yr_transition_political_live/latest_report.md`
  now shows the run directory, current stage parameters, completed-stage count,
  and the latest completed-stage diagnostics instead of only a thin state line.
- Live state at the time of this note:
  the historical workflow supervisor and reporter are running again cleanly.
  The live run folder is
  `original_5yr_political_re/truth/original_5yr_transition_political_live/`,
  `hist_k1_smoke` has completed successfully, and the workflow has advanced to
  `hist_k2_baseline`.
- Implementation split remains explicit:
  the dynamic original 5-year Bellman ladder is still MATLAB,
  while the C side is currently validated only for the original steady-state
  political object. Dynamic C outer-loop parity is the next compiled target,
  not something already solved.
- Added a first compiled dynamic smoke for the original 5-year transition
  pass:
  - bridge:
    `original_5yr_political_re/compiled_sidecar_bridge/build_demographic_path_from_age_state_csv.m`
  - runner:
    `extensions/re_no_politics/compiled_sidecar/run_original_5yr_transition_pass_cli.ps1`
  - validation result on the historical `1950, 1955` pack:
    `policy_idx_b` diff `0`, `policy_idx_a` diff `0`,
    `valuefunctions` max abs diff about `5.96e-06`,
    and all aggregate political / density paths match to floating-point noise
  - practical implication:
    the compiled sidecar now has a working historical original-5-year
    transition-pass lane, but the outer political Bellman fixed-point loop is
    still MATLAB-only
- The bounded historical workflow then completed cleanly through `k = 4` on
  the `1950, 1955, ..., 2015` path:
  - best `k = 2` branch:
    `hist_k2_baseline`
    `max_abs_vote = 0.0230712997659694`
    `max_abs_gap = 0.00930612826320038`
  - `k = 3` continuation:
    `max_abs_vote = 0.0241826342693745`
    `max_abs_gap = 0.00930612826320038`
  - `k = 4` smoke:
    `max_abs_vote = 0.0278386148549857`
    `max_abs_gap = 0.00930727724494884`
- Because the user wanted a faster answer on whether the full historical
  horizon is even climbable, launched direct sparse smoke probes in parallel at
  `k = 5`, `k = 8`, and `k = 14`.
- Those sparse probes all completed locally and showed that the full horizon is
  numerically stable under a one-iteration smoke:
  - `k = 14`:
    `max_abs_vote = 0.0343491536712217`
    `max_abs_gap = 0.00930727724494884`
    `residual_norm = 0.0544188470639966`
  - The `k = 14` vote path changes sign across the middle of the sample and
    turns positive again by the final periods, so the object is bounded but not
    yet close to a vote-zero fixed point.
- Also launched a mixed local refinement packet:
  - full horizon:
    `hist_k14_baseline_i2`
    `hist_k14_baseline_i3`
    `hist_k14_secant_i2`
  - shorter bridge jobs:
    `hist_k5_baseline_i2`
    `hist_k6_baseline_i2`
- Local resource pressure then became real:
  before offload, only about `2.4 GB` of physical memory was free and there
  were five heavy MATLAB workers active.
- To relieve that pressure without dropping the highest-value jobs, copied a
  fresh project bundle to Hamilton:
  `/home/hfnt93/codex_runs/original_5yr_hist_20260415_130649/02_nimbyism_and_housing_supply`
- Submitted the heavy `k = 14` refinement jobs to Hamilton under Slurm:
  - `ham_k14_baseline_i2` -> job `16799608`
  - `ham_k14_baseline_i3` -> job `16799609`
  - `ham_k14_secant_i2` -> job `16799610`
  At the submission check, all three were already running on compute nodes.
- Stopped the duplicate local `k = 14` jobs after the Hamilton submission so
  the local machine would only keep the shorter bridge jobs.
  That raised free physical memory from about `2.4 GB` to about `4.5 GB`.

---

### Session: 2026-04-14 (original 5-year steady-state bracket refinement)
- Continued the original 5-year political steady-state root hunt inside:
  `original_5yr_political_re/truth/`
- The manual refinement chain now reads:
  - `micro_ss_2` on `[0.34, 0.44]` found a sign-change bracket on
    `[0.34, 0.340833333333333]`
  - `micro_ss_3` on that narrower interval tightened the bracket further to
    `[0.340125, 0.340138888888889]`
  - `micro_ss_4` is now running inside that latest bracket
- Practical interpretation:
  the original 5-year steady-state political vote-zero price is not near the
  old published benchmark price around `2.0`; it sits much lower, near
  `0.34013` under the current original-model steady-state object.
- New local refinement read:
  `micro_ss_4` tightened the sign-change bracket again to
  `[0.3401359375, 0.340136111111111]`.
  The bracket width is now about `1.74e-7`, but the vote function is locally
  step-like rather than smooth: nearby grid points often repeat the exact same
  vote value before jumping. So this looks more like a discrete policy-switch
  boundary than a well-behaved continuous root.
- Tightened the workflow itself so it now keeps drilling down automatically
  after the first bracket:
  `run_original_5yr_political_re_workflow.ps1` now continues through
  `refined`, `dense`, `micro`, and `ultra` local sweeps until either the
  bracket width is already small enough or `best |vote|` is already below the
  configured tolerance.
- Updated the workflow note accordingly:
  `original_5yr_political_re/workflow_original_5yr_political_re.md`
- Confirmed there are no stray original-5-year watcher loops currently running;
  the live active process is the direct narrow MATLAB sweep, not a hidden
  overseer.
- Pushed the pinned price into the compiled sidecar by exporting a new pack:
  `extensions/re_no_politics/compiled_sidecar/truth/steady_state_p03401360_rb0_03`
- The no-OpenMP steady-state political CLI runs on that pack, but it does not
  yet match the MATLAB original-model object at the same price:
  - compiled result at `trial_price = 0.340136`:
    `totalvote = 0.0756085`
  - local MATLAB bracket says the sign change sits inside
    `[0.3401359375, 0.340136111111111]`
- Practical implication:
  the compiled steady-state lane is still not a clean parity implementation of
  the original `SolveSS_iter.m` political object at low prices; the next step
  is parity debugging, not more blind price search.
- Root-cause clarification:
  this is not just a mysterious numerical mismatch. The current compiled
  exporter itself is still exporting the `re_no_politics` steady-state object:
  `compiled_sidecar/matlab/export_steady_state_input_pack.m` calls
  `solve_ss_no_politics(...)`, while the original 5-year MATLAB sweep calls
  `SolveSS_iter(...)`.
- So the current C-vs-MATLAB comparison is mixing two different steady-state
  objects. The next compiled task is therefore to build an exporter / truth pack
  for the original `SolveSS_iter.m` political steady state, then re-run parity
  on that like-for-like object.
- Implemented that fix:
  - `compiled_sidecar/matlab/export_steady_state_input_pack.m` now supports
    `steady_state_mode = original_solve_ss_iter`
  - `compiled_sidecar/export_steady_state_input.ps1` now passes the selected
    steady-state mode through to MATLAB
  - the exporter now writes `meta_strings.csv` plus original-model truth files
    such as `matlab_age_valuefunctions_dp.csv`,
    `matlab_age_preference_sign.csv`, and
    `matlab_political_summary.csv`
- Patched the compiled steady-state solver to read that mode and reproduce the
  original `SolveSS_iter.m` political object rather than the cleaned-up
  `re_no_politics` version:
  - added `steady_state_mode` to
    `compiled_sidecar/include/nimby_sidecar/steady_state_solver.hpp`
  - updated `compiled_sidecar/src/steady_state_solver.cpp`
  - the political solve now uses branch-aware original-model formulas, including
    the original younger-age rent formulas and the original baseline
    borrowing-constraint object in the perturbed-price branch
- Validation read:
  - original low-price pack:
    `truth/steady_state_original_p03401360_rb0_03`
    MATLAB `totalvote = -0.431837112084382`
    sidecar `totalvote = -0.4318371120843828`
  - original benchmark pack:
    `truth/steady_state_original_p2_rb0_03`
    MATLAB `totalvote = -0.970803363781172`
    sidecar `totalvote = -0.970803...`
- Practical implication:
  the compiled steady-state political prototype is now a genuine parity match
  for the original 5-year MATLAB political object. The next step is no longer
  "make C hit the right steady-state number"; it is "use this validated
  original-mode steady-state object as the base for the outer root solve and
  then the dynamic Bellman lane."
- Added a bounded away-from-keyboard compiled workflow for that next step:
  - runner:
    `original_5yr_political_re/run_compiled_original_steady_state_overnight_workflow.ps1`
  - launcher:
    `original_5yr_political_re/start_compiled_original_steady_state_overnight_workflow.ps1`
- Workflow scope:
  stay inside the original 5-year compiled steady-state lane, reuse the
  validated original pack, run staged political sweeps that keep narrowing the
  vote bracket, stop on bracket-width tolerance, vote tolerance, stage cap, or
  time budget, and write live status plus a handoff summary.
- Smoke result:
  a 2-stage local test completed cleanly in about 5 minutes and narrowed the
  compiled bracket from `[0.3401, 0.34015]` to `[0.340136, 0.3401365]`.
- Live overnight run:
  `truth/compiled_original_steady_state_overnight_live/r/co_20260414_211451/`
  started at 2026-04-14 21:14 local time on the tighter MATLAB bracket
  `[0.3401359375, 0.340136111111111]`
  with:
  - `21` grid points per stage
  - `price_multiplier = 1.01`
  - `max_stages = 10`
  - `max_hours = 10`
  - `bracket_width_tolerance = 1e-8`
  - `vote_tolerance = 1e-4`
- Important operating choice:
  this is a single bounded workflow process, not a restart watcher. That keeps
  the overnight lane simpler and closer to the user's request to avoid hidden
  babysitter loops.

---

### Session: 2026-04-14 (compiled steady-state political prototype)
- Built the smallest compileable prototype of the original 5-year steady-state political object in
  the compiled sidecar:
  - `extensions/re_no_politics/compiled_sidecar/src/steady_state_solver.cpp`
  - `extensions/re_no_politics/compiled_sidecar/include/nimby_sidecar/steady_state_solver.hpp`
  - `extensions/re_no_politics/compiled_sidecar/src/steady_state_political_cli.cpp`
  - `extensions/re_no_politics/compiled_sidecar/CMakeLists.txt`
- New helper behavior:
  - solve the baseline steady state at the fixed trial price
  - solve the perturbed branch at `a_price * price_multiplier`
  - compute state-level `sign(V^{dp} - V)`
  - aggregate `totalvote`
  - compute `distance = totalvote^2`
- Smoke test:
  - `nimby_steady_state_political_cli` runs successfully on
    `truth/steady_state_p2_rb0_03` once the LLVM runtime DLLs are on `PATH`
  - output example:
    `totalvote = -0.97080399781627569`
    `distance = 0.94246040217606342`
- Baseline check:
  the existing steady-state reference output still matches the MATLAB summary pack to machine
  precision on the same test fixture.

---

### Session: 2026-04-14 (pivot back to original 5-year political RE target)
- User clarified that the annual `2010-2018` transition extension is not the
  main object they want for this paper.
- Confirmed from the baseline code that the original model is the 5-year
  political object:
  `code/steadystate/SolveSS_iter.m` uses `dage = 5` and closes the steady-state
  equilibrium with the median-voter residual built from `sign(V^{dp} - V)`.
- Practical decision:
  park the annual extension as a side branch and reset the main target to the
  original 5-year political RE Bellman problem.
- Stopped the two live NIMBY no-politics extension watchers so the local
  machine is not continuing the wrong background lane:
  - `extensions/re_no_politics/compiled_sidecar/stop_house_price_compiled_supervisor.ps1`
  - `extensions/re_no_politics/compiled_sidecar/stop_political_bellman_compiled_supervisor.ps1`
- New working definition:
  build the reusable Bellman kernel from the original 5-year model first, then
  wrap a dynamic median-voter outer loop around that object rather than around
  the annual extension.
- Added a separate original-timing MATLAB workflow folder:
  `original_5yr_political_re/`
- New first-rung runner:
  `run_original_5yr_steady_state_vote_sweep.m`
  plus wrapper
  `run_original_5yr_steady_state_vote_sweep.ps1`
- New live runged workflow:
  `run_original_5yr_political_re_workflow.ps1`
  which executes
  coarse steady-state sweep
  -> if no bracket, directional price expansion
  -> if still no bracket, broad full-domain sweep
  -> if still no bracket, small `rb` sensitivity family
  -> if a bracket is found, refined bracket sweep
  -> dense bracket sweep
  -> C-port handoff
- First live coarse run completed and showed why the tree was needed:
  all votes were negative on the initial `[1.8, 2.2]` grid, with best
  `|vote|` about `0.6370` at price about `1.8138`, so the old workflow stopped
  too early.
- Workflow was then rewritten to branch automatically on that failure mode
  rather than asking the user what to do next.
- New background supervisor and reporter:
  - `start_original_5yr_political_re_supervisor.ps1`
  - `watch_original_5yr_political_re_supervisor.ps1`
  - `start_original_5yr_political_re_reporter.ps1`
  - `watch_original_5yr_political_re_reporter.ps1`
- Live state folder:
  `original_5yr_political_re/truth/original_5yr_political_re_live/`
- Current live run at the time of note:
  the supervisor is on `coarse_ss`, and the reporter is writing
  `latest_report.md` from the same live state folder.

---

### Session: 2026-04-14 (construction-adjustment branch)
- Added a separate reduced-form construction-adjustment branch inside:
  `extensions/re_no_politics/solve_transition_re_no_politics.m`
- New parameters:
  - `housing_adjustment_mode`
  - `housing_adjustment_weight`
  - `housing_adjustment_space`
  - `housing_adjustment_anchor_price`
- Baseline behavior is unchanged by default:
  `housing_adjustment_mode = 'instant_market_clearing'`
- The new diagnostic mode is:
  `housing_adjustment_mode = 'construction_lag_price_partial_adjustment'`
- Interpretation:
  this is a reduced-form price-adjustment law meant to stand in for slower
  housing adjustment while the literature lane works out whether a stronger
  construction-lag equation is justified.
- Added a sweep runner and wrapper:
  - `extensions/re_no_politics/run_transition_re_construction_adjustment_sweep.m`
  - `extensions/re_no_politics/run_transition_re_construction_adjustment_sweep.ps1`
- Smoke check:
  `run_transition_re_construction_adjustment_sweep(1, [1.00; 0.50])`
  completed successfully.
- Read from that smoke:
  the one-period case remains unchanged under the slower-adjustment branch,
  which is the expected sanity check.

---

### Session: 2026-04-14 (parallel workflow and Hamilton verification)
- Wrote a concrete three-lane operating workflow in:
  `extensions/re_no_politics/workflow_parallel_political_bellman_and_price_path.md`
- The workflow now separates:
  - MATLAB as the current-model political Bellman reference lane
  - compiled C++ as the parity / runtime lane
  - any slower construction-response equation as a separate literature-backed
    model-extension lane
- Verified Hamilton access from this machine directly:
  `ssh hamilton8 "whoami; hostname; quota; squeue -u hfnt93"` succeeded.
- Result at the time of check:
  - user `hfnt93`
  - host `login1.ham8.dur.ac.uk`
  - `/home` about `520M / 10G`
  - `/nobackup` about `550.8G / 600G`
  - one running job already visible: `16786759 shared fert_t13`
- Practical implication:
  keep quick debugging and parity work local, but once a MATLAB political
  workflow is stable, broader sweeps can be pushed to Hamilton instead of
  saturating the local machine.

---

### Session: 2026-04-14 (MATLAB horizon sweep and first direct parity read)
- The bounded parallel MATLAB political Bellman horizon sweep is now complete:
  `extensions/re_no_politics/truth/political_bellman_parallel_k_live/summary.md`
- Grid:
  `k = 1..9`
  with `2` political iterations per job,
  `price_update_mode = political_only`,
  `political_target = equal_weight_vote`,
  `political_update_rule = fixed_step`.
- Main read:
  - `k = 1` is trivial on the housing side
  - `k = 2` already has a real transition gap, about `0.08868`
  - from `k = 3` onward the housing gap stays near `0.16737`
  - the political residual remains near a corner throughout:
    `max_abs_vote` stays around `0.9708 -> 0.9721`
- Interpretation:
  the bounded political path object is numerically stable enough to run
  through the full `k = 9` horizon, but it is not close to a vote-zero path.
- We also now have the first direct one-iteration MATLAB-vs-C++ parity read
  on `T = 4` using the same no-politics prefix path:
  MATLAB output:
  `transition_political_bellman_audit_t4_i1_fixed_step_summary.csv`
  sidecar output:
  `compiled_sidecar/truth/political_bellman_one_iteration_audit/sidecar_t4_i1_fixed_step/sidecar_summary.csv`
- That direct read is already informative:
  the anchor path matches exactly,
  but the compiled wrapper's vote path differs on the very first iteration.
  Current manual comparison:
  - vote-path max abs diff about `0.5691`
  - final-price-path max abs diff about `0.00567`
  - anchor-path max abs diff `0`
- Practical implication:
  the compiled outer-political mismatch appears immediately in the political
  residual construction, not only after several outer iterations.

### Session: 2026-04-14 (project priority)
- User explicitly set the NIMBY project as the current top-priority project.
- Practical implication:
  keep the live compiled political overseer, the parallel MATLAB `k` sweep,
  and the next debugging passes focused here before returning to lower-priority
  projects.

### Session: 2026-04-14 (parallel MATLAB political k sweep)
- User asked whether we could run the MATLAB political Bellman horizons
  simultaneously instead of only through the sequential ladder.
- Confirmed the bounded MATLAB political runner is parallel-safe for this use:
  it reads the shared benchmark path but writes tagged summary/result files, and
  the shared solver path does not write fixed output files as a side effect.
- Added a bounded parallel MATLAB sweep workflow:
  `extensions/re_no_politics/run_transition_political_bellman_parallel_k_sweep.ps1`
  with launcher/stop scripts:
  `start_transition_political_bellman_parallel_k_sweep.ps1`
  `stop_transition_political_bellman_parallel_k_sweep.ps1`
- Workflow behavior:
  launch independent bounded political Bellman jobs for a supplied `k` grid,
  throttle concurrent MATLAB processes, and write live state plus a Markdown
  summary under `extensions/re_no_politics/truth/<workflow_name>/`.
- Smoke test:
  `political_bellman_parallel_k_smoke3` completed cleanly for `k = 1, 2`
  with `1` political iteration per job and `2` concurrent MATLAB processes.
- Live run started:
  `political_bellman_parallel_k_live`
  on `k = 1..9`, `max_iter = 2`, `max_parallel = 3`,
  `price_update_mode = political_only`,
  `political_target = equal_weight_vote`,
  `political_update_rule = fixed_step`.
- Practical implication:
  while the compiled overseer keeps pushing the C++ political wrapper, we now
  also have a bounded MATLAB lane that can map how the political Bellman object
  behaves across horizons without waiting for the warm-start ladder to finish
  one `k` at a time.

### Session: 2026-04-14 (compiled political outer wrapper)
- Added the first compiled outer political wrapper in
  `extensions/re_no_politics/compiled_sidecar/`.
- New compiled entry point:
  `nimby_political_bellman_cli.exe`
- The wrapper is deliberately narrow:
  equal-weight vote path, `price_update_mode = political_only`,
  `political_update_rule = fixed_step` or `diagonal_secant`, log-space updates.
- Added a non-blocking compiled political supervisor workflow and watcher:
  `political_bellman_compiled_supervisor_workflow.ps1`
  `watch_political_bellman_compiled_supervisor.ps1`
  `start_political_bellman_compiled_supervisor.ps1`
  `stop_political_bellman_compiled_supervisor.ps1`
- The overseer now runs the bounded `T = 4` fixed-step smoke pack and the
  `T = 9` diagonal-secant smoke pack automatically.
- The workflow also exports the no-politics prefix from
  `transition_re_no_politics_results.mat` so the compiled wrapper starts from
  the same benchmark path as the MATLAB political smoke runs.
- Current status:
  the compiled wrapper runs and the overseer completes cleanly, but the
  compiled smoke outputs still do not match the stored MATLAB summary rows yet.
  That is now a parity / model-closure gap, not a workflow gap.

### Session: 2026-04-14 (compiled political transition-pass port)
- User asked why we were still using MATLAB for the political Bellman lane and pushed to move the
  next piece into the C++ sidecar.
- Clarified the right boundary:
  do not port the whole political outer loop first; port the expensive reusable inner object first.
- Implemented that boundary in the compiled sidecar:
  `extensions/re_no_politics/compiled_sidecar/src/transition_pass_solver.cpp` now supports
  `compute_political_path`, a perturbed-price Bellman branch, and political aggregation from
  `sign(V^{dp} - V)` on a fixed guessed transition price path.
- Added the corresponding pack/export support in
  `extensions/re_no_politics/compiled_sidecar/matlab/export_transition_pass_input_pack.m` and
  `extensions/re_no_politics/compiled_sidecar/export_transition_pass_input.ps1`.
- Added validation coverage for the political outputs in
  `extensions/re_no_politics/compiled_sidecar/validate_transition_pass.ps1`.
- New compiled political outputs now include:
  `equal_weight_vote_path`,
  `weighted_vote_path`,
  `weighted_vote_share_path`,
  the distance paths,
  and owner-share diagnostics.
- Validation result on bounded pack:
  `transition_pass_t4_political_diag` matches MATLAB to floating-point noise on policy/value
  objects, aggregate paths, `density_by_period_age`, and all exported political vote/share paths.
- Validation result on full sample pack:
  `transition_pass_t9_political_diag` also matches MATLAB to floating-point noise on the same
  political outputs.
- Practical implication:
  the expensive political Bellman inner pass is no longer MATLAB-only.
  The remaining compiled target for the full political RE lane is the outer vote-zero path solver.

### Session: 2026-04-13 (referee-driven RE reprioritization)
- User wants to treat the recent three-report rejection packet as a reason to reopen the RE
  extension, with house prices as the main object rather than generic "full RE."
- User then clarified the desired scope even further:
  no full political RE, just the house-price expectations object.
- Actual IER packet located in the project root:
  `IER MS31540-1 Decision letter.pdf`
  `IER MS31540-1 R1's report.pdf`
  `IER MS31540-1 R2's report.pdf`
- Current reading of that packet:
  the editor's first concern is house-price expectations, referee 2's least satisfactory part is
  the steady-state analysis, and the next layer of repair is the dynamic household problem /
  expectations notation.
- Added referee strategy note:
  `referee/re_house_price_resubmission_strategy.md`
- Added drafting note for the revision order:
  `referee/ier_house_price_steady_state_then_bellman_draft.md`
- Updated `STATUS.md` so the near-term project priority is now:
  house-price RE write-up and bounded diagnostics for resubmission, not an open-ended full
  political RE continuation campaign.
- Implemented the first code-side response to that reprioritization:
  a fertility-style shared Bellman layer in
  `extensions/re_no_politics/solve_household_path_nimby.m` plus
  `extensions/re_no_politics/build_stationary_cross_section_nimby.m`.
- `extensions/re_no_politics/solve_ss_no_politics.m` and
  `extensions/re_no_politics/solve_transition_re_no_politics.m` now use that same household solve,
  so the steady-state benchmark, the transition RE pass, and the steady-state reference cache all
  sit on one common micro block.
- The shared Bellman core in
  `extensions/re_no_politics/solve_household_path_nimby.m` now also supports an optional
  price-perturbed branch:
  it can return perturbed tail/path Bellman objects plus
  `tail_value_difference`, `path_value_difference`, and their sign objects, which are the clean
  shared-solver version of the old `d_valuefunction_dp` / `sign(d_valuefunction_dp)` political
  inputs.
- `extensions/re_no_politics/solve_transition_re_no_politics.m` now also exposes the final
  `policy_idx_b`, `policy_idx_a`, and `valuefunctions` in its returned `results` struct, so the
  political side does not have to recover them indirectly from local wrapper state.
- `extensions/re_no_politics/solve_transition_re_no_politics.m` can now also build a transition
  political path when `params.compute_political_path = true`:
  it combines pre-decision densities with the shared-solver price-preference signs and returns
  period-by-period equal-weight and coalition-weighted vote diagnostics under `results.political`.
- Added a bounded workflow around that new capability:
  `extensions/re_no_politics/run_transition_re_political_path_diagnostic.m`
  `extensions/re_no_politics/run_transition_re_political_path_diagnostic.ps1`
  `extensions/re_no_politics/run_transition_re_political_path_workflow.ps1`
  `extensions/re_no_politics/write_transition_re_political_path_report.ps1`
  `extensions/re_no_politics/workflow_re_political_path.md`
- First bounded political-path packet is now complete on `T = 4`.
- Current read from `transition_re_political_path_report.md`:
  the house-price residual bottleneck is still period `3`, but the largest political pressure is in
  period `1`, and political pressure remains strongly negative and very persistent across the whole
  four-period window.
- That means the new political residual path is not just a copy of the house-price residual path.
  This is exactly the kind of object needed before attempting a joint price-and-vote update rule.
- Added that next bounded step too:
  `extensions/re_no_politics/run_transition_re_joint_price_vote_experiment.m`
  `extensions/re_no_politics/run_transition_re_joint_price_vote_experiment.ps1`
  `extensions/re_no_politics/run_transition_re_joint_price_vote_workflow.ps1`
  `extensions/re_no_politics/write_transition_re_joint_price_vote_report.ps1`
  `extensions/re_no_politics/workflow_re_joint_price_vote.md`
- First bounded joint price-and-vote packet is now complete on `T = 4` with two outer joint
  iterations and vote weight `0.001`.
- Current read from `transition_re_joint_price_vote_report.md`:
  the coalition-weighted political force pushes prices down in every period, while the housing
  residual still pushes prices up in periods `2` to `4`.
- So the main bounded lesson is now sharper than before:
  the full political RE problem is not just the house-price RE problem plus an extra diagnostic.
  The two forces work in opposite directions on the bounded path.
- Added the bounded vote-weight sweep around that same packet:
  `extensions/re_no_politics/run_transition_re_joint_price_vote_weight_sweep.m`
  `extensions/re_no_politics/run_transition_re_joint_price_vote_weight_sweep.ps1`
  `extensions/re_no_politics/run_transition_re_joint_price_vote_weight_sweep_workflow.ps1`
  `extensions/re_no_politics/write_transition_re_joint_price_vote_weight_sweep_report.ps1`
  `extensions/re_no_politics/workflow_re_joint_price_vote_weight_sweep.md`
- First vote-weight sweep is now complete on the same bounded `T = 4` packet.
- Current read from `transition_re_joint_price_vote_weight_sweep_report.md`:
  conflict share stays at `0.75` across the tested grid `{0, 0.0005, 0.001, 0.002, 0.005}`.
  Larger vote weights just scale the same downward political adjustment; they do not overturn the
  sign pattern.
- So the bounded antagonism result is now more robust:
  the political force still pushes down while the housing-clearing block still pushes up in the
  middle periods even when the political feedback weight changes.
- Added a bounded overnight workflow and hidden overseer for this political RE branch:
  `extensions/re_no_politics/political_re_overnight_workflow.ps1`
  `extensions/re_no_politics/watch_political_re_overnight.ps1`
  `extensions/re_no_politics/start_political_re_overnight.ps1`
  `extensions/re_no_politics/stop_political_re_overnight.ps1`
  `extensions/re_no_politics/workflow_political_re_overnight.md`
- The overnight packet refreshes the three bounded political deliverables, snapshots the artifacts
  into `extensions/re_no_politics/truth/political_re_overnight_live/`, and uses a watcher to
  restart the child run if it dies before the milestone chain completes.
- Important watcher bug fix:
  the first draft crashed before writing `watcher_state.json` because the state writer dereferenced
  a null exit-code slot. The watcher now writes live state correctly and is safe to leave running.
- User then pushed back, correctly, on one conceptual point:
  the original published NIMBY model is not a full RE steady state. It is a political steady-state
  voting object with a local price-perturbation Bellman comparison, not a model-consistent future-
  price fixed point. The fertility analogy only carries over once we are explicit about which
  channel is frozen and which fixed-point object remains.
- Implemented the next code-side response to that correction:
  `solve_transition_re_no_politics.m` can now optionally return the exact current-path transition
  pass under `results.current_path_pass`.
- Added a separate bounded political-Bellman outer wrapper:
  `extensions/re_no_politics/solve_transition_political_bellman_nimby.m`
  plus runner
  `extensions/re_no_politics/run_transition_political_bellman_bounded.m`
  and PowerShell wrapper
  `extensions/re_no_politics/run_transition_political_bellman_bounded.ps1`
- This wrapper uses the shared full-backward Bellman block, extracts the equal-weight political
  residual from the current-path pass, and applies a bounded political-only outer update directly.
- First bounded run is now complete on `T = 4` with two outer political iterations.
- Current read from `transition_political_bellman_bounded_summary.csv`:
  - max equal-weight vote stays near `0.9708` in absolute value
  - the political-only update pushes the price path down from about `2.00` to about
    `[1.9807, 1.9812]`
  - the housing-side max gap stays around `0.167`
  - so the political outer loop is now real code, but it is not yet a solved full political
    transition equilibrium
- User then suggested the right next move:
  do not attack `T = 9` cold if that is too hard; climb the horizon the way we did in fertility.
- Implemented that workflow directly:
  `extensions/re_no_politics/run_transition_political_bellman_k_step_ladder.m`
  `extensions/re_no_politics/run_transition_political_bellman_k_step_ladder.ps1`
  `extensions/re_no_politics/workflow_re_political_bellman_ladder.md`
- This ladder uses:
  - equal-weight political vote as the target
  - the joint housing-plus-politics update mode
  - one political outer iteration per `k`
  - warm starts from the previous political solution, with the no-politics path only as the tail
    anchor for the new period
- First ladder run is now complete through the full sample:
  `transition_political_bellman_joint_eqvote_ladder_ladder_summary.csv`
- Current read:
  - yes, the full demographic sample is `T = 9` because the path is `2010:2018`
  - the political Bellman ladder reaches every `k = 1..9` without crashing or hitting the price
    bounds
  - `k = 1` is trivial on the housing side, with zero gap
  - `k = 2` already introduces a nontrivial housing gap of about `0.089`
  - from `k = 3` onward the housing gap is roughly `0.168`
  - max equal-weight political vote remains very large, around `0.971 -> 0.972`
  - so the ladder is operational through the whole sample, but the political fixed point is still
    nowhere near solved
- Recommended write-up stance:
  keep the benchmark expectations structure in the main text, use the stripped-down no-coalition
  RE and continuation results as conservative evidence that the price-path story is not mainly an
  artifact of the random-walk shortcut, and treat full political RE as future work.
- Corrected the execution lane after a short MATLAB detour:
  the house-price Bellman workflow should live in the compiled sidecar, with MATLAB kept as the
  truth/export harness rather than as the main steady-state runtime.
- Added a compiled steady-state price sweep inside
  `extensions/re_no_politics/compiled_sidecar/`:
  - executable:
    `src/steady_state_sweep_cli.cpp`
  - wrapper:
    `run_steady_state_sweep_cli.ps1`
  - output:
    full sweep CSV plus a best-price Bellman payload under a chosen output folder
- Added a hidden local supervisor/watcher for the compiled house-price packet:
  - workflow:
    `compiled_sidecar/house_price_compiled_supervisor_workflow.ps1`
  - watcher:
    `compiled_sidecar/watch_house_price_compiled_supervisor.ps1`
  - launcher:
    `compiled_sidecar/start_house_price_compiled_supervisor.ps1`
  - stop script:
    `compiled_sidecar/stop_house_price_compiled_supervisor.ps1`
  - live state:
    `compiled_sidecar/truth/house_price_compiled_supervisor_live/`
- The supervised packet now runs without prompts through:
  steady-state CLI, steady-state validation, steady-state sweep, transition-pass CLI and
  validation, and bounded transition-RE CLI and validation.
- Hardened the validation scripts while setting up that watcher:
  - `validate_transition_pass.ps1` now handles single-line CSV reads safely
  - `validate_transition_re.ps1` now treats iteration-path and selection-diagnostic CSVs as
    optional unless MATLAB exported the matching files
- Added an equilibrium-definition note for the no-politics transition object:
  `extensions/re_no_politics/house_price_re_equilibrium_definition.md`
- That note fixes the conceptual target as:
  a fixed point in the house-price path, conditional on an explicitly chosen continuation
  mechanism, rather than either a given-price transition pass or full political RE

### Session: 2026-04-11 (compiled restart-check packets)
- Extended the compiled multi-case case-sweep layer beyond the old `alpha = 0.14`,
  `k = 4` warm-start packet to the older `alpha = 0.15` and `alpha = 0.20`,
  `k = 4` restart-check summaries.
- Added a generic runner:
  `extensions/re_no_politics/compiled_sidecar/run_transition_re_policy_bridge_k4_restart_checks_sidecar.ps1`
  - accepts `-Alpha 0.15` or `0.20`
  - extracts the historical start paths from the saved frontier result `.mat` files
  - exports per-case input-only packs
  - runs the compiled case-sweep CLI on the three restart-check cases
- Added a validator:
  `extensions/re_no_politics/compiled_sidecar/validate_transition_re_policy_bridge_k4_restart_checks_sidecar.ps1`
  - compares the compiled summary against
    `transition_re_policy_bridge_alpha_0_15_k4_restart_checks.csv`
    and
    `transition_re_policy_bridge_alpha_0_20_k4_restart_checks.csv`
- Updated the dispatcher:
  `extensions/re_no_politics/compiled_sidecar/run_compiled_sidecar.ps1`
  - new mode `restart_checks_k4`
  - argument `-Alpha 0.15` or `0.20`
- Validation status:
  - `alpha = 0.15` restart-check packet now matches the saved MATLAB summary to
    floating-point noise
  - `alpha = 0.20` restart-check packet now matches the saved MATLAB summary to
    floating-point noise
- Workflow note:
  - do not run those restart-check validators in parallel; the MATLAB export
    path still reuses the same local `SS_no_politics_iter.mat` scratch file
- Implication:
  - the compiled sidecar now covers the old local `k = 4` diagnostic family on
    all three historically important alpha packets:
    `0.14`, `0.15`, and `0.20`

### Session: 2026-04-11 (compiled warm-start case sweep)
- Added a reusable compiled multi-case warm-start diagnostic runner:
  `extensions/re_no_politics/compiled_sidecar/src/transition_re_case_sweep_cli.cpp`
- Added a single dispatcher entry point for the sidecar:
  `extensions/re_no_politics/compiled_sidecar/run_compiled_sidecar.ps1`
  - default: bounded outer RE
  - other modes: retry-aware edge, compiled warm-start diagnostic, live
    full-horizon bracket workflow
- Tightened the local sidecar ignore rules in
  `extensions/re_no_politics/compiled_sidecar/.gitignore` so local build files
  and transient truth/output artifacts stay out of version control.
- Added the specific wrapper and validator for the old
  `alpha = 0.14`, `k = 4` warm-start diagnostic:
  - `extensions/re_no_politics/compiled_sidecar/run_transition_re_policy_bridge_k4_warm_start_sidecar.ps1`
  - `extensions/re_no_politics/compiled_sidecar/validate_transition_re_policy_bridge_k4_warm_start_sidecar.ps1`
- Important workflow detail:
  - for these frontier-style diagnostics, one shared base pack is not enough,
    because the embedded transition-pass `price_path` changes the reference
    object
  - the wrapper therefore exports one input-only pack per case using that
    case's own start path, then hands the batch to the compiled case-sweep CLI
- Validation read:
  - the compiled `alpha = 0.14`, `k = 4` warm-start diagnostic matches the old
    MATLAB summary and path tables to floating-point noise
  - summary max numeric diff about `7.55e-15`
  - path max numeric diff about `7.55e-15`
  - zero string mismatches

### Session: 2026-04-11 (compiled full-horizon away workflow continuation)
- Resumed the live compiled away session:
  `extensions/re_no_politics/compiled_sidecar/truth/tr_full_horizon_away_live/`
- Two additional real probes completed cleanly:
  - `alpha = 0.18083722352981568`:
    unstable already at `k = 8`
    retry-aware status `ok_retry_failed`
    final max gap about `0.89792`
  - `alpha = 0.18083671212196351`:
    stable at `k = 8` and also stable at `k = 9`
    retry-aware status `ok` on both horizons
    `k = 8` max gap about `7.08e-05`
    `k = 9` max gap about `1.41e-04`
- Current live compiled full-horizon bracket:
  - stable at `0.18083671212196353`
  - unstable at `0.18083722352981568`
  - bracket width about `5.11e-07`
- The live away workflow therefore already reached its target bracket width and
  now stops immediately on resume with `target_bracket_width_reached`.
- Hardened the workflow resume path:
  `run_transition_re_full_horizon_away_workflow.ps1` now normalizes
  `workflow_log.csv` on startup, dedupes repeated `probe_index` rows, and
  syncs the probe counter to the highest recorded probe before resuming.

### Session: 2026-04-10 (compiled full-horizon away workflow)
- Added the bounded compiled away-workflow entry point for the live
  high-horizon NIMBY RE continuation:
  `extensions/re_no_politics/compiled_sidecar/run_transition_re_full_horizon_away_workflow.ps1`
- Added the companion note:
  `extensions/re_no_politics/compiled_sidecar/workflow_transition_re_full_horizon_away.md`
- Workflow objective:
  refine the compiled retry-aware full-horizon bracket, not the old local
  `k = 4` knife edge and not the naive `0.18` ceiling.
- Current live bracket after one real smoke probe through the new workflow:
  - stable at `0.18083620071411133`
  - unstable at `0.18083824634552`
- Workflow design:
  - resumes from a JSON state file under
    `compiled_sidecar/truth/tr_full_horizon_away_live/`
  - uses the validated compiled retry-aware wrapper, not MATLAB runtime
  - clones small `k = 8` and `k = 9` minimal packs from existing templates
  - keeps only compact probe artifacts plus the current best stable `k = 8`
    and `k = 9` final-price paths
  - deletes transient probe input/output trees after each probe
  - stops on time budget, bracket tolerance, max-probe cap, or disk guard
- Real smoke validation:
  - session initially failed on a Windows path-length issue once the retry-aware
    CLI tried to write nested attempt outputs inside a long workflow path
  - shortened the live session and work-tree names to:
    `tr_full_horizon_away_live/`, `r/`, `s/`, and `w/`
  - reran a one-probe smoke session successfully
  - midpoint `alpha = 0.18083824634552` is unstable already at `k = 8`
  - promoted that compact smoke session into the live resume directory
- Disk note:
  - this machine hit effectively zero free space during setup
  - deleted several large, reproducible transition-pass validation packs to
    restore working headroom before validating the live workflow

### Session: 2026-04-10 (compiled retry-aware RE CLI)
- Moved the sidecar retry-aware local frontier check out of PowerShell solve
  orchestration and into a real compiled entry point:
  - executable:
    `extensions/re_no_politics/compiled_sidecar/src/transition_re_retryaware_cli.cpp`
  - wrapper:
    `extensions/re_no_politics/compiled_sidecar/run_transition_re_retryaware.ps1`
- The compiled retry-aware CLI now:
  - runs the first bounded outer-RE attempt
  - retries once from its own failed endpoint when needed
  - writes `attempt1/`, `attempt2/`, `sidecar_retryaware_attempts.csv`,
    `sidecar_retryaware_summary.csv`, and `sidecar_retryaware_status.txt`
  - supports `--per-attempt-max-iter` so the old `25 + 25` versus `50 + 50`
    edge-robustness checks use the same compiled path
- Local validation read on the existing `k = 4` frontier edge packs:
  - stable-side pack
    `transition_re_k4_frontier_alpha_0_190899658203125_input_only`:
    default budget still returns `ok_after_retry` with final max gap about
    `0.031897826461325`
  - unstable-side pack
    `transition_re_k4_frontier_alpha_0_19090576171875_input_only`:
    default budget still returns `ok_retry_failed` with final max gap about
    `0.794702946857174`
  - stable-side pack with `-PerAttemptMaxIter 50`:
    now returns `ok` on attempt `1`, with the same final max gap
  - unstable-side pack with `-PerAttemptMaxIter 50`:
    still returns `ok_retry_failed`, with final max gap about
    `0.261580942721814`
- Interpretation:
  - the local retry-aware edge workflow is no longer shell-only glue
  - the compiled sidecar now reproduces both the default knife-edge checks and
    the longer-budget robustness reruns through the same C++ path

### Session: 2026-04-10 (frontier runner resume and validator)
- Hardened the compiled NIMBY frontier runner into a real long-run workflow:
  - it now resumes from its own `sidecar_frontier_summary_live.csv` /
    `sidecar_frontier_live.csv` outputs instead of restarting from `k = 1`
  - parser also now tolerates the simple quoted CSV format that PowerShell
    writes in resume smoke tests
- Added frontier summary validation script:
  - `extensions/re_no_politics/compiled_sidecar/validate_transition_re_frontier.ps1`
  - compares overlapping frontier rows from sidecar and MATLAB summary CSVs
  - supports `-MaxK` so partially completed MATLAB live packets can still be
    checked on the completed overlap
- Resume smoke test:
  - seeded
    `extensions/re_no_politics/compiled_sidecar/truth/transition_re_frontier_single_0_20_k4_resume_smoke`
    with only `k = 1..2` case folders plus truncated live frontier CSVs
  - reran the frontier runner with `-Resume`
  - recovered the full `k = 1..4` frontier summary exactly, row for row,
    against
    `extensions/re_no_politics/compiled_sidecar/truth/transition_re_frontier_single_0_20_k4_sidecar_v2/sidecar_frontier_summary.csv`
- Frontier validation read:
  - `validate_transition_re_frontier.ps1` passes on the completed overlap
    between the compiled frontier summary and the MATLAB retry-aware live
    packet for `alpha = 0.20`, `k <= 3`
  - max abs differences are about:
    - residual norm: `5.27e-11`
    - max gap: `9.05e-11`
    - max update: `1.03e-11`
  - status and warm-start labels also match exactly on those rows
- Extended the compiled retry-aware `alpha = 0.20` frontier run through
  `k = 6` by resuming from the completed `k = 4` sidecar directory:
  - `k = 4`: `ok_retry_failed`, max gap about `0.02814`, but lower bound `0.4`
    is hit so it is still not stable
  - `k = 5`: `ok_retry_failed`, max gap about `65.41739`
  - `k = 6`: `ok_retry_failed`, max gap about `65.41739`
- Interpretation:
  - the compiled frontier runner is now practical for long bounded scans
  - the old MATLAB `single_0_20_k6` packet remains a useful one-pass
    unstable-region reference, but it is not the exact parity target once the
    retry-aware second-attempt logic is part of the workflow

### Session: 2026-04-10 (compiled frontier runner)
- Added a compiled frontier runner on top of the existing bounded outer RE
  sidecar:
  - executable:
    `extensions/re_no_politics/compiled_sidecar/src/transition_re_frontier_cli.cpp`
  - wrapper:
    `extensions/re_no_politics/compiled_sidecar/run_transition_re_frontier_cli.ps1`
  - it scans an `alpha` grid across horizons `k`, reuses the MATLAB
    frontier workflow's warm-start ladder, and applies the same retry-aware
    two-attempt classification rule as the local edge checks
- Extended the compiled RE result payload so frontier summaries can use the
  final policy-reference path directly:
  - `extensions/re_no_politics/compiled_sidecar/include/nimby_sidecar/transition_re_solver.hpp`
  - `extensions/re_no_politics/compiled_sidecar/src/transition_re_solver.cpp`
- Important pack-construction lesson:
  - frontier base packs must be exported with the same warm-start path that
    the compiled frontier runner will treat as its anchor
  - a flat embedded `price_path.csv` is not equivalent to a fixed-price
    benchmark anchor, because the exporter bakes that path into the
    transition-pass side of the pack
- Also hit and fixed one local debugging mistake:
  - the first extracted `frontier_anchor_fixed_price_2_0.csv` was in the
    wrong order because it was sorted on a non-existent `t` field instead of
    `period_index`
  - after correcting that anchor and re-exporting the base pack, the
    frontier comparisons made sense
- Validation read:
  - compiled frontier output:
    `extensions/re_no_politics/compiled_sidecar/truth/transition_re_frontier_single_0_20_k4_sidecar_v2/sidecar_frontier_summary.csv`
  - current MATLAB retry-aware live packet:
    `extensions/re_no_politics/transition_re_policy_bridge_alpha_frontier_single_0_20_k4_retryaware_sidecar_check_summary_live.csv`
  - completed rows `k = 1..3` match to floating-point noise on:
    final prices, gap/residual diagnostics, policy-reference prices, and
    warm-start labels
  - the MATLAB `k = 4` reference run did not finish within the session
    timeout here, so full frontier-runner parity above those completed rows
    is still open

### Session: 2026-04-10 (compiled sidecar diagnostic payload parity)
- Extended the compiled NIMBY sidecar so the bounded outer RE solver now emits
  the workflow-used diagnostic payloads that were still MATLAB-only:
  - nested candidate-selection diagnostics from the outer RE loop
  - optional `density_by_period_age` from the forward simulation
- Added diagnostic structs and CSV writers in:
  `extensions/re_no_politics/compiled_sidecar/include/nimby_sidecar/transition_re_solver.hpp`
  `extensions/re_no_politics/compiled_sidecar/src/transition_re_solver.cpp`
- Added optional forward-density storage in:
  `extensions/re_no_politics/compiled_sidecar/include/nimby_sidecar/transition_pass_solver.hpp`
  `extensions/re_no_politics/compiled_sidecar/src/transition_pass_solver.cpp`
- Extended the MATLAB pack exporters and wrappers so bounded packs can request:
  - `save_candidate_history`
  - `save_period_details`
  and export MATLAB truth in the same normalized CSV format.
- New validated packs:
  - `transition_re_t4_fixed_terminal_history`
    - selection-iteration, pass, and candidate tables match MATLAB to floating-point noise
    - zero string mismatches
  - `transition_pass_t4_diag_period_details`
    - `density_by_period_age` max diff about `7.63e-17`
  - `transition_re_t4_fixed_terminal_full_details`
    - density payload plus selection diagnostics both match MATLAB
- Practical read:
  the compiled sidecar now covers the runtime core plus the solver payloads
  that downstream NIMBY RE workflows actually inspect; remaining MATLAB
  dependence is mostly the export/truth harness and report scripts.

### Session: 2026-04-10 (retry-aware `k = 4` blend frontier reruns)
- Diagnosed the old `alpha = 0.14`, `k = 4` failure more carefully and confirmed it was a
  one-pass solver artifact rather than a structural edge of the bounded-horizon object.
- Added a dedicated diagnostic runner:
  `run_transition_re_policy_bridge_k4_warm_start_diagnostics.m`
  with outputs:
  `transition_re_policy_bridge_k4_warm_start_diagnostics_summary.csv`
  `transition_re_policy_bridge_k4_warm_start_diagnostics_paths.csv`
  `transition_re_policy_bridge_k4_warm_start_report.md`
- Main warm-start finding:
  - at `alpha = 0.14`, the default `same_alpha_k_3` start is unstable after `25` iterations
  - but `50` iterations or a single restart from the failed endpoint reaches a stable path
  - the same restart-aware logic also rescues `alpha = 0.15`
  - `alpha = 0.20` still remains unstable at `k = 4`
- Patched `run_transition_re_policy_bridge_alpha_frontier.m` so the runner now:
  - retries one unstable case from its own failed endpoint before classifying it as unstable
  - prefers the last stable `k - 1` frontier path when stepping down in `alpha`, instead of
    inheriting a failed same-`k` higher-alpha path first
- Verified the patched runner on new same-alpha `k = 4` continuation packets:
  - `alpha = 0.15`:
    `transition_re_policy_bridge_alpha_frontier_single_0_15_k4_retryaware_summary.csv`
    stable at `k = 4` after retry
    max gap about `0.01510`
    price max about `2.7577`
  - `alpha = 0.175`:
    `transition_re_policy_bridge_alpha_frontier_single_0_175_k4_retryaware_summary.csv`
    stable at `k = 4` after retry
    max gap about `0.00632`
    price max about `2.9833`
  - `alpha = 0.1875`:
    `transition_re_policy_bridge_alpha_frontier_single_0_1875_k4_retryaware_summary.csv`
    stable at `k = 4` after retry
    max gap about `0.04782`
    price max about `4.3442`
  - `alpha = 0.190625`:
    `transition_re_policy_bridge_alpha_frontier_single_0_190625_k4_retryaware_summary.csv`
    stable at `k = 4` after retry
    max gap about `0.03292`
    price max about `4.4657`
  - `alpha = 0.1908203125`:
    `transition_re_policy_bridge_alpha_frontier_single_0_1908203125_k4_retryaware_summary.csv`
    stable at `k = 4` after retry
    max gap about `0.03204`
    price max about `4.4665`
  - `alpha = 0.190869140625`:
    `transition_re_policy_bridge_alpha_frontier_single_0_190869140625_k4_retryaware_summary.csv`
    stable at `k = 4` after retry
    max gap about `0.03202`
    price max about `4.4666`
  - `alpha = 0.1908935546875`:
    `transition_re_policy_bridge_alpha_frontier_single_0_1908935546875_k4_retryaware_summary.csv`
    stable at `k = 4` after retry
    max gap about `0.03190`
    price max about `4.4667`
  - `alpha = 0.190899658203125`:
    `transition_re_policy_bridge_alpha_frontier_single_0_190899658203125_k4_retryaware_summary.csv`
    stable at `k = 4` after retry
    max gap about `0.03190`
    price max about `4.4667`
  - `alpha = 0.19090576171875`:
    `transition_re_policy_bridge_alpha_frontier_single_0_19090576171875_k4_retryaware_summary.csv`
    unstable at `k = 4` even after retry
    max gap about `0.79470`
    price max about `4.4667`
  - `alpha = 0.19091796875`:
    `transition_re_policy_bridge_alpha_frontier_single_0_19091796875_k4_retryaware_summary.csv`
    unstable at `k = 4` even after retry
    max gap about `0.72382`
    price max about `4.5378`
  - `alpha = 0.191015625`:
    `transition_re_policy_bridge_alpha_frontier_single_0_191015625_k4_retryaware_summary.csv`
    unstable at `k = 4` even after retry
    max gap about `0.41349`
    price max about `4.8481`
  - `alpha = 0.19140625`:
    `transition_re_policy_bridge_alpha_frontier_single_0_19140625_k4_retryaware_summary.csv`
    unstable at `k = 4` even after retry
    max gap about `0.26158`
    price max hits `5.0`
  - `alpha = 0.1921875`:
    `transition_re_policy_bridge_alpha_frontier_single_0_1921875_k4_retryaware_summary.csv`
    unstable at `k = 4` even after retry
    max gap about `0.26161`
    price max hits `5.0`
  - `alpha = 0.19375`:
    `transition_re_policy_bridge_alpha_frontier_single_0_19375_k4_retryaware_summary.csv`
    unstable at `k = 4` even after retry
    max gap about `0.26211`
    price max hits `5.0`
- Current bounded-horizon read:
  - raw one-pass same-alpha ladder:
    `alpha = 0.13` is still the largest tested value that stays stable for every `k <= 6`
  - retry-aware local `k = 4` boundary under the current stability filter:
    stable at `0.190899658203125`
    unstable at `0.19090576171875`
  - so the old `0.13995/0.14000` pinch-point packet should now be treated as a conservative
    workflow artifact, not as the economic boundary of the bounded-horizon object
- Added a dedicated edge-robustness runner:
  `run_transition_re_policy_bridge_k4_edge_robustness.m`
  with outputs:
  `transition_re_policy_bridge_k4_edge_robustness_summary.csv`
  `transition_re_policy_bridge_k4_edge_robustness_attempts.csv`
  `transition_re_policy_bridge_k4_edge_robustness_report.md`
- Edge-robustness result around the current cutoff:
  - stable-side point `alpha = 0.190899658203125`:
    baseline `25 + 25` retry-aware packet is stable with max gap about `0.03190`
    longer `50 + 50` retry-aware packet reaches the same final path and same max gap, but does so
    in the first `50`-iteration attempt without needing the retry
  - unstable-side point `alpha = 0.19090576171875`:
    baseline `25 + 25` retry-aware packet is unstable with max gap about `0.79470`
    longer `50 + 50` retry-aware packet is still unstable after retry, with max gap about
    `0.26158`
    it still fails even a looser `0.10` cutoff and the retry path hits the upper bound `5.0`
- Interpretation update:
  the local `0.190899658203125 / 0.19090576171875` knife-edge is not a byproduct of the old
  iteration cap
  it looks more like a basin change under the current solver/object, with only the stable-side
  point being sensitive to a materially tighter cutoff like `0.03`
- New retry-aware `k = 5` continuation packet:
  - `alpha = 0.19`:
    `transition_re_policy_bridge_alpha_frontier_single_0_19_k5_retryaware_summary.csv`
    stable at `k = 4`
    unstable at `k = 5`
    `k = 5` max gap about `0.32128`
  - `alpha = 0.18`:
    `transition_re_policy_bridge_alpha_frontier_single_0_18_k5_retryaware_summary.csv`
    unstable at `k = 4` under this same-alpha packet
    stable at `k = 5`
    `k = 5` max gap about `0.00555`
  - `alpha = 0.185`:
    `transition_re_policy_bridge_alpha_frontier_single_0_185_k5_retryaware_summary.csv`
    stable at `k = 4`
    stable at `k = 5`
    `k = 5` max gap about `0.00376`
  - `alpha = 0.1875`:
    `transition_re_policy_bridge_alpha_frontier_single_0_1875_k5_retryaware_summary.csv`
    stable at `k = 4`
    unstable at `k = 5`
    `k = 5` max gap about `0.34335`
  - `alpha = 0.18625`:
    `transition_re_policy_bridge_alpha_frontier_single_0_18625_k5_retryaware_summary.csv`
    unstable at `k = 4`
    unstable at `k = 5`
    `k = 5` max gap about `0.34336`
  - `alpha = 0.185625`:
    `transition_re_policy_bridge_alpha_frontier_single_0_185625_k5_retryaware_summary.csv`
    unstable at `k = 4`
    unstable at `k = 5`
    `k = 5` max gap about `0.33471`
- Current horizon-by-horizon read:
  - retry-aware `k = 4` edge:
    between `0.190899658203125` and `0.19090576171875`
  - retry-aware `k = 5` edge:
    between `0.185` and `0.185625`
  - so even after the `k = 4` reclassification, the bounded-horizon object still becomes
    materially harsher as the horizon length rises

### Session: 2026-04-09 (same-alpha continuation bracket for the blend frontier)
- Used the resumable frontier runner for two new bounded-horizon continuation checks that keep the
  same `alpha` across `k` rather than descending from a higher-alpha same-`k` warm start.
- New refined local frontier run:
  - command target:
    `run_transition_re_policy_bridge_alpha_frontier(6, [0.05 0.06 0.07 0.08 0.09 0.10], 'alpha_frontier_refine_0_05_0_10_k6')`
  - result:
    `alpha = 0.10` stays stable through `k = 6`
  - summary stats at `k = 6`:
    residual norm about `0.003824`
    max gap about `0.007170`
    price range about `[1.6865, 2.0896]`
- New single-alpha continuation run:
  - command target:
    `run_transition_re_policy_bridge_alpha_frontier(6, [0.20], 'alpha_frontier_single_0_20_k6')`
  - result:
    `alpha = 0.20` is stable through `k = 3` and fails at `k = 4`
  - failure read at `k = 4`:
    residual norm about `0.7376`
    max gap about `0.4057`
    price range about `[0.7775, 2.0896]`
  - later periods:
    `k = 5` and `k = 6` hit the imposed `[0.4, 5.0]` bounds with very large gaps
- Additional single-alpha continuation run:
  - command target:
    `run_transition_re_policy_bridge_alpha_frontier(6, [0.15], 'alpha_frontier_single_0_15_k6')`
  - result:
    `alpha = 0.15` is also stable through `k = 3` and fails at `k = 4`
  - failure read at `k = 4`:
    residual norm about `0.0761`
    max gap about `0.2032`
    price range about `[1.6887, 2.5696]`
- Additional single-alpha continuation run:
  - command target:
    `run_transition_re_policy_bridge_alpha_frontier(6, [0.12], 'alpha_frontier_single_0_12_k6')`
  - result:
    `alpha = 0.12` stays stable through `k = 6`
  - `k = 6` read:
    residual norm about `0.00350`
    max gap about `0.00668`
    price range about `[1.6865, 2.0896]`
- Resumed single-alpha continuation run:
  - command target:
    `run_transition_re_policy_bridge_alpha_frontier(6, [0.13], 'alpha_frontier_single_0_13_k6')`
  - result:
    `alpha = 0.13` stays stable through `k = 6`
  - `k = 6` read:
    residual norm about `0.00296`
    max gap about `0.00552`
    price range about `[1.6774, 2.0896]`
- Additional single-alpha continuation run:
  - command target:
    `run_transition_re_policy_bridge_alpha_frontier(6, [0.14], 'alpha_frontier_single_0_14_k6')`
  - result:
    `alpha = 0.14` is unstable at `k = 4`, then returns to the stable region at `k = 5` and
    `k = 6`
  - `k = 4` failure read:
    residual norm about `0.06195`
    max gap about `0.13429`
    price range about `[1.6887, 2.1017]`
  - `k = 6` later read:
    residual norm about `0.00160`
    max gap about `0.00320`
    price range about `[1.6865, 2.2353]`
- Local `k = 4` refinement run:
  - command target:
    `run_transition_re_policy_bridge_alpha_frontier(4, [0.13 0.131 0.132 0.133 0.134 0.135 0.136 0.137 0.138 0.139 0.14], 'alpha_frontier_refine_0_13_0_14_k4')`
  - result:
    `alpha = 0.139` is stable at `k = 4`
    `alpha = 0.140` is unstable at `k = 4`
  - stable-side read at `alpha = 0.139`:
    residual norm about `0.01145`
    max gap about `0.02546`
    price range about `[1.6867, 2.2106]`
- Finer local `k = 4` refinement run:
  - command target:
    `run_transition_re_policy_bridge_alpha_frontier(4, [0.139 0.13925 0.1395 0.13975 0.14], 'alpha_frontier_refine_0_139_0_14_k4')`
  - result:
    `alpha = 0.13975` is stable at `k = 4`
    `alpha = 0.14000` is unstable at `k = 4`
  - stable-side read at `alpha = 0.13975`:
    residual norm about `0.00445`
    max gap about `0.00992`
    price range about `[1.6867, 2.2261]`
- Finest local `k = 4` refinement run:
  - command target:
    `run_transition_re_policy_bridge_alpha_frontier(4, [0.13975 0.1398 0.13985 0.1399 0.13995 0.14], 'alpha_frontier_refine_0_13975_0_14_k4')`
  - result:
    `alpha = 0.13995` is stable at `k = 4`
    `alpha = 0.14000` is unstable at `k = 4`
  - stable-side read at `alpha = 0.13995`:
    residual norm about `0.00445`
    max gap about `0.00992`
    price range about `[1.6867, 2.2261]`
- Interpretation update from the continuation checks:
  - the old descending-alpha coarse frontier understated stability because lower-alpha tests could
    inherit bad warm starts from unstable higher-alpha same-`k` paths
  - for bounded-horizon quantitative reading, the more reliable object is same-alpha continuation
    across `k`
  - current monotone-through-`k <= 6` bracket:
    `alpha = 0.13` stays stable through every `k <= 6`
    `alpha = 0.14` already breaks at `k = 4`
  - the packet is not nested in `k` under the current solver and stability filter:
    `alpha = 0.14` fails at `k = 4` but is back inside the stability region at `k = 5` and
    `k = 6`
  - conditional on focusing on the `k = 4` bottleneck itself, the current local bracket is now
    extremely tight:
    `alpha = 0.13995` stable
    `alpha = 0.14000` unstable
  - practical next step is no longer to refine between `0.10` and `0.15`
  - it is to understand why the `k = 4` cliff is so sharp while `k = 5` and `k = 6` are again
    admissible at `alpha = 0.14`

### Session: 2026-04-09 (resumable alpha frontier continuation)
- Hardened `extensions/re_no_politics/run_transition_re_policy_bridge_alpha_frontier.m` into a
  resumable workflow:
  - resumes from live checkpoint files when present
  - can also resume from the older partial `*_results.mat` frontier files under the same
    `output_tag`
  - writes live checkpoint files while a long run is in progress, then cleans them up on
    successful completion
- Kept the existing wrapper:
  - `extensions/re_no_politics/run_transition_re_policy_bridge_alpha_frontier.ps1`
- Updated workflow note:
  - `extensions/re_no_politics/workflow_re_policy_bridge_blend_ladder.md`
- Used the new resume logic to continue the stalled coarse frontier run:
  - command target:
    `run_transition_re_policy_bridge_alpha_frontier(5, [], 'alpha_frontier_k5')`
  - resumed at:
    `k = 4`, `alpha = 0.20`
  - did not restart the already completed `k = 1..3` work
- Coarse frontier read now locked in:
  - grid:
    `{0.00, 0.01, 0.015, 0.02, 0.03, 0.05, 0.10, 0.20, 0.50, 1.00}`
  - `k = 1`, `2`, `3`:
    max stable `alpha = 1.00`
  - `k = 4`:
    `alpha = 0.20` unstable
    `alpha = 0.10` unstable
    `alpha = 0.05` stable
  - `k = 5`:
    resumed monotone search stays at `alpha = 0.05`
- Interpretation update from this continuation:
  - the old `alpha = 0.02` lower bound was too conservative for the coarse `k <= 5` frontier
  - the blend object can absorb noticeably more current-price feedback than that at `k = 4` and
    `k = 5`
  - the sharp full-horizon `alpha = 0.015 -> 0.02` statement and the softer bounded-horizon
    frontier are now even more clearly distinct objects

### Session: 2026-04-09 (policy-bridge blend frontier and ladder)
- Added the policy-bridge blend seam to the NIMBY RE climb so the solver can interpolate between
  the fixed-price policy bridge and the pure by-period-price bridge.
- Solver seam already in place:
  - `extensions/re_no_politics/solve_transition_re_no_politics.m`
    now supports
    `params.policy_reference_mode = 'blended_current_and_fixed_price'`
    with
    `params.policy_reference_blend_weight`
- New full-horizon blend workflow:
  - `extensions/re_no_politics/run_transition_re_policy_bridge_blend_sweep.m`
  - `extensions/re_no_politics/run_transition_re_policy_bridge_blend_sweep.ps1`
  - `extensions/re_no_politics/workflow_re_policy_bridge_blend.md`
  - `extensions/re_no_politics/transition_re_policy_bridge_blend_report.md`
- New matched-budget ladder workflow:
  - `extensions/re_no_politics/run_transition_re_policy_bridge_blend_ladder.m`
  - `extensions/re_no_politics/run_transition_re_policy_bridge_blend_ladder.ps1`
  - `extensions/re_no_politics/workflow_re_policy_bridge_blend_ladder.md`
- Full-horizon blend read locked in this session:
  - stable:
    `alpha = 0.00`, `0.01`, `0.015`
  - first unstable tested full-horizon case:
    `alpha = 0.02`
  - by `alpha = 0.05`, the full-horizon case is materially worse again
  - on the stable full-horizon cases:
    max gap is about `0.00033`
    price range stays about `[1.9081, 2.1682]`
- Matched-budget `k`-ladder read from the same session:
  - `alpha = 1.00`:
    stable through `k = 3`, unstable at `k = 4`
  - `alpha = 0.05`:
    stable through `k = 4`
  - `alpha = 0.02`:
    stable through at least `k = 5` in the checkpointed ladder output
  - `alpha = 0.00`, `0.01`, `0.015`:
    stable through the full ladder `k = 9`
  - a longer timed rerun for `alpha = 0.02` reached a stable `k = 6` before entering `k = 7`,
    but that continuation hit the wall-clock cap before a clean stopping point
- Workflow interpretation updated in this session:
  - the full-horizon blend frontier is sharp
  - the matched-budget ladder frontier is softer
  - so the instability grows with both:
    the amount of current-price feedback
    and
    the length of the forward-looking horizon
  - this now gives the NIMBY RE climb a clearer sequence:
    reduced-form ladder = rung `0`
    fixed-price policy bridge = rung `1`
    blended policy bridge = rung `2`
    pure by-period bridge = short-horizon only
    full structural household-policy block = still the hard unsolved object

### Session: 2026-04-09 (reduced-form-first NIMBY RE ladder)
- Built the first explicitly reduced-form-first NIMBY RE branch to mirror the fertility workflow
  more closely than the structural policy-bridge branch does.
- New helper files:
  - `extensions/re_no_politics/build_reduced_form_price_operator_from_policy_bridge.m`
  - `extensions/re_no_politics/solve_reduced_form_price_path.m`
- New runners:
  - `extensions/re_no_politics/run_transition_re_reduced_form_one_step.m`
  - `extensions/re_no_politics/run_transition_re_reduced_form_k_step_ladder.m`
- New workflow packet:
  - `extensions/re_no_politics/run_transition_re_reduced_form_one_step.ps1`
  - `extensions/re_no_politics/run_transition_re_reduced_form_k_step_ladder.ps1`
  - `extensions/re_no_politics/run_transition_re_reduced_form_workflow.ps1`
  - `extensions/re_no_politics/workflow_re_reduced_form.md`
  - `extensions/re_no_politics/transition_re_reduced_form_report.md`
- New output files:
  - `extensions/re_no_politics/transition_re_reduced_form_one_step_summary.csv`
  - `extensions/re_no_politics/transition_re_reduced_form_one_step_results.mat`
  - `extensions/re_no_politics/transition_re_reduced_form_k_step_summary.csv`
  - `extensions/re_no_politics/transition_re_reduced_form_k_step_paths.csv`
  - `extensions/re_no_politics/transition_re_reduced_form_k_step_frontier.csv`
  - `extensions/re_no_politics/transition_re_reduced_form_k_step_results.mat`
- Reduced-form operator design locked in this session:
  - source benchmark:
    stable fixed-price policy-bridge path at `2.0`
  - current log price is fit on:
    - the `25-44` population-share gap from `2010`
    - the next-period log price gap relative to the benchmark price `2.0`
  - fitted next-price coefficient:
    about `0.4744`
  - bounded-fit RMSE on the benchmark path:
    about `0.0325`
  - reduced-form price box:
    `[1.75, 2.25]`
  - tail closure:
    flat benchmark tail at `2.0`
- One-step reduced-form result:
  - solved `2011` price about `2.0297`
  - converged in `22` iterations
- k-step reduced-form ladder result:
  - stable through the full forward horizon `k = 8`
  - tested RE weights:
    `{0.25, 0.50, 0.75, 1.00, 1.25}`
  - full-horizon (`k = 8`) solved `2011` price ranges roughly:
    `2.0329 -> 2.0557`
  - full-horizon solved `2018` price stays near:
    `2.0049`
- Workflow interpretation locked in this session:
  - this is the first NIMBY branch that really copies the fertility sequence rather than only
    copying the fertility fixed-point update
  - once the within-path household-policy feedback is replaced by a smooth aggregate operator,
    bounded RE becomes numerically easy
  - that means the demographic path alone is not the hard object
  - the hard object is the structural household-policy feedback map
  - the reduced-form ladder should therefore be treated as rung `0` for any future NIMBY RE climb,
    with the fixed-price policy bridge above it and the full structural solver above that
  - the reduced-form branch should still be described honestly:
    it is fit on the stable fixed-price benchmark and is not itself a structural NIMBY RE solution

### Session: 2026-04-08 (fertility-style RE transplant test)
- Added a separate direct-transplant branch for the NIMBY transition-path RE problem so the
  fertility project's whole-path fixed-point logic can be tested without overwriting the older
  candidate-search workflow.
- Solver change:
  - `extensions/re_no_politics/solve_transition_re_no_politics.m` now supports
    `params.outer_iteration_mode = 'fertility_style'`
  - in that mode, the solver skips candidate search and carries the whole relaxed path forward each
    iteration
  - added controls for:
    - `fixed_point_relaxation_weight`
    - `fixed_point_relaxation_space`
    - `fixed_point_price_min`
    - `fixed_point_price_max`
- Added dedicated runner:
  - `extensions/re_no_politics/run_demographic_forecast_re_no_politics_fertility_style.m`
- Added bounded-horizon continuation runner:
  - `extensions/re_no_politics/run_transition_re_no_politics_k_step_ladder.m`
- Added dedicated `k = 2` bridge workflow:
  - `extensions/re_no_politics/workflow_re_k2_bridge.md`
  - `extensions/re_no_politics/run_transition_re_k2_bridge_followup.m`
  - `extensions/re_no_politics/run_transition_re_k2_bridge_followup.ps1`
  - `extensions/re_no_politics/run_transition_re_k2_bridge_workflow.ps1`
  - `extensions/re_no_politics/write_transition_re_k2_bridge_report.ps1`
- Added note:
  - `extensions/re_no_politics/transition_re_fertility_style_note.md`
- Dedicated output file:
  - `extensions/re_no_politics/transition_re_no_politics_fertility_style_results.mat`
- Bounded-horizon output files:
  - `extensions/re_no_politics/transition_re_no_politics_k_step_ladder_summary.csv`
  - `extensions/re_no_politics/transition_re_no_politics_k_step_ladder_results.mat`
- Main tested specification:
  - warm start from `transition_re_no_politics_results.final_price_path`
  - outer loop `fertility_style`
  - relaxation space `log`
  - relaxation weight `0.10`
  - price band `[0.40, 5.00]`
  - `max_iter = 25`
- Observed result from the dedicated runner:
  - iterations completed: `25`
  - final max gap: `694.6074`
  - final max update: `0.0001`
  - final path range: `[0.4000, 5.0000]`
  - worst excess-demand period: `4`
- Earlier manual smoke tests in the same session showed the complementary failure mode:
  - unbounded level relaxation could reduce the residual numerically for a while
  - but it did so by drifting into absurd price regions rather than by finding a usable RE path
- New bounded-horizon continuation read from the same session:
  - `k = 1` solves immediately with final price `2.0003` and zero gap
  - `k = 2` already fails:
    final price path `[2.0003, 5.0000]`
  - implied price path at that iterate:
    `[2.0003, 164.3896]`
  - residual norm about `3.4928`
  - max gap about `159.3896`
  - the run therefore stops at `k = 2` because the bounded second-period price hits the upper
    limit while the RE gap remains large
- New `k = 2` bridge read from the same session:
  - default tail case (`path_end_price_tail`):
    implied second-period price about `164.3896`
  - fixed-tail cases (`initial_path_price_tail`, `fixed_price_2_0_tail`):
    implied second-period price about `162.9505`
  - in every tested case the bounded final second-period price still hits `5.0`
  - best bridge case still has max gap about `157.9505`
  - best bridge case still has second-period excess demand about `3.0334`
  - report written to:
    `extensions/re_no_politics/transition_re_k2_bridge_report.md`
- Added within-path policy bridge workflow:
  - `extensions/re_no_politics/workflow_re_policy_bridge.md`
  - `extensions/re_no_politics/run_transition_re_k2_policy_bridge_followup.m`
  - `extensions/re_no_politics/run_transition_re_k_step_policy_bridge_ladder.m`
  - wrappers:
    `extensions/re_no_politics/run_transition_re_k2_policy_bridge_followup.ps1`
    and
    `extensions/re_no_politics/run_transition_re_k_step_policy_bridge_ladder.ps1`
  - report writer:
    `extensions/re_no_politics/write_transition_re_policy_bridge_report.ps1`
- New policy bridge read from the same session:
  - dynamic benchmark with fixed tail at `2.0`:
    `k = 2` max gap about `157.9505`
  - steady-state-by-period-price bridge:
    `k = 2` max gap about `0.0065`
  - steady-state-fixed-price bridge:
    `k = 2` max gap about `0.0065`
  - short policy-bridge ladder:
    `k = 1` gap `0`
    `k = 2` gap about `0.0065`
    `k = 3` gap about `0.0208`
    `k = 4` gap about `68.7083`
  - fixed-price policy-bridge ladder:
    `k = 1` gap `0`
    `k = 2` gap about `0.0065`
    `k = 3` gap about `0.0125`
    `k = 4` gap about `0.0112`
    `k = 5` gap about `0.0008`
    `k = 6` gap about `0.0028`
    `k = 7` gap about `0.0028`
    `k = 8` gap about `0.0065`
    `k = 9` gap about `0.0016`
  - full 9-period fixed-price bridge path:
    `[2.0003, 2.0896, 2.1682, 2.1508, 2.0053, 2.0382, 1.9603, 1.9085, 1.9790]`
  - consolidated report written to:
    `extensions/re_no_politics/transition_re_policy_bridge_report.md`
  - added full workflow wrapper:
    `extensions/re_no_politics/run_transition_re_policy_bridge_workflow.ps1`
- Solver seam extended again in the same session:
  - `extensions/re_no_politics/solve_transition_re_no_politics.m` now supports
    `params.policy_reference_price_floor`
    and
    `params.policy_reference_price_cap`
  - these bounds clip the steady-state policy-reference path before loading policy objects
  - `load_ss_reference` now also retries the steady-state cache write/load a few times to handle
    transient contention on `SS_no_politics_iter.mat`
- Added anchored-policy follow-ups:
  - floor sweep:
    `extensions/re_no_politics/run_transition_re_policy_bridge_floor_sweep.m`
    `extensions/re_no_politics/run_transition_re_policy_bridge_floor_sweep.ps1`
    `extensions/re_no_politics/write_transition_re_policy_bridge_floor_report.ps1`
    `extensions/re_no_politics/workflow_re_policy_bridge_floor_sweep.md`
  - band sweep:
    `extensions/re_no_politics/run_transition_re_policy_bridge_band_sweep.m`
    `extensions/re_no_politics/run_transition_re_policy_bridge_band_sweep.ps1`
    `extensions/re_no_politics/write_transition_re_policy_bridge_band_report.ps1`
- New anchored-policy read from the same session:
  - refreshed fixed-price-`2.0` benchmark:
    max gap about `0.000116`
    price range about `[1.9081, 2.1682]`
  - floor sweep:
    unclipped by-period bridge max gap about `223.3768`
    floor `1.80` max gap about `27.4355`
    floor `1.85` max gap about `15.9070`
    floor `1.90` max gap about `5.4979`
    floor `1.95` max gap about `2.7894`
    floor `2.00` max gap about `0.2103`
    no tested floor restores full-horizon stability
  - band sweep:
    band `[1.95, 2.05]` max gap about `0.1516`
    band `[1.95, 2.10]` max gap about `1.0167`
    band `[1.90, 2.10]` max gap about `2.9907`
    band `[1.90, 2.15]` max gap about `2.9870`
    no tested band restores the fixed-price branch either
  - coarse fixed-price sweep:
    only `2.00` is stable on the grid
    `{1.85, 1.90, 1.95, 2.00, 2.05, 2.10, 2.15}`
  - refined local fixed-price sweeps:
    stable at `1.970`, `1.980`, `1.985`, `1.990`, `1.992`, `1.994`, `1.995`, `1.998`, `1.999`,
    `2.000`, `2.001`, `2.002`
    unstable at `1.960`, `1.965`, `2.003`, `2.004`, `2.005`
    current tested stable bracket is therefore roughly `[1.970, 2.002]`
- Interpretation locked in this session:
  - the direct fertility-style transplant is informative but not successful
  - starting from `k = 1` and extending the horizon does not rescue it
  - the failure appears as soon as the model has to internalize one period ahead
  - simplifying only the terminal steady-state tail is not enough either
  - replacing the full within-path policy feedback with steady-state policy rules is the first
    simplification that actually stabilizes the short-horizon object
  - if the same bridge is allowed to react to low current prices, it remains useful through `k = 3`
    but fails again by `k = 4`
  - if the bridge is fixed at policy price `2.0`, it stays numerically well behaved through the
    full 9-period horizon
  - clipping the by-period policy-reference path from below does not recover that fixed-price
    branch, even with a floor at `2.0`
  - clipping the by-period bridge into narrow benchmark bands around `2.0` does not recover it
    either
  - the fixed-price bridge is not a broad benchmark neighborhood either
  - it is, however, slightly weaker than a literal point mass at `2.0`
  - the old NIMBY RE problem is not just a bad local search rule
  - the fixed-point map itself is harsh enough that a simpler bridge object is more promising than
    more blind tuning of the direct transplant
  - the current best reduced-form interpretation is therefore a narrow benchmark-price neighborhood
    centered on the calibration price, with a sharper upper edge than lower edge
  - inference:
    because that narrow stable interval is centered on the benchmark calibration price, the branch
    still looks more like a benchmark-anchored policy proxy than a generally robust expectations
    rule

### Session: 2026-03-22 (qualitative RE pivot)
- The project interpretation changed materially during this session:
  the transition-path RE extension is now being treated as a supporting extension where qualitative
  intuition is enough; a tightly converged RE benchmark is no longer the required bar.
- Added:
  - `extensions/re_no_politics/transition_re_intuition_note.md`
  - `extensions/re_no_politics/workflow_re_intuition.md`
- The new note records:
  - the current qualitative RE takeaway from the completed runs
  - why the full transition-path RE problem is computationally hard in this model
  - acceptable simplified RE exercises if one more bounded numerical check is desired
  - an explicit future-revisit trigger: return to the extension when a better RE solver or a
    cleaner simplified model becomes available
- Key interpretation locked in this session:
  - the existing RE runs are informative enough for extension purposes
  - the solver can move the path, but it mostly trades residual norm against worst-gap performance
  - the main bottleneck remains localized at period `3`
  - further work should be limited to at most one cheap simplified RE sanity check unless a new
    result materially changes the story
- Updated `extensions/re_no_politics/README.md` so the workspace description now reflects the new
  qualitative target.
- Added a coarse lambda continuation workflow as the preferred one-more-pass RE exercise:
  - `extensions/re_no_politics/scale_demographic_path_lambda.m`
  - `extensions/re_no_politics/run_transition_re_lambda_continuation.m`
  - `extensions/re_no_politics/run_transition_re_lambda_continuation.ps1`
  - `extensions/re_no_politics/run_transition_re_lambda_workflow.ps1`
  - `extensions/re_no_politics/workflow_re_lambda_continuation.md`
- Lambda workflow design locked in this session:
  - scale the demographic path toward the 2010 baseline with `lambda`
  - coarse ladder `0, 0.25, 0.5, 0.75, 1`
  - warm-start each step from the previous final price path
  - hold solver settings fixed at the config-11-style control profile
  - interpret the run qualitatively rather than as a new precision benchmark
- Added benchmark-based coalition roadmap note:
  `extensions/re_no_politics/coalition_extension_from_benchmark.md`
- Coalition design conclusion locked in this session:
  - the coalition extension should be benchmarked against the published political model, not the
    no-politics RE branch
  - zero coalition weights should nest the benchmark exactly
  - the first comparison should be one-margin-at-a-time coalition weighting, not a multi-change
    dynamic extension
- Added long-compute benchmark runner for the coalition branch:
  - `extensions/re_no_politics/run_coalition_benchmark_sensitivity.m`
  - `extensions/re_no_politics/run_coalition_benchmark_sensitivity.ps1`
  - `extensions/re_no_politics/write_coalition_benchmark_report.ps1`
- Coalition benchmark runner design locked in this session:
  - cases: zero-alpha benchmark, owner only, old-owner only, leveraged-owner only, big-house only,
    combined default
  - same steady-state search grid for every case
  - outputs: `coalition_benchmark_summary.csv` and `coalition_benchmark_results.mat`
  - report: `coalition_benchmark_report.md`
- Added one-day away orchestrator for the current extension packet:
  - `extensions/re_no_politics/run_extension_away_workflow.ps1`
  - `extensions/re_no_politics/workflow_extension_away.md`
- Away-workflow chain locked in this session:
  - attach to or finish the live lambda continuation run
  - refresh the RE follow-up report
  - run the benchmark-based coalition sensitivity batch
  - write the coalition benchmark report
  - stop there rather than broadening scope
- The away-workflow chain completed successfully on 2026-03-22.
  Logs:
  - `extensions/re_no_politics/workflow_logs/transition_re_lambda_workflow.log`
  - `extensions/re_no_politics/workflow_logs/extension_away_workflow.log`
- Final lambda continuation outputs:
  - `extensions/re_no_politics/transition_re_lambda_continuation_summary.csv`
  - `extensions/re_no_politics/transition_re_lambda_continuation_results.mat`
- Lambda continuation read:
  - `lambda = 0`: residual norm `0.189800232028244`, max gap `0.210720915080019`, worst gap period `8`
  - `lambda = 0.25`: residual norm `0.164965629625652`, max gap `0.17864001132828`, worst gap period `8`
  - `lambda = 0.5`: residual norm `0.145972386288913`, max gap `0.152174686037218`, worst gap period `8`
  - `lambda = 0.75`: residual norm `0.133643529519012`, max gap `0.159104190915086`, worst gap period `3`
  - `lambda = 1`: residual norm `0.128180623096122`, max gap `0.165930860076853`, worst gap period `3`
- Interpretation after lambda continuation:
  - the path back to the full-shock case looks smooth rather than discontinuous
  - the low-lambda cases shift the hardest period to the back of the path
  - near the full shock the old period-`3` bottleneck reappears
  - the full-shock row lands close to the existing control benchmark, which is useful extension
    evidence even without a fully converged RE solution
- Final coalition benchmark outputs:
  - `extensions/re_no_politics/coalition_benchmark_summary.csv`
  - `extensions/re_no_politics/coalition_benchmark_results.mat`
  - `extensions/re_no_politics/coalition_benchmark_report.md`
- Coalition benchmark read:
  - equal-weight benchmark best price: `1.81379310344828`
  - combined default coalition best price: `1.82758620689655`
  - combined price shift: `+0.0137931034482757`
  - owner-only and old-owner-only each shift the best price up by the same grid increment
  - leverage-only and big-house-only move the weighted-vote object but not the selected best price
    on this coarse price grid
- Operational state at this update:
  - no active MATLAB batch remains for the extension packet
  - the away watcher has finished cleanly
- Added standalone paper-style RE section packet under:
  `extensions/re_no_politics/re_extension_section/`
- Files created there:
  - `make_re_extension_figures.m`
  - `re_extension_section.tex`
  - `build_re_extension_section.ps1`
  - compiled PDF `re_extension_section.pdf`
  - generated figures:
    - `figures/re_lambda_continuation.pdf`
    - `figures/re_solver_comparison.pdf`
- Section design choice locked in this session:
  - do not pretend we have a perfect original-paper benchmark overlay from the current extension
    outputs
  - instead use two clean paper-quality figures:
    - continuation by `lambda`
    - full-shock benchmark-control versus relaxed challenger
  - explain the comparison to the paper's benchmark exercise in text rather than fabricating a
    numeric overlay that is not currently in a clean export file
- Later in the same session, this was upgraded from a text-only comparison to a caveated heuristic
  overlay because a usable local benchmark image was available:
  - digitized source:
    `extensions/re_no_politics/re_extension_section/digitized_paper_benchmark_2010_2018.csv`
  - benchmark image source for digitization:
    `graphs/Baseline.jpg`
  - added figure:
    `extensions/re_no_politics/re_extension_section/figures/re_vs_paper_benchmark.pdf`
- Benchmark overlay read:
  - published benchmark over 2010--2018 rises by about `3.3` log points relative to 2010
  - full-shock RE no-politics path over the same window moves by less than `0.1` log points
  - interpretation:
    the current RE extension does not by itself look like it ``brings NIMBY forward''
  - caveat:
    this is only a directional timing comparison because the benchmark retains politics and the RE
    extension shuts politics down
- Added a combined paper-style packet:
  `extensions/re_no_politics/nimby_and_housing_extensions/`
- Files created there:
  - `make_nimby_and_housing_extensions_figures.m`
  - `nimby_and_housing_extensions.tex`
  - `build_nimby_and_housing_extensions.ps1`
  - compiled PDF:
    `nimby_and_housing_extensions.pdf`
  - coalition figure:
    `figures/coalition_extension.pdf`
- Combined packet design choice:
  - title:
    `NIMBY and Housing Extensions: RE and Coalitions`
  - extension 1 uses the existing RE continuation and benchmark-overlay figures
  - extension 2 adds a new reduced-form coalition-power figure rather than pretending we have a
    full coalition-formation game
- Coalition figure message locked in this session:
  - owner-only, old-owner-only, and combined coalition-weighting each raise the selected benchmark
    price by about `0.760456%`
  - leveraged-owner-only and big-house-only move the political object but do not move the selected
    price on the current grid
  - the coalition extension therefore strengthens the benchmark mechanism more than the RE
    extension, but should be labeled as reduced-form political amplification rather than a true
    coalition game
- Added two paper-safe RE insertion drafts:
  - `extensions/re_no_politics/rational_expectations_footnote.md`
  - `extensions/re_no_politics/rational_expectations_appendix_note.md`
- New recommendation locked in:
  - do not sell the current RE work as a standalone extension section in the main paper
  - instead use a short footnote on the random-walk expectations assumption and, if needed, a brief
    appendix note on computational scope and the stripped-down RE diagnostic
- Added a compiled review packet for that recommendation under:
  `extensions/re_no_politics/rational_expectations_note/`
- Files there:
  - `rational_expectations_note.tex`
  - `rational_expectations_note.pdf`
  - `build_rational_expectations_note.ps1`
- Purpose of the new packet:
  - make it easy to review the exact footnote-plus-appendix version without reopening the older,
    more ambitious standalone RE section


### Session: 2026-03-22 (focus-objective workflow completion)
- The focus-objective workflow finished successfully on 2026-03-21.
  Workflow log:
  `extensions/re_no_politics/workflow_logs/transition_re_focus_objective_workflow.log`
- Final focus-objective summary now exists:
  `extensions/re_no_politics/transition_re_focus_objective_summary.csv`
- Focus-objective outcome:
  - `config11_focus_relaxed`, `aggressive_p2_b8_focus_relaxed`, and
    `aggressive_p2_b8_focus_loose_slack` all tied the canonical control max gap
    (`0.165893855900913`) but worsened residual norm to about `0.128660740438`
    and stalled after only `2` nontrivial updates
  - `aggressive_p2_b8_focus_wider_target` was slightly worse on both residual norm and max gap
  - `aggressive_p2_b8_hybrid_gap_guard` did not create a new regime; it simply reproduced the old
    relaxed-hybrid challenger result:
    residual norm `0.128074177550138`, max gap `0.166384245138625`,
    `last_nontrivial_iter = 4`
- Interpretation after the completed focus-objective branch:
  - pure `focus` mode is too myopic and stalls early
  - the guarded `hybrid_focus` case still buys persistence / residual improvement only by accepting
    the larger max gap
  - therefore the current issue is not "which remaining focus-tuning knob should we try?" but
    whether the solver objective itself needs redesign
- The staged post-workflow watcher also completed successfully.
  Watcher log:
  `extensions/re_no_politics/workflow_logs/transition_re_focus_post_workflow.log`
- Post-workflow decision:
  - baseline control max gap: `0.165893855900913`
  - best completed focus-objective max gap: `0.165893855900913`
  - measured improvement: `0`
  - result: no extra focus-validation pack was launched, because the configured threshold was
    `1e-6`
- The refreshed report remains:
  `extensions/re_no_politics/transition_re_followup_report.md`
- Operational state at the start of this session:
  - no active MATLAB batch for the NIMBY focus-objective workflow
  - no active focus-objective watcher still running

### Session: 2026-03-21 (overnight workflow completion)
- The away workflow completed successfully on 2026-03-20. The watcher log
  `extensions/re_no_politics/workflow_logs/transition_re_day_workflow.log` shows:
  - candidate-selection batch monitored until summary creation at `2026-03-20 19:36:21`
  - report refreshed immediately after candidate selection
  - validation pack ran next and finished at `2026-03-20 22:36:52`
  - report refreshed again and workflow ended successfully
- Candidate-selection follow-up outputs now exist:
  - `extensions/re_no_politics/transition_re_candidate_selection_summary.csv`
  - `extensions/re_no_politics/transition_re_candidate_selection_results.mat`
- Best candidate-selection row:
  - case: `aggressive_p2_b8_hybrid_relaxed`
  - residual norm: `0.128074177550138`
  - max gap: `0.166384245138625`
  - max iter: `6`
  - last nontrivial iteration: `4`
  - nontrivial update count: `4`
  - rule settings:
    - `candidate_selection_mode = hybrid_focus`
    - `greedy_block_accept = false`
    - `candidate_residual_slack = 0.0002`
    - `focus_residual_slack = 0.0005`
- Baseline control from the same sweep remained:
  - case: `config11_global_control`
  - residual norm: `0.128123139189984`
  - max gap: `0.165893855900913`
  - last nontrivial iteration: `3`
  - nontrivial update count: `3`
- Interpretation after candidate selection:
  - the relaxed hybrid rule improves residual norm and extends persistence by one iteration
  - but it worsens the worst max gap materially relative to the control
  - so the result is informative but not a clean dominance win
- Validation-pack outputs now exist:
  - `extensions/re_no_politics/transition_re_validation_summary.csv`
  - `extensions/re_no_politics/transition_re_validation_results.mat`
- Validation result:
  - `best_variant_validation` (source `aggressive_p2_b8_hybrid_relaxed`) reproduces the lower
    residual norm and the same `last_nontrivial_iter = 4`
  - `baseline_control_validation` reproduces the lower max gap and `last_nontrivial_iter = 3`
  - neither case pushes nontrivial updates past iteration `4`
- Current report file:
  `extensions/re_no_politics/transition_re_followup_report.md`
- Current bottleneck diagnosis remains unchanged in location:
  - worst gap period: `3`
  - worst excess-demand period: `3`
  - action region highlighted by prior accepted updates: block `4-6`
- Immediate next technical question is no longer "did the workflow run?" but "which objective do we
  actually want to optimize?" The data now show a real tradeoff:
  - control case is better on max gap
  - relaxed hybrid case is better on residual norm and persistence
- Wrote an explicit decision memo:
  `extensions/re_no_politics/transition_re_objective_tradeoff_report.md`
  using the saved candidate-history diagnostics from
  `transition_re_candidate_selection_results.mat`.
- Main memo finding:
  - `aggressive_p2_b8_hybrid_relaxed` shifts accepted moves later in the path (`6-8`, then `5-7`)
  - but its selected wins come from the global rule, not from focus-region wins
  - so it looks more like error redistribution than actual relief of the peak period-`3` problem
- Added the next bounded runner:
  - `extensions/re_no_politics/run_transition_re_focus_objective_followup.m`
  - `extensions/re_no_politics/run_transition_re_focus_objective_followup.ps1`
  - `extensions/re_no_politics/run_transition_re_focus_objective_workflow.ps1`
  - `extensions/re_no_politics/workflow_focus_objective.md`
- Focus-objective case family:
  - relaxed `focus` mode around the config-11 control profile
  - relaxed `focus` mode around the aggressive `p2_b8` profile
  - looser focus residual slack around the aggressive profile
  - wider targeted-region focus around the aggressive profile
  - one `hybrid_focus` guard case with tighter emphasis on focus-gap improvement
- The focus-objective workflow was started in a detached PowerShell process on 2026-03-21.
  Current workflow log:
  `extensions/re_no_politics/workflow_logs/transition_re_focus_objective_workflow.log`
- At launch, the workflow moved through:
  - `objective_tradeoff_report`
  - into the live `focus_objective_followup` MATLAB stage
- Current live process note:
  `run_transition_re_focus_objective_followup` is running via MATLAB batch as of this session.
- Added a post-workflow watcher:
  - `extensions/re_no_politics/run_transition_re_focus_post_workflow.ps1`
  - `extensions/re_no_politics/run_transition_re_focus_validation_pack.m`
  - `extensions/re_no_politics/run_transition_re_focus_validation_pack.ps1`
- Post-workflow rule:
  - wait for the current focus-objective workflow to finish
  - compare the best completed focus-objective row against canonical control
    `config11_global_control`
  - run one additional validation only if max gap improves by more than `1e-6`
  - otherwise stop cleanly, refresh the report, and treat the result as evidence that the current
    objective family is not enough

### Session: 2026-03-20 (candidate-selection follow-up queued)
- Recovered the interrupted NIMBY calibration state from the repo files. The completed numerical
  outputs are still the refreshed tuning summary, long-run follow-up, and block-search follow-up;
  there was no partially completed candidate-selection summary to resume.
- Found that the active batch MATLAB job on this machine is actually the fertility project runner
  `run_ge_fertility_main`, not a NIMBY batch process. To avoid stacking two heavy runs, the next
  NIMBY follow-up was queued behind it instead of being launched immediately in parallel.
- Fixed a real solver issue in `extensions/re_no_politics/solve_transition_re_no_politics.m`:
  `candidate_selection_mode = 'focus'` and `'hybrid_focus'` were previously behaving the same.
  They now differ as intended:
  - `focus`: sequential acceptance uses the worst-period/focus metric only (subject to residual slack)
  - `hybrid_focus`: sequential acceptance allows either a focus-metric improvement or the global
    residual/gap improvement rule
- Added `extensions/re_no_politics/run_transition_re_candidate_selection_followup.m`:
  - resumable live checkpoints
  - canonical outputs:
    `transition_re_candidate_selection_summary.csv` and
    `transition_re_candidate_selection_results.mat`
  - 8 narrow cases around:
    - the config `11` control profile (`p2`, `b4`)
    - the `aggressive_p2_b8` profile
  - levers tested:
    - `candidate_selection_mode` (`global`, `focus`, `hybrid_focus`)
    - greedy vs non-greedy block acceptance
    - baseline vs looser residual slack
- Added wrappers for unattended execution:
  - `run_transition_re_candidate_selection_followup.ps1`
  - `queue_transition_re_candidate_selection_followup.ps1`
- Static MATLAB lint check succeeded:
  - `run_transition_re_candidate_selection_followup.m`: 0 code-analyzer issues
  - `solve_transition_re_no_politics.m`: analyzer warnings only; no syntax failure
- The queue watcher was started in a detached PowerShell process and is currently waiting for the
  active batch MATLAB jobs to clear. Current queue log:
  `extensions/re_no_politics/workflow_logs/candidate_selection_followup_queue.log`
- Once the queue releases, the run wrapper will write logs to:
  - `extensions/re_no_politics/workflow_logs/candidate_selection_followup_stdout.log`
  - `extensions/re_no_politics/workflow_logs/candidate_selection_followup_stderr.log`
- No new NIMBY numerical summary should be inferred yet; the follow-up has been staged and queued,
  not completed.
- Added pass-level instrumentation to `extensions/re_no_politics/solve_transition_re_no_politics.m`
  behind `params.save_candidate_history`. When enabled, the solver now stores:
  - iteration-level targeted periods / blocks
  - pass-level focus periods and block-start order
  - candidate-by-candidate diagnostics:
    label, block, scale, residual norm, max gap, focus metrics, whether it won on the focus rule,
    whether it won on the global rule, and whether greedy acceptance fired
- Updated `run_transition_re_candidate_selection_followup.m` so the queued run enables that
  instrumentation and saves compact per-case snapshots into
  `transition_re_candidate_selection_results.mat` rather than only a flat summary table.
- Added a cheap reporting script:
  `extensions/re_no_politics/write_transition_re_followup_report.ps1`
  which reads the existing CSV summaries (and the candidate-selection summary once it exists) and
  writes:
  `extensions/re_no_politics/transition_re_followup_report.md`
- Current report takeaway before the queued run starts:
  - best tuning config remains `11`
  - best block-search row is `fine_p3_b6` on residual norm, but the bottleneck still localizes at
    period `3`
  - the queued candidate-selection follow-up is the next structured test for breaking the
    iteration-3/4 plateau
- Added unattended next-stage workflow files:
  - `extensions/re_no_politics/run_transition_re_validation_pack.m`
  - `extensions/re_no_politics/run_transition_re_validation_pack.ps1`
  - `extensions/re_no_politics/run_transition_re_day_workflow.ps1`
  - `extensions/re_no_politics/workflow_day.md`
- Validation-pack logic:
  - waits for `transition_re_candidate_selection_summary.csv`
  - takes baseline control `config11_global_control`
  - takes the best non-baseline row from the candidate-selection summary
  - reruns both at `max_iter = 8` with candidate-history diagnostics still enabled
  - writes `transition_re_validation_summary.csv` and `transition_re_validation_results.mat`
- Extended `write_transition_re_followup_report.ps1` so the Markdown report now includes the
  validation stage once it exists.
- Started the day-workflow watcher in a detached PowerShell process. Current watcher log:
  `extensions/re_no_politics/workflow_logs/transition_re_day_workflow.log`
- At launch, the watcher correctly detected that the candidate-selection batch was already active
  (`run_transition_re_candidate_selection_followup`) and attached to it rather than starting a
  duplicate run.

### Session: 2026-03-18 (sequential RE candidate-search fix)
- Diagnosed why the latest tuning grid was completely uninformative: in
  `extensions/re_no_politics/solve_transition_re_no_politics.m`, the
  `sequential_blocks` branch computed a regularized full-path update but never evaluated it, and
  then built local block candidates off the raw implied path rather than the updater's damped /
  regularized log step. That meant the tuning parameters were effectively bypassed in sequential
  mode, which helps explain why all rows in `transition_re_tuning_summary.csv` ended on
  `current_path`.
- Patched the sequential search so it now:
  1. evaluates the regularized full-path update as an actual candidate, and
  2. uses `update_price_path_re_no_politics` on each pass to refresh the local log-step direction
     before trying block moves.
- Short-horizon runtime verification (4 periods from the 2010-2013 slice, `max_iter = 1`,
  `sequential_block_size = 2`) succeeded in MATLAB and accepted a real update:
  `sequential_block_p2_2_3_0.01` rather than `current_path`.
- Smoke-test diagnostics after the patch:
  - residual norm about `0.1166`
  - max absolute gap about `0.1673`
  - final price range about `2.000000` to `2.000440`
- Full wrapper verification on the actual 2010-2018 path also succeeded:
  `run_demographic_forecast_re_no_politics` now saves a result whose accepted update is
  `sequential_block_p2_1_3_0.01` rather than `current_path`.
- Full-path one-step diagnostics after the patch:
  - residual norm about `0.1293`
  - max absolute gap about `0.1673`
  - final price range about `2.000000` to `2.000450`
  - targeted periods reported by the wrapper: `[2 3 4]`
- Runtime note: the full one-step wrapper run completed in about 4.7 minutes on this machine,
  which is materially faster than the older long-runtime notes and makes a fresh tuning-grid rerun
  more practical.
- Full-path `max_iter = 3` verification also completed under the patched sequential search.
  The final accepted update remained `sequential_block_p2_1_3_0.01`, the final price range widened
  modestly to about `2.000000` to `2.001336`, and the final max absolute gap moved only slightly
  to about `0.166341`.
- Interpretation after the 3-iteration run: the patch successfully moved the solver off the old
  `current_path` stall, and local updates now compound a bit rather than stopping immediately, but
  the convergence gain per iteration is still small. The next step should therefore be fresh tuning
  plus a better localized acceptance/search rule, not more blind reruns of the old grid.
- Hardened `run_transition_re_tuning_grid.m` for unattended work:
  - added live checkpoint files after each config,
  - added resume-from-checkpoint logic, and
  - kept the canonical summary/materialized results only for completed runs.
- Completed the refreshed tuning sweep after resuming from checkpoint. New canonical summary:
  `extensions/re_no_politics/transition_re_tuning_summary.csv`.
- Best tuning row is config `11`:
  - `damping = 0.15`
  - `smoothing_weight = 8`
  - `targeted_correction_weight = 0.20`
  - `line_search_scales = [0.1 0.05 0.02 0.01]`
  - residual norm about `0.128123`
  - max absolute gap about `0.165894`
- Added `run_transition_re_longrun_followup.m` to run resumable longer-horizon tests on the top
  tuning configs. Current follow-up summary:
  `extensions/re_no_politics/transition_re_longrun_summary.csv`.
- Long-run follow-up result: the top 3 configs (IDs `11`, `3`, `7`) were run at `max_iter = 5`
  and `10`, and all of them still ended their final iteration on `current_path` with no further
  update accepted. So the current solver now escapes the old initial stall, but it still plateaus
  after a few passes.
- Added a hybrid candidate-selection rule in `solve_transition_re_no_politics.m` that allows a
  candidate to win on max-gap improvement if the residual norm does not worsen materially.
- Focused verification on the current best config (`11`, `max_iter = 5`) after that selection
  patch:
  - iteration 1 accepted `sequential_block_p2_1_3_0.02`
  - iteration 2 accepted `sequential_block_p2_4_6_0.10`
  - iteration 3 accepted `sequential_block_p2_4_6_0.01`
  - iterations 4 and 5 returned to `current_path`
  - final price range about `2.000000` to `2.001782`
- Interpretation now: the meaningful numerical bottleneck is no longer "can the solver update at
  all?" but "how do we keep improving after the first 2-3 local block moves?" The next sensible
  calibration step is a targeted search over block-search aggressiveness around config `11`, not
  another broad damping/smoothing sweep.
- Added `run_transition_re_block_search_followup.m` to run a resumable focused grid around config
  `11`, varying:
  - `line_search_scales`
  - `block_sweep_passes`
  - `max_blocks_per_pass`
- Completed that targeted block-search follow-up. Current summary:
  `extensions/re_no_politics/transition_re_block_search_summary.csv`.
- Main result from the block-search follow-up:
  - none of the cases materially beat the best residual/gap from the broad tuning summary
  - baseline-like cases still plateau by iteration `3`
  - `aggressive_p2_b8` kept nontrivial updates alive through iteration `4`, but its final residual
    norm was slightly worse (`~0.128128`) and its final max gap was not better
- Current interpretation after the focused search:
  - more block-search aggression alone is not enough
  - the next experiment should target the acceptance rule itself (for example non-greedy pass
    selection, looser residual slack, or an explicit worst-period objective), not more copies of
    the same scale/pass grid
- Practical implication: the old pre-fix tuning summary has now been superseded; use the refreshed
  `extensions/re_no_politics/transition_re_tuning_summary.csv` for any current numerical reading.
- Direct call note: `solve_transition_re_no_politics` still assumes the baseline
  `code/steadystate/` folder is already on the MATLAB path; the project wrapper
  `run_demographic_forecast_re_no_politics` does add that path correctly.

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

### Session: 2026-04-10 (NIMBY compiled sidecar bootstrap)
- Added `extensions/re_no_politics/compiled_sidecar/` as a separate compiled solver workspace
  inside the NIMBY project.
- The first compiled target is the reduced-form RE branch in
  `extensions/re_no_politics/solve_reduced_form_price_path.m`.
- Added a MATLAB exporter at
  `extensions/re_no_politics/compiled_sidecar/matlab/export_reduced_form_input_pack.m`
  that writes both sidecar input packs and MATLAB truth outputs.
- Added a standalone C++ solver and CLI at
  `extensions/re_no_politics/compiled_sidecar/src/reduced_form_solver.cpp` and
  `extensions/re_no_politics/compiled_sidecar/src/reduced_form_cli.cpp`.
- Added portable build/export/run wrappers so the sidecar can be built and run from the project
  folder without touching the published baseline code.

### Session: 2026-04-10 (NIMBY structural transition-pass sidecar)
- Added a bounded structural exporter at
  `extensions/re_no_politics/compiled_sidecar/matlab/export_transition_pass_input_pack.m`.
- Added a standalone compiled transition-pass solver at
  `extensions/re_no_politics/compiled_sidecar/src/transition_pass_solver.cpp` and
  `extensions/re_no_politics/compiled_sidecar/src/transition_pass_cli.cpp`.
- Added wrappers
  `extensions/re_no_politics/compiled_sidecar/export_transition_pass_input.ps1`,
  `extensions/re_no_politics/compiled_sidecar/run_transition_pass_cli.ps1`, and
  `extensions/re_no_politics/compiled_sidecar/validate_transition_pass.ps1`.
- Verified the `transition_pass_t4_diag` pack against MATLAB truth:
  - `policy_idx_b` differences: `0`
  - `policy_idx_a` differences: `0`
  - `valuefunctions` max abs diff: about `7.15e-06`
  - aggregate-path differences: machine precision
- The current compiled structural scope is the expensive bounded `run_transition_pass` object in
  the default `full_backward` mode, not yet the full outer RE candidate-search loop.

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
- Setup plan archived to `old/project_plan_2026-02-18.md`; `STATUS.md` is the only active tracker

---

## Key files

| Role | Path |
|---|---|
| Paper source (LyX) | `research_projects/02_nimbyism_and_housing_supply/Gross and Chivers (2025) NIMBYism and the Housing Supply.lyx` |
| Published PDF | `research_projects/02_nimbyism_and_housing_supply/Gross and Chivers (2025) NIMBYism and the Housing Supply.pdf` |
| MATLAB steady-state | `research_projects/02_nimbyism_and_housing_supply/code/steadystate/SolveSS.m` |
| Stata data pipeline | `research_projects/02_nimbyism_and_housing_supply/code/data/merge data.do` |
| Upstream fix log | `research_projects/02_nimbyism_and_housing_supply/UPSTREAM_FIX_LOG.md` |
| Referee reports | `research_projects/02_nimbyism_and_housing_supply/referee/Economic Journal Referee Reports.docx` |

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

---

### Session: 2026-04-10 (NIMBY compiled OpenMP speed pass)
- Kept the separate compiled sidecar under `extensions/re_no_politics/compiled_sidecar/` and moved from pure coverage work to runtime work.
- Confirmed the portable LLVM-MinGW toolchain supports OpenMP (`-fopenmp=libomp`) and enabled it in the sidecar CMake build.
- Parallelized the hot structural Bellman loops inside `src/transition_pass_solver.cpp`:
  - expected continuation-value construction across `(z, a, b)` states
  - state-by-state choice maximization across `(z, a, b)` states
- Revalidated the bounded structural pass on `transition_pass_t4_diag`:
  - exact policy indices
  - value-function max abs diff still about `7.15e-06`
  - aggregate path differences still at floating-point noise
- Measured structural-pass runtime on `transition_pass_t4_diag` at about `5.10s`, down from about `25.52s` before OpenMP.
- Re-ran the bounded outer RE CLI on `transition_re_t4_fixed_terminal` and it now finishes in about `229.55s`; before the speed pass it did not finish within a 20-minute timeout.
- Important caveat:
  - the bounded compiled outer RE object is now operational but still not exact MATLAB parity on that exported fixed-terminal pack
  - compiled summary on the latest run:
    - `iterations = 3`
    - `final_max_abs_gap ~= 0.1683`
    - `final_residual_norm ~= 0.1092`
    - `final_label = sequential_block_p2_4_4_0.01`
  - saved MATLAB pack summary remains:
    - `final_max_abs_gap ~= 0.1664`
    - `final_residual_norm ~= 0.1161`
    - accepted update `sequential_block_p2_1_3_0.01`
- Read going forward:
  - the structural transition pass is now fast enough that the outer RE sidecar is practical for bounded runs
  - the next NIMBY compiled task is parity/tie-break logic in the bounded outer RE loop, not another port

---

### Session: 2026-04-10 (NIMBY bounded outer-RE parity)
- Fixed the compiled bounded outer-RE mismatch in `extensions/re_no_politics/compiled_sidecar/src/transition_re_solver.cpp`.
- Two concrete bugs mattered:
  - the compiled regularized update step was solving a tridiagonal approximation, while MATLAB's
    `second_diff' * second_diff` penalty is pentadiagonal
  - the compiled sequential-block layer had a return-path mismatch relative to MATLAB's
    `sequential_return_endpoint = false` behavior
- Replaced the approximate regularization solve with an exact dense linear solve for the bounded
  update system.
- Re-ran the bounded fixed-terminal outer-RE pack and matched MATLAB exactly up to floating-point
  noise:
  - accepted update label `sequential_block_p2_1_3_0.01`
  - final max gap about `0.16636905120656`
  - final residual norm about `0.11611478792937`
- Added `extensions/re_no_politics/compiled_sidecar/validate_transition_re.ps1`, which now
  validates the full bounded outer-RE pack against MATLAB truth.
- Current runtime read after the OpenMP speed pass plus exact update fix:
  - bounded fixed-terminal compiled outer RE now finishes in about `49.7s`
  - that is down from the earlier `~229.6s` compiled read and far below the old timeout state
- Updated read going forward:
  - the bounded fixed-terminal outer RE object is now both practical and validated
  - the next NIMBY compiled target is broader exported-pack coverage, not basic bounded-pack parity

---

### Session: 2026-04-10 (NIMBY bounded candidate-selection coverage)
- Extended the compiled bounded outer-RE sidecar beyond the original fixed-terminal/global pack.
- Added bounded pack export support for candidate-selection settings in
  `extensions/re_no_politics/compiled_sidecar/matlab/export_transition_re_input_pack.m`:
  - `candidate_selection_mode`
  - `focus_gap_improvement_tol`
  - `focus_excess_improvement_tol`
  - `focus_residual_slack`
- Added `re_params_strings.csv` to the bounded outer-RE pack format and kept backward compatibility:
  - old packs still default to `candidate_selection_mode = global`
  - missing focus tolerances fall back to compiled defaults
- Ported MATLAB's sequential candidate-selection logic into
  `extensions/re_no_politics/compiled_sidecar/src/transition_re_solver.cpp`:
  - `global`
  - `focus`
  - `hybrid_focus`
  using the same focus-gap / focus-excess / residual-slack rule as the MATLAB solver.
- Added pack-generation support in
  `extensions/re_no_politics/compiled_sidecar/export_transition_re_input.ps1` for:
  - `-CandidateSelectionMode`
  - focus-tolerance overrides
- Revalidated the original bounded pack after the option-boundary change:
  - `transition_re_t4_fixed_terminal` still matches MATLAB to floating-point noise
- Exported and validated two new bounded packs:
  - `transition_re_t4_fixed_terminal_focus`
  - `transition_re_t4_fixed_terminal_hybrid_focus`
- Current read:
  - all three bounded fixed-terminal candidate-selection modes now match MATLAB to floating-point
    noise on the exported `T = 4` packs
  - on this particular bounded case they happen to choose the same accepted update path, so the
    benefit is broader mode coverage rather than a new numerical result
  - the next compiled NIMBY target is now richer continuation/reference-pack coverage, not
    candidate-selection parity

---

### Session: 2026-04-10 (NIMBY fixed-policy bridge sidecar mode)
- Extended the compiled sidecar through the first non-`full_backward` transition-policy mode:
  `transition_policy_mode = steady_state_fixed_price`.
- Added optional transition-pass pack metadata in
  `extensions/re_no_politics/compiled_sidecar/src/transition_pass_solver.cpp`:
  - `meta_strings.csv` with `transition_policy_mode`
  - optional exported static reference policy/value paths:
    - `reference_policy_idx_b.csv`
    - `reference_policy_idx_a.csv`
    - `reference_valuefunctions.csv`
- Kept backward compatibility:
  - old `full_backward` packs still load without the new files
  - missing `meta_strings.csv` defaults the compiled pass to `full_backward`
- Extended the MATLAB pass exporter in
  `extensions/re_no_politics/compiled_sidecar/matlab/export_transition_pass_input_pack.m` so it can
  emit:
  - the original `full_backward` pass pack
  - a static fixed-policy bridge pack using one exported steady-state reference price
- Extended the bounded RE exporter in
  `extensions/re_no_politics/compiled_sidecar/matlab/export_transition_re_input_pack.m` and the
  PowerShell wrappers so the same fixed-policy bridge mode can be exported for the standalone outer
  RE CLI.
- Exported and validated the new bounded structural pass pack:
  - `transition_pass_t4_fixed_policy_2_0`
  - exact policy indices
  - value-function max abs diff about `1.19e-07`
  - aggregate paths at floating-point noise
  - compiled runtime about `1.65s`
- Exported and validated the new bounded outer-RE pack:
  - `transition_re_t4_fixed_terminal_fixed_policy_2_0`
  - validator passes against MATLAB to floating-point noise
  - final max gap about `0.070564`
  - final residual norm about `0.044122`
  - compiled runtime about `0.76s`
- Current read:
  - the sidecar now covers both the bounded `full_backward` branch and the first bounded policy
    bridge branch
  - the next continuation/reference mode, if we keep going, is the harder
    `steady_state_by_period_price` branch, which would require either exported by-period reference
    paths or a standalone steady-state reference builder

---

### Session: 2026-04-10 (NIMBY steady-state and dynamic-reference sidecar)
- Added a standalone compiled steady-state reference solver:
  - header `extensions/re_no_politics/compiled_sidecar/include/nimby_sidecar/steady_state_solver.hpp`
  - implementation `extensions/re_no_politics/compiled_sidecar/src/steady_state_solver.cpp`
  - CLI `extensions/re_no_politics/compiled_sidecar/src/steady_state_cli.cpp`
- Added a MATLAB truth-pack exporter and wrappers for that steady-state solver:
  - `matlab/export_steady_state_input_pack.m`
  - `export_steady_state_input.ps1`
  - `run_steady_state_cli.ps1`
  - `validate_steady_state.ps1`
- Validated the standalone steady-state solver on `steady_state_p2_rb0_03`:
  - exact policy indices
  - value-function max abs diff about `5.25e-06`
  - density differences at floating-point noise
  - housing demand / debt stock differences at floating-point noise
- Rewired the compiled transition-pass sidecar to use compiled steady-state references on demand:
  - terminal reference modes now resolve in C++
  - steady-state policy bridges can now be built in C++ at changing prices
  - exported fixed-policy tables are still supported as a fallback, but they are no longer the only
    route
- Extended the transition-pass / bounded-RE pack contract with the dynamic reference settings:
  - terminal reference mode / price
  - policy reference mode / price
  - blend weight
  - policy-reference floor / cap
- Exported and validated dynamic bounded RE packs that exercise those new compiled reference paths:
  - `transition_re_t4_fixed_terminal_by_period_policy`
  - `transition_re_t4_path_end_terminal`
  - `transition_re_t4_blended_policy_band`
  All match MATLAB to floating-point noise.
- Extended the compiled outer RE solver through the fertility-style outer loop:
  - added `outer_iteration_mode`
  - added fixed-point relaxation settings and price bounds
  - validated pack `transition_re_t4_fertility_style`
- Current read:
  - the no-politics NIMBY solver core is now in compiled C++ across the active workflow branches:
    steady-state reference, transition pass, bounded candidate-search RE, bounded policy-bridge RE,
    dynamic terminal/reference modes, and fertility-style RE
  - MATLAB is now mainly the truth/export harness for regression checking, not the runtime
    dependency for those solver branches

---

### Session: 2026-04-17 (Hamilton horizon insurance packet)
- Added reusable submission script:
  `original_5yr_political_re/submit_original_5yr_hamilton_horizon_insurance.ps1`
- The script now:
  - syncs the current bounded Bellman runner and solver files to Hamilton
  - syncs a known-good `TransitionMatrix.mat` bundle into the remote `external_root`
  - submits a horizon insurance ladder with the fast `union_only` rule
- First Hamilton test packet exposed the old remote transition-matrix problem:
  job `16819324` (`k = 7`) failed with
  `No usable TransitionMatrix.mat found`
- After syncing the good transition bundle to the remote `external_root`, resubmitted the full packet:
  - `k = 7` -> `16819486`
  - `k = 8` -> `16819487`
  - `k = 9` -> `16819488`
  - `k = 10` -> `16819489`
  - `k = 11` -> `16819490`
  - `k = 12` -> `16819491`
  - `k = 13` -> `16819492`
  - `k = 14` -> `16819493`
- Verified immediately after submission:
  all eight jobs were in `RUNNING` state on Hamilton.
- Latest local tracking file:
  `original_5yr_political_re/truth/hamilton_horizon_insurance_latest.json`

---

### Manuscript drafting rule: live paper language
- Treat the manuscript as the live paper, not a response memo.
- Do not write phrases such as "in the revised version", "in the revised transition",
  "we now revise", or "the current candidate will be updated" inside paper prose.
- Revision-process language belongs in STATUS/memory/referee notes only.
- In the manuscript, describe the object directly, e.g. "In the transition exercise"
  or "Under deterministic rational expectations".

---

### Session: 2026-05-07 (RE full-p0060 rescue workflow)
- Original T20 Broyden homotopy job `17042468` completed but missed promotion:
  best full-`p0060` gap was `0.0012135` at period `19`, above the `0.001`
  T20 promotion threshold and far above the `0.0002` paper-safe target.
- The first T20 fallback job `17053242` was cancelled because it used the
  generated path as seed and moved away from the best iterate; visible gaps
  were around `0.00156`-`0.00192`.
- All T80 insurance branches from `17048937` were cancelled because T20 had
  not promoted, so the T80 run was not a valid paper route.
- Added and submitted the 12-hour reduced-basis rescue job `17055353`
  (`bb20bas12`). It uses the best full-`p0060` guess path, controlled
  end-window/report-window seed blends, reduced-basis path updates, extra
  weight on periods `16`-`20`, and longer-tail/terminal-reference diagnostics.
  The monitor now focuses on `17055353`.

---

### Session: 2026-05-09 (parallel RE rescue restart)
- Annual-vote h6/h7 failsafe job `17070620` timed out above promotion:
  best h6 gap `0.00167602`, h7 `0.00189438`, both above the `0.001` T20 gate.
- User clarified that the goal is still to get an RE result, not to stop after
  annual-vote failure.
- Submitted two separated Hamilton rescue tracks:
  - `17071550` (`bb20avsd`): annual-vote fresh-seed homotopy, solving
    pass-through stages `0.0030 -> 0.0045 -> 0.0060` for h5/h6 from three
    source families rather than continuing the failed h6 path.
  - `17071551` (`bb20opol`): original path-shift near-miss polish, restarting
    from the closest original-object seeds around gaps `0.001109`-`0.001149`
    with smaller reduced-basis/Broyden steps.
- Decision rule: promote to T80 only if a T20 branch reports
  `max_abs_path_gap <= 0.001`; treat `<= 0.0002` as paper-safe at T20. If both
  tracks finish above `0.001`, stop blind Hamilton variants and force a
  modeling/terminal-treatment decision.
- Added a third, narrower route after the user suggested voting every five
  years. Implemented `VoteShiftMode = block_vote` with `VoteBlockLength = 5`:
  one vote sets the political restriction for a five-year block, then the next
  block gets a new vote. Submitted Hamilton job `17071923` (`bb20bv5`, array
  `0-3`) as a pass-through homotopy from four source seeds. This differs from
  the earlier h5 finite-horizon annual-vote runs, which still re-voted every
  year.
- Early read from the new homotopy routes crossed the `0.001` threshold at the
  intermediate `p0030` stage:
  - `avsd_h5_brh_p0030` outer `4`: gap `0.000942205`, vote residual `0.0243019`
  - `bv5_rbend_p0030` outer `5`: gap `0.000948474`, vote residual `0.0227575`
  - `bv5_rbguess_p0030` outer `4`: gap `0.000952978`, vote residual `0.0225157`
  These are not full-target promotion results yet because target pass-through
  is `p0060`; keep monitoring for `p0045` and `p0060`.
- Added the more defensible state-cycle version of block voting:
  `VoteShiftMode = block_vote` with `VoteBlockLength = 4`. Submitted Hamilton
  job `17072544` (`bb20bv4`, array `0-3`) using the same four source seeds as
  the five-year block-vote job. Treat this as a parallel model-timing branch:
  compare only at the same homotopy stage, and promote to T80 only if a full
  `p0060` T20 branch reaches `max_abs_path_gap <= 0.001`.
- Later 2026-05-09 model-acceptability reset: although five-year block vote
  (`17071923`, `bb20bv5`) cleared the T20 `p0060` promotion threshold with
  best gap `0.000814014`, the user rejected the five-year interpretation as
  not defensible for the paper. Cancelled five-year T80 promotion job
  `17073814` and remaining five-year task `17071923_3`. The live acceptable
  routes are now annual-vote/fresh-seed (`17071550`) and four-year block-vote
  (`17072544`) only. Added/uploaded `run_t80_accepted_promotion_0509.m` so an
  exact-source T80 promotion can be submitted quickly if either acceptable
  route reaches target `p0060 <= 0.001`.
- 2026-05-10 acceptable-route update: annual-vote/fresh-seed timed out without
  an acceptable `p0060` result. Four-year block vote reached `p0060` but the
  best row, `bv4_brh_p0060` outer `4`, missed promotion narrowly at
  `0.00111560`. Cancelled the remaining worse four-year task and submitted one
  narrow four-year polish, Hamilton job `17074423` (`bb20bv4p`), from exact
  source `bv4_brh_p0060` outer `4`. This is the last bounded compute route
  before a modeling/terminal-treatment decision; five-year remains diagnostic
  only.
- Subsequent acceptable-route read: annual-vote/fresh-seed job `17071550`
  timed out without an acceptable target `p0060` summary. Four-year block-vote
  job `17072544` remains running and has reached target `p0060`, but the best
  visible row is still just above promotion: `bv4_brh_p0060` outer `4`, max
  path gap `0.00111560`, max vote residual `0.00776448`. If it does not cross
  while live, this is a near miss within `0.0012`; consider at most one narrow
  exact-source polish from that four-year branch, not another broad variant.
- Added four-year timing to the no-RE fail-safe comparator so no-RE can be run
  on the same political clock as the acceptable four-year RE branch. The
  patched solver accepts `VoteShiftMode = block_vote` and `VoteBlockLength = 4`,
  holding the vote-implied restriction fixed for each four-year block before a
  new vote is taken. Submitted Hamilton job `17074451` (`nore80bv4`, array
  `0-2`) for pass-throughs `0.006`, `0.012`, and `0.018`, with T20/T80
  outputs under `annual_political_transition_fail_safe/nore80bv4_*`.
- Job `17074451` completed cleanly. Four-year no-RE T80 readout:
  `nore80bv4_006` usable with max vote residual `0.0101070` and max log price
  move `0.00279781`; `nore80bv4_012` usable with max vote residual `0.0114996`
  and max log price move `0.00610918`; `nore80bv4_018` survivor with max vote
  residual `0.0232139` and max log price move `0.0147822`. The no-RE
  comparator is now available on the four-year political clock.
- Four-year RE T20 promotion trigger occurred in job `17074423`: branch
  `bv4p_r25_d18` outer `2` reached max path gap `0.000989508`, max vote
  residual `0.00647572`, and max log price move `0.00221812`. This clears
  the `0.001` T20 promotion gate, but is not paper-safe at `0.0002`. Submitted
  exact-source T80 promotion job `17074725` (`bb80bv4`, array `0-2`) from
  `bv4p_r25_d18` outer `2`, preserving four-year block vote
  (`VoteShiftMode = block_vote`, `VoteBlockLength = 4`) and pass-through
  `-0.006`.
- The same accepted T20 branch improved further to `bv4p_r25_d18` outer `4`
  with max path gap `0.000924056` and max vote residual `0.00627314`.
  Submitted second exact-source T80 promotion job `17074755` (`bb80bv4o4`,
  array `0-2`) from outer `4`, again preserving four-year block vote and
  pass-through `-0.006`.
- It then improved further to `bv4p_r25_d18` outer `5`, with max path gap
  `0.000857297`, max vote residual `0.00582734`, and max log price move
  `0.00219694`. Submitted third exact-source T80 promotion job `17074802`
  (`bb80bv4o5`, array `0-2`) from outer `5`, preserving the same four-year
  block-vote model and pass-through.
- It then improved again to `bv4p_r25_d18` outer `6`, with max path gap
  `0.000796333`, max vote residual `0.00601394`, and max log price move
  `0.00213763`. Submitted fourth exact-source T80 promotion job `17074822`
  (`bb80bv4o6`, array `0-2`) from outer `6`, preserving the same four-year
  block-vote model and pass-through.
- The four-year T20 polish job `17074423` then completed cleanly. Best final
  row was `bv4p_r25_d14` outer `14`, with max path gap `0.000735817`, max vote
  residual `0.00622223`, and max log price move `0.00201609`. This is an
  accepted T20 result but not paper-safe. It was treated as a modest
  refinement rather than a new promotion source while four exact-source T80
  promotions were already live.
- Added a diagnostic-only long-block T80 seed test after the user asked
  whether one vote every `20` or `40` years might help. Submitted Hamilton job
  `17075892` (`bb80bvl`, array `0-3`) from local/remote script
  `drafts_re/hamilton_jobs/bb80blockvote_long_seed_0510.slurm`. It tests
  block lengths `20` and `40` from `bv4p_r25_d14` outer `14` and
  `bv4p_r25_d18` outer `6`. This should only be interpreted as a possible
  seed/continuation diagnostic back to the acceptable four-year model, not as
  a defensible paper model by itself.
- Added a four-year T80 full-seed rescue because the direct T80 promotions are
  stuck far above threshold while seeding most of the long horizon mechanically.
  Submitted Hamilton job `17076871` (`bb80bv4fs`, array `0-5`) from local/remote
  scripts `run_t80_blockvote4_fullseed_rescue_0510.m` and
  `bb80blockvote4_fullseed_rescue_0510.slurm`. It keeps the target model fixed
  as four-year block-vote RE with pass-through `-0.006`, but initializes T80
  using no-RE T80 full paths (`nore80bv4_006`, `nore80bv4_012`) and hybrid
  seeds that splice the accepted RE T20 branch into the no-RE T80 tail. Treat
  any success as a four-year RE result, not as a no-RE result; no-RE is only
  the initial guess.
- 2026-05-10 evening failsafe: non-lag full-seed job `17076871` exhausted its
  array without promotion; best durable row is `bv80bv4fs_n006_d022` outer
  `20`, gap `0.0023876553175479`. The remaining live acceptable T80 route is
  lagged four-year RE job `17078003` (`bb80bv4lg`). Started a 12-hour
  heartbeat failsafe from about `21:40 BST` to `2026-05-11 09:40 BST`: monitor
  only `bv80bv4lag*`, notify/update if gap `<= 0.001`, mark paper-safe if
  `<= 0.0002`, and otherwise stop the monitor after completion or deadline.
- 2026-05-11 lag-failsafe closeout: Hamilton access recovered at about
  `09:08 BST`. Job `17078003` (`bb80bv4lg`) had completed cleanly for all six
  array members but did not clear T80 promotion. Best row was
  `bv80bv4lag_l4_n012` outer `17`, gap `0.00183754003051641`, vote residual
  `0.0183758214463522`, and log price move `0.00492082839501052`; next best
  was `bv80bv4lag_l4_n006` outer `7`, gap `0.00188229537948787`. The four-year
  T80 promotion/lag rescue is closed as failed. Preserve the accepted
  four-year T20 result as promotion-clearing only, not as a T80/paper-safe
  result.
- 2026-05-11 first-wave model-design grid: the user approved a parallel,
  defensible modelling workflow rather than another blind rescue. Uploaded via
  the interactive `ssh -tt` tar-stream workaround after `scp` timed out, then
  submitted Hamilton job `17084463` (`bb80mg11`, array `1-12`). The grid keeps
  T80 full RE and four-year block voting, excludes expectation inertia, and
  varies return-to-steady-state post-report demographics, ghost-tail length,
  pass-through, and the existing lagged delivery/time-to-build proxy. Local
  tracking files live in `drafts_re/hamilton_jobs/`: `model_grid_0511.csv`,
  `workflow_model_grid_0511.md`, `run_t80_model_grid_0511.m`,
  `bb80modelgrid_re_0511.slurm`, and `rank_model_grid_0511.py`. A heartbeat
  monitor `nimby-t80-model-grid-monitor` checks the array every 30 minutes and
  should update STATUS/memory only on a usable row (`<=0.001`), a paper-safe
  row (`<=0.0002`), or final closeout.
- 2026-05-11 perfect-foresight continuation probes: after live first-wave
  summaries favored `0.006` pass-through with 4-year delivery lag and 80-year
  hidden tail but remained survivor-only, submitted Hamilton job `17087303`
  (`bb80pfc11`, array `1-6`). Rows `1-3` are horizon probes (`T20`, `T40`,
  `T60`) at target amplitude `0.25`; rows `4-6` are T80 shock-amplitude probes
  (`0.10`, `0.15`, `0.20`). These keep perfect foresight and the same best
  model family; they are numerical continuation probes, not new expectation
  assumptions.
- 2026-05-11 bridge/polish wave: after T20/T40 continuation cleared the usable
  threshold and T60 sat just above it, uploaded and submitted Hamilton job
  `17097472` (`bb80pfb11`, array `1-6`). The packet tests three T60
  bridge/polish rows, two staged T80 bridges from T60/T40 sources, and one
  conservative polish of current best T80 grid row `re80tail80_pt006_ttb4`
  outer `5`. Treat this as a numerical continuation/refinement of the current
  perfect-foresight family, not as a new modelling assumption.
- 2026-05-11 eleven-hour failsafe packet: after inspecting live residuals,
  uploaded and submitted Hamilton job `17098151` (`bb80pff11`, array `1-14`).
  The packet uses the same perfect-foresight family but attacks different
  numerical/model-closure margins: report-horizon residual focus around periods
  `20`/`21` and `37`, a `120`-year hidden tail, softer terminal-reference
  closure, focused staged T40/T60-to-T80 bridges, and small-shock T80
  diagnostics. This is the last automatic compute wave for the current
  failsafe; checkpoint with the user before any further submission.
- 2026-05-11 primary model-grid closeout: Hamilton job `17084463` (`bb80mg11`)
  produced no usable T80 row. Array members `1`, `2`, and `7` completed; the
  rest timed out at the 12-hour wall limit. Best row remains
  `re80tail80_pt006_ttb4`, gap `0.00150894920957352` at outer `5`; later outer
  `17` was worse at `0.00188268886448642`. Treat this first-wave grid as
  closed unless the user explicitly asks to reopen it.
- 2026-05-12 wide T80 RE transition search: after the alternatives packet
  closed with only bounded-40 forecast-horizon expectations usable and no full
  T80 RE route, submitted Hamilton job `17141699` (`bb80wide12`, array `1-40`,
  13-hour wall time). Files live in `drafts_re/hamilton_jobs/`:
  `model_re_wide_0512.csv`, `workflow_re_wide_0512.md`,
  `run_re_wide_0512.m`, `bb80rewide_0512.slurm`, and
  `rank_re_wide_0512.py`. The wide search keeps the main T80 target at
  pass-through `0.006`, shock `0.25`, four-year block voting, and explores
  hybrid T40/T60-to-T80 seeds, bridge/failsafe survivor continuations,
  terminal/tail/focus/basis sweeps, lag diagnostics, homotopy diagnostics, and
  no-RE/small-shock initial paths. Automation `nimby-wide-t80-re-monitor`
  checks every 30 minutes; do not submit another chain without a user
  checkpoint.
