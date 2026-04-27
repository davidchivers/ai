# Annual political transition paper workflow

This is the working sequence for turning the annual political transition into a paper
exercise. The current computational lane should be described as an annual transition with
current-price/random-walk house-price expectations and smoothed political pass-through.
It is not yet a full future-house-price-path rational-expectations Bellman problem.
Decisions should be made one at a time. Do not keep adding runs unless they answer one of
the gates below.

## Terminology lock

Use these labels consistently:

- `current-price expectations`: the existing annual lane. Households solve at the current
  house price, while the realized economy moves forward through smoothed political
  pass-through.
- `full demographic-price RE`: not yet implemented. Households know the future demographic
  path and forecast the implied future house-price path when choosing housing today.
- `perfect-foresight transition`: the deterministic version of full demographic-price RE.
  This is probably the cleanest phrase for the paper if the demographic shock is announced
  rather than stochastic.

The current Hamilton jobs are useful controls and diagnostics. They should not be sold as
the full RE transition.

## Gate 0: build the full demographic-price RE lane

Purpose: implement the object the paper ultimately wants if agents are forward-looking
about demographic pressure on future house prices.

Precise benchmark object:

- demographics are an exogenous known path,
- house prices are the aggregate path agents forecast,
- if demographics do not change, the expected price path should stay near the steady
  state,
- if demographics imply future price changes, those changes should be capitalized into
  current choices through the full expected price path.

Computational object:

1. Guess a full future house-price path, initially from the current-price benchmark.
2. Solve a time-indexed household problem backward over calendar years and ages. Current
   decisions use `P_t`; continuation and resale values use the future path `P_{t+1}`,
   `P_{t+2}`, and so on.
3. Simulate the age distribution forward under the demographic path.
4. Compute political pressure and the implied generated house-price path.
5. Update the guessed path with damping or homotopy until the guessed and generated paths
   agree.

Smoke ladder:

- `T = 4`, flat demographics, no shock: code correctness only.
- `T = 4`, baby boom and secular decline: check whether the RE price-path channel moves in
  the expected direction.
- `T = 4`, immigration projection paths: code correctness for the paper's low/medium/high
  immigration forecast exercise.
- `T = 20`: first meaningful horizon.
- `T = 80`: Hamilton only, after the short gates pass.

Promotion rule after the 2026-04-26 full-RE correction:

- do not jump every scenario straight to `T = 80`;
- if fixed-age and secular decline pass at `T = 40`, promote those passers to `T = 80`;
- for the temporary baby-boom case, first use a long tail so agents can see the boom end
  before the terminal anchor bites;
- if the long-tail baby-boom `T = 4` check stays usable, climb baby boom through `T = 20`
  or `T = 40` before `T = 80`;
- if the long-tail baby-boom check does not materially improve the path gap, stop adding
  horizon and switch to a path-level solver update, such as secant, Anderson, or a reduced
  path-root solve.
- the paper's forecast exercise is a third substantive lane, separate from baby boom and
  secular decline. Use the explicit projection scenarios
  `forecast_low`, `forecast_median`, and `forecast_high`, corresponding to the old
  low/medium/high immigration paths from `loop101_output_extended.mat`.
- after the current jobs finish, run `T4Proj` as the projection smoke; if it passes, climb
  projection paths to `T40Proj` and then `T80Proj`.

Acceptance criteria:

- generated and guessed price paths are close,
- no price-grid or policy-grid cap hits,
- political residual is no worse than the current-price benchmark,
- results can be compared directly against the current-price expectation lane.

Current implementation:

- local runner: `run_annual_political_full_re_price_path.m`,
- Hamilton submitter: `submit_annual_full_re_price_path_hamilton.ps1`,
- projection scenarios now wired in the runner:
  `forecast_low`, `forecast_median`, and `forecast_high`,
- projection runs can now set `ReferenceYear = 2020`, which should be used for the
  paper's 2020-2100 immigration forecast exercise,
- Hamilton projection stages now available:
  `T4Proj`, `T20Proj`, `T40Proj`, and `T80Proj`,
- the Hamilton submitter now defaults those projection stages to `ReferenceYear = 2020`;
  non-projection stages keep `ReferenceYear = NaN`,
- first Hamilton smoke submitted as job `16893956`,
- stage name: `annre_T4_20260426_1445`,
- tasks: `fixed_age_share`, `baby_boom`, and `secular_decline`, each with `T = 4`,
  `TailYears = 20`, `eta = 0.090`, and `OuterIter = 3`.

Unit-test logic:

- `fixed_age_share` is the no-demographic-change test. It should stay near the steady
  state. If this fails, do not promote to `T = 20`.
- `baby_boom` and `secular_decline` are short mechanism tests. They are not yet paper
  results.
- `forecast_low`, `forecast_median`, and `forecast_high` are the paper forecast tests.
  They should be treated as the direct update of the old low/medium/high immigration
  projection exercise, not as ad hoc shocks.

Hamilton naming rule:

- keep stage and task names short. Use labels like `reT4_04261535`, `t4_fix_e09`,
  `t4_bb_e09`, and `t4_dec_e09`.
- do not include full scenario names, long timestamps, or descriptive prose in Hamilton
  run/task directories. Long nested names caused avoidable Windows/SSH collection
  failures.

Current Hamilton poll automation:

- scheduled task: `NimbyAnnualFullREPoll`,
- cadence: every 15 minutes for up to 24 hours,
- poll script: `poll_annual_full_re_hamilton_once.ps1`,
- registration script: `register_annual_full_re_hamilton_poll_task.ps1`,
- local report: `truth/annual_full_re_hamilton_poll/latest_report.md`,
- local state: `truth/annual_full_re_hamilton_poll/latest_state.json`,
- current watched jobs: `16894032`, `16894205`, and `16894254`,
- current watched stages: `reT4BBTail_04261648`, `reT80A_04262004`, and
  `reT40D_04262131`,
- fetch rule: while jobs are active it fetches `summary_all.csv`; once the jobs are
  inactive it fetches all CSV outputs from the watched result folders,
- stop rule: when Hamilton has no active rows for those job IDs and at least seven
  expected summary files have been fetched, the poll script unregisters the scheduled
  task itself.

This replaces the sketchy recursive watcher path for the current run. It only polls and
fetches summaries; it does not submit the next stage automatically.

Aggressive T80 packet and T40 secular backup submitted on 2026-04-26:

- broad run: job `16894205`, stage `reT80A_04262004`, six tasks at `eta = 0.090`:
  `fixed_age_share`, `baby_boom`, `secular_decline`, `forecast_low`,
  `forecast_median`, and `forecast_high`;
- after user review, cancelled the low/high forecast array tasks (`16894205_3` and
  `16894205_5`) and kept only the median forecast stress-test task (`16894205_4`);
- cancelled mistaken secular-decline `T80` backup job `16894209` before it started;
- correct secular-decline backup: job `16894254`, stage `reT40D_04262131`, two tasks
  (`eta = 0.090` and `0.105`) with more outer iterations and smaller path relaxation at
  `T = 40`.

Interpretation:

- the broad run answers whether the full paper package can go straight to the 80-year
  horizon;
- the damping backup protects against the main known risk at the cheaper `T = 40` horizon
  before deciding whether secular decline deserves a full `T80` rerun.

Projection-path caveat:

- the `forecast_low`, `forecast_median`, and `forecast_high` rows inside `T80All` should
  be treated as an aggressive stress test, not the validated projection workflow;
- after the first stress-test rows, only the median forecast task is still running. Low
  and high should be attempted later, after the median projection path is solved or the
  right damping/terminal setup is clear;
- the paper projection exercise is conceptually a 2020-2100 forecast exercise using the
  old low/medium/high immigration paths;
- before relying on projection `T80` results, run `T4Proj` and then `T40Proj/T80Proj`
  as a separate ladder;
- the projection ladder should use a projection-specific terminal steady state, anchored
  to the terminal forecast age composition, just as secular decline uses a terminal
  fixed-point anchor rather than the old steady state.
- local projection validation now starts with the median path only. The guarded local
  ladder `run_local_median_projection_ladder.ps1` climbs `T = 4, 8, 12, 20` with
  `forecast_median`, `ReferenceYear = 2020`, and a terminal fixed-point anchor. If this
  ladder passes, patch the Hamilton projection submit path to pass `ReferenceYear = 2020`
  before treating a Hamilton median projection as paper-ready.

## Gate 1: fix the benchmark

Purpose: choose one defensible benchmark transition before building figures.

Current candidate class:

```text
rho = 0
tau = 0.020
gamma = 1
eta in {0.090, 0.105, 0.120}
```

Decision rule:

- prefer the smallest eta that gives a stable `T = 80` transition,
- do not choose a larger eta only because it mechanically lowers the residual,
- require no price-cap hit and smooth price, homeownership and housing-demand paths,
- require that death/terminal-age robustness does not overturn the ranking.

Current live dependency:

```text
Hamilton job 16893866: T80Death
```

Status: complete.

Read:

- `eta = 0.075` is a survivor under all terminal-age treatments,
- `eta = 0.090` is usable under baseline, terminal-half and terminal-drop treatments,
- `eta = 0.105` is also usable but uses more price movement for similar max residuals.

Provisional benchmark:

```text
eta = 0.090
```

Keep `eta = 0.105` as the fallback if the full baby-boom or secular-decline shock needs
more pass-through strength.

## Gate 2: prove smoothing is doing real work

Purpose: show the smoothed political rule is not cosmetic.

Required comparisons:

- benchmark smoothed transition,
- hard-sign `tau = 0` transition,
- near-hard small-tau map or transition,
- constant/no-feedback price path.
- supply-adjustment lags of 5 and 10 years, interpreted as permit/construction-to-price
  delays rather than delayed voter pressure.

Current evidence:

- saved-grid map: smooth `tau = 0.020` materially improves the political residual,
- hard-sign `tau = 0` mostly falls back toward the constant-price failure,
- one-period hard-sign dynamic smoke runs.
- 5-year and 10-year supply-adjustment lag checks have been submitted on Hamilton:
  `16893926` and `16893930`.

Next dynamic run if needed:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\Dave_\AI\.claude\worktrees\nimby_smoothed_permits\research_projects\02_nimbyism_and_housing_supply\original_annual_political_re\submit_annual_political_hamilton_thin_ladder.ps1 -Stage T80Hard -PeriodIter 4
```

## Gate 3: prove this is not random house prices

Purpose: show the political rule beats exogenous price noise.

Current evidence:

- saved-grid random-price comparison is complete,
- 200 random AR(1) paths per amplitude produced zero usable paths,
- median random-path residuals are far worse than the smoothed benchmark.

Paper version still needed:

- select a small number of representative random paths from the saved-grid distribution,
- run those paths through the full annual dynamic household/distribution code,
- plot benchmark residual against the random-price residual envelope.

## Gate 4: demographic shock exercises

Purpose: make the extension substantive rather than only numerical.

Required shock exercises:

- temporary baby boom,
- secular decline in entrants,
- possibly source-path historical demographic transition if useful for continuity with the published result.

Current evidence:

- local `T = 4` baby-boom smoke passed,
- local `T = 4` secular-decline smoke passed,
- full `T = 80` Hamilton stages are now submitted:
  `16893936` for baby boom and `16893937` for secular decline.

Submitted dynamic runs:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\Dave_\AI\.claude\worktrees\nimby_smoothed_permits\research_projects\02_nimbyism_and_housing_supply\original_annual_political_re\submit_annual_political_hamilton_thin_ladder.ps1 -Stage T80Boom -PeriodIter 4
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\Dave_\AI\.claude\worktrees\nimby_smoothed_permits\research_projects\02_nimbyism_and_housing_supply\original_annual_political_re\submit_annual_political_hamilton_thin_ladder.ps1 -Stage T80Decline -PeriodIter 4
```

## Gate 5: paper figures

Minimum figure package:

- benchmark transition price path,
- political residual and political pressure by year,
- homeownership and housing demand by year,
- baby-boom and secular-decline transition paths,
- random-price envelope versus benchmark,
- hard-sign/no-smoothing versus benchmark,
- age-profile figure showing annual age cells, with display bins only for readability.

Graphing convention:

- model uses annual ages 25 to 80,
- any plotted age groups are display bins, not model bins,
- transition horizon is calendar years, not a single cohort's age grid.

## Gate 6: paper text

Current blue inserts in the LyX source cover:

- why the transition uses annual age cells and an 80-year horizon,
- why the hard median-voter threshold is smoothed,
- the pressure function,
- how the demographic-shock exercise should be interpreted,
- why random-price and hard-sign comparisons are diagnostic controls.

Before finalizing:

- replace provisional language with final benchmark values,
- add figure references after the new graphs exist,
- remove or revise older text that conflicts with the rational-expectations transition,
- if a full future-price-path RE Bellman is later implemented, add it as a separate
  comparison rather than relabeling the current random-walk expectation lane,
- keep all changes blue until the coauthor has seen them.
