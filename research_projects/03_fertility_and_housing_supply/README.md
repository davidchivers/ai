# 03_Fertility_and_Housing_Supply

Canonical status tracker: `STATUS.md`

Operational note: when the user asks whether a named skill or agent exists or should be used for
this project, check the repo-level shared folders first:
- `_shared/skills/`
- `_shared/agents/`
Do not answer from installed system skills alone. The shared calibration workflow for this project
is `_shared/skills/calibration-skill-SKILL.md`.

## Project type

Paper-phase drafting is now underway, with the notes/build comparison pack still serving as the
model-validation workspace.

## Current status

As of `2026-04-08`, the annual branch now has a **stationary no-drift endpoint** on the calibrated
permits-starts-completions-stock block. That matters because the annual full-RE branch can now be
framed as a transition around a stationary annual equilibrium rather than only as a permanently
trending path that eventually hits the long-run price cap. The same pass also fixed an internal
consistency problem: the annual scripts labelled `calibrated` now actually load the best-fit
construction parameters from the calibration search table rather than silently using the class
defaults.

There is now also a clear next rung on the annual full-RE ladder:
- `notes/build/annual_full_re_stationary_transition_fertility_shock_T80.md`
- this keeps the stationary annual full-RE housing block fixed but lets a temporary fertility-demand
  path feed future housing demand and therefore future prices
- so fertility can now affect future prices inside the annual RE branch, even though fertility is
  not yet an endogenous state in the RE loop

That rung has now been pushed one step further:
- `notes/build/annual_full_re_stationary_transition_endogenous_fertility_T80.md`
- fertility is now a reduced-form endogenous state inside the stationary annual full-RE block
- it responds to prices and ownership access relative to the stationary endpoint, then feeds back into demand and prices
- the main effect is still on prices rather than ownership composition, but this is now a genuine step beyond q-only annual RE

The ladder has also now passed the simplest policy-persistence rung:
- `notes/build/annual_full_re_stationary_transition_regime_path_t5_T80.md`
- agents internalize a known switch from baseline support to benchmark support at `t = 5`
- this barely changes prices relative to the always-benchmark full-RE path, but it does change ownership composition before the switch arrives
- so the next real gap is no longer “anticipated regime path”; it is a genuinely forecasted policy or political state

The stationary annual endpoints are:
- baseline:
  - `q_ss ≈ 1.993`
  - young mortgaged-owner share `25-34 ≈ 0.224`
- benchmark:
  - `q_ss ≈ 1.974`
  - young mortgaged-owner share `25-34 ≈ 0.269`
- robustness:
  - `q_ss ≈ 1.961`
  - young mortgaged-owner share `25-34 ≈ 0.290`

There is now also a **full RE annual transition around that stationary endpoint**:
- `notes/build/annual_full_re_stationary_transition_calibrated_T80.md`
- object:
  - observed `t = 0` snapshot
  - no permanent drift
  - calibrated construction-flow block
  - full RE price path solved out to `T = 80`
- main read:
  - the early and middle years of the full-RE path are almost identical to the corresponding no-RE no-drift transition anchor
  - by `t = 80`, the ownership side is essentially at the stationary endpoint and prices are still converging upward toward it
  - so the annual branch can now be described as a genuine full-RE annualised model, not only as a bounded-RE transition experiment

The live annual calibration pack is now:
- calibration targets:
  - `notes/build/annual_transition_calibration_targets.md`
  - `drafts/tables/annual_transition_calibration_targets.tex`
- experiment grid:
  - `notes/build/annual_transition_calibrated_experiments.md`
- figures:
  - `notes/build/annual_transition_benchmark_paths.png`
  - `notes/build/annual_transition_benchmark_sensitivity.png`
- paper-facing annualised draft:
  - `drafts/fertility_and_housing_supply_annualised.tex`
  - `drafts/fertility_and_housing_supply_annualised.pdf`
- bounded RE extensions:
  - `notes/build/annual_one_step_re_transition.md`
  - `notes/build/annual_k_step_re_transition.md`
  - `notes/build/annual_plm_re_transition.md`
  - `notes/build/annual_re_step_ladder.md`
  - `notes/build/annual_votes_supply_stock_price_note.md`
  - `notes/build/annual_snapshot_state_transition_permits_stock.md`
  - `notes/build/annual_snapshot_state_transition_permits_starts_stock_calibrated.md`
  - `notes/build/annual_one_step_re_permits_stock.md`
  - `notes/build/annual_permits_stock_re_workflow.md`
  - `notes/build/annual_two_step_re_permits_stock.md`
  - `notes/build/annual_three_step_re_permits_stock.md`
  - `notes/build/annual_permits_stock_re_summary.md`
  - `notes/build/annual_1_step_re_permits_starts_stock_calibrated.md`
  - `notes/build/annual_2_step_re_permits_starts_stock_calibrated.md`
  - `notes/build/annual_3_step_re_permits_starts_stock_calibrated.md`
  - `notes/build/annual_permits_starts_stock_re_summary.md`

The annual extension is now organized around two frozen cases:
- benchmark:
  - qualification `0.25`
  - family help `0.15`
- robustness:
  - qualification `0.40`
  - family help `0.30`

Interpretation:
- the `5-year` branch remains the main steady-state benchmark
- the annual branch is a `t = 0-5` crunch-window transition diagnostic, with `t = 20` used only
  as a persistence check
- help-to-buy / qualification is the main annual mechanism, with lighter family deposit help as
  an amplifier rather than the core story
- bounded RE is now viable on top of that annual transition object:
  - one-step RE works cleanly
  - at moderate RE feedback, even finite-horizon `k-step` RE stays stable out to `k = 20`
  - the live RE lesson is that instability comes from feedback strength, not horizon length alone
  - a first perceived-law-of-motion RE pass now converges technically but is not yet economically usable, so the paper-facing RE region should stay with explicit bounded `k = 2-3`
- the next structural upgrade should probably be on the supply side rather than in expectations alone:
  - the current annual bridge is too compressed as `politics -> theta -> reduced-form supply -> price`
  - the live recommendation is to move toward a data-facing chain
    `politics/restrictiveness -> permits -> completions -> stock -> prices`
    before reopening richer RE beyond the bounded `k = 2-3` region
- the first permits/stock implementation is now in place:
  - `code/build_annual_snapshot_state_transition_permits_stock.py`
  - it produces a more believable annual mechanism story:
    - support still lifts young mortgaged ownership
    - and by `t = 20` it leaves prices slightly below baseline because it works through lower political tightness and gradually higher stock
  - the live read window is still `t = 0-20`, because under permanent `+5%` demand pressure the long-run price path still eventually hits the numerical cap
- there is now also a more data-facing construction-flow calibration on top of that block:
  - `code/build_annual_snapshot_state_transition_permits_starts_stock_calibrated.py`
  - it explicitly tracks:
    - permits
    - units authorized but not yet started
    - starts
    - units under construction
    - completions
    - stock
  - it is calibrated to Census-style construction targets over `t = 1-5`:
    - starts / permits about `0.932`
    - completions / starts about `0.895`
    - permit-inventory lag about `0.50` years
  - the best-fit parameters match those targets closely while preserving the main annual ownership mechanism
- bounded RE now also passes cleanly on that **calibrated** construction-flow block:
  - `code/build_annual_k_step_re_permits_starts_stock_calibrated.py`
  - solved prices stay tame through `k = 3`:
    - `q_1 ≈ 1.006`
    - `q_2 ≈ 1.018`
    - `q_3 ≈ 1.037`
  - and remain technically stable out to `k = 5` and `k = 8`, though the extra horizon mostly shows up as a larger positive price premium rather than meaningful composition changes
  - a full active-horizon `k = 20` solve also converges on the calibrated construction-flow block, so full-path RE is no longer blocked numerically there
  - but that longer solve mainly adds a larger price premium rather than materially changing ownership composition
  - relative to the calibrated stock-flow anchors, RE mainly adds a small price offset rather than changing ownership composition materially
  - this makes the calibrated construction-flow block the strongest candidate for the live annual price layer
  - there is now also a stationary-equilibrium check on that same calibrated block:
    - `notes/build/annual_stationary_equilibrium_permits_starts_stock_calibrated.md`
  - read:
    - the no-drift annual block converges cleanly
    - so full annual RE can now be framed as a transition around a stationary annual equilibrium rather than only around a drifting path
  - the next workflow toward full RE is now explicit in:
    - `notes/build/annual_full_re_workflow.md`
    - the recommended next step there is finite-path full RE with `T = 20`, not infinite-horizon RE
  - that next step has now also been pushed further with a genuine longer finite-path solve:
    - `code/build_annual_full_path_re_permits_starts_stock_calibrated.py`
    - `notes/build/annual_full_path_re_permits_starts_stock_calibrated_T40.md`
  - read:
    - the early annual RE path is robust to extending the horizon to `T = 40`
    - but by `t = 40` both the RE path and the calibrated non-RE anchor are at the price cap
    - so `T = 40` is mainly a feasibility / closure stress test rather than a new main-text economic result
- there is now also a bounded unattended refresh packet for the live annual RE hierarchy:
  - workflow note:
    - `notes/build/annual_full_re_12_hour_workflow.md`
  - launcher / runner:
    - `code/start_annual_full_re_12_hour_workflow.ps1`
    - `code/annual_full_re_12_hour_workflow.ps1`
  - packet builder:
    - `code/build_annual_permits_starts_stock_re_packet.py`
  - purpose:
    - rerun the calibrated construction-flow anchor plus the live `k = 3 / 5 / 20` RE cases
    - then leave one consolidated packet note/table plus a figure and a rebuilt annualised PDF for draft or appendix integration
- bounded RE has now been reopened on top of that upgraded block:
  - `code/build_annual_one_step_re_permits_stock.py`
  - one-step RE is very tame there, with solved `q_1` around `1.005`
  - explicit `k = 2` and `k = 3` also pass on the upgraded block:
    - `q_2` settles around `1.016`
    - `q_3` settles around `1.033`
  - the live conclusion is now that the upgraded permits/stock block passes the bounded RE workflow cleanly through `k = 3`
  - that means the next open question is not whether bounded RE works on this block; it is whether to calibrate the permits/completions side more directly to data before pushing any deeper

As of `2026-04-01`, the project has a clean branch split again. The corrected `5-year` fertility
benchmark is the live benchmark object, while the annual branch is being re-baselined separately
after the transition-orientation fix in `code/SolveSS_fertility.m`. The refreshed `5-year`
overnight rerun now leaves the operative local benchmark bracket at `a_price = 1.750-1.800`,
with refined local equilibrium price about `1.750394` on the `I = 60`, `J = 14` grid.

Because the first-birth timing fix made the fertility-side crossing more locally irregular, the
old one-shot benchmark refresh wrapper is no longer the reliable way to regenerate the public
comparison files. The current unattended refresh path is now:
- launcher: `code/start_refresh_corrected_benchmark_outputs_overnight.ps1`
- overnight worker: `code/refresh_corrected_benchmark_outputs_overnight.ps1`
- active run pointer: `notes/build/logs/active_overnight_benchmark_refresh.txt`
- latest run pointer: `notes/build/logs/latest_overnight_benchmark_refresh.txt`
Each overnight run writes its own timestamped log folder under `notes/build/logs/`.
The latest completed corrected refresh is
`notes/build/logs/overnight_benchmark_refresh_20260401_113700`.
That run refreshed the benchmark markdown/csv/pdf layer. The resulting live `5-year` benchmark
outputs are `notes/build/fertility_run_ge_report.md`,
`notes/build/fertility_vs_nimby_benchmark_report.md`,
`notes/build/fertility_vs_nimby_benchmark_report.pdf`,
and the short project-facing note
`notes/build/fertility_five_year_live_benchmark_note.md`.

The annual branch is no longer a promoted near-benchmark object. After fixing the
transition-matrix orientation bug, the corrected annual smoke and benchmark-eval runs show no
sign change on the checked grids and much worse fertility moments than the pre-fix notes
suggested. So the older annual mechanism-search notes below are now historical context only and
should be treated as stale until the corrected rebaseline finishes.

If that corrected rerun still fails, the planned reopen path is now fixed in
`code/fertility_annual_ownership_balance_sheet_branch_spec.m`
and
`notes/build/fertility_annual_ownership_balance_sheet_workflow.md`.
That branch keeps the usable annual fertility anchor and reopens annual with entrant ownership /
balance-sheet heterogeneity rather than more one-parameter rescue screens.

The corrected annual rebaseline is now running on Hamilton as job `16633573` through
`code/hpc/fertility_annual_broad_calibration_screen.slurm`, with detached local monitor
`code/hamilton_annual_fertility_rebaseline_handoff.ps1`. The current synced handoff run directory
is `notes/build/logs/hamilton_annual_fertility_rebaseline_handoff_20260401_113958`.

There is now also a solver-integrity pass for the annual branch. The upstream shutoff shortcut in
`code/SolveSS_fertility.m` now only triggers in the true nested reproduction case and writes
consistent grid / mass diagnostics, the reproduction checks in
`code/run_ge_fertility_main.m` and
`code/write_fertility_vs_nimby_benchmark_main.m`
now build that shutoff case through `code/build_nimby_shutoff_overrides.m`, and the annual layer
in
`code/fertility_benchmark_annual_config.m`,
`code/compare_nimby_annual_vs_five_year_main.m`,
and
`code/run_ge_fertility_annual_main.m`
now annualizes the financial block on the same convention as the active annual workflows. A new
check,
`code/run_fertility_solver_integrity_checks.m`,
now writes
`notes/build/fertility_solver_integrity_checks.md`;
that check passed locally on `2026-03-27`, and the annual smoke outputs
`notes/build/fertility_run_ge_annual_report.md`
and
`notes/build/nimby_annual_vs_five_year_report.md`
were refreshed on the fixed path.

There is now also a fresh direct CDC WONDER state-year timing review for the annual fertility
target layer. The direct pull lives in
`data/raw/cdc_wonder_first_births_state_year_export.csv`,
the clean imported panel lives in
`data/raw/cdc_fertility_state_year.csv`,
and the review note / graph are
`notes/build/cdc_first_birth_timing_target_review.md`
and
`notes/build/cdc_first_birth_timing_target_review.png`.
That review shows the old pooled age-25+ timing shape target was already close to the direct
`2020-2024` CDC pull, but the main annual fertility targets should instead be the direct annual
timing levels: pooled `2020-2024` mean age at first birth `27.484` and share of first births at
age `30+` `0.372`. The pooled age-shape shares should remain as medium-weight support targets,
not knife-edge annual requirements.

That annual target layer has now been widened further into an explicit screening-band policy.
The new code helper is
`code/fertility_annual_target_ranges.m`,
the builder is
`code/build_annual_fertility_target_ranges.py`,
and the current note is
`notes/build/annual_fertility_target_ranges.md`.
The main rule is now: this is an economic-model calibration, not a simulation-style exact fit.
So the annual calibration should use wide screen bands plus qualitative sign checks, not
month-level penalties. The preferred screen bands are currently:
- mean age at first birth: `25.0-31.0`
- share first births at age `30+`: `0.20-0.55`
- childless share at age `50`: `0.10-0.35`
- U.S. TFR: `1.40-1.95` as validation only
The grouped age-bin shares remain loose support targets, and the decisive qualitative
requirements are still that higher house prices delay births and lower fertility.

That target reset first became a broad annual fertility-first workflow:
`code/run_fertility_annual_broad_calibration_screen.m`,
with Hamilton wrappers
`code/hpc/run_fertility_annual_broad_calibration_screen.sh`
and
`code/hpc/fertility_annual_broad_calibration_screen.slurm`.
Its scoring rule is intentionally loose: zero penalty inside the broad timing / childlessness
bands, gradual penalty outside them, and hard emphasis on getting the comparative-static signs
right. The first local smoke note,
`notes/build/fertility_annual_broad_calibration_screen.md`,
showed why the broad box was only a first pass: even after widening the tolerances, the annual
model was still too delayed, with the best smoke candidate at mean age first birth about `32.28`
and share first births at age `30+` about `0.817`.

There is now also a local timing-shifter diagnostic on top of that broad-band screen:
`code/run_fertility_annual_timing_shifter_micro_screen.m`.
The resulting note is
`notes/build/fertility_annual_timing_shifter_micro_screen.md`.
That micro screen shows the annual timing layer matters a lot. A mid realized-birth profile
(`0.45 / 0.15 / 0.04` across the four five-year bins, repeated to single ages) brings the best
local candidate much closer on timing, to mean age first birth about `30.53` and share first
births at age `30+` about `0.510`. But the stock fertility side is still badly off, with
childless share at age `50` only about `0.008`. So the next annual branch should treat timing
profiles as a live calibration margin, but it still needs a separate stock-fertility correction.

That broad fertility-first Hamilton box (`16620737`, `ann_fert_cal`) has now been stopped after a
shared-calibration-skill theory checkpoint. It was a `survivor`, not `usable`: after `70 / 145`
candidates and `1-10:44:44` elapsed, its best row still sat around mean age first birth `32.12`,
share first births age `30+` `0.817`, and childless share at `50` `0.0037`. The resulting theory
note is `notes/build/fertility_annual_timing_stock_theory_note.md`.

The live annual Hamilton branch is now the narrower timing-plus-stock survivor refinement:
`code/run_fertility_annual_timing_stock_screen.m`,
with Hamilton wrappers
`code/hpc/run_fertility_annual_timing_stock_screen.sh`
and
`code/hpc/fertility_annual_timing_stock_screen.slurm`.
The local smoke note is
`notes/build/fertility_annual_timing_stock_screen.md`.
That smoke pass is materially better: the best candidate
(`front_loaded_timing | phi0 1.45 | child 0.02 | cost 0.05 | kappa 0.16 | lambda 0.10`)
gets mean age first birth down to about `30.67` and share first births age `30+` down to about
`0.485`, but childless share at `50` is still only about `0.024`. So timing is now in a broadly
reasonable region, while stock fertility remains the active miss.

That timing-plus-stock fast screen has now completed on Hamilton as job `16624677` with exit
`0:0` after `10:26:57` on `cn043`. The final screen confirms the same basic read: there is still
no candidate inside all primary annual fertility bands, but the tradeoff is now visible rather
than hidden. The best overall scored row remains the same front-loaded low-deterrence candidate
above, while the best childlessness-in-band candidate is
`front_loaded_timing | phi0 1.05 | child 0.02 | cost 0.05 | kappa 0.16 | lambda 0.10`,
which gets childless share at `50` up to about `0.197` but pushes mean age first birth back out
to about `33.26` and share first births age `30+` to about `0.766`. In calibration-skill terms
this completed box is a `survivor`, not `usable`.

That completed survivor batch was then turned into an actual auto-continue bridge box rather than
a pause. The new workflow is
`code/run_fertility_annual_timing_stock_bridge_screen.m`,
with Hamilton wrappers
`code/hpc/run_fertility_annual_timing_stock_bridge_screen.sh`
and
`code/hpc/fertility_annual_timing_stock_bridge_screen.slurm`.
Its theory note is
`notes/build/fertility_annual_timing_stock_bridge_theory_note.md`,
and the local bridge smoke note is
`notes/build/fertility_annual_timing_stock_bridge_screen.md`.
That bridge smoke narrows the useful frontier further: `pivot_front_loaded` and
`ultra_front_loaded` at `phi0 = 1.25` are now much closer on timing than the old
childlessness-in-band row, while the mild deterrence bridge bundle is dominated. So the live
Hamilton bridge box keeps only the low-deterrence frontier and searches finer `phi0` steps
between `1.05` and `1.25`.

There is now also a cluster-prep handoff layer for the active annual NIMBY steady-state workflow.
The new files live under `code/hpc/`:
`prepare_annual_nimby_bundle.ps1`,
`run_annual_nimby_workflow.sh`,
and
`annual_nimby_workflow.slurm`.
That path stages a sibling-project bundle with the prebuilt annual transition matrices plus the
upstream project-02 steady-state code. The broader low-entry and owner-grid NIMBY annual screens
were useful as bridge diagnostics, but they are no longer the main annual calibration objective.
The stale owner-grid job `16602541` is cancelled, the broad fertility-first box `16620737` is
also cancelled after the survivor diagnosis, and the latest low-priority cluster branch
`16624677` (`ann_fert_timing_stock`) has now completed cleanly. Its synced log folder is
`notes/build/logs/fertility_annual_timing_stock_screen_hpc_20260329_205716`, and its result is
the annual-calibration baseline for the next follow-up box. That bridge follow-up has now also
completed cleanly on Hamilton as job `16627167` with exit `0:0` after `07:40:39` on `cn003`.
The synced result in `notes/build/fertility_annual_timing_stock_bridge_screen.md` is the clearest
annual frontier so far: the best overall row,
`very_front_loaded | phi0 1.15 | child 0.02 | cost 0.05 | kappa 0.16 | lambda 0.10`,
gets mean age first birth to about `31.01`, share first births age `30+` to about `0.503`, and
childless share at `50` to about `0.088`. So there is still no full primary-band pass, but the
remaining miss is now small and concentrated rather than broad. In calibration-skill terms this
bridge box is still a `survivor`, but it is now close enough that the next step should be a very
narrow micro follow-up, not another generic screen.

That micro continuation now exists as
`code/run_fertility_annual_timing_stock_micro_screen.m`,
with matching Hamilton wrappers under `code/hpc/`.
The important update is that the local micro smoke has already found the first usable annual
candidate. The smoke run was only partial before timeout, but the candidate order was rewritten to
prioritize the plausible pass region, and the rerun reached it quickly enough to identify:
`max_front_loaded | phi0 1.120 | child 0.020 | cost 0.050 | kappa 0.16 | lambda 0.10`.
At the annual evaluation price that row gives mean age first birth about `30.70`, share first
births age `30+` about `0.444`, and childless share at `50` about `0.1007`, so it is inside all
three primary annual screen bands and still passes the smoke-path sign checks. In calibration-skill
terms that is a `usable local candidate`, which means the next step is inspection / confirmation,
not another exploratory upload.

That confirmation has now been run directly on the candidate itself over the wider annual market
grid. The result is mixed but useful: the fertility fit survives, but the market-clearing problem
does not. Vote stays negative from `a_price = 1.50` through `5.00`, so this row is still not a
promoted annual benchmark. The annual bottleneck has therefore shifted from “find a usable
fertility-fit row” to “recover a crossing in the now-usable fertility region.”

That crossing-recovery step has now also been tested locally in a deliberately tiny owner-access
micro box. The new workflow is
`code/run_fertility_annual_crossing_recovery_micro_screen.m`,
with matching wrappers under `code/hpc/`.
It freezes the usable fertility row and varies only `housingmax`, `theta_r`, `ka`, and
`rent_markup`. The read is now clearer: those levers do move vote, but not nearly enough to fix
the annual market-clearing failure. The best local row in
`notes/build/fertility_annual_crossing_recovery_micro_screen.md`
still has eval vote about `-312.46` and best wider-grid vote only about `-142.80` even at
`a_price = 5.00`, with no unique crossing. So the next annual decision is no longer another tiny
owner-side sweep; it is whether the benchmark can be presented with a fertility-fit/no-crossing
row, or whether a deeper political/access redesign is needed.

That deeper redesign pass now also exists as
`code/run_fertility_annual_political_redesign_screen.m`.
It freezes the fertility block near the usable annual row and searches only the near-benchmark
ridge built around partial uniform cohort blends, lower `theta_r`, the safer
`extra_front_loaded` timing anchor, and a tight owner-grid neighborhood. The important read is
that this ridge is genuinely promising but not yet stable. In low-resolution smoke
(`I = 12`, `J = 6`) it can produce apparent unique crossings, with the best smoke row at
`extra_front_loaded phi0 1.120 | alpha 0.75 | theta_r 0.35 | housingmax 15`.
But on the finer owner grids those apparent benchmarks do not survive cleanly:
the `theta_r = 0.35` row develops multiple sign changes, the smoother `theta_r = 0.45` row stays
negative throughout, and the midpoint `theta_r = 0.40` row gets a local crossing that disappears
again on a still finer `J = 12` check. So there is still no promoted annual benchmark, but the
search is now concentrated on a narrow and economically interpretable political/access ridge
rather than on the fertility block itself.

That follow-up has now also been pushed into an age-selective older-tail shape branch:
`code/run_fertility_annual_political_shape_screen.m`.
The useful direction is not younger-heavy. The only live shape family is an older-tail flattening
of the annual cohort profile, and its best local smooth near-miss is
`older-tail bridge shape | theta_r 0.40 | housingmax 15.25`.
On the local `I = 16`, `J = 10` grid that row keeps the annual fertility moments inside the main
bands and gets as close as vote `-0.029` at `a_price = 5.00` without introducing extra sign
changes. But the finer owner-grid confirmation in
`notes/build/fertility_annual_political_shape_screen.md`
and the theory note
`notes/build/fertility_annual_political_shape_theory_note.md`
kill the apparent rescue: on `J = 12` the same row is still negative throughout, with max
wider-grid vote only about `-0.377`. Heavier older-tail interpolants do not improve on that, and
a direct `d_a_price` probe around the confirmed bridge row also leaves the wider-grid maximum
negative. A final direct discount-block probe lifts vote only by destroying the fertility fit.
So there is still no stable promoted annual benchmark, and the older-tail shape / direct
vote-shock / discount-micro branch is now best treated as exhausted.

One benchmark-layer caveat remains: the long 5-year public benchmark markdown / pdf outputs have
not yet been rebuilt end to end on the fixed shutoff path. A direct interactive rerun of
`write_fertility_vs_nimby_benchmark_main` was stopped after a one-hour timeout, and the published
benchmark-file timestamps did not change. That refresh has now been pushed to Hamilton as a
separate low-priority documentation-layer job, using the new cluster
runner
`code/hpc/run_fertility_benchmark_refresh.sh`
and SLURM wrapper
`code/hpc/fertility_benchmark_refresh.slurm`.
The first benchmark-refresh submit (`16604880`) failed immediately because the staged Hamilton
`notes/` tree was not writable. The second submit (`16608839`) also failed immediately because the
sibling bundled `02_nimbyism_and_housing_supply` tree was not traversable, so MATLAB could not see
`ensure_external_matlab_data_paths`. After repairing whole-bundle permissions with
`chmod -R u+rwX`, the replacement benchmark-refresh job is now `16608946`, currently back in the
queue on `shared`. A detached local monitor is attached via
`code/start_hamilton_fertility_benchmark_handoff.ps1` so the rebuilt benchmark layer is synced
back automatically when that run finishes.

There is now a paper draft in `drafts/`:
`drafts/fertility_and_housing_supply.tex` and `drafts/fertility_and_housing_supply.pdf`.
That draft has now been reframed so the main text leads with the paper's own fertility results
rather than with the NIMBY comparison pack. The main text now centers on delayed first births in
the steady state, persistent housing scarcity in the long run, and the modest empirical timing /
historical validation bridge. Exact nesting of the NIMBY benchmark, the baby-boom exercise, and
the bounded robustness material have been demoted to appendices.

The model-side presentation refresh is now complete: the NIMBY-versus-fertility comparison
bundle has been rebuilt so the note and figures report both raw vote and normalized
vote-per-mass after the mass-scaling fix. The empirical geography mismatch between county
fertility data and the legacy metro-year housing/control block is again the main paper
bottleneck, with benchmark-presentation tradeoffs now a secondary framing choice.

There is now also a separate paper-style model-comparison note in `notes/build/`:
`nimby_vs_fertility_model_comparison.pdf`. It follows the Gross and Chivers model-section order,
states the exact household-utility and state-space changes in the fertility extension, keeps
implementation detail in an appendix, and replaces the copied NIMBY placeholders with genuine
steady-state comparison figures.

That note now also includes a direct baby-boom transition comparison. The upstream NIMBY line is
taken from the original smoothed IRF object in Dropbox, while the fertility line is generated from
the matched project-03 transition run under the same temporary `+10%` birth shock for 10 periods.
The transition section now also includes NIMBY-style young/old homeownership panels and a cohort
homeownership-access comparison. On the fertility side these are explicitly labeled proxy objects:
they are built from a common age profile plus the model-implied house-price path, because the
current transition block still does not solve explicit tenure or savings choices.

That note now also contains an explicit baby-boom mechanism decomposition. The baby-boom section is
no longer just a side-by-side price-path comparison: it now traces the common boom shock into
children at home, house-price amplification, and the later fertility correction; compares the full
fertility bridge against `no crowding` and `no price-sensitive births` shutoff cases; and adds an
age-support proxy to make the family-years political mechanism visible. The main read is that
crowding is the main extra price-amplification channel, while price-sensitive births matter
primarily for the later fertility correction. At age `35` and `t = 20`, the support proxy for
higher prices is about `0.004` in the NIMBY proxy, about `-0.019` with crowding shut off, and
about `-0.307` in the full fertility model.

The steady-state benchmark can now also show delayed first births directly. A new timing export in
`notes/build/` tracks the birth flow out of childless states and converts it into mean age at
first birth, median age at first birth, and the share of first births occurring at age `30+`.
Across the benchmark price grid, moving from `a_price = 1.50` to `3.00` now raises mean age at
first birth from about `27.57` to about `30.95`, raises the `30+` first-birth share from about
`0.370` to about `0.709`, and lowers the average first-birth rate from about `0.233` to about
`0.134`. The benchmark note now records the underlying U.S. calibration target directly: recent
CDC first-birth shares at ages `25, 30, 35, 40` are `[0.438, 0.381, 0.152, 0.029]`, while the
model delivers `[0.498, 0.312, 0.143, 0.047]` at benchmark `a_price = 2.00`. The new timing note
is `notes/build/fertility_first_birth_timing.md`, and the figure used in both the comparison note
and the manuscript is `notes/build/nimby_vs_fertility_first_birth_timing.png`.

It now also includes a historical validation section for the postwar fertility decline. Using the
legacy aggregate birth-rate series and aligning the post-boom decline from `1956` onward to model
period `t >= 10`, the fertility extension fits the post-boom decline modestly better than the
flat NIMBY return path at every checked horizon. The note now also includes a bounded baby-boom
robustness section and a future demographic-projection bridge. The projection comparison uses the
upstream forecast age-weight scenarios, but the two lines are matched bridge objects: a NIMBY
proxy with the fertility-demand channel shut off, and the fertility bridge with births plus
children-at-home in the demand block. The richer wealth and exact forecast-solver objects used in
the NIMBY paper are still not available on the fertility side.

The main long-run counterfactual is now a calibrated persistent NIMBY shock rather than the
earlier aging-only bridge or a free `theta0` dial. The current note in `notes/build/`:
`nimby_shock_calibrated_supply_margins.md` and
`nimby_shock_calibrated_supply_margins.png`
matches three different supply-tightening shocks to the same 15 percent 40-period house-price
target, then compares the implied fertility paths both to the historical postwar decline and to
the forward age-scenario bridge. The main model result survives across all three supply margins:
sustained housing scarcity lowers future fertility. The historical comparison is now also stated
more honestly: the calibrated shocks move the model in the right direction, but only explain a
modest share of the aggregate postwar decline. That calibrated comparison has now replaced the
older long-run section in both the manuscript draft and the model-comparison note.

The immediate empirical bridge is now clearer than it was before. Because the model exports direct
first-birth timing moments, the natural next comparison is not total fertility alone but the
state-year CDC WONDER first-birth timing outcomes already in the project: `mean_age_first_birth`,
`share_first_birth_30_plus`, and `first_birth_rate_15_44`.

That timing bridge has now been built in `notes/build/first_birth_timing_model_data_comparison.md`.
The comparison uses state-and-year-adjusted rent bins rather than raw levels, because the model
uses steady-state house prices while the empirical panel uses a state-year rent index. The result
is encouraging but still limited: the data and the model move in the same direction on all three
timing objects, but the empirical gradients are much smaller and remain imprecise in the current
sample. So this is directionally supportive evidence, not yet a tight quantitative validation.

An international timing scaffold now also exists. The script
`code/pull_eurostat_first_birth_timing.py` pulls the official Eurostat `demo_find` fertility
indicators and writes `data/processed/international_first_birth_timing_eu.csv`. That panel covers
`49` countries over `1960-2024` and currently includes `mean_age_first_birth`,
`pct_first_order_live_births`, `mean_age_childbirth`, and `total_fertility_rate`.

The first international shock layer is now in place as well. The new script
`code/pull_international_timing_shocks.py` merges the Eurostat timing panel with official OECD
annual house-price and interest-rate series plus annualized BIS property-price growth, writing
`data/processed/international_first_birth_timing_shocks_v1.csv`. The merged panel currently has at
least one shock series for `35` countries. The companion source menu in
`notes/build/international_timing_shock_menu.md` still sets the next richer timing layer as HFD.

The first international timing regressions have now also been run in
`notes/build/international_timing_shock_regressions.md`. The clearest cross-country signal is the
house-price level rather than short-run price growth: in the OECD-only panel, higher house-price
indices are associated with later first births and lower total fertility. The standalone
interest-rate block is mixed, and the simple horse-race specifications weaken the clean housing
story rather than sharpen it.

The next empirical design is now documented explicitly in
`notes/build/uk_greenbelt_planning_shock_workflow.md`. The recommended England-specific causal path
is no longer a vague "policy shock" idea: it is pre-period greenbelt exposure interacted with
common planning-regime timing, validated first against local house prices and then taken to
fertility timing outcomes.

That England design now has a real first panel behind it. The new builder
`code/build_england_greenbelt_planning_panel.py` writes
`data/processed/england_greenbelt_fertility_panel_v1.csv`, which merges official greenbelt live
tables, NOMIS local-authority birth rates and age-of-mother counts, and annualized UK HPI local
authority prices. The merged panel covers `313` authorities over `2013-2024`, with a complete
`2014-2024` sample of `3206` authority-years across `293` authorities.

The first descriptive England read is encouraging but uneven. The timing outcome moves in the
expected direction: higher greenbelt exposure is associated with a higher `share_births_30_plus`
in the year-fixed-effects panel. The local house-price validation is positive but imprecise in the
same first pass, so the England panel is now useful enough to work with but not yet the final
causal design. The current greenbelt-side harmonization is no longer the main problem: after a
second pass that aggregates multi-belt authorities and backfills current-code histories from
legacy rows, the remaining overlap gap is down to `17` old district codes in the NOMIS fertility
pull that do not line up with current-code UK HPI geographies.

The first England regressions are now written up in
`notes/build/england_greenbelt_regressions.md`. The main read is that the England panel currently
looks more like a timing/composition result than a clean quantity result. Greenbelt exposure is
associated with later childbearing and a shift away from younger ASFRs toward older ASFRs, but the
local-price validation remains weak and the cross-sectional TFR sign is positive rather than
negative. By contrast, local house prices line up cleanly with the model direction: higher prices
predict later births and lower fertility. So the England empirical block is now informative, but
it is not yet the final causal validation object.

That interpretation is now tighter after a separate `poshness`-control pass. The new builders
`code/build_england_greenbelt_baseline_controls.py` and
`code/build_england_greenbelt_controlled_regressions.py` add 2011 Census degree, tenure, and
occupation controls plus an official LAD24-to-region lookup, then rerun the England design as
`greenbelt_share_pre x post2019` with local-authority fixed effects and region-year fixed effects.
In that stricter design the raw greenbelt timing gradient mostly disappears: the greenbelt
exposure term becomes small and imprecise on timing, fertility, and price outcomes. So the
England block currently points more toward `raw cross-sectional greenbelt exposure is confounded by
affluent-place / regional composition` than toward a clean England causal validation.

## Current working folders

- `notes/`: active research notes and contribution framing.
- `literature/`: verified source PDFs.
- `code/`: scripts and experiments.
- `data/`, `figures/`, `exports/`: empirical/model artifacts and collaboration outputs.
- `referee/`: reserved for paper-stage response materials.
- `drafts/`: canonical latest paper sources and compiled latest paper PDF.
- `slides/`: canonical latest slide sources and compiled latest slide PDF.

## Draft and slide naming standard

- Latest paper files in `drafts/` (no version suffix):
  - `fertility_and_housing_supply.lyx`
  - `fertility_and_housing_supply.tex`
  - `fertility_and_housing_supply.pdf` (when compiled)
- Latest slide files in `slides/` (no version suffix):
  - `fertility_and_housing_supply_slides.lyx`
  - `fertility_and_housing_supply_slides.pdf` (when compiled)
- TeX exports are archived (not shown in root folders):
  - `drafts/old_drafts/source_tex/fertility_and_housing_supply.tex`
  - `slides/old_slides/source_tex/fertility_and_housing_supply_slides.tex`
- Versioned archives only when explicitly requested:
  - `drafts/old_drafts/vNNN/`
  - `slides/old_slides/vNNN/`

## Standards

- Paper structure standard: `_shared/standards/paper_project_structure_standard.md`
- code/calibration standard: `_shared/standards/code_calibration_standard.md`
