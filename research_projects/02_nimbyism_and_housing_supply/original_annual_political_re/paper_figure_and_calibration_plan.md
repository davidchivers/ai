# Paper figure and calibration plan for the annual full-RE revision

This plan assumes the full price-path RE runs ultimately pass at the target horizons. It is
not a claim that the final numerical results are already in hand.

## Core principle

Keep the steady-state results. They answer a different question from the transition
figures.

- The steady-state figures show the political equilibrium implied by each demographic
  structure when the economy is evaluated one year at a time.
- The transition figures show how the economy moves when households and the political
  supply channel respond dynamically.
- The new full-RE transition figures should not replace the steady-state figures. They
  should sit beside them and show whether anticipated future demographic pressure changes
  the timing or size of the response.

## Figure set

### Figure A: demographic inputs

Status: mostly keep existing figures.

Purpose: show the demographic variation before showing model outcomes.

Use:

- historical age composition, 1950-2020,
- projection age composition, 2020-2100,
- low / medium / high immigration projection paths if space allows.

Existing inputs:

- `figures/3. Projections by age group, median immigration.png`
- source data in `loop101_output_extended.mat`: `forecast_lower`,
  `forecast_median`, `forecast_upper`

Decision:

- Keep a compact demographic projection figure in the main text.
- If low/medium/high age composition is visually crowded, show medium immigration in the
  main text and put low/high in the appendix.

### Figure B: steady-state demographic equilibrium

Status: keep and possibly relabel.

Purpose: preserve the original paper's steady-state mechanism.

Use:

- historical steady-state price-income ratio,
- projection steady-state price-income ratio under low / medium / high immigration,
- optionally real-rent comparison if the original text still leans on it.

Existing figures:

- `figures/5. Price Income Ratio.jpg`
- `figures/5b. PriceIncomeRatio with Real Rents.jpg`
- `figures/6. Price Income Ratio Scenario.jpg`
- `figures/PriceIncomeRatio_Forecasts.jpg`

Decision:

- Keep the steady-state figure separate from transition graphs.
- Rename in captions as "steady-state political equilibrium" so readers do not confuse it
  with the RE transition.

### Figure C: expectation comparison for the baby-boom transition

Status: new main figure.

Purpose: show what full price-path RE changes relative to the current-price/non-RE
transition.

Plot on the same axes:

- dashed line: current-price expectation / non-RE transition,
- solid line: full price-path RE transition.

Panels:

- house price or price-income ratio,
- homeownership,
- housing demand,
- political pressure or vote imbalance.

Implementation:

1. Use current-price transition outputs from `annual_political_transition_fail_safe` or
   the Hamilton thin-ladder results.
2. Use full-RE outputs from `annual_political_full_re_price_path`.
3. Align by model year and scenario.
4. Plot first 80 reported years, not ghost-tail years.
5. Export as PDF for final paper, PNG only for quick checking.

Interpretation target:

- If full RE shifts the response earlier, say future demographic pressure is capitalized
  into current choices and prices.
- If levels are similar but timing differs, emphasize expectations affect timing more than
  the long-run political mechanism.

### Figure D: permanent entrant-decline transition

Status: new main figure or paired with Figure C.

Purpose: update the old "permanent demographic shock" exercise.

Name in paper:

- "permanent decline in entrant formation" or "permanent fall in new household
  formation"

Plot:

- dashed current-price transition,
- solid full price-path RE transition,
- same panels as baby boom if space allows.

Important distinction:

- Baby boom uses a tail that returns toward the original demographic environment.
- Permanent entrant decline should use a terminal fixed-point anchor based on the terminal
  demographic composition.

### Figure E: projection transition under immigration assumptions

Status: new main or appendix figure depending on space.

Purpose: dynamic counterpart to the old forecast exercise.

Scenarios:

- `forecast_low`
- `forecast_median`
- `forecast_high`

Preferred layout:

- Main text: price-income ratio panel for low / medium / high immigration, with solid
  full-RE lines and dashed current-price lines.
- Appendix or second panel: political pressure and homeownership under the same
  scenarios.

Reason:

- The forecast exercise is central to the old paper's forward-looking claim. It should
  not be hidden behind stylized baby-boom and entrant-decline shocks.

### Figure F: diagnostic controls

Status: appendix unless one is rhetorically essential.

Purpose: show the benchmark is not arbitrary.

Diagnostics:

- hard-sign political rule, `tau = 0`,
- near-hard small-tau rule,
- random/exogenous price paths,
- possibly no-feedback constant-price path.

Use:

- residual envelopes or summary bars,
- not every random path as a spaghetti plot unless heavily faded.

Decision:

- Do not crowd Figures C-E with diagnostic lines.
- Use diagnostics to discipline the method, not as the headline result.

### Figure G: smoothing function diagram

Status: optional, likely appendix or short text figure.

Purpose: make the smoothing parameter defensible.

Plot:

- horizontal axis: vote imbalance,
- vertical axis: political pressure,
- curves for benchmark `tau` and near-hard `tau`,
- mark the empirical range of vote imbalances from the transition runs.

Reason:

- This directly answers the referee-style concern that smoothing is arbitrary. It shows
  the rule preserves direction, limits knife-edge jumps, and does not create a free
  outcome target.

## Tables

### Table 1: baseline calibration moments

Status: keep current calibration table, add a short transition-note if needed.

Purpose:

- show the original steady-state calibration remains the anchor.

Do not recalibrate the whole model around the RE transition. That would look like
overfitting.

### Table 2: transition parameters

Status: new small table.

Rows:

- `tau`: smoothing scale for political pressure,
- `eta`: pass-through from political pressure to price/permit environment,
- horizon: 80 reported years,
- ghost-tail / terminal-tail rule,
- terminal anchor for temporary versus permanent shocks,
- demographic source for projection paths.

Key wording:

- These parameters govern the transition algorithm and the political adjustment rule.
- They are not re-estimated separately for each demographic shock.
- The benchmark is chosen before interpreting the shock paths.

### Table 3: model-fit and numerical credibility summary

Status: new small table, maybe appendix.

Columns:

- scenario,
- expectation assumption,
- max path fixed-point gap,
- max vote residual,
- max price movement,
- verdict.

Rows:

- fixed-age/no-demographic unit test,
- baby boom,
- permanent entrant decline,
- forecast low,
- forecast median,
- forecast high,
- hard-sign diagnostic,
- random-price diagnostic summary.

Purpose:

- show which results are solved objects versus diagnostics,
- make clear that full RE passes a fixed-point check rather than just producing a path.

## Calibration language to add

The revised paper should say four things clearly.

1. The steady-state calibration is unchanged.

The new transition exercise is not a recalibration of preferences, income risk, or the
life-cycle model. The original steady-state calibration remains the quantitative anchor.

2. The smoothing parameter is a transition regularization with economic content.

The hard median-voter rule treats a tiny majority as a full political mandate. The
smoothed rule instead maps the size of the vote imbalance into the strength of political
pressure. This is more defensible in an annual transition because permits, local
opposition, legal delay, and construction all move continuously rather than as an
instantaneous binary switch.

3. The pass-through parameter should be parsimonious.

Use one benchmark pass-through value, with a narrow robustness band. Do not tune `eta`
separately for baby boom, entrant decline, and projection paths. If a scenario only works
under a different parameter, it belongs in robustness, not the benchmark.

4. The steady-state and transition objects should be shown together but not confused.

The steady-state figures show the equilibrium associated with a demographic composition.
The transition figures show adjustment over time under current-price expectations and
full price-path RE. In the text, say explicitly which object each figure reports.

## Production workflow

1. Finish current Hamilton jobs.
2. If current jobs pass, submit projection smoke `T4Proj`.
3. Climb full-RE shock and projection scenarios through `T20/T40` before `T80`.
4. Once final full-RE runs exist, write a single figure-building script that reads:
   - current-price transition CSVs,
   - full-RE `paths_all.csv`,
   - steady-state projection outputs,
   - diagnostic comparison outputs.
5. Generate draft figures into a new subfolder under
   `original_annual_political_re/truth/paper_figures/`.
6. Only after the figures look right, copy final PDF/PNG files into `figures/` with stable
   names and update the LyX source.

## Expected main-text figure package

Minimum:

1. Demographic age composition / projections.
2. Steady-state political equilibrium, historical and projection.
3. Baby-boom transition, current-price versus full RE.
4. Permanent entrant-decline transition, current-price versus full RE.
5. Immigration projection transition, current-price versus full RE.

Appendix:

1. Hard-sign versus smoothed political rule.
2. Random-price placebo envelope.
3. Smoothing function and observed vote-imbalance range.
4. Numerical fixed-point summary table.
