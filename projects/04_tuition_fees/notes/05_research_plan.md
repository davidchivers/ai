# 05 Research plan

Last updated: 2026-02-25

---

## Chosen question and estimand

How does the present-value incidence of higher-education funding differ across three UK
regimes (income-contingent loans, graduate tax, general taxation) by graduate status, family
wealth, and lifetime earnings profile?

The primary estimand is the pairwise PDV burden difference:
$\Delta B_i^{r,s} = B_i^r - B_i^s$ for each type cell $i$ and regime pair $(r,s)$.

## Chosen model

Model 1 from `03_model_notes.md`: OLG lifecycle incidence with exogenous education choice.

Why: transparent PDV accounting, directly maps policy rules to incidence, low parametric
complexity, sufficient for a debate-paper contribution.

Model 2 (education-choice extension) is deferred to v1 unless baseline results call for it.

## Chosen calibration approach

Strategy 1 from `04_empirical_notes.md`: calibration to UK graduate earnings profiles using
IFS/LEO/SLC data.

Strategy 2: systematic policy-parameter verification from institutional sources.

Both are required — Strategy 1 pins the income process, Strategy 2 pins the regime rules.

## Regime equations (summary)

**Regime A (loans):** $R_{i,t}^A = \phi \max(y_{i,t} - \bar{y}, 0)$, with debt evolution
$D_{i,t+1} = \max((1+r_L)D_{i,t} - R_{i,t}^A, 0)$ and write-off at $T_w$.

**Regime B (graduate tax):** $Payment_{i,t}^B = \tau_G\, y_{i,t} \cdot \mathbf{1}\{e_i = G\} \cdot \mathbf{1}\{t \leq T_G\}$.

**Regime C (general tax):** $Payment_{i,t}^C = \tau_{all}\, y_{i,t}$.

Budget-balancing calibration: $\tau_G$ and $\tau_{all}$ are set to close the government
budget given the graduate share and earnings distribution.

## Data access

All inputs are from public sources: IFS reports, SLC statistics, DfE documentation, LEO
summary tables. No restricted data access is required for the baseline.

## Next 3 tasks

1. Lock baseline cohort definition (Plan 2 vs Plan 5) and document all verified parameter
   values in `02_literature_and_synthesis.md`.
2. Build earnings profiles by type cell from IFS/LEO and produce the first PDV burden table.
3. Produce the pairwise winner/loser matrix and sensitivity checks (discount rate, write-off
   horizon, earnings growth).
