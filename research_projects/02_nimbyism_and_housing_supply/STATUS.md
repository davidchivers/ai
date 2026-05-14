# STATUS - 02_Nimbyism_and_Housing_Supply

## Snapshot

- Last updated: 2026-05-14
- 2026-05-14 Moll direct-price-beliefs implementation: built the runnable
  Moll-route workbench under
  `drafts_re/moll_direct_price_beliefs/workbench/` and submitted Hamilton job
  `17152180` (`bb80moll14`, array `1-5`, six-hour wall) from
  `/nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual`. The packet
  runs the tractable avenues that match Moll's direct-beliefs prescription:
  Route A temporary-equilibrium baseline (`mollA_temp_bound40_rss`), Route B
  least-squares learning over a direct age-price law (`mollB_lsl_age_t40`),
  two Route C restricted-perceptions heuristics (`mollC_static_t40`,
  `mollC_adapt_anchor_t40`), and Route D price-only AR(1)
  (`mollD_ar1_t40`). Measured/survey beliefs are data-gated; reinforcement
  learning is future work. Early `squeue` check showed all five rows running,
  and early logs showed only the known missing projection-variable warnings
  from `old_paper_source_min.mat`, not a runner error. Close out with
  `python3 closeout_moll_direct_0514.py --annual-dir .` after the job finishes.
  These outputs are direct price-belief diagnostics, not full rational
  expectations rows.
- 2026-05-14 Moll avenues workbench read: `moll_avenues_report.md` compares
  the avenues Moll points toward using available small outputs. The temporary
  bounded T40 baseline has RMSE log price `0.000645268674443`; recursive
  least-squares age-price learning has RMSE `0.000344809404341`; the best
  restricted-perceptions smoke heuristic has RMSE `0.000355376384361`; and the
  price-only AR(1) cross-check has RMSE `0.000230369031896`. The lower AR(1)
  smoke RMSE does not make it the preferred paper route, because it drops the
  demographic channel. Route B remains the main Moll-aligned candidate because
  it uses direct price beliefs, a low-dimensional public age signal, and
  coefficient feedback from realized model prices.
- 2026-05-14 01:00 BST safeguarded full-T80 RE final closeout: Hamilton job
  `17145335` (`bb80safe13`, array `1-5`) hit the 13-hour wall on all five
  tasks. Final closeout with `closeout_re_safeguard_0513.py --final` found no
  usable headline full-T80 RE row. Best visible row is `sg80_flat_trust12`,
  route `full_t80_safeguarded_polish`, gap `0.00190273652098779` at outer `4`,
  verdict `survivor`. The other four safeguarded rows remain survivors at
  gap `0.00284389447561411` at outer `1`. Missing/timed-out rows: none. The
  headline full-T80 RE figure should not be reported. Prepared next full-RE
  solver remains the unsubmitted LM/Gauss-Newton fallback
  (`run_re_lm_0513.m`, `bb80relm_0513.slurm`), to be launched only if the user
  explicitly chooses to continue the full-RE route after this final miss.
- 2026-05-13 dual-route workflow: created
  `drafts_re/dual_route_14h_workflow.md`, a bounded 14-hour plan covering the
  live full T80 RE route and the Moll-aligned direct-price-belief route. It
  keeps `17145335` as the live full-RE job, permits exactly one prepared
  LM/Gauss-Newton fallback only after final miss and only if time remains, and
  treats the Moll route as a restricted direct-price-belief implementation
  rather than the existing bounded T40 prototype. It does not start new compute
  by itself.
- 2026-05-13 Moll route-menu clarification: added
  `drafts_re/moll_direct_price_beliefs/route_options.md`. Moll does not give a
  single recipe. For this project, the route ranking is: least-squares learning
  over a direct price law first; restricted perceptions/simple heuristics second;
  temporary equilibrium with measured/calibrated beliefs as a useful baseline;
  price-only aggregate-law methods as infrastructure; reinforcement learning as
  future work. The 14-hour workflow now defaults to the least-squares learning
  route while keeping the alternatives explicit.
- 2026-05-13 Moll route correction: after re-reading Moll's criteria, demoted
  the bounded T40 artifact to a diagnostic/prototype rather than the actual
  "Moll route." Created
  `drafts_re/moll_direct_price_beliefs/criteria_audit.md` and
  `candidate_routes.csv`. The target route is now a restricted direct
  price-belief equilibrium: households forecast prices directly using a
  low-dimensional perceived law of motion, model prices are solved as temporary
  equilibria under those beliefs, and the belief-rule coefficients update from
  realized model prices. Existing `extensions/re_no_politics/run_linear_age_price_rule.m`
  is the closest current code pattern, but it still needs adaptation to the
  annual political baby-boom environment and empirical discipline from the
  house-price-expectations literature.
- 2026-05-13 bounded/direct price-expectations artifact: built the first
  bounded-route comparison under `drafts_re/bounded_price_expectations/`. The
  object is `bound40_baby_rss_l4`, a 40-year bounded price-belief route with a
  40-year return-to-steady-state internal tail, not full T80 RE. Validation
  recomputes the report-horizon gap as `0.000990326504390731`, matching the
  ranked gap `0.000990326504390953`; verdict remains usable but not paper-safe.
  The comparison uses `nore80bv4_006` over the same 40 reported years. Figure:
  `figure/bounded_price_expectations_vs_nore_0513.svg`; validation:
  `figure/bounded_price_expectations_validation_0513.csv`.
- 2026-05-13 strategy update after reading Moll's rational-expectations
  challenge: keep the full T80 RE search alive through the existing slow
  monitor and the current safeguarded Hamilton job `17145335`, but also develop
  the bounded/direct price-expectations result as a separate serious model
  object. This is not a relabeling rule: full T80 RE still requires the hard
  generated-vs-guessed path-gap gates, while `bound40_baby_rss_l4` should be
  explored as a finite-forecast-horizon price-belief equilibrium motivated by
  direct price expectations. Working memo:
  `drafts_re/bounded_price_expectations_route.md`.
- 2026-05-13 11:13 BST safeguarded full-T80 RE polish: submitted Hamilton job
  `17145335` (`bb80safe13`, array `1-5`, 13-hour wall). This is the
  methodologically distinct next attempt after the wide packet: it starts from
  the best survivor `w80_b60hold_bl70` outer `4` and uses a copied solver with
  best-anchor safeguarding plus trust-region log-price fixed-point updates.
  Rank with `rank_re_wide_0512.py --grid model_re_safeguard_0513.csv --out-dir
  truth/re_safeguard_0513`. C: is at/below the 20 GB guard; keep local writes
  tiny.
- 2026-05-13 fallback design note: prepared but did not submit a sequential
  black-box LM/Gauss-Newton residual-minimization fallback (`run_re_lm_0513.m`,
  `bb80relm_0513.slurm`). This should only be used if job `17145335` misses,
  and is meant as a genuinely different fixed-point solve rather than another
  blind grid.
- 2026-05-13 11:02 BST wide T80 RE closeout: Hamilton job `17141699`
  (`bb80wide12`, array `1-40`) finished or hit the 13-hour wall with no usable
  full T80 target row. Best full target remains `w80_b60hold_bl70`, route
  `full_t80_bridge_candidate`, gap `0.00101892245727956` at outer `4`,
  verdict `survivor`; this is narrowly above the `0.001` usable threshold and
  not paper-safe. Next rows are `w80_flat_rss_b6` gap `0.00108682802289991`
  and lower-pass-through diagnostic `w80_pt004_b40` gap
  `0.00111768158539817`. Residual readout: the best full target's largest
  generated-vs-guessed mismatch is in the hidden tail around periods `85-96`,
  while the report-horizon gap is just above usable. Interpretation: the wide
  blind/bridge/basis packet did not deliver a paper-ready full T80 RE figure;
  the next attempt should be a methodologically distinct safeguarded log-price
  fixed-point/homotopy solve from the best survivor, not another broad grid.
- 2026-05-12 14:59 BST RE alternatives final closeout: jobs `17115233` and
  `17115493` have finished. The only usable row is bounded 40-year forecast
  expectations with return-to-steady-state tail, `bound40_baby_rss_l4`, gap
  `0.000990326504390953` at outer `7`. This is usable but not paper-safe and
  not a full T80 perfect-foresight equilibrium. Nearby rows did not clear:
  `bound40_baby_hold_l4` gap `0.00100980359249257`, `bound60_baby_hold_l4`
  gap `0.00129819162075221`, local-linear baby-boom diagnostics gap
  `0.00174411505390316`, projected T80 basis rows gap `0.00216636160274657`
  or worse, and the best secular/official projection RE rows remain above
  usable (`resec80_rss_pt006_l4` gap `0.00324246094740715`,
  `resec80_hold_pt006_l4` gap `0.0032589206926111`,
  `reprojmed80_pt006_l4` gap `0.00360511078990618`). Interpretation: the final
  paper-facing result from this packet is the bounded-forecast-horizon T40
  robustness row only; full T80 RE, secular RE, official-projection RE, and
  projected T80 RE did not clear the usable threshold.
- 2026-05-12 11:59 BST stationary old-model RE closeout: job `17119202`
  completed pass-through `0.006` rows cleanly but pass-through `0.012` rows
  timed out at the two-hour wall without numeric terminal-anchor output. This
  leaves the stationary old-paper RE evidence as the clean `0.006` benchmark
  only; it does not change the interpretation that stationary demographic price
  effects are tiny in the old-model RE benchmark.
- 2026-05-12 11:24 BST stationary old-model RE partial result: pass-through
  `0.006` rows have clean stationary outputs with terminal gaps at numerical
  precision. Relative to the stationary baseline case, the permanently
  younger/high-entry profile changes the RE house price by `-0.001534%`, the
  low-entry/secular-ageing profile changes it by `-0.008640%`, the official
  2050 age distribution changes it by `-0.006164%`, and the official 2100 age
  distribution changes it by `-0.007117%`. Interpretation: under this stationary
  old-paper RE benchmark, these demographic steady-state shifts have extremely
  small price effects at pass-through `0.006`, even though homeownership changes
  materially across age profiles. The `0.012` stationary rows are still running.
- 2026-05-12 11:24 BST RE alternatives update: `bound40_baby_rss_l4` remains
  the only usable row, gap `0.000990326504390953`. `bound60_baby_hold_l4` has
  improved to gap `0.00141805693976858` but remains survivor-only. Secular and
  official-projection RE rows have improved but remain dead above usable:
  best visible secular `resec80_hold_pt006_l4` gap `0.0041903747261602`, and
  official projection `reprojmed80_pt006_l4` gap `0.00456072256236721`.
- 2026-05-12 10:54 BST RE alternatives threshold crossing: bounded-expectations
  baby-boom row `bound40_baby_rss_l4` became usable, with gap
  `0.000990326504390953` at outer `7`. This is not paper-safe and is not a
  full T80 perfect-foresight equilibrium; it is a bounded 40-year forecast row
  with return-to-steady-state tail. Interpretation: there is now a usable
  forecast-horizon expectations result for the baby-boom experiment, distinct
  from the failed full T80 RE routes. Other live alternatives remain above
  usable: `bound40_baby_hold_l4` gap `0.00100980359249257`, `bound60_baby_hold_l4`
  gap `0.00187133923488724`, projected T80 basis rows still around
  `0.002166` or worse, and secular/official-projection RE rows still around
  `0.0047` to `0.0105`. Stationary old-model RE job `17119202` is still
  running and has not yet written numeric terminal-anchor output.
- 2026-05-12 09:16 BST stationary old-model RE benchmark: submitted Hamilton
  job `17119202` (`bbssre12`, array `1-10`) to solve stationary RE benchmarks
  using the old-paper source files. Remote checks confirmed the intended files:
  `../SteadyState/Mod_IRF/old_paper_source_min.mat` has md5
  `79523aaf721ec337119daa0c64813458`, matching the compact old-paper source;
  the job copies `run_annual_political_full_re_price_path_basis_0507.m` to the
  live annual RE solver; and it uses `SteadyState/Mod_Functions` plus
  `COMPECON`. Rows cover baseline, a permanently younger/high-entry stationary
  profile, a low-entry/secular-ageing stationary profile, and official 2050/2100
  age distributions, each at pass-throughs `0.006` and `0.012`. The job was
  running cleanly at the readout; no stationary results had been written yet.
  Rank with `rank_stationary_re_0512.py` under `truth/stationary_re_0512`.
- 2026-05-12 09:16 BST RE alternatives live readout: no usable
  full-equilibrium row yet. Best visible row is bounded-expectations
  `bound40_baby_rss_l4`, gap `0.00222049690605593` at outer `3`, verdict
  survivor. Projected T80 rows are visible but still survivors
  (`projbb80_basis4_l4`/`projbb80_basis6_l4`, gap `0.00253623304746369` at
  outer `1`). Secular and official-projection RE rows are currently dead above
  `0.005` to `0.011`. Partial-equilibrium and local-linear rows remain
  diagnostic only, not headline nonlinear equilibria.
- 2026-05-12 07:00 BST eight-hour RE alternatives packet: submitted Hamilton
  job `17115233` (`bb80alt12`, array `1-18`) under
  `/nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual`. This packet
  tests the paper-facing alternatives requested at the checkpoint: secular
  demographic RE and no-RE comparators, low-dimensional projected T80
  perfect-foresight paths, local-linear small-shock proxies, partial-equilibrium
  PF mechanism rows holding no-RE prices fixed, and bounded 40/60-year forecast
  horizons. Rows `6` and `7`, the official `projection_median` rows, first
  failed because `old_paper_source_min.mat` lacks `forecast_median`; they were
  repaired by building `official_age_path_0512.mat` from the local age workbook
  for model ages 25-80 and years 2001-2100, then relaunched as job `17115493`
  (`bb80alt12`, array `6-7`) with `DemographicScenario = external_age_path`.
  Monitor with `rank_re_alt_0512.py`; do not submit another chained wave before
  the eight-hour checkpoint unless the user explicitly asks.
- 2026-05-12 08:06 BST old eleven-hour failsafe closeout: Hamilton job
  `17098151` (`bb80pff11`) finished or timed out with no usable T60/T80 row.
  Best final visible row is `pff80_from40_f37`, gap `0.00160894640707105` at
  outer `13`, verdict survivor. The best T60 row remains
  `pff60_f21_from40`, gap `0.00171620263714836`. Rows `7` and `12` timed out;
  the other array rows completed. Interpretation: the bridge/failsafe route did
  not clear the `0.001` usable threshold. The active paper route is now the
  separate RE alternatives packet `17115233`/`17115493`.
- 2026-05-11 19:05 BST decision update: perfect-foresight continuation job
  `17087303` produced usable intermediate-horizon rows, but not paper-safe
  rows. `pfh40_tail80_pt006_ttb4` cleared the usable threshold with gap
  `0.000960075941637735` at outer `8`, and `pfh20_tail80_pt006_ttb4`
  cleared with gap `0.000985200745180424` at outer `9`. `pfh60_tail80_pt006_ttb4`
  remains a near survivor at `0.00108147857180333`, and the T80 amplitude
  continuation rows remain survivors around `0.00150894920957352`. The primary
  T80 model grid `17084463` has no usable row yet; its best remains
  `re80tail80_pt006_ttb4` gap `0.00150894920957352`, while the latest visible
  outer has drifted to `0.00185360668754506`. Interpretation: the paper now has
  a usable staged perfect-foresight bridge at T20/T40, but not a usable T80 RE
  robustness figure.
- 2026-05-11 20:05 BST parallel bridge wave: submitted narrow Hamilton job
  `17097472` (`bb80pfb11`, array `1-6`) to extend the usable T20/T40
  perfect-foresight continuation rather than add a new behavioural assumption.
  Rows `1-3` polish/bridge T60 from the current T60 and usable T40 sources;
  rows `4-5` try staged T80 bridges from T60/T40; row `6` conservatively
  polishes current best T80 grid source `re80tail80_pt006_ttb4` outer `5`.
  At submit check it was pending while `17084463` and `17087303` continued
  running.
- 2026-05-11 21:25 BST eleven-hour failsafe: submitted Hamilton job
  `17098151` (`bb80pff11`, array `1-14`) as the final bounded parallel packet
  before a checkpoint. The packet targets the live residual windows directly
  after diagnosing max report-horizon gaps around periods `21`, `20`, and `37`;
  it also tests longer hidden tails, softer terminal-reference closure, focused
  T40/T60-to-T80 bridges, and small-shock T80 diagnostics. It is pending at
  submit check. Failsafe deadline: about `2026-05-12 08:25 BST`; do not submit
  another chained wave before user checkpoint.
- 2026-05-11 21:40 BST primary-grid closeout: first-wave T80 model grid job
  `17084463` is now effectively final, with array members `1`, `2`, and `7`
  completed and the remaining members timed out at the 12-hour wall limit. It
  produced no usable T80 row. Best row remains `re80tail80_pt006_ttb4`, gap
  `0.00150894920957352` at outer `5`; later visible outer `17` was worse at
  `0.00188268886448642`. Interpretation: the broad defensible model-grid route
  did not clear T80; live hope is now the continuation/bridge/failsafe packets.
- 2026-05-11 23:35 BST continuation closeout: perfect-foresight continuation
  job `17087303` (`bb80pfc11`) is closed. T20 and T40 remain usable but not
  paper-safe (`pfh20_tail80_pt006_ttb4` best `0.000930287456276735`;
  `pfh40_tail80_pt006_ttb4` best `0.000960075941637735`). T60 did not clear
  usable: best `pfh60_tail80_pt006_ttb4` is `0.00104819991480841`, with the
  final visible outer worse at `0.00107304033719742`; T80 amplitude rows remain
  above usable around the first-wave T80 best. Rows `3` and `6` timed out at
  the wall. Live T60/T80 hope is now bridge/polish job `17097472` and failsafe
  packet job `17098151` only.
- Current workflow to paper:
  1. Do not treat `oldbase_re_0505/obre80_0505_e006` as a final RE paper
     result. It is useful as a diagnostic run, but the generated price path and
     guessed/expected price path are not close enough for a paper figure.
  2. The figure builder now has a hard guard: if an RE output contains both
     `price_guess` and `price_generated`, paper-figure generation fails unless
     `max |log(price_generated / price_guess)| <= 0.0002`. Diagnostic figures
     require the explicit `--allow-unconverged-re` override.
  3. Current baby-boom RE diagnostic numbers for `obre80_0505_e006`:
     max path gap `0.00586282`, guessed-path trough `-0.006192`, generated-path
     trough `-0.004117`, and max vote residual `0.016815`. This is not tight
     enough because the path gap is about as large as the economic price
     movement.
  4. The completed no-RE pass-through range is usable as a diagnostic:
     pass-throughs `{0.006, 0.012, 0.018, 0.024}` give max log price moves of
     about `{0.00205, 0.00328, 0.00393, 0.00444}`. It shows the old-paper
     comparison difference is mostly pass-through strength, not just RE versus
     no-RE.
  5. The no-RE transition code has been patched so stored price, stored
     political restriction, and stored vote residual refer to the same
     within-period object. Rerun final no-RE paper outputs after this patch
     before treating them as final.
  6. Next computation priority: replace plain damping in the RE price-path
     loop with an explicit fixed-point workflow in log prices, using
     pass-through homotopy and safeguarded Anderson/Broyden acceleration.
  7. Main paper figures should eventually compare RE and no-RE under the same
     pass-through values, plus one old-paper-matched reference if needed. Do
     not use separate hidden tuning for RE versus no-RE.
  8. Still missing for final paper figures: paper-safe baby-boom RE, rerun
     final no-RE after the consistency patch, old-baseline secular decline RE,
     and locked no-RE secular decline. Existing secular figures are
     wrong-source placeholders and must not be used.
  9. LaTeX-only paper integration: define the smooth political vote rule and
     persistent path-shift object, state deterministic perfect foresight over
     demographics/house prices, label the no-RE comparator carefully, and keep
     all new paper text in blue until approved. Do not edit LyX until asked.
- 2026-05-06 diagnostic correction: the preview baby-boom figure with the RE
  line close to the old-paper current-price path is not enough to declare the
  RE fixed point solved. The figure builder plotted the RE `price_guess`, which
  was initialized from the old-paper path and updated only lightly. In the
  same output, the model-generated RE path is materially flatter: old-paper
  trough about `-0.00626` log points, plotted RE guess trough about `-0.00619`,
  generated RE trough about `-0.00412`, and locked no-RE trough about
  `-0.00205`. The final-iteration RE path gap is about `0.00586`, comparable
  to the whole price movement, so the current RE preview is a diagnostic, not a
  final paper figure. Next paper-safe computation should tighten the RE
  fixed-point loop and then rebuild figures only after `price_guess` and
  `price_generated` are close.
- 2026-05-06 Hamilton submissions: uploaded the patched RE solver and patched
  no-RE transition solver to
  `/nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual/`.
  Submitted `bb20aa_0506.slurm` as job `17026242` (T20 baby-boom RE Anderson
  smoke, array of four safeguarded Anderson settings) and `nore80p_0506.slurm`
  as job `17026243` (T20/T80 no-RE pass-through rerun after the within-period
  consistency fix, pass-throughs `0.006`, `0.012`, `0.018`, `0.024`). The
  first no-RE submission failed immediately because the wrapper passed an
  unsupported `ReferenceYear` argument; this was a submission-script error, not
  a model failure. The wrapper was patched and resubmitted as job `17026795`,
  currently pending at last check. The RE Anderson job `17026242` is still
  running; all four variants had written the first outer-iteration summary.
- 2026-05-06 later Hamilton check: `bb20aa` is still running. The best visible
  RE Anderson variant so far is `aa20m6d50`, with T20 path gap down to about
  `0.00398` by outer iteration 6. This is an improvement over the starting
  `0.00577`, but still not paper-safe. The resubmitted no-RE job `17026795`
  is running for pass-throughs `0.006`, `0.012`, and `0.018`; the `0.024`
  array member completed early at T20 with max vote residual about `0.03944`
  and was classified dead.
- 2026-05-06 target workflow installed: target is
  `max |log(price_generated / price_guess)| <= 0.0002` on the reported
  horizon. Local monitor script:
  `figures/re_transition/figure_robustness_checks/run_re_target_workflow_0506.ps1`.
  Hidden launcher:
  `figures/re_transition/figure_robustness_checks/start_re_target_workflow_0506.ps1`.
  State and logs:
  `D:\AI_storage\spillover\nimby_re_fig_inputs\diagnostics\re_target_workflow_0506\`.
  The monitor polls Hamilton every 15 minutes for up to 6 hours. If the current
  T20 RE smoke hits the target or gets below `0.001`, it submits the T80
  Anderson promotion job `bb80aa_0506.slurm`. If the current smoke completes
  with a best gap between `0.001` and `0.0045`, it submits the extended T20
  Anderson job `bb20aa2_0506.slurm`. If the smoke completes outside that band,
  it stops and marks the next step as solver refactor/homotopy rather than
  wasting T80 compute. The hidden monitor was started with PID `51532`.
- 2026-05-06 workflow branch taken: first T20 Anderson smoke `bb20aa`
  completed. Best final T20 gap was `0.0033696` from `aa20m6d50`, so the
  workflow correctly did not promote to T80 and instead submitted extended T20
  Anderson job `bb20aa2` as Hamilton job `17028671`. At submit check, array
  members `0`, `1`, and `2` were running and members `3` to `5` were pending.
- 2026-05-06 extended T20 update: `bb20aa2` remains running on all six array
  members. Best live summary seen is `aa2m6d80` at outer iteration 13 with
  max path gap `0.0030513`, max vote residual `0.0201543`, and max log price
  move `0.0022724`. This is better but still far above the `0.0002` paper-safe
  target and above the `0.001` T80-promotion threshold. No-RE pass-through
  rerun `17026795` completed: `0.006` and `0.012` are usable at T80, `0.018`
  is a T80 survivor with max vote residual `0.0236573`, and `0.024` is dead at
  T20.
- 2026-05-06 later extended T20 update: `bb20aa2` is still running on all six
  array members. Best live summary improved to max path gap about `0.0023696`
  from the high-Anderson-damping variants (`aa2m6d80`/`aa2m8d80`) by outer
  iteration 16. This is continued progress, but it remains above the `0.001`
  T80-promotion threshold and far above the `0.0002` final paper-safe target.
  Monitor action remains `wait`; homotopy fallback has not yet been submitted.
- 2026-05-06 12-hour fail-safe workflow: replaced the old 6-hour monitor with
  a 12-hour monitor, current hidden PID `44624`. Added and uploaded Hamilton
  homotopy fallback files `run_bb20_homotopy_0506.m` and `bb20hom_0506.slurm`.
  Updated fail-safe ladder:
  (i) wait for current `bb20aa2`;
  (ii) if T20 gap falls below `0.001`, submit T80 Anderson `bb80aa`;
  (iii) if extended Anderson finishes above `0.001` but within the extension
  band, submit pass-through homotopy `bb20hom`;
  (iv) if homotopy fails to produce a promotable T20 result, stop and record
  solver refactor/Broyden as the next step rather than resubmitting loops.
  State/log path remains
  `D:\AI_storage\spillover\nimby_re_fig_inputs\diagnostics\re_target_workflow_0506\`.
- 2026-05-07 overnight workflow result: all Hamilton jobs are complete and the
  hidden monitor was stopped manually after reaching the fail-safe stop state.
  Extended Anderson `bb20aa2` completed but did not reach the T80-promotion
  threshold; best late gaps were roughly `0.0025`-`0.0030`. Homotopy fallback
  `bb20hom` also completed; the best final target-pass-through stage was
  `h20m8d50_p0060` with max path gap `0.0017100`, max vote residual
  `0.0222038`, and max log price move `0.0041525`. This improved materially
  but still missed the `0.001` T80-promotion threshold and the `0.0002`
  paper-safe target. Next step is solver refactor/Broyden or a reduced-basis
  root solve; do not keep resubmitting the same Anderson/homotopy jobs.
- 2026-05-07 diagnostic figures: generated diagnostic-only RE versus no-RE
  plots in
  `D:\AI_storage\spillover\nimby_re_fig_inputs\diagnostics\diagnostic_re_vs_nore_0507\`.
  The best T20 homotopy RE diagnostic is plotted against no-RE pass-throughs
  `0.006`, `0.012`, and `0.018`; a separate older T80 RE diagnostic is also
  plotted for horizon shape only. These are explicitly not paper-safe because
  the RE fixed-point gap remains above tolerance.
- 2026-05-07 Broyden attempt: added safeguarded Broyden update mode to
  `run_annual_political_full_re_price_path.m`, added Broyden options to
  `run_bb20_homotopy_0506.m`, and submitted Hamilton job `17042468`
  (`bb20hbr`) for T20 pass-through homotopy with Broyden updates. At submit
  check, array members `0`, `1`, and `2` were running and member `3` was
  pending. This is the current attempt to get below the `0.001` T20 promotion
  threshold.
- 2026-05-07 Broyden live follow-up: Hamilton job `17042468` remains running
  cleanly. The `0.0015` homotopy stage completed for all four variants, with
  best max path gap `2.3818e-05` from `brh20d80c005_p0015`. The `0.0030`
  stage has started and, by the latest check, all visible rows are already
  below the `0.001` T80-promotion threshold; the best visible `0.0030` row is
  `brh20d80c005_p0030` at outer iteration `4`, with max path gap about
  `0.0002442`. The decisive `0.0060` stage has not written a summary yet.
  Added local ranker
  `D:\AI_storage\spillover\nimby_re_fig_inputs\ham_code\rank_broyden_summaries_0507.ps1`
  and staged Broyden-specific T80 promotion script
  `D:\AI_storage\spillover\nimby_re_fig_inputs\ham_code\bb80hbr_0507.slurm`,
  also uploaded to Hamilton as
  `/nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual/bb80hbr_0507.slurm`.
  After the T20 `p0045` stage opened below the `0.001` promotion threshold
  (best visible `p0045` gap about `0.0005506`), submitted a narrow T80
  insurance array for leading settings `0-2` as Hamilton job `17048937`
  (`bb80hbr`). This is intentionally an insurance job to save queue time:
  cancel it if final T20 `p0060` later fails badly, and treat it as the live
  T80 promotion only if final `p0060` confirms the Broyden route. A local
  MATLAB T4 Broyden smoke at `p0060` was attempted on `D:` but was stopped
  after showing slow progress only (gap from `0.00577` to about `0.00363` by
  outer iteration `5`), so local full-solve attempts should not be treated as
  the acceleration path.
- 2026-05-07 full-`p0060` fallback: the Broyden homotopy job `17042468`
  reached the final `p0060` stage but stalled above the T20 promotion
  threshold. Best visible full-`p0060` T20 gap was `0.0012135` from
  `brh20d80c005_p0060` at outer iteration `7`; later rows stayed around
  `0.0013`-`0.0016`, above the `0.001` promotion threshold and far above the
  `0.0002` paper-safe target. Submitted narrow fallback job `17053242`
  (`bb20p60fb`) using the best full-`p0060` generated path as the seed and
  testing smaller Broyden steps, plain relaxation, and low-damped Anderson at
  `p0060` only. Local submission script:
  `drafts_re/hamilton_jobs/bb20p60fb_0507.slurm`; remote script:
  `/nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual/bb20p60fb_0507.slurm`.
  Keep T80 insurance job `17048937` running for now, but do not treat it as a
  valid promotion unless a T20 full-`p0060` branch crosses below `0.001`.
- 2026-05-07 T80 insurance trimmed: cancelled weaker T80 array tasks
  `17048937_0` and `17048937_1` after the original T20 Broyden full-`p0060`
  failed to clear promotion. Kept only best-running diagnostic branch
  `17048937_2` (`br80d80c005_p0060`), which had reached gap `0.0028079` at
  outer iteration `9`, while T20 fallback job `17053242` starts.
- 2026-05-07 T80 insurance stopped: cancelled remaining branch `17048937_2`
  after original T20 Broyden completed above promotion and the fallback had not
  improved enough to justify treating T80 as live promotion. Best visible T80
  diagnostic before cancellation was `br80d80c005_p0060` with gap about
  `0.0025234`, still far above `0.001` and not valid without T20 promotion.
  Active Hamilton RE compute is now T20 fallback job `17053242` only.
- 2026-05-07 12-hour reduced-basis rescue: cancelled fallback job `17053242`
  after it worsened relative to the best original Broyden iterate. Best original
  full-`p0060` residual was at period `19` with gap `0.0012135`; the fallback
  started from the generated path and produced broader gaps around
  `0.00156`-`0.00192`, so it was not the right direction. Added reduced-basis
  update mode to the Hamilton RE solver and submitted 12-hour job `17055353`
  (`bb20bas12`, array `0-7`). The packet starts from the best full-`p0060`
  guess path, tests controlled end-window/report-window seed blends, gives
  extra residual weight to periods `16`-`20`, and includes longer-tail and
  terminal-reference diagnostics to identify whether the report-end anchor is
  the binding issue. Local scripts:
  `drafts_re/hamilton_jobs/run_annual_political_full_re_price_path_basis_0507.m`,
  `drafts_re/hamilton_jobs/run_bb20_basis12_0507.m`, and
  `drafts_re/hamilton_jobs/bb20basis12_0507.slurm`; remote files are in
  `/nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual/`.
- 2026-05-08 reduced-basis rescue result: Hamilton job `17055353`
  (`bb20bas12`) completed cleanly for all eight array branches, but no branch
  crossed the `0.001` T20 promotion threshold. The best branch was
  `rb20end50_k8` at outer iteration `4`, with max path gap `0.00111135`, max
  vote residual `0.0163897`, mean vote residual `0.0057114`, max log price
  move `0.0029781`, and mean homeownership `0.413590`. This is closer than
  the original Broyden full-`p0060` best of `0.0012135`, but still not enough
  to promote to T80 and far above the `0.0002` paper-safe target. The right
  next computational step is a true reduced-basis/root-solve workflow or an
  explicit terminal-anchor/model decision, not another small damping variant.
- 2026-05-08 root-solve rescue submission: added a reduced-basis
  quasi-Newton update method (`PathUpdateMethod = basis_broyden`) and submitted
  narrow Hamilton array `17064938` (`bb20rbrt`, tasks `0-7`). This restarts
  from the best completed reduced-basis branches, especially `rb20end50_k8`
  outer `4`, and solves in the low-dimensional path-coefficient space rather
  than relaxing the whole path again. At submit check the array was pending
  for priority. Promotion rule is unchanged: only a T20 full-`p0060` branch
  with max path gap `<= 0.001` justifies a fresh T80 promotion; `<= 0.0002`
  is the paper-safe target.
- 2026-05-08 parallel anchor diagnostics: added an explicit soft-reference
  terminal anchor option (`TerminalAnchor = soft_reference`,
  `TerminalBlendWeight` between reference and terminal fixed-point price) and
  submitted Hamilton job `17064996` (`bb20anch`, tasks `0-7`). This runs
  anchor variants in parallel with root job `17064938`: longer hidden tails
  (`TailYears = 60` and `80`) under `terminal_fixed_point`, reference anchors
  at short/long tail, and soft-reference anchors with blend weights `0.50` and
  `0.75`. At submit check, tasks `0` and `1` were running and tasks `2-7`
  were pending for priority. Use the same rule: if any T20 reported branch
  reaches max path gap `<= 0.001`, promote that exact branch to T80; if both
  root and anchor diagnostics miss, stop solver variants and make the
  terminal-anchor/model decision explicitly.
- 2026-05-08 early-stop pruning: cancelled root task `17064938_7`
  (`rbr20ref_k10`) after it worsened from `0.00111309` at outer `1` to
  `0.00137934` by outer `5`, and cancelled anchor task `17064996_4`
  (`anc20ref20_g`) after it worsened from `0.00111061` at outer `1` to
  `0.00125713` at outer `2`. These were reference-anchor losers; terminal
  fixed-point, longer-tail, soft-reference, and main root branches remain
  running.
- 2026-05-08 critical-year rescue submission: live diagnostics showed the
  best branch `rbr20end100_k8` at outer `1` had max path gap `0.00110938`,
  now binding at period `7`/year `2007` rather than the end of the reported
  window. Added critical-year seed modes (`critical7`, `critical7end50`,
  `critical7end100`) and optional reduced-basis focus weights over periods
  `6`-`8`, then submitted Hamilton job `17066581` (`bb20crit7`, tasks `0-5`).
  This is a narrow p6-p8 focused rescue seeded from `rb20end50_k8` outer `4`;
  at submit check the array was pending for priority. It is the only additional
  compute worth adding now because it targets the newly diagnosed binding year.
- 2026-05-08 second early-stop pruning: cancelled root tasks `17064938_0`
  (`rbr20best_k8`), `17064938_1` (`rbr20rep50_k8`), `17064938_4`
  (`rbr20midend_k10`), and `17064938_5` (`rbr20guess2_k8`) after early rows
  either worsened or started materially above the near-miss band. Kept the
  best live root branches `17064938_2` (`rbr20end50_k8`), `17064938_3`
  (`rbr20end100_k8`), and `17064938_6` (`rbr40guess2_k8`), plus all still-live
  anchor diagnostics and the critical-year rescue job `17066581`.
- 2026-05-08 best-source branch expansion: submitted Hamilton job `17067205`
  (`bb20bsrc`, tasks `0-5`) to restart directly from the current best live
  branch `rbr20end100_k8` outer `1` (`0.00110938`). The new branches combine
  p6-p8 focus weights with smaller quasi-Newton steps, higher basis dimensions
  (`14` and `18`), and terminal fixed-point/soft-reference long-tail variants.
  This is meant to attack the newly binding 2007 residual from the best known
  seed, not to broaden the search indiscriminately. At submit check the array
  was pending for priority.
- 2026-05-08 root job fully pruned: cancelled the remaining live root tasks
  `17064938_2`, `17064938_3`, and `17064938_6` after their second rows
  worsened from their best first rows (`rbr20end50_k8` to `0.00127960`,
  `rbr20end100_k8` to `0.00125999`, and `rbr40guess2_k8` to `0.00126586`).
  The original root-solve job `17064938` is no longer active; the live compute
  is now the anchor diagnostics `17064996`, the critical-year rescue
  `17066581`, and the best-source expansion `17067205`.
- 2026-05-08 anchor pruning: cancelled anchor task `17064996_5`
  (`anc20ref60_g`) after it worsened from `0.00111061` at outer `1` to
  `0.00125663` at outer `2`. Current best remains `rbr20end100_k8` outer `1`
  at `0.00110938`, above the `0.001` promotion threshold. Remaining live
  compute is longer-tail/soft anchor diagnostics, critical-year p6-p8 rescue,
  and best-source branches; no MATLAB syntax failures are visible.
- 2026-05-08 third early-stop pruning: cancelled anchor tasks `17064996_0`
  (`anc20tfp60_g`) and `17064996_1` (`anc20tfp80_g`) after they worsened to
  `0.00134797` and `0.00136720` at outer `2`; cancelled anchor task
  `17064996_2` (`anc20tfp60_r50`) after its first row was already
  `0.00128101`; and cancelled critical-year tasks `17066581_0`
  (`crit7e20_k12`) and `17066581_2` (`crit7only_k12`) after first rows around
  `0.0012445`. Kept `17064996_3`, `17064996_6`, `17064996_7`, remaining
  critical-year branches, and all best-source branches. No branch has crossed
  `0.001`; best remains `0.00110938`.
- 2026-05-08 soft-anchor pruning: cancelled anchor tasks `17064996_6`
  (`anc20soft50_60g`) and `17064996_7` (`anc20soft75_60g`) after both worsened
  from `0.00111061` at outer `1` to `0.00126243` at outer `2`. The anchor job
  now has only `17064996_3` (`anc20tfp60_e50`) still live. Remaining live
  compute is `17064996_3`, critical-year tasks `17066581_1`, `_3`, `_4`, `_5`,
  and all best-source tasks `17067205_0`-`_5`.
- 2026-05-08 computational rescue stop: cancelled all remaining live anchor,
  critical-year, and best-source tasks after their visible rows failed to
  improve on the best near-miss. The best branch remains `rbr20end100_k8`
  outer `1`, with max path gap `0.00110938`, above the `0.001` T20 promotion
  threshold and far above the `0.0002` paper-safe target. The best critical
  and best-source attempts were worse: `crit7e20_k14` reached `0.00120747`,
  `bsrc_c7only20_k14` reached `0.00119758`, and high-dimensional/best-source
  variants moved to roughly `0.0014`-`0.0016`. At this point the reduced-basis,
  anchor, critical-year, and best-source rescue packet has failed promotion.
  Do not submit more small variants without a modelling/terminal-anchor
  decision or a materially different solver formulation.
- 2026-05-08 annual-vote timing smoke: after user clarification that each
  period has a new vote and future votes respond to future demographics,
  submitted Hamilton job `17067913` (`bb20avsm`, tasks `0-11`). This is a
  materially different political timing object, not a ghost-tail variant: it
  uses `VoteShiftMode = current_period` for the main branches, with small
  finite-horizon construction-effect comparisons (`VoteShiftHorizon` 2, 3, 5).
  The packet restarts from the best previous near-miss `rbr20end100_k8` outer
  `1`, tests seeds `guess`, `end100`, and `critical7end100`, and includes one
  pass-through sensitivity at `-0.003` and `-0.012` around the locked
  `-0.006`. At submit check, tasks `0`-`10` were running and task `11` was
  pending. Promotion rule remains max reported T20 path gap `<= 0.001`;
  `<= 0.0002` is paper-safe.
- 2026-05-08 annual-vote early read: first visible branch was
  `av20cur_ref_g` at outer `1`, with max path gap `0.00990991` and max vote
  residual `0.0444785`, far worse than the previous near-miss and the `0.001`
  promotion target. Cancelled array task `17067913_10`. The other annual-vote
  timing branches remain running; no syntax failures are visible.
- 2026-05-08 annual-vote current-period read: the pure current-period
  branches that reported were all far above promotion. Best among them was the
  weaker pass-through branch `av20cur_g_p003` at `0.00697936`; the main
  `-0.006` current-period branches were around `0.00991`-`0.01057`, and
  `-0.012` was `0.01577`. Cancelled current-period tasks `17067913_0`, `_1`,
  `_2`, `_3`, `_4`, `_5`, and `_11` (plus earlier `_10`). Kept finite-horizon
  tasks `17067913_6`-`_9` running because they test short-lived construction
  effects rather than a pure one-period price comparison.
- 2026-05-08 annual-vote wider smoke: submitted Hamilton job `17069045`
  (`bb20avwd`, tasks `0-7`) to use time more efficiently while the first
  finite-horizon smoke continues. This packet does not add more damping
  variants. It widens only the construction-effect comparison horizon:
  `VoteShiftHorizon` `8`, `10`, `15`, `20`, plus two `critical7end100` seeds
  at horizons `10` and `20`, and two longer-tail checks with `TailYears = 40`
  at horizons `20` and `30`. It restarts from `rbr20end100_k8` outer `1`;
  promotion rule remains max reported T20 path gap `<= 0.001`, with
  `<= 0.0002` as the paper-safe target.
- 2026-05-08 annual-vote h5 continuation: after `av20fh5_g_k8` improved from
  `0.00449884` to `0.00371732` to `0.00290906` over its first three outer
  rows, submitted targeted continuation job `17069147` (`bb20avc5`, tasks
  `0-3`). This restarts from `av20fh5_g_k8` outer `3` and tests
  `VoteShiftHorizon` `5`, `6`, `8`, and `10`. The goal is to avoid losing the
  only improving annual-vote branch to the original four-hour wall clock while
  the wider horizon packet is still waiting for first rows.
- 2026-05-08 annual-vote original smoke latest/final read: the short-horizon
  annual-vote packet `17067913` is no longer live. Its best branch was
  `av20fh5_g_k8`, which improved through outer rows
  `0.00449884 -> 0.00371732 -> 0.00290906 -> 0.00243256` before the task hit
  the four-hour wall clock. This remains above the `0.001` T20 promotion
  threshold and above the `0.0002` paper-safe target, but it is the only
  annual-vote branch with a clear improving direction. The continuation
  `17069147` and wider horizon packet `17069045` remain live.
- 2026-05-08 12-hour annual-vote failsafe: updated heartbeat automation
  `check-nimby-annual-vote-smoke` to run every 15 minutes for 48 checks. It
  monitors live jobs `17069045` and `17069147` plus at most one direct
  successor. Promotion rule is unchanged: a T20 branch with max path gap
  `<= 0.001` triggers notification and a T80 promotion only from that exact
  branch if the source paths and existing promotion workflow are unambiguous;
  `<= 0.0002` is paper-safe. The failsafe may cancel clear losers, and it may
  submit at most one additional 4-hour continuation only if the best live
  branch beats `0.00243256`, remains above `0.001`, and is monotonically
  improving. It must not launch new model families, ghost-tail/anchor variants,
  or broad damping sweeps. If all allowed branches finish above `0.001`, it
  should record annual-vote timing as failed promotion, notify the user, and
  delete the heartbeat automation.
- 2026-05-09 annual-vote failsafe continuation: wider finite-horizon job
  `17069045` and h5 continuation `17069147` both reached their four-hour
  limits without crossing promotion. Best new branch was `av20fh5c_h6_k8`
  outer `4`, with max path gap `0.00233993`, max vote residual `0.0501932`,
  and a monotone path-gap sequence
  `0.00470557 -> 0.00391335 -> 0.00309294 -> 0.00233993`. This beats the
  previous h5 best `0.00243256` but remains above the `0.001` promotion
  threshold and far above the `0.0002` paper-safe target. Per the 12-hour
  failsafe rule, submitted the one allowed direct successor job `17070620`
  (`bb20avf6`, tasks `0-1`), restarting from `av20fh5c_h6_k8` outer `4` and
  testing only horizons `6` and `7`. No further continuation branches should
  be submitted by this failsafe; if `17070620` finishes above `0.001`, record
  annual-vote timing as failed promotion and stop the automation.
- 2026-05-09 final h6 failsafe live read: job `17070620` is running and the
  h6 branch `av20fh6f_h6_k8` has improved the annual-vote best to
  `0.00181196` at outer `2` (max vote residual `0.0503729`). This is a
  material improvement from `0.00233993`, but still above the `0.001` T20
  promotion threshold and far above the `0.0002` paper-safe target. The h7
  branch first row was worse at `0.00249685`. Per the failsafe, no further
  continuation branches should be submitted; wait for `17070620` to finish or
  time out and promote only if a reported row reaches `<= 0.001`.
- 2026-05-09 final annual-vote failsafe result: Hamilton job `17070620`
  (`bb20avf6`) hit the four-hour wall clock on both tasks without any T20 row
  crossing the `0.001` promotion threshold. Best annual-vote row is now
  `av20fh6f_h6_k8` outer `3`, with max path gap `0.00167602` and max vote
  residual `0.0507223`; h7 was worse, with best row `0.00189438` and max vote
  residual `0.0594301`. This is a useful diagnostic improvement from
  `0.00233993`, but annual-vote political timing failed promotion and remains
  far above the `0.0002` paper-safe target. Per the agreed failsafe and Oracle
  review, do not submit more annual-vote continuation branches or broad
  Hamilton variants from this path. Treat annual-vote timing as a diagnostic or
  robustness exercise unless a separate modeling decision changes the object.
- 2026-05-09 parallel RE rescue restart after user clarification: the annual
  vote result should not be treated as "give up on RE." There are now two
  separated routes. First, submitted Hamilton job `17071550` (`bb20avsd`,
  array `0-5`) as a fresh-seed annual-vote homotopy: it solves the annual-vote
  finite-horizon object at pass-throughs `0.0030 -> 0.0045 -> 0.0060`, carrying
  the best annual-vote seed forward instead of continuing the failed h6 path.
  It tests h5/h6 from three source families: `rbr20end100_k8` outer `1`,
  `rb20guess_k8` outer `2`, and `brh20d80c005_p0060` outer `7`. Second,
  submitted Hamilton job `17071551` (`bb20opol`, array `0-7`) as an original
  path-shift near-miss polish: it restarts from the best original-object seeds
  around gaps `0.001109`-`0.001149`, uses smaller reduced-basis/Broyden steps,
  and focuses on the critical years and report-end years. Decision rule:
  if either packet reports a T20 max path gap `<= 0.001`, promote only that
  exact branch to T80; if `<= 0.0002`, it is paper-safe at T20. If neither
  packet clears `0.001`, stop blind variants and make an explicit modeling
  decision about the RE object or terminal treatment.
- 2026-05-09 five-year block-vote branch: added `VoteShiftMode = block_vote`
  with `VoteBlockLength = 5` to the annual RE solver. This is not the same as
  the earlier h5 finite-horizon annual-vote runs. It means one vote sets the
  political restriction for a five-year block, then the next block gets a new
  vote. Submitted Hamilton job `17071923` (`bb20bv5`, array `0-3`), a narrow
  pass-through homotopy `0.0030 -> 0.0045 -> 0.0060` from four source seeds:
  `rbr20end100_k8` outer `1`, `rb20end50_k8` outer `4`, `rb20guess_k8` outer
  `2`, and `brh20d80c005_p0060` outer `7`. Same rule: T20 gap `<= 0.001`
  triggers exact-branch T80 promotion; `<= 0.0002` is paper-safe.
- 2026-05-09 intermediate homotopy breakthrough: the new political-timing
  homotopy branches crossed the `0.001` threshold at the intermediate
  pass-through stage `p0030`, not yet at the target `p0060` stage. Best current
  row is annual-vote fresh seed `avsd_h5_brh_p0030` outer `4`, with max path
  gap `0.000942205` and max vote residual `0.0243019`. Five-year block-vote
  also crossed at `p0030`: `bv5_rbend_p0030` outer `5` gap `0.000948474`,
  and `bv5_rbguess_p0030` outer `4` gap `0.000952978`. These are real
  improvements and show the fresh-seed/block-vote route is live, but they are
  not yet full-target promotion results because the chain still has to survive
  `p0045` and then target pass-through `p0060`. Do not submit T80 from these
  intermediate `p0030` rows unless explicitly deciding to change the target
  pass-through; keep monitoring the chain for `p0060 <= 0.001`.
- 2026-05-09 four-year block-vote branch: because U.S. state political cycles
  are more naturally four-year than five-year, added a parallel
  `VoteShiftMode = block_vote` job with `VoteBlockLength = 4`. Submitted
  Hamilton job `17072544` (`bb20bv4`, array `0-3`) from the same four source
  seeds as `bb20bv5`. Compare annual-vote, five-year block-vote, and
  four-year block-vote only at the same homotopy stage; the target promotion
  rule remains full `p0060 <= 0.001`.
- 2026-05-09 five-year block-vote intermediate trigger: job `17071923`
  (`bb20bv5`) has now crossed the `0.001` threshold at the intermediate
  `p0045` stage. Best visible rows are `bv5_rbguess_p0045` outer `6`, max path
  gap `0.000863389` and max vote residual `0.0215626`, and
  `bv5_rbend_p0045` outer `7`, max path gap `0.000965247` and max vote
  residual `0.0225703`. This is a real improvement and keeps the five-year
  block-vote route live, but it is not yet a T80 promotion result: the target
  stage is still `p0060 <= 0.001`, and there are no `p0060` rows yet.
- 2026-05-09 five-year block-vote T20 promotion trigger: job `17071923`
  (`bb20bv5`) produced target `p0060` rows below the `0.001` T20 promotion
  threshold. Best visible target row is `bv5_rbguess_p0060` outer `8`, max path
  gap `0.000814014`, max vote residual `0.0214950`, mean vote residual
  `0.0166167`; `bv5_rbend_p0060` also cleared with best visible gap about
  `0.000897717`. This clears the T20 promotion threshold, but it is not
  paper-safe at T20 because it remains above the `0.0002` paper-safe target.
  Submitted exact-source T80 promotion job `17073814` (`bb80bv5`, array `0-2`)
  using `bv5_rbguess_p0060` outer `8` as the seed and preserving
  `VoteShiftMode = block_vote`, `VoteBlockLength = 5`, pass-through `-0.006`,
  and the published baby-boom demographic path. Local/remote script:
  `drafts_re/hamilton_jobs/bb80blockvote5_promote_0509.slurm` and
  `/nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual/bb80blockvote5_promote_0509.slurm`.
- 2026-05-09 model-acceptability reset: user rejected the five-year block-vote
  interpretation as not defensible enough. Cancelled five-year T80 promotion
  job `17073814` (`bb80bv5`) and remaining five-year T20 task `17071923_3`.
  Keep the five-year result only as a numerical diagnostic that the solver can
  clear T20, not as an acceptable paper route. The acceptable live routes are
  now annual-vote/fresh-seed (`17071550`, `bb20avsd`) and four-year block-vote
  (`17072544`, `bb20bv4`). Added and uploaded
  `drafts_re/hamilton_jobs/run_t80_accepted_promotion_0509.m`, a small helper
  for exact-source T80 promotion from whichever acceptable T20 `p0060` branch
  clears `0.001`.
- 2026-05-09 acceptable-route near miss: annual-vote/fresh-seed job `17071550`
  timed out without an acceptable target `p0060` summary. Four-year block-vote
  job `17072544` is still running and has reached target `p0060`; the best
  visible acceptable row is `bv4_brh_p0060` outer `4`, max path gap
  `0.00111560`, max vote residual `0.00776448`. This is a near miss within
  `0.0012` but still above the `0.001` promotion threshold, so do not submit
  T80 yet.
- 2026-05-10 four-year polish: after the remaining live four-year branch was
  clearly worse than the near miss, cancelled `17072544_0` and submitted the
  one allowed narrow polish from exact source `bv4_brh_p0060` outer `4` as
  Hamilton job `17074423` (`bb20bv4p`, array `0-5`). The polish preserves
  `VoteShiftMode = block_vote`, `VoteBlockLength = 4`, and target pass-through
  `-0.006`; it tests only small seed/update variants around the best
  acceptable row. Do not revive five-year or launch broad blind variants.
- 2026-05-10 no-RE four-year comparator: patched the no-RE fail-safe solver so
  it also accepts `VoteShiftMode = block_vote` and `VoteBlockLength = 4`.
  This holds the vote-implied restriction fixed for each four-year block and
  then takes a new vote. Uploaded the patched solver and submitted Hamilton job
  `17074451` (`nore80bv4`, array `0-2`) for pass-throughs `0.006`, `0.012`,
  and `0.018`, with T20/T80 outputs under
  `annual_political_transition_fail_safe/nore80bv4_*`. This gives a
  like-for-like no-RE baseline if the four-year RE route promotes.
- 2026-05-10 no-RE four-year comparator completion: Hamilton job `17074451`
  completed cleanly. The `0.006` and `0.012` pass-through T80 outputs are
  usable: `nore80bv4_006` has max vote residual `0.0101070` and max log price
  move `0.00279781`; `nore80bv4_012` has max vote residual `0.0114996` and
  max log price move `0.00610918`. The `0.018` output is a survivor rather
  than clean usable: max vote residual `0.0232139`, max log price move
  `0.0147822`. This confirms the no-RE side can be done on the four-year
  political clock.
- 2026-05-10 four-year T20 promotion trigger: the acceptable four-year
  block-vote polish job `17074423` crossed the T20 promotion threshold.
  Winning visible row: `bv4p_r25_d18` outer `2`, report horizon `20`,
  internal horizon `40`, max path gap `0.000989508`, max vote residual
  `0.00647572`, and max log price move `0.00221812`. This is below the
  `0.001` T20 promotion threshold, but not below the `0.0002` paper-safe
  target. Submitted exact-source T80 promotion job `17074725` (`bb80bv4`,
  array `0-2`) from that branch, preserving `VoteShiftMode = block_vote`,
  `VoteBlockLength = 4`, and pass-through `-0.006`. Local/remote script:
  `drafts_re/hamilton_jobs/bb80blockvote4_promote_0510.slurm` and
  `/nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual/bb80blockvote4_promote_0510.slurm`.
- 2026-05-10 improved four-year source: the same T20 branch improved further
  to `bv4p_r25_d18` outer `4`, max path gap `0.000924056`, max vote residual
  `0.00627314`. Submitted a second exact-source T80 promotion from that
  improved row as job `17074755` (`bb80bv4o4`, array `0-2`). This is not a
  new model variant; it is the same four-year accepted branch promoted from a
  better T20 seed. Local/remote script:
  `drafts_re/hamilton_jobs/bb80blockvote4_o4_promote_0510.slurm` and
  `/nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual/bb80blockvote4_o4_promote_0510.slurm`.
- 2026-05-10 further improved four-year source: the same branch improved to
  `bv4p_r25_d18` outer `5`, max path gap `0.000857297`, max vote residual
  `0.00582734`, and max log price move `0.00219694`. Submitted a third
  exact-source T80 promotion from this better seed as job `17074802`
  (`bb80bv4o5`, array `0-2`). This remains the same accepted four-year model,
  not a broad new variant. Local/remote script:
  `drafts_re/hamilton_jobs/bb80blockvote4_o5_promote_0510.slurm` and
  `/nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual/bb80blockvote4_o5_promote_0510.slurm`.
- 2026-05-10 best current four-year source: the same branch improved again to
  `bv4p_r25_d18` outer `6`, max path gap `0.000796333`, max vote residual
  `0.00601394`, and max log price move `0.00213763`. Submitted a fourth
  exact-source T80 promotion from this best current seed as job `17074822`
  (`bb80bv4o6`, array `0-2`). Local/remote script:
  `drafts_re/hamilton_jobs/bb80blockvote4_o6_promote_0510.slurm` and
  `/nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual/bb80blockvote4_o6_promote_0510.slurm`.
- 2026-05-10 four-year T20 polish completion: Hamilton job `17074423`
  completed cleanly. The best final T20 row was `bv4p_r25_d14` outer `14`,
  max path gap `0.000735817`, max vote residual `0.00622223`, and max log
  price move `0.00201609`. This is below the `0.001` T20 promotion threshold
  but still above the `0.0002` paper-safe target. It is only a modest
  improvement over the already-promoted outer-6 seed, so no fifth T80
  promotion was submitted while the four existing exact-source T80 promotions
  remain live.
- 2026-05-10 long-block diagnostic submitted: after the user asked whether
  one vote every `20` or `40` years could provide a better seed for the
  acceptable four-year model, submitted a narrow diagnostic-only T80 job
  `17075892` (`bb80bvl`, array `0-3`). It tests vote block lengths `20` and
  `40`, each from `bv4p_r25_d14` outer `14` and `bv4p_r25_d18` outer `6`.
  This is not an acceptable paper route by itself. If it solves better than
  the live four-year T80 jobs, use it only as a possible continuation seed to
  homotopy back to `VoteBlockLength = 4`.
- 2026-05-10 four-year full-seed T80 rescue first readout: Hamilton job
  `17076871` (`bb80bv4fs`) is a seed change, not a model change: it preserves
  `VoteShiftMode = block_vote`, `VoteBlockLength = 4`, and pass-through
  `-0.006`, but initializes the T80 RE target from full-horizon no-RE/hybrid
  price paths. First visible rows improved the best acceptable T80 gap from
  the direct-promotion best `0.00685190` to `0.00458603` in
  `bv80bv4fs_n006_d022` outer `1` (max vote residual `0.00943235`, max log
  price move `0.00279781`). This is a useful directional improvement but still
  far above the `0.001` promotion threshold and the `0.0002` paper-safe target.
- 2026-05-10 four-year T80 update: ordinary non-PTY SSH to Hamilton was
  hanging after authentication, but a forced PTY plus stdin script works for
  read-only monitoring. All exact-source T80 promotion arrays `17074725`,
  `17074755`, `17074802`, and `17074822` completed cleanly and failed to clear
  the `0.001` threshold; their best durable row remains `0.00685190`. The live
  full-seed rescue `17076871` improved further: best visible row is now
  `bv80bv4fs_h006_d030` outer `8`, max path gap `0.00280127`, max vote
  residual `0.0154794`, and max log price move `0.00535724`. This is a real
  improvement over `0.00458603` but still about `2.8x` above the T80 promotion
  threshold. Long-block diagnostic `17075892` is still worse so far:
  `bv80bvl20_d14` outer `6` has gap `0.00975817`; the `40`-year rows had not
  reported at this readout.
- 2026-05-07 detailed session handoff for archive:
  `drafts_re/session_handoffs/2026-05-07-codex-handoff-re-transition.md`.
  Fresh Codex threads should read this after `STATUS.md` and then immediately
  check Hamilton job `17042468`.
- 2026-05-06 completed local plain-damping refinement: no local MATLAB process
  is currently running. The T20 damping variants improved the RE path gap from
  about `0.00586` to a best diagnostic gap around `0.00385`, but this remains
  far above the paper-safe target. Treat this as evidence to stop plain damping
  as the main strategy and move to Anderson/homotopy.
- 2026-05-06 no-RE interpretation: the locked no-RE smooth-politics line is
  flatter than the old-paper current-price line because it holds the same
  political pass-through magnitude as the RE benchmark (`0.006`). In the
  locked no-RE run, the maximum smoothed political pressure is only about
  `0.34`, so `0.006 * 0.34` gives a maximum log price movement of about
  `0.00205`. The old-paper trough is about `0.00626`, which would require a
  pass-through around `0.016` to `0.019` using the same no-RE pressure signal.
  Thus the difference is not primarily RE versus no-RE; it is that the old
  current-price transition effectively corresponds to a stronger price
  response than the locked comparable-pass-through no-RE comparator.
- 2026-05-06 paired pass-through workflow: the preferred paper comparison is
  now a range of common political pass-through magnitudes, comparing RE and
  no-RE within each magnitude rather than selecting a single no-RE parameter to
  match the old figure. Scripts prepared:
  `D:\AI_storage\spillover\nimby_re_fig_inputs\ham_code\run_local_no_re_pass_through_range_0506.m`
  and
  `D:\AI_storage\spillover\nimby_re_fig_inputs\ham_code\run_local_re_pass_through_range_T20_0506.m`.
  The grid is `{0.006, 0.012, 0.018, 0.024}`. The no-RE grid is running
  locally now as `nore_ptrange_0506`; earlier starts failed from a MATLAB path
  collision around `TransitionMatrix.mat`, but the shared runner was patched to
  put the SteadyState parent folder and intended function directory first on
  the MATLAB path. The RE range script is prepared but should wait until the
  current RE fixed-point refinement finishes, so we do not run two heavy RE
  ladders at once.
- 2026-05-06 Oracle review attempt: prepared a compact Oracle bundle at
  `D:\AI_storage\spillover\nimby_re_fig_inputs\oracle_bundle_re_strategy_0506`
  with the prompt, solver files, figure builder, scoring scripts, and key
  RE/no-RE summary/path diagnostics. Dry run was successful: 17 files, about
  109k tokens. Browser upload failed before sending because Oracle could not
  find a logged-in ChatGPT browser session/model selector. No API run was
  launched because that requires explicit user approval for potential cost.
- 2026-05-06 Oracle review completed: reran Oracle with browser model selector
  ignored, using the current logged-in ChatGPT state. Full response saved at
  `D:\AI_storage\spillover\nimby_re_fig_inputs\oracle_bundle_re_strategy_0506\oracle_re_strategy_response_0506.md`.
  Oracle agreed that the modelling route is defensible as a reduced-form
  political transition experiment, but said the current RE figure is not
  paper-safe because the fixed-point residual is the same order as the whole
  price movement. It specifically flagged the figure builder's use of
  `price_guess` as misleading for unconverged RE runs, recommended a hard
  figure-build guard on `price_guess` vs `price_generated`, recommended common
  pass-through ranges plus one old-paper-matched calibration as reference, and
  advised stopping plain damping if the current T20 ladder stalls around
  `0.004`-`0.005`. Recommended next numerical route: explicit log-price map
  `F(x)-x`, Anderson acceleration with safeguards, homotopy in pass-through,
  then Broyden/reduced-basis root solve if needed. Suggested paper-safe RE
  tolerance: max log path residual around `0.0001`-`0.0002`, or at least well
  below 5% of the plotted price amplitude.
- Extra workflow additions now required:
  1. Add a paper-figure guard to `build_matched_transition_figures.py`: if a
     run has both `price_guess` and `price_generated`, refuse paper output
     unless max log gap is below the selected tolerance. Diagnostic figures may
     still be produced with an explicit override.
  2. Add an RE convergence dashboard for every RE run: plot/report
     `price_guess`, `price_generated`, residual `log(price_generated/price_guess)`,
     residual-to-amplitude ratio, trough timing, trough magnitude, and sign
     mismatch count.
  3. Fix the no-RE within-period storage/iteration logic so the stored price,
     vote, pressure, and restriction all come from the same final fixed-point
     evaluation. Then rerun the no-RE pass-through grid.
  4. Finish current plain-damping T20 RE ladder only as a diagnostic. If it
     stalls around `0.004`-`0.005`, stop plain damping and do not escalate that
     method to T80 as a paper solution.
  5. Implement an explicit RE fixed-point map in log prices, `x -> F(x)`, with
     residual `F(x)-x`. This should be the core object for Anderson/homotopy
     rather than relying on plotted `price_guess` paths.
  6. Implement Anderson acceleration with safeguards: memory 3-8, step clamp,
     accept only if residual falls, otherwise fall back to damped Picard.
  7. Implement pass-through homotopy: solve from `0` to `0.006`, then continue
     through `{0.012, 0.018, 0.024}` using each solved path as the next seed.
  8. If Anderson/homotopy does not converge, implement a low-dimensional smooth
     price-path basis or spline representation and solve for basis coefficients
     with Broyden/secant/least-squares residual minimization.
  9. Build two comparison objects after convergence: (i) common pass-through
     range RE vs no-RE, and (ii) one old-paper-matched no-RE pass-through
     calibration applied unchanged to RE.
  10. Only after the above passes, regenerate baby-boom figures, then repeat
      the same workflow for secular decline. Keep LyX untouched; LaTeX edits
      remain blue until approved.
- 2026-05-06 T20 RE damping ladder result: the plain-damping refinement ladder
  completed. Best case is `br20h10` with max path gap about `0.00385`, mean
  path gap about `0.00268`, max vote residual about `0.01105`, and max log
  price movement about `0.00216`. This is an improvement over the earlier
  `0.00586` gap but still not close to the paper-safe target. Conclusion:
  do not escalate plain damping to T80 as the main solution; implement the
  Anderson/homotopy residual workflow next.
- 2026-05-06 no-RE pass-through range completed: `nore_ptrange_0506` finished
  T20 and T80 locally. All four T80 common pass-through magnitudes are usable:
  `0.006` gives max log price move about `0.00205`, `0.012` gives `0.00328`,
  `0.018` gives `0.00392`, and `0.024` gives `0.00444`; max vote residuals
  fall from about `0.00711` to `0.00374`. This confirms the old-paper mismatch
  is largely a pass-through-strength issue, not a failure of the no-RE smooth
  transition itself. No local MATLAB processes are running after completion.
- Latest figure correction: the baby-boom current-price cohort figure has
  been rebuilt from the original paper current-price cohort series rather than
  from the solved no-RE/current-price output. The solved no-RE comparator is
  currently unsuitable for the paper figure because its early house-price path
  moves above steady state, while the original current-price benchmark moves
  below steady state. That sign/direction mismatch was mechanically making the
  children net-worth line too high. The figure builder now defaults to the old
  current-price benchmark and only uses the solved no-RE output if explicitly
  requested with `--use-solved-no-re-current-price`.
- Latest 2026-05-05 action: Hamilton old-baseline RE eta grid job `16947947`
  (`obre80`, array `0-2`) completed cleanly. All three eta values are usable
  numerically on the T80 published-baby-boom path with the old-paper baseline:
  `eta = -0.006` is currently the best numerical survivor with max path gap
  about `0.00586`, max vote residual about `0.01682`, and mean homeownership
  about `0.42044`; `eta = -0.012` and `eta = -0.020` are also usable but have
  larger path gaps. This is still not paper-ready until the old-baseline
  no-RE/current-price comparator job `16947946` (`obnr80`) finishes and passes
  the old-paper-shape sanity check.
- Diagnostic plots after pulling the completed RE outputs are in
  `figures/re_transition/paper_definition_checks/`. The report-horizon path
  looks numerically plausible but the strong performance is partly mechanical:
  the RE solver was initialized from the old paper price path, uses very small
  path relaxation, and the best `eta = -0.006` pass-through is weak. The
  internal terminal tail is less clean and should not be confused with the
  80-year paper horizon.
- Fail-safe update: the original old-baseline no-RE comparator job `16947946`
  is still running serially and only writes outputs after all candidates. To
  avoid losing time, a one-candidate-per-task insurance array `16953583`
  (`obnr1`, tasks `0-2`) has been submitted for `phi = -0.006`, `-0.012`, and
  `-0.020`. The figure builder now accepts run-directory overrides so the
  completed old-baseline RE output can be paired with whichever no-RE
  candidate lands first.
- Local insurance update: one local MATLAB run is also active for the best
  weak-pass-through no-RE candidate only, `local_obn006_T80_0505c`
  (`phi = -0.006`). Earlier local starts failed before solving because of
  local MATLAB path issues; the active run now reaches `Running T=80 candidate
  1/1`.
- Completion update: the Hamilton old-baseline no-RE jobs finished cleanly and
  have been pulled locally. The serial job `16947946` and insurance array
  `16953583` agree. Best current no-RE control is `phi = -0.006`, with max
  vote residual about `0.01042`, mean vote residual about `0.00452`, max log
  price move about `0.00287`, and mean homeownership about `0.41853`. The
  `phi = -0.012` run is also usable but weaker; `phi = -0.020` is only a
  survivor. Diagnostic RE-vs-no-RE baby-boom figures using old-baseline RE
  `eta = -0.006` and no-RE `phi = -0.006` are in
  `figures/re_transition/paper_definition_checks/oldbase_pair_0505/`. The
  diagnostic now passes the basic sanity checks: demographics match, old
  baseline is used, lifecycle/cohort lines do not collapse, and the previous
  wrong-source graph failure is gone. It is still a diagnostic figure set, not
  yet a cleaned paper insertion.
- Figure audit update: after visual inspection, the current-price cohort
  housing panel was corrected to use total housing services (`H + Rent`)
  consistently for parents, boom, and children. The prior version mixed total
  housing services for the boom with owned housing for children/parents, which
  mechanically exaggerated young-child ratios because baseline owned housing is
  close to zero. The regenerated baby-boom cohort figures now remove that spike;
  the remaining children-above-boom feature in the current-price panel is a
  small normalized-net-worth timing effect, not a housing-services spike.
- Figure convention update: the main cohort figure now follows the original
  draft's temporary-shock content and reports only net worth and consumption.
  Cohort homeownership was removed from the paper figure because raw rates
  mostly show the normal life-cycle rise in ownership, while indexed ratios are
  unstable for young cohorts with near-zero benchmark ownership.
- Current-period vote-shift robustness update: the full RE solver now supports
  `VoteShiftMode = 'current_period'`, which perturbs only the current-period
  vote comparison while leaving future expected prices on the solved RE path.
  Local old-baseline T20 published-baby-boom checks completed for
  `eta = -0.003`, `-0.006`, and `-0.020`. They are numerical survivors, but
  the max vote residual remains high and nearly unchanged at about `0.045`
  across the grid. This indicates the issue is not simple eta tuning. The
  persistent path-shift vote object used in the current RE figure is therefore
  an important modelling assumption, not just a numerical convenience. A
  post-patch T4 smoke for the default `path_shift` mode passed with max vote
  residual about `0.0027`, so the current paper-figure branch still executes
  cleanly. A T80 Hamilton script with short job name `obrcp` is prepared, but
  Hamilton SSH is currently timing out from this machine.
- Additional RE robustness update: the solver also now supports
  `VoteShiftMode = 'finite_horizon'`, where the vote comparison shifts prices
  only for a finite number of future years before returning to the solved RE
  path. Local T4 smokes show that a 5-year horizon is intermediate but still
  not close enough (max vote residual about `0.0363`), and a 10-year
  short-horizon smoke is worse (about `0.0538`). This points toward a
  modelling interpretation rather than a numerical eta fix: the clean branch is
  the persistent path-shift policy object. A second Hamilton script with short
  job name `obrfh` is prepared for finite-horizon T80 runs once Hamilton SSH is
  reachable.
- Figure validation workflow now active: no transition/cohort figure should be
  treated as paper-safe until it passes four checks: (i) source-object check
  against the old-paper baseline and intended RE/no-RE output folders, (ii)
  code-definition check for cohort windows, denominators, smoothing, labels,
  and owner/renter averaging, (iii) visual robustness checks comparing
  smoothed and unsmoothed panels plus separate RE and current-price panels, and
  (iv) economic decomposition checks for cohort net worth, homeownership,
  owned housing, rental housing, and consumption. Three independent agents are
  currently assigned to the figure-code audit, MATLAB output/model-object
  audit, and robustness-diagnostic figure generation. Canonical paper figures
  should not be overwritten while this audit is in progress.
- Figure validation results: independent audits found no confirmed bug in the
  baby-boom RE source object, the RE price-path interpretation, or the
  owner/renter averaging for `NW`, `C`, `H`, `Rent`, and homeownership. These
  are full within-age distribution means, not homeowner-only means. The main
  remaining risks are presentation and robustness: the figure legend should
  distinguish the old-paper current-price benchmark from a solved no-RE run;
  smoothing should be disclosed; the old-paper young-homeownership display
  shift should be described if used; stale secular figure files should not be
  reused; and the cohort panels should be checked against a population-weighted
  cohort version. Diagnostic robustness outputs are in
  `figures/re_transition/figure_robustness_checks/baby_boom_re_obre80_e006/`.
  They show the RE children-above-boom net-worth feature is real in the current
  output (`22/31` overlapping periods, max gap about `0.0112`) but does not
  come from children owning more housing or consuming more housing services:
  children are above the boom cohort in `0/31` overlapping periods for both
  homeownership and total housing services.
- Population-weighted cohort robustness completed: weighting ages within each
  moving cohort window by period age shares does not remove the RE
  children-above-boom net-worth feature. In the population-weighted diagnostic,
  children are above boom in `23/31` raw overlapping periods and `22/31`
  smoothed overlapping periods, with max gap about `0.0113`, while still being
  above boom in `0/31` periods for homeownership and total housing services.
  This means the feature is not an artefact of unweighted age-window averaging.
- Overnight no-RE smoothed-politics workflow active: a local hidden PowerShell
  runner was started at `2026-05-05T22:50` to search positive-phi
  smoothed-politics no-RE candidates. This follows the T4 smoke result showing
  positive phi moves prices downward, the old-current-price direction, while
  keeping vote residuals low. The workflow runs a broad T20/T80 positive-phi
  grid, then lagged pass-through T80 checks with 2- and 5-year lags, and scores
  each output against both political residuals and the old current-price path.
  Status file:
  `figures/re_transition/figure_robustness_checks/no_re_smooth_politics/overnight_status.json`.
  Diagnostic scores and plots will be written to the same folder. Hamilton
  upload is prepared through `oldbase_no_re_positive_T80.slurm`, but the
  overnight runner's first SSH attempt timed out, so local MATLAB is the active
  lane.
- Referee-risk correction: the broad positive-phi no-RE grid was stopped on
  `2026-05-06` before writing T80 output because it risks looking like
  arbitrary multi-parameter curve fitting. Its completed T20 stage is retained
  as a diagnostic only. The paper-safe replacement run is
  `locked_nore_smooth_phi006_T20_T80_0506`, with `rho = 0`, `gamma = 1`, and
  `phi = 0.006`, matching the magnitude of the selected RE pass-through rather
  than selecting a best-fitting no-RE line. This run is active locally and
  currently on `T=20`, candidate `1/1`.
- High-pass-through diagnostic: a deliberately aggressive no-RE T8 smoke
  `smoke_nore_high_phi_T8_0506` is also active locally with `rho = 0`,
  `gamma = 1`, and `phi` in `{0.15, 0.25, 0.40}`. This is explicitly not a
  paper baseline; it is only checking whether very large pass-through stabilizes
  the smoothed no-RE path or just hits caps/creates large vote residuals. Prior
  T20 evidence already shows `phi = 0.08` and `phi = 0.10` are dead, with max
  vote residuals around `0.57`.
- Safety update: an independent read-only audit flagged the existing secular
  decline figures as wrong-source outputs (`reference_price ~= 6.06`, not the
  old-paper baseline `8.9813`). The LaTeX paper now omits those figures and
  leaves a blue placeholder until old-baseline secular RE and current-price
  runs are regenerated. The figure builder defaults now point to the locked
  old-baseline baby-boom pair and refuse multi-candidate output folders for
  paper figures.
- Prior 2026-05-05 action: the figure builder now has an old-paper
  definition mode using the explicit published baby-boom path, old-paper
  25-35 homeownership definition, and `ss_eq.age` cohort denominators. The
  corrected diagnostic confirms the bad current matched no-RE figure is driven
  by the wrong source object: raw young homeownership is about `0.63` in
  `nrpaper_0501b` versus about `0.03` in the original paper object before the
  old paper's display shift. A source-object audit confirms that
  `loop101_output_extended.mat` is a materially different calibration, not a
  harmless re-export of the old paper model: parameters including `Ph_ss`,
  `beta`, `chi`, `deltaPh`, `hmin`, `kappa`, and `psi_x` differ sharply from
  the old paper `irfs_smoothed.mat` object. A short old-baseline smooth-vote
  T4 smoke passed locally with negative pass-through. Hamilton job `16947946`
  (`obnr80`) is still running the full T80 old-baseline no-RE comparator.
- Current 2026-05-05 correction: the generated matched transition figures
  (`fig_matched_baby_boom_transition`, `fig_matched_baby_boom_cohorts`,
  `fig_matched_secular_decline_transition`, and
  `fig_matched_secular_decline_cohorts`) are invalid as paper figures. They
  were built from runs anchored to `reference_price ~= 6.06` and
  `target_vote ~= 0.829`, while the old published baby-boom object is anchored
  to `param.Ph_ss ~= 8.9813` and `TargetVote ~= 0.3916`. This is a different
  steady-state object, not merely a different graph denominator. The current
  figure builder now refuses these inputs by default. The immediate next task
  is to rebuild the no-RE/current-price comparator so that it reproduces the
  old period-by-period market-clearing transition shape under the published
  baby-boom shock, then rerun the RE comparison from the same old-paper
  baseline.
- Superseded 2026-05-01 graph workflow note: the intended clean comparison was
  to hold political smoothing fixed in both series and vary only expectations.
  The latest 2026-05-05 figure audit showed that the available solved
  no-RE/current-price output does not reproduce the original current-price
  direction for the baby boom, so paper figures currently use the original
  current-price benchmark as the dashed comparison while the smoothed no-RE
  pass-through issue remains a diagnostic problem.
- Latest 2026-05-01 Hamilton read: `pbpaper` (`16918434`) completed cleanly
  and reproduces the selected published-baby-boom RE path: max path gap about
  `0.0261`, max vote residual about `0.0184`, mean vote residual about
  `0.0067`, verdict `survivor`. The matched baby-boom current-price/no-RE
  comparator is usable, with max vote residual about `0.0058`. The secular RE
  path has reached outer iteration `3` while still running, with max path gap
  about `0.0383`, max vote residual about `0.0224`, and mean vote residual
  about `0.0169`. The secular current-price/no-RE comparator is a survivor,
  with max vote residual about `0.0214`. The live Hamilton jobs are now only
  the continuing secular RE pass and three baby-boom fixed-point refinements.
- Active paper-output workflow: draw the transition figures from matched
  smoothed-politics outputs, then update the LaTeX paper with minimal blue
  edits. Figure `7` should compare the baby-boom transition under deterministic
  RE and the current-price/no-RE rule. Figure `8` should show the corresponding
  cohort outcomes. Figure `9` should do the same for the permanent/secular
  demographic shock. These paper figures should not mix old hard-vote transition
  panels with the new smoothed-vote RE panels. In parallel, Hamilton array job
  `16919098` (`bbfit`) is testing three smaller-relaxation baby-boom fixed-point
  refinements. If one improves on the current `0.0261` max path gap without
  worsening the vote residual materially, refresh the figure input path. The
  LaTeX model section now defines the smoothed logit vote object in blue and
  states the hard-vote rule as the `tau -> 0` limiting case. The graph builder
  now aggregates parent, boom, and child cohort panels over 10-year birth-year
  windows rather than a single birth year.
- Latest paper-output update: the matched no-RE comparator outputs have landed
  and been pulled locally. The figure builder has generated the four working
  paper figures:
  `fig_matched_baby_boom_transition`, `fig_matched_baby_boom_cohorts`,
  `fig_matched_secular_decline_transition`, and
  `fig_matched_secular_decline_cohorts`, each as `.eps`, `.pdf`, and `.png`.
  The LaTeX paper now uses these figures for Figures `7` through `10`; the
  compile-check PDF was generated at
  `D:\AI_storage\spillover\nimby_latex_check\nimby_latex_check.pdf`. The figure
  builder now selects the latest available outer iteration when an RE output
  directory contains multiple saved iterations. The first
  pass of the baby-boom fixed-point refinement did not beat the existing
  `0.0261` max path gap. The longer-tail refinement has deteriorated by
  iteration `3`, so it is not the current candidate. The other refinement jobs
  are still running on Hamilton and should be checked again before declaring
  the path final.
- Current 2026-04-26 active override: the live priority is now the annual
  political-smoothing / full price-path RE lane under
  `original_annual_political_re/`. The earlier annual political-smoothing
  runs without future price-path Bellman expectations are now controls only.
  The active full-RE object solves household choices backward on a guessed
  future house-price path, simulates distributions forward, maps political
  pressure into a generated house-price path, and relaxes that path to a fixed
  point. The no-demographic fixed-age test passes, secular decline now passes
  the T4 full-RE gate, and the remaining blocker is the temporary baby-boom
  path: its vote residual is small but its price-path fixed-point gap is still
  about 4.5 percent on the short T4 checks. Two Hamilton jobs are live:
  `16894030` bumps the T4 passers to T40, while `16894032` gives the baby boom
  a long terminal tail so agents can see the boom end before the terminal
  anchor bites. Interim read after roughly 1.5 hours: fixed-age T40 is already
  usable by outer iteration 4 (`max_abs_path_gap ~= 0.0054`), secular-decline
  T40 is improving but still only a survivor by iteration 4
  (`max_abs_path_gap ~= 0.0433`), and the baby-boom long-tail test is the key
  good news: it reaches usable by iteration 4, with the path gap down to about
  `0.0197` from the earlier short-tail T4 gap around `0.045`.
- Overall state: published paper; now maintained as an upstream base for project 03, with the
  transition-path RE extension now through a completed candidate-selection follow-up and a
  completed validation pack, plus a completed focus-objective follow-up. The best challenger is
  still `aggressive_p2_b8_hybrid_relaxed`, which lowers residual norm to about `0.128074` and
  keeps nontrivial updates alive through iteration `4`, but its max gap worsens to about
  `0.166384` relative to the config-`11` control (`0.165894`). The focus-objective family did not
  improve that worst-gap benchmark: the best pure-focus rows only tied the control max gap and
  stalled by iteration `2`, while the `hybrid_gap_guard` row simply reproduced the old relaxed
  hybrid challenger. The plateau therefore still remains. The bounded lambda continuation workflow
  is now also complete, and it suggests a smooth qualitative path back to the full-shock case
  rather than a dramatic regime break: residual norm falls monotonically from about `0.1898` at
  `lambda = 0` to about `0.1282` at `lambda = 1`, while the hardest period shifts from `8` at low
  lambda back to the familiar period-`3` bottleneck near the full shock. The benchmark-based
  coalition run is also complete and shows that coalition weighting moves the political steady-state
  price upward relative to the equal-weight benchmark. The project decision is therefore to treat
  the RE extension as a qualitative exercise with a clear computational-hardness explanation, not
  as an open-ended precision-calibration project. A new separate diagnostic branch now also tests a
  direct fertility-style whole-path relaxation transplant inside the NIMBY RE solver. Current read:
  it does not fix the problem. The direct transplant either wanders into implausible price regions
  or saturates at imposed bounds with very large residuals, which strengthens the interpretation
  that the hard part is the NIMBY fixed-point map itself, not only the old local candidate-search
  rule. A new bounded-horizon continuation check sharpens that point further: `k = 1` solves
  trivially, but the instability appears already at `k = 2`, where the second-period price hits the
  upper bound while the implied second-period price is still about `164.4`. A new dedicated `k = 2`
  bridge workflow now also says that simplifying only the terminal steady-state tail is not enough:
  the best fixed-tail case lowers the implied second-period price only to about `163.0`, so the
  bottleneck is not just the terminal continuation object. A new within-path policy bridge now
  provides the first genuinely useful simplification: replacing the full backward-looking policy map
  with steady-state policy rules lowers the `k = 2` max gap to about `0.0065`, keeps a short ladder
  numerically well behaved through `k = 3`, and then breaks again by `k = 4` if the bridge is
  allowed to react to the current price each period. A fixed-price policy bridge at `2.0` goes
  further and stays numerically well behaved through the full 9-period horizon. New anchored-policy
  follow-ups now sharpen that result: a floor-only clip on the by-period policy-reference path does
  not recover the fixed-price branch, and neither do narrow bands around `2.0`. The current best
  interpretation is therefore stronger than a generic clipped-current-price rule: the simplified RE
  object is closer to a nearly frozen benchmark-price policy map. A new reduced-form-first branch
  now mirrors the fertility sequence more closely: fit a smooth aggregate price operator on the
  stable fixed-price benchmark, then solve bounded one-step and `k`-step RE on that smoother
  object. That ladder is numerically tame through the full forward horizon, which sharpens the
  interpretation that the real hardness lives in the structural household-policy feedback block
  rather than in the demographic transition by itself. A new policy-bridge blend frontier now
  sharpens the climb back upward. On the full 9-period horizon, the refined blend sweep is stable
  through `alpha = 0.015` and unstable by `alpha = 0.02`. But on the matched-budget `k`-ladder,
  the pure by-period bridge survives through `k = 3`, `alpha = 0.05` survives through `k = 4`, and
  `alpha = 0.02` survives through at least `k = 5`. So the instability depends on horizon length
  as well as on the amount of current-price feedback. A new resumable `alpha`-by-`k` frontier
  runner now carries that continuation cleanly through `k = 5` on the coarse grid
  `{0, 0.01, 0.015, 0.02, 0.03, 0.05, 0.10, 0.20, 0.50, 1.00}`:
  `alpha = 1.00` remains stable through `k = 3`, then the largest stable tested `alpha` drops to
  `0.05` at `k = 4` and stays there at `k = 5`. But new same-alpha continuation runs show that
  coarse descending frontier is too pessimistic as a quantitative boundary: `alpha = 0.13` stays
  stable through every `k <= 6`, while `alpha = 0.14` already breaks at `k = 4` even though it
  returns to the stable region at `k = 5` and `k = 6`. New warm-start diagnostics overturn the
  old `0.13995/0.14000` pinch-point reading: that cliff was a one-pass solver artifact. The
  frontier runner now retries one failed case from its own endpoint and prefers the last stable
  `k - 1` frontier path when it steps down in `alpha`. Under that integrated retry-aware reading,
  `alpha = 0.15`, `0.175`, `0.1875`, `0.190625`, `0.1908203125`, `0.190869140625`,
  `0.1908935546875`, and `0.190899658203125` are stable at `k = 4`, while `alpha =
  0.19090576171875`, `0.19091796875`, `0.191015625`, `0.19140625`, `0.1921875`, `0.19375`, and
  `0.20` are unstable, so the practical local `k = 4` edge now lies between `0.190899658203125`
  and `0.19090576171875` under the current stability filter. A new edge-robustness packet now
  says that this remaining knife-edge is not just the old `25 + 25` budget in disguise: at the
  stable-side point `0.190899658203125`, a longer `50 + 50` retry-aware budget reaches the same
  final path and max gap about `0.03190`, but now does so without needing the retry; at the
  unstable-side point `0.19090576171875`, the longer `50 + 50` budget still remains unstable after
  retry, with max gap about `0.26158`, failing even a looser `0.10` gap cutoff.
  A new `k = 5` retry-aware packet now shows that the next horizon is materially harsher even
  after the `k = 4` cliff is reclassified upward: `alpha = 0.18` and `0.185` are stable at `k = 5`,
  while `0.185625`, `0.18625`, `0.1875`, and `0.19` are unstable. So the current retry-aware
  `k = 5` edge lies between `0.185` and `0.185625`.
  The compiled sidecar has now gone further than the MATLAB live packet on the high-horizon branch.
  The local retry-aware `k = 4` and `k = 5` knife edges match, same-`k` compiled continuation lifts
  the `k = 6` bracket to `[0.18140625, 0.181953125]`, and the current compiled full-horizon
  bracket is stable at `0.18083671212196353` and unstable at `0.18083722352981568`. A bounded
  12-hour compiled away workflow now exists to keep refining that full-horizon bracket while
  retaining only compact probe artifacts and stopping cleanly under disk pressure. The live
  compiled away session has now already reached its target bracket width, with final width about
  `5.11e-07`. The sidecar now also matches MATLAB on the old `alpha = 0.14`, `k = 4`
  warm-start diagnostic through a compiled per-case case-sweep runner, and that same
  runner now also reproduces the old `alpha = 0.15` and `alpha = 0.20`, `k = 4`
  restart-check packets. So those older local warm-start / restart artifacts are no
  longer MATLAB-only either.
- Immediate user priority from the 2026-04-13 session: use the recent three-report rejection packet
  to reopen the RE extension as a resubmission-facing house-price expectations exercise. Treat the
  full political RE transition as background motivation and future work, not as the near-term
  blocking deliverable.
- Active user priority from the 2026-04-14 session: this project is now the
  top active work lane. Keep compute, workflow, and debugging effort focused
  here rather than diffusing into lower-priority projects.
- New solver-redesign branch from the 2026-04-19 session: the exhausted
  full-horizon targeted line-search family is no longer the only live lane.
  A separate reduced-path Jacobian branch now exists under
  `original_5yr_political_re/`:
  `run_original_5yr_transition_reduced_path_jacobian.m`,
  `run_original_5yr_transition_reduced_path_jacobian.ps1`,
  `workflow_original_5yr_transition_reduced_path_jacobian.md`, and
  `submit_original_5yr_hamilton_reduced_path_packet.ps1`.
  This new branch parameterizes the `k = 14` log price path with a small
  basis, estimates a finite-difference Jacobian on the active political
  residuals, and applies a damped trust-region update. The first Hamilton
  packet is now live under Slurm jobs `16835609` through `16835612`
  (`b3`, `b4`, `b4wide`, `b5` variants), all seeded from the stable full
  `k = 14` continuation path. The earlier Hamilton loader failure is also now
  fixed for this branch: the remote external root contains the real
  `Codes_ABB/TransitionMatrix.mat` file (`116,819,684` bytes) plus the
  matching steady-state file, rather than the tiny placeholder bundle that
  caused the old "No usable TransitionMatrix.mat found" errors.
- Current compute split from the 2026-04-19 session:
  - local machine keeps the old normalization branch alive for one more pass
    (`hist_k14_activeclusters_norm_i3`) because RAM is still acceptable
  - Hamilton now carries the genuinely different reduced-path/Jacobian branch
    in parallel
- Model-scope reset from the 2026-04-14 session: park the annual `2010-2018`
  transition extension as a side branch rather than the main paper target.
  The main target is now the original 5-year political model, centered on the
  household Bellman block in `code/steadystate/SolveSS_iter.m` and the dynamic
  median-voter condition built from `sign(V^{dp} - V)`. In other words, the
  priority is no longer "annual no-politics extension plus political wrapper";
  it is "full political RE Bellman on the original 5-year timing."
- New solver-stabilization lane from the 2026-04-15 session: the first
  whole-path outer line-search safeguard now exists in
  `extensions/re_no_politics/solve_transition_political_bellman_nimby.m`, and
  the first trimmed `k = 6` test (`hist_k6_linesearch_trim_i2`) confirmed the
  narrow failure mode: it prevented the bad second update, but only by
  rejecting every candidate and staying at the one-iteration path. The next
  live lane is therefore targeted outer updates rather than more whole-path
  steps. That targeted rule is now patched into the same Bellman wrapper under
  `fixed_step_targeted_linesearch`, the long `hist_k6_targeted_linesearch_i2`
  run proved too broad for a useful bridge diagnostic, so the active overnight
  packet has now been tightened to a compact targeted branch:
  `hist_k6_targeted_compact_i2` with scale `[0.1]`, `max_targeted_periods = 1`,
  and `target_block_half_width = 0`. A bounded supervisor/reporting packet now
  monitors that compact branch under
  `original_5yr_political_re/truth/original_5yr_transition_solver_stabilization_live/`.
  The solver packet is no longer a short hand-coded fallback chain. It is now
  a bounded candidate search on `k = 6`: compact fixed-step, compact secant,
  compact block update, compact small-weight retry, then wider two-period and
  block variants if needed, with automatic carry-forward to `k = 14` only if a
  `k = 6` branch actually improves on the smoke benchmark.
- New original-timing workflow lane from the 2026-04-14 session:
  `original_5yr_political_re/` now contains a runged MATLAB workflow for the
  original 5-year political object. The live workflow starts with a coarse
  steady-state vote sweep, then branches automatically if no bracket is found:
  it expands toward lower or higher prices depending on the sign pattern,
  then falls back to a broad full-domain sweep, then to a small `rb`
  sensitivity family before giving up. If a bracket is found along the way, it
  now keeps narrowing automatically through `refined`, `dense`, `micro`, and
  `ultra` local brackets until the vote residual is small or the bracket is
  already tight, then writes a machine-readable `c_port_handoff.json` for the
  compiled C lane. The current manual refinement lane has already tightened the
  original 5-year steady-state sign change from the broad lower-price branch to
  a local bracket around `0.3401359375 -> 0.3401361111`. That very narrow local
  search also revealed that the vote function is step-like near the root rather
  than smoothly varying, so this looks like a discrete policy-switch boundary
  rather than a classical smooth scalar zero.
- Original steady-state parity clarification from the 2026-04-14 session:
  the current compiled steady-state political prototype is still exporting the
  `re_no_politics` object, not the original 5-year political steady state.
  Concretely,
  `extensions/re_no_politics/compiled_sidecar/matlab/export_steady_state_input_pack.m`
  calls `solve_ss_no_politics(...)`, while the trusted original-model MATLAB
  sweep under `original_5yr_political_re/` calls
  `code/steadystate/SolveSS_iter.m`. So the observed C-vs-MATLAB mismatch near
  the pinned low-price root is currently a wrong-object mismatch as well as a
  possible code-parity issue. The next compiled step is therefore to export and
  validate the original `SolveSS_iter.m` steady-state political object directly.
- Original steady-state compiled parity is now closed on the correct object:
  the steady-state exporter now supports
  `steady_state_mode = original_solve_ss_iter`, writes the original MATLAB
  truth payloads, and the no-OpenMP compiled political CLI now matches the
  original MATLAB political summary on both the pinned low-price pack
  (`p ~= 0.340136`) and the old benchmark pack (`p = 2.0`).
- Original 5-year Bellman refactor is now live and parity-tested:
  `code/steadystate/solve_original_5yr_bellman_core.m` now holds the reusable
  backward household solve, and
  `code/steadystate/solve_original_5yr_political_steady_state.m` now wraps that
  Bellman core with the original age-distribution / voting aggregation layer.
  At both the benchmark price (`p = 2.0`) and the pinned low-price steady-state
  root region (`p ~= 0.340136059`), the refactored solver matches
  `SolveSS_iter.m` exactly on `distance`, `totalvote`, `debtstock`, and
  `dens4`; the only residual difference is a zero-density `pref4` sign mismatch
  on some numerically negligible states. The original 5-year MATLAB sweep entry
  point and the original-mode sidecar exporter now both call this refactored
  solver rather than calling `SolveSS_iter.m` directly.
- The first bounded dynamic original-timing outer loop now also exists:
  `original_5yr_political_re/build_original_5yr_demographic_path_from_age_state_csv.m`
  subsamples the annual age-state CSV onto 5-year checkpoints
  (`2010 -> 2015` with the current data), and
  `original_5yr_political_re/run_original_5yr_transition_political_bellman_bounded.m`
  now reuses the shared transition Bellman wrapper with
  `steady_state_reference_mode = original_5yr_political`.
  Smoke read:
  `k = 1` nests the steady-state benchmark with zero housing gap and vote
  about `0.02525`,
  while the first nontrivial `k = 2` one-iteration smoke produces vote path
  about `[0.02525, 0.00983]`, final price path about
  `[0.340179, 0.340153]`, and max housing gap about `0.01172`.
- The historical `1950`-start demographic source is now wired for that same
  original 5-year lane:
  `original_5yr_political_re/build_original_5yr_demographic_path_from_historical_age_shares.m`
  now reads `US Age Share Fine Grained.xlsx`, sheet `Share`, aggregates the
  adult-share columns into the model's 14 age bins, and builds the 5-year
  path `1950, 1955, ..., 2015`.
- The bounded historical original 5-year workflow now also exists and is live:
  `original_5yr_political_re/workflow_original_5yr_transition_political_re.md`
  documents the ladder,
  `run_original_5yr_transition_political_re_workflow.ps1` runs the bounded
  stage tree,
  and the local supervisor / reporter pair now monitor
  `truth/original_5yr_transition_political_live/`.
  Historical smoke read so far:
  `k = 1` passes at the `1950` benchmark with `max_abs_vote ~= 0.02525` and
  zero housing gap, and the live supervised run has already completed that
  rung and moved into the historical `k = 2` baseline stage.
  Current implementation split remains:
  the dynamic Bellman lane is MATLAB,
  while the compiled C lane is validated on the original steady-state
  political object but not yet on the dynamic outer loop.
- The bounded historical ladder has now completed cleanly through `k = 4`, and
  sparse direct horizon probes have now also completed at `k = 5`, `k = 8`,
  and the full historical `k = 14` smoke horizon. The main read is that the
  full `1950 -> 2015` path is numerically climbable under a one-iteration
  smoke: `k = 14` stays bounded with `max_abs_gap ~= 0.00931`, but the
  political residual remains nonzero and oscillates across periods, with
  `max_abs_vote ~= 0.03435`.
- Because local RAM became tight during the mixed refinement packet, the
  heaviest full-horizon refinement jobs have now been offloaded to Hamilton.
  A fresh cluster bundle was copied to
  `/home/hfnt93/codex_runs/original_5yr_hist_20260415_130649/02_nimbyism_and_housing_supply`,
  and the three main `k = 14` follow-up jobs
  (`ham_k14_baseline_i2`, `ham_k14_baseline_i3`, `ham_k14_secant_i2`)
  were submitted under Slurm job IDs
  `16799608`, `16799609`, and `16799610`.
  The duplicate local `k = 14` jobs were then stopped to reduce machine
  pressure, leaving the shorter local bridge jobs as the main remaining
  local MATLAB load.
- Added the first compiled dynamic smoke for the original 5-year transition
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
- New bounded compiled overnight workflow from the 2026-04-14 session:
  `original_5yr_political_re/run_compiled_original_steady_state_overnight_workflow.ps1`
  now drives the original-model compiled political sweep lane without a watcher.
  It reuses the validated original steady-state pack, narrows the vote bracket
  stage by stage, and writes live status under
  `original_5yr_political_re/truth/compiled_original_steady_state_overnight_live/`.
  The current live run starts from the tight MATLAB bracket
  `0.3401359375 -> 0.3401361111` with `21` grid points per stage, a
  `1e-8` bracket-width stop rule, and a `10`-stage / `10`-hour cap.
- Current technical lane from the 2026-04-14 session: keep pushing the full political Bellman
  infrastructure, but do it through the compiled inner Bellman block rather than only through
  MATLAB wrappers. The compiled `transition_pass` sidecar now reproduces the political transition
  diagnostics too: on `transition_pass_t4_political_diag` and `transition_pass_t9_political_diag`,
  the compiled sidecar matches MATLAB on `sign(V^{dp} - V)`-based vote paths, coalition-weighted
  vote paths, and the forward density payload up to floating-point noise. The remaining gap is now
  the compiled outer political fixed-point loop, not the compiled inner Bellman/political pass.
  A first compiled outer political wrapper now exists in the compiled sidecar and is wired into a
  non-blocking overseer. It runs the bounded `T = 4` fixed-step smoke packet and the `T = 9`
  diagonal-secant smoke packet automatically, but exact MATLAB parity is still not closed yet.
  In parallel, a new bounded MATLAB horizon sweep is now live for the same
  political Bellman lane:
  `extensions/re_no_politics/run_transition_political_bellman_parallel_k_sweep.ps1`
  can launch independent `k` jobs side by side with throttling, and the live
  run `truth/political_bellman_parallel_k_live/` has now completed on
  `k = 1..9` with `2` political iterations per job. That horizon map is
  already useful:
  `k = 1` is trivial, `k = 2` has a real gap around `0.08868`, and from
  `k = 3` onward the housing gap stays near `0.16737` while the political
  residual remains near a corner at about `0.9708 -> 0.9721`.
  We also now have the first direct one-iteration MATLAB-vs-C++ read on the
  outer political wrapper at `T = 4`:
  using the same no-politics prefix path, the anchor path matches exactly,
  but the compiled wrapper's vote path differs immediately.
  Current manual comparison:
  vote-path max abs diff about `0.5691`,
  final-price-path max abs diff about `0.00567`,
  anchor-path max abs diff `0`.
  So the remaining compiled mismatch is now localized much more sharply:
  it appears in the first-step political residual object, not only in later
  outer iterations.
- Updated parallel-workflow decision from the 2026-04-14 session:
  split the work into three lanes rather than mixing solver and model changes:
  (i) MATLAB as the current-model political Bellman reference,
  (ii) compiled C++ as the outer-loop parity lane,
  and (iii) a separate literature-backed construction-lag lane.
  Hamilton access has now been verified from this machine via the `hamilton8`
  SSH alias, so broader MATLAB sweeps can move there once the local workflow is
  debugged.
- New construction-adjustment diagnostic branch from the 2026-04-14 session:
  `solve_transition_re_no_politics.m` now supports an explicit separate
  reduced-form housing-adjustment mode,
  `housing_adjustment_mode = 'construction_lag_price_partial_adjustment'`,
  with weight parameter `housing_adjustment_weight` and a dedicated sweep
  runner
  `extensions/re_no_politics/run_transition_re_construction_adjustment_sweep.m`.
  This is intentionally not the baseline model. It is a separate diagnostic
  branch motivated by the local supply-constraint literature, with calibration
  still open. A `k = 1` smoke check now passes and leaves the trivial one-period
  case unchanged, as it should.
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
- Reframing the extension workspace around the actual target experiment: demographic transition
  forecasts with RE house prices and no coalition voting.
- Bounded full-political Bellman continuation now has two live engineering
  lanes:
  the compiled overseer for the C++ outer wrapper and a throttled parallel
  MATLAB `k` sweep over `1..9` horizons for the original bounded political
  wrapper.
- The original 5-year steady-state MATLAB lane is now also running through a
  split Bellman architecture instead of the monolithic
  `code/steadystate/SolveSS_iter.m` entrypoint:
  `run_original_5yr_steady_state_vote_sweep.m` and the original-mode branch of
  `extensions/re_no_politics/compiled_sidecar/matlab/export_steady_state_input_pack.m`
  now both use `solve_original_5yr_political_steady_state.m`.
- A first original-timing dynamic runner now sits beside that steady-state
  lane:
  `run_original_5yr_transition_political_bellman_bounded.m`
  plus PowerShell launcher
  `run_original_5yr_transition_political_bellman_bounded.ps1`.
  It now supports both the temporary subsampled path and the proper
  `historical_1950` source.
  Current priority is the historical 5-year ladder built from
  `US Age Share Fine Grained.xlsx`, with the bounded supervised workflow under
  `truth/original_5yr_transition_political_live/` climbing from
  `k = 1` toward `k = 2`, `k = 3`, and `k = 4` only if each rung stays
  numerically well behaved.
- Added a fertility-style shared Bellman refactor for the no-politics RE side:
  `solve_household_path_nimby.m` now owns the household value/policy solve,
  `build_stationary_cross_section_nimby.m` builds the steady-state cross section from that common
  object, and both `solve_ss_no_politics.m` and `solve_transition_re_no_politics.m` now call that
  shared layer instead of carrying separate household-solve code paths.
- Sequential-block RE search now evaluates the regularized full-path candidate and uses the
  updater's log-step inside local block moves; a short-horizon smoke test accepted a real block
  update instead of stalling on `current_path`.
- Full 2010-2018 one-step wrapper rerun now also accepts a nontrivial update
  (`sequential_block_p2_1_3_0.01`) and rewrites `transition_re_no_politics_results.mat`.
- Full `max_iter = 3` path test compounds the accepted local updates a little, but only nudges the
  max gap from about `0.1673` to about `0.1663`, so the remaining bottleneck is candidate search /
  scoring rather than transition-path plumbing.
- The resumed tuning sweep is now complete. Best current row is config `11`
  (`damping = 0.15`, `smoothing_weight = 8`, `targeted_correction_weight = 0.20`,
  `line_search_scales = [0.1 0.05 0.02 0.01]`) with residual norm about `0.128123` and max gap
  about `0.165894`.
- Long-run follow-up on the top 3 configs (`max_iter = 5` and `10`) shows the solver still ends on
  `current_path` by the final iterations. The local updates help early, but they do not keep
  compounding without a better search rule.
- The targeted block-search follow-up around config `11` is now complete. It did not materially
  beat the baseline ranking, but case `aggressive_p2_b8` did keep nontrivial updates alive through
  iteration `4`, which is useful evidence about where the plateau starts.
- The candidate-selection follow-up is now complete. Best row is
  `aggressive_p2_b8_hybrid_relaxed`:
  - `candidate_selection_mode = hybrid_focus`
  - `greedy_block_accept = false`
  - `candidate_residual_slack = 0.0002`
  - `focus_residual_slack = 0.0005`
  - residual norm about `0.128074`
  - max gap about `0.166384`
  - nontrivial updates through iteration `4`
- The validation pack is now complete. It confirms the same ranking against the control:
  - `best_variant_validation` (source: `aggressive_p2_b8_hybrid_relaxed`) reproduces the lower
    residual norm and persistence
  - `baseline_control_validation` retains the lower max gap
  - neither case pushes nontrivial updates beyond iteration `4`
- Pass-level candidate-selection diagnostics and a Markdown report pipeline are now in place, and
  the away workflow completed successfully.
- The objective-tradeoff memo is now written at
  `extensions/re_no_politics/transition_re_objective_tradeoff_report.md`. Main conclusion:
  the challenger wins only through the global residual rule, not through focus-region improvement.
- The bounded focus-objective workflow is now complete:
  `extensions/re_no_politics/run_transition_re_focus_objective_workflow.ps1`
  finished on 2026-03-21 and refreshed the summary report.
- Focus-objective result:
  - best row: `config11_focus_relaxed`
  - residual norm about `0.128661`
  - max gap about `0.165894` (tie with the control, not an improvement)
  - nontrivial updates only through iteration `2`
- Added a separate fertility-style RE transplant branch:
  - solver hook in `extensions/re_no_politics/solve_transition_re_no_politics.m`
  - runner `extensions/re_no_politics/run_demographic_forecast_re_no_politics_fertility_style.m`
  - note `extensions/re_no_politics/transition_re_fertility_style_note.md`
- Added a bounded-horizon continuation diagnostic for that transplant:
  - runner `extensions/re_no_politics/run_transition_re_no_politics_k_step_ladder.m`
  - outputs `extensions/re_no_politics/transition_re_no_politics_k_step_ladder_summary.csv`
    and `extensions/re_no_politics/transition_re_no_politics_k_step_ladder_results.mat`
- Current fertility-style transplant read:
  - log-space relaxation weight `0.10`
  - price band `[0.40, 5.00]`
  - warm start from `transition_re_no_politics_results.final_price_path`
  - after `25` iterations, final max gap is still about `694.6074`
  - final path is pinned to the imposed band rather than converged
- Current bounded-horizon ladder read:
  - `k = 1` solves immediately with zero gap
  - `k = 2` already fails cleanly:
    final price path `[2.0003, 5.0000]`
  - the implied second-period price at that same iterate is about `164.3896`
  - residual norm is about `3.4928`
  - max gap is about `159.3896`
- Added a dedicated `k = 2` bridge workflow:
  - workflow note `extensions/re_no_politics/workflow_re_k2_bridge.md`
  - runner `extensions/re_no_politics/run_transition_re_k2_bridge_followup.m`
  - wrapper `extensions/re_no_politics/run_transition_re_k2_bridge_followup.ps1`
  - workflow wrapper `extensions/re_no_politics/run_transition_re_k2_bridge_workflow.ps1`
  - report `extensions/re_no_politics/transition_re_k2_bridge_report.md`
- Current `k = 2` bridge read:
  - default tail case:
    implied second-period price about `164.3896`
  - fixed-tail cases:
    implied second-period price about `162.9505`
  - in all tested cases, final bounded second-period price still hits `5.0`
  - best bridge case still has max gap about `157.9505`
  - best bridge case still has second-period excess demand about `3.0334`
- Interpretation:
  - this is useful negative evidence
  - simply swapping the old candidate search for the fertility-style whole-path relaxation does not
    make the NIMBY RE object behave well
  - starting from `k = 1` and extending the horizon does not rescue the method either; the trouble
    begins as soon as one step-ahead expectations matter
  - simplifying only the terminal steady-state tail is not enough either
  - the first simplification that really helps is the within-path policy bridge, not the endpoint
    tail fix
- Added a within-path policy bridge workflow:
  - workflow note `extensions/re_no_politics/workflow_re_policy_bridge.md`
  - `k = 2` runner `extensions/re_no_politics/run_transition_re_k2_policy_bridge_followup.m`
  - short ladder runner `extensions/re_no_politics/run_transition_re_k_step_policy_bridge_ladder.m`
  - wrappers:
    `extensions/re_no_politics/run_transition_re_k2_policy_bridge_followup.ps1`
    and
    `extensions/re_no_politics/run_transition_re_k_step_policy_bridge_ladder.ps1`
  - report:
    `extensions/re_no_politics/transition_re_policy_bridge_report.md`
- Current policy bridge read:
  - dynamic benchmark with fixed tail:
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
    remains numerically well behaved through `k = 9`
  - full 9-period fixed-price ladder endpoint:
    max gap about `0.0016`
    price range about `[1.9085, 2.1682]`
- Added full-horizon anchored-policy follow-ups:
  - floor sweep:
    `extensions/re_no_politics/run_transition_re_policy_bridge_floor_sweep.m`
    `extensions/re_no_politics/transition_re_policy_bridge_floor_report.md`
  - band sweep:
    `extensions/re_no_politics/run_transition_re_policy_bridge_band_sweep.m`
    `extensions/re_no_politics/transition_re_policy_bridge_band_report.md`
- Current anchored-policy read:
  - refreshed fixed-price benchmark:
    max gap about `0.000116`
    price range about `[1.9081, 2.1682]`
  - unclipped by-period bridge:
    max gap about `223.3768`
  - floor-only clips do not recover the fixed-price branch:
    floor `2.00` still leaves max gap about `0.2103`
    floor `1.95` leaves max gap about `2.7894`
  - narrow bands do not recover it either:
    best tested band `[1.95, 2.05]` still leaves max gap about `0.1516`
    wider bands perform worse and can still hit the imposed upper price bound
  - coarse fixed-price sweep:
    only `2.00` is stable on the grid `{1.85, 1.90, 1.95, 2.00, 2.05, 2.10, 2.15}`
  - refined local fixed-price sweeps:
    stable on the tested interval roughly `[1.970, 2.002]`
    unstable already at `1.965` and `2.003`
- Added a reduced-form-first RE workflow:
  - `extensions/re_no_politics/build_reduced_form_price_operator_from_policy_bridge.m`
  - `extensions/re_no_politics/solve_reduced_form_price_path.m`
  - `extensions/re_no_politics/run_transition_re_reduced_form_one_step.m`
  - `extensions/re_no_politics/run_transition_re_reduced_form_k_step_ladder.m`
  - `extensions/re_no_politics/run_transition_re_reduced_form_workflow.ps1`
  - `extensions/re_no_politics/workflow_re_reduced_form.md`
  - `extensions/re_no_politics/transition_re_reduced_form_report.md`
- Current reduced-form-first read:
  - operator source:
    stable fixed-price policy-bridge benchmark at `2.0`
  - fitted next-price coefficient:
    about `0.4744`
  - bounded-fit RMSE:
    about `0.0325`
  - one-step reduced-form RE:
    solved `2011` price about `2.0297`
  - finite-horizon reduced-form ladder:
    stable through the full forward horizon `k = 8`
    for all tested RE weights `{0.25, 0.50, 0.75, 1.00, 1.25}`
  - full-horizon (`k = 8`) endpoints:
    solved `2011` price ranges roughly `2.0329 -> 2.0557`
    solved `2018` price stays near `2.0049`
- Interpretation update:
  - the main explosive object in the original transplant is the full forward-looking within-path
    policy feedback
- The NIMBY compiled sidecar now reproduces not only the runtime core
  (steady state, transition pass, bounded outer RE, dynamic reference modes,
  and fertility-style outer loop), but also the workflow-used solver payloads:
  nested `selection_diagnostics` and optional `density_by_period_age` now
  validate against MATLAB on bounded packs. The remaining MATLAB role in that
  branch is now mainly exporter and report harness code.
  - new follow-up:
    the sidecar now also has a compiled frontier runner for the blended
    policy-bridge branch, driven from one exported input-only base pack plus
    an explicit anchor path
  - current validation read on that runner:
    the retry-aware `alpha = 0.20` ladder matches the current MATLAB live
    frontier packet through the completed `k = 1..3` rows when the base pack
    is exported with the correct fixed-price anchor path
  - that compiled frontier runner now also resumes from its own live files,
    and a seeded resume smoke test reproduced the full `k = 1..4` sidecar
    frontier summary exactly after restarting from saved `k = 1..2` outputs
  - compiled continuation read on the same retry-aware `alpha = 0.20` branch:
    stable through `k = 3`, then `ok_retry_failed` from `k = 4` onward
    (`k = 4` max gap about `0.02814` but with the lower bound hit,
    `k = 5` and `k = 6` max gap about `65.41739`)
  - remaining gap:
    broader frontier-runner parity at longer horizons is still open because
    the MATLAB `k = 4` retry-aware reference run did not finish within the
    session timeout here
  - workflow update:
    the local retry-aware edge wrapper is now also compiled C++, with the
    same two-attempt logic and an optional per-attempt max-iteration override
    for the `25 + 25` versus `50 + 50` robustness checks
  - compiled retry-aware validation read:
    the stable-side `k = 4` pack still returns `ok_after_retry` at the
    default budget and `ok` under `50 + 50`, while the unstable-side pack
    remains `ok_retry_failed` under both budgets
  - the policy bridge is therefore the canonical simplified RE branch
  - more precisely:
    a policy bridge that reacts to current prices postpones the instability,
    while a fixed-price policy bridge eliminates it over the full horizon on the current path
  - the anchored-policy follow-up strengthens that interpretation:
    the fixed-price branch is not reproduced by a low-price floor or by a narrow benchmark band
  - the fixed-price sweeps refine it further:
    the stable branch is not a broad benchmark neighborhood, but a narrow one centered on the
    calibration price with a much sharper upper edge than lower edge
  - the best current reduced-form interpretation is therefore a narrow benchmark-price neighborhood
    rather than a generic clipped-current-price rule
  - the new reduced-form-first branch sharpens the workflow lesson:
    once the within-path household-policy feedback is replaced by a smooth aggregate operator,
    bounded RE is numerically tame through the full forward horizon
  - that means the demographic transition by itself is not the hard object
  - the hard object is the structural household-policy feedback map
- Added a policy-bridge blend frontier workflow:
  - `extensions/re_no_politics/run_transition_re_policy_bridge_blend_sweep.m`
  - `extensions/re_no_politics/run_transition_re_policy_bridge_blend_sweep.ps1`
  - `extensions/re_no_politics/run_transition_re_policy_bridge_blend_ladder.m`
  - `extensions/re_no_politics/run_transition_re_policy_bridge_blend_ladder.ps1`
  - `extensions/re_no_politics/workflow_re_policy_bridge_blend.md`
  - `extensions/re_no_politics/workflow_re_policy_bridge_blend_ladder.md`
  - `extensions/re_no_politics/transition_re_policy_bridge_blend_report.md`
- Current policy-bridge blend read:
  - refined full-horizon sweep:
    `alpha = 0.00`, `0.01`, and `0.015` are stable
    `alpha = 0.02` is the first unstable tested full-horizon case
    `alpha = 0.05` is materially worse again
  - matched-budget `k`-ladder:
    `alpha = 1.00` is stable through `k = 3` and fails at `k = 4`
    `alpha = 0.05` is stable through `k = 4`
    `alpha = 0.02` is stable through at least `k = 5` in the checkpointed ladder output
    `alpha = 0.00`, `0.01`, and `0.015` are stable through the full ladder `k = 9`
- Added a resumable `alpha`-by-`k` frontier workflow:
  - `extensions/re_no_politics/run_transition_re_policy_bridge_alpha_frontier.m`
  - `extensions/re_no_politics/run_transition_re_policy_bridge_alpha_frontier.ps1`
- Current coarse `alpha` frontier read on grid
  `{0.00, 0.01, 0.015, 0.02, 0.03, 0.05, 0.10, 0.20, 0.50, 1.00}`:
  - `k = 1`, `2`, `3`: max stable `alpha = 1.00`
  - `k = 4`: max stable `alpha = 0.05`
  - `k = 5`: resumed cleanly from the timed partial run and remains at `alpha = 0.05`
- Same-alpha continuation refinement:
  - local refined frontier on `{0.05, 0.06, 0.07, 0.08, 0.09, 0.10}` keeps
    `alpha = 0.10` stable through `k = 6`
  - single-alpha continuation at `alpha = 0.12` stays stable through `k = 6`
  - single-alpha continuation at `alpha = 0.13` stays stable through `k = 6`
  - single-alpha continuation at `alpha = 0.14` is unstable at `k = 4`, then stable again at
    `k = 5` and `k = 6`
  - dedicated warm-start diagnostics show that the old local `k = 4` pinch point was not
    structural:
    `alpha = 0.14` and `0.15` are stable after restart-aware checks
  - the frontier runner now automates one restart from the failed endpoint and uses the last stable
    `k - 1` frontier path before any failed same-`k` higher-alpha path
  - integrated retry-aware single-alpha continuation at `k = 4` now gives:
    `alpha = 0.15` stable
    `alpha = 0.175` stable
    `alpha = 0.1875` stable
    `alpha = 0.190625` stable
    `alpha = 0.1908203125` stable
    `alpha = 0.190869140625` stable
    `alpha = 0.1908935546875` stable
    `alpha = 0.190899658203125` stable
    `alpha = 0.19090576171875` unstable
    `alpha = 0.19091796875` unstable
    `alpha = 0.191015625` unstable
    `alpha = 0.19140625` unstable
    `alpha = 0.1921875` unstable
    `alpha = 0.19375` unstable
    `alpha = 0.20` unstable
  - current bounded-horizon read is therefore:
    `alpha = 0.13` is the largest tested value that stays stable for every `k <= 6`
    under the old raw one-pass ladder, `alpha = 0.14` already breaks at `k = 4`
    under the retry-aware `k = 4` reading, the local edge is between `0.190899658203125` and
    `0.19090576171875`
    under the retry-aware `k = 5` reading, the local edge is between `0.185` and `0.185625`
- Interpretation update:
  - the full-horizon statement is still sharp:
    the 9-period bridge is only stable for a narrow neighborhood of the fixed-price branch
  - but the ladder statement is softer:
    shorter horizons can absorb some current-price feedback before instability returns
  - so the structural hardness grows with both the amount of current-price feedback and the
    forward-looking horizon length
  - the resumable frontier runner is now the preferred long-compute object for this branch because
    the `k = 4` and `k = 5` searches are slow enough that partial runs are realistic
  - the old descending-alpha coarse frontier is not a clean boundary object by itself:
    lower-alpha tests can inherit bad warm starts from unstable higher-alpha same-`k` paths
  - for quantitative reading, the more reliable object is same-alpha continuation across `k`, not
    only the monotone descent from the previous frontier
  - the current practical continuation edge is therefore much tighter than the old coarse packet
    suggested:
    the monotone-through-`k <= 6` bracket is between `alpha = 0.13` and `0.14`, not between
    `0.05` and `0.10`
  - the packet is not nested in `k` under the current solver and stability filter:
    `alpha = 0.14` fails at `k = 4` but returns to the stable region at `k = 5` and `k = 6`
  - inside that horizon-by-horizon view, the raw one-pass `k = 4` boundary is best read as a
    conservative lower bound, not the structural edge
  - the current retry-aware `k = 4` boundary under the implemented stability filter is:
    stable at `0.190899658203125`, unstable at `0.19090576171875`
  - the new edge-robustness packet says this cutoff is mostly a basin change rather than a
    near-miss against the current `0.05` rule:
    the stable-side point would only fail under a materially tighter `0.03` cutoff, while the
    unstable-side point still fails even a looser `0.10` cutoff after `50 + 50` iterations
  - the new `k = 5` packet says the horizon-length story remains real even after the `k = 4`
    reclassification:
    the retry-aware edge falls back from roughly `0.19090` at `k = 4` to roughly `0.185` at `k = 5`
- The final `aggressive_p2_b8_hybrid_gap_guard` case did not rescue the focus-objective branch; it
  reproduced the earlier relaxed-hybrid tradeoff:
  - residual norm about `0.128074`
  - max gap about `0.166384`
  - nontrivial updates through iteration `4`
- The post-workflow watcher is now also complete:
  `extensions/re_no_politics/run_transition_re_focus_post_workflow.ps1`
  It correctly skipped the extra validation stage because no completed focus-objective case beat
  `config11_global_control` on max gap by the `1e-6` threshold.
- Added extension-facing interpretation notes:
  - `extensions/re_no_politics/transition_re_intuition_note.md`
  - `extensions/re_no_politics/workflow_re_intuition.md`
  These record the current qualitative RE message, explain why the full transition-path RE problem
  is computationally hard, and cap further work at a lightweight sanity-check workflow.
- Added a bounded coarse continuation workflow for the RE extension:
  - `extensions/re_no_politics/scale_demographic_path_lambda.m`
  - `extensions/re_no_politics/run_transition_re_lambda_continuation.m`
  - `extensions/re_no_politics/run_transition_re_lambda_continuation.ps1`
  - `extensions/re_no_politics/run_transition_re_lambda_workflow.ps1`
  - `extensions/re_no_politics/workflow_re_lambda_continuation.md`
  This is the preferred one-more-pass workflow if we want intuition about how the RE transition
  changes as the demographic shock is gradually turned on.
- Added a benchmark-based coalition roadmap note:
  `extensions/re_no_politics/coalition_extension_from_benchmark.md`
  The coalition extension should be benchmarked against the published political model and should
  change only the political aggregation object first.
- Added the long-compute extension away workflow:
  - `extensions/re_no_politics/run_coalition_benchmark_sensitivity.m`
  - `extensions/re_no_politics/run_coalition_benchmark_sensitivity.ps1`
  - `extensions/re_no_politics/write_coalition_benchmark_report.ps1`
  - `extensions/re_no_politics/run_extension_away_workflow.ps1`
  - `extensions/re_no_politics/workflow_extension_away.md`
  This chains the live RE lambda continuation into a benchmark-based coalition sensitivity run and
  stops after the two main deliverables exist.
- The extension away workflow is now complete. Main new outputs:
  - `extensions/re_no_politics/transition_re_lambda_continuation_summary.csv`
  - `extensions/re_no_politics/transition_re_lambda_continuation_results.mat`
  - `extensions/re_no_politics/coalition_benchmark_summary.csv`
  - `extensions/re_no_politics/coalition_benchmark_results.mat`
  - `extensions/re_no_politics/coalition_benchmark_report.md`
- Lambda continuation result:
  - residual norm improves smoothly as `lambda` rises:
    `0.1898 -> 0.1650 -> 0.1460 -> 0.1336 -> 0.1282`
  - max gap moves:
    `0.2107 -> 0.1786 -> 0.1522 -> 0.1591 -> 0.1659`
  - the hardest period is `8` at low lambda and returns to `3` by `lambda = 0.75` and `1.0`
  - the full-shock `lambda = 1` row lands very close to the old control benchmark, which supports a
    smooth intuition rather than a hidden RE regime shift
- Benchmark-based coalition result:
  - equal-weight benchmark best price: about `1.8138`
  - combined default coalition best price: about `1.8276`
  - price shift versus benchmark: about `+0.0138`
  - one-margin cases show that owner and old-owner overweighting move price up on the same grid,
    while leverage-only and big-house-only mainly move the weighted-vote object without changing the
    grid-selected price at this resolution
- Added a standalone paper-style RE section packet:
  - `extensions/re_no_politics/re_extension_section/re_extension_section.tex`
  - `extensions/re_no_politics/re_extension_section/re_extension_section.pdf`
  - `extensions/re_no_politics/re_extension_section/figures/re_lambda_continuation.pdf`
  - `extensions/re_no_politics/re_extension_section/figures/re_solver_comparison.pdf`
  - `extensions/re_no_politics/re_extension_section/figures/re_vs_paper_benchmark.pdf`
  The section is written as a self-contained draft paper section, not just a memo, and compiles
  successfully to PDF.
- The standalone RE section now also includes a heuristic benchmark overlay based on the local
  published benchmark figure:
  - source data file:
    `extensions/re_no_politics/re_extension_section/digitized_paper_benchmark_2010_2018.csv`
  - new figure:
    `extensions/re_no_politics/re_extension_section/figures/re_vs_paper_benchmark.pdf`
  - interpretation over 2010--2018:
    the published benchmark rises by about `3.3` log points from its 2010 level, while the
    full-shock RE no-politics path moves by less than `0.1` log points
  This is useful for timing intuition, but it is explicitly not a clean apples-to-apples welfare
  comparison because the benchmark retains politics while the RE extension shuts politics down.
- Added a combined paper-style packet for the two extension ideas:
  - `extensions/re_no_politics/nimby_and_housing_extensions/nimby_and_housing_extensions.tex`
  - `extensions/re_no_politics/nimby_and_housing_extensions/nimby_and_housing_extensions.pdf`
  - `extensions/re_no_politics/nimby_and_housing_extensions/figures/coalition_extension.pdf`
  Title:
  `NIMBY and Housing Extensions: RE and Coalitions`
- Combined packet interpretation:
  - Extension 1 (RE) is a supporting robustness exercise and does not materially change the
    lifecycle NIMBY message
  - Extension 2 (coalitions) is better described as a reduced-form coalition-power extension rather
    than a full coalition game
  - the coalition result strengthens the benchmark mechanism more than the RE result:
    owner-only, old-owner-only, and combined coalition weighting each raise the selected benchmark
    equilibrium price by about `0.76%` on the current coarse grid
- Added paper-safe RE insertion drafts for the main paper:
  - `extensions/re_no_politics/rational_expectations_footnote.md`
  - `extensions/re_no_politics/rational_expectations_appendix_note.md`
  These recast the RE work as a short footnote plus an optional appendix note on computational
  scope, rather than a standalone extension section.
- Added a standalone review packet for the paper-safe RE insertion:
  - `extensions/re_no_politics/rational_expectations_note/rational_expectations_note.tex`
  - `extensions/re_no_politics/rational_expectations_note/rational_expectations_note.pdf`
  - `extensions/re_no_politics/rational_expectations_note/build_rational_expectations_note.ps1`
  This packet shows the exact footnote plus appendix-note version, separate from the older
  standalone RE extension section.
- Added a separate compiled solver workspace inside
  `extensions/re_no_politics/compiled_sidecar/`. The first compiled target is the reduced-form RE
  branch: MATLAB now exports reduced-form input packs plus truth outputs there, and the sidecar
  solves the same bounded fixed point in standalone C++.
- Added a bounded structural compiled target inside that same sidecar for the expensive
  `run_transition_pass` object in `solve_transition_re_no_politics.m`. The current `T = 4`
  diagnostic pack matches MATLAB exactly on policy indices and up to floating-point noise on
  value functions and aggregate paths.
- Added an OpenMP speed pass to that same sidecar:
  - bounded structural `transition_pass_t4_diag` runtime fell from about `25.5s` to about `5.1s`
  - the bounded standalone outer RE CLI on `transition_re_t4_fixed_terminal` now finishes in
    about `49.7s` instead of timing out past 20 minutes
- Closed the bounded fixed-terminal outer-RE parity gap in that same sidecar:
  - the compiled bounded outer RE now matches MATLAB on the exported `transition_re_t4_fixed_terminal`
    pack to floating-point noise
  - added `extensions/re_no_politics/compiled_sidecar/validate_transition_re.ps1` as the
    canonical bounded outer-RE validator
- Extended that same compiled bounded outer-RE sidecar through the exported candidate-selection
  modes:
  - `candidate_selection_mode` plus focus tolerances now export through
    `re_params_strings.csv` / `re_params_scalars.csv`
  - the compiled solver now mirrors MATLAB's `global`, `focus`, and `hybrid_focus` sequential
    selection logic on bounded fixed-terminal packs
  - exported packs `transition_re_t4_fixed_terminal`,
    `transition_re_t4_fixed_terminal_focus`, and
    `transition_re_t4_fixed_terminal_hybrid_focus` all validate against MATLAB to floating-point
    noise
- Extended that same sidecar through the first bounded policy-bridge continuation mode:
  - `transition_policy_mode = steady_state_fixed_price` now exports through the pass pack
    metadata plus static reference policy/value paths
  - bounded pack `transition_pass_t4_fixed_policy_2_0` matches MATLAB on the structural pass
  - bounded pack `transition_re_t4_fixed_terminal_fixed_policy_2_0` matches MATLAB on the outer
    RE loop
  - the fixed-policy bounded RE case is also much easier numerically:
    final max gap about `0.070564`, residual norm about `0.044122`, and compiled runtime under a
    second on the exported `T = 4` pack
- Added a standalone compiled no-politics steady-state reference solver inside the same sidecar:
  - bounded pack `steady_state_p2_rb0_03` matches MATLAB on policy indices, value functions,
    density, housing demand, and debt stock
  - this removes the remaining MATLAB-only dependency for dynamic reference objects in the active
    no-politics extension solver
- Added a compiled steady-state price-sweep driver on top of that same steady-state solver:
  - executable:
    `extensions/re_no_politics/compiled_sidecar/src/steady_state_sweep_cli.cpp`
  - wrapper:
    `extensions/re_no_politics/compiled_sidecar/run_steady_state_sweep_cli.ps1`
  - current smoke read on the anchor pack:
    best price remains `2.0`, with excess demand at floating-point noise
- Used that steady-state solver to extend the compiled sidecar through the dynamic continuation
  modes that previously required repeated MATLAB `load_ss_reference(...)` calls:
  - bounded pack `transition_re_t4_fixed_terminal_by_period_policy` matches MATLAB
  - bounded pack `transition_re_t4_path_end_terminal` matches MATLAB
  - bounded pack `transition_re_t4_blended_policy_band` matches MATLAB
- Added a hidden house-price compiled supervisor watcher for unattended local validation packets:
  - workflow:
    `extensions/re_no_politics/compiled_sidecar/house_price_compiled_supervisor_workflow.ps1`
  - watcher/launcher:
    `watch_house_price_compiled_supervisor.ps1`
    `start_house_price_compiled_supervisor.ps1`
    `stop_house_price_compiled_supervisor.ps1`
  - live logs/state:
    `extensions/re_no_politics/compiled_sidecar/truth/house_price_compiled_supervisor_live/`
  - current supervised packet now runs end to end without prompts through
    steady state, transition pass, and bounded transition RE on the canonical exported packs
- Added a first bounded transition political-path workflow:
  - runner:
    `extensions/re_no_politics/run_transition_re_political_path_diagnostic.m`
  - wrapper/workflow:
    `run_transition_re_political_path_diagnostic.ps1`
    `run_transition_re_political_path_workflow.ps1`
  - note/report:
    `workflow_re_political_path.md`
    `transition_re_political_path_report.md`
  - outputs:
    `transition_re_political_path_summary.csv`
    `transition_re_political_path_periods.csv`
    `transition_re_political_path_results.mat`
- Current bounded political-path read on the first `T = 4` packet:
  - one outer iteration with the current `full_backward` transition solve
  - residual norm about `0.11667`
  - max price gap about `0.16726`
  - hardest house-price period still `3`
  - max equal-weight political pressure about `0.9708` in period `1`
  - max coalition-weighted political pressure about `0.9487` in period `1`
  - political pressure stays strongly one-sided through all four periods
  - so the new political residual path does not peak in the same place as the house-price residual
    path
- Added a bounded joint price-and-vote update workflow:
  - runner:
    `extensions/re_no_politics/run_transition_re_joint_price_vote_experiment.m`
  - wrapper/workflow:
    `run_transition_re_joint_price_vote_experiment.ps1`
    `run_transition_re_joint_price_vote_workflow.ps1`
  - note/report:
    `workflow_re_joint_price_vote.md`
    `transition_re_joint_price_vote_report.md`
  - outputs:
    `transition_re_joint_price_vote_summary.csv`
    `transition_re_joint_price_vote_periods.csv`
    `transition_re_joint_price_vote_results.mat`
- Current bounded joint-update read on the first `T = 4` packet:
  - two outer joint iterations with vote weight `0.001`
  - coalition-weighted political pressure pushes prices downward in every period
  - the housing-clearing map still pushes prices upward in periods `2` to `4`
  - after two bounded joint iterations, the adjusted price path drifts down to roughly
    `[1.9963, 1.9976]` while implied market-clearing prices remain around `[1.9988, 2.1664]`
  - residual norm is nearly unchanged (`0.11667 -> 0.11668`)
  - the key qualitative result is therefore clear:
    the political force and the house-price-clearing force work against each other on the bounded
    path, which makes the full political RE problem genuinely harder than the house-price-only one
- Added a bounded vote-weight robustness sweep:
  - runner:
    `extensions/re_no_politics/run_transition_re_joint_price_vote_weight_sweep.m`
  - wrapper/workflow:
    `run_transition_re_joint_price_vote_weight_sweep.ps1`
    `run_transition_re_joint_price_vote_weight_sweep_workflow.ps1`
  - note/report:
    `workflow_re_joint_price_vote_weight_sweep.md`
    `transition_re_joint_price_vote_weight_sweep_report.md`
  - outputs:
    `transition_re_joint_price_vote_weight_sweep_summary.csv`
    `transition_re_joint_price_vote_weight_sweep_periods.csv`
    `transition_re_joint_price_vote_weight_sweep_results.mat`
- Current bounded vote-weight read:
  - tested weights `{0, 0.0005, 0.001, 0.002, 0.005}`
  - conflict share stays at `0.75` across the whole grid
  - larger weights simply scale the downward political price adjustment
  - so the sign conflict is robust on the bounded `T = 4` packet, not a quirk of the original
    `0.001` choice
- Added a bounded overnight workflow and hidden overseer for the political RE branch:
  - workflow:
    `extensions/re_no_politics/political_re_overnight_workflow.ps1`
  - watcher/launcher:
    `watch_political_re_overnight.ps1`
    `start_political_re_overnight.ps1`
    `stop_political_re_overnight.ps1`
  - note:
    `workflow_political_re_overnight.md`
  - live state:
    `extensions/re_no_politics/truth/political_re_overnight_live/`
  - scope:
    refresh the bounded political-path packet, the bounded joint price-vote packet, and the
    vote-weight sweep under one time budget, snapshot the artifacts, and stop cleanly after one
    milestone chain
- Added a bounded full-political Bellman wrapper:
  - solver:
    `extensions/re_no_politics/solve_transition_political_bellman_nimby.m`
  - runner:
    `extensions/re_no_politics/run_transition_political_bellman_bounded.m`
    `extensions/re_no_politics/run_transition_political_bellman_bounded.ps1`
  - support change:
    `solve_transition_re_no_politics.m` can now optionally return the exact current-path pass under
    `results.current_path_pass`, which is what the political wrapper needs
- Current bounded political-Bellman read:
  - horizon `T = 4`
  - target:
    equal-weight political vote, which is closer to the original benchmark object than the
    coalition-weighted diagnostic
  - update mode:
    political-only log update with weight `0.005`
  - after two iterations, the price path drifts from about `2.00` to roughly `[1.981, 1.981]`
  - max political vote stays near `0.971` in absolute value
  - so this is not a solved political transition equilibrium yet, but it is now a genuine
    political outer loop on top of the full transition Bellman block rather than only an
    after-the-fact diagnostic
- Added a fertility-style political Bellman `k`-ladder:
  - runner:
    `extensions/re_no_politics/run_transition_political_bellman_k_step_ladder.m`
    `extensions/re_no_politics/run_transition_political_bellman_k_step_ladder.ps1`
  - note:
    `extensions/re_no_politics/workflow_re_political_bellman_ladder.md`
  - first full run:
    `transition_political_bellman_joint_eqvote_ladder_ladder_summary.csv`
- Current political Bellman ladder read:
  - the full sample horizon is indeed `T = 9` because the demographic path runs from `2010` to
    `2018`
  - the joint housing-plus-politics ladder reached every `k = 1..9` with one political iteration
    per `k`
  - it did not crash and did not hit the imposed price bounds
  - max equal-weight political vote stays around `0.971 -> 0.972`
  - the housing-side max gap is `0` at `k = 1`, about `0.089` at `k = 2`, and then about `0.168`
    from `k = 3` onward
  - final price ranges are very tight around `1.9903` to `1.9912` on the longer horizons
  - so the full-political Bellman ladder is now operational through the whole sample, but it is
    still far from a solved joint fixed point because the political residual remains large
- Extended the compiled bounded outer RE loop through the alternative fertility-style relaxation
  branch:
  - bounded pack `transition_re_t4_fertility_style` matches MATLAB
  - final label `fertility_style_relaxation`
  - final max gap about `149.985`
  - final residual norm about `25.235`
- Extended the compiled sidecar through the first full-political Bellman inner object:
  - `compiled_sidecar/src/transition_pass_solver.cpp` now supports
    `compute_political_path`, a perturbed-price Bellman branch, and coalition/equal-weight vote
    aggregation on a fixed guessed price path
  - `compiled_sidecar/matlab/export_transition_pass_input_pack.m` now exports truth packs with the
    corresponding political settings and vote-path outputs
  - `compiled_sidecar/validate_transition_pass.ps1` now validates the political outputs too
  - bounded validation result:
    `transition_pass_t4_political_diag` matches MATLAB to floating-point noise on
    `equal_weight_vote_path`, `weighted_vote_path`, `weighted_vote_share_path`, the distance paths,
    owner-share paths, and `density_by_period_age`
  - full-horizon validation result:
    `transition_pass_t9_political_diag` also matches MATLAB to floating-point noise on the same
    political outputs
  - practical implication:
    the expensive inner political Bellman pass is no longer MATLAB-only; the next compiled target is
    the outer vote-zero path solver
- Added the smallest compileable steady-state political prototype in the compiled sidecar:
  - `compiled_sidecar/src/steady_state_solver.cpp` now exposes a political steady-state helper that
    solves the baseline 5-year steady state, resolves the perturbed-price branch at
    `a_price * price_multiplier`, builds `sign(V^{dp} - V)`, and computes the aggregate
    `totalvote` and `distance = totalvote^2`
  - `compiled_sidecar/src/steady_state_political_cli.cpp` provides a smoke-test CLI for a fixed
    trial price
  - `compiled_sidecar/CMakeLists.txt` wires the new target
  - smoke test on `truth/steady_state_p2_rb0_03` succeeds when the LLVM runtime DLLs are on PATH
  - baseline steady-state output still matches the existing MATLAB summary pack to machine precision
- 2026-05-10 no-RE lag robustness: Hamilton job `17078002` (`nore80bvl`) completed
  cleanly. All six four-year block-vote T80 lag comparators are usable:
  `p006_l1` vote `0.0102347`, move `0.00282475`; `p006_l2` vote `0.0100557`,
  move `0.00278235`; `p006_l4` vote `0.00959167`, move `0.00266465`;
  `p012_l1` vote `0.0120562`, move `0.00616904`; `p012_l2` vote `0.0115326`,
  move `0.00592947`; `p012_l4` vote `0.0106023`, move `0.00577416`.
  This supports the four-year no-RE robustness/comparator route; it is not an
  RE fixed-point promotion result.
- 2026-05-10 RE lag/long-block update: diagnostic long-block T80 seed job
  `17075892` (`bb80bvl`) timed out without a useful seed. Best visible
  20-year rows were still far above promotion (`bv80bvl20_d14` gap
  `0.00854918`; `bv80bvl20_d18` gap `0.00887295`), and 40-year rows had no
  summary before timeout. The four-year RE lag job `17078003` is still live;
  best visible row is `bv80bv4lag_l4_n006` outer `2`, gap `0.00239250`,
  which is better than the non-lag full-seed best visible row
  `bv80bv4fs_n006_d022` outer `19`, gap `0.00249383`, but still above the
  `0.001` promotion threshold.
- 2026-05-10 non-lag full-seed T80 rescue result: Hamilton job `17076871`
  (`bb80bv4fs`) exhausted its array without clearing promotion. Array member
  `5` timed out at 12 hours; the other members completed cleanly. Best durable
  non-lag full-seed row is `bv80bv4fs_n006_d022` outer `20`, max path gap
  `0.0023876553175479`, max vote residual `0.0150187250083962`, and max log
  price move `0.00381477059944836`. This route improves materially over the
  exact-source T80 promotions but remains above the `0.001` promotion
  threshold.
- 2026-05-10 RE lag live update: Hamilton job `17078003` (`bb80bv4lg`) remains
  the only live acceptable RE T80 route. Best visible row is
  `bv80bv4lag_l4_n006` outer `7`, max path gap `0.00188229537948787`, max
  vote residual `0.0155539073450329`, and max log price move
  `0.00455863279886198`; second-best is `bv80bv4lag_l4_n012` outer `9`, gap
  `0.00195122580671123`. Both are still above the `0.001` promotion threshold.
- 2026-05-10 12-hour failsafe workflow: started a bounded monitor at about
  `21:40 BST`, ending at `2026-05-11 09:40 BST`. Scope is deliberately narrow:
  monitor only live RE lag job `17078003` (`bb80bv4lg`) and do not submit new
  five-year, long-block, non-lag full-seed, or broad blind variants. Trigger
  actions: if any `bv80bv4lag*` row reaches max path gap `<= 0.001`, notify
  immediately and update this file; if `<= 0.0002`, mark it paper-safe at T80.
  If all lag arrays finish or the 12-hour window expires above `0.001`, record
  the four-year T80 promotion/lag rescue as failed and stop the heartbeat
  automation.
- 2026-05-11 lag-failsafe result: Hamilton job `17078003` (`bb80bv4lg`) is
  complete for all six array members and did not clear the `0.001` T80
  promotion threshold. Best lagged four-year RE T80 row is
  `bv80bv4lag_l4_n012` outer `17`, with max path gap
  `0.00183754003051641`, max vote residual `0.0183758214463522`, and max log
  price move `0.00492082839501052`. Next best is `bv80bv4lag_l4_n006` outer
  `7`, gap `0.00188229537948787`. This closes the bounded four-year T80
  promotion/lag rescue as failed. Preserve the accepted four-year T20 result
  (`bv4p_r25_d14` outer `14`, gap `0.000735817`) as promotion-clearing only;
  it is not a T80 paper result.
- 2026-05-11 first-wave T80 model-grid workflow: after the user chose a
  deliberate model-design exercise rather than more blind rescue, uploaded and
  submitted Hamilton job `17084463` (`bb80mg11`, array `1-12`) from
  `drafts_re/hamilton_jobs/`. The grid tests defensible branches in parallel:
  T80 full RE, four-year block voting, terminal fixed point, return-to-steady-
  state post-report demographics, ghost tails of `20`, `40`, and `80` years,
  pass-throughs `0.006` and `0.012`, and the existing lagged delivery/time-to-
  build proxy with lags `0`, `1`, `2`, and `4`. Expectation inertia/adaptive
  beliefs are intentionally excluded. Tracking files are
  `model_grid_0511.csv`, `model_grid_existing_comparators_0511.csv`,
  `workflow_model_grid_0511.md`, `run_t80_model_grid_0511.m`,
  `bb80modelgrid_re_0511.slurm`, and `rank_model_grid_0511.py`. Verdicts:
  `paper_safe` if max path gap `<= 0.0002`, `usable` if `<= 0.001`,
  `survivor` if `0.001 < gap <= 0.003`, and `dead` otherwise. Treat a clearing
  lag/time-to-build proxy row as robustness/model-extension evidence distinct
  from the failed non-lag baseline.
- 2026-05-11 perfect-foresight continuation probes: submitted Hamilton job
  `17087303` (`bb80pfc11`, array `1-6`) after the first-wave grid showed the
  strongest survivor family was pass-through `0.006`, 4-year delivery-lag
  proxy, 80-year hidden tail, and return-to-steady-state demographics. Files:
  `model_pf_continuation_0511.csv`, `workflow_pf_continuation_0511.md`,
  `run_pf_continuation_0511.m`, `bb80pfcont_0511.slurm`, and
  `rank_pf_continuation_0511.py`. Rows `1-3` test horizon continuation
  (`T20`, `T40`, `T60`) at target shock amplitude `0.25`; rows `4-6` test
  shock-amplitude continuation at `T80` with amplitudes `0.10`, `0.15`, and
  `0.20`. These are pure perfect-foresight numerical probes, not expectation-
  inertia variants and not final target rows unless a row clears the same
  convergence gates.

## Next 3 Tasks

1. Monitor and close out Hamilton job `17152180` (`bb80moll14`) with
   `python3 closeout_moll_direct_0514.py --annual-dir .`; treat completion as
   a direct-belief diagnostic result, not as full-RE success.
2. If Route B (`mollB_lsl_age_t40`) completes, inspect
   `belief_iterations.csv`, `belief_coefficients.csv`, and `belief_paths_all.csv`
   to decide whether the low-dimensional learning rule is stable enough to
   become the main Moll route, or whether Route C should become the robustness
   fallback.
3. Add empirical expectations discipline before any paper-facing claim:
   connect the chosen direct-belief rule to measured house-price expectations
   or clearly label it as an internally disciplined restricted-perceptions
   exercise. The prepared LM/Gauss-Newton full-RE fallback remains unsubmitted
   unless the user explicitly reopens the full-RE route.

## Blockers

- No formal code-review output document yet in the project.
- The large external MATLAB `.mat` inputs still live outside this git repo, so portability
  improvements reduce friction but do not make the project fully self-contained.
- The current implemented extension is a steady-state side benchmark, not yet the main transition-path RE experiment.

## Open Decisions

- Scope of maintenance pass: bug-fix-only vs broader refactor.
- Priority order for reviewing `SteadyState/` vs `Codes_ABB/` modules.

## References

- Project overview: `projects/02_nimbyism_and_housing_supply/README.md`
- Session log: `projects/02_nimbyism_and_housing_supply/memory.md`
- Upstream fix log: `projects/02_nimbyism_and_housing_supply/UPSTREAM_FIX_LOG.md`
- Referee report source file: `projects/02_nimbyism_and_housing_supply/referee/Economic Journal Referee Reports.docx`
- IER decision letter:
  `projects/02_nimbyism_and_housing_supply/IER MS31540-1 Decision letter.pdf`
- IER referee reports:
  `projects/02_nimbyism_and_housing_supply/IER MS31540-1 R1's report.pdf`
  `projects/02_nimbyism_and_housing_supply/IER MS31540-1 R2's report.pdf`
- Referee strategy note:
  `projects/02_nimbyism_and_housing_supply/referee/re_house_price_resubmission_strategy.md`
- Drafting note:
  `projects/02_nimbyism_and_housing_supply/referee/ier_house_price_steady_state_then_bellman_draft.md`

## Working Rule

- When asked "where are we?" or to update the to-do list, update this file first.
- Live manuscript prose must not refer to itself as "revised" or use revision-process
  language. Use direct paper language such as "In the transition exercise" or
  "Under deterministic rational expectations"; keep workflow caveats in notes/status,
  not in the paper.

## Session Update (2026-04-17)

- Local priority remains the live full-horizon `k = 14` solver-stabilization tree.
- Added Hamilton insurance ladder submission script:
  `original_5yr_political_re/submit_original_5yr_hamilton_horizon_insurance.ps1`
- After fixing the remote transition-matrix bundle, submitted a parallel Hamilton packet for
  `k = 7, 8, 9, 10, 11, 12, 13, 14` using the fast `union_only` rule.
- Active Hamilton insurance jobs:
  `16819486`, `16819487`, `16819488`, `16819489`, `16819490`, `16819491`, `16819492`, `16819493`
- Tracking file:
  `original_5yr_political_re/truth/hamilton_horizon_insurance_latest.json`

## Session Update (2026-05-12)

- Submitted a new 13-hour wide Hamilton search for the full T80 baby-boom
  rational-expectations transition: job `17141699` (`bb80wide12`, Slurm array
  `1-40`), submitted about `2026-05-12 21:29 BST`. Local/remote packet files
  are in `drafts_re/hamilton_jobs/`: `model_re_wide_0512.csv`,
  `workflow_re_wide_0512.md`, `run_re_wide_0512.m`, `bb80rewide_0512.slurm`,
  and `rank_re_wide_0512.py`.
- The packet is deliberately broad but bounded: T40/T60 bounded-expectations
  sources promoted to full T80 with shifted no-RE tails, best bridge/failsafe
  survivors continued and refocused, terminal/tail/focus/basis sweeps,
  delivery-lag diagnostics, lower pass-through/shock homotopy diagnostics, and
  no-RE/small-shock path seeds. Main paper candidates are the `T80`,
  pass-through `0.006`, shock `0.25` rows labelled
  `full_t80_bridge_candidate` or `projected_pf_candidate`.
- Monitor with automation `nimby-wide-t80-re-monitor`. Rank from the remote
  annual dir using:
  `python3 rank_re_wide_0512.py --annual-dir . --grid model_re_wide_0512.csv --out-dir truth/re_wide_0512`.
  Decision thresholds remain: `paper_safe <= 0.0002`, `usable <= 0.001`,
  `survivor <= 0.003`, otherwise dead/missing/failed. Do not submit another
  chained wave without an explicit checkpoint.
