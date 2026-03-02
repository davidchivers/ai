# Minimal Calibration Targets (UK, illustrative)

Goal: discipline magnitudes without overengineering.

## 1. Core targets
- Tuition fee level `F` (annual and implied total for typical degree length).
- Graduate share in population/cohort (`Pr[e_i=G]`).
- Earnings profiles by education status (`y_t^G`, `y_t^N`) over lifecycle.
- Earnings dispersion among graduates (at least low/median/high profiles).
- Discount rate benchmark(s) for PDV calculations.

## 2. Loan-regime policy parameters
- Repayment threshold `y_bar`.
- Repayment rate `phi` above threshold.
- Loan interest parameter(s) `r_L`.
- Write-off horizon `T_w`.

## 3. Regime-balancing parameters
- Graduate-tax rate `tau_G` (chosen to satisfy budget target under regime B).
- General-tax rate `tau_all` (chosen to satisfy budget target under regime C).

## 4. Minimal calibration strategy
1. Choose one baseline cohort and stylised earnings age-profile.
2. Pin policy-rule parameters to verified UK institutional values.
3. Calibrate `tau_G` and `tau_all` to equalise government present-value budget across regimes.
4. Compute PDV burdens by type cell (`G/N` x `H/L` x earnings profile).

## 5. Outputs to report
- PDV burden table by type and regime.
- Net-winner matrix for pairwise regime comparisons.
- Decomposition: insurance component (income contingency) vs redistribution component (who funds subsidy).

## 6. What to avoid at v0
- Large parameter sets.
- Endogenous schooling or occupation choice.
- Full general equilibrium effects.